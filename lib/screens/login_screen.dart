// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart'; // Import AuthProvider
import 'signup_screen.dart'; // Import màn hình đăng ký để điều hướng

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controller để lấy dữ liệu từ TextFields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // State để quản lý trạng thái loading
  bool _isLoading = false;

  // Biến để ẩn/hiện mật khẩu
  bool _isPasswordVisible = false;

  // Key cho Form để validation (tùy chọn)
  final _formKey = GlobalKey<FormState>();

  // Hàm xử lý đăng nhập
  Future<void> _signIn() async {
    // 1. Validate form (nếu sử dụng Form)
    // if (!_formKey.currentState!.validate()) {
    //   return; // Không làm gì nếu form không hợp lệ
    // }

    // Lấy giá trị từ controllers
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Kiểm tra đơn giản nếu không dùng Form validation
    if (email.isEmpty || password.isEmpty) {
      if (mounted) {
        // Kiểm tra widget còn tồn tại không
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vui lòng nhập đầy đủ email và mật khẩu.')),
        );
      }
      return;
    }

    // Ẩn bàn phím
    FocusScope.of(context).unfocus();

    // Bắt đầu loading
    setState(() {
      _isLoading = true;
    });

    try {
      // Gọi hàm signIn từ AuthProvider
      // `listen: false` vì chúng ta chỉ gọi hàm, không cần rebuild khi state thay đổi ở đây
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      String? error = await authProvider.signIn(email, password);

      // Nếu đăng nhập thành công (error == null), Wrapper sẽ tự động
      // điều hướng đến HomeScreen do lắng nghe authStateChanges.
      // Nếu có lỗi, hiển thị SnackBar
      if (error != null && mounted) {
        // Kiểm tra mounted trước khi dùng context trong hàm async
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng nhập thất bại: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Xử lý các lỗi không mong muốn khác (hiếm khi xảy ra với try-catch trong provider)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xảy ra lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Dừng loading dù thành công hay thất bại (nếu widget còn tồn tại)
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Đừng quên dispose controllers khi widget bị hủy
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Đăng Nhập'), centerTitle: true),
      body: Center(
        // Đưa nội dung vào giữa màn hình
        child: SingleChildScrollView(
          // Cho phép cuộn nếu nội dung quá dài
          padding: const EdgeInsets.all(20.0),
          child: Form(
            // Bọc trong Form nếu bạn muốn dùng validation tích hợp
            key: _formKey,
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Căn giữa theo chiều dọc
              crossAxisAlignment:
                  CrossAxisAlignment
                      .stretch, // Kéo dài các children theo chiều ngang
              children: <Widget>[
                // Logo hoặc tiêu đề ứng dụng (Tùy chọn)
                Text(
                  'Calorie Tracker',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                SizedBox(height: 40),

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
                    // Ví dụ validation
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
                  obscureText: !_isPasswordVisible, // Ẩn/hiện mật khẩu
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    // Icon để bật/tắt hiển thị mật khẩu
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
                SizedBox(height: 30),

                // --- Nút Đăng Nhập ---
                _isLoading
                    ? Center(
                      child: CircularProgressIndicator(),
                    ) // Hiển thị loading
                    : ElevatedButton(
                      onPressed: _signIn, // Gọi hàm xử lý đăng nhập
                      child: Text('Đăng Nhập'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                SizedBox(height: 20),

                // --- Chuyển sang màn hình Đăng Ký ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Chưa có tài khoản?'),
                    TextButton(
                      onPressed: () {
                        // Điều hướng thay thế màn hình hiện tại bằng màn hình đăng ký
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignUpScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Đăng ký ngay',
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
