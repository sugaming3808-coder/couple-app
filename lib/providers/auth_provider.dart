import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/couple_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  CoupleModel? _couple;
  String? _errorMessage;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<UserModel?>? _userSubscription;
  StreamSubscription<CoupleModel?>? _coupleSubscription;

  bool _skipCoupleConnect = false;

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  CoupleModel? get couple => _couple;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  /// True only when both partners are connected OR user chose solo mode.
  bool get isConnected =>
      (_couple != null && _couple!.isComplete) || _skipCoupleConnect;

  /// True when the user chose to skip couple connection and use solo.
  bool get isSoloMode =>
      _skipCoupleConnect && (_couple == null || !_couple!.isComplete);

  /// The Firestore "namespace" used to store this user's events.
  /// Uses coupleId when available, otherwise falls back to the user's own uid
  /// (solo mode).
  String? get calendarId => _currentUser?.coupleId ?? _currentUser?.uid;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authSubscription = _authService.authStateChanges.listen((user) async {
      if (user != null) {
        _status = AuthStatus.loading;
        notifyListeners();

        // Subscribe to user stream
        _userSubscription?.cancel();
        _userSubscription =
            _firestoreService.userStream(user.uid).listen((userModel) {
          _currentUser = userModel;

          if (userModel?.coupleId != null && userModel!.coupleId!.isNotEmpty) {
            _subscribeToCoupleStream(userModel.coupleId!);
          } else {
            _couple = null;
          }

          _status = AuthStatus.authenticated;
          notifyListeners();
        }, onError: (e) {
          _errorMessage = e.toString();
          _status = AuthStatus.error;
          notifyListeners();
        });
      } else {
        _cancelSubscriptions();
        _currentUser = null;
        _couple = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
    });
  }

  void _subscribeToCoupleStream(String coupleId) {
    _coupleSubscription?.cancel();
    _coupleSubscription =
        _firestoreService.coupleStream(coupleId).listen((couple) {
      _couple = couple;
      notifyListeners();
    });
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async {
    _setLoading();
    try {
      await _authService.signUp(
        email: email,
        password: password,
        nickname: nickname,
      );
      // Stream listener will update state
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading();
    try {
      await _authService.signIn(email: email, password: password);
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _setLoading();
    await _authService.signOut();
  }

  Future<bool> createCoupleCode() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return false;

    try {
      final couple = await _firestoreService.createCouple(uid);
      _couple = couple;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<String?> connectWithCode({
    required String code,
    required DateTime anniversaryDate,
  }) async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return '로그인이 필요합니다.';

    try {
      final couple = await _firestoreService.findCoupleByCode(code);
      if (couple == null) return '유효하지 않은 코드입니다.';
      if (couple.members.contains(uid)) return '이미 연결된 코드입니다.';
      if (couple.isComplete) return '이미 다른 커플이 연결된 코드입니다.';

      await _firestoreService.connectCouple(
        coupleId: couple.id,
        joiningUid: uid,
        anniversaryDate: anniversaryDate,
      );

      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateAnniversary(DateTime date) async {
    final uid = _authService.currentUser?.uid;
    final coupleId = _currentUser?.coupleId;
    if (uid == null || coupleId == null) return '커플 연결이 필요합니다.';

    try {
      await _firestoreService.updateAnniversary(coupleId, uid, date);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Skip couple connection and use the app as a personal calendar.
  void skipCoupleConnect() {
    _skipCoupleConnect = true;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _cancelSubscriptions() {
    _userSubscription?.cancel();
    _coupleSubscription?.cancel();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _cancelSubscriptions();
    super.dispose();
  }
}
