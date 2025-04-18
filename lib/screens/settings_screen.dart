import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Để sử dụng inputFormatters
import 'package:provider/provider.dart';

import '../providers/calorie_provider.dart'; // Import CalorieProvider

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Controller cho ô nhập mục tiêu mới
  final TextEditingController _goalController = TextEditingController();
  // Key cho Form để validation
  final _formKey = GlobalKey<FormState>();
  // State để quản lý trạng thái loading khi lưu
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Lấy giá trị mục tiêu hiện tại từ Provider khi màn hình được khởi tạo
    // và gán vào TextField. `listen: false` vì chúng ta chỉ cần đọc giá trị một lần ở đây.
    final initialGoal =
        Provider.of<CalorieProvider>(context, listen: false).calorieGoal;
    // Gán giá trị ban đầu cho controller (hiển thị dạng số nguyên)
    _goalController.text = initialGoal.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _goalController.dispose(); // Nhớ dispose controller
    super.dispose();
  }

  // Hàm xử lý việc lưu mục tiêu mới
  Future<void> _saveGoal() async {
    // Validate form trước
    if (!_formKey.currentState!.validate()) {
      return; // Không làm gì nếu form không hợp lệ
    }

    // Ẩn bàn phím
    FocusScope.of(context).unfocus();

    // Bắt đầu trạng thái đang lưu
    setState(() {
      _isSaving = true;
    });

    // Lấy giá trị từ controller và parse thành double
    final String goalString = _goalController.text.trim();
    final double? newGoal = double.tryParse(goalString);

    if (newGoal == null) {
      // Trường hợp không thể parse (dù đã có validator, phòng ngừa)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Giá trị mục tiêu không hợp lệ.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSaving = false;
        }); // Dừng lưu
      }
      return;
    }

    // Gọi hàm setCalorieGoal từ CalorieProvider
    try {
      // `listen: false` vì chỉ gọi hàm, không cần rebuild ở đây
      await Provider.of<CalorieProvider>(
        context,
        listen: false,
      ).setCalorieGoal(newGoal);

      // Hiển thị thông báo thành công (nếu widget còn tồn tại)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật mục tiêu calo thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        // Có thể tự động đóng màn hình cài đặt sau khi lưu thành công (tùy chọn)
        // Navigator.of(context).pop();
      }
    } catch (e) {
      // Xử lý lỗi nếu có lỗi từ provider (ví dụ: lỗi lưu vào Firestore)
      if (mounted) {
        print("Error saving calorie goal: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lưu mục tiêu thất bại: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Dừng trạng thái đang lưu (nếu widget còn tồn tại)
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sử dụng Consumer để lắng nghe thay đổi của calorieGoal và rebuild phần hiển thị
    return Scaffold(
      appBar: AppBar(title: Text('Cài Đặt')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          // Bọc trong Form để sử dụng validation
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Căn lề trái
            children: <Widget>[
              Text(
                'Mục tiêu Calo Hàng Ngày',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 15),

              // Hiển thị mục tiêu hiện tại (lắng nghe Provider)
              Consumer<CalorieProvider>(
                builder: (context, calorieProvider, child) {
                  return Text(
                    'Mục tiêu hiện tại: ${calorieProvider.calorieGoal.toStringAsFixed(0)} kcal',
                    style: TextStyle(fontSize: 16),
                  );
                },
              ),
              SizedBox(height: 25),

              // Ô nhập mục tiêu mới
              TextFormField(
                controller: _goalController,
                keyboardType: TextInputType.number, // Bàn phím chỉ hiển thị số
                // Chỉ cho phép nhập số
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  labelText: 'Nhập mục tiêu mới (kcal)',
                  hintText: 'ví dụ: 1800',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  suffixText: 'kcal',
                ),
                validator: (value) {
                  // Validation
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mục tiêu';
                  }
                  final number = int.tryParse(value);
                  if (number == null || number <= 0) {
                    return 'Mục tiêu phải là một số nguyên dương';
                  }
                  if (number < 500 || number > 10000) {
                    // Giới hạn hợp lý (ví dụ)
                    return 'Mục tiêu nên trong khoảng 500 - 10000 kcal';
                  }
                  return null; // Hợp lệ
                },
              ),
              SizedBox(height: 30),

              // Nút Lưu
              Center(
                // Đặt nút vào giữa
                child:
                    _isSaving
                        ? CircularProgressIndicator() // Hiển thị loading khi đang lưu
                        : ElevatedButton(
                          onPressed: _saveGoal,
                          child: Text('Lưu Thay Đổi'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
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
