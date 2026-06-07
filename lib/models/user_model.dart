import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String nickname;
  final String? coupleId;
  final DateTime? anniversaryDate;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.nickname,
    this.coupleId,
    this.anniversaryDate,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      nickname: map['nickname'] as String? ?? '',
      coupleId: map['coupleId'] as String?,
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
      'uid': uid,
      'email': email,
      'nickname': nickname,
      'coupleId': coupleId,
      'anniversaryDate':
          anniversaryDate != null ? Timestamp.fromDate(anniversaryDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? nickname,
    String? coupleId,
    DateTime? anniversaryDate,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      coupleId: coupleId ?? this.coupleId,
      anniversaryDate: anniversaryDate ?? this.anniversaryDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isConnected => coupleId != null && coupleId!.isNotEmpty;
}
