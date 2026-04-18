import 'package:flutter/material.dart';

enum NotificationCategory {
  calendar,
  attendance,
  tracker,
  schedule,
  system,
}

enum NotificationPriority { high, medium, low }

class AppNotification {
  final String id;
  final NotificationCategory category;
  final NotificationPriority priority;
  final String title;
  final String? subtitle;
  final String timeLabel;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  bool isRead;

  AppNotification({
    required this.id,
    required this.category,
    required this.priority,
    required this.title,
    this.subtitle,
    required this.timeLabel,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.isRead = false,
  });
}
