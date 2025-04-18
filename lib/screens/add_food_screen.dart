// lib/screens/add_food_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import các thành phần cần thiết
import '../services/food_api_service.dart';
import '../models/food_item.dart';
import '../models/daily_log_entry.dart';
import '../providers/calorie_provider.dart';
import 'barcode_scanner_screen.dart'; // *** THÊM IMPORT MÀN HÌNH QUÉT BARCODE ***

// === WIDGET DIALOG STATEFUL (ĐÃ THÊM Ở BƯỚC SỬA LỖI TRƯỚC) ===
class _QuantityInputDialog extends StatefulWidget {
  final FoodItem foodItem;
  const _QuantityInputDialog({required this.foodItem});
  @override
  __QuantityInputDialogState createState() => __QuantityInputDialogState();
}

class __QuantityInputDialogState extends State<_QuantityInputDialog> {
  final _quantityController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Nhập số lượng cho "${widget.foodItem.name}"'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _quantityController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Số lượng (gam)',
            hintText: 'ví dụ: 150',
            suffixText: 'g',
          ),
          autofocus: true,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Vui lòng nhập số lượng';
            final number = double.tryParse(value);
            if (number == null || number <= 0)
              return 'Số lượng phải là số dương';
            return null;
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Hủy'),
          onPressed: () => Navigator.of(context).pop<double?>(null),
        ),
        ElevatedButton(
          child: Text('Thêm'),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final quantity = double.parse(_quantityController.text);
              Navigator.of(
                context,
              ).pop<double?>(quantity); // Trả về quantity khi đóng
            }
          },
        ),
      ],
    );
  }
}
// === KẾT THÚC WIDGET DIALOG STATEFUL ===

class AddFoodScreen extends StatefulWidget {
  @override
  _AddFoodScreenState createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FoodApiService _foodApiService = FoodApiService();
  List<FoodItem> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _searchFood() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _errorMessage = 'Vui lòng nhập từ khóa tìm kiếm.';
        });
      }
      return;
    }
    FocusScope.of(context).unfocus();
    if (mounted) {
      setState(() {
        _isLoading = true;
        _searchResults = [];
        _errorMessage = null;
      });
    }
    try {
      final results = await _foodApiService.searchFood(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          if (results.isEmpty)
            _errorMessage = 'Không tìm thấy kết quả nào cho "$query".';
        });
      }
    } catch (e) {
      print("Error during food search: $e");
      if (mounted)
        setState(() => _errorMessage = 'Đã xảy ra lỗi khi tìm kiếm.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Hàm hiển thị dialog (ĐÃ CẬP NHẬT SỬ DỤNG STATEFUL WIDGET)
  Future<void> _showQuantityDialog(FoodItem foodItem) async {
    final double? enteredQuantity = await showDialog<double?>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return _QuantityInputDialog(foodItem: foodItem);
      },
    );
    if (enteredQuantity != null && mounted) {
      _addFoodEntry(foodItem, enteredQuantity);
    }
  }

  // Hàm thêm thực phẩm (ĐÃ CẬP NHẬT ĐỂ TÍNH MACROS)
  void _addFoodEntry(FoodItem foodItem, double quantity) {
    final double caloriesPerGram = foodItem.caloriesPer100g / 100.0;
    final double totalCalories = quantity * caloriesPerGram;
    double? totalProtein, totalCarbs, totalFat;
    if (foodItem.proteinPer100g != null)
      totalProtein = quantity * (foodItem.proteinPer100g! / 100.0);
    if (foodItem.carbsPer100g != null)
      totalCarbs = quantity * (foodItem.carbsPer100g! / 100.0);
    if (foodItem.fatPer100g != null)
      totalFat = quantity * (foodItem.fatPer100g! / 100.0);
    final String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final newEntry = DailyLogEntry(
      foodId: foodItem.id,
      foodName: foodItem.name,
      quantity: quantity,
      unit: 'g',
      calories: totalCalories,
      protein: totalProtein,
      carbs: totalCarbs,
      fat: totalFat,
      timestamp: Timestamp.now(),
      date: currentDate,
    );
    try {
      Provider.of<CalorieProvider>(
        context,
        listen: false,
      ).addLogEntry(newEntry);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thêm "${foodItem.name}"'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      print("Error adding log entry via provider: $e");
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi thêm thực phẩm: $e'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Thêm Thực Phẩm')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Tìm kiếm thực phẩm...',
                      hintText: 'ví dụ: chuối, sữa tươi...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      suffixIcon:
                          _searchController.text.isNotEmpty
                              ? IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  if (mounted)
                                    setState(() {
                                      _searchResults = [];
                                      _errorMessage = null;
                                    });
                                },
                              )
                              : null,
                    ),
                    onChanged: (_) {
                      if (mounted) setState(() {});
                    },
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _searchFood(),
                  ),
                ),
                SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.search, size: 30),
                  onPressed: _searchFood,
                  tooltip: 'Tìm kiếm',
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
                SizedBox(width: 5), // Khoảng cách
                // *** NÚT MỞ MÀN HÌNH QUÉT BARCODE ***
                IconButton(
                  icon: Icon(Icons.qr_code_scanner, size: 30),
                  tooltip: 'Quét mã vạch',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blueGrey, // Màu khác cho nút quét
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    // Hàm onPressed giờ là async
                    // Điều hướng đến màn hình quét và chờ kết quả (kiểu FoodItem?)
                    final result = await Navigator.push<FoodItem?>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BarcodeScannerScreen(),
                      ),
                    );

                    // Xử lý kết quả trả về từ màn hình quét
                    if (result != null && mounted) {
                      print("Received FoodItem from scanner: ${result.name}");
                      // Nếu quét thành công và tìm thấy FoodItem, hiển thị dialog nhập số lượng
                      _showQuantityDialog(result);
                    }
                    // Nếu result là null (người dùng back hoặc không tìm thấy), không làm gì cả
                  },
                ),
                // *** KẾT THÚC NÚT QUÉT BARCODE ***
              ],
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_errorMessage != null && !_isLoading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          Expanded(
            child:
                (!_isLoading && _errorMessage == null)
                    ? _searchResults.isEmpty &&
                            _searchController.text.isNotEmpty
                        ? Center(child: Text('Không tìm thấy kết quả nào.'))
                        : _searchResults.isEmpty &&
                            _searchController.text.isEmpty
                        ? Center(
                          child: Text(
                            'Nhập từ khóa hoặc quét mã vạch để tìm kiếm.',
                          ),
                        ) // Cập nhật thông báo
                        : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final foodItem = _searchResults[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              child: ListTile(
                                title: Text(foodItem.name),
                                subtitle: Text(
                                  '${foodItem.caloriesPer100g.toStringAsFixed(1)} kcal / 100g' +
                                      (foodItem.proteinPer100g != null
                                          ? ' • P:${foodItem.proteinPer100g!.toStringAsFixed(1)}g'
                                          : '') + // Hiển thị macro nếu có
                                      (foodItem.carbsPer100g != null
                                          ? ' • C:${foodItem.carbsPer100g!.toStringAsFixed(1)}g'
                                          : '') +
                                      (foodItem.fatPer100g != null
                                          ? ' • F:${foodItem.fatPer100g!.toStringAsFixed(1)}g'
                                          : '') +
                                      (foodItem.brand != null &&
                                              foodItem.brand!.isNotEmpty
                                          ? '\n${foodItem.brand}'
                                          : ''), // Thêm brand ở dòng mới nếu có
                                ),
                                isThreeLine:
                                    foodItem.brand != null &&
                                    foodItem
                                        .brand!
                                        .isNotEmpty, // Tự động 3 dòng nếu có brand
                                trailing: Icon(
                                  Icons.add_circle_outline,
                                  color: Colors.green,
                                ),
                                onTap: () => _showQuantityDialog(foodItem),
                              ),
                            );
                          },
                        )
                    : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
