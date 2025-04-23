// lib/screens/onboarding/weight_input_screen.dart
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'; // Không cần cho picker
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:numberpicker/numberpicker.dart'; // *** THÊM LẠI IMPORT NUMBER PICKER ***
import 'dart:math' as math; // Cần cho làm tròn

import '../../providers/onboarding_provider.dart';
import 'height_input_screen.dart'; // Màn hình tiếp theo

enum WeightUnit { kg, lbs }

class WeightInputScreen extends StatefulWidget {
  @override
  _WeightInputScreenState createState() => _WeightInputScreenState();
}

class _WeightInputScreenState extends State<WeightInputScreen> {
  // State Variables
  WeightUnit _selectedUnit = WeightUnit.kg;
  double _currentWeightKg = 60.0; // Luôn lưu trữ giá trị gốc là Kg
  final double _minWeightKg = 20.0;
  final double _maxWeightKg = 200.0;

  // Conversion Factors & Helpers
  final double kgToLbsFactor = 2.20462;

  // Tính giá trị hiển thị dựa trên đơn vị chọn
  double get _currentDisplayWeight {
    double displayValue =
        (_selectedUnit == WeightUnit.lbs)
            ? _currentWeightKg * kgToLbsFactor
            : _currentWeightKg;
    // Làm tròn đến 1 chữ số thập phân cho hiển thị picker
    return (displayValue * 10).round() / 10;
  }

  String get _currentUnitString =>
      _selectedUnit == WeightUnit.kg ? 'Kg' : 'Lbs';
  String get _currentUnitSuffix =>
      _selectedUnit == WeightUnit.kg ? 'kg' : 'lbs';

  // Tính min/max cho picker dựa trên đơn vị chọn
  double get _minWeightForPicker =>
      (_selectedUnit == WeightUnit.kg
              ? _minWeightKg
              : _minWeightKg * kgToLbsFactor)
          .roundToDouble();
  double get _maxWeightForPicker =>
      (_selectedUnit == WeightUnit.kg
              ? _maxWeightKg
              : _maxWeightKg * kgToLbsFactor)
          .roundToDouble();

  // Hàm xử lý khi đơn vị thay đổi
  void _onUnitSelected(WeightUnit unit) {
    if (_selectedUnit != unit) {
      setState(() {
        _selectedUnit = unit;
        // Không cần chuyển đổi _currentWeightKg vì nó luôn là Kg
        // Giá trị hiển thị sẽ tự động cập nhật qua getter _currentDisplayWeight
      });
    }
  }

  // Hàm xử lý khi giá trị picker thay đổi
  void _onWeightChanged(double newValue) {
    // newValue là giá trị hiển thị (có thể là kg hoặc lbs)
    setState(() {
      if (_selectedUnit == WeightUnit.lbs) {
        // Chuyển lbs về kg để lưu trữ
        _currentWeightKg = newValue / kgToLbsFactor;
      } else {
        // Giữ nguyên giá trị kg
        _currentWeightKg = newValue;
      }
      // Giới hạn lại giá trị kg trong khoảng min/max gốc
      _currentWeightKg = _currentWeightKg.clamp(_minWeightKg, _maxWeightKg);
      print(
        "Selected display value: $newValue $_currentUnitString, Stored Kg: ${_currentWeightKg.toStringAsFixed(2)}",
      );
    });
  }

  void _goToNextStep() {
    Provider.of<OnboardingProvider>(
      context,
      listen: false,
    ).setWeight(_currentWeightKg);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HeightInputScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final lightGreen = Colors.lime[100]!;
    final highlightColor = Colors.greenAccent[700]!;

    return Scaffold(
      appBar: AppBar(
        /* ... AppBar như cũ ... */
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Colors.grey[700],
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'compleat NUTRITION',
          style: GoogleFonts.poppins(
            color: primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                '3 / 4',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[500],
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          // Thêm Padding tổng thể
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              Text(
                'Cân nặng hiện tại của bạn?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 20),

              // Bộ chọn Đơn vị
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40.0,
                ), // Padding lớn hơn cho nút nhỏ lại
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: lightGreen,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildUnitButton(WeightUnit.kg, primaryColor),
                      ),
                      SizedBox(width: 5),
                      Expanded(
                        child: _buildUnitButton(WeightUnit.lbs, primaryColor),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),

              // Hiển thị Cân nặng Lớn
              Text(
                // Sử dụng _currentDisplayWeight đã làm tròn và _currentUnitString
                '${_currentDisplayWeight.toStringAsFixed(1)} $_currentUnitString',
                style: GoogleFonts.poppins(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              SizedBox(height: 30),

              // --- THAY THẾ THƯỚC KẺ BẰNG DecimalNumberPicker ---
              DecimalNumberPicker(
                minValue:
                    _minWeightForPicker
                        .floor(), // Cần giá trị nguyên cho min/max của picker này
                maxValue: _maxWeightForPicker.ceil(),
                value: _currentDisplayWeight, // Giá trị hiển thị hiện tại
                onChanged: _onWeightChanged, // Hàm xử lý khi giá trị thay đổi
                decimalPlaces:
                    1, // Hiển thị 1 chữ số thập phân (cho phép bước nhảy 0.1)
                // integerOnly: false, // Mặc định là false cho DecimalNumberPicker
                axis: Axis.horizontal, // *** ĐẶT CHIỀU NGANG ***
                itemHeight: 60, // Chiều cao của picker ngang
                itemWidth: 80, // Chiều rộng của mỗi item số
                haptics: true,
                itemCount: 5, // Hiển thị 5 số cùng lúc (1 giữa, 2 hai bên)
                // Styling
                textStyle: GoogleFonts.poppins(
                  fontSize: 20,
                  color: Colors.grey[400],
                ),
                selectedTextStyle: GoogleFonts.poppins(
                  fontSize: 32,
                  color: highlightColor,
                  fontWeight: FontWeight.bold,
                ),
                // Decoration cho phần highlight (viền ngang thay vì hộp nền)
                decimalDecoration: BoxDecoration(
                  border: Border.symmetric(
                    vertical: BorderSide(
                      color: highlightColor,
                      width: 2,
                    ), // Vẽ viền dọc 2 bên số được chọn
                  ),
                ),
              ),

              // --- KẾT THÚC DecimalNumberPicker ---
              Spacer(), // Đẩy nút Tiếp Tục xuống dưới
              // Nút Tiếp tục
              Padding(
                padding: const EdgeInsets.only(
                  left: 10.0,
                  right: 10.0,
                  bottom: 30.0,
                  top: 10,
                ), // Giảm padding ngang
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _goToNextStep,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Tiếp Tục',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 10),
                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget cho nút chọn đơn vị (giữ nguyên)
  Widget _buildUnitButton(WeightUnit unit, Color primaryColor) {
    bool isSelected = _selectedUnit == unit;
    String text = unit == WeightUnit.kg ? 'Kg' : 'Lbs';
    return GestureDetector(
      onTap: () => _onUnitSelected(unit),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 3,
                    ),
                  ]
                  : [],
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? primaryColor : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}
