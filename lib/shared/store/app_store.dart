import 'package:flutter/material.dart';
import '../models/app_models.dart';

class AppStore extends ChangeNotifier {
  static final AppStore instance = AppStore._();
  AppStore._() {
    _seed();
  }

  // ─── SETTINGS ─────────────────────────────────────────────────────────────

  WorkScheduleSettings _settings = WorkScheduleSettings.defaults();
  WorkScheduleSettings get settings => _settings;

  void updateSettings(WorkScheduleSettings s) {
    _settings = s;
    notifyListeners();
  }

  // ─── ATTENDANCE ───────────────────────────────────────────────────────────

  final Map<String, AttendanceRecord> _attendance = {};

  static String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  AttendanceRecord? attendanceOf(DateTime d) => _attendance[dateKey(d)];

  Map<String, AttendanceRecord> get allAttendance =>
      Map.unmodifiable(_attendance);

  void setAttendance(AttendanceRecord record) {
    _attendance[dateKey(record.date)] = record;
    notifyListeners();
  }

  void removeAttendance(DateTime date) {
    _attendance.remove(dateKey(date));
    notifyListeners();
  }

  // ─── WORKLOGS ─────────────────────────────────────────────────────────────

  final Map<String, List<WorklogEntry>> _worklogs = {};

  List<WorklogEntry> worklogsOf(DateTime d) =>
      List.unmodifiable(_worklogs[dateKey(d)] ?? []);

  Map<String, List<WorklogEntry>> get allWorklogs => Map.unmodifiable(
    _worklogs.map(
      (key, value) => MapEntry(key, List<WorklogEntry>.unmodifiable(value)),
    ),
  );

  void addWorklog(WorklogEntry entry) {
    final key = dateKey(entry.date);
    _worklogs[key] = [...(_worklogs[key] ?? []), entry];
    notifyListeners();
  }

  void upsertWorklog(WorklogEntry entry) {
    for (final key in _worklogs.keys.toList()) {
      final filtered = _worklogs[key]!.where((e) => e.id != entry.id).toList();
      if (filtered.length != _worklogs[key]!.length) {
        if (filtered.isEmpty) {
          _worklogs.remove(key);
        } else {
          _worklogs[key] = filtered;
        }
      }
    }

    final key = dateKey(entry.date);
    _worklogs[key] = [...(_worklogs[key] ?? []), entry];
    notifyListeners();
  }

  void setWorklogsForDay(DateTime date, List<WorklogEntry> entries) {
    _worklogs[dateKey(date)] = entries;
    notifyListeners();
  }

  void removeWorklog(String id) {
    var changed = false;

    for (final key in _worklogs.keys.toList()) {
      final filtered = _worklogs[key]!.where((e) => e.id != id).toList();
      if (filtered.length != _worklogs[key]!.length) {
        changed = true;
        if (filtered.isEmpty) {
          _worklogs.remove(key);
        } else {
          _worklogs[key] = filtered;
        }
      }
    }

    if (changed) notifyListeners();
  }

  // ─── REMINDERS ────────────────────────────────────────────────────────────

  final Map<String, List<ReminderEvent>> _reminders = {};

  List<ReminderEvent> remindersOf(DateTime d) =>
      List.unmodifiable(_reminders[dateKey(d)] ?? []);

  void addReminder(ReminderEvent event) {
    final key = dateKey(event.startDateTime);
    _reminders[key] = [...(_reminders[key] ?? []), event];
    notifyListeners();
  }

  void updateReminder(ReminderEvent event) {
    final key = dateKey(event.startDateTime);
    final list = _reminders[key] ?? [];
    final idx = list.indexWhere((e) => e.id == event.id);
    if (idx >= 0) {
      _reminders[key] = [
        ...list.sublist(0, idx),
        event,
        ...list.sublist(idx + 1),
      ];
      notifyListeners();
    }
  }

  void removeReminder(ReminderEvent event) {
    final key = dateKey(event.startDateTime);
    _reminders[key] = (_reminders[key] ?? [])
        .where((e) => e.id != event.id)
        .toList();
    notifyListeners();
  }

  // ─── DERIVED DAY STATE ────────────────────────────────────────────────────

  DayDisplayState dayStateOf(DateTime day) {
    final todayNorm = _todayNorm();
    final dayNorm = DateTime(day.year, day.month, day.day);
    final isOffDay = _settings.offDays.contains(day.weekday);
    final record = attendanceOf(day);
    final isFuture = dayNorm.isAfter(todayNorm);

    if (record != null) {
      if (record.status == AttendanceStatus.present) {
        return isOffDay
            ? DayDisplayState.workedOnOffDay
            : DayDisplayState.presentWorkday;
      }
      return DayDisplayState.manualException;
    }

    if (isOffDay) return DayDisplayState.offDay;

    if (isFuture) return DayDisplayState.futureDay;

    final isToday = dayNorm == todayNorm;
    if (!isToday && _settings.autoMarkMissingAttendance) {
      return DayDisplayState.missingAttendance;
    }

    return DayDisplayState.futureDay;
  }

  DateTime _todayNorm() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // ─── MONTH STATS ──────────────────────────────────────────────────────────

  ({int present, int missing, int offDay, int reminders}) monthStatsOf(
    DateTime month,
  ) {
    int present = 0, missing = 0, offDay = 0, reminders = 0;

    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final today = _todayNorm();

    for (var d = 1; d <= daysInMonth; d++) {
      final day = DateTime(month.year, month.month, d);
      if (day.isAfter(today)) break;
      switch (dayStateOf(day)) {
        case DayDisplayState.presentWorkday:
        case DayDisplayState.workedOnOffDay:
          present++;
          break;
        case DayDisplayState.missingAttendance:
          missing++;
          break;
        case DayDisplayState.offDay:
          offDay++;
          break;
        default:
          break;
      }
    }

    for (final list in _reminders.values) {
      for (final r in list) {
        if (r.startDateTime.year == month.year &&
            r.startDateTime.month == month.month) {
          reminders++;
        }
      }
    }

    return (
      present: present,
      missing: missing,
      offDay: offDay,
      reminders: reminders,
    );
  }

  // ─── WEEK ATTENDANCE ──────────────────────────────────────────────────────

  /// Returns attendance states for Mon–Sun of the week containing [day].
  List<({DateTime date, DayDisplayState state})> weekStatesOf(DateTime day) {
    final monday = day.subtract(Duration(days: day.weekday - 1));
    return List.generate(7, (i) {
      final d = monday.add(Duration(days: i));
      return (date: d, state: dayStateOf(d));
    });
  }

  // ─── SEED ─────────────────────────────────────────────────────────────────

  void _seed() {
    final now = DateTime.now();

    void putAttendance(
      int dayOfMonth,
      AttendanceStatus s, {
      TimeOfDay? cin,
      TimeOfDay? cout,
      String? note,
    }) {
      final d = DateTime(now.year, now.month, dayOfMonth);
      _attendance[dateKey(d)] = AttendanceRecord(
        id: 'seed-$dayOfMonth',
        date: d,
        source: AttendanceSource.face,
        status: s,
        checkIn: cin,
        checkOut: cout,
        note: note,
      );
    }

    putAttendance(
      1,
      AttendanceStatus.present,
      cin: const TimeOfDay(hour: 8, minute: 5),
      cout: const TimeOfDay(hour: 17, minute: 10),
    );
    putAttendance(
      2,
      AttendanceStatus.present,
      cin: const TimeOfDay(hour: 8, minute: 15),
      cout: const TimeOfDay(hour: 17, minute: 0),
    );
    putAttendance(3, AttendanceStatus.leave, note: 'Urusan keluarga');
    putAttendance(
      6,
      AttendanceStatus.present,
      cin: const TimeOfDay(hour: 8, minute: 0),
      cout: const TimeOfDay(hour: 17, minute: 30),
    );
    putAttendance(7, AttendanceStatus.sick, note: 'Flu');
    putAttendance(
      8,
      AttendanceStatus.present,
      cin: const TimeOfDay(hour: 8, minute: 20),
      cout: const TimeOfDay(hour: 17, minute: 5),
    );
    putAttendance(9, AttendanceStatus.training, note: 'Workshop Flutter');
    putAttendance(10, AttendanceStatus.holiday, note: 'Cuti bersama');

    // Seed today with check-in only
    final today = DateTime(now.year, now.month, now.day);
    if (_attendance[dateKey(today)] == null) {
      _attendance[dateKey(today)] = AttendanceRecord(
        id: 'today',
        date: today,
        source: AttendanceSource.face,
        status: AttendanceStatus.present,
        checkIn: const TimeOfDay(hour: 8, minute: 15),
      );
    }

    // Seed worklogs for today
    _worklogs[dateKey(today)] = [
      WorklogEntry(
        id: 'wl-1',
        date: today,
        taskName: 'Review design mockup',
        projectName: 'Mobile App',
        projectColor: const Color(0xFF1565C0),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 30),
        duration: '1j 30m',
      ),
      WorklogEntry(
        id: 'wl-2',
        date: today,
        taskName: 'Meeting sprint planning',
        projectName: 'Internal',
        projectColor: const Color(0xFFFF8F00),
        startTime: const TimeOfDay(hour: 10, minute: 30),
        endTime: const TimeOfDay(hour: 12, minute: 30),
        duration: '2j 00m',
      ),
      WorklogEntry(
        id: 'wl-3',
        date: today,
        taskName: 'Update dokumentasi API',
        projectName: 'Backend',
        projectColor: const Color(0xFF7B61FF),
        startTime: const TimeOfDay(hour: 13, minute: 0),
        endTime: const TimeOfDay(hour: 13, minute: 45),
        duration: '45m',
      ),
    ];

    // Seed reminder for today
    final todayMeeting = DateTime(now.year, now.month, now.day, 14, 0);
    _reminders[dateKey(today)] = [
      ReminderEvent(
        id: 'rem-1',
        title: 'Sprint Review',
        description: 'Demo fitur baru kepada stakeholder',
        startDateTime: todayMeeting,
        endDateTime: todayMeeting.add(const Duration(hours: 1)),
        reminderOffsetsInMinutes: [15, 5],
      ),
    ];
  }
}
