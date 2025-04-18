// lib/providers/calorie_provider.dart

import 'package:flutter/material.dart'; // Cần cho ChangeNotifier
import 'package:cloud_firestore/cloud_firestore.dart'; // Tương tác với Firestore
import 'package:intl/intl.dart'; // Để định dạng ngày tháng (YYYY-MM-DD)

// Import các models
import '../models/daily_log_entry.dart';
import '../models/weight_entry.dart'; // *** THÊM IMPORT CHO WEIGHT ENTRY ***

// Lớp CalorieProvider kế thừa từ ChangeNotifier để có thể thông báo thay đổi
class CalorieProvider extends ChangeNotifier {
  // 1. Khởi tạo đối tượng Firestore để tương tác
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 2. User ID của người dùng hiện tại
  final String? _userId;

  // 3. Các biến trạng thái (State Variables)
  // ---- Dữ liệu nhật ký hàng ngày ----
  List<DailyLogEntry> _logEntries = [];
  double _totalCaloriesToday = 0;
  double _totalProtein = 0;
  double _totalCarbs = 0;
  double _totalFat = 0;
  DateTime _selectedDate = DateTime.now();

  // ---- Dữ liệu mục tiêu ----
  double _calorieGoal = 2000; // Giá trị mặc định ban đầu

  // ---- Dữ liệu lịch sử cân nặng ----
  List<WeightEntry> _weightHistory = []; // *** BIẾN STATE MỚI ***

  // ---- Trạng thái chung ----
  bool _isLoading = false;

  // 4. Getters
  // ---- Getters cho nhật ký ----
  List<DailyLogEntry> get logEntries => _logEntries;
  double get totalCaloriesToday => _totalCaloriesToday;
  double get totalProtein => _totalProtein;
  double get totalCarbs => _totalCarbs;
  double get totalFat => _totalFat;
  DateTime get selectedDate => _selectedDate;
  // ---- Getter cho mục tiêu ----
  double get calorieGoal => _calorieGoal;
  // ---- Getter cho lịch sử cân nặng ----
  List<WeightEntry> get weightHistory => _weightHistory; // *** GETTER MỚI ***
  // ---- Getter cho trạng thái ----
  bool get isLoading => _isLoading;

  // --- Constructor ---
  CalorieProvider(this._userId) {
    print("CalorieProvider initialized/updated with userId: $_userId");
    if (_userId != null && _userId.isNotEmpty) {
      _initializeData();
      // Có thể gọi fetchWeightHistory() ở đây nếu muốn tải sẵn,
      // nhưng thường sẽ gọi khi mở màn hình ProgressScreen để tiết kiệm tài nguyên.
      // fetchWeightHistory();
    } else {
      _resetStateToDefault(); // Gọi hàm reset riêng cho gọn
    }
  }

  // Hàm reset state về mặc định
  void _resetStateToDefault() {
    _logEntries = [];
    _totalCaloriesToday = 0;
    _totalProtein = 0;
    _totalCarbs = 0;
    _totalFat = 0;
    _calorieGoal = 2000;
    _isLoading = false;
    _selectedDate = DateTime.now();
    _weightHistory = []; // Reset cả lịch sử cân nặng
    // Không cần notifyListeners() ở đây
  }

  // --- Hàm Khởi tạo Dữ liệu ---
  Future<void> _initializeData() async {
    if (mountedSafe) {
      // Sử dụng getter an toàn
      _isLoading = true;
      notifyListeners();
    }

    await Future.wait([
      fetchCalorieGoal(),
      fetchLogEntries(_selectedDate),
      // fetchWeightHistory(), // Bỏ comment dòng này nếu muốn tải lịch sử cân nặng cùng lúc
    ]);

    if (mountedSafe) {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Các Hàm Tương tác Firestore ---

  // 7. Lấy mục tiêu calo
  Future<void> fetchCalorieGoal() async {
    if (_userId == null || _userId.isEmpty) return;
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
          print("Fetched calorie goal: $_calorieGoal");
        } else {
          print("Calorie goal field not found, setting default and saving.");
          if (mountedSafe) await setCalorieGoal(_calorieGoal);
        }
      } else {
        print("Calorie goal document not found, creating with default.");
        if (mountedSafe) await setCalorieGoal(_calorieGoal);
      }
    } catch (e) {
      print("Error fetching calorie goal: $e");
      if (mountedSafe) _calorieGoal = 2000; // Giữ giá trị mặc định nếu lỗi
    }
  }

  // 8. Lưu mục tiêu calo
  Future<void> setCalorieGoal(double newGoal) async {
    if (_userId == null || _userId.isEmpty) return;
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
      print("Successfully set calorie goal to $newGoal");
    } catch (e) {
      print("Error setting calorie goal: $e");
      // Có thể fetch lại để đảm bảo state đúng nếu cần
      // if(mountedSafe) await fetchCalorieGoal();
    }
  }

  // 9. Lấy nhật ký ăn uống cho một ngày
  Future<void> fetchLogEntries(DateTime date) async {
    if (_userId == null || _userId.isEmpty) return;

    final dateString = _formatDate(date);
    // Không set isLoading ở đây nếu được gọi từ _initializeData hoặc changeSelectedDate
    // bool setLoading = !_isLoading; // Chỉ set loading nếu chưa loading
    // if(setLoading && mountedSafe) { setState(() => _isLoading = true); notifyListeners(); }

    try {
      print("Fetching log entries for date: $dateString");
      final querySnapshot =
          await _firestore
              .collection('users')
              .doc(_userId)
              .collection('dailyLogs')
              .where('date', isEqualTo: dateString)
              .orderBy('timestamp', descending: true)
              .get();

      if (mountedSafe) {
        // Kiểm tra trước khi cập nhật state
        _logEntries =
            querySnapshot.docs
                .map((doc) => DailyLogEntry.fromSnapshot(doc))
                .toList();
        _calculateTotals(); // Tính lại tổng calo và macro
        print("Fetched ${_logEntries.length} entries for $dateString");
        notifyListeners(); // Thông báo sau khi tính toán xong
      }
    } catch (e) {
      print("Error fetching log entries for $dateString: $e");
      if (mountedSafe) {
        _logEntries = [];
        _calculateTotals(); // Tính lại tổng (sẽ về 0)
        notifyListeners();
      }
    }
    // finally {
    //    if(setLoading && mountedSafe) { setState(() => _isLoading = false); notifyListeners(); }
    // }
  }

  // 10. Thêm mục nhật ký ăn uống
  Future<void> addLogEntry(DailyLogEntry entry) async {
    if (_userId == null || _userId.isEmpty) return;
    final entryDateString = entry.date;

    try {
      final docRef = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('dailyLogs')
          .add(entry.toJson());
      print("Added log entry with ID: ${docRef.id}");

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
      } else {
        print(
          "Log entry added for a different date ($entryDateString), not updating current list.",
        );
      }
    } catch (e) {
      print("Error adding log entry: $e");
      // Xử lý lỗi (ví dụ: thông báo cho người dùng)
    }
  }

  // 11. Xóa mục nhật ký ăn uống
  Future<void> deleteLogEntry(String entryId) async {
    if (_userId == null || _userId.isEmpty || entryId.isEmpty) return;
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
      print("Deleted log entry: $entryId");

      if (indexToRemove != -1 && mountedSafe) {
        _logEntries.removeAt(indexToRemove);
        _calculateTotals();
        notifyListeners();
      }
    } catch (e) {
      print("Error deleting log entry $entryId: $e");
    }
  }

  // --- HÀM MỚI CHO CÂN NẶNG ---
  // 11.5. Lấy lịch sử cân nặng
  Future<void> fetchWeightHistory({int limit = 30}) async {
    if (_userId == null || _userId.isEmpty) return;
    // Có thể thêm cờ isLoading riêng cho weight history nếu muốn
    // bool _isWeightLoading = true; notifyListeners();
    try {
      final querySnapshot =
          await _firestore
              .collection('users')
              .doc(_userId)
              .collection('weightLogs') // Truy cập collection weightLogs
              .orderBy('timestamp', descending: true)
              .limit(limit)
              .get();

      if (mountedSafe) {
        _weightHistory =
            querySnapshot.docs
                .map((doc) => WeightEntry.fromSnapshot(doc))
                .toList();
        // Sắp xếp lại theo thứ tự thời gian tăng dần để vẽ biểu đồ
        _weightHistory.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        print("Fetched ${_weightHistory.length} weight entries.");
        notifyListeners(); // Thông báo cho UI cập nhật
      }
    } catch (e) {
      print("Error fetching weight history: $e");
      if (mountedSafe) _weightHistory = []; // Đặt lại list rỗng nếu lỗi
      // notifyListeners(); // Có thể notify để xóa biểu đồ cũ nếu lỗi
    } finally {
      // if(mountedSafe) _isWeightLoading = false; notifyListeners();
    }
  }

  // 11.6. Thêm mục cân nặng mới
  Future<void> addWeightEntry(double weight) async {
    if (_userId == null || _userId.isEmpty) return;
    final newEntry = WeightEntry(weight: weight, timestamp: Timestamp.now());
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('weightLogs')
          .add(newEntry.toJson());
      print("Added new weight entry: $weight kg");
      // Tải lại lịch sử để cập nhật biểu đồ/danh sách
      // Chúng ta gọi lại fetchWeightHistory thay vì thêm trực tiếp vào list và sort
      // để đảm bảo tính nhất quán và đơn giản hóa logic.
      if (mountedSafe) await fetchWeightHistory();
    } catch (e) {
      print("Error adding weight entry: $e");
      // Xử lý lỗi (ví dụ: thông báo cho người dùng)
    }
  }
  // --- KẾT THÚC HÀM MỚI CHO CÂN NẶNG ---

  // --- Các Hàm Tiện Ích và Quản lý State ---

  // 12. Hàm thay đổi ngày đang xem nhật ký
  Future<void> changeSelectedDate(DateTime newDate) async {
    if (_formatDate(newDate) != _formatDate(_selectedDate)) {
      if (mountedSafe) {
        _selectedDate = newDate;
        print("Selected date changed to: ${_formatDate(_selectedDate)}");
        _isLoading = true; // Bật loading cho việc fetch log
        notifyListeners();
      }

      // Fetch dữ liệu cho ngày mới
      await fetchLogEntries(
        newDate,
      ); // Hàm này sẽ gọi notifyListeners sau khi xong

      if (mountedSafe) {
        _isLoading = false; // Tắt loading sau khi fetch xong
        // Không cần notifyListeners lần nữa vì fetchLogEntries đã gọi
      }
    }
  }

  // 13. Hàm tính tổng Calo và Macros (Đã gộp lại)
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

  // 14. Hàm định dạng ngày
  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // --- Getter an toàn để kiểm tra mounted ---
  // Thêm getter này để tránh lỗi khi gọi notifyListeners sau khi widget bị dispose
  // (Mặc dù trong Provider thì ít gặp hơn so với StatefulWidget trực tiếp)
  bool _mounted = true; // Giả sử là true khi khởi tạo
  bool get mountedSafe => _mounted;

  // Ghi đè phương thức dispose của ChangeNotifier
  @override
  void dispose() {
    _mounted = false; // Đánh dấu là đã dispose
    print("CalorieProvider disposed");
    super.dispose();
  }
}
