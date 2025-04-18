// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Import các thành phần cần thiết
import '../providers/calorie_provider.dart';
import '../providers/auth_provider.dart';
import 'add_food_screen.dart';
import 'settings_screen.dart';
import 'progress_screen.dart'; // Đảm bảo dòng này đã được import và file tồn tại

class HomeScreen extends StatelessWidget {
  // Giữ là StatelessWidget

  // Hàm helper để tạo cột hiển thị Macro
  Widget _buildMacroColumn(
    BuildContext context,
    String label,
    double value,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(1)}g',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // Hàm helper để tạo cột hiển thị Calo
  Widget _buildCalorieColumn(
    String label,
    double value,
    Color color, {
    bool isGoal = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: isGoal ? 20 : 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        if (!isGoal)
          Text('kcal', style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lấy AuthProvider (không cần lắng nghe thay đổi ở đây)
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Sử dụng Consumer để lắng nghe và rebuild khi CalorieProvider thay đổi
    return Scaffold(
      appBar: AppBar(
        // Title hiển thị ngày, tự cập nhật khi ngày thay đổi trong provider
        title: Consumer<CalorieProvider>(
          builder:
              (context, calorieProvider, _) => Text(
                'Ngày: ${DateFormat('dd/MM/yyyy', 'vi_VN').format(calorieProvider.selectedDate)}', // Thêm locale 'vi_VN'
              ),
        ),
        actions: [
          // Nút chọn ngày
          IconButton(
            icon: Icon(Icons.calendar_today),
            tooltip: 'Chọn ngày',
            onPressed: () async {
              final DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate:
                    Provider.of<CalorieProvider>(
                      context,
                      listen: false,
                    ).selectedDate,
                firstDate: DateTime(2020), // Giới hạn ngày bắt đầu
                lastDate: DateTime.now().add(
                  Duration(days: 365),
                ), // Giới hạn ngày kết thúc
                locale: const Locale("vi", "VN"), // Đặt locale tiếng Việt
              );
              // Sau khi DatePicker đóng, kiểm tra xem người dùng có chọn ngày không
              if (pickedDate != null) {
                // Kiểm tra context còn hợp lệ không trước khi gọi Provider
                if (context.mounted) {
                  await Provider.of<CalorieProvider>(
                    context,
                    listen: false,
                  ).changeSelectedDate(pickedDate);
                }
              }
            },
          ),
          // Nút Xem Tiến trình
          IconButton(
            icon: Icon(Icons.show_chart),
            tooltip: 'Xem tiến trình',
            onPressed: () {
              // Điều hướng đến màn hình ProgressScreen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProgressScreen()),
              );
            },
          ),
          // Nút Cài đặt
          IconButton(
            icon: Icon(Icons.settings),
            tooltip: 'Cài đặt',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SettingsScreen()),
              );
            },
          ),
          // Nút Đăng xuất
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () async {
              // Hiển thị dialog xác nhận
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (ctx) => AlertDialog(
                      title: Text('Xác nhận Đăng xuất'),
                      content: Text('Bạn có chắc muốn đăng xuất?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: Text(
                            'Đăng xuất',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
              );
              // Nếu người dùng xác nhận
              if (confirm == true) {
                // Kiểm tra context trước khi gọi hàm async từ provider
                if (context.mounted) {
                  await authProvider.signOut(); // Gọi hàm đăng xuất
                }
              }
            },
          ),
        ],
      ),
      body: Consumer<CalorieProvider>(
        builder: (context, calorieProvider, child) {
          // Hiển thị loading indicator nếu đang tải và chưa có dữ liệu log nào
          if (calorieProvider.isLoading && calorieProvider.logEntries.isEmpty) {
            return Center(child: CircularProgressIndicator());
          }

          // Cho phép kéo để làm mới
          return RefreshIndicator(
            onRefresh:
                () => calorieProvider.fetchLogEntries(
                  calorieProvider.selectedDate,
                ),
            child: Column(
              children: [
                // Phần tổng quan Calo & Macros
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Hàng Calo
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildCalorieColumn(
                                'Tiêu thụ',
                                calorieProvider.totalCaloriesToday,
                                Colors.orange,
                              ),
                              Container(
                                height: 40,
                                width: 1,
                                color: Colors.grey[300],
                              ),
                              _buildCalorieColumn(
                                'Mục tiêu',
                                calorieProvider.calorieGoal,
                                Colors.green,
                                isGoal: true,
                              ),
                              Container(
                                height: 40,
                                width: 1,
                                color: Colors.grey[300],
                              ),
                              _buildCalorieColumn(
                                'Còn lại',
                                (calorieProvider.calorieGoal -
                                    calorieProvider.totalCaloriesToday),
                                (calorieProvider.calorieGoal -
                                            calorieProvider
                                                .totalCaloriesToday) >=
                                        0
                                    ? Colors.blueAccent
                                    : Colors.redAccent,
                              ),
                            ],
                          ),
                          Divider(
                            height: 25,
                            thickness: 1,
                            indent: 10,
                            endIndent: 10,
                          ),
                          // Hàng Macros
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMacroColumn(
                                context,
                                'Protein',
                                calorieProvider.totalProtein,
                                Colors.blue[600]!,
                              ),
                              _buildMacroColumn(
                                context,
                                'Carbs',
                                calorieProvider.totalCarbs,
                                Colors.deepOrange[400]!,
                              ),
                              _buildMacroColumn(
                                context,
                                'Fat',
                                calorieProvider.totalFat,
                                Colors.red[400]!,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Tiêu đề danh sách nhật ký
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.list_alt, color: Colors.grey[600]),
                      SizedBox(width: 8),
                      Text(
                        'Nhật ký ${DateFormat('dd/MM', 'vi_VN').format(calorieProvider.selectedDate)}', // Hiển thị ngày đang xem
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),

                // Danh sách thực phẩm đã thêm
                Expanded(
                  child:
                      calorieProvider.logEntries.isEmpty
                          ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(30.0),
                              child: Text(
                                'Chưa có thực phẩm nào được thêm vào ngày này.\nNhấn nút + để bắt đầu.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          )
                          : ListView.builder(
                            itemCount: calorieProvider.logEntries.length,
                            itemBuilder: (context, index) {
                              final entry = calorieProvider.logEntries[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                elevation: 1.5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListTile(
                                  title: Text(
                                    entry.foodName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${entry.quantity.toStringAsFixed(0)}${entry.unit}'
                                    '  •  P:${entry.protein?.toStringAsFixed(1) ?? '-'}g'
                                    '  C:${entry.carbs?.toStringAsFixed(1) ?? '-'}g'
                                    '  F:${entry.fat?.toStringAsFixed(1) ?? '-'}g'
                                    '\nLúc: ${DateFormat('HH:mm').format(entry.timestamp.toDate())}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  isThreeLine: true,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${entry.calories.toStringAsFixed(0)} kcal',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      SizedBox(width: 5),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: Colors.red[400],
                                        ),
                                        tooltip: 'Xóa mục này',
                                        iconSize: 22,
                                        padding: EdgeInsets.zero,
                                        constraints: BoxConstraints(),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder:
                                                (ctx) => AlertDialog(
                                                  title: Text('Xác nhận xóa'),
                                                  content: Text(
                                                    'Bạn có chắc muốn xóa "${entry.foodName}" khỏi nhật ký?',
                                                  ),
                                                  actions: <Widget>[
                                                    TextButton(
                                                      child: Text('Hủy'),
                                                      onPressed:
                                                          () =>
                                                              Navigator.of(
                                                                ctx,
                                                              ).pop(),
                                                    ),
                                                    TextButton(
                                                      child: Text(
                                                        'Xóa',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                      onPressed: () {
                                                        Navigator.of(ctx).pop();
                                                        if (entry.id != null) {
                                                          calorieProvider
                                                              .deleteLogEntry(
                                                                entry.id!,
                                                              );
                                                        } else {
                                                          print(
                                                            "Error: Entry ID is null, cannot delete.",
                                                          );
                                                          if (context.mounted) {
                                                            // Kiểm tra context trước khi dùng
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  'Lỗi: Không thể xóa mục này (thiếu ID).',
                                                                ),
                                                                backgroundColor:
                                                                    Colors.red,
                                                              ),
                                                            );
                                                          }
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                ),
              ],
            ),
          );
        },
      ),
      // Nút thêm thực phẩm
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddFoodScreen()),
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Thêm thực phẩm',
      ),
    );
  }
}
