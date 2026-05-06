import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/models/app_models.dart';
import '../../../shared/services/attendance_service.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/providers/notification_provider.dart';
import '../../../shared/store/app_store.dart';
import '../../../shared/services/face/face_recognition_service.dart';
import '../../../shared/services/face/embedding_sync_service.dart';
import '../../enrollment/presentation/enrollment_screen.dart';
import 'camera_face_view.dart';

class AttendanceScreen extends StatefulWidget {
  final bool isActive;

  const AttendanceScreen({super.key, this.isActive = true});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _store = AppStore.instance;
  GlobalKey<CameraFaceViewState> _cameraKey = GlobalKey<CameraFaceViewState>();

  bool _processing = false;
  bool _isEnrolled = false;
  bool _enrollChecked = false;

  // Live recognition state
  double _liveSimilarity = 0;
  bool _liveRecognized = false;
  bool _recognizing = false;
  List<List<double>>? _cachedEmbeddings;
  String? _cachedUid;

  // Frame terakhir yang dikenali — dipakai saat user tekan tombol.
  _RecognizedFrame? _lastRecognizedFrame;

  // Throttle recognition agar tidak spam inference.
  bool _inferencing = false;
  static const Duration _inferenceThrottle = Duration(milliseconds: 400);
  DateTime _lastInference = DateTime(0);

  // Temporal smoothing — rata-rata embedding dari N frame terakhir
  // sebelum matching agar hasil lebih stabil.
  static const int _smoothingWindow = 5;
  final List<List<double>> _embeddingBuffer = [];

  DateTime get _today =>
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  AttendanceRecord? get _todayRecord => _store.attendanceOf(_today);
  bool get _isCheckedIn => _todayRecord?.checkIn != null;
  bool get _isCheckedOut => _todayRecord?.checkOut != null;

  @override
  void initState() {
    super.initState();
    _checkEnrollmentStatus();
    FaceRecognitionService.instance.init();
  }

  Future<void> _checkEnrollmentStatus() async {
    if (kIsWeb) {
      setState(() {
        _isEnrolled = true;
        _enrollChecked = true;
      });
      return;
    }
    final uid = AuthService.instance.currentUserId;
    if (uid == null) return;
    final enrolled = await EmbeddingSyncService.instance.isEnrolledOnCloud(uid);
    if (!mounted) return;
    setState(() {
      _isEnrolled = enrolled;
      _enrollChecked = true;
    });

    // Pre-load embeddings ke cache supaya live recognition tidak perlu
    // fetch tiap frame.
    if (enrolled) unawaited(_preloadEmbeddings(uid));
  }

  Future<void> _preloadEmbeddings(String uid) async {
    final embeddings = await EmbeddingSyncService.instance.getEmbeddings(uid);
    if (!mounted) return;
    _cachedEmbeddings = embeddings;
    _cachedUid = uid;
  }

  // ── Live recognition callback ─────────────────────────────────────────────

  void _onLiveRecognition(LiveRecognitionResult result) {
    if (_processing || _isCheckedOut) return;
    if (result.status == LiveRecognitionStatus.noFace) {
      _embeddingBuffer.clear();
      if (_liveRecognized || _liveSimilarity > 0) {
        setState(() {
          _liveRecognized = false;
          _liveSimilarity = 0;
          _lastRecognizedFrame = null;
        });
      }
      return;
    }

    // Frame ada wajah tapi belum ada face object untuk di-infer.
    if (result.face == null) {
      if (!_recognizing) setState(() => _recognizing = true);
      return;
    }

    // Throttle inference.
    final now = DateTime.now();
    if (_inferencing || now.difference(_lastInference) < _inferenceThrottle) return;
    _lastInference = now;
    _inferencing = true;

    unawaited(_runInference(result));
  }

  Future<void> _runInference(LiveRecognitionResult frame) async {
    try {
      final stored = _cachedEmbeddings;
      final uid = _cachedUid;
      if (stored == null || stored.isEmpty || uid == null) return;

      final face = frame.face!;

      List<double>? queryEmbedding;
      if (frame.nv21Bytes != null) {
        queryEmbedding = await FaceRecognitionService.instance
            .extractEmbeddingFromNv21(
              nv21Bytes: frame.nv21Bytes!,
              width: frame.rawWidth,
              height: frame.rawHeight,
              rotation: frame.rotation!,
              face: face,
            )
            .timeout(const Duration(seconds: 4));
      } else if (frame.fullImage != null) {
        queryEmbedding = await FaceRecognitionService.instance
            .extractEmbedding(frame.fullImage!, face)
            .timeout(const Duration(seconds: 4));
      } else {
        return;
      }

      if (queryEmbedding == null || !mounted) return;

      // Temporal smoothing: tambah ke buffer, buang yang paling lama.
      _embeddingBuffer.add(queryEmbedding);
      if (_embeddingBuffer.length > _smoothingWindow) {
        _embeddingBuffer.removeAt(0);
      }
      final smoothedEmbedding = _embeddingBuffer.length > 1
          ? FaceRecognitionService.averageEmbeddings(_embeddingBuffer)
          : queryEmbedding;

      final result = FaceRecognitionService.instance.findBestMatchMulti(
        smoothedEmbedding,
        {uid: stored},
      );

      if (!mounted) return;

      setState(() {
        _liveSimilarity = result.similarity;
        _liveRecognized = result.matched;
        _recognizing = false;
        if (result.matched) {
          _lastRecognizedFrame = _RecognizedFrame(
            queryEmbedding: smoothedEmbedding,
          );
        } else {
          _lastRecognizedFrame = null;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _recognizing = false);
    } finally {
      _inferencing = false;
    }
  }

  // ── Connectivity check ────────────────────────────────────────────────────

  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result.any((r) => r != ConnectivityResult.none);
  }

  // ── Tombol Check-In / Check-Out ditekan ───────────────────────────────────

  void _handleButtonTap() {
    if (_isCheckedOut || _processing) return;
    if (kIsWeb) {
      _manualCheckInOrOut();
      return;
    }
    if (!_liveRecognized || _lastRecognizedFrame == null) return;
    unawaited(_confirmAndRecord());
  }

  Future<void> _confirmAndRecord() async {
    final frame = _lastRecognizedFrame;
    if (frame == null) return;

    if (_isCheckedIn) {
      final confirmed = await _confirmCheckOut();
      if (!confirmed) return;
    }

    setState(() => _processing = true);

    try {
      if (!await _isOnline()) {
        _showResult(
          success: false,
          message: 'Tidak ada koneksi internet.',
          icon: Icons.wifi_off_rounded,
        );
        return;
      }

      final uid = AuthService.instance.currentUserId;
      if (uid == null) return;

      if (!_isCheckedIn) {
        final record = await AttendanceService.instance.checkIn(
          uid,
          source: AttendanceSource.face,
        );
        if (!mounted) return;
        _store.setAttendance(record);
        NotificationProvider.instance.refresh();
        _showResult(
          success: true,
          message: 'Check-in berhasil pukul ${_fmtTod(record.checkIn!)}',
        );
      } else {
        final record = await AttendanceService.instance.checkOut(uid);
        if (!mounted) return;
        _store.setAttendance(record);
        NotificationProvider.instance.refresh();
        _cameraKey.currentState?.markDone();
        _showResult(
          success: true,
          message: 'Check-out berhasil pukul ${_fmtTod(record.checkOut!)}',
          color: AppColors.error,
        );
      }

      // Adaptive embedding update — update di background, jangan blok UI.
      unawaited(
        EmbeddingSyncService.instance.adaptEmbedding(uid, frame.queryEmbedding),
      );

      setState(() {
        _liveRecognized = false;
        _liveSimilarity = 0;
        _lastRecognizedFrame = null;
      });
    } catch (e) {
      if (mounted) {
        _showResult(success: false, message: 'Gagal menyimpan presensi. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<bool> _confirmCheckOut() async {
    final pct = (_liveSimilarity * 100).toStringAsFixed(0);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Konfirmasi Check-Out',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Wajah dikenali ($pct%). Lanjutkan check-out sekarang?',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Check-Out', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _manualCheckInOrOut() async {
    final uid = AuthService.instance.currentUserId;
    if (uid == null) return;
    setState(() => _processing = true);
    try {
      if (!_isCheckedIn) {
        final record = await AttendanceService.instance.checkIn(
          uid,
          source: AttendanceSource.manual,
        );
        if (!mounted) return;
        _store.setAttendance(record);
        NotificationProvider.instance.refresh();
        _showResult(
          success: true,
          message: 'Check-in berhasil pukul ${_fmtTod(record.checkIn!)}',
        );
      } else {
        final record = await AttendanceService.instance.checkOut(uid);
        if (!mounted) return;
        _store.setAttendance(record);
        NotificationProvider.instance.refresh();
        _showResult(
          success: true,
          message: 'Check-out berhasil pukul ${_fmtTod(record.checkOut!)}',
          color: AppColors.error,
        );
      }
    } catch (e) {
      if (mounted) _showResult(success: false, message: 'Gagal: $e');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _showResult({
    required bool success,
    required String message,
    Color? color,
    IconData? icon,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color ?? (success ? AppColors.success : AppColors.error),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            Icon(
              icon ?? (success ? Icons.check_circle_rounded : Icons.error_rounded),
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _goToEnrollment() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EnrollmentScreen()),
    );
    if (result == true && mounted) {
      await _checkEnrollmentStatus();
      if (!mounted) return;
      setState(() {
        _isEnrolled = true;
        _cameraKey = GlobalKey<CameraFaceViewState>();
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          if (!_enrollChecked) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (!_isEnrolled) return _buildEnrollPrompt();
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                children: [
                  _buildStatusSummary(),
                  const SizedBox(height: 14),
                  Expanded(child: _buildCameraArea()),
                  const SizedBox(height: 10),
                  if (!_isCheckedOut && !kIsWeb) _buildRecognitionStatus(),
                  const SizedBox(height: 14),
                  _buildActionButton(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Recognition status ────────────────────────────────────────────────────

  Widget _buildRecognitionStatus() {
    final (icon, label, color, bg) = switch (true) {
      _ when _processing => (
          Icons.hourglass_top_rounded,
          'Menyimpan presensi...',
          AppColors.primary,
          AppColors.primaryLight,
        ),
      _ when _liveRecognized => (
          Icons.verified_rounded,
          'Wajah dikenali — tekan tombol untuk presensi',
          AppColors.success,
          AppColors.successLight,
        ),
      _ when _recognizing => (
          Icons.manage_search_rounded,
          'Mengenali wajah...',
          AppColors.warning,
          AppColors.warningLight,
        ),
      _ when _liveSimilarity > 0 => (
          Icons.face_retouching_off_rounded,
          'Wajah tidak cocok, coba lagi',
          AppColors.error,
          AppColors.errorLight,
        ),
      _ => (
          Icons.face_rounded,
          'Arahkan wajah ke kamera',
          AppColors.textSecondary,
          AppColors.background,
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }

  // ── Enrollment prompt ─────────────────────────────────────────────────────

  Widget _buildEnrollPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.warningLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.face_retouching_off_rounded,
                size: 52,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Wajah Belum Terdaftar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Untuk menggunakan fitur absensi wajah, kamu perlu mendaftarkan wajah terlebih dahulu.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _goToEnrollment,
                icon: const Icon(Icons.face_retouching_natural_rounded, size: 20),
                label: const Text(
                  'Daftarkan Wajah Sekarang',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── App bar ───────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      toolbarHeight: 64,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Absensi',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _todayLabel(),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
          child: Align(
            alignment: Alignment.center,
            child: _buildStatusBadge(),
          ),
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.border),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final (label, color, bg) = _statusStyle();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  (String, Color, Color) _statusStyle() {
    if (_isCheckedOut) return ('Selesai', AppColors.success, AppColors.successLight);
    if (_isCheckedIn) return ('Sudah Check-In', AppColors.warning, AppColors.warningLight);
    return ('Belum Hadir', AppColors.missing, AppColors.missingLight);
  }

  // ── Status summary ────────────────────────────────────────────────────────

  Widget _buildStatusSummary() {
    final record = _todayRecord;
    final cin = record?.checkIn;
    final cout = record?.checkOut;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(child: _timeSlot('Check-in', cin, AppColors.success)),
          Container(width: 1, height: 36, color: AppColors.border),
          Expanded(child: _timeSlot('Check-out', cout, AppColors.error)),
        ],
      ),
    );
  }

  Widget _timeSlot(String label, TimeOfDay? time, Color activeColor) {
    final hasTime = time != null;
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          hasTime ? _fmtTod(time) : '--:--',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: hasTime ? activeColor : AppColors.textSecondary,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  // ── Camera area ───────────────────────────────────────────────────────────

  Widget _buildCameraArea() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: _isCheckedOut
          ? _buildCompletedAttendanceView()
          : CameraFaceView(
              key: _cameraKey,
              active: widget.isActive,
              hint: 'Arahkan wajah ke kamera',
              liveMode: !kIsWeb,
              onLiveRecognition: _onLiveRecognition,
            ),
    );
  }

  // ── Supporting info ───────────────────────────────────────────────────────

  Widget _buildCompletedAttendanceView() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.success.withValues(alpha: 0.16)),
                boxShadow: const [
                  BoxShadow(color: Color(0x120F172A), blurRadius: 16, offset: Offset(0, 8)),
                ],
              ),
              child: const Icon(Icons.check_circle_rounded, size: 36, color: AppColors.success),
            ),
            const SizedBox(height: 18),
            Text(
              _completedAttendanceHeadline(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _completedAttendanceMessage(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, height: 1.45, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                _completedAttendanceFooter(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _completedAttendanceHeadline() {
    final hour = DateTime.now().hour;
    if (hour >= 17) return 'Sampai ketemu esok hari';
    if (hour >= 12) return 'Presensi hari ini sudah lengkap';
    return 'Presensi selesai dengan baik';
  }

  String _completedAttendanceMessage() {
    final checkIn = _todayRecord?.checkIn;
    final checkOut = _todayRecord?.checkOut;
    final checkInText = checkIn != null ? _fmtTod(checkIn) : '--:--';
    final checkOutText = checkOut != null ? _fmtTod(checkOut) : '--:--';
    return 'Check-in tercatat pukul $checkInText dan check-out pukul '
        '$checkOutText. Semua proses verifikasi wajah untuk hari ini sudah selesai.';
  }

  String _completedAttendanceFooter() {
    final hour = DateTime.now().hour;
    if (hour >= 17) return 'Terima kasih, selamat beristirahat';
    if (hour >= 12) return 'Terima kasih, semoga harimu lancar';
    return 'Terima kasih, sampai jumpa lagi';
  }

  // ── Action button ─────────────────────────────────────────────────────────

  Widget _buildActionButton() {
    if (_isCheckedOut) {
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.check_circle_rounded, size: 20),
          label: const Text('Presensi Selesai',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.successLight,
            foregroundColor: AppColors.success,
            disabledBackgroundColor: AppColors.successLight,
            disabledForegroundColor: AppColors.success,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    if (kIsWeb) {
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: _processing ? null : _handleButtonTap,
          icon: Icon(_isCheckedIn ? Icons.logout_rounded : Icons.login_rounded, size: 20),
          label: Text(
            _processing ? 'Memproses…' : (_isCheckedIn ? 'Check-Out Manual' : 'Check-In Manual'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isCheckedIn ? AppColors.error : AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    // Mode live: tombol aktif hanya kalau wajah sudah dikenali.
    final canPress = _liveRecognized && !_processing;
    final label = _processing
        ? 'Memproses…'
        : (_liveRecognized
            ? (_isCheckedIn ? 'Konfirmasi Check-Out' : 'Konfirmasi Check-In')
            : (_isCheckedIn ? 'Menunggu verifikasi wajah...' : 'Menunggu verifikasi wajah...'));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: canPress ? _handleButtonTap : null,
        icon: Icon(
          _liveRecognized
              ? (_isCheckedIn ? Icons.logout_rounded : Icons.login_rounded)
              : Icons.face_retouching_natural_rounded,
          size: 20,
        ),
        label: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isCheckedIn ? AppColors.error : AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textSecondary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _fmtTod(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';


  String _todayLabel() {
    final now = DateTime.now();
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }
}

/// Embedding yang berhasil dikenali, disimpan sampai user tekan tombol.
class _RecognizedFrame {
  final List<double> queryEmbedding;
  const _RecognizedFrame({required this.queryEmbedding});
}
