// lib/screens/onboarding/age_input_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/onboarding_provider.dart';
import 'weight_input_screen.dart'; // Màn hình tiếp theo

class AgeInputScreen extends StatefulWidget {
  @override
  _AgeInputScreenState createState() => _AgeInputScreenState();
}

class _AgeInputScreenState extends State<AgeInputScreen> {
  int _currentAge = 25; // Giá trị tuổi mặc định ban đầu
  final int _minAge = 10;
  final int _maxAge = 100;

  // *** THÊM SCROLL CONTROLLER ***
  late FixedExtentScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    // Khởi tạo controller với vị trí ban đầu tương ứng với _currentAge
    // Index = Giá trị tuổi - Giá trị nhỏ nhất
    _scrollController = FixedExtentScrollController(
      initialItem: _currentAge - _minAge,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Nhớ dispose controller
    super.dispose();
  }

  void _goToNextStep() {
    // Validation cơ bản
    if (_currentAge < _minAge || _currentAge > _maxAge) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Tuổi không hợp lệ')));
      return;
    }
    Provider.of<OnboardingProvider>(context, listen: false).setAge(_currentAge);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WeightInputScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final highlightColor = Colors.greenAccent[700]!; // Màu xanh lá mạ đậm
    final int itemCount = _maxAge - _minAge + 1; // Tổng số tuổi cần hiển thị

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
                '2 / 4',
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
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20.0, bottom: 40.0),
                child: Text(
                  'Bạn bao nhiêu tuổi?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),

              // --- THAY THẾ NumberPicker BẰNG ListWheelScrollView ---
              Expanded(
                child: Center(
                  child: SizedBox(
                    // Giới hạn chiều rộng của ListWheelScrollView
                    width: 150, // Điều chỉnh chiều rộng nếu muốn
                    height: 800, // Đặt chiều cao cố định hoặc để Expanded xử lý
                    child: ListWheelScrollView.useDelegate(
                      controller: _scrollController, // Gán controller
                      itemExtent: 80, // Chiều cao của mỗi item tuổi
                      perspective: 0.002, // Độ cong của bánh xe
                      diameterRatio:
                          1.5, // Tỷ lệ đường kính (ảnh hưởng độ cong)
                      physics:
                          FixedExtentScrollPhysics(), // Kiểu cuộn của bánh xe
                      onSelectedItemChanged: (index) {
                        // index là vị trí trong danh sách (từ 0)
                        // Cập nhật _currentAge dựa trên index và _minAge
                        setState(() {
                          _currentAge = _minAge + index;
                          print("Selected Age: $_currentAge");
                        });
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: itemCount, // Số lượng tuổi = max - min + 1
                        builder: (context, index) {
                          final int age = _minAge + index; // Tính tuổi từ index
                          final bool isSelected =
                              (age ==
                                  _currentAge); // Kiểm tra có phải item đang chọn không

                          // Style cho số chưa chọn
                          TextStyle unselectedStyle = GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[350],
                          );

                          // Style cho số được chọn
                          TextStyle selectedStyle = GoogleFonts.poppins(
                            fontSize: 40, // Có thể giảm nếu vẫn bị cắt
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          );

                          // Container bao bọc item được chọn
                          Widget selectedItemWidget = Container(
                            width: 120, // Chiều rộng khớp với itemWidth cũ
                            height: 80, // Chiều cao khớp itemExtent
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: highlightColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(age.toString(), style: selectedStyle),
                          );

                          // Text đơn giản cho item không được chọn
                          Widget unselectedItemWidget = Center(
                            child: Text(age.toString(), style: unselectedStyle),
                          );

                          // Trả về widget tương ứng
                          return isSelected
                              ? selectedItemWidget
                              : unselectedItemWidget;
                        },
                      ),
                    ),
                  ),
                ),
              ),
              // --- KẾT THÚC ListWheelScrollView ---

              // --- Nút Tiếp tục (Giữ nguyên) ---
              Padding(
                padding: const EdgeInsets.only(bottom: 40.0, top: 20.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    /* ... */
                    onPressed: _goToNextStep,
                    child: Text(
                      'Tiếp Tục',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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
}
