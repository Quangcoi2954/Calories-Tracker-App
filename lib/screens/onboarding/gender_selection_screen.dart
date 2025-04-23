// lib/screens/onboarding/gender_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts

import '../../providers/onboarding_provider.dart';
import 'age_input_screen.dart'; // Màn hình tiếp theo

// Đảm bảo Enum có giá trị 'other'
enum Gender { male, female, other }

class GenderSelectionScreen extends StatefulWidget {
  @override
  _GenderSelectionScreenState createState() => _GenderSelectionScreenState();
}

class _GenderSelectionScreenState extends State<GenderSelectionScreen> {
  Gender? _selectedGender; // Bắt đầu mà không chọn gì

  // Hàm xử lý khi nhấn Tiếp tục
  void _goToNextStep() {
    if (_selectedGender != null) {
      final provider = Provider.of<OnboardingProvider>(context, listen: false);
      String genderString;
      switch (_selectedGender!) {
        case Gender.male:
          genderString = 'male';
          break;
        case Gender.female:
          genderString = 'female';
          break;
        case Gender.other:
          genderString = 'other'; // Lưu giá trị 'other'
          break;
      }
      provider.setGender(genderString);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AgeInputScreen()),
      );
    }
    // Nút bị vô hiệu hóa nếu _selectedGender là null, nên không cần xử lý else
  }

  @override
  Widget build(BuildContext context) {
    // Định nghĩa màu sắc chủ đạo mới
    final primaryColor = Colors.greenAccent[700]; // Vẫn dùng màu xanh lá theme
    final coralColor = const Color(0xFFFF7F50); // Màu cam san hô (Coral)

    return Scaffold(
      // --- AppBar ---
      appBar: AppBar(
        automaticallyImplyLeading: false, // Không có nút back
        backgroundColor: Colors.grey[200],
        elevation: 0,
        centerTitle: true,
        title: Text(
          'compleat NUTRITION', // Chỉ hiển thị 'compleat' hoặc logo nếu có
          style: GoogleFonts.poppins(
            color: primaryColor, // Màu xanh lá
            fontWeight: FontWeight.w600, // Đậm hơn
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                '1 / 4',
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
          padding: const EdgeInsets.symmetric(
            horizontal: 30.0,
          ), // Padding chung
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween, // Để nút ở dưới cùng
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.05),
              // --- Tiêu đề chính ---
              Text(
                'Giới tính của bạn là gì?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 40),

              // --- Các lựa chọn giới tính ---
              _buildGenderOption(
                value: Gender.female,
                icon: Icons.female_rounded,
                label: 'Female',
                selectedColor: coralColor,
              ),
              SizedBox(height: 15),
              _buildGenderOption(
                value: Gender.male,
                icon: Icons.male_rounded,
                label: 'Male',
                selectedColor: coralColor,
              ),
              SizedBox(height: 15),
              _buildGenderOption(
                value: Gender.other,
                icon: Icons.transgender_rounded, // Hoặc Icons.wc
                label: 'Other',
                selectedColor: coralColor,
              ),

              Spacer(), // Đẩy nút xuống dưới cùng
              // --- Nút Tiếp tục ---
              Padding(
                padding: const EdgeInsets.only(bottom: 40.0, top: 20.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    // Nút bị vô hiệu hóa nếu chưa chọn giới tính
                    onPressed: _selectedGender == null ? null : _goToNextStep,
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
                      backgroundColor: coralColor, // Màu cam san hô cho nút
                      disabledBackgroundColor: coralColor.withOpacity(
                        0.5,
                      ), // Màu mờ đi khi bị vô hiệu hóa
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

  // === WIDGET HELPER CHO MỖI LỰA CHỌN GIỚI TÍNH ===
  Widget _buildGenderOption({
    required Gender value,
    required IconData icon,
    required String label,
    required Color selectedColor,
  }) {
    final bool isSelected = (_selectedGender == value);

    return GestureDetector(
      onTap: () => setState(() => _selectedGender = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: Colors.white, // Nền thẻ luôn trắng
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            // Đổi màu viền khi được chọn
            color: isSelected ? selectedColor : Colors.grey[300]!,
            width: isSelected ? 2.0 : 1.5, // Viền dày hơn khi chọn
          ),
          boxShadow:
              isSelected
                  ? [
                    // Thêm đổ bóng nhẹ khi chọn
                    BoxShadow(
                      color: selectedColor.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                    ),
                  ]
                  : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 28,
              color:
                  isSelected
                      ? selectedColor
                      : Colors.grey[600], // Icon đổi màu khi chọn
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.black87 : Colors.grey[700],
                ),
              ),
            ),
            Radio<Gender>(
              value: value,
              groupValue: _selectedGender,
              onChanged: (Gender? newValue) {
                setState(() => _selectedGender = newValue);
              },
              activeColor: selectedColor, // Màu khi radio được chọn
              // visualDensity: VisualDensity.compact, // Làm radio nhỏ gọn hơn nếu cần
            ),
          ],
        ),
      ),
    );
  }

  // === KẾT THÚC WIDGET HELPER ===
}
