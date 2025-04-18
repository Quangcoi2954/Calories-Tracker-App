// lib/screens/onboarding/height_input_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/onboarding_provider.dart';
import '../../providers/calorie_provider.dart';
import '../../providers/auth_provider.dart';
import '../home_screen.dart';

class HeightInputScreen extends StatefulWidget {
  @override
  _HeightInputScreenState createState() => _HeightInputScreenState();
}

class _HeightInputScreenState extends State<HeightInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _heightController.dispose();
    super.dispose();
  }

  // === HÀM MỚI ĐỂ HIỂN THỊ DIALOG ===
  Future<void> _showGoalConfirmationDialog(double calculatedGoal) async {
    // Sử dụng context của màn hình (this.context) vì hàm này thuộc State
    // Hoặc nếu gọi từ builder thì dùng context của builder
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Người dùng phải nhấn nút để đóng
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            // Bo góc dialog
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Row(
            // Thêm icon vào title
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Colors.green[600],
                size: 28,
              ),
              SizedBox(width: 10),
              Text(
                'Sẵn Sàng Bắt Đầu!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            // Đảm bảo nội dung không bị tràn
            child: RichText(
              // Dùng RichText để style chữ
              textAlign: TextAlign.center, // Căn giữa nội dung
              text: TextSpan(
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.black87,
                  height: 1.4,
                ), // Style mặc định
                children: <TextSpan>[
                  TextSpan(
                    text:
                        'Tuyệt vời! Chúng tôi đã tính toán mục tiêu calo hàng ngày phù hợp cho bạn là\n',
                  ),
                  TextSpan(
                    text:
                        '${calculatedGoal.toStringAsFixed(0)} kcal', // Hiển thị số calo
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18, // Làm nổi bật con số
                      color: Theme.of(context).primaryColorDark,
                    ),
                  ),
                  TextSpan(
                    text: '\n\nHãy cùng xây dựng thói quen ăn uống lành mạnh!',
                  ),
                ],
              ),
            ),
          ),
          actionsAlignment: MainAxisAlignment.center, // Căn giữa nút bấm
          actions: <Widget>[
            ElevatedButton(
              // Dùng ElevatedButton cho nổi bật
              style: ElevatedButton.styleFrom(
                // backgroundColor: Theme.of(context).primaryColor, // Màu nền nút
                // foregroundColor: Colors.white, // Màu chữ nút
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child: const Text('Bắt đầu hành trình'),
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(); // Chỉ cần đóng dialog khi nhấn nút
              },
            ),
          ],
        );
      },
    );
  }
  // === KẾT THÚC HÀM HIỂN THỊ DIALOG ===

  // === HÀM _finishOnboarding ĐÃ ĐƯỢC CẬP NHẬT ===
  Future<void> _finishOnboarding() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    // Kiểm tra mounted trước khi setState
    if (mounted) setState(() => _isLoading = true);

    final height = double.parse(_heightController.text);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: Không tìm thấy ID người dùng.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
      return;
    }

    double? savedGoal; // Biến để lưu mục tiêu sau khi lưu thành công

    try {
      onboardingProvider.setHeight(height);
      // Tính toán và LƯU dữ liệu, lấy về goal đã lưu
      savedGoal = await onboardingProvider.calculateAndSaveData(userId);

      if (savedGoal != null && mounted) {
        // Cập nhật goal trong CalorieProvider local
        await calorieProvider.setCalorieGoal(savedGoal);

        // *** GỌI DIALOG HIỂN THỊ MỤC TIÊU ***
        // Chờ người dùng đóng dialog trước khi điều hướng
        await _showGoalConfirmationDialog(savedGoal);

        // Xóa dữ liệu tạm trong OnboardingProvider
        onboardingProvider.clearData();

        // Điều hướng đến HomeScreen sau khi dialog đóng
        // ignore: use_build_context_synchronously
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => HomeScreen()),
          (Route<dynamic> route) => false,
        );
        // Không cần set _isLoading=false vì màn hình đã bị thay thế
        return; // Thoát sớm sau khi điều hướng thành công
      } else if (mounted) {
        // Xử lý trường hợp calculateAndSaveData trả về null hoặc widget unmounted
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tính toán hoặc lưu mục tiêu.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Error during finishing onboarding: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xảy ra lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Chỉ set isLoading = false nếu còn ở màn hình này (tức là có lỗi xảy ra TRƯỚC khi điều hướng)
      if (mounted && savedGoal == null) {
        // Kiểm tra savedGoal == null để chắc chắn chưa điều hướng
        setState(() => _isLoading = false);
      }
    }
  }
  // === KẾT THÚC HÀM _finishOnboarding CẬP NHẬT ===

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bước 4: Chiều cao')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Chiều cao của bạn là bao nhiêu?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 30),
              TextFormField(
                controller: _heightController,
                keyboardType: TextInputType.numberWithOptions(decimal: false),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Chiều cao',
                  hintText: 'ví dụ: 170',
                  suffixText: 'cm',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.height_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Vui lòng nhập chiều cao';
                  final number = int.tryParse(value);
                  if (number == null || number <= 0)
                    return 'Chiều cao phải là số dương';
                  if (number < 50 || number > 250)
                    return 'Chiều cao không hợp lệ';
                  return null;
                },
              ),
              SizedBox(height: 50),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                    onPressed: _finishOnboarding,
                    child: Text('Hoàn Tất & Tính Toán'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
