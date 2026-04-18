import 'package:flutter/material.dart';

import '../../profile/presentation/profile_screen.dart';
import '../../../shared/models/app_models.dart';
import '../../../shared/providers/notification_provider.dart';
import '../../../shared/store/app_store.dart';
import '../../../shared/theme/app_colors.dart';
import '../controller/home_controller.dart';
import 'notification_panel.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onGoToTracker;

  const HomeScreen({super.key, this.onGoToTracker});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = HomeController();

  @override
  void initState() {
    super.initState();
    _controller.loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListenableBuilder(
        listenable: Listenable.merge([_controller, AppStore.instance, NotificationProvider.instance]),
        builder: (context, _) {
          return NestedScrollView(
            headerSliverBuilder: (ctx, _) => [_buildAppBar(ctx)],
            body: _buildBody(context),
          );
        },
      ),
    );
  }

  // ─── APP BAR ──────────────────────────────────────────────────────────────

  SliverAppBar _buildAppBar(BuildContext context) {
    final profile = AppStore.instance.profile;
    final initials = profile?.initials ?? '?';
    final unread = NotificationProvider.instance.unreadCount;

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
          onPressed: () => showNotificationPanel(context),
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
              if (unread > 0)
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
                      unread > 9 ? '9+' : '$unread',
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
            child: CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.primaryLight,
              child: profile?.avatarUrl != null
                  ? ClipOval(
                      child: Image.network(
                        profile!.avatarUrl!,
                        width: 34,
                        height: 34,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, e, s) => _avatarText(initials),
                      ),
                    )
                  : _avatarText(initials),
            ),
          ),
        ),
      ],
    );
  }

  Widget _avatarText(String initials) => Text(
        initials,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      );

  // ─── BODY ─────────────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context) {
    if (_controller.isLoading && AppStore.instance.profile == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
      );
    }

    if (_controller.state == HomeLoadState.error) {
      return _buildErrorState();
    }

    final bottomInset = MediaQuery.of(context).padding.bottom;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _controller.refresh,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 120 + bottomInset),
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
              _InlineLink(
                label: 'Lihat semua',
                onTap: _goToTracker,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTrackerHistory(),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.2),
                ),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: AppColors.error,
                size: 26,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _controller.errorMessage ?? 'Gagal memuat data.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Periksa koneksi internet Anda dan coba lagi.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _controller.refresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToTracker() => widget.onGoToTracker?.call();

  // ─── GREETING ─────────────────────────────────────────────────────────────

  Widget _buildGreeting() {
    final profile = AppStore.instance.profile;
    final firstName = profile?.fullName.split(' ').first ?? 'Karyawan';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greetingPrefix()}, $firstName!',
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
        _buildWorkStatusChip(),
      ],
    );
  }

  Widget _buildWorkStatusChip() {
    final record = AppStore.instance.attendanceOf(_today);
    final Color color;
    final Color bg;
    final String label;

    if (record == null) {
      color = AppColors.textSecondary;
      bg = AppColors.background;
      label = 'Belum Presensi';
    } else if (record.checkOut != null) {
      color = AppColors.success;
      bg = AppColors.successLight;
      label = 'Selesai Bekerja';
    } else if (record.checkIn != null) {
      color = AppColors.warning;
      bg = AppColors.warningLight;
      label = 'Sedang Bekerja';
    } else {
      color = AppColors.textSecondary;
      bg = AppColors.background;
      label = 'Belum Presensi';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ─── SECTION LABEL ────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String title) => Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.3,
        ),
      );

  // ─── KEHADIRAN HARI INI ───────────────────────────────────────────────────

  Widget _buildAttendanceCard() {
    final record = AppStore.instance.attendanceOf(_today);
    final hasCheckin = record?.checkIn != null;
    final hasCheckout = record?.checkOut != null;

    final cinTime = hasCheckin ? _fmtTod(record!.checkIn!) : '--:--';
    final coutTime = hasCheckout ? _fmtTod(record!.checkOut!) : '--:--';
    final cinSub = hasCheckin ? 'Tercatat' : 'Belum check-in';
    final coutSub = hasCheckout ? 'Tercatat' : 'Belum checkout';

    final String statusLabel;
    final Color statusColor;
    final Color statusBg;

    if (record == null) {
      statusLabel = 'Belum Hadir';
      statusColor = AppColors.missing;
      statusBg = AppColors.missingLight;
    } else if (record.status != AttendanceStatus.present) {
      final s = _exceptionStyle(record.status);
      statusLabel = s.$1;
      statusColor = s.$2;
      statusBg = s.$3;
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
        ? _durationBetween(record!.checkIn!, record.checkOut!)
        : null;

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
                _StatusChip(
                  label: statusLabel,
                  color: statusColor,
                  bg: statusBg,
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
                  child: _TimeSlot(
                    label: 'Check-in',
                    time: cinTime,
                    sub: cinSub,
                    icon: Icons.login_rounded,
                    color: hasCheckin ? AppColors.success : AppColors.textSecondary,
                    bgColor: hasCheckin ? AppColors.successLight : AppColors.background,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimeSlot(
                    label: 'Check-out',
                    time: coutTime,
                    sub: coutSub,
                    icon: Icons.logout_rounded,
                    color: hasCheckout ? AppColors.error : AppColors.textSecondary,
                    bgColor: hasCheckout ? AppColors.errorLight : AppColors.background,
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
                _metaChip(
                  Icons.schedule_rounded,
                  totalTime != null ? 'Total: $totalTime' : 'Total: --',
                ),
                if (record != null && record.note != null)
                  _metaChip(Icons.sticky_note_2_outlined, record.note!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaChip(IconData icon, String text) {
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

  // ─── KEHADIRAN MINGGU INI ─────────────────────────────────────────────────

  Widget _buildWeekProgress() {
    final weekStates = AppStore.instance.weekStatesOf(_today);
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
              final isToday = _isSameDay(info.date, _today);
              final state = info.state;

              final IconData icon;
              final Color iconColor;
              final Color bgColor;
              final Color borderColor;

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
                      fontWeight:
                          isToday ? FontWeight.bold : FontWeight.normal,
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

  // ─── PENGINGAT HARI INI ───────────────────────────────────────────────────

  Widget _buildReminderHighlight() {
    final reminders = AppStore.instance.remindersOf(_today);

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
                    'Agenda dari kalender akan muncul di sini.',
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

    final next = reminders.first;
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
                      'Agenda yang perlu diperhatikan.',
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
          const SizedBox(height: 12),
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
                  next.title,
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
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      next.isAllDay
                          ? 'Seharian'
                          : _formatReminderTime(next),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (next.description != null &&
                    next.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    next.description!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
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

  // ─── RINGKASAN TRACKER ────────────────────────────────────────────────────

  Widget _buildTrackerSummary() {
    final worklogs = AppStore.instance.worklogsOf(_today);
    final todayMin = _totalMinutes(worklogs);
    final weekMin = _weekTotalMinutes();
    final projectCount = worklogs.map((w) => w.projectName).toSet().length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _SummaryTile(
            icon: Icons.today_rounded,
            value: _fmtMinutes(todayMin),
            label: 'Hari Ini',
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          _SummaryTile(
            icon: Icons.calendar_view_week_rounded,
            value: _fmtMinutes(weekMin),
            label: 'Minggu Ini',
            color: AppColors.success,
          ),
          const SizedBox(width: 10),
          _SummaryTile(
            icon: Icons.folder_rounded,
            value: '$projectCount',
            label: 'Project',
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  // ─── AKTIVITAS HARI INI ───────────────────────────────────────────────────

  Widget _buildTrackerHistory() {
    final worklogs = AppStore.instance.worklogsOf(_today);

    if (worklogs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 36,
              color: AppColors.textSecondary.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 10),
            const Text(
              'Belum ada aktivitas hari ini',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tambah pekerjaan lewat tab Tracker.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      children: worklogs.map((wl) => _buildActivityCard(wl)).toList(),
    );
  }

  Widget _buildActivityCard(WorklogEntry wl) {
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
                      '$startStr – $endStr',
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

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  String _greetingPrefix() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  String _todayLabel() {
    final now = DateTime.now();
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _fmtTod(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _durationBetween(TimeOfDay a, TimeOfDay b) {
    var mins = (b.hour * 60 + b.minute) - (a.hour * 60 + a.minute);
    if (mins < 0) mins += 24 * 60;
    if (mins <= 0) return '0j 00m';
    return '${mins ~/ 60}j ${(mins % 60).toString().padLeft(2, '0')}m';
  }

  int _totalMinutes(List<WorklogEntry> logs) {
    var total = 0;
    for (final wl in logs) {
      if (wl.startTime != null && wl.endTime != null) {
        var m = (wl.endTime!.hour * 60 + wl.endTime!.minute) -
            (wl.startTime!.hour * 60 + wl.startTime!.minute);
        if (m < 0) m += 24 * 60;
        total += m;
      }
    }
    return total;
  }

  int _weekTotalMinutes() {
    final monday = _today.subtract(Duration(days: _today.weekday - 1));
    var total = 0;
    for (var i = 0; i < 7; i++) {
      total += _totalMinutes(
        AppStore.instance.worklogsOf(monday.add(Duration(days: i))),
      );
    }
    return total;
  }

  String _fmtMinutes(int m) {
    final h = m ~/ 60;
    final min = m % 60;
    return '${h}j ${min.toString().padLeft(2, '0')}m';
  }

  String _formatReminderTime(ReminderEvent r) {
    final s = r.startDateTime;
    final e = r.endDateTime;
    final sl = '${s.hour.toString().padLeft(2, '0')}:${s.minute.toString().padLeft(2, '0')}';
    if (e == null) return sl;
    final el = '${e.hour.toString().padLeft(2, '0')}:${e.minute.toString().padLeft(2, '0')}';
    return '$sl – $el';
  }

  (String, Color, Color) _exceptionStyle(AttendanceStatus s) {
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

// ─── REUSABLE WIDGETS ─────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const _StatusChip({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
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
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeSlot extends StatelessWidget {
  final String label;
  final String time;
  final String sub;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _TimeSlot({
    required this.label,
    required this.time,
    required this.sub,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
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
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _SummaryTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
}

class _InlineLink extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _InlineLink({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
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
      ),
    );
  }
}
