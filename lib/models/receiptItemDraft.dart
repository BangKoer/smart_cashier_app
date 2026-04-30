import 'package:flutter/material.dart';

class ReceiptItemDraft {
  int? productId;
  int? unitId;
  final TextEditingController qtyCtrl = TextEditingController();
  final TextEditingController unitCostCtrl = TextEditingController();

  void dispose() {
    qtyCtrl.dispose();
    unitCostCtrl.dispose();
  }
}