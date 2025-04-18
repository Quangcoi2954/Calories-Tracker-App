// lib/screens/progress_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart'; // Import thư viện biểu đồ
import 'package:intl/intl.dart'; // Để format ngày tháng

import '../providers/calorie_provider.dart'; // Provider chứa dữ liệu cân nặng
import '../models/weight_entry.dart'; // Model cho dữ liệu cân nặng
import 'add_weight_screen.dart'; // Màn hình để thêm cân nặng mới

class ProgressScreen extends StatefulWidget {
  @override
  _ProgressScreenState createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool _isLoading = false; // State loading cục bộ cho lần fetch đầu tiên

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      await Provider.of<CalorieProvider>(
        context,
        listen: false,
      ).fetchWeightHistory();
    } catch (e) {
      print("Error fetching weight data in ProgressScreen: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu cân nặng: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tiến trình Cân nặng'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Tải lại dữ liệu',
            onPressed: _fetchData,
          ),
        ],
      ),
      body: Consumer<CalorieProvider>(
        builder: (context, calorieProvider, child) {
          final weightData = calorieProvider.weightHistory;

          if (_isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (weightData.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sentiment_dissatisfied,
                    size: 60,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có dữ liệu cân nặng.',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Hãy thêm cân nặng hiện tại của bạn!',
                    style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToAddWeight(context),
                    icon: Icon(Icons.add),
                    label: Text('Thêm Cân nặng'),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(
              top: 20.0,
              bottom: 20.0,
              left: 10.0,
              right: 20.0,
            ),
            child: Column(
              children: [
                Text(
                  'Biểu đồ Thay đổi Cân nặng',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 25),
                Expanded(
                  child:
                      (weightData.length <
                              2) // Xử lý trường hợp ít hơn 2 điểm dữ liệu
                          ? Center(
                            child: Text(
                              'Cần ít nhất 2 điểm dữ liệu để vẽ biểu đồ đường.',
                            ),
                          )
                          : LineChart(_buildChartData(weightData, context)),
                ),
                SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddWeight(context),
        label: Text('Thêm Cân nặng'),
        icon: Icon(Icons.add),
      ),
    );
  }

  void _navigateToAddWeight(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddWeightScreen()),
    ).then((_) {
      // Tùy chọn: Tải lại dữ liệu sau khi màn hình AddWeight đóng lại
      // Bỏ comment nếu muốn tự động refresh
      // _fetchData();
    });
  }

  // --- Hàm xây dựng dữ liệu cho LineChart ĐÃ SỬA LỖI ---
  LineChartData _buildChartData(List<WeightEntry> data, BuildContext context) {
    // Cần ít nhất 2 điểm để vẽ đường, nếu không trả về data rỗng hoặc cấu hình đặc biệt
    if (data.length < 2) {
      // Hoặc bạn có thể cấu hình để vẽ 1 điểm nếu muốn
      return LineChartData(); // Trả về data rỗng để tránh lỗi
    }

    List<FlSpot> spots =
        data.asMap().entries.map((entry) {
          return FlSpot(
            entry.value.timestamp.millisecondsSinceEpoch.toDouble(),
            entry.value.weight,
          );
        }).toList();

    double minY =
        spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b) - 2;
    double maxY =
        spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) + 2;
    if (minY < 0) minY = 0;

    double minX = spots.first.x;
    double maxX = spots.last.x;
    // Đảm bảo minX và maxX không trùng nhau tuyệt đối (gây lỗi chia cho 0 ở interval)
    if (minX == maxX) {
      minX = minX - Duration(days: 1).inMilliseconds;
      maxX = maxX + Duration(days: 1).inMilliseconds;
    }
    // Tính toán interval hợp lý, tránh chia cho 0
    double bottomInterval =
        (maxX - minX) > 0 ? (maxX - minX) / 4 : 1; // Chia 4 khoảng nếu > 0
    double horizontalInterval =
        (maxY - minY) > 0 ? (maxY - minY) / 5 : 1; // Chia 5 khoảng nếu > 0

    return LineChartData(
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          // Lỗi 'tooltipBgColor' isn't defined?
          // Tham số này hợp lệ trong các phiên bản fl_chart gần đây.
          // Nếu bạn vẫn gặp lỗi, hãy kiểm tra lại tên hoặc thử xóa tạm dòng này
          // và tham khảo docs của phiên bản fl_chart bạn đang dùng.
          //tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              final flSpot = barSpot;
              final dt = DateTime.fromMillisecondsSinceEpoch(flSpot.x.toInt());
              return LineTooltipItem(
                '${DateFormat('dd/MM/yy').format(dt)}\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: '${flSpot.y.toStringAsFixed(1)} kg',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                textAlign: TextAlign.center,
              );
            }).toList();
          },
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: horizontalInterval, // Dùng interval đã tính
        verticalInterval: bottomInterval, // Dùng interval đã tính
        getDrawingHorizontalLine:
            (value) => FlLine(color: Colors.grey[300]!, strokeWidth: 0.5),
        getDrawingVerticalLine:
            (value) => FlLine(color: Colors.grey[300]!, strokeWidth: 0.5),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: bottomInterval, // Dùng interval đã tính
            getTitlesWidget: (value, meta) {
              // Hàm này nhận value và meta
              // Chỉ hiển thị nếu không phải min/max để tránh trùng lặp
              if (value == meta.min || value == meta.max) return Container();
              DateTime date = DateTime.fromMillisecondsSinceEpoch(
                value.toInt(),
              );
              return SideTitleWidget(
                // *** SỬA LỖI 2 & 3: Thêm meta, xóa axisSide ***
                meta: meta, // Thêm tham số meta
                space: 8.0,
                // axisSide: meta.axisSide, // Bỏ dòng này
                child: Text(
                  DateFormat('dd/MM').format(date),
                  style: TextStyle(fontSize: 10),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            // interval: 5, // Có thể đặt interval cố định hoặc để thư viện tự tính
            getTitlesWidget: (value, meta) {
              // Hàm này nhận value và meta
              if (value == meta.min || value == meta.max) return Container();
              return SideTitleWidget(
                // *** SỬA LỖI 2 & 3: Thêm meta, xóa axisSide ***
                meta: meta, // Thêm tham số meta
                space: 4.0, // Giảm space nếu cần
                // axisSide: meta.axisSide, // Bỏ dòng này
                child: Text(
                  '${value.toInt()}kg',
                  style: TextStyle(fontSize: 10),
                  textAlign: TextAlign.right,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey[400]!, width: 1),
      ),
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Theme.of(context).primaryColor,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter:
                (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4,
                  color: Theme.of(context).primaryColorDark,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: Theme.of(context).primaryColor.withOpacity(0.2),
          ),
        ),
      ],
    );
  }
}
