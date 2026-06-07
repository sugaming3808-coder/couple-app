import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/event_model.dart';
import '../models/couple_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ─── Collections ───────────────────────────────────────────────
  CollectionReference get _users => _db.collection('users');
  CollectionReference get _couples => _db.collection('couples');
  CollectionReference get _events => _db.collection('events');

  // ─── User ──────────────────────────────────────────────────────

  Future<void> createUser(UserModel user) async {
    await _users.doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  Stream<UserModel?> userStream(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    });
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _users.doc(uid).update(data);
  }

  Future<void> deleteUser(String uid) async {
    await _users.doc(uid).delete();
  }

  // ─── Couple ────────────────────────────────────────────────────

  /// Generate a unique 6-digit couple code and create the couple document
  Future<CoupleModel> createCouple(String ownerUid) async {
    final code = _generateCoupleCode();
    final coupleId = _uuid.v4();

    final couple = CoupleModel(
      id: coupleId,
      coupleCode: code,
      members: [ownerUid],
      createdAt: DateTime.now(),
    );

    await _couples.doc(coupleId).set(couple.toMap());
    await updateUser(ownerUid, {'coupleId': coupleId});

    return couple;
  }

  Future<CoupleModel?> getCouple(String coupleId) async {
    final doc = await _couples.doc(coupleId).get();
    if (!doc.exists) return null;
    return CoupleModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Stream<CoupleModel?> coupleStream(String coupleId) {
    return _couples.doc(coupleId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return CoupleModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  /// Find a couple by its 6-digit code
  Future<CoupleModel?> findCoupleByCode(String code) async {
    final query = await _couples
        .where('coupleCode', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return CoupleModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// Connect two users by joining the couple document
  Future<void> connectCouple({
    required String coupleId,
    required String joiningUid,
    required DateTime anniversaryDate,
  }) async {
    final batch = _db.batch();

    final coupleRef = _couples.doc(coupleId);
    batch.update(coupleRef, {
      'members': FieldValue.arrayUnion([joiningUid]),
      'anniversaryDate': Timestamp.fromDate(anniversaryDate),
    });

    final joiningUserRef = _users.doc(joiningUid);
    batch.update(joiningUserRef, {
      'coupleId': coupleId,
      'anniversaryDate': Timestamp.fromDate(anniversaryDate),
    });

    // Also update the owner's anniversary date
    final coupleDoc = await coupleRef.get();
    if (coupleDoc.exists) {
      final data = coupleDoc.data() as Map<String, dynamic>;
      final members = List<String>.from(data['members'] as List? ?? []);
      for (final uid in members) {
        if (uid != joiningUid) {
          batch.update(_users.doc(uid), {
            'anniversaryDate': Timestamp.fromDate(anniversaryDate),
          });
        }
      }
    }

    await batch.commit();
  }

  Future<void> updateAnniversary(
    String coupleId,
    String uid,
    DateTime date,
  ) async {
    final batch = _db.batch();
    batch.update(_couples.doc(coupleId), {
      'anniversaryDate': Timestamp.fromDate(date),
    });
    batch.update(_users.doc(uid), {
      'anniversaryDate': Timestamp.fromDate(date),
    });
    await batch.commit();
  }

  // ─── Events ────────────────────────────────────────────────────

  Future<EventModel> createEvent(EventModel event) async {
    final docRef = await _events.add(event.toMap());
    return event.copyWith(id: docRef.id);
  }

  Future<void> updateEvent(EventModel event) async {
    await _events.doc(event.id).update(event.toMap());
  }

  Future<void> deleteEvent(String eventId) async {
    await _events.doc(eventId).delete();
  }

  /// Stream all events belonging to a couple
  Stream<List<EventModel>> eventsStream(String coupleId) {
    return _events
        .where('coupleId', isEqualTo: coupleId)
        .orderBy('date')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                EventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  /// Get events for a specific date range (for calendar display)
  Future<List<EventModel>> getEventsForMonth(
    String coupleId,
    int year,
    int month,
  ) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);

    final query = await _events
        .where('coupleId', isEqualTo: coupleId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date')
        .get();

    return query.docs
        .map((doc) =>
            EventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  // ─── Helpers ───────────────────────────────────────────────────

  String _generateCoupleCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = List.generate(
      6,
      (i) => chars[DateTime.now().microsecondsSinceEpoch % (i + 7) % chars.length],
    );
    // Use uuid for better randomness
    final uid = _uuid.v4().replaceAll('-', '').toUpperCase();
    return uid.substring(0, 6);
  }
}
