import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_item.dart'; // Sẽ tạo sau

class FoodApiService {
  // Base URL của Open Food Facts API (search)
  // Lưu ý: API này có thể thay đổi, hãy kiểm tra tài liệu của họ
  static const String _baseUrl =
      'https://world.openfoodfacts.org/cgi/search.pl';

  Future<List<FoodItem>> searchFood(String query) async {
    // Tham số cho API search
    final Map<String, String> queryParams = {
      'search_terms': query, // Từ khóa tìm kiếm
      'search_simple': '1', // Chế độ tìm kiếm đơn giản
      'action': 'process', // Hành động cần thực hiện
      'json': '1', // Yêu cầu trả về dạng JSON
      'page_size': '20', // Số lượng kết quả mỗi trang (ví dụ)
      // Thêm các trường cần lấy để giảm dung lượng response
      'fields':
          'product_name,nutriments,code,serving_size,serving_quantity,brands',
    };

    // Tạo URI với query parameters
    final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);

    print('API Request URL: $uri'); // In URL để debug

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Kiểm tra cấu trúc JSON trả về (có thể thay đổi)
        if (data['products'] != null && data['products'] is List) {
          final List<dynamic> products = data['products'];
          List<FoodItem> foodItems = [];

          for (var product in products) {
            // Lấy thông tin calo (energy-kcal) từ nutriments
            // Open Food Facts thường có calo trên 100g/100ml
            final nutriments = product['nutriments'];
            double caloriesPer100g = 0;
            double? proteinPer100g; // Khai báo nullable
            double? carbsPer100g; // Khai báo nullable
            double? fatPer100g; // Khai báo nullable

            if (nutriments != null) {
              // Lấy Calo
              if (nutriments['energy-kcal_100g'] != null) {
                try {
                  caloriesPer100g = double.parse(
                    nutriments['energy-kcal_100g'].toString(),
                  );
                } catch (e) {
                  caloriesPer100g = 0;
                }
              }
              // Lấy Protein (ví dụ key 'proteins_100g') - Key có thể khác, cần kiểm tra response API
              if (nutriments['proteins_100g'] != null) {
                try {
                  proteinPer100g = double.parse(
                    nutriments['proteins_100g'].toString(),
                  );
                } catch (e) {
                  proteinPer100g = null;
                }
              }
              // Lấy Carb (ví dụ key 'carbohydrates_100g')
              if (nutriments['carbohydrates_100g'] != null) {
                try {
                  carbsPer100g = double.parse(
                    nutriments['carbohydrates_100g'].toString(),
                  );
                } catch (e) {
                  carbsPer100g = null;
                }
              }
              // Lấy Fat (ví dụ key 'fat_100g')
              if (nutriments['fat_100g'] != null) {
                try {
                  fatPer100g = double.parse(nutriments['fat_100g'].toString());
                } catch (e) {
                  fatPer100g = null;
                }
              }
            }

            // Lấy tên sản phẩm
            String productName = product['product_name'] ?? 'Không rõ tên';
            // Lấy barcode/code
            String id =
                product['code'] ??
                DateTime.now().millisecondsSinceEpoch
                    .toString(); // Id tạm nếu ko có code

            // Tạo đối tượng FoodItem (chỉ khi có calo > 0)
            if (caloriesPer100g > 0 && productName != 'Không rõ tên') {
              foodItems.add(
                FoodItem(
                  id: id,
                  name: productName,
                  caloriesPer100g: caloriesPer100g,
                  proteinPer100g: proteinPer100g, // Truyền giá trị macro
                  carbsPer100g: carbsPer100g, // Truyền giá trị macro
                  fatPer100g: fatPer100g, // Truyền giá trị macro
                  brand: product['brands'] ?? '',
                  servingSize: product['serving_size'] ?? '100 g',
                ),
              );
            }
          }
          print("API Search Found: ${foodItems.length} items");
          return foodItems;
        } else {
          print("API Search Error: 'products' field not found or not a list");
          return []; // Không tìm thấy hoặc cấu trúc JSON sai
        }
      } else {
        // Lỗi HTTP
        print('API Search Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      // Lỗi mạng hoặc parse JSON
      print('API Search Exception: $e');
      return [];
    }
  }

  // Hàm mới để tra cứu bằng barcode
  Future<FoodItem?> lookupFoodByBarcode(String barcode) async {
    // URL của Open Food Facts API cho sản phẩm cụ thể
    final uri = Uri.parse(
      'https://world.openfoodfacts.org/api/v2/product/$barcode.json?fields=product_name,nutriments,code,serving_size,serving_quantity,brands',
    );
    print('API Barcode Lookup URL: $uri');

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Kiểm tra xem sản phẩm có tồn tại không ('status: 1') và có 'product' không
        if (data['status'] == 1 && data['product'] != null) {
          final product = data['product'];
          // Parse dữ liệu tương tự như trong hàm searchFood
          final nutriments = product['nutriments'];
          double caloriesPer100g = 0;
          double? proteinPer100g, carbsPer100g, fatPer100g;
          if (nutriments != null) {
            // ... (code parse nutriments giống hệt searchFood) ...
            if (nutriments['energy-kcal_100g'] != null) {
              /*...*/
            }
            if (nutriments['proteins_100g'] != null) {
              /*...*/
            }
            if (nutriments['carbohydrates_100g'] != null) {
              /*...*/
            }
            if (nutriments['fat_100g'] != null) {
              /*...*/
            }
          }
          String productName = product['product_name'] ?? 'Không rõ tên';
          String id =
              product['code'] ?? barcode; // Dùng barcode làm ID dự phòng

          if (caloriesPer100g > 0 && productName != 'Không rõ tên') {
            return FoodItem(
              id: id,
              name: productName,
              caloriesPer100g: caloriesPer100g,
              proteinPer100g: proteinPer100g,
              carbsPer100g: carbsPer100g,
              fatPer100g: fatPer100g,
              brand: product['brands'] ?? '',
              servingSize: product['serving_size'] ?? '100 g',
            );
          }
        } else {
          print("API Barcode Lookup: Product not found or status is not 1.");
        }
      } else {
        print('API Barcode Lookup Error: ${response.statusCode}');
      }
    } catch (e) {
      print('API Barcode Lookup Exception: $e');
    }
    return null; // Trả về null nếu không tìm thấy hoặc có lỗi
  }
}
