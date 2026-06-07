import 'package:cloud_firestore/cloud_firestore.dart';

class CoupleModel {
  final String id;
  final String coupleCode;
  final List<String> members;
  final DateTime? anniversaryDate;
  final DateTime createdAt;

  CoupleModel({
    required this.id,
    required this.coupleCode,
    required this.members,
    this.anniversaryDate,
    required this.createdAt,
  });

  factory CoupleModel.fromMap(Map<String, dynamic> map, String id) {
    return CoupleModel(
      id: id,
      coupleCode: map['coupleCode'] as String? ?? '',
      members: List<String>.from(map['members'] as List? ?? []),
      anniversaryDate: map['anniversaryDate'] != null
          ? (map['anniversaryDate'] as Timestamp).toDate()
          : null,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'coupleCode': coupleCode,
      'members': members,
      'anniversaryDate': anniversaryDate != null
          ? Timestamp.fromDate(anniversaryDate!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  CoupleModel copyWith({
    String? id,
    String? coupleCode,
    List<String>? members,
    DateTime? anniversaryDate,
    DateTime? createdAt,
  }) {
    return CoupleModel(
      id: id ?? this.id,
      coupleCode: coupleCode ?? this.coupleCode,
      members: members ?? this.members,
      anniversaryDate: anniversaryDate ?? this.anniversaryDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isComplete => members.length >= 2;

  String? partnerUid(String myUid) {
    try {
      return members.firstWhere((m) => m != myUid);
    } catch (_) {
      return null;
    }
  }
}
