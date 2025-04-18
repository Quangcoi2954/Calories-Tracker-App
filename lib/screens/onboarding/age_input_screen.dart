// lib/screens/onboarding/age_input_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';
import 'weight_input_screen.dart'; // Màn hình tiếp theo

class AgeInputScreen extends StatefulWidget {
  @override
  _AgeInputScreenState createState() => _AgeInputScreenState();
}

class _AgeInputScreenState extends State<AgeInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bước 2: Tuổi'),
        // Nút back sẽ tự động xuất hiện do dùng Navigator.push
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Bạn bao nhiêu tuổi?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 30),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Tuổi',
                  hintText: 'ví dụ: 25',
                  suffixText: 'tuổi',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.cake_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Vui lòng nhập tuổi';
                  final number = int.tryParse(value);
                  if (number == null || number <= 0)
                    return 'Tuổi phải là số dương';
                  if (number < 10 || number > 120) return 'Tuổi không hợp lệ';
                  return null;
                },
              ),
              SizedBox(height: 50),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final age = int.parse(_ageController.text);
                    Provider.of<OnboardingProvider>(
                      context,
                      listen: false,
                    ).setAge(age);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WeightInputScreen(),
                      ),
                    );
                  }
                },
                child: Text('Tiếp Tục'),
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
