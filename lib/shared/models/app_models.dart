import 'package:flutter/material.dart';

// ─── ENUMS ───────────────────────────────────────────────────────────────────

enum AttendanceSource { face, manual }

enum AttendanceStatus {
  present,
  leave,
  sick,
  training,
  meeting,
  holiday,
  otherException,
}

enum DayDisplayState {
  presentWorkday,
  workedOnOffDay,
  offDay,
  manualException,
  missingAttendance,
  futureDay,
}

// ─── ATTENDANCE RECORD ───────────────────────────────────────────────────────

class AttendanceRecord {
  final String id;
  final DateTime date;
  final AttendanceSource source;
  final AttendanceStatus status;
  final TimeOfDay? checkIn;
  final TimeOfDay? checkOut;
  final String? note;

  const AttendanceRecord({
    required this.id,
    required this.date,
    required this.source,
    required this.status,
    this.checkIn,
    this.checkOut,
    this.note,
  });

  AttendanceRecord copyWith({
    String? id,
    DateTime? date,
    AttendanceSource? source,
    AttendanceStatus? status,
    TimeOfDay? checkIn,
    TimeOfDay? checkOut,
    String? note,
    bool clearCheckOut = false,
  }) =>
      AttendanceRecord(
        id: id ?? this.id,
        date: date ?? this.date,
        source: source ?? this.source,
        status: status ?? this.status,
        checkIn: checkIn ?? this.checkIn,
        checkOut: clearCheckOut ? null : (checkOut ?? this.checkOut),
        note: note ?? this.note,
      );
}

// ─── WORKLOG ENTRY ───────────────────────────────────────────────────────────

class WorklogEntry {
  final String id;
  final DateTime date;
  final String taskName;
  final String projectName;
  final Color projectColor;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final String duration;

  const WorklogEntry({
    required this.id,
    required this.date,
    required this.taskName,
    required this.projectName,
    required this.projectColor,
    this.startTime,
    this.endTime,
    required this.duration,
  });
}

// ─── REMINDER EVENT ──────────────────────────────────────────────────────────

class ReminderEvent {
  final String id;
  final String title;
  final String? description;
  final String? location;
  final DateTime startDateTime;
  final DateTime? endDateTime;
  final bool isAllDay;
  final List<int> reminderOffsetsInMinutes;
  final List<int> notificationIds;

  const ReminderEvent({
    required this.id,
    required this.title,
    this.description,
    this.location,
    required this.startDateTime,
    this.endDateTime,
    this.isAllDay = false,
    this.reminderOffsetsInMinutes = const [15, 5],
    this.notificationIds = const [],
  });

  ReminderEvent copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    DateTime? startDateTime,
    DateTime? endDateTime,
    bool? isAllDay,
    List<int>? reminderOffsetsInMinutes,
    List<int>? notificationIds,
  }) =>
      ReminderEvent(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        location: location ?? this.location,
        startDateTime: startDateTime ?? this.startDateTime,
        endDateTime: endDateTime ?? this.endDateTime,
        isAllDay: isAllDay ?? this.isAllDay,
        reminderOffsetsInMinutes:
            reminderOffsetsInMinutes ?? this.reminderOffsetsInMinutes,
        notificationIds: notificationIds ?? this.notificationIds,
      );
}

// ─── WORK SCHEDULE SETTINGS ──────────────────────────────────────────────────

class WorkScheduleSettings {
  final Set<int> offDays; // DateTime.weekday: 1=Mon … 7=Sun
  final List<int> defaultReminderOffsetsInMinutes;
  final bool autoMarkMissingAttendance;

  const WorkScheduleSettings({
    required this.offDays,
    required this.defaultReminderOffsetsInMinutes,
    required this.autoMarkMissingAttendance,
  });

  factory WorkScheduleSettings.defaults() => const WorkScheduleSettings(
        offDays: {6, 7},
        defaultReminderOffsetsInMinutes: [15, 5],
        autoMarkMissingAttendance: true,
      );

  WorkScheduleSettings copyWith({
    Set<int>? offDays,
    List<int>? defaultReminderOffsetsInMinutes,
    bool? autoMarkMissingAttendance,
  }) =>
      WorkScheduleSettings(
        offDays: offDays ?? this.offDays,
        defaultReminderOffsetsInMinutes:
            defaultReminderOffsetsInMinutes ?? this.defaultReminderOffsetsInMinutes,
        autoMarkMissingAttendance:
            autoMarkMissingAttendance ?? this.autoMarkMissingAttendance,
      );
}
