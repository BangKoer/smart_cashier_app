import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:intl/intl.dart';
import 'package:smart_cashier_app/models/cart.dart';
import 'package:smart_cashier_app/utils/format_rupiah.dart' as format_rupiah;


class ReceiptPrinterService {
  // 🖨️ IP printer thermal kamu (misal printer LAN)
  static const String printerIp = '192.168.1.100';
  static const int printerPort = 9100;

  static Future<void> printReceipt({
    required List<CartItem> cartItems,
    required double totalPrice,
    required String paymentMethod,
    required String customerName,
  }) async {
    try {
      final profile = await CapabilityProfile.load();
      final printer = NetworkPrinter(PaperSize.mm80, profile);

      final PosPrintResult connect = await printer.connect(printerIp, port: printerPort);

      if (connect != PosPrintResult.success) {
        print('⚠️ Gagal konek ke printer: $connect');
        return;
      }

      final now = DateTime.now();
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss').format(now);

      // === HEADER ===
      printer.text('SMART CASHIER',
          styles: PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
      printer.text('Jl. Contoh No.123 - Surabaya',
          styles: PosStyles(align: PosAlign.center));
      printer.text('Telp. 0812-3456-7890', styles: PosStyles(align: PosAlign.center));
      printer.text('--------------------------------');

      // === INFO TRANSAKSI ===
      printer.text('Tanggal : $dateFormat');
      if (customerName.isNotEmpty) printer.text('Customer: $customerName');
      printer.text('--------------------------------');

      // === ITEM BARANG ===
      for (final item in cartItems) {
        final name = item.product.productName;
        final qty = item.qty;
        final price = format_rupiah.toRupiah(item.selectedUnit?.price ?? 0);
        final total = format_rupiah.toRupiah(item.total);

        // baris pertama: nama produk
        printer.text(name, styles: PosStyles(bold: true));

        // baris kedua: qty × harga = total
        printer.text('$qty x $price', styles: PosStyles(align: PosAlign.left));
        printer.text(total, styles: PosStyles(align: PosAlign.right));
      }

      printer.text('--------------------------------');
      printer.text('TOTAL: ${format_rupiah.toRupiah(totalPrice)}',
          styles: PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size2));
      printer.text('Metode: ${paymentMethod.toUpperCase()}');
      printer.text('--------------------------------');

      // === FOOTER ===
      printer.text('Terima kasih atas pembelian Anda!',
          styles: PosStyles(align: PosAlign.center));
      printer.text('Barang yang sudah dibeli tidak dapat dikembalikan.',
          styles: PosStyles(align: PosAlign.center, bold: false));
      printer.feed(3);
      printer.cut();

      printer.disconnect();
    } catch (e) {
      print('❌ Error print struk: $e');
    }
  }
}
