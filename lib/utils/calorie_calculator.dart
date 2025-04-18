// lib/utils/calorie_calculator.dart

class CalorieCalculator {
  // Tính BMR (Basal Metabolic Rate) bằng công thức Mifflin-St Jeor
  static double calculateBMR({
    required double weight, // kg
    required double height, // cm
    required int age, // years
    required String gender, // 'male' or 'female'
  }) {
    if (gender.toLowerCase() == 'male') {
      // Công thức cho nam
      return (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else if (gender.toLowerCase() == 'female') {
      // Công thức cho nữ
      return (10 * weight) + (6.25 * height) - (5 * age) - 161;
    } else {
      // Trường hợp giới tính không hợp lệ (nên được validate trước khi gọi)
      throw ArgumentError('Invalid gender provided. Use "male" or "female".');
    }
  }

  // Tính TDEE (Total Daily Energy Expenditure)
  static double calculateTDEE({
    required double weight,
    required double height,
    required int age,
    required String gender,
    double activityFactor = 1.375, // Hệ số vận động mặc định (vận động nhẹ)
    // 1.2: Ít vận động (công việc văn phòng)
    // 1.375: Vận động nhẹ (1-3 ngày/tuần)
    // 1.55: Vận động vừa (3-5 ngày/tuần)
    // 1.725: Vận động nhiều (6-7 ngày/tuần)
    // 1.9: Vận động rất nhiều (công việc chân tay nặng nhọc, VĐV)
  }) {
    final double bmr = calculateBMR(
      weight: weight,
      height: height,
      age: age,
      gender: gender,
    );
    return bmr * activityFactor;
  }
}
