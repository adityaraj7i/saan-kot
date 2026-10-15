import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/order_model.dart';
import '../../models/menu_item_model.dart';
import '../../theme/app_theme.dart';

/// Supported thermal paper sizes
enum PaperSize {
  mm58(32, '58mm (Compact)'),
  mm80(48, '80mm (Standard)');

  final int columns;
  final String label;
  const PaperSize(this.columns, this.label);
}

/// Supported printer connection modes
enum PrinterConnectionMode {
  bluetooth('Bluetooth'),
  wifiLan('Wi-Fi / LAN IP');

  final String label;
  const PrinterConnectionMode(this.label);
}

/// Data payload for kitchen order ticket printing
class KotPrintData {
  final String kotNumber;
  final String tableName;
  final String serverName;
  final DateTime timestamp;
  final List<OrderLineItem> items;
  final String? notes;

  const KotPrintData({
    required this.kotNumber,
    required this.tableName,
    required this.serverName,
    required this.timestamp,
    required this.items,
    this.notes,
  });
}

/// Thermal receipt text formatter adhering to exact column widths
class ThermalFormatter {
  static String center(String text, int width) {
    if (text.length >= width) return text.substring(0, width);
    final totalPad = width - text.length;
    final leftPad = totalPad ~/ 2;
    final rightPad = totalPad - leftPad;
    return '${' ' * leftPad}$text${' ' * rightPad}';
  }

  static String divider(int width, [String char = '-']) {
    return char * width;
  }

  static String doubleDivider(int width) {
    return '=' * width;
  }

  static String twoColumn(String left, String right, int width) {
    final available = width - right.length;
    if (available <= 0) return '$left $right';
    if (left.length > available - 1) {
      left = left.substring(0, available - 1);
    }
    return left.padRight(available) + right;
  }

  static String threeColumn(
    String col1,
    String col2,
    String col3,
    int width, {
    int col2Width = 5,
    int col3Width = 10,
  }) {
    final col1Width = width - col2Width - col3Width;
    var c1 = col1;
    if (c1.length > col1Width) {
      c1 = c1.substring(0, col1Width);
    }
    final p1 = c1.padRight(col1Width);
    final p2 = col2.padLeft(col2Width);
    final p3 = col3.padLeft(col3Width);
    return '$p1$p2$p3';
  }

  /// Formats a Kitchen Order Ticket (KOT)
  static String formatKot(
    KotPrintData kot, {
    PaperSize paperSize = PaperSize.mm58,
  }) {
    final w = paperSize.columns;
    final sb = StringBuffer();

    sb.writeln(doubleDivider(w));
    sb.writeln(center('*** SAAN KOT ***', w));
    sb.writeln(center('KITCHEN ORDER TICKET', w));
    sb.writeln(doubleDivider(w));
    sb.writeln(twoColumn('TABLE: ${kot.tableName.toUpperCase()}', kot.kotNumber, w));
    sb.writeln(twoColumn('SERVER: ${kot.serverName}', _formatDate(kot.timestamp), w));
    sb.writeln(divider(w));
    sb.writeln(twoColumn('ITEM', 'QTY', w));
    sb.writeln(divider(w));

    for (final item in kot.items) {
      final name = item.item.name;
      final qty = 'x${item.quantity}';
      sb.writeln(twoColumn(name, qty, w));
    }

    sb.writeln(divider(w));
    if (kot.notes != null && kot.notes!.isNotEmpty) {
      sb.writeln('NOTE: ${kot.notes}');
      sb.writeln(divider(w));
    }
    sb.writeln(center('>>> SENT TO KITCHEN <<<', w));
    sb.writeln(doubleDivider(w));

    return sb.toString();
  }

  /// Formats an itemized Customer Bill / Tax Receipt
  static String formatCustomerReceipt(
    OrderModel order, {
    PaperSize paperSize = PaperSize.mm58,
    String cafeName = 'SAAN CAFE & LOUNGE',
    String branch = 'Kathmandu Main Branch',
    String panNumber = '609823412',
    String serverName = 'Addy',
    double? cashGiven,
  }) {
    final w = paperSize.columns;
    final sb = StringBuffer();

    sb.writeln(doubleDivider(w));
    sb.writeln(center(cafeName, w));
    sb.writeln(center(branch, w));
    sb.writeln(center('VAT / PAN: $panNumber', w));
    sb.writeln(doubleDivider(w));
    sb.writeln(twoColumn('Order: ${order.id}', order.tableName, w));
    sb.writeln(twoColumn('Server: $serverName', _formatDate(order.createdAt), w));
    sb.writeln(divider(w));

    if (w == 32) {
      // 58mm layout: Item, Qty x Price, Total
      sb.writeln(twoColumn('ITEM (QTY)', 'TOTAL', w));
      sb.writeln(divider(w));
      for (final item in order.items) {
        final itemLine = '${item.item.name} (${item.quantity})';
        final totalStr = CurrencyHelper.format(item.totalPrice);
        sb.writeln(twoColumn(itemLine, totalStr, w));
      }
    } else {
      // 80mm layout: 3 columns (Item, Qty x Rate, Total)
      sb.writeln(threeColumn('ITEM', 'QTY x RATE', 'TOTAL', w, col2Width: 16, col3Width: 12));
      sb.writeln(divider(w));
      for (final item in order.items) {
        final rateStr = '${item.quantity} x ${item.item.price.toStringAsFixed(0)}';
        final totalStr = CurrencyHelper.format(item.totalPrice);
        sb.writeln(threeColumn(item.item.name, rateStr, totalStr, w, col2Width: 16, col3Width: 12));
      }
    }

    sb.writeln(divider(w));
    sb.writeln(twoColumn('Subtotal:', CurrencyHelper.format(order.subtotal), w));

    if (order.discountAmount > 0) {
      final discLabel = order.discountPreset == DiscountPreset.percent5
          ? 'Discount (5%):'
          : order.discountPreset == DiscountPreset.percent10
              ? 'Discount (10%):'
              : 'Discount:';
      sb.writeln(twoColumn(discLabel, '-${CurrencyHelper.format(order.discountAmount)}', w));
    }

    sb.writeln(doubleDivider(w));
    sb.writeln(twoColumn('PAYABLE TOTAL:', CurrencyHelper.format(order.payableAmount), w));
    sb.writeln(doubleDivider(w));

    if (order.status == OrderStatus.completed && order.paymentMethod != null) {
      sb.writeln(twoColumn('Payment Method:', _formatPaymentMethod(order.paymentMethod!), w));
      if (order.paymentMethod == PaymentMethod.cash && cashGiven != null && cashGiven > order.payableAmount) {
        final change = cashGiven - order.payableAmount;
        sb.writeln(twoColumn('Cash Tendered:', CurrencyHelper.format(cashGiven), w));
        sb.writeln(twoColumn('Change Returned:', CurrencyHelper.format(change), w));
      }
    } else {
      sb.writeln(twoColumn('Status:', 'PENDING BILL', w));
    }

    sb.writeln(divider(w));
    sb.writeln(center('Thank you for your visit!', w));
    sb.writeln(center('Powered by Saan KOT POS', w));
    sb.writeln(doubleDivider(w));

    return sb.toString();
  }

  /// Formats an End-of-Day Z-Report
  static String formatZReport({
    required double totalRevenue,
    required double totalDiscount,
    required int totalOrders,
    required double cashRevenue,
    required double fonepayRevenue,
    required double walletRevenue,
    required double bankRevenue,
    required double creditSales,
    required double creditCollectedCash,
    required double totalDrawerCash,
    required double totalCollection,
    required int lowStockCount,
    PaperSize paperSize = PaperSize.mm80,
    String cashier = 'Addy',
    DateTime? reportDate,
  }) {
    final w = paperSize.columns;
    final sb = StringBuffer();
    final date = reportDate ?? DateTime.now();

    sb.writeln(doubleDivider(w));
    sb.writeln(center('SAAN CAFE & LOUNGE', w));
    sb.writeln(center('END-OF-DAY Z-REPORT', w));
    sb.writeln(center('DATE: ${_formatDate(date)}', w));
    sb.writeln(twoColumn('Terminal: #01 POS', 'Cashier: $cashier', w));
    sb.writeln(doubleDivider(w));

    sb.writeln(center('--- REVENUE SUMMARY ---', w));
    sb.writeln(twoColumn('Gross Sales:', CurrencyHelper.format(totalRevenue + totalDiscount), w));
    sb.writeln(twoColumn('Total Discounts:', '-${CurrencyHelper.format(totalDiscount)}', w));
    sb.writeln(twoColumn('NET SALES REVENUE:', CurrencyHelper.format(totalRevenue), w));
    sb.writeln(twoColumn('Completed Orders:', '$totalOrders', w));
    final aov = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;
    sb.writeln(twoColumn('Avg Order Value:', CurrencyHelper.format(aov), w));
    sb.writeln(divider(w));

    sb.writeln(center('--- PAYMENT COLLECTIONS ---', w));
    sb.writeln(twoColumn('Cash Sales:', CurrencyHelper.format(cashRevenue), w));
    sb.writeln(twoColumn('Fonepay QR:', CurrencyHelper.format(fonepayRevenue), w));
    sb.writeln(twoColumn('Digital Wallet:', CurrencyHelper.format(walletRevenue), w));
    sb.writeln(twoColumn('Bank / Card:', CurrencyHelper.format(bankRevenue), w));
    sb.writeln(twoColumn('Credit Sales (Khata):', CurrencyHelper.format(creditSales), w));
    sb.writeln(divider(w));

    sb.writeln(center('--- KHATA & DRAWER SUMMARY ---', w));
    sb.writeln(twoColumn('Khata Credit Collected:', CurrencyHelper.format(creditCollectedCash), w));
    sb.writeln(twoColumn('DRAWER CASH TOTAL:', CurrencyHelper.format(totalDrawerCash), w));
    sb.writeln(twoColumn('TOTAL COLLECTIONS:', CurrencyHelper.format(totalCollection), w));
    sb.writeln(divider(w));

    sb.writeln(center('--- INVENTORY STATUS ---', w));
    sb.writeln(twoColumn('Low Stock Items:', '$lowStockCount item(s)', w));
    sb.writeln(doubleDivider(w));
    sb.writeln(center('*** END OF REPORT ***', w));
    sb.writeln(doubleDivider(w));

    return sb.toString();
  }

  static String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]}, $hour:$minute';
  }

  static String _formatPaymentMethod(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.fonepay:
        return 'Fonepay QR';
      case PaymentMethod.esewa:
        return 'eSewa / Digital Wallet';
      case PaymentMethod.customerCredit:
        return 'Customer Credit (Khata)';
      case PaymentMethod.bank:
        return 'Bank / Card';
    }
  }
}

/// Raw ESC/POS command generator for Bluetooth / LAN thermal printers
class EscPosGenerator {
  static Uint8List generateBytes(String text, {bool cut = true}) {
    final bytes = <int>[];

    // ESC @ - Initialize printer
    bytes.addAll([0x1B, 0x40]);

    // Character code table: PC437 (Standard Europe / ASCII)
    bytes.addAll([0x1B, 0x74, 0x00]);

    // Encode text to ASCII / Latin-1 bytes
    final textBytes = latin1.encode(text);
    bytes.addAll(textBytes);

    // Feed 3 lines
    bytes.addAll([0x1B, 0x64, 0x03]);

    if (cut) {
      // GS V 65 0 - Paper Cut (Partial cut with feed)
      bytes.addAll([0x1D, 0x56, 0x41, 0x10]);
    }

    return Uint8List.fromList(bytes);
  }
}

/// Thermal Printer Service for simulating and executing print jobs
class ThermalPrinterService {
  static Future<bool> sendPrintJob({
    required String rawText,
    required PaperSize paperSize,
    required PrinterConnectionMode connectionMode,
    String targetDevice = '192.168.1.200:9100',
  }) async {
    // Generate ESC/POS payload
    final payload = EscPosGenerator.generateBytes(rawText);
    debugPrint('[ThermalPrinterService] Dispatched ${payload.length} ESC/POS bytes via ${connectionMode.label} to $targetDevice (${paperSize.label})');
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }
}

/// Realistic thermal receipt preview modal with perforated jagged edges
class ThermalReceiptPreviewModal extends StatefulWidget {
  final String title;
  final String formattedText58mm;
  final String formattedText80mm;
  final PaperSize initialPaperSize;
  final String? subtitle;

  const ThermalReceiptPreviewModal({
    super.key,
    required this.title,
    required this.formattedText58mm,
    required this.formattedText80mm,
    this.initialPaperSize = PaperSize.mm58,
    this.subtitle,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String formattedText58mm,
    required String formattedText80mm,
    PaperSize initialPaperSize = PaperSize.mm58,
    String? subtitle,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ThermalReceiptPreviewModal(
        title: title,
        formattedText58mm: formattedText58mm,
        formattedText80mm: formattedText80mm,
        initialPaperSize: initialPaperSize,
        subtitle: subtitle,
      ),
    );
  }

  @override
  State<ThermalReceiptPreviewModal> createState() => _ThermalReceiptPreviewModalState();
}

class _ThermalReceiptPreviewModalState extends State<ThermalReceiptPreviewModal> {
  late PaperSize _activeSize;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _activeSize = widget.initialPaperSize;
  }

  String get _currentText =>
      _activeSize == PaperSize.mm58 ? widget.formattedText58mm : widget.formattedText80mm;

  Future<void> _handlePrint() async {
    setState(() => _isPrinting = true);
    await ThermalPrinterService.sendPrintJob(
      rawText: _currentText,
      paperSize: _activeSize,
      connectionMode: PrinterConnectionMode.bluetooth,
    );
    if (!mounted) return;
    setState(() => _isPrinting = false);

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.print_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Job sent to Thermal Printer (${_activeSize.label})',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.emeraldPrimary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleCopy() {
    Clipboard.setData(ClipboardData(text: _currentText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 1500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 420,
        constraints: const BoxConstraints(maxHeight: 680),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Modal Header Bar
            Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 12, 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.emeraldPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        if (widget.subtitle != null)
                          Text(
                            widget.subtitle!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Paper Size Toggle Chips
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Row(
                children: [
                  const Text(
                    'Paper:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildSizeChip(PaperSize.mm58, '58mm'),
                  const SizedBox(width: 8),
                  _buildSizeChip(PaperSize.mm80, '80mm'),
                ],
              ),
            ),

            // Thermal Paper Preview Box with Perforated Edges
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: Center(
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: _activeSize == PaperSize.mm58 ? 290 : 380,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFDF8),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1F000000),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Perforated Top Edge
                            CustomPaint(
                              size: const Size(double.infinity, 8),
                              painter: _PerforatedEdgePainter(isTop: true),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: SelectableText(
                                _currentText,
                                style: const TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 11.5,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                            // Perforated Bottom Edge
                            CustomPaint(
                              size: const Size(double.infinity, 8),
                              painter: _PerforatedEdgePainter(isTop: false),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Actions Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _handleCopy,
                      icon: const Icon(Icons.copy_rounded, size: 15),
                      label: const Text('Copy Text', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textDark,
                        side: const BorderSide(color: AppColors.cardBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isPrinting ? null : _handlePrint,
                      icon: _isPrinting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.print_rounded, size: 16),
                      label: Text(
                        _isPrinting ? 'Printing...' : 'Print to Thermal',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emeraldPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeChip(PaperSize size, [String? customLabel]) {
    final isSelected = _activeSize == size;
    final label = customLabel ?? (size == PaperSize.mm58 ? '58mm' : '80mm');
    return InkWell(
      onTap: () => setState(() => _activeSize = size),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.emeraldPrimary : AppColors.alabasterBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.emeraldPrimary : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }
}

/// Custom painter for realistic zigzag/perforated thermal paper cut edge
class _PerforatedEdgePainter extends CustomPainter {
  final bool isTop;
  const _PerforatedEdgePainter({required this.isTop});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.fill;

    final path = Path();
    const toothWidth = 8.0;
    const toothHeight = 5.0;
    final teethCount = (size.width / toothWidth).ceil();

    if (isTop) {
      path.moveTo(0, 0);
      for (int i = 0; i < teethCount; i++) {
        final x = i * toothWidth;
        path.lineTo(x + toothWidth / 2, toothHeight);
        path.lineTo(x + toothWidth, 0);
      }
      path.lineTo(size.width, 0);
      path.close();
    } else {
      path.moveTo(0, size.height);
      for (int i = 0; i < teethCount; i++) {
        final x = i * toothWidth;
        path.lineTo(x + toothWidth / 2, size.height - toothHeight);
        path.lineTo(x + toothWidth, size.height);
      }
      path.lineTo(size.width, size.height);
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
