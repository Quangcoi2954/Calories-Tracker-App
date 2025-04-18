// lib/screens/barcode_scanner_screen.dart

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // Import thư viện
// import 'package:provider/provider.dart'; // Không dùng Provider trực tiếp
import '../services/food_api_service.dart';
import '../models/food_item.dart';
// import 'add_food_screen.dart'; // Không cần import nếu chỉ pop

class BarcodeScannerScreen extends StatefulWidget {
  @override
  _BarcodeScannerScreenState createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  // Khởi tạo controller
  final MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;
  final FoodApiService _foodApiService = FoodApiService();

  void _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing || !mounted) return;
    final String? code = capture.barcodes.first.rawValue;

    if (code != null && code.isNotEmpty) {
      setState(() => _isProcessing = true);
      print('Barcode found! $code');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đang tra cứu mã: $code...'),
          duration: const Duration(seconds: 3),
        ),
      );

      FoodItem? foundItem;
      try {
        foundItem = await _foodApiService.lookupFoodByBarcode(code);
      } catch (e) {
        print("Error during barcode lookup API call: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi tra cứu mã vạch: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted && foundItem == null) {
          setState(
            () => _isProcessing = false,
          ); // Cho phép quét lại nếu lỗi/không tìm thấy
        }
      }

      if (!mounted) return;

      if (foundItem != null) {
        Navigator.of(context).pop(foundItem); // Trả về kết quả
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không tìm thấy thông tin cho mã vạch này.'),
            backgroundColor: Colors.orange,
          ),
        );
        // Đã setState _isProcessing = false trong finally
      }
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    print("BarcodeScannerScreen disposed, cameraController disposed.");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quét Mã Vạch Thực Phẩm"),
        actions: [
          // === NÚT ĐÈN FLASH ĐÃ CẬP NHẬT ===
          // Xóa ValueListenableBuilder, dùng icon tĩnh
          IconButton(
            color: Colors.white, // Đặt màu để dễ thấy
            // Sử dụng icon biểu thị hành động bật/tắt
            icon: const Icon(
              Icons.flashlight_on_outlined,
            ), // Hoặc Icons.highlight
            tooltip: 'Bật/Tắt đèn flash',
            onPressed:
                () =>
                    cameraController.toggleTorch(), // Hành động vẫn giữ nguyên
          ),
          // === NÚT CHUYỂN CAMERA ĐÃ CẬP NHẬT ===
          // Xóa ValueListenableBuilder, dùng icon tĩnh
          IconButton(
            color: Colors.white, // Đặt màu để dễ thấy
            // Sử dụng icon biểu thị hành động chuyển camera
            icon: const Icon(
              Icons.cameraswitch_outlined,
            ), // Hoặc Icons.switch_camera
            tooltip: 'Chuyển camera trước/sau',
            onPressed:
                () =>
                    cameraController.switchCamera(), // Hành động vẫn giữ nguyên
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _handleBarcode,
            fit: BoxFit.cover,
          ),
          // Overlay khung quét (giữ nguyên)
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.height * 0.25,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // Hiển thị loading overlay khi đang xử lý API (giữ nguyên)
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.6),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 10),
                      Text(
                        'Đang xử lý...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
