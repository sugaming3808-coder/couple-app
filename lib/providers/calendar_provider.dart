import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/event_model.dart';
import '../services/firestore_service.dart';

class CalendarProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<EventModel> _events = [];
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<List<EventModel>>? _eventsSubscription;
  String? _currentCoupleId;
  String? _currentUserUid;

  List<EventModel> get events => _events;
  DateTime get focusedDay => _focusedDay;
  DateTime get selectedDay => _selectedDay;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Returns events for a specific date (date-only comparison)
  List<EventModel> getEventsForDay(DateTime day) {
    final dateOnly = DateTime(day.year, day.month, day.day);
    return _events
        .where((e) => e.dateOnly == dateOnly)
        .toList()
      ..sort((a, b) {
        final aTime = a.startTime ?? '';
        final bTime = b.startTime ?? '';
        return aTime.compareTo(bTime);
      });
  }

  /// Returns events for today
  List<EventModel> get todayEvents => getEventsForDay(DateTime.now());

  /// Returns a map of date -> events list (for table_calendar markers)
  Map<DateTime, List<EventModel>> get eventMap {
    final map = <DateTime, List<EventModel>>{};
    for (final event in _events) {
      final key = event.dateOnly;
      map.putIfAbsent(key, () => []).add(event);
    }
    return map;
  }

  void init(String coupleId, String userUid) {
    if (_currentCoupleId == coupleId) return;
    _currentCoupleId = coupleId;
    _currentUserUid = userUid;
    _subscribeToEvents(coupleId);
  }

  void _subscribeToEvents(String coupleId) {
    _eventsSubscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _eventsSubscription =
        _firestoreService.eventsStream(coupleId).listen((events) {
      _events = events;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    }, onError: (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  void setFocusedDay(DateTime day) {
    _focusedDay = day;
    notifyListeners();
  }

  void setSelectedDay(DateTime day) {
    _selectedDay = day;
    notifyListeners();
  }

  Future<bool> addEvent(EventModel event) async {
    try {
      await _firestoreService.createEvent(event);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateEvent(EventModel event) async {
    try {
      await _firestoreService.updateEvent(event);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEvent(String eventId) async {
    try {
      await _firestoreService.deleteEvent(eventId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _eventsSubscription?.cancel();
    _events = [];
    _currentCoupleId = null;
    _currentUserUid = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    super.dispose();
  }
}
