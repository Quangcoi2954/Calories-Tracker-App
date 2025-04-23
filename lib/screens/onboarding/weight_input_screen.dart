// lib/screens/onboarding/weight_input_screen.dart
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:numberpicker/numberpicker.dart';
import 'dart:math' as math;

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
  double _currentWeightKg = 60.0;
  final double _minWeightKg = 20.0;
  final double _maxWeightKg = 200.0;

  // Conversion Factors & Helpers
  final double kgToLbsFactor = 2.20462;
  double get _currentDisplayWeight {
    double displayValue =
        (_selectedUnit == WeightUnit.lbs)
            ? _currentWeightKg * kgToLbsFactor
            : _currentWeightKg;
    return (displayValue * 10).round() / 10;
  }

  String get _currentUnitString =>
      _selectedUnit == WeightUnit.kg ? 'Kg' : 'Lbs';
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
      });
    }
  }

  // Hàm xử lý khi giá trị picker thay đổi
  void _onWeightChanged(double newValue) {
    setState(() {
      if (_selectedUnit == WeightUnit.lbs) {
        _currentWeightKg = newValue / kgToLbsFactor;
      } else {
        _currentWeightKg = newValue;
      }
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
    // *** ĐỊNH NGHĨA MÀU SẮC MỚI ***
    final darkGreenBg = Colors.lightGreen[800]!; // Màu nền xanh lá mạ đậm
    final textOnDark = Colors.white; // Màu chữ chính trên nền đậm
    final textOnDarkFaded = Colors.white70; // Màu chữ mờ hơn trên nền đậm
    final highlightColor =
        Colors.white; // Màu highlight (nền nút chọn đơn vị, đường kẻ picker)
    final textOnHighlight = darkGreenBg; // Màu chữ trên nền highlight (trắng)

    return Scaffold(
      // --- AppBar với nền đậm ---
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: textOnDark,
          ), // Icon màu trắng
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: darkGreenBg, // Nền AppBar cùng màu body
        elevation: 0,
        centerTitle: true,
        title: Text(
          'compleat NUTRITION',
          style: GoogleFonts.poppins(
            color: textOnDark, // Chữ trắng
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
                  color: textOnDarkFaded, // Chữ trắng mờ
                ),
              ),
            ),
          ),
        ],
      ),
      // --- Body với nền đậm ---
      backgroundColor: darkGreenBg, // *** ĐỔI MÀU NỀN BODY ***
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              // --- Tiêu đề màu trắng ---
              Text(
                'Cân nặng hiện tại của bạn?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: textOnDark, // *** ĐỔI MÀU CHỮ ***
                ),
              ),
              SizedBox(height: 20),

              // --- Bộ chọn Đơn vị (Style mới) ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    // Nền tối hơn một chút hoặc viền trắng
                    color: Colors.black.withOpacity(0.1),
                    // border: Border.all(color: Colors.white30),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildUnitButton(
                          WeightUnit.kg,
                          highlightColor,
                          textOnHighlight,
                          textOnDarkFaded,
                        ),
                      ),
                      SizedBox(width: 5),
                      Expanded(
                        child: _buildUnitButton(
                          WeightUnit.lbs,
                          highlightColor,
                          textOnHighlight,
                          textOnDarkFaded,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),

              // --- Hiển thị Cân nặng Lớn màu trắng ---
              Text(
                '${_currentDisplayWeight.toStringAsFixed(1)} $_currentUnitString',
                style: GoogleFonts.poppins(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: textOnDark, // *** ĐỔI MÀU CHỮ ***
                ),
              ),
              SizedBox(height: 30),

              // --- DecimalNumberPicker (Style mới) ---
              DecimalNumberPicker(
                minValue: _minWeightForPicker.floor(),
                maxValue: _maxWeightForPicker.ceil(),
                value: _currentDisplayWeight,
                onChanged: _onWeightChanged,
                decimalPlaces: 1,
                axis: Axis.horizontal,
                itemHeight: 60,
                itemWidth: 80,
                haptics: true,
                itemCount: 5,
                // Style số chưa chọn (trắng mờ)
                textStyle: GoogleFonts.poppins(
                  fontSize: 20,
                  color: textOnDarkFaded,
                ),
                // Style số được chọn (trắng đậm)
                selectedTextStyle: GoogleFonts.poppins(
                  fontSize: 32,
                  color: textOnDark,
                  fontWeight: FontWeight.bold,
                ),
                // Decoration viền dọc màu trắng
                decimalDecoration: BoxDecoration(
                  border: Border.symmetric(
                    vertical: BorderSide(
                      color: highlightColor,
                      width: 2,
                    ), // Viền dọc màu trắng
                  ),
                ),
              ),

              // --- KẾT THÚC DecimalNumberPicker ---
              Spacer(), // Đẩy nút Tiếp Tục xuống dưới
              // --- Nút Tiếp tục (Style mới) ---
              Padding(
                padding: const EdgeInsets.only(
                  left: 10.0,
                  right: 10.0,
                  bottom: 30.0,
                  top: 10,
                ),
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
                            color: textOnHighlight,
                          ), // Chữ màu nền đậm
                        ),
                        SizedBox(width: 10),
                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: textOnHighlight.withOpacity(0.3),
                          ), // Vòng tròn màu nền đậm mờ
                          child: Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: textOnHighlight,
                          ), // Icon màu nền đậm
                        ),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          highlightColor, // Nền nút màu trắng (highlight)
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

  // Helper Widget cho nút chọn đơn vị (Cập nhật màu sắc)
  Widget _buildUnitButton(
    WeightUnit unit,
    Color selectedBgColor,
    Color selectedTextColor,
    Color unselectedTextColor,
  ) {
    bool isSelected = _selectedUnit == unit;
    String text = unit == WeightUnit.kg ? 'Kg' : 'Lbs';

    return GestureDetector(
      onTap: () => _onUnitSelected(unit),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          // Nền trắng khi chọn, trong suốt khi không chọn (để thấy nền container cha)
          color: isSelected ? selectedBgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
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
              // Chữ màu nền đậm khi chọn, chữ trắng mờ khi không chọn
              color: isSelected ? selectedTextColor : unselectedTextColor,
            ),
          ),
        ),
      ),
    );
  }
}
