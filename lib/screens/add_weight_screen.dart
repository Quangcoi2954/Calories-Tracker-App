// lib/screens/add_weight_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Thêm import để format ngày

import '../providers/calorie_provider.dart';

class AddWeightScreen extends StatefulWidget {
  @override
  _AddWeightScreenState createState() => _AddWeightScreenState();
}

class _AddWeightScreenState extends State<AddWeightScreen> {
  final TextEditingController _weightController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  // State để lưu ngày được chọn
  DateTime _selectedDate = DateTime.now(); // Mặc định là ngày hiện tại

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  // Hàm để chọn ngày
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate, // Ngày đang chọn hiện tại
      firstDate: DateTime(2020), // Ngày xa nhất có thể chọn
      lastDate:
          DateTime.now(), // Chỉ cho phép chọn từ ngày hiện tại trở về trước
      locale: const Locale("vi", "VN"),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked; // Cập nhật ngày đã chọn
      });
    }
  }

  // Hàm lưu cân nặng
  Future<void> _saveWeight() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    if (mounted) setState(() => _isLoading = true);

    final String weightString = _weightController.text.trim();
    final double? newWeight = double.tryParse(weightString);

    if (newWeight == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Giá trị cân nặng không hợp lệ.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      // Truyền ngày đã chọn vào hàm addWeightEntry
      await Provider.of<CalorieProvider>(
        context,
        listen: false,
      ).addWeightEntry(newWeight, _selectedDate); // Truyền _selectedDate

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã lưu cân nặng thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        print("Error saving weight entry from screen: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lưu cân nặng thất bại: ${e.toString().replaceFirst("Exception: ", "")}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Thêm Cân nặng')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(height: 20),
              // Phần chọn ngày
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Ngày ghi nhận:', style: TextStyle(fontSize: 16)),
                  TextButton.icon(
                    icon: Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      DateFormat(
                        'dd/MM/yyyy',
                        'vi_VN',
                      ).format(_selectedDate), // Hiển thị ngày đã chọn
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: () => _selectDate(context), // Gọi hàm chọn ngày
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text(
                'Nhập cân nặng của bạn vào ngày trên:',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 15),
              // Ô nhập cân nặng
              TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                  if (value == null || value.isEmpty)
                    return 'Vui lòng nhập cân nặng';
                  final number = double.tryParse(value);
                  if (number == null || number <= 0)
                    return 'Cân nặng phải là số dương';
                  if (number < 20 || number > 300)
                    return 'Cân nặng không hợp lệ (20kg - 300kg)';
                  return null;
                },
              ),
              SizedBox(height: 30),
              // Nút Lưu
              _isLoading
                  ? Center(child: CircularProgressIndicator())
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
