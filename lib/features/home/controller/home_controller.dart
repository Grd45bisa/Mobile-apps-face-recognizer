import 'package:flutter/material.dart';
import '../../../shared/models/app_models.dart';
import '../../../shared/services/attendance_service.dart';
import '../../../shared/services/reminder_service.dart';
import '../../../shared/services/worklog_service.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/store/app_store.dart';

enum HomeLoadState { loading, success, error }

class HomeController extends ChangeNotifier {
  HomeLoadState _state = HomeLoadState.loading;
  String? _errorMessage;
  bool _disposed = false;

  HomeLoadState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == HomeLoadState.loading;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  // Semua data dibaca dari AppStore yang sudah di-load saat login.
  // Controller ini hanya memastikan data hari ini dan minggu ini tersedia,
  // lalu refresh dari Supabase jika AppStore belum punya data hari ini.

  Future<void> loadData() async {
    _state = HomeLoadState.loading;
    notifyListeners();

    final uid = AuthService.instance.currentUserId;
    if (uid == null) {
      _state = HomeLoadState.error;
      _errorMessage = 'Sesi tidak ditemukan. Silakan masuk kembali.';
      notifyListeners();
      return;
    }

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Fetch data yang belum ada di AppStore (fresh load atau bulan berganti)
      final futures = <Future>[
        // Attendance: fetch hari ini + minggu ini sekaligus
        AttendanceService.instance.fetchWeekRecords(uid, today),
        // Worklogs hari ini
        WorklogService.instance.fetchDayWorklogs(uid, today),
        // Reminder hari ini
        ReminderService.instance.fetchTodayReminders(uid),
      ];

      final results = await Future.wait(futures);

      if (_disposed) return;

      // Simpan ke AppStore agar UI reaktif lewat ListenableBuilder
      final weekRecords = results[0] as List<AttendanceRecord>;
      for (final r in weekRecords) {
        AppStore.instance.setAttendance(r);
      }

      final todayWorklogs = results[1] as List<WorklogEntry>;
      AppStore.instance.setWorklogsForDay(today, todayWorklogs);

      final todayReminders = results[2] as List<ReminderEvent>;
      // Hapus dulu agar tidak duplikasi, lalu re-add
      for (final old in List.of(AppStore.instance.remindersOf(today))) {
        AppStore.instance.removeReminder(old);
      }
      for (final r in todayReminders) {
        AppStore.instance.addReminder(r);
      }

      _state = HomeLoadState.success;
      _errorMessage = null;
    } catch (e) {
      if (_disposed) return;

      // Jika AppStore sudah punya data (misalnya dari loadFromCloud), tetap
      // tampilkan data yang ada dan mark sebagai success.
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final hasAnyData =
          AppStore.instance.attendanceOf(today) != null ||
          AppStore.instance.worklogsOf(today).isNotEmpty;

      if (hasAnyData) {
        _state = HomeLoadState.success;
        _errorMessage = null;
      } else {
        _state = HomeLoadState.error;
        _errorMessage = 'Gagal memuat data. Coba lagi.';
      }
    }

    notifyListeners();
  }

  Future<void> refresh() => loadData();
}
