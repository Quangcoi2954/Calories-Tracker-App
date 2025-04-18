// lib/providers/calorie_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../models/daily_log_entry.dart';
import '../models/weight_entry.dart'; // Đảm bảo đã import

class CalorieProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _userId;

  // State nhật ký
  List<DailyLogEntry> _logEntries = [];
  double _totalCaloriesToday = 0;
  double _totalProtein = 0;
  double _totalCarbs = 0;
  double _totalFat = 0;
  DateTime _selectedDate = DateTime.now();

  // State mục tiêu
  double _calorieGoal = 2000;

  // State cân nặng
  List<WeightEntry> _weightHistory = [];

  // State chung
  bool _isLoading = false;
  bool _mounted = true; // Để kiểm tra an toàn

  // Getters
  List<DailyLogEntry> get logEntries => _logEntries;
  double get totalCaloriesToday => _totalCaloriesToday;
  double get totalProtein => _totalProtein;
  double get totalCarbs => _totalCarbs;
  double get totalFat => _totalFat;
  DateTime get selectedDate => _selectedDate;
  double get calorieGoal => _calorieGoal;
  List<WeightEntry> get weightHistory => _weightHistory;
  bool get isLoading => _isLoading;
  bool get mountedSafe => _mounted;

  CalorieProvider(this._userId) {
    print("CalorieProvider initialized/updated with userId: $_userId");
    if (_userId != null && _userId!.isNotEmpty) {
      _initializeData();
    } else {
      _resetStateToDefault();
    }
  }

  void _resetStateToDefault() {
    _logEntries = [];
    _totalCaloriesToday = 0;
    _totalProtein = 0;
    _totalCarbs = 0;
    _totalFat = 0;
    _calorieGoal = 2000;
    _isLoading = false;
    _selectedDate = DateTime.now();
    _weightHistory = [];
  }

  Future<void> _initializeData() async {
    if (mountedSafe) {
      _isLoading = true;
      notifyListeners();
    }
    await Future.wait([fetchCalorieGoal(), fetchLogEntries(_selectedDate)]);
    if (mountedSafe) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCalorieGoal() async {
    if (_userId == null || _userId!.isEmpty) return;
    try {
      final docRef = _firestore
          .collection('users')
          .doc(_userId)
          .collection('settings')
          .doc('calorieGoal');
      final docSnapshot = await docRef.get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        if (data.containsKey('goal') && data['goal'] != null) {
          if (mountedSafe) _calorieGoal = (data['goal'] as num).toDouble();
        } else {
          if (mountedSafe) await setCalorieGoal(_calorieGoal);
        }
      } else {
        if (mountedSafe) await setCalorieGoal(_calorieGoal);
      }
    } catch (e) {
      print("Error fetching calorie goal: $e");
      if (mountedSafe) _calorieGoal = 2000;
    }
  }

  Future<void> setCalorieGoal(double newGoal) async {
    if (_userId == null || _userId!.isEmpty) return;
    if (mountedSafe) {
      _calorieGoal = newGoal;
      notifyListeners();
    }
    try {
      final docRef = _firestore
          .collection('users')
          .doc(_userId)
          .collection('settings')
          .doc('calorieGoal');
      await docRef.set({'goal': newGoal}, SetOptions(merge: true));
    } catch (e) {
      print("Error setting calorie goal: $e");
    }
  }

  Future<void> fetchLogEntries(DateTime date) async {
    if (_userId == null || _userId!.isEmpty) return;
    final dateString = _formatDate(date);
    try {
      final querySnapshot =
          await _firestore
              .collection('users')
              .doc(_userId)
              .collection('dailyLogs')
              .where('date', isEqualTo: dateString)
              .orderBy('timestamp', descending: true)
              .get();
      if (mountedSafe) {
        _logEntries =
            querySnapshot.docs
                .map((doc) => DailyLogEntry.fromSnapshot(doc))
                .toList();
        _calculateTotals();
        print("Fetched ${_logEntries.length} entries for $dateString");
        notifyListeners();
      }
    } catch (e) {
      print("Error fetching log entries for $dateString: $e");
      if (mountedSafe) {
        _logEntries = [];
        _calculateTotals();
        notifyListeners();
      }
    }
  }

  Future<void> addLogEntry(DailyLogEntry entry) async {
    if (_userId == null || _userId!.isEmpty) return;
    final entryDateString = entry.date;
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('dailyLogs')
          .add(entry.toJson());
      if (entryDateString == _formatDate(_selectedDate) && mountedSafe) {
        final entryWithId = DailyLogEntry(
          id: docRef.id,
          foodName: entry.foodName,
          foodId: entry.foodId,
          calories: entry.calories,
          quantity: entry.quantity,
          unit: entry.unit,
          protein: entry.protein,
          carbs: entry.carbs,
          fat: entry.fat,
          timestamp: entry.timestamp,
          date: entry.date,
        );
        _logEntries.insert(0, entryWithId);
        _calculateTotals();
        notifyListeners();
      }
    } catch (e) {
      print("Error adding log entry: $e");
    }
  }

  Future<void> deleteLogEntry(String entryId) async {
    if (_userId == null || _userId!.isEmpty || entryId.isEmpty) return;
    final indexToRemove = _logEntries.indexWhere(
      (entry) => entry.id == entryId,
    );
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('dailyLogs')
          .doc(entryId)
          .delete();
      if (indexToRemove != -1 && mountedSafe) {
        _logEntries.removeAt(indexToRemove);
        _calculateTotals();
        notifyListeners();
      }
    } catch (e) {
      print("Error deleting log entry $entryId: $e");
    }
  }

  // --- HÀM CHO CÂN NẶNG ---
  Future<void> fetchWeightHistory({int limit = 30}) async {
    if (_userId == null || _userId!.isEmpty) return;
    print("Fetching weight history (Ascending)...");
    try {
      final querySnapshot =
          await _firestore
              .collection('users')
              .doc(_userId)
              .collection('weightLogs')
              .orderBy(
                'timestamp',
                descending: false,
              ) // Lấy theo thứ tự thời gian tăng dần
              // .limit(limit) // Xem xét bỏ limit nếu muốn vẽ toàn bộ lịch sử
              .get();
      if (mountedSafe) {
        _weightHistory =
            querySnapshot.docs
                .map((doc) => WeightEntry.fromSnapshot(doc))
                .toList();
        print(
          "Fetched ${_weightHistory.length} weight entries (already sorted by Firestore).",
        );
        notifyListeners();
      }
    } catch (e) {
      print("Error fetching weight history: $e");
      if (mountedSafe) _weightHistory = [];
      notifyListeners();
    }
  }

  // Đã cập nhật để nhận ngày
  Future<void> addWeightEntry(double weight, DateTime date) async {
    if (_userId == null || _userId!.isEmpty) return;
    // Sử dụng Timestamp.fromDate(date)
    final newEntry = WeightEntry(
      weight: weight,
      timestamp: Timestamp.fromDate(date),
    );
    print(
      "Attempting to add weight entry: $weight kg for date: ${_formatDate(date)} userId: $_userId",
    );
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('weightLogs')
          .add(newEntry.toJson());
      print("Added new weight entry successfully.");
      if (mountedSafe) await fetchWeightHistory(); // Tải lại lịch sử
    } catch (e) {
      print("Error adding weight entry: $e");
      throw Exception('Failed to save weight: $e');
    }
  }
  // --- KẾT THÚC HÀM CÂN NẶNG ---

  Future<void> changeSelectedDate(DateTime newDate) async {
    if (_formatDate(newDate) != _formatDate(_selectedDate)) {
      if (mountedSafe) {
        _selectedDate = newDate;
        _isLoading = true;
        notifyListeners();
      }
      await fetchLogEntries(newDate);
      if (mountedSafe) {
        _isLoading = false; /* notifyListeners() đã gọi trong fetchLogEntries */
      }
    }
  }

  void _calculateTotals() {
    _totalCaloriesToday = 0;
    _totalProtein = 0;
    _totalCarbs = 0;
    _totalFat = 0;
    for (var entry in _logEntries) {
      _totalCaloriesToday += entry.calories;
      _totalProtein += entry.protein ?? 0;
      _totalCarbs += entry.carbs ?? 0;
      _totalFat += entry.fat ?? 0;
    }
    print(
      "Recalculated Totals: Cal=$_totalCaloriesToday, P=$_totalProtein, C=$_totalCarbs, F=$_totalFat",
    );
  }

  String _formatDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  @override
  void dispose() {
    _mounted = false;
    print("CalorieProvider disposed");
    super.dispose();
  }
}
