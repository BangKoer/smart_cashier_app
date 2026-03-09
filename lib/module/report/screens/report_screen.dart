import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'package:smart_cashier_app/common/widgets/custom_loading.dart';
import 'package:smart_cashier_app/constant/global_variables.dart';
import 'package:smart_cashier_app/constant/utils.dart';
import 'package:smart_cashier_app/module/report/services/report_services.dart';
import 'package:smart_cashier_app/utils/format_rupiah.dart' as format;

class ReportScreen extends StatefulWidget {
  static const String routeName = 'report-screen';
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ReportServices _reportServices = ReportServices();

  bool _isLoading = true;
  String? _errorMessage;
  DateTime? _fromDate;
  DateTime? _toDate;
  String _paymentStatus = 'all';

  Map<String, dynamic> _kpi = {
    "total_transaction": 0,
    "total_sales": 0.0,
    "total_profit": 0.0,
    "avg_transaction_value": 0.0,
  };
  Map<String, dynamic> _series = {
    "group_by": "day",
    "points": <Map<String, dynamic>>[],
  };

  Future<void> _loadKpiSummary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final filtersPayment = _paymentStatus == 'all' ? null : _paymentStatus;
      final data = await _reportServices.fetchKpiSummary(
          context: context,
          dateFrom: _fromDate,
          dateTo: _toDate,
          paymentStatus: filtersPayment);
      final series = await _reportServices.fetchSalesSeries(
        context: context,
        dateFrom: _fromDate,
        dateTo: _toDate,
        paymentStatus: filtersPayment,
      );
      if (!mounted) return;
      setState(() {
        _kpi = data;
        _series = series;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadKpiSummary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadKpiSummary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          children: [
            const Text(
              "Sales Report",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: GlobalVariables.thirdColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildFilterSection(),
            const SizedBox(height: 16),
            if (_isLoading)
              const SizedBox(
                height: 220,
                child: Center(
                  child: CustomLoading(),
                ),
              )
            else if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildKpiSection(),
                  const SizedBox(height: 20),
                  _buildSalesSeriesSection(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    final DateTime? localFromDate = _fromDate;
    final DateTime? localToDate = _toDate;
    final fromDateText =
        localFromDate == null ? 'From Date' : _formatDate(localFromDate);
    final toDateText = localToDate == null ? 'To Date' : _formatDate(localToDate);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _pickFromDate,
              icon: const Icon(Icons.date_range),
              label: Text(fromDateText),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _pickToDate,
              icon: const Icon(Icons.event),
              label: Text(toDateText),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              ),
            ),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                value: _paymentStatus,
                decoration: const InputDecoration(
                  labelText: "Payment Status",
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'paid', child: Text('Paid')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                ],
                onChanged: (value) {
                  setState(() {
                    _paymentStatus = value ?? 'all';
                  });
                },
              ),
            ),
            ElevatedButton.icon(
              onPressed: _applyFilters,
              icon: const Icon(Icons.filter_alt),
              label: const Text("Apply"),
            ),
            OutlinedButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.restart_alt),
              label: const Text("Reset"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? now,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year + 5, 12, 31),
    );

    if (picked == null) return;
    setState(() {
      _fromDate = picked;
    });
  }

  Future<void> _pickToDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? _fromDate ?? now,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year + 5, 12, 31),
    );

    if (picked == null) return;
    setState(() {
      _toDate = picked;
    });
  }

  Future<void> _applyFilters() async {
    final DateTime? localFromDate = _fromDate;
    final DateTime? localToDate = _toDate;

    if (localFromDate != null &&
        localToDate != null &&
        localFromDate.isAfter(localToDate)) {
      if (!mounted) return;
      showSnackBar(
        context,
        "From Date cannot be after To Date",
        bgColor: Colors.red,
      );
      return;
    }
    await _loadKpiSummary();
  }

  Future<void> _resetFilters() async {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _paymentStatus = 'all';
    });
    await _loadKpiSummary();
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Widget _buildKpiSection() {
    const spacing = 12.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;
        if (isWide) {
          final cardWidth = (constraints.maxWidth - (spacing * 3)) / 4;
          return Row(
            children: [
              SizedBox(
                width: cardWidth,
                child: _buildKpiCard(
                  title: "Total Transaction",
                  value: (_kpi["total_transaction"] ?? 0).toString(),
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: spacing),
              SizedBox(
                width: cardWidth,
                child: _buildKpiCard(
                  title: "Total Sales",
                  value: format.toRupiah(_kpi["total_sales"] ?? 0),
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: spacing),
              SizedBox(
                width: cardWidth,
                child: _buildKpiCard(
                  title: "Total Profit",
                  value: format.toRupiah(_kpi["total_profit"] ?? 0),
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: spacing),
              SizedBox(
                width: cardWidth,
                child: _buildKpiCard(
                  title: "ATV",
                  value: format.toRupiah(_kpi["avg_transaction_value"] ?? 0),
                  color: Colors.purple,
                ),
              ),
            ],
          );
        }

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            _buildKpiCard(
              title: "Total Transaction",
              value: (_kpi["total_transaction"] ?? 0).toString(),
              color: Colors.blue,
            ),
            _buildKpiCard(
              title: "Total Sales",
              value: format.toRupiah(_kpi["total_sales"] ?? 0),
              color: Colors.green,
            ),
            _buildKpiCard(
              title: "Total Profit",
              value: format.toRupiah(_kpi["total_profit"] ?? 0),
              color: Colors.orange,
            ),
            _buildKpiCard(
              title: "ATV",
              value: format.toRupiah(_kpi["avg_transaction_value"] ?? 0),
              color: Colors.purple,
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return SizedBox(
      width: 250,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSalesSeriesSection() {
    final pointsRaw = (_series["points"] as List?) ?? const [];
    final points = pointsRaw
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Sales Performance Over Time",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              "Grouping: ${(_series["group_by"] ?? "day").toString()}",
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 14),
            if (points.isEmpty)
              const SizedBox(
                height: 220,
                child: Center(child: Text("No chart data for current filter")),
              )
            else
              SizedBox(
                height: 280,
                child: CustomPaint(
                  painter: _SalesLineChartPainter(points: points),
                  child: Container(),
                ),
              ),
            if (points.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                "Range: ${points.first["label"]} - ${points.last["label"]}",
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SalesLineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> points;

  _SalesLineChartPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    const chartLeft = 52.0;
    const chartRightPadding = 16.0;
    const chartTop = 28.0;
    const chartBottomPadding = 36.0;

    final chartRight = size.width - chartRightPadding;
    final chartBottom = size.height - chartBottomPadding;
    final chartWidth = chartRight - chartLeft;
    final chartHeight = chartBottom - chartTop;

    final axisPaint = Paint()
      ..color = Colors.black38
      ..strokeWidth = 1;
    final gridPaint = Paint()
      ..color = Colors.black26
      ..strokeWidth = 1;

    final lineColor = GlobalVariables.thirdColor;
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    // Legend
    canvas.drawLine(const Offset(14, 10), const Offset(36, 10), linePaint);
    _drawText(
      canvas,
      "total_sales",
      const Offset(42, 2),
      const TextStyle(
        color: Colors.black87,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );

    final salesValues = points
        .map((e) => (e["total_sales"] as num?)?.toDouble() ?? 0.0)
        .toList(growable: false);
    double minValue = salesValues.reduce((a, b) => a < b ? a : b);
    double maxValue = salesValues.reduce((a, b) => a > b ? a : b);
    minValue = 0;
    if (minValue == maxValue) {
      maxValue = maxValue + 1;
    }

    // Grid
    const yGridCount = 5;
    final xGridCount = points.length <= 1 ? 1 : (points.length - 1).clamp(1, 20);
    for (int i = 0; i <= xGridCount; i++) {
      final x = chartLeft + (i / xGridCount) * chartWidth;
      canvas.drawLine(Offset(x, chartTop), Offset(x, chartBottom), gridPaint);
    }

    for (int i = 0; i <= yGridCount; i++) {
      final ratio = i / yGridCount;
      final y = chartBottom - (ratio * chartHeight);
      canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);

      final axisValue = minValue + ((maxValue - minValue) * ratio);
      _drawText(
        canvas,
        _formatCompact(axisValue),
        Offset(4, y - 7),
        const TextStyle(color: Colors.black54, fontSize: 10),
      );
    }

    canvas.drawLine(Offset(chartLeft, chartBottom), Offset(chartRight, chartBottom), axisPaint);
    canvas.drawLine(Offset(chartLeft, chartTop), Offset(chartLeft, chartBottom), axisPaint);

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final x = chartLeft +
          (points.length == 1
              ? chartWidth / 2
              : (i / (points.length - 1)) * chartWidth);
      final value = (points[i]["total_sales"] as num?)?.toDouble() ?? 0.0;
      final y =
          chartBottom - ((value - minValue) / (maxValue - minValue)) * chartHeight;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    for (int i = 0; i < points.length; i++) {
      final x = chartLeft +
          (points.length == 1
              ? chartWidth / 2
              : (i / (points.length - 1)) * chartWidth);
      final value = (points[i]["total_sales"] as num?)?.toDouble() ?? 0.0;
      final y =
          chartBottom - ((value - minValue) / (maxValue - minValue)) * chartHeight;
      canvas.drawCircle(Offset(x, y), 2.2, dotPaint);
    }

    final maxLabels = 8;
    final step = points.length <= maxLabels ? 1 : (points.length / maxLabels).ceil();
    for (int i = 0; i < points.length; i += step) {
      final x = chartLeft +
          (points.length == 1
              ? chartWidth / 2
              : (i / (points.length - 1)) * chartWidth);
      final rawLabel = points[i]["label"]?.toString() ?? "";
      final shortLabel = _gridDateLabel(rawLabel);
      _drawText(
        canvas,
        shortLabel,
        Offset(x - 16, chartBottom + 6),
        const TextStyle(color: Colors.black54, fontSize: 10),
      );
    }
  }

  String _gridDateLabel(String raw) {
    try {
      DateTime parsed;
      if (RegExp(r'^\d{4}-\d{2}$').hasMatch(raw)) {
        // Month group format from backend: YYYY-MM
        parsed = DateTime.parse('$raw-01');
      } else {
        // Day/week formats from backend: YYYY-MM-DD
        parsed = DateTime.parse(raw);
      }
      return DateFormat('dd-MMM-yyyy').format(parsed);
    } catch (_) {
      return raw;
    }
  }

  String _formatCompact(double value) {
    if (value >= 1000000000) return '${(value / 1000000000).toStringAsFixed(1)}B';
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}k';
    return value.toStringAsFixed(0);
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _SalesLineChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
