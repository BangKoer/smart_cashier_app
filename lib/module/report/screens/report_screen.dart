import 'package:flutter/material.dart';
import 'package:smart_cashier_app/constant/global_variables.dart';
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

  Map<String, dynamic> _kpi = {
    "total_transaction": 0,
    "total_sales": 0.0,
    "total_profit": 0.0,
    "avg_transaction_value": 0.0,
  };

  Future<void> _loadKpiSummary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _reportServices.fetchKpiSummary(context: context);
      if (!mounted) return;
      setState(() {
        _kpi = data;
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
          padding: const EdgeInsets.all(16),
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
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 50),
                child: Center(child: CircularProgressIndicator()),
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
              Wrap(
                spacing: 12,
                runSpacing: 12,
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
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required Color color,
  }) {
    final cardWidth = (MediaQuery.of(context).size.width - 64) / 2;
    return SizedBox(
      width: cardWidth < 240 ? double.infinity : cardWidth,
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
}
