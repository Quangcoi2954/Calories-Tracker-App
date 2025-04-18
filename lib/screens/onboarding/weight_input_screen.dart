// lib/screens/onboarding/weight_input_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';
import 'height_input_screen.dart'; // Màn hình tiếp theo

class WeightInputScreen extends StatefulWidget {
  @override
  _WeightInputScreenState createState() => _WeightInputScreenState();
}

class _WeightInputScreenState extends State<WeightInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bước 3: Cân nặng')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Cân nặng của bạn là bao nhiêu?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 30),
              TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Cân nặng',
                  hintText: 'ví dụ: 65.5',
                  suffixText: 'kg',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
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
                    return 'Cân nặng không hợp lệ';
                  return null;
                },
              ),
              SizedBox(height: 50),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final weight = double.parse(_weightController.text);
                    Provider.of<OnboardingProvider>(
                      context,
                      listen: false,
                    ).setWeight(weight);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HeightInputScreen(),
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
