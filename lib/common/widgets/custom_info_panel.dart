import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import 'package:smart_cashier_app/constant/global_variables.dart';

class TopInfoPanel extends StatefulWidget {
  final String userName;
  const TopInfoPanel({super.key, required this.userName});

  @override
  State<TopInfoPanel> createState() => _TopInfoPanelState();
}

class _TopInfoPanelState extends State<TopInfoPanel> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;
        setState(() {
          _now = DateTime.now();
        });
      },
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clock = DateFormat('HH:mm:ss').format(_now);
    final date = DateFormat('EEEE, dd MM yyyy').format(_now);
    final user = widget.userName.trim().isEmpty ? '-' : widget.userName.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _infoRow(
            icon: Icons.access_time_filled_rounded,
            text: clock,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: GlobalVariables.secondaryColor,
            ),
          ),
          const SizedBox(height: 4),
          _infoRow(
            icon: Icons.calendar_month_rounded,
            text: date,
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          _infoRow(
            icon: Icons.person_rounded,
            text: user,
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: GlobalVariables.thirdColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String text,
    required TextStyle textStyle,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: textStyle.color),
        const SizedBox(width: 6),
        Text(text, style: textStyle),
      ],
    );
  }
}
