import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart'; // Sẽ tạo sau
import 'login_screen.dart'; // Màn hình đăng nhập/đăng ký

class Wrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Kiểm tra trạng thái đăng nhập
    if (authProvider.isAuthenticated) {
      print("Wrapper: User authenticated, showing HomeScreen");
      return HomeScreen(); // Nếu đã đăng nhập, vào màn hình chính
    } else {
      print("Wrapper: User not authenticated, showing LoginScreen");
      return LoginScreen(); // Nếu chưa, vào màn hình đăng nhập
    }
  }
}
