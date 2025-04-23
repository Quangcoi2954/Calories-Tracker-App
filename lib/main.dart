// lib/main.dart

import 'package:calories_tracker/screens/onboarding/age_input_screen.dart';
import 'package:flutter/material.dart';

// 1. Import Firebase Core để khởi tạo Firebase
import 'package:firebase_core/firebase_core.dart';

// 2. Import Provider để quản lý state
import 'package:provider/provider.dart';

// *** THÊM IMPORT CHO LOCALIZATION DELEGATES (NẾU DÙNG) ***
import 'package:flutter_localizations/flutter_localizations.dart';

// 3. Import file cấu hình Firebase
import 'firebase_options.dart';

// 4. Import các Providers
import 'providers/auth_provider.dart';
import 'providers/calorie_provider.dart';
import 'providers/onboarding_provider.dart';

// bo dong nay sau khi da ching UI xong
import 'screens/onboarding/weight_input_screen.dart';

// 5. Import màn hình Wrapper
import 'screens/wrapper.dart';

// 6. Import intl date formatting
import 'package:intl/date_symbol_data_local.dart'; // Đảm bảo đã import dòng này

// Hàm main - điểm khởi đầu của ứng dụng
void main() async {
  // Đảm bảo Flutter binding đã sẵn sàng
  WidgetsFlutterBinding.ensureInitialized();

  // --- Khởi tạo các dịch vụ bất đồng bộ ---
  try {
    // Khởi tạo Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // *** KHỞI TẠO ĐỊNH DẠNG NGÀY THÁNG TIẾNG VIỆT ***
    // Gọi hàm này sau khi Firebase init và trước runApp
    await initializeDateFormatting('vi_VN', null);
    // *** KẾT THÚC KHỞI TẠO ĐỊNH DẠNG ***
  } catch (e) {
    // Xử lý lỗi nếu khởi tạo thất bại
  }

  // --- Chạy ứng dụng Flutter ---
  runApp(MyApp());
}

// Widget gốc của ứng dụng
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- Thiết lập Provider ---
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(
          create: (context) => AuthProvider(),
          lazy: false,
        ),
        ChangeNotifierProxyProvider<AuthProvider, CalorieProvider>(
          create: (context) => CalorieProvider(null),
          update: (context, authProvider, previousCalorieProvider) {
            final userId = authProvider.user?.uid;
            return CalorieProvider(userId);
          },
          lazy: false,
        ),
      ],
      // --- MaterialApp với cấu hình Locale ---
      child: MaterialApp(
        title: 'Calorie Tracker',
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          // Tùy chọn: Thêm font tiếng Việt nếu cần
          // fontFamily: 'YourVietnameseFont',
        ),

        // *** THÊM CẤU HÌNH LOCALE ***
        locale: const Locale('vi', 'VN'), // Đặt locale mặc định là tiếng Việt
        localizationsDelegates: const [
          // Các delegate cần thiết cho localization của Flutter
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''), // Hỗ trợ tiếng Anh (tùy chọn)
          Locale('vi', 'VN'), // Hỗ trợ tiếng Việt
        ],

        // *** KẾT THÚC CẤU HÌNH LOCALE ***
        //home: Wrapper(), // Widget Wrapper để điều hướng
        home: WeightInputScreen(), // Widget điều hướng chính
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
