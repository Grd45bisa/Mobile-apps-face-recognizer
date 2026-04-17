import 'dart:async';
import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/models/app_models.dart';
import '../../../shared/store/app_store.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  MODELS
// ═══════════════════════════════════════════════════════════════════════════

class Project {
  final String id;
  final String name;
  final Color color;
  const Project({required this.id, required this.name, required this.color});
}

class TimeEntry {
  final String id;
  final String taskName;
  final Project project;
  final DateTime startTime;
  final DateTime endTime;

  const TimeEntry({
    required this.id,
    required this.taskName,
    required this.project,
    required this.startTime,
    required this.endTime,
  });

  Duration get duration => endTime.difference(startTime);

  TimeEntry copyWith({
    String? taskName,
    Project? project,
    DateTime? startTime,
    DateTime? endTime,
  }) => TimeEntry(
    id: id,
    taskName: taskName ?? this.taskName,
    project: project ?? this.project,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
  );
}

// ═══════════════════════════════════════════════════════════════════════════
//  SCREEN
// ═══════════════════════════════════════════════════════════════════════════

class TimesheetScreen extends StatefulWidget {
  const TimesheetScreen({super.key});

  @override
  State<TimesheetScreen> createState() => _TimesheetScreenState();
}

class _TimesheetScreenState extends State<TimesheetScreen> {
  final _store = AppStore.instance;

  final List<Project> _projects = [
    const Project(id: '1', name: 'Ruang360', color: AppColors.primary),
    const Project(id: '2', name: 'Personal Assistant', color: AppColors.error),
    const Project(id: '3', name: 'FaceWork Tracker', color: Color(0xFF7B61FF)),
    const Project(id: '4', name: 'Internal', color: AppColors.warning),
    const Project(
      id: '5',
      name: 'Tanpa Project',
      color: AppColors.textSecondary,
    ),
  ];

  static const List<Color> _projectColorPalette = [
    AppColors.primary,
    AppColors.success,
    AppColors.error,
    AppColors.warning,
    Color(0xFF7B61FF),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
    Color(0xFFF97316),
    Color(0xFF6366F1),
    AppColors.textSecondary,
  ];

  // Timer state
  bool _isRunning = false;
  DateTime? _startTime;
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  Project _activeProject = const Project(
    id: '5',
    name: 'Tanpa Project',
    color: AppColors.textSecondary,
  );
  final TextEditingController _taskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _seedEntries();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _taskController.dispose();
    super.dispose();
  }

  // ─── SEED ──────────────────────────────────────────────────────────────

  void _seedEntries() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final y1 = today.subtract(const Duration(days: 1));
    final y2 = today.subtract(const Duration(days: 2));

    final seedEntries = [
      TimeEntry(
        id: 'e1',
        taskName: 'Review design mockup dashboard',
        project: _projects[0],
        startTime: today.add(const Duration(hours: 9)),
        endTime: today.add(const Duration(hours: 10, minutes: 30)),
      ),
      TimeEntry(
        id: 'e2',
        taskName: 'Meeting sprint planning',
        project: _projects[3],
        startTime: today.add(const Duration(hours: 10, minutes: 30)),
        endTime: today.add(const Duration(hours: 12, minutes: 30)),
      ),
      TimeEntry(
        id: 'e3',
        taskName: 'Update dokumentasi API endpoint',
        project: _projects[0],
        startTime: today.add(const Duration(hours: 13, minutes: 30)),
        endTime: today.add(const Duration(hours: 14, minutes: 15)),
      ),
      TimeEntry(
        id: 'e4',
        taskName: 'Implementasi face recognition pipeline',
        project: _projects[2],
        startTime: y1.add(const Duration(hours: 9, minutes: 30)),
        endTime: y1.add(const Duration(hours: 12)),
      ),
      TimeEntry(
        id: 'e5',
        taskName: 'Bersih bersih rumah',
        project: _projects[1],
        startTime: y1.add(const Duration(hours: 14)),
        endTime: y1.add(const Duration(hours: 16, minutes: 30)),
      ),
      TimeEntry(
        id: 'e6',
        taskName: 'Refactor auth middleware',
        project: _projects[0],
        startTime: y2.add(const Duration(hours: 10)),
        endTime: y2.add(const Duration(hours: 13)),
      ),
      TimeEntry(
        id: 'e7',
        taskName: 'Bikin unit test login flow',
        project: _projects[2],
        startTime: y2.add(const Duration(hours: 14)),
        endTime: y2.add(const Duration(hours: 15, minutes: 45)),
      ),
    ];

    for (final entry in seedEntries) {
      if (_hasWorklog(entry.id)) continue;
      _store.addWorklog(_toWorklogEntry(entry));
    }
  }

  // ─── TIMER ─────────────────────────────────────────────────────────────

  void _startTimer() {
    setState(() {
      _isRunning = true;
      _startTime = DateTime.now();
      _elapsed = Duration.zero;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed = DateTime.now().difference(_startTime!);
      });
    });
  }

  void _stopTimer() {
    if (_startTime == null) return;
    _ticker?.cancel();
    final capturedStart = _startTime!;
    final capturedEnd = DateTime.now();
    _showSaveTimerSheet(capturedStart, capturedEnd);
  }

  void _resumeTickerAfterCancel(DateTime start) {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed = DateTime.now().difference(start));
    });
  }

  void _showSaveTimerSheet(DateTime capturedStart, DateTime capturedEnd) {
    final taskCtrl = TextEditingController(text: _taskController.text.trim());
    Project project = _activeProject;
    bool saved = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final dur = capturedEnd.difference(capturedStart);
            return Padding(
              padding: EdgeInsets.only(
                top: 12,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.stop_circle_rounded,
                            color: AppColors.success,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Simpan Entry',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDurationLong(dur),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_timeHm(capturedStart)} - ${_timeHm(capturedEnd)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 18),

                    _sheetLabel('Nama tugas'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: taskCtrl,
                      autofocus: taskCtrl.text.isEmpty,
                      decoration: _sheetInput('Mis. Review dokumen'),
                    ),
                    const SizedBox(height: 14),

                    _sheetLabel('Project'),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => _showProjectPicker(
                        onPick: (p) => setSheet(() => project = p),
                      ),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: project.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                project.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              side: const BorderSide(color: AppColors.border),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Lanjutkan Timer',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              if (taskCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Isi nama tugasnya'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }
                              if (project.id == '5') {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Pilih project dulu'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }
                              saved = true;
                              final entry = TimeEntry(
                                id: DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                                taskName: taskCtrl.text.trim(),
                                project: project,
                                startTime: capturedStart,
                                endTime: capturedEnd,
                              );
                              _store.addWorklog(_toWorklogEntry(entry));
                              setState(() {
                                _isRunning = false;
                                _startTime = null;
                                _elapsed = Duration.zero;
                                _taskController.clear();
                                _activeProject = _projects[4];
                              });
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Tersimpan · ${_formatDurationLong(entry.duration)}',
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Simpan Entry',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      if (!saved) {
        _taskController.text = taskCtrl.text;
        setState(() {
          _activeProject = project;
          _elapsed = DateTime.now().difference(capturedStart);
        });
        _resumeTickerAfterCancel(capturedStart);
      }
      taskCtrl.dispose();
    });
  }

  String _timeHm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Future<void> _changeStartTime() async {
    if (!_isRunning || _startTime == null) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startTime!),
      helpText: 'Ubah jam mulai',
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    final now = DateTime.now();
    var newStart = DateTime(
      now.year,
      now.month,
      now.day,
      picked.hour,
      picked.minute,
    );
    if (newStart.isAfter(now)) {
      newStart = newStart.subtract(const Duration(days: 1));
    }
    setState(() {
      _startTime = newStart;
      _elapsed = DateTime.now().difference(newStart);
    });
  }

  // ─── ENTRY OPS ─────────────────────────────────────────────────────────

  void _deleteEntry(TimeEntry e) {
    _store.removeWorklog(e.id);
  }

  void _continueEntry(TimeEntry e) {
    if (_isRunning) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hentikan timer yang aktif dulu'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      _taskController.text = e.taskName;
      _activeProject = e.project;
    });
    _startTimer();
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Text(
              'Tracker',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (_isRunning) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Sedang aktif',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showManualEntrySheet,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.edit_calendar_rounded),
        label: const Text(
          'Manual',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          final entries = _entries;
          final grouped = _groupByDate(entries);
          final sortedDates = grouped.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return Column(
            children: [
              _buildTimerBar(),
              Expanded(
                child: entries.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
                        itemCount: sortedDates.length,
                        itemBuilder: (context, i) {
                          final date = sortedDates[i];
                          final items = grouped[date]!
                            ..sort(
                              (a, b) => b.startTime.compareTo(a.startTime),
                            );
                          return _buildDateGroup(date, items);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── TIMER BAR ─────────────────────────────────────────────────────────

  Widget _buildTimerBar() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            // Row 1: task input + project
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _taskController,
                      enabled: !_isRunning,
                      decoration: const InputDecoration(
                        hintText: 'Apa yang kamu kerjakan?',
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _isRunning ? null : _showProjectPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _activeProject.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _activeProject.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _activeProject.name,
                            style: TextStyle(
                              fontSize: 11,
                              color: _activeProject.color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (!_isRunning) ...[
                            const SizedBox(width: 2),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              size: 16,
                              color: _activeProject.color,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            // Row 2: timer display + start/stop
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _isRunning ? _changeStartTime : null,
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _formatDurationClock(_elapsed),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: _isRunning
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                              if (_isRunning) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.edit_rounded,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                              ],
                            ],
                          ),
                          if (_isRunning && _startTime != null)
                            Text(
                              'Mulai: ${_formatHHMM(_startTime!)}  ·  tap untuk ubah',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            )
                          else
                            const Text(
                              'Isi nama tugas lalu tekan MULAI',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: _isRunning ? _stopTimer : _startTimer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRunning
                            ? AppColors.error
                            : AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isRunning
                                ? Icons.stop_rounded
                                : Icons.play_arrow_rounded,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isRunning ? 'BERHENTI' : 'MULAI',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── WEEK SUMMARY ──────────────────────────────────────────────────────

  // ─── DATE GROUP + ENTRY CARD ───────────────────────────────────────────

  Widget _buildDateGroup(DateTime date, List<TimeEntry> items) {
    final total = items.fold<Duration>(Duration.zero, (p, e) => p + e.duration);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _dateLabel(date),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${items.length} aktivitas tercatat',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _formatDurationLong(total),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...items.map(_buildEntryCard),
      ],
    );
  }

  Widget _buildEntryCard(TimeEntry e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: e.project.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.taskName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        e.project.name,
                        style: TextStyle(
                          fontSize: 11,
                          color: e.project.color,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Text(
                      '  ·  ',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${_formatHHMM(e.startTime)} – ${_formatHHMM(e.endTime)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  _formatDurationLong(e.duration),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
            padding: EdgeInsets.zero,
            onSelected: (v) {
              if (v == 'continue') _continueEntry(e);
              if (v == 'edit') _showManualEntrySheet(editing: e);
              if (v == 'delete') _confirmDelete(e);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'continue',
                child: Row(
                  children: [
                    Icon(
                      Icons.play_arrow_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 10),
                    Text('Lanjutkan', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 10),
                    Text('Edit', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_rounded,
                      size: 16,
                      color: AppColors.error,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Hapus',
                      style: TextStyle(fontSize: 13, color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── EMPTY ─────────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.timer_outlined,
              size: 36,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Belum ada catatan waktu',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mulai timer di atas atau tekan tombol Manual untuk menambahkan entry pertama.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ─── PROJECT PICKER ────────────────────────────────────────────────────

  void _showProjectPicker({ValueChanged<Project>? onPick}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pilih Project',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.5,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: _projects
                          .map(
                            (p) => InkWell(
                              onTap: () {
                                Navigator.pop(ctx);
                                if (onPick != null) {
                                  onPick(p);
                                } else {
                                  setState(() => _activeProject = p);
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: p.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        p.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (_activeProject.id == p.id &&
                                        onPick == null)
                                      const Icon(
                                        Icons.check_rounded,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final created = await _showCreateProjectSheet(
                      rootCtx: context,
                    );
                    if (!mounted || created == null) return;
                    setSheet(() {});
                    if (onPick != null) {
                      Navigator.pop(context);
                      onPick(created);
                    } else {
                      setState(() => _activeProject = created);
                      Navigator.pop(context);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Tambah Project Baru',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.primary,
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
      ),
    );
  }

  // ─── CREATE PROJECT SHEET ──────────────────────────────────────────────

  Future<Project?> _showCreateProjectSheet({required BuildContext rootCtx}) {
    final nameCtrl = TextEditingController();
    Color selectedColor = _projectColorPalette.first;

    return showModalBottomSheet<Project>(
      context: rootCtx,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) => Padding(
            padding: EdgeInsets.only(
              top: 12,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.folder_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Project Baru',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _sheetLabel('Nama project'),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: _sheetInput('Mis. Website Client A'),
                ),
                const SizedBox(height: 18),

                _sheetLabel('Warna'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _projectColorPalette.map((c) {
                    final selected = c.toARGB32() == selectedColor.toARGB32();
                    return GestureDetector(
                      onTap: () => setSheet(() => selectedColor = c),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? AppColors.textPrimary : c,
                            width: selected ? 3 : 0,
                          ),
                        ),
                        child: selected
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 20,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Preview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Preview: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: selectedColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: selectedColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              nameCtrl.text.trim().isEmpty
                                  ? 'Nama project'
                                  : nameCtrl.text.trim(),
                              style: TextStyle(
                                fontSize: 11,
                                color: selectedColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Isi nama project dulu'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }
                      final newProject = Project(
                        id: 'p${DateTime.now().millisecondsSinceEpoch}',
                        name: name,
                        color: selectedColor,
                      );
                      setState(() => _projects.add(newProject));
                      Navigator.pop(ctx, newProject);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Simpan Project',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── MANUAL ENTRY SHEET ────────────────────────────────────────────────

  void _showManualEntrySheet({TimeEntry? editing}) {
    final taskCtrl = TextEditingController(text: editing?.taskName ?? '');
    Project project = editing?.project ?? _projects[4];
    DateTime date = editing?.startTime ?? DateTime.now();
    TimeOfDay start = editing != null
        ? TimeOfDay.fromDateTime(editing.startTime)
        : const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay end = editing != null
        ? TimeOfDay.fromDateTime(editing.endTime)
        : TimeOfDay.fromDateTime(DateTime.now());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            Duration calcDuration() {
              final s = DateTime(
                date.year,
                date.month,
                date.day,
                start.hour,
                start.minute,
              );
              var e = DateTime(
                date.year,
                date.month,
                date.day,
                end.hour,
                end.minute,
              );
              if (e.isBefore(s)) e = e.add(const Duration(days: 1));
              return e.difference(s);
            }

            final dur = calcDuration();

            return Padding(
              padding: EdgeInsets.only(
                top: 12,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.edit_calendar_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          editing == null ? 'Tambah Manual' : 'Edit Entry',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Task name
                    _sheetLabel('Nama tugas'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: taskCtrl,
                      decoration: _sheetInput('Mis. Review dokumen'),
                    ),
                    const SizedBox(height: 14),

                    // Project
                    _sheetLabel('Project'),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => _showProjectPicker(
                        onPick: (p) => setSheet(() => project = p),
                      ),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: project.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                project.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Date
                    _sheetLabel('Tanggal'),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: date,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setSheet(() => date = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _dateFull(date),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Start + End time
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sheetLabel('Jam Mulai'),
                              const SizedBox(height: 6),
                              _timeButton(ctx, start, (t) {
                                setSheet(() => start = t);
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sheetLabel('Jam Selesai'),
                              const SizedBox(height: 6),
                              _timeButton(ctx, end, (t) {
                                setSheet(() => end = t);
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Duration preview
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Total durasi:',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatDurationLong(dur),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (taskCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('Isi nama tugasnya'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          if (project.id == '5') {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('Pilih project dulu'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          if (calcDuration() <= Duration.zero) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('Durasi tidak boleh kosong'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          final s = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            start.hour,
                            start.minute,
                          );
                          var e = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            end.hour,
                            end.minute,
                          );
                          if (e.isBefore(s)) {
                            e = e.add(const Duration(days: 1));
                          }
                          final entry = TimeEntry(
                            id:
                                editing?.id ??
                                DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                            taskName: taskCtrl.text.trim(),
                            project: project,
                            startTime: s,
                            endTime: e,
                          );
                          _store.upsertWorklog(_toWorklogEntry(entry));
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          editing == null ? 'Simpan Entry' : 'Perbarui Entry',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _timeButton(
    BuildContext ctx,
    TimeOfDay t,
    ValueChanged<TimeOfDay> onPick,
  ) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: ctx,
          initialTime: t,
          builder: (c, child) => MediaQuery(
            data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
        );
        if (picked != null) onPick(picked);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.access_time_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Text(
              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
    ),
  );

  InputDecoration _sheetInput(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
    filled: true,
    fillColor: AppColors.background,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );

  // ─── DELETE CONFIRM ────────────────────────────────────────────────────

  void _confirmDelete(TimeEntry e) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Hapus entry?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          '"${e.taskName}" akan dihapus permanen.',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteEntry(e);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────

  List<TimeEntry> get _entries {
    final entries = <TimeEntry>[
      for (final dayEntries in _store.allWorklogs.values)
        for (final worklog in dayEntries) _toTimeEntry(worklog),
    ]..sort((a, b) => b.startTime.compareTo(a.startTime));
    return entries;
  }

  bool _hasWorklog(String id) {
    for (final dayEntries in _store.allWorklogs.values) {
      if (dayEntries.any((entry) => entry.id == id)) return true;
    }
    return false;
  }

  TimeEntry _toTimeEntry(WorklogEntry worklog) {
    final startTime = worklog.startTime ?? const TimeOfDay(hour: 0, minute: 0);
    final endTime = worklog.endTime ?? startTime;
    final project =
        _projects.cast<Project?>().firstWhere(
          (item) => item?.name == worklog.projectName,
          orElse: () => null,
        ) ??
        Project(
          id: 'project-${worklog.projectName}',
          name: worklog.projectName,
          color: worklog.projectColor,
        );

    return TimeEntry(
      id: worklog.id,
      taskName: worklog.taskName,
      project: project,
      startTime: DateTime(
        worklog.date.year,
        worklog.date.month,
        worklog.date.day,
        startTime.hour,
        startTime.minute,
      ),
      endTime: DateTime(
        worklog.date.year,
        worklog.date.month,
        worklog.date.day,
        endTime.hour,
        endTime.minute,
      ),
    );
  }

  WorklogEntry _toWorklogEntry(TimeEntry entry) {
    final date = DateTime(
      entry.startTime.year,
      entry.startTime.month,
      entry.startTime.day,
    );

    return WorklogEntry(
      id: entry.id,
      date: date,
      taskName: entry.taskName,
      projectName: entry.project.name,
      projectColor: entry.project.color,
      startTime: TimeOfDay.fromDateTime(entry.startTime),
      endTime: TimeOfDay.fromDateTime(entry.endTime),
      duration: _formatDurationLong(entry.duration),
    );
  }

  Map<DateTime, List<TimeEntry>> _groupByDate(List<TimeEntry> list) {
    final map = <DateTime, List<TimeEntry>>{};
    for (final e in list) {
      final d = DateTime(e.startTime.year, e.startTime.month, e.startTime.day);
      map.putIfAbsent(d, () => []).add(e);
    }
    return map;
  }

  String _formatDurationClock(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatDurationLong(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h == 0) return '${m}m';
    return '${h}j ${m.toString().padLeft(2, '0')}m';
  }

  String _formatHHMM(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _dateLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Hari Ini';
    if (diff == 1) return 'Kemarin';
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agt',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
  }

  String _dateFull(DateTime d) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
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
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
