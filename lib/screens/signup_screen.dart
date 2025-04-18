// lib/screens/signup_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart'; // Import AuthProvider
import 'login_screen.dart'; // Import màn hình đăng nhập để điều hướng
import 'onboarding/gender_selection_screen.dart'; // *** THÊM IMPORT CHO MÀN HÌNH ONBOARDING ĐẦU TIÊN ***

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController(); // Thêm controller cho xác nhận mật khẩu

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final _formKey = GlobalKey<FormState>();

  // Hàm xử lý đăng ký
  Future<void> _signUp() async {
    // Validate form (nếu dùng)
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    // Không cần lấy confirmPassword ở đây vì đã validate trong TextFormField

    FocusScope.of(context).unfocus();

    // Chỉ gọi setState nếu widget còn tồn tại
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      String? error = await authProvider.signUp(email, password);

      // === PHẦN ĐƯỢC CẬP NHẬT ===
      // Nếu đăng ký thành công (error == null) và widget còn tồn tại
      if (error == null && mounted) {
        // Điều hướng đến màn hình onboarding đầu tiên (GenderSelectionScreen)
        // Sử dụng pushReplacement để người dùng không thể quay lại màn hình đăng ký
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => GenderSelectionScreen()),
        );
        // Không cần tắt loading ở đây vì màn hình đã bị thay thế
        return; // Thoát khỏi hàm _signUp sớm
      }
      // === KẾT THÚC CẬP NHẬT ===

      // Xử lý nếu đăng ký thất bại (error != null)
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng ký thất bại: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Xử lý các lỗi khác nếu có
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xảy ra lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Chỉ tắt loading nếu widget còn tồn tại (trường hợp đăng ký thất bại)
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose(); // Nhớ dispose controller mới
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đăng Ký'),
        centerTitle: true,
        // leading: IconButton( // Bạn có thể giữ hoặc bỏ nút back tùy ý
        //    icon: Icon(Icons.arrow_back),
        //    onPressed: () => Navigator.of(context).pop(),
        // ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Tạo tài khoản mới',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                SizedBox(height: 30),

                // --- Email TextField ---
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    if (!value.contains('@')) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // --- Password TextField ---
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu';
                    }
                    if (value.length < 6) {
                      return 'Mật khẩu phải có ít nhất 6 ký tự';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // --- Confirm Password TextField ---
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Xác nhận mật khẩu',
                    prefixIcon: Icon(Icons.lock_outline), // Icon khác một chút
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng xác nhận mật khẩu';
                    }
                    // Kiểm tra xem có khớp với mật khẩu đã nhập ở trên không
                    if (value != _passwordController.text) {
                      return 'Mật khẩu không khớp';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 30),

                // --- Nút Đăng Ký ---
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                      onPressed: _signUp,
                      child: Text('Đăng Ký'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                SizedBox(height: 20),

                // --- Chuyển sang màn hình Đăng Nhập ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Đã có tài khoản?'),
                    TextButton(
                      onPressed: () {
                        // Điều hướng thay thế màn hình hiện tại bằng màn hình đăng nhập
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Đăng nhập ngay',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
