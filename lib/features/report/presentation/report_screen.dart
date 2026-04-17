import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../shared/models/app_models.dart';
import '../../../shared/store/app_store.dart';
import '../../../shared/theme/app_colors.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _store = AppStore.instance;
  late DateTime _rangeStart;
  late DateTime _rangeEnd;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _rangeStart = DateTime(now.year, now.month, 1);
    _rangeEnd = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Laporan',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showExportInfo,
            splashRadius: 20,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            icon: const Icon(
              Icons.picture_as_pdf_rounded,
              color: AppColors.textPrimary,
            ),
            tooltip: 'Export PDF',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          final data = _reportDataForRange(_rangeStart, _rangeEnd);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroCard(data),
                const SizedBox(height: 14),
                _buildRangeFilterCard(),
                const SizedBox(height: 14),
                _buildStatsGrid(data),
                const SizedBox(height: 14),
                _buildBarChartCard(data),
                const SizedBox(height: 14),
                _buildDistributionCard(data),
                const SizedBox(height: 14),
                _buildInsightCard(data),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroCard(_ReportRangeData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x221565C0),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0x1FFFFFFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _dateRangeLabel(data.startDate, data.endDate),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _formatDurationCompact(data.totalWorkDuration),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 30,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Total jam kerja dari tracker pada rentang tanggal yang dipilih',
            style: TextStyle(
              color: Color(0xD9FFFFFF),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _heroMetric(
                  'Target',
                  '${data.presentDays}/${data.workdayTarget}',
                  Icons.calendar_today_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _heroMetric(
                  'Rata-rata',
                  data.averageWorkHoursLabel,
                  Icons.schedule_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _heroMetric(
                  'Entry',
                  data.totalEntries.toString(),
                  Icons.work_history_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroMetric(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x26FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Color(0xD9FFFFFF), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeFilterCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.filter_alt_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Rentang Tanggal',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Pilih tanggal mulai dan tanggal selesai, misalnya periode gajian 7 Apr sampai 6 Mei.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'Mulai',
                  value: _dateShort(_rangeStart),
                  onTap: () => _pickRangeDate(isStart: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDateField(
                  label: 'Selesai',
                  value: _dateShort(_rangeEnd),
                  onTap: () => _pickRangeDate(isStart: false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(_ReportRangeData data) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.52,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          'Hari Hadir',
          '${data.presentDays} / ${data.workdayTarget}',
          Icons.calendar_today_rounded,
          AppColors.success,
          '${data.attendanceRateLabel} dari target kerja',
        ),
        _buildStatCard(
          'Total Jam',
          _formatDurationCompact(data.totalWorkDuration),
          Icons.schedule_rounded,
          AppColors.primary,
          '${data.totalEntries} aktivitas kerja tercatat',
        ),
        _buildStatCard(
          'Ketepatan',
          data.punctualityLabel,
          Icons.alarm_on_rounded,
          AppColors.warning,
          '${data.onTimeCount}/${data.daysWithCheckIn} hari datang tepat waktu',
        ),
        _buildStatCard(
          'Rata-rata',
          data.averageWorkHoursLabel,
          Icons.insights_rounded,
          const Color(0xFF7C3AED),
          'Jam kerja rata-rata per hari aktif',
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    String helper,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            helper,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChartCard(_ReportRangeData data) {
    final maxHours = data.buckets.fold<double>(
      0,
      (prev, bucket) => bucket.hours > prev ? bucket.hours : prev,
    );
    final chartMaxY = maxHours <= 4
        ? 4.0
        : ((maxHours / 2).ceil() * 2).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Jam Kerja per Periode 7 Hari',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
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
                  '${data.totalDays} hari',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Cocok untuk memantau periode kerja khusus seperti 7 April sampai 6 Mei.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 190,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: chartMaxY,
                barTouchData: BarTouchData(enabled: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: chartMaxY <= 4 ? 2 : 4,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: AppColors.border, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: chartMaxY <= 4 ? 2 : 4,
                      reservedSize: 30,
                      getTitlesWidget: (value, _) => Text(
                        '${value.toInt()}j',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 || i >= data.buckets.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            data.buckets[i].shortLabel,
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: data.buckets.asMap().entries.map((entry) {
                  final isPeak =
                      entry.value.hours == data.peakBucketHours &&
                      data.peakBucketHours > 0;
                  return _bar(entry.key, entry.value.hours, isPeak: isPeak);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _bar(int x, double y, {bool isPeak = false}) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: 22,
          color: isPeak ? AppColors.success : AppColors.primary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
        ),
      ],
    );
  }

  Widget _buildDistributionCard(_ReportRangeData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Komposisi Kehadiran',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Distribusi status kehadiran berdasarkan rentang tanggal yang dipilih.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          _progressItem(
            'Hadir',
            data.presentRatio,
            AppColors.success,
            '${data.presentDays} hari',
          ),
          const SizedBox(height: 12),
          _progressItem(
            'Libur',
            data.offDayRatio,
            AppColors.error,
            '${data.offDays} hari',
          ),
          const SizedBox(height: 12),
          _progressItem(
            'Absen',
            data.missingRatio,
            AppColors.warning,
            '${data.missingDays} hari',
          ),
          const SizedBox(height: 12),
          _progressItem(
            'Pengingat',
            data.reminderRatio,
            AppColors.primary,
            '${data.reminders} acara',
          ),
        ],
      ),
    );
  }

  Widget _progressItem(
    String label,
    double value,
    Color color,
    String caption,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              caption,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(_ReportRangeData data) {
    final insights = <({IconData icon, Color color, String label})>[
      (
        icon: Icons.auto_graph_rounded,
        color: AppColors.primary,
        label:
            'Periode tersibuk: ${data.peakBucketLabel} (${data.peakBucketHoursLabel})',
      ),
      (
        icon: Icons.login_rounded,
        color: AppColors.success,
        label:
            'Hari tepat waktu: ${data.onTimeCount} dari ${data.daysWithCheckIn}',
      ),
      (
        icon: Icons.notifications_active_rounded,
        color: AppColors.warning,
        label: 'Pengingat aktif di periode ini: ${data.reminders} acara',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Insight Singkat',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ringkasan cepat dari attendance, tracker, dan pengingat pada periode ini.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          ...insights.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, size: 18, color: item.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
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

  Future<void> _pickRangeDate({required bool isStart}) async {
    final initialDate = isStart ? _rangeStart : _rangeEnd;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _rangeStart = _normalizeDate(picked);
        if (_rangeStart.isAfter(_rangeEnd)) {
          _rangeEnd = _rangeStart;
        }
      } else {
        _rangeEnd = _normalizeDate(picked);
        if (_rangeEnd.isBefore(_rangeStart)) {
          _rangeStart = _rangeEnd;
        }
      }
    });
  }

  _ReportRangeData _reportDataForRange(DateTime start, DateTime end) {
    final startDate = _normalizeDate(start);
    final endDate = _normalizeDate(end);

    int workdayTarget = 0;
    int presentDays = 0;
    int missingDays = 0;
    int offDays = 0;
    int reminders = 0;
    int onTimeCount = 0;
    int daysWithCheckIn = 0;

    for (
      var date = startDate;
      !date.isAfter(endDate);
      date = date.add(const Duration(days: 1))
    ) {
      final isOffDay = _store.settings.offDays.contains(date.weekday);
      if (!isOffDay) workdayTarget++;

      switch (_store.dayStateOf(date)) {
        case DayDisplayState.presentWorkday:
        case DayDisplayState.workedOnOffDay:
          presentDays++;
          break;
        case DayDisplayState.missingAttendance:
          missingDays++;
          break;
        case DayDisplayState.offDay:
          offDays++;
          break;
        default:
          break;
      }

      reminders += _store.remindersOf(date).length;

      final record = _store.attendanceOf(date);
      if (record?.checkIn != null) {
        daysWithCheckIn++;
        final checkIn = record!.checkIn!;
        final isOnTime =
            checkIn.hour < 8 || (checkIn.hour == 8 && checkIn.minute <= 15);
        if (isOnTime) onTimeCount++;
      }
    }

    final rangeLogs = <WorklogEntry>[
      for (final entry in _store.allWorklogs.entries)
        ...entry.value.where(
          (worklog) =>
              !_normalizeDate(worklog.date).isBefore(startDate) &&
              !_normalizeDate(worklog.date).isAfter(endDate),
        ),
    ]..sort((a, b) => a.date.compareTo(b.date));

    Duration totalWorkDuration = Duration.zero;
    final bucketMap = <DateTime, Duration>{};

    for (
      var bucketStart = startDate;
      !bucketStart.isAfter(endDate);
      bucketStart = bucketStart.add(const Duration(days: 7))
    ) {
      bucketMap[bucketStart] = Duration.zero;
    }

    for (final log in rangeLogs) {
      final duration = _worklogDuration(log);
      totalWorkDuration += duration;

      final daysFromStart = _normalizeDate(
        log.date,
      ).difference(startDate).inDays;
      final bucketOffset = (daysFromStart ~/ 7) * 7;
      final bucketStart = startDate.add(Duration(days: bucketOffset));
      bucketMap[bucketStart] =
          (bucketMap[bucketStart] ?? Duration.zero) + duration;
    }

    final buckets = bucketMap.entries.map((entry) {
      final bucketStart = entry.key;
      final bucketEnd =
          bucketStart.add(const Duration(days: 6)).isAfter(endDate)
          ? endDate
          : bucketStart.add(const Duration(days: 6));
      return _RangeBucket(
        start: bucketStart,
        end: bucketEnd,
        hours: entry.value.inMinutes / 60,
      );
    }).toList();

    final totalDistributionBase =
        (presentDays + missingDays + offDays + reminders).clamp(1, 9999);
    final peakBucketHours = buckets.fold<double>(
      0,
      (prev, bucket) => bucket.hours > prev ? bucket.hours : prev,
    );
    final peakBucket = buckets.firstWhere(
      (bucket) => bucket.hours == peakBucketHours,
      orElse: () => _RangeBucket(start: startDate, end: endDate, hours: 0),
    );

    return _ReportRangeData(
      startDate: startDate,
      endDate: endDate,
      presentDays: presentDays,
      workdayTarget: workdayTarget,
      missingDays: missingDays,
      offDays: offDays,
      reminders: reminders,
      totalEntries: rangeLogs.length,
      totalWorkDuration: totalWorkDuration,
      onTimeCount: onTimeCount,
      daysWithCheckIn: daysWithCheckIn,
      totalDays: endDate.difference(startDate).inDays + 1,
      buckets: buckets,
      peakBucketHours: peakBucketHours,
      peakBucketLabel: _bucketLabel(peakBucket.start, peakBucket.end),
      presentRatio: presentDays / totalDistributionBase,
      missingRatio: missingDays / totalDistributionBase,
      offDayRatio: offDays / totalDistributionBase,
      reminderRatio: reminders / totalDistributionBase,
    );
  }

  Duration _worklogDuration(WorklogEntry entry) {
    if (entry.startTime == null || entry.endTime == null) return Duration.zero;

    final start = DateTime(
      entry.date.year,
      entry.date.month,
      entry.date.day,
      entry.startTime!.hour,
      entry.startTime!.minute,
    );
    var end = DateTime(
      entry.date.year,
      entry.date.month,
      entry.date.day,
      entry.endTime!.hour,
      entry.endTime!.minute,
    );
    if (end.isBefore(start)) end = end.add(const Duration(days: 1));
    return end.difference(start);
  }

  DateTime _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  String _dateShort(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _dateRangeLabel(DateTime start, DateTime end) =>
      '${_dateShort(start)} - ${_dateShort(end)}';

  String _bucketLabel(DateTime start, DateTime end) {
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
    if (start.month == end.month) {
      return '${start.day}-${end.day} ${months[start.month - 1]}';
    }
    return '${start.day} ${months[start.month - 1]}-${end.day} ${months[end.month - 1]}';
  }

  String _formatDurationCompact(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}j';
    return '${hours}j ${minutes.toString().padLeft(2, '0')}m';
  }

  void _showExportInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Export PDF belum diaktifkan untuk periode ${_dateRangeLabel(_rangeStart, _rangeEnd)}.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _ReportRangeData {
  final DateTime startDate;
  final DateTime endDate;
  final int presentDays;
  final int workdayTarget;
  final int missingDays;
  final int offDays;
  final int reminders;
  final int totalEntries;
  final Duration totalWorkDuration;
  final int onTimeCount;
  final int daysWithCheckIn;
  final int totalDays;
  final List<_RangeBucket> buckets;
  final double peakBucketHours;
  final String peakBucketLabel;
  final double presentRatio;
  final double missingRatio;
  final double offDayRatio;
  final double reminderRatio;

  const _ReportRangeData({
    required this.startDate,
    required this.endDate,
    required this.presentDays,
    required this.workdayTarget,
    required this.missingDays,
    required this.offDays,
    required this.reminders,
    required this.totalEntries,
    required this.totalWorkDuration,
    required this.onTimeCount,
    required this.daysWithCheckIn,
    required this.totalDays,
    required this.buckets,
    required this.peakBucketHours,
    required this.peakBucketLabel,
    required this.presentRatio,
    required this.missingRatio,
    required this.offDayRatio,
    required this.reminderRatio,
  });

  String get attendanceRateLabel {
    if (workdayTarget == 0) return '0%';
    return '${((presentDays / workdayTarget) * 100).round()}%';
  }

  String get punctualityLabel {
    if (daysWithCheckIn == 0) return '0%';
    return '${((onTimeCount / daysWithCheckIn) * 100).round()}%';
  }

  String get averageWorkHoursLabel {
    if (presentDays == 0 || totalWorkDuration == Duration.zero) return '0j';
    final avgMinutes = totalWorkDuration.inMinutes / presentDays;
    final hours = avgMinutes ~/ 60;
    final minutes = avgMinutes.round() % 60;
    if (hours == 0) return '${minutes}m';
    return '${hours}j ${minutes.toString().padLeft(2, '0')}m';
  }

  String get peakBucketHoursLabel {
    final wholeHours = peakBucketHours.floor();
    final minutes = ((peakBucketHours - wholeHours) * 60).round();
    if (peakBucketHours == 0) return '0j';
    if (minutes == 0) return '${wholeHours}j';
    return '${wholeHours}j ${minutes.toString().padLeft(2, '0')}m';
  }
}

class _RangeBucket {
  final DateTime start;
  final DateTime end;
  final double hours;

  const _RangeBucket({
    required this.start,
    required this.end,
    required this.hours,
  });

  String get shortLabel {
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
    return '${start.day} ${months[start.month - 1]}';
  }
}
