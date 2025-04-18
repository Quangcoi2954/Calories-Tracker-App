// lib/screens/onboarding/gender_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';
import 'age_input_screen.dart'; // Màn hình tiếp theo

enum Gender { male, female }

class GenderSelectionScreen extends StatefulWidget {
  @override
  _GenderSelectionScreenState createState() => _GenderSelectionScreenState();
}

class _GenderSelectionScreenState extends State<GenderSelectionScreen> {
  Gender? _selectedGender;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bước 1: Giới tính'),
        automaticallyImplyLeading: false, // Không cần nút back ở bước đầu
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Bạn là nam hay nữ?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            ListTile(
              title: const Text('Nam'),
              leading: Radio<Gender>(
                value: Gender.male,
                groupValue: _selectedGender,
                onChanged:
                    (Gender? value) => setState(() => _selectedGender = value),
              ),
              onTap: () => setState(() => _selectedGender = Gender.male),
            ),
            ListTile(
              title: const Text('Nữ'),
              leading: Radio<Gender>(
                value: Gender.female,
                groupValue: _selectedGender,
                onChanged:
                    (Gender? value) => setState(() => _selectedGender = value),
              ),
              onTap: () => setState(() => _selectedGender = Gender.female),
            ),
            SizedBox(height: 50),
            ElevatedButton(
              onPressed:
                  _selectedGender == null
                      ? null // Vô hiệu hóa nút nếu chưa chọn
                      : () {
                        final provider = Provider.of<OnboardingProvider>(
                          context,
                          listen: false,
                        );
                        provider.setGender(
                          _selectedGender == Gender.male ? 'male' : 'female',
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AgeInputScreen(),
                          ),
                        );
                      },
              child: Text('Tiếp Tục'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
