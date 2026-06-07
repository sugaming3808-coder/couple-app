import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum EventColor { personalA, personalB, shared }

extension EventColorExtension on EventColor {
  Color get color {
    switch (this) {
      case EventColor.personalA:
        return AppColors.personalA;
      case EventColor.personalB:
        return AppColors.personalB;
      case EventColor.shared:
        return AppColors.shared;
    }
  }

  String get value {
    switch (this) {
      case EventColor.personalA:
        return 'personal_a';
      case EventColor.personalB:
        return 'personal_b';
      case EventColor.shared:
        return 'shared';
    }
  }

  static EventColor fromString(String value) {
    switch (value) {
      case 'personal_a':
        return EventColor.personalA;
      case 'personal_b':
        return EventColor.personalB;
      case 'shared':
        return EventColor.shared;
      default:
        return EventColor.personalA;
    }
  }
}

class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String? startTime;
  final String? endTime;
  final String ownerUid;
  final String coupleId;
  final EventColor color;
  final bool isShared;
  final DateTime createdAt;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.startTime,
    this.endTime,
    required this.ownerUid,
    required this.coupleId,
    required this.color,
    required this.isShared,
    required this.createdAt,
  });

  factory EventModel.fromMap(Map<String, dynamic> map, String id) {
    return EventModel(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      date: map['date'] != null
          ? (map['date'] as Timestamp).toDate()
          : DateTime.now(),
      startTime: map['startTime'] as String?,
      endTime: map['endTime'] as String?,
      ownerUid: map['ownerUid'] as String? ?? '',
      coupleId: map['coupleId'] as String? ?? '',
      color: EventColorExtension.fromString(
        map['color'] as String? ?? 'personal_a',
      ),
      isShared: map['isShared'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'startTime': startTime,
      'endTime': endTime,
      'ownerUid': ownerUid,
      'coupleId': coupleId,
      'color': color.value,
      'isShared': isShared,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? ownerUid,
    String? coupleId,
    EventColor? color,
    bool? isShared,
    DateTime? createdAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      ownerUid: ownerUid ?? this.ownerUid,
      coupleId: coupleId ?? this.coupleId,
      color: color ?? this.color,
      isShared: isShared ?? this.isShared,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  DateTime get dateOnly => DateTime(date.year, date.month, date.day);
}
