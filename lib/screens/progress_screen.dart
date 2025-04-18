// lib/screens/progress_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../providers/calorie_provider.dart';
import '../models/weight_entry.dart';
import 'add_weight_screen.dart';

class ProgressScreen extends StatefulWidget {
  @override
  _ProgressScreenState createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool _isLoading = true; // Bắt đầu với trạng thái loading
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    if (mounted)
      setState(() {
        _isLoading = true;
        _errorMsg = null;
      });
    try {
      await Provider.of<CalorieProvider>(
        context,
        listen: false,
      ).fetchWeightHistory();
    } catch (e) {
      print("Error fetching weight data in ProgressScreen: $e");
      if (mounted) {
        setState(() {
          _errorMsg =
              'Lỗi tải dữ liệu: ${e.toString().replaceFirst("Exception: ", "")}';
        });
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
          if (_errorMsg != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  _errorMsg!,
                  style: TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (weightData.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /* ... Thông báo chưa có data ... */
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
                      (weightData.length < 2)
                          ? Center(
                            child: Text(
                              'Cần ít nhất 2 điểm dữ liệu\nđể vẽ biểu đồ đường.',
                              textAlign: TextAlign.center,
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
    ).then((_) => _fetchData()); // Tải lại dữ liệu sau khi thêm
  }

  LineChartData _buildChartData(List<WeightEntry> data, BuildContext context) {
    if (data.isEmpty) return LineChartData(); // Trả về rỗng nếu data rỗng

    List<FlSpot> spots =
        data
            .map(
              (entry) => FlSpot(
                entry.timestamp.millisecondsSinceEpoch.toDouble(),
                entry.weight,
              ),
            )
            .toList();

    // Xử lý data chỉ có 1 điểm để vẽ biểu đồ
    bool isSinglePoint = data.length < 2;
    double minY, maxY, minX, maxX;

    if (isSinglePoint) {
      minY = spots.first.y - 5;
      maxY = spots.first.y + 5;
      minX = spots.first.x - Duration(days: 1).inMilliseconds.toDouble();
      maxX = spots.first.x + Duration(days: 1).inMilliseconds.toDouble();
    } else {
      minY = spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b) - 2;
      maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) + 2;
      minX = spots.first.x;
      maxX = spots.last.x;
      if (minX == maxX) {
        minX -= Duration(days: 1).inMilliseconds;
        maxX += Duration(days: 1).inMilliseconds;
      }
    }
    if (minY < 0) minY = 0;
    double horizontalInterval =
        (maxY - minY).abs() > 1
            ? (maxY - minY) / 5
            : 1; // Tránh chia cho 0 hoặc số quá nhỏ

    return LineChartData(
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
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
        horizontalInterval: horizontalInterval,
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
          axisNameWidget: Text(
            "Ngày",
            style: TextStyle(fontSize: 10, color: Colors.grey[700]),
          ), // Thêm tên trục X
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32, // Tăng khoảng trống nếu cần
            // interval: // Bỏ interval để fl_chart tự quyết định
            getTitlesWidget: (value, meta) {
              // Logic hiển thị nhãn trục X
              DateTime date = DateTime.fromMillisecondsSinceEpoch(
                value.toInt(),
              );
              // Chỉ hiển thị nhãn ở các khoảng do fl_chart quyết định, tránh chồng chéo
              // Nếu muốn kiểm soát nhiều hơn, bạn cần logic phức tạp hơn ở đây
              // hoặc đặt interval cố định (ví dụ: mỗi 2 ngày)
              // if (value != meta.min && value != meta.max) { // Vẫn có thể ẩn đầu cuối nếu muốn
              return SideTitleWidget(
                meta: meta,
                space: 10.0,
                child: Text(
                  DateFormat('dd/MM', 'vi_VN').format(date),
                  style: TextStyle(fontSize: 10),
                ),
              );
              // }
              // return Container();
            },
          ),
        ),
        leftTitles: AxisTitles(
          axisNameWidget: Text(
            "Cân nặng (kg)",
            style: TextStyle(fontSize: 10, color: Colors.grey[700]),
          ), // Thêm tên trục Y
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            getTitlesWidget: (value, meta) {
              // if (value == meta.min || value == meta.max) return Container(); // Có thể ẩn đầu cuối
              return SideTitleWidget(
                meta: meta,
                space: 4.0, // Đảm bảo đủ chỗ
                child: Text(
                  '${value.toInt()}',
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
            show: !isSinglePoint, // Chỉ hiển thị điểm nếu có nhiều hơn 1 điểm
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
        // Vẽ điểm duy nhất nếu chỉ có 1 điểm dữ liệu
        if (isSinglePoint)
          LineChartBarData(
            spots: spots,
            dotData: FlDotData(
              show: true,
              getDotPainter:
                  (spot, percent, barData, index) => FlDotCirclePainter(
                    radius: 5,
                    color: Theme.of(context).primaryColorDark,
                    strokeWidth: 1,
                    strokeColor: Colors.white,
                  ),
            ),
            // Đặt barWidth = 0 để không vẽ đường nối
            barWidth: 0,
          ),
      ],
      // Thêm giới hạn cho các đường kẻ không vượt ra ngoài vùng dữ liệu (tùy chọn)
      // clipData: FlClipData.all(),
    );
  }
}
