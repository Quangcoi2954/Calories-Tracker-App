import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Để sử dụng inputFormatters (tùy chọn)
import 'package:provider/provider.dart';

import '../providers/calorie_provider.dart'; // Import CalorieProvider để gọi hàm addWeightEntry

class AddWeightScreen extends StatefulWidget {
  @override
  _AddWeightScreenState createState() => _AddWeightScreenState();
}

class _AddWeightScreenState extends State<AddWeightScreen> {
  // Controller cho ô nhập cân nặng
  final TextEditingController _weightController = TextEditingController();
  // Key cho Form để validation
  final _formKey = GlobalKey<FormState>();
  // State để quản lý trạng thái loading khi lưu
  bool _isLoading = false;

  @override
  void dispose() {
    _weightController.dispose(); // Nhớ dispose controller
    super.dispose();
  }

  // Hàm xử lý việc lưu cân nặng mới
  Future<void> _saveWeight() async {
    // Validate form trước
    if (!_formKey.currentState!.validate()) {
      return; // Không làm gì nếu form không hợp lệ
    }

    // Ẩn bàn phím
    FocusScope.of(context).unfocus();

    // Bắt đầu trạng thái đang lưu
    if (mounted) {
      setState(() => _isLoading = true);
    }

    // Lấy giá trị từ controller và parse thành double
    final String weightString = _weightController.text.trim();
    final double? newWeight = double.tryParse(weightString);

    if (newWeight == null) {
      // Trường hợp không thể parse (dù đã có validator)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Giá trị cân nặng không hợp lệ.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false); // Dừng lưu
      }
      return;
    }

    // Gọi hàm addWeightEntry từ CalorieProvider
    try {
      // `listen: false` vì chỉ gọi hàm
      await Provider.of<CalorieProvider>(
        context,
        listen: false,
      ).addWeightEntry(newWeight);

      // Hiển thị thông báo thành công và đóng màn hình (nếu widget còn tồn tại)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã lưu cân nặng thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Đóng màn hình sau khi lưu
      }
    } catch (e) {
      // Xử lý lỗi nếu có lỗi từ provider (ví dụ: lỗi lưu vào Firestore)
      if (mounted) {
        print("Error saving weight entry: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lưu cân nặng thất bại: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Dừng trạng thái đang lưu (nếu widget còn tồn tại)
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Thêm Cân nặng Hiện tại')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          // Bọc trong Form để sử dụng validation
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Kéo dài nút Lưu
            children: <Widget>[
              SizedBox(height: 20), // Khoảng cách từ AppBar
              Text(
                'Nhập cân nặng mới nhất của bạn:',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),

              // Ô nhập cân nặng
              TextFormField(
                controller: _weightController,
                // Cho phép nhập số thập phân
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                // Tùy chọn: Chỉ cho phép nhập số và dấu chấm thập phân
                // inputFormatters: <TextInputFormatter>[
                //   FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')), // Chỉ cho 1 số sau dấu phẩy
                // ],
                decoration: InputDecoration(
                  labelText: 'Cân nặng',
                  hintText: 'ví dụ: 65.5',
                  suffixText: 'kg',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon: Icon(Icons.monitor_weight_outlined),
                ),
                validator: (value) {
                  // Validation
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập cân nặng';
                  }
                  final number = double.tryParse(value);
                  if (number == null || number <= 0) {
                    return 'Cân nặng phải là số dương';
                  }
                  if (number < 20 || number > 300) {
                    // Giới hạn hợp lý
                    return 'Cân nặng không hợp lệ (20kg - 300kg)';
                  }
                  return null; // Hợp lệ
                },
              ),
              SizedBox(height: 30),

              // Nút Lưu
              _isLoading
                  ? Center(
                    child: CircularProgressIndicator(),
                  ) // Hiển thị loading khi đang lưu
                  : ElevatedButton.icon(
                    icon: Icon(Icons.save),
                    label: Text('Lưu Cân nặng'),
                    onPressed: _saveWeight,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
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
