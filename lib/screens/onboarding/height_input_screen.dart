// lib/screens/onboarding/height_input_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math; // Dùng cho tính toán vị trí

import '../../providers/onboarding_provider.dart';
import '../../providers/calorie_provider.dart';
import '../../providers/auth_provider.dart';
import '../home_screen.dart';

class HeightInputScreen extends StatefulWidget {
  @override
  _HeightInputScreenState createState() => _HeightInputScreenState();
}

class _HeightInputScreenState extends State<HeightInputScreen> {
  // --- State Variables ---
  int _currentHeightCm = 165; // Giá trị tuổi mặc định ban đầu
  final int _minHeightCm = 100;
  final int _maxHeightCm = 230; // Giảm max height một chút

  late FixedExtentScrollController
  _scrollController; // Controller cho ListWheelScrollView
  final TextEditingController _heightController =
      TextEditingController(); // Controller cho TextField
  bool _isLoading = false;

  // --- State cho thanh chỉ báo ---
  final double _indicatorBarHeight =
      250.0; // Chiều cao cố định của thanh chỉ báo
  final List<int> _milestones = List.generate(
    14,
    (index) => 100 + index * 10,
  ); // Mốc mỗi 10cm từ 100 đến 230
  final int _stepValueCm = 10; // Giá trị bước giữa các mốc
  int? _activeMilestone; // Mốc đang được hiển thị số

  @override
  void initState() {
    super.initState();
    _scrollController = FixedExtentScrollController(
      initialItem: _currentHeightCm - _minHeightCm,
    );
    _heightController.text = _currentHeightCm.toString();
    _updateActiveMilestone(); // Tính mốc ban đầu

    // Lắng nghe thay đổi từ TextField để cập nhật Wheel và Bar
    _heightController.addListener(_syncFromTextField);
  }

  @override
  void dispose() {
    _heightController.removeListener(_syncFromTextField); // Hủy lắng nghe
    _scrollController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  // --- Logic đồng bộ và cập nhật ---

  // Cập nhật từ Wheel
  void _updateFromWheel(int index) {
    setState(() {
      _currentHeightCm = (_minHeightCm + index).clamp(
        _minHeightCm,
        _maxHeightCm,
      );
      // Chỉ cập nhật textfield nếu text hiện tại khác
      if (_heightController.text != _currentHeightCm.toString()) {
        _heightController.text = _currentHeightCm.toString();
        _moveCursorToEnd();
      }
      _updateActiveMilestone();
      print("Wheel changed to: $_currentHeightCm");
    });
  }

  // Cập nhật từ TextField
  void _syncFromTextField() {
    final String textValue = _heightController.text;
    final int? parsedValue = int.tryParse(textValue);
    if (parsedValue != null) {
      int clampedValue = parsedValue.clamp(_minHeightCm, _maxHeightCm);
      // Chỉ cập nhật state và scroll wheel nếu giá trị thực sự thay đổi
      if (_currentHeightCm != clampedValue) {
        setState(() {
          _currentHeightCm = clampedValue;
        });
        // Scroll bánh xe đến vị trí mới
        _scrollToHeight(clampedValue, isFromTextField: true);
        _updateActiveMilestone();
        print("TextField sync to: $_currentHeightCm");
      }
      // Cập nhật lại text nếu giá trị bị clamp
      if (clampedValue.toString() != textValue) {
        _heightController.text = clampedValue.toString();
        _moveCursorToEnd();
      }
    }
  }

  // Scroll bánh xe đến chiều cao cụ thể
  void _scrollToHeight(int height, {bool isFromTextField = false}) {
    int targetIndex = (height - _minHeightCm).clamp(
      0,
      _maxHeightCm - _minHeightCm,
    );
    // Chỉ animate nếu không phải do chính TextField gây ra (tránh vòng lặp)
    // và controller đã được gắn client
    if (_scrollController.hasClients) {
      _scrollController.animateToItem(
        targetIndex,
        duration: Duration(
          milliseconds: isFromTextField ? 50 : 300,
        ), // Nhanh hơn nếu từ TextField
        curve: Curves.easeInOut,
      );
    }
  }

  // Di chuyển con trỏ về cuối TextField
  void _moveCursorToEnd() {
    _heightController.selection = TextSelection.fromPosition(
      TextPosition(offset: _heightController.text.length),
    );
  }

  // Tìm mốc gần nhất với chiều cao hiện tại
  void _updateActiveMilestone() {
    int? closestMilestone;
    double minDifference = double.infinity;

    for (int milestone in _milestones) {
      double difference = (_currentHeightCm - milestone).abs().toDouble();
      // Ưu tiên mốc bằng hoặc nhỏ hơn gần nhất
      if (_currentHeightCm >= milestone && difference < minDifference) {
        minDifference = difference;
        closestMilestone = milestone;
      }
      // Nếu không tìm thấy mốc nhỏ hơn gần nhất, tìm mốc lớn hơn gần nhất
      else if (closestMilestone == null && difference < minDifference) {
        minDifference = difference;
        closestMilestone = milestone;
      }
      // Nếu đã có mốc nhỏ hơn, chỉ cập nhật nếu mốc lớn hơn gần hơn RẤT NHIỀU (ví dụ: gần hơn 1 nửa step)
      else if (closestMilestone != null &&
          _currentHeightCm < milestone &&
          difference < minDifference - (_stepValueCm / 2)) {
        minDifference = difference;
        closestMilestone = milestone;
      }
    }
    // Chỉ cập nhật state nếu mốc hoạt động thay đổi
    if (_activeMilestone != closestMilestone) {
      // Không cần setState ở đây vì hàm này thường được gọi bên trong setState khác
      _activeMilestone = closestMilestone;
    }
  }

  // --- Logic hoàn tất Onboarding (giữ nguyên) ---
  Future<void> _finishOnboarding() async {
    /* ... code như cũ, đọc _currentHeightCm ... */
    // Validate giá trị cuối cùng
    final number = _currentHeightCm;
    if (number < _minHeightCm || number > _maxHeightCm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng nhập chiều cao hợp lệ.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    if (mounted) setState(() => _isLoading = true);
    final height = _currentHeightCm.toDouble();
    final onboardingProvider = Provider.of<OnboardingProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final calorieProvider = Provider.of<CalorieProvider>(
      context,
      listen: false,
    );
    final userId = authProvider.user?.uid;
    if (userId == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: Không tìm thấy ID người dùng.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    double? savedGoal;
    try {
      onboardingProvider.setHeight(height);
      savedGoal = await onboardingProvider.calculateAndSaveData(userId);
      if (savedGoal != null && mounted) {
        await calorieProvider.setCalorieGoal(savedGoal);
        await _showGoalConfirmationDialog(savedGoal);
        onboardingProvider.clearData();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => HomeScreen()),
          (Route<dynamic> route) => false,
        );
        return;
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tính toán hoặc lưu mục tiêu.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Error during finishing onboarding: $e");
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xảy ra lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted && savedGoal == null) setState(() => _isLoading = false);
    }
  }

  // Dialog xác nhận (giữ nguyên)
  Future<void> _showGoalConfirmationDialog(double calculatedGoal) async {
    /* ... code dialog như cũ ... */
    final primaryColor = Theme.of(context).primaryColor;
    final darkGreenBg = Colors.lightGreen[800]!;
    final textOnDark = Colors.white;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          titlePadding: const EdgeInsets.only(
            top: 25.0,
            left: 24.0,
            right: 24.0,
            bottom: 10.0,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24.0,
            vertical: 15.0,
          ),
          actionsPadding: const EdgeInsets.only(bottom: 20.0, top: 10.0),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 10),
              Text(
                'Hoàn tất!',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.poppins(
                  fontSize: 16.0,
                  color: Colors.black87,
                  height: 1.5,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: 'Mục tiêu calo hàng ngày ước tính cho bạn là\n',
                  ),
                  TextSpan(
                    text: '${calculatedGoal.toStringAsFixed(0)} kcal',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: primaryColor,
                    ),
                  ),
                  TextSpan(
                    text:
                        '\n\nĐây là con số tham khảo, bạn có thể điều chỉnh trong Cài đặt.',
                  ),
                ],
              ),
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: darkGreenBg,
                foregroundColor: textOnDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                elevation: 3,
              ),
              child: Text(
                'Bắt đầu theo dõi',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    );
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final darkGreenBg = Colors.lightGreen[800]!;
    final textOnDark = Colors.white;
    final textOnDarkFaded = Colors.white70;
    final highlightColor = Colors.white;
    final textOnHighlight = darkGreenBg;

    return Scaffold(
      appBar: AppBar(
        /* ... AppBar như cũ ... */
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: textOnDark,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: darkGreenBg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'compleat NUTRITION',
          style: GoogleFonts.poppins(
            color: textOnDark,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                '4 / 4',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textOnDarkFaded,
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: darkGreenBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Chiều cao của bạn là bao nhiêu?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: textOnDark,
                ),
              ),
              SizedBox(height: 30),

              // --- Phần Hiển thị Chính: Wheel và Thanh Chỉ Báo ---
              Expanded(
                // Cho phần này chiếm không gian linh hoạt
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // --- Bánh xe cuộn dọc (ListWheelScrollView) ---
                    Container(
                      width: 100, // Chiều rộng cố định cho bánh xe
                      child: ListWheelScrollView.useDelegate(
                        controller: _scrollController,
                        itemExtent: 65, // Chiều cao mỗi item nhỏ hơn
                        perspective: 0.005,
                        diameterRatio: 1.8, // Tăng độ cong nhẹ
                        physics: FixedExtentScrollPhysics(),
                        onSelectedItemChanged:
                            _updateFromWheel, // Gọi hàm cập nhật
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: _maxHeightCm - _minHeightCm + 1,
                          builder: (context, index) {
                            final int age = _minHeightCm + index;
                            final bool isSelected = (age == _currentHeightCm);
                            return Center(
                              child: Text(
                                age.toString(),
                                style:
                                    isSelected
                                        ? GoogleFonts.poppins(
                                          fontSize: 36,
                                          color: textOnDark,
                                          fontWeight: FontWeight.bold,
                                        ) // Style khi chọn
                                        : GoogleFonts.poppins(
                                          fontSize: 24,
                                          color: textOnDarkFaded,
                                        ), // Style khi không chọn
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    SizedBox(
                      width: 25,
                    ), // Khoảng cách giữa wheel và thanh chỉ báo
                    // --- Thanh Chỉ Báo Dọc ---
                    _buildIndicatorBar(
                      highlightColor,
                      textOnDark,
                      textOnDarkFaded,
                    ),
                  ],
                ),
              ), // Kết thúc Expanded chứa Row
              // --- Ô Nhập Liệu Luôn Hiển Thị ---
              _buildHeightTextField(
                textOnDark,
                textOnDarkFaded,
                highlightColor,
              ),
              SizedBox(height: 20), // Khoảng cách trước nút bấm
              // --- Nút Hoàn Tất & Tính Toán ---
              Padding(
                padding: const EdgeInsets.only(
                  left: 10.0,
                  right: 10.0,
                  bottom: 30.0,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    /* ... Nút như cũ ... */
                    onPressed: _isLoading ? null : _finishOnboarding,
                    child:
                        _isLoading
                            ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: textOnHighlight,
                                strokeWidth: 3,
                              ),
                            )
                            : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Hoàn Tất & Tính Toán',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: textOnHighlight,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: textOnHighlight.withOpacity(0.3),
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 12,
                                    color: textOnHighlight,
                                  ),
                                ),
                              ],
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: highlightColor,
                      disabledBackgroundColor: highlightColor.withOpacity(0.7),
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

  // --- WIDGET HELPER CHO THANH CHỈ BÁO ---
  Widget _buildIndicatorBar(
    Color barColor,
    Color labelColorActive,
    Color labelColorInactive,
  ) {
    // Tính toán chiều cao phần đã đầy của thanh
    double filledHeight = 0;
    if (_maxHeightCm > _minHeightCm) {
      filledHeight =
          _indicatorBarHeight *
          (_currentHeightCm - _minHeightCm) /
          (_maxHeightCm - _minHeightCm);
      filledHeight = filledHeight.clamp(
        0,
        _indicatorBarHeight,
      ); // Đảm bảo không vượt quá chiều cao thanh
    }

    return Container(
      width: 60, // Chiều rộng tổng thể của khu vực thanh chỉ báo + nhãn
      height: _indicatorBarHeight,
      child: Stack(
        alignment: Alignment.bottomLeft, // Căn các thành phần theo đáy và trái
        children: [
          // --- Thanh nền ---
          Container(
            width: 12, // Chiều rộng của thanh chính
            height: _indicatorBarHeight,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15), // Màu nền mờ
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          // --- Phần đã đầy (Fill) ---
          // Sử dụng AnimatedContainer để thay đổi chiều cao mượt mà
          AnimatedContainer(
            duration: Duration(milliseconds: 150), // Thời gian animation
            curve: Curves.easeOut, // Kiểu animation
            width: 12,
            height: filledHeight, // Chiều cao động
            decoration: BoxDecoration(
              color: barColor, // Màu trắng highlight
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          // --- Các Mốc (Milestones) ---
          ..._milestones.map((milestone) {
            // Tính vị trí Y của mốc (từ dưới lên)
            double milestonePosition = 0;
            if (_maxHeightCm > _minHeightCm) {
              milestonePosition =
                  _indicatorBarHeight *
                  (milestone - _minHeightCm) /
                  (_maxHeightCm - _minHeightCm);
              milestonePosition = milestonePosition.clamp(
                0,
                _indicatorBarHeight,
              );
            }

            final bool isActive = (milestone == _activeMilestone);

            return Positioned(
              bottom:
                  milestonePosition - 4, // Dịch tâm chấm tròn vào đúng vị trí
              left: 0, // Đặt ở cạnh trái của Stack
              child: Row(
                // Dùng Row để đặt dấu chấm và nhãn cạnh nhau
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Dấu chấm tròn
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          isActive
                              ? barColor
                              : Colors.white30, // Màu trắng nếu active
                      border:
                          isActive
                              ? Border.all(color: Colors.white54, width: 1)
                              : null,
                    ),
                  ),
                  SizedBox(width: 8), // Khoảng cách giữa chấm và nhãn
                  // Nhãn số (chỉ hiển thị nếu active)
                  AnimatedOpacity(
                    // Hiệu ứng mờ dần
                    duration: Duration(milliseconds: 200),
                    opacity: isActive ? 1.0 : 0.0,
                    child: Text(
                      '${milestone}cm',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: labelColorActive, // Màu trắng
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // --- WIDGET HELPER CHO TEXT FIELD ---
  Widget _buildHeightTextField(
    Color textOnDark,
    Color textOnDarkFaded,
    Color highlightColor,
  ) {
    // Giữ nguyên style và logic của TextField như trước
    return Padding(
      /* ... code TextFormField như cũ ... */
      key: ValueKey('textfield'),
      padding: const EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 0,
      ), // Giảm padding ngang
      child: TextFormField(
        controller: _heightController,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textOnDark,
        ), // Giảm font size chút
        decoration: InputDecoration(
          hintText: 'Hoặc nhập tại đây (cm)',
          hintStyle: GoogleFonts.poppins(
            color: textOnDarkFaded.withOpacity(0.5),
          ),
          contentPadding: EdgeInsets.symmetric(
            vertical: 12,
          ), // Giảm padding dọc
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: highlightColor.withOpacity(0.5)),
          ), // Dùng UnderlineBorder
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: highlightColor, width: 2.0),
          ),
          errorBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.redAccent, width: 2.0),
          ),
        ),
        onChanged: (value) => _syncFromTextField(),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Vui lòng nhập';
          final number = int.tryParse(value);
          if (number == null || number < _minHeightCm || number > _maxHeightCm)
            return 'Không hợp lệ';
          return null;
        },
      ),
    );
  }
} // Kết thúc State Class
