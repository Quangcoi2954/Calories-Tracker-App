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
  bool _isProcessing = false; // Cờ để tránh xử lý nhiều lần cùng lúc
  final FoodApiService _foodApiService = FoodApiService();

  // Hàm được gọi khi quét được barcode
  void _handleBarcode(BarcodeCapture capture) async {
    // Thêm kiểm tra mounted ngay đầu để an toàn hơn
    if (_isProcessing || !mounted) return;

    final String? code = capture.barcodes.first.rawValue;

    if (code != null && code.isNotEmpty) {
      // Kiểm tra code không rỗng
      // Chỉ gọi setState nếu widget còn tồn tại
      if (mounted) setState(() => _isProcessing = true);
      print('Barcode found! $code. Processing...'); // Log khi bắt đầu xử lý

      // Hiện SnackBar thông báo ngắn gọn (kiểm tra mounted)
      if (mounted) {
        // Xóa SnackBar cũ nếu có trước khi hiện cái mới
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đang tra cứu mã: $code...'),
            duration: const Duration(seconds: 4),
          ), // Tăng thời gian một chút
        );
      }

      FoodItem? foundItem; // Khai báo ngoài try-catch
      String? errorMsg; // Biến lưu lỗi

      try {
        // Gọi API để tra cứu sản phẩm
        foundItem = await _foodApiService.lookupFoodByBarcode(code);
        print(
          'API lookup completed. Found item: ${foundItem != null}',
        ); // Log kết quả API
      } catch (e) {
        errorMsg = e.toString(); // Lưu lỗi lại
        print("Error during barcode lookup API call: $e");
      } finally {
        // Luôn đảm bảo tắt loading và cho phép quét lại nếu không tìm thấy hoặc lỗi
        // Chỉ pop màn hình nếu tìm thấy item
        if (mounted && foundItem == null) {
          print(
            'Resetting _isProcessing to false in finally.',
          ); // Log trước khi reset
          setState(() => _isProcessing = false);
        } else if (!mounted) {
          print(
            'Widget unmounted before finally could reset processing state.',
          );
        } else {
          // foundItem != null
          print(
            'Item found, not resetting processing state in finally as screen should pop.',
          );
        }
      }

      // Kiểm tra mounted một lần nữa trước khi xử lý kết quả cuối cùng
      if (!mounted) {
        print('Widget unmounted after finally.');
        return;
      }

      if (foundItem != null) {
        // Tìm thấy sản phẩm -> Đóng màn hình quét và trả về FoodItem
        print('Popping screen with found item: ${foundItem.name}');
        Navigator.of(context).pop(foundItem);
      } else {
        // Không tìm thấy sản phẩm hoặc có lỗi API
        String snackBarMsg =
            errorMsg != null
                ? 'Lỗi khi tra cứu: ${errorMsg.replaceFirst("Exception: ", "")}'
                : 'Không tìm thấy thông tin cho mã vạch này.';
        Color snackBarColor = errorMsg != null ? Colors.red : Colors.orange;

        print('Item not found or error occurred, showing SnackBar.');
        ScaffoldMessenger.of(
          context,
        ).removeCurrentSnackBar(); // Xóa snackbar "Đang tra cứu..."
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(snackBarMsg), backgroundColor: snackBarColor),
        );
        // _isProcessing đã được đặt lại thành false trong finally ở trên
      }
    } else {
      print('Detected barcode value is null or empty.'); // Log nếu mã vạch rỗng
      // Không cần làm gì thêm ở đây, chờ lần quét hợp lệ tiếp theo
    }
  }

  @override
  void dispose() {
    // Quan trọng: phải dispose controller khi không cần nữa
    cameraController.dispose();
    print("BarcodeScannerScreen disposed, cameraController disposed.");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lấy màu icon mặc định từ AppBar theme để đảm bảo tương phản
    final appBarIconColor =
        Theme.of(context).appBarTheme.iconTheme?.color ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black);

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: appBarIconColor,
        ), // Đảm bảo nút back cũng có màu đúng
        title: const Text("Quét Mã Vạch Thực Phẩm"),
        titleTextStyle: TextStyle(
          color: appBarIconColor,
          fontSize: 20,
        ), // Đảm bảo title có màu đúng
        backgroundColor:
            Theme.of(
              context,
            ).appBarTheme.backgroundColor, // Lấy màu nền từ theme
        actions: [
          // Nút bật/tắt đèn flash
          IconButton(
            color: appBarIconColor, // Sử dụng màu icon từ theme
            icon: const Icon(Icons.flashlight_on_outlined),
            tooltip: 'Bật/Tắt đèn flash',
            onPressed: () => cameraController.toggleTorch(),
          ),
          // Nút chuyển camera trước/sau
          IconButton(
            color: appBarIconColor, // Sử dụng màu icon từ theme
            icon: const Icon(Icons.cameraswitch_outlined),
            tooltip: 'Chuyển camera trước/sau',
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _handleBarcode,
            fit: BoxFit.cover,
            // *** errorBuilder chi tiết hơn ***
            errorBuilder: (context, error, child) {
              // In ra toàn bộ đối tượng lỗi để xem chi tiết
              print("MobileScanner encountered an error object: $error");
              String errorMessage =
                  'Đã xảy ra lỗi không xác định với camera.'; // Mặc định
              if (error is MobileScannerException) {
                errorMessage = error.toString() ?? error.errorCode.toString();
                if (error.errorDetails != null) {
                  errorMessage += '\nChi tiết: ${error.errorDetails}';
                  // Check specifically for NotReadableError common cause
                  if (error.errorDetails is String &&
                      (error.errorDetails as String).contains(
                        'NotReadableError',
                      )) {
                    errorMessage +=
                        '\n\nCamera có thể đang được sử dụng bởi ứng dụng khác. Hãy thử đóng các ứng dụng đó và khởi động lại.';
                  }
                }
              } else {
                errorMessage =
                    error.toString(); // Lỗi không phải MobileScannerException
              }

              return Center(
                child: Container(
                  padding: EdgeInsets.all(20),
                  margin: EdgeInsets.all(20), // Thêm margin
                  decoration: BoxDecoration(
                    // Thêm nền và bo góc
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Lỗi Camera: \n$errorMessage',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
          // Overlay khung quét
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
          // Hiển thị loading overlay
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
