import 'package:flutter/material.dart';

import '../../profile/presentation/profile_screen.dart';
import '../../../shared/models/app_models.dart';
import '../../../shared/store/app_store.dart';
import '../../../shared/theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListenableBuilder(
        listenable: AppStore.instance,
        builder: (context, _) {
          return NestedScrollView(
            headerSliverBuilder: (context, _) => [
              _buildAppBar(context),
            ],
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _buildGreeting(),
                const SizedBox(height: 16),
                _buildAttendanceCard(),
                const SizedBox(height: 12),
                _buildWeekProgress(),
                const SizedBox(height: 12),
                _buildReminderHighlight(),
                const SizedBox(height: 20),
                _buildSectionLabel('Ringkasan Tracker'),
                const SizedBox(height: 8),
                _buildTrackerSummary(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildSectionLabel('Aktivitas Hari Ini')),
                    const _InlineLink(label: 'Lihat semua'),
                  ],
                ),
                const SizedBox(height: 8),
                _buildTrackerHistory(),
              ],
            ),
          );
        },
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    final reminders = AppStore.instance.remindersOf(_todayDate());
    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 16,
      title: const Text(
        'FaceWork',
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.border),
      ),
      actions: [
        IconButton(
          onPressed: () {},
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.textPrimary,
                size: 24,
              ),
              if (reminders.isNotEmpty)
                Positioned(
                  right: -1,
                  top: -1,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.surface, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      reminders.length > 9 ? '9+' : '${reminders.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          ),
          child: Container(
            margin: const EdgeInsets.only(right: 16, left: 4),
            child: const CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                'P',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greetingText(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _todayLabel(),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _workStatusBg(),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 7, color: _workStatusColor()),
              const SizedBox(width: 5),
              Text(
                _workStatusLabel(),
                style: TextStyle(
                  color: _workStatusColor(),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }


  Widget _buildReminderHighlight() {
    final reminders = AppStore.instance.remindersOf(_todayDate());
    if (reminders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.event_available_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tidak ada pengingat hari ini',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Kalau ada acara dari kalender, detailnya akan muncul di sini.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final nextReminder = reminders.first;
    final extraCount = reminders.length - 1;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: AppColors.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pengingat Hari Ini',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Supaya user langsung tahu ada agenda atau tidak.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (extraCount > 0)
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
                    '+$extraCount lagi',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nextReminder.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      nextReminder.isAllDay
                          ? 'Seharian'
                          : _formatReminderTime(nextReminder),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (nextReminder.description != null &&
                    nextReminder.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    nextReminder.description!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard() {
    final record = AppStore.instance.attendanceOf(_todayDate());
    final hasCheckin = record?.checkIn != null;
    final hasCheckout = record?.checkOut != null;

    final cinTime = hasCheckin ? _fmtTod(record!.checkIn!) : '--:--';
    final coutTime = hasCheckout ? _fmtTod(record!.checkOut!) : '--:--';
    final cinSub = hasCheckin ? 'Tercatat' : 'Belum check-in';
    final coutSub = hasCheckout ? 'Tercatat' : 'Belum checkout';

    String statusLabel;
    Color statusColor;
    Color statusBg;

    if (record == null) {
      statusLabel = 'Belum Hadir';
      statusColor = AppColors.missing;
      statusBg = AppColors.missingLight;
    } else if (record.status != AttendanceStatus.present) {
      final style = _exceptionLabel(record.status);
      statusLabel = style.$1;
      statusColor = style.$2;
      statusBg = style.$3;
    } else if (hasCheckin) {
      statusLabel = 'Hadir';
      statusColor = AppColors.success;
      statusBg = AppColors.successLight;
    } else {
      statusLabel = 'Belum Hadir';
      statusColor = AppColors.missing;
      statusBg = AppColors.missingLight;
    }

    final totalTime = (hasCheckin && hasCheckout)
        ? _duration(record!.checkIn!, record.checkOut!)
        : '-- j -- m';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kehadiran Hari Ini',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Lihat status presensi dan jam kerja hari ini',
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
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 7, color: statusColor),
                      const SizedBox(width: 5),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildTimeSlot(
                    label: 'Check-in',
                    time: cinTime,
                    sub: cinSub,
                    icon: Icons.login_rounded,
                    color: hasCheckin
                        ? AppColors.success
                        : AppColors.textSecondary,
                    bgColor: hasCheckin
                        ? AppColors.successLight
                        : AppColors.background,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTimeSlot(
                    label: 'Check-out',
                    time: coutTime,
                    sub: coutSub,
                    icon: Icons.logout_rounded,
                    color: hasCheckout
                        ? AppColors.error
                        : AppColors.textSecondary,
                    bgColor: hasCheckout
                        ? AppColors.errorLight
                        : AppColors.background,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _footerMeta(Icons.location_on_rounded, 'Kantor Pusat, Jakarta'),
                _footerMeta(Icons.schedule_rounded, 'Total: $totalTime'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerMeta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlot({
    required String label,
    required String time,
    required String sub,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekProgress() {
    final store = AppStore.instance;
    final today = _todayDate();
    final weekStates = store.weekStatesOf(today);
    const dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final presentCount = weekStates
        .where(
          (w) =>
              w.state == DayDisplayState.presentWorkday ||
              w.state == DayDisplayState.workedOnOffDay,
        )
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kehadiran Minggu Ini',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Progress kehadiran untuk 7 hari minggu ini',
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
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$presentCount / 7 hari',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final info = weekStates[i];
              final isToday = _isSameDay(info.date, today);
              final state = info.state;

              IconData icon;
              Color iconColor;
              Color bgColor;
              Color borderColor;

              if (isToday) {
                icon = Icons.access_time_rounded;
                iconColor = Colors.white;
                bgColor = AppColors.primary;
                borderColor = AppColors.primary;
              } else if (state == DayDisplayState.presentWorkday ||
                  state == DayDisplayState.workedOnOffDay) {
                icon = Icons.check_rounded;
                iconColor = AppColors.success;
                bgColor = AppColors.successLight;
                borderColor = AppColors.success;
              } else if (state == DayDisplayState.missingAttendance) {
                icon = Icons.close_rounded;
                iconColor = AppColors.missing;
                bgColor = AppColors.missingLight;
                borderColor = AppColors.missing;
              } else if (state == DayDisplayState.offDay) {
                icon = Icons.weekend_rounded;
                iconColor = AppColors.error;
                bgColor = AppColors.errorLight;
                borderColor = AppColors.error;
              } else if (state == DayDisplayState.manualException) {
                icon = Icons.info_outline_rounded;
                iconColor = const Color(0xFF3B82F6);
                bgColor = const Color(0xFFEFF6FF);
                borderColor = const Color(0xFF3B82F6);
              } else {
                icon = Icons.remove;
                iconColor = AppColors.textSecondary;
                bgColor = AppColors.background;
                borderColor = AppColors.border;
              }

              return Column(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: 1.2),
                    ),
                    child: Icon(icon, size: 16, color: iconColor),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dayLabels[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }


  Widget _buildTrackerSummary() {
    final today = _todayDate();
    final worklogs = AppStore.instance.worklogsOf(today);
    final totalTodayMinutes = _totalWorkMinutes(worklogs);
    final totalWeekMinutes = _totalWeekMinutes();
    final projects = worklogs.map((w) => w.projectName).toSet().length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _buildSummaryTile(
            icon: Icons.today_rounded,
            value: _formatMinutes(totalTodayMinutes),
            label: 'Hari Ini',
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          _buildSummaryTile(
            icon: Icons.calendar_view_week_rounded,
            value: _formatMinutes(totalWeekMinutes),
            label: 'Minggu Ini',
            color: AppColors.success,
          ),
          const SizedBox(width: 10),
          _buildSummaryTile(
            icon: Icons.folder_rounded,
            value: '$projects',
            label: 'Project',
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTile({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 18),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackerHistory() {
    final worklogs = AppStore.instance.worklogsOf(_todayDate());
    if (worklogs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text(
            'Belum ada aktivitas hari ini',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      );
    }
    return Column(
      children: worklogs.map((wl) => _buildHistoryCard(wl)).toList(),
    );
  }

  Widget _buildHistoryCard(WorklogEntry wl) {
    final startStr = wl.startTime != null ? _fmtTod(wl.startTime!) : '--:--';
    final endStr = wl.endTime != null ? _fmtTod(wl.endTime!) : '--:--';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: wl.projectColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wl.taskName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      wl.projectName,
                      style: TextStyle(
                        fontSize: 11,
                        color: wl.projectColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$startStr - $endStr',
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              wl.duration,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  DateTime _todayDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  int _totalWorkMinutes(List<WorklogEntry> worklogs) {
    var totalMin = 0;
    for (final wl in worklogs) {
      if (wl.startTime != null && wl.endTime != null) {
        var minutes =
            (wl.endTime!.hour * 60 + wl.endTime!.minute) -
            (wl.startTime!.hour * 60 + wl.startTime!.minute);
        if (minutes < 0) minutes += 24 * 60;
        totalMin += minutes;
      }
    }
    return totalMin;
  }

  int _totalWeekMinutes() {
    final store = AppStore.instance;
    final today = _todayDate();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    var total = 0;

    for (var i = 0; i < 7; i++) {
      total += _totalWorkMinutes(
        store.worklogsOf(monday.add(Duration(days: i))),
      );
    }
    return total;
  }

  String _formatMinutes(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours}j ${minutes.toString().padLeft(2, '0')}m';
  }

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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }


  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi, Pahmi!';
    if (hour < 15) return 'Selamat siang, Pahmi!';
    if (hour < 18) return 'Selamat sore, Pahmi!';
    return 'Selamat malam, Pahmi!';
  }

  Color _workStatusColor() {
    final record = AppStore.instance.attendanceOf(_todayDate());
    if (record == null) return AppColors.textSecondary;
    if (record.checkOut != null) return AppColors.success;
    if (record.checkIn != null) return AppColors.warning;
    return AppColors.textSecondary;
  }

  Color _workStatusBg() {
    final record = AppStore.instance.attendanceOf(_todayDate());
    if (record == null) return AppColors.background;
    if (record.checkOut != null) return AppColors.successLight;
    if (record.checkIn != null) return AppColors.warningLight;
    return AppColors.background;
  }

  String _workStatusLabel() {
    final record = AppStore.instance.attendanceOf(_todayDate());
    if (record == null) return 'Belum Presensi';
    if (record.checkOut != null) return 'Selesai Bekerja';
    if (record.checkIn != null) return 'Sedang Bekerja';
    return 'Belum Presensi';
  }

  String _formatReminderTime(ReminderEvent reminder) {
    final start = reminder.startDateTime;
    final end = reminder.endDateTime;
    final startLabel =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    if (end == null) return startLabel;
    final endLabel =
        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    return '$startLabel - $endLabel';
  }

  (String, Color, Color) _exceptionLabel(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.leave:
        return ('Cuti', const Color(0xFF3B82F6), const Color(0xFFEFF6FF));
      case AttendanceStatus.sick:
        return ('Sakit', const Color(0xFFDB2777), const Color(0xFFFDF2F8));
      case AttendanceStatus.training:
        return ('Training', const Color(0xFF0D9488), const Color(0xFFF0FDFA));
      case AttendanceStatus.meeting:
        return ('Meeting', const Color(0xFF7C3AED), const Color(0xFFF5F3FF));
      case AttendanceStatus.holiday:
        return ('Libur', const Color(0xFFF97316), const Color(0xFFFFF7ED));
      default:
        return ('Lainnya', AppColors.primary, AppColors.primaryLight);
    }
  }
}

class _InlineLink extends StatelessWidget {
  final String label;

  const _InlineLink({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 2),
        const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 11,
          color: AppColors.primary,
        ),
      ],
    );
  }
}
