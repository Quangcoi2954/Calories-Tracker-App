import 'package:cloud_firestore/cloud_firestore.dart';

class DailyLogEntry {
  final String? id; // ID của document trong Firestore (tùy chọn)
  final String foodName;
  final String foodId;
  final Timestamp timestamp;
  final String date; // 'YYYY-MM-DD'
  final double calories;
  final double quantity;
  final String unit;
  final double? protein; // Tổng protein đã tính (nullable)
  final double? carbs; // Tổng carb đã tính (nullable)
  final double? fat; // Tổng fat đã tính (nullable)

  DailyLogEntry({
    this.id,
    required this.foodName,
    required this.foodId,
    required this.calories,
    required this.quantity,
    required this.unit,
    required this.timestamp,
    required this.date,
    this.protein, // Thêm vào constructor
    this.carbs, // Thêm vào constructor
    this.fat, // Thêm vào constructor
  });

  // Chuyển đổi từ Firestore DocumentSnapshot thành đối tượng Dart
  factory DailyLogEntry.fromSnapshot(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return DailyLogEntry(
      id: doc.id,
      foodName: data['foodName'] ?? 'N/A',
      foodId: data['foodId'] ?? 'N/A',
      calories: (data['calories'] ?? 0.0).toDouble(),
      quantity: (data['quantity'] ?? 0.0).toDouble(),
      unit: data['unit'] ?? 'N/A',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      date: data['date'] ?? '',
      protein: (data['protein'] as num?)?.toDouble(), // Chuyển đổi an toàn
      carbs: (data['carbs'] as num?)?.toDouble(), // Chuyển đổi an toàn
      fat: (data['fat'] as num?)?.toDouble(), // Chuyển đổi an toàn
    );
  }

  // Chuyển đổi từ đối tượng Dart thành Map để lưu vào Firestore
  Map<String, dynamic> toJson() {
    return {
      'foodName': foodName,
      'foodId': foodId,
      'calories': calories,
      'quantity': quantity,
      'unit': unit,
      'timestamp': timestamp,
      'date': date,
      'protein': protein, // Thêm vào map
      'carbs': carbs, // Thêm vào map
      'fat': fat, // Thêm vào map
    };
  }
}
