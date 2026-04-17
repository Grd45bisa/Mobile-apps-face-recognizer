import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/models/app_models.dart';
import '../../../shared/store/app_store.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _store = AppStore.instance;

  DateTime get _today =>
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  AttendanceRecord? get _todayRecord => _store.attendanceOf(_today);

  bool get _isCheckedIn =>
      _todayRecord != null && _todayRecord!.checkIn != null;

  bool get _isCheckedOut =>
      _todayRecord != null && _todayRecord!.checkOut != null;

  void _handleCheckIn() {
    final now = TimeOfDay.now();
    final existing = _todayRecord;
    _store.setAttendance(AttendanceRecord(
      id: existing?.id ?? _today.millisecondsSinceEpoch.toString(),
      date: _today,
      source: AttendanceSource.face,
      status: AttendanceStatus.present,
      checkIn: now,
      checkOut: existing?.checkOut,
    ));
    setState(() {});
  }

  void _handleCheckOut() {
    final existing = _todayRecord;
    if (existing == null) return;
    _store.setAttendance(existing.copyWith(checkOut: TimeOfDay.now()));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                children: [
                  _buildStatusSummary(),
                  const SizedBox(height: 14),
                  Expanded(child: _buildCameraArea()),
                  const SizedBox(height: 14),
                  _buildSupportingInfo(),
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

  // ─── APP BAR ─────────────────────────────────────────────────────────────

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
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  (String, Color, Color) _statusStyle() {
    if (_isCheckedOut) {
      return ('Selesai', AppColors.success, AppColors.successLight);
    }
    if (_isCheckedIn) {
      return ('Sudah Check-In', AppColors.warning, AppColors.warningLight);
    }
    return ('Belum Hadir', AppColors.missing, AppColors.missingLight);
  }

  // ─── STATUS SUMMARY ──────────────────────────────────────────────────────

  Widget _buildStatusSummary() {
    final record = _todayRecord;
    final cin = record?.checkIn;
    final cout = record?.checkOut;

    final cinText = cin != null ? _fmtTod(cin) : '--:--';
    final coutText = cout != null ? _fmtTod(cout) : '--:--';
    final duration = (cin != null && cout != null)
        ? _duration(cin, cout)
        : '--j --m';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _summarySlot(
              icon: Icons.login_rounded,
              iconColor: cin != null ? AppColors.success : AppColors.textSecondary,
              iconBg: cin != null ? AppColors.successLight : AppColors.background,
              label: 'Check-in',
              value: cinText,
              valueColor: cin != null
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
          _verticalDivider(),
          Expanded(
            child: _summarySlot(
              icon: Icons.logout_rounded,
              iconColor: cout != null ? AppColors.error : AppColors.textSecondary,
              iconBg: cout != null ? AppColors.errorLight : AppColors.background,
              label: 'Check-out',
              value: coutText,
              valueColor: cout != null
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
          _verticalDivider(),
          Expanded(
            child: _summarySlot(
              icon: Icons.schedule_rounded,
              iconColor: AppColors.primary,
              iconBg: AppColors.primaryLight,
              label: 'Durasi',
              value: duration,
              valueColor: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summarySlot({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: valueColor,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider() => Container(
        width: 1,
        height: 42,
        color: AppColors.border,
        margin: const EdgeInsets.symmetric(horizontal: 4),
      );

  // ─── CAMERA AREA ─────────────────────────────────────────────────────────

  Widget _buildCameraArea() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.face_retouching_natural_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verifikasi Wajah',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'Posisikan wajah di dalam area oval',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Siap',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Oval face frame
                  CustomPaint(
                    size: const Size(double.infinity, double.infinity),
                    painter: _OvalFramePainter(),
                  ),
                  // Face silhouette icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.person_rounded,
                      size: 72,
                      color: AppColors.primary,
                    ),
                  ),
                  // Bottom instruction chip
                  Positioned(
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _cameraHint(),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _cameraHint() {
    if (_isCheckedOut) return 'Presensi hari ini sudah selesai';
    if (_isCheckedIn) return 'Tap untuk memulai check-out';
    return 'Arahkan wajah ke kamera';
  }

  // ─── SUPPORTING INFO ─────────────────────────────────────────────────────

  Widget _buildSupportingInfo() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _infoItem(
              icon: Icons.verified_user_rounded,
              label: 'Metode',
              value: 'Face Recognition',
            ),
          ),
          _infoDivider(),
          Expanded(
            child: _infoItem(
              icon: Icons.location_on_rounded,
              label: 'Lokasi',
              value: 'Kantor Pusat',
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoDivider() => Container(
        width: 1,
        height: 28,
        color: AppColors.border,
        margin: const EdgeInsets.symmetric(horizontal: 8),
      );

  // ─── ACTION BUTTON ───────────────────────────────────────────────────────

  Widget _buildActionButton() {
    VoidCallback? onPressed;
    IconData icon;
    String label;
    Color bg;

    if (_isCheckedOut) {
      onPressed = null;
      icon = Icons.check_circle_rounded;
      label = 'Presensi Selesai';
      bg = AppColors.success;
    } else if (_isCheckedIn) {
      onPressed = _handleCheckOut;
      icon = Icons.logout_rounded;
      label = 'Check-Out Sekarang';
      bg = AppColors.error;
    } else {
      onPressed = _handleCheckIn;
      icon = Icons.login_rounded;
      label = 'Check-In Sekarang';
      bg = AppColors.primary;
    }

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.successLight,
          disabledForegroundColor: AppColors.success,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────

  String _fmtTod(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _duration(TimeOfDay a, TimeOfDay b) {
    var mins = (b.hour * 60 + b.minute) - (a.hour * 60 + a.minute);
    if (mins < 0) mins += 24 * 60;
    if (mins <= 0) return '0j 00m';
    return '${mins ~/ 60}j ${(mins % 60).toString().padLeft(2, '0')}m';
  }

  String _todayLabel() {
    final now = DateTime.now();
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }
}

class _OvalFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.62,
      height: size.height * 0.78,
    );

    // Dashed oval outline
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.35)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    _drawDashedOval(canvas, rect, paint);

    // Corner brackets around the oval
    final bracketPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double len = 18;
    final outer = rect.inflate(8);

    // Top-left
    canvas.drawLine(
      Offset(outer.left, outer.top + len),
      Offset(outer.left, outer.top),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(outer.left, outer.top),
      Offset(outer.left + len, outer.top),
      bracketPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(outer.right - len, outer.top),
      Offset(outer.right, outer.top),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(outer.right, outer.top),
      Offset(outer.right, outer.top + len),
      bracketPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(outer.left, outer.bottom - len),
      Offset(outer.left, outer.bottom),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(outer.left, outer.bottom),
      Offset(outer.left + len, outer.bottom),
      bracketPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(outer.right - len, outer.bottom),
      Offset(outer.right, outer.bottom),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(outer.right, outer.bottom),
      Offset(outer.right, outer.bottom - len),
      bracketPaint,
    );
  }

  void _drawDashedOval(Canvas canvas, Rect rect, Paint paint) {
    final path = Path()..addOval(rect);
    const dashLen = 6.0;
    const gapLen = 5.0;
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        final extract = metric.extractPath(dist, dist + dashLen);
        canvas.drawPath(extract, paint);
        dist += dashLen + gapLen;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
