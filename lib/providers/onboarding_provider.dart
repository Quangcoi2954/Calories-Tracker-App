// lib/providers/onboarding_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Cần cho WriteBatch và Firestore
import '../utils/calorie_calculator.dart'; // Import hàm tính toán

class OnboardingProvider extends ChangeNotifier {
  String? gender;
  int? age;
  double? weight;
  double? height;

  // Các hàm để cập nhật giá trị từ các màn hình onboarding
  void setGender(String value) {
    gender = value;
    // Không cần notifyListeners() ở đây nếu chỉ dùng để lưu trữ tạm
    // Chỉ notify nếu có widget nào đó cần lắng nghe sự thay đổi này ngay lập tức
    // notifyListeners();
    print("OnboardingProvider: Gender set to $gender");
  }

  void setAge(int value) {
    age = value;
    print("OnboardingProvider: Age set to $age");
    // notifyListeners();
  }

  void setWeight(double value) {
    weight = value;
    print("OnboardingProvider: Weight set to $weight");
    // notifyListeners();
  }

  void setHeight(double value) {
    height = value;
    print("OnboardingProvider: Height set to $height");
    // notifyListeners();
  }

  // Hàm thực hiện tính toán và lưu tất cả dữ liệu vào Firestore
  // Trả về double? là calorie goal đã tính, hoặc null nếu lỗi
  Future<double?> calculateAndSaveData(String userId) async {
    // Đảm bảo tất cả dữ liệu đã được thu thập
    if (gender == null || age == null || weight == null || height == null) {
      print("OnboardingProvider Error: Missing data for calculation.");
      throw Exception(
        "Dữ liệu onboarding bị thiếu.",
      ); // Ném lỗi để màn hình UI xử lý
    }

    // --- Tính toán Calo cần thiết (TDEE) ---
    final double activityFactor =
        1.375; // Giữ mặc định hoặc lấy từ state nếu có
    final double calculatedTDEE = CalorieCalculator.calculateTDEE(
      weight: weight!, // Dùng ! vì đã kiểm tra null ở trên
      height: height!,
      age: age!,
      gender: gender!,
      activityFactor: activityFactor,
    );
    final double calculatedGoal = calculatedTDEE.roundToDouble();

    print('OnboardingProvider: Calculated Daily Calorie Goal: $calculatedGoal');

    // --- Lưu thông tin vào Firestore ---
    try {
      final firestore = FirebaseFirestore.instance;
      final userDocRef = firestore.collection('users').doc(userId);
      WriteBatch batch = firestore.batch();

      // 1. Lưu profile
      final profileRef = userDocRef.collection('profile').doc('details');
      batch.set(profileRef, {
        'weight': weight,
        'height': height,
        'age': age,
        'gender': gender,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Lưu mục tiêu calo
      final settingsRef = userDocRef.collection('settings').doc('calorieGoal');
      batch.set(settingsRef, {
        'goal': calculatedGoal,
        'calculationDetails': {
          'bmrFormula': 'Mifflin-St Jeor',
          'activityFactor': activityFactor,
          'calculatedTDEE': calculatedTDEE,
          'timestamp': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

      await batch.commit(); // Thực hiện lưu
      print(
        'OnboardingProvider: User data and goal saved successfully for userId: $userId',
      );
      return calculatedGoal; // Trả về mục tiêu đã tính
    } catch (e) {
      print("OnboardingProvider Error saving data: $e");
      throw Exception("Lỗi khi lưu dữ liệu: $e"); // Ném lỗi để UI xử lý
    }
  }

  // (Tùy chọn) Hàm để reset dữ liệu khi onboarding hoàn tất hoặc hủy
  void clearData() {
    gender = null;
    age = null;
    weight = null;
    height = null;
    notifyListeners(); // Thông báo để reset state nếu cần
  }
}
