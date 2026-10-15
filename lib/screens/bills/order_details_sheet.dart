import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../models/menu_item_model.dart';
import '../../models/customer_model.dart';
import '../../state/app_state.dart';
import '../../state/app_state_scope.dart';
import '../../widgets/custom_badges.dart';
import '../../widgets/currency_text.dart';
import '../../core/services/thermal_printer_service.dart';

class OrderDetailsSheet extends StatefulWidget {
  final String orderId;

  const OrderDetailsSheet({
    super.key,
    required this.orderId,
  });

  static Future<void> show(BuildContext context, String orderId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OrderDetailsSheet(orderId: orderId),
    );
  }

  @override
  State<OrderDetailsSheet> createState() => _OrderDetailsSheetState();
}

class _OrderDetailsSheetState extends State<OrderDetailsSheet> {
  late TextEditingController _discountController;
  late TextEditingController _cashGivenController;
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  String? _selectedCustomerId;

  @override
  void initState() {
    super.initState();
    _discountController = TextEditingController();
    _cashGivenController = TextEditingController();
  }

  @override
  void dispose() {
    _discountController.dispose();
    _cashGivenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final order = appState.orders.firstWhere(
      (o) => o.id == widget.orderId,
      orElse: () => OrderModel(
        id: widget.orderId,
        tableName: 'Unknown',
        createdAt: DateTime.now(),
        items: [],
      ),
    );

    // Sync discount controller if preset is set and controller is empty
    if (_discountController.text.isEmpty && order.discountAmount > 0) {
      _discountController.text = order.discountAmount.toStringAsFixed(0);
    }

    // Default customer for credit if not selected
    if (_selectedCustomerId == null && appState.customers.isNotEmpty) {
      // Find customer with matching name if any, e.g. "Raj Shrestha" for "Raj Group"
      final matched = appState.customers.firstWhere(
        (c) =>
            order.tableName.toLowerCase().contains(c.name.toLowerCase()) ||
            c.name.toLowerCase().contains(order.tableName.toLowerCase().split(' ')[0]),
        orElse: () => appState.customers.first,
      );
      _selectedCustomerId = matched.id;
    }

    final double cashGiven = double.tryParse(_cashGivenController.text) ?? 0.0;
    final double returnChange =
        cashGiven > order.payableAmount ? (cashGiven - order.payableAmount) : 0.0;

    final mediaQuery = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: AppColors.emeraldPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Order Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                // PDF button chip
                OutlinedButton.icon(
                  onPressed: () => _openReceiptPreview(context, appState, order),
                  icon: const Icon(Icons.picture_as_pdf_rounded,
                      size: 16, color: AppColors.emeraldPrimary),
                  label: const Text(
                    'PDF',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.emeraldPrimary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.emeraldPrimary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.cardBorder),

          // Scrollable Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 1. Order Metadata Card
                _buildMetadataCard(order),
                const SizedBox(height: 16),

                // 2. Order Items Section
                _buildItemsSection(context, appState, order),
                const SizedBox(height: 18),

                // 3. Discount Section
                _buildDiscountSection(context, appState, order),
                const SizedBox(height: 18),

                // 4. Bill Summary Box
                _buildBillSummaryBox(order),
                const SizedBox(height: 20),

                // 5. Payment Collection Grid (2x2)
                _buildPaymentGrid(),
                const SizedBox(height: 16),

                // 6. Contextual Payment Detail Box (Cash Calculator or Credit Selector)
                if (_selectedMethod == PaymentMethod.cash)
                  _buildCashCalculatorBox(order, returnChange),
                if (_selectedMethod == PaymentMethod.customerCredit)
                  _buildCustomerCreditPicker(appState, order),
                if (_selectedMethod == PaymentMethod.fonepay)
                  _buildFonepayQRBox(order),
                if (_selectedMethod == PaymentMethod.esewa)
                  _buildEsewaBox(order),

                const SizedBox(height: 20),
              ],
            ),
          ),

          // Sticky Bottom Action Row
          _buildStickyBottomActionRow(context, appState, order),
        ],
      ),
    );
  }

  // Metadata Card
  Widget _buildMetadataCard(OrderModel order) {
    final formattedDate =
        '${order.createdAt.day.toString().padLeft(2, '0')} Oct, ${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.alabasterBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '# ${order.id}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              if (order.status == OrderStatus.pending)
                StatusBadge.pending()
              else if (order.status == OrderStatus.completed)
                StatusBadge.completed()
              else
                StatusBadge.cancelled(),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  size: 15, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                'Created at $formattedDate',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.table_restaurant_rounded,
                      size: 16, color: AppColors.emeraldPrimary),
                  const SizedBox(width: 6),
                  Text(
                    'Table : ${order.tableName}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emeraldLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Taken By : ${order.takenByStaff}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.emeraldDark,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Items Section
  Widget _buildItemsSection(
      BuildContext context, AppState appState, OrderModel order) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          // Title Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Text(
                  'Order Items',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${order.totalItemCount} Items',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.emeraldDark,
                    ),
                  ),
                ),
                if (order.hasRemovedItems) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.amberLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Item Removed',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.amberDark,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showOrderAuditHistoryDialog(context, order),
                  icon: const Icon(Icons.history_rounded,
                      size: 15, color: AppColors.textMuted),
                  label: const Text(
                    'History',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.cardBorder),

          // Items Table Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: const [
                Expanded(
                  flex: 5,
                  child: Text(
                    'Item',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      'Qty',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.cardBorder),

          // Items List
          ...order.items.map((lineItem) {
            final isPending = order.status == OrderStatus.pending;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lineItem.item.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          CurrencyHelper.format(lineItem.item.price),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: InkWell(
                        onTap: isPending
                            ? () => _showQuantityAdjustmentDialog(
                                  context,
                                  appState,
                                  order,
                                  lineItem,
                                )
                            : null,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPending
                                ? AppColors.emeraldLight.withValues(alpha: 0.5)
                                : AppColors.alabasterBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isPending
                                  ? AppColors.emeraldPrimary
                                      .withValues(alpha: 0.4)
                                  : AppColors.cardBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${lineItem.quantity}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isPending
                                      ? AppColors.emeraldDark
                                      : AppColors.textDark,
                                ),
                              ),
                              if (isPending) ...[
                                const SizedBox(width: 3),
                                const Icon(Icons.edit_rounded,
                                    size: 11, color: AppColors.emeraldDark),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: CurrencyText(
                        lineItem.totalPrice,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Discount Section
  Widget _buildDiscountSection(
      BuildContext context, AppState appState, OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Discount (Rs.)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(
                width: 100,
                height: 36,
                child: TextField(
                  controller: _discountController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.roseRed,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.emeraldPrimary),
                    ),
                  ),
                  onChanged: (val) {
                    final parsed = double.tryParse(val) ?? 0.0;
                    appState.applyDiscount(
                      order.id,
                      DiscountPreset.custom,
                      customAmount: parsed,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Quick Tap Discount Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDiscountChip(
                  label: 'No Disc',
                  preset: DiscountPreset.none,
                  isSelected: order.discountPreset == DiscountPreset.none &&
                      order.discountAmount == 0,
                  onTap: () {
                    _discountController.clear();
                    appState.applyDiscount(order.id, DiscountPreset.none);
                  },
                ),
                const SizedBox(width: 8),
                _buildDiscountChip(
                  label: '5% Off',
                  preset: DiscountPreset.percent5,
                  isSelected: order.discountPreset == DiscountPreset.percent5,
                  onTap: () {
                    final disc = order.subtotal * 0.05;
                    _discountController.text = disc.toStringAsFixed(0);
                    appState.applyDiscount(order.id, DiscountPreset.percent5);
                  },
                ),
                const SizedBox(width: 8),
                _buildDiscountChip(
                  label: '10% Off',
                  preset: DiscountPreset.percent10,
                  isSelected: order.discountPreset == DiscountPreset.percent10,
                  onTap: () {
                    final disc = order.subtotal * 0.10;
                    _discountController.text = disc.toStringAsFixed(0);
                    appState.applyDiscount(order.id, DiscountPreset.percent10);
                  },
                ),
                const SizedBox(width: 8),
                _buildDiscountChip(
                  label: '- Rs. 20',
                  preset: DiscountPreset.flat20,
                  isSelected: order.discountPreset == DiscountPreset.flat20,
                  onTap: () {
                    _discountController.text = '20';
                    appState.applyDiscount(order.id, DiscountPreset.flat20);
                  },
                ),
                const SizedBox(width: 8),
                _buildDiscountChip(
                  label: '- Rs. 50',
                  preset: DiscountPreset.flat50,
                  isSelected: order.discountPreset == DiscountPreset.flat50,
                  onTap: () {
                    _discountController.text = '50';
                    appState.applyDiscount(order.id, DiscountPreset.flat50);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountChip({
    required String label,
    required DiscountPreset preset,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.roseRed : AppColors.alabasterBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.roseRed : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }

  // Bill Summary Box
  Widget _buildBillSummaryBox(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.alabasterBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              CurrencyText(
                order.subtotal,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Discount',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.roseRed,
                  fontWeight: FontWeight.w500,
                ),
              ),
              CurrencyText(
                order.discountAmount,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.roseRed,
                isNegative: order.discountAmount > 0,
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: AppColors.cardBorder),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payable Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.emeraldPrimary,
                ),
              ),
              CurrencyText(
                order.payableAmount,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.emeraldPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Payment 2x2 Grid
  Widget _buildPaymentGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Payment Method',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildPaymentMethodCard(
                title: 'Cash',
                method: PaymentMethod.cash,
                icon: Icons.payments_rounded,
                iconColor: AppColors.emeraldPrimary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildPaymentMethodCard(
                title: 'Fonepay QR',
                method: PaymentMethod.fonepay,
                icon: Icons.qr_code_2_rounded,
                iconColor: const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildPaymentMethodCard(
                title: 'eSewa / Wallet',
                method: PaymentMethod.esewa,
                icon: Icons.account_balance_wallet_rounded,
                iconColor: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildPaymentMethodCard(
                title: 'Customer Credit',
                method: PaymentMethod.customerCredit,
                icon: Icons.person_pin_rounded,
                iconColor: const Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard({
    required String title,
    required PaymentMethod method,
    required IconData icon,
    required Color iconColor,
  }) {
    final isSelected = _selectedMethod == method;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedMethod = method;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.emeraldLight : AppColors.pureWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.emeraldPrimary : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.emeraldDark : AppColors.textDark,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: AppColors.emeraldPrimary,
              ),
          ],
        ),
      ),
    );
  }

  // Cash Calculator Box
  Widget _buildCashCalculatorBox(OrderModel order, double returnChange) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greenTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.emeraldLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cash Received (Optional)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text(
                        'Return Change: ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.emeraldDark,
                        ),
                      ),
                      CurrencyText(
                        returnChange,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.emeraldPrimary,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(
                width: 120,
                height: 38,
                child: TextField(
                  controller: _cashGivenController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Rs. Given',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.emeraldPrimary),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Quick Cash Given Presets
          Row(
            children: [
              _buildCashPresetChip(
                label: 'Exact',
                amount: order.payableAmount,
              ),
              const SizedBox(width: 8),
              _buildCashPresetChip(
                label: 'Rs. 500',
                amount: 500.0,
              ),
              const SizedBox(width: 8),
              _buildCashPresetChip(
                label: 'Rs. 1000',
                amount: 1000.0,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashPresetChip({required String label, required double amount}) {
    return InkWell(
      onTap: () {
        setState(() {
          _cashGivenController.text = amount.toStringAsFixed(0);
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ),
    );
  }

  // Customer Credit Picker Box
  Widget _buildCustomerCreditPicker(AppState appState, OrderModel order) {
    CustomerModel? selectedCustomer;
    if (_selectedCustomerId != null) {
      selectedCustomer = appState.customers.firstWhere(
        (c) => c.id == _selectedCustomerId,
        orElse: () => appState.customers.first,
      );
    }

    final double projectedDue =
        (selectedCustomer?.totalDue ?? 0.0) + order.payableAmount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.person_pin_rounded,
                  color: Color(0xFF7C3AED), size: 18),
              SizedBox(width: 6),
              Text(
                'Assign to Customer Credit Khata',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5B21B6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCustomerId,
                isExpanded: true,
                hint: const Text('Select Customer'),
                items: appState.customers.map((c) {
                  return DropdownMenuItem<String>(
                    value: c.id,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${c.name} (${c.phone})',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Due: ${CurrencyHelper.format(c.totalDue)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: c.hasDues ? AppColors.roseRed : AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCustomerId = val;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Due: ${CurrencyHelper.format(selectedCustomer?.totalDue ?? 0.0)}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              Row(
                children: [
                  const Text(
                    'New Due: ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.roseRed,
                    ),
                  ),
                  CurrencyText(
                    projectedDue,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.roseRed,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Fonepay QR Box
  Widget _buildFonepayQRBox(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Icon(Icons.qr_code_2_rounded,
                size: 48, color: Color(0xFFDC2626)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fonepay Merchant QR',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF991B1B),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Scan to pay instantly via any Nepali Mobile Banking app',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                const SizedBox(height: 4),
                CurrencyText(
                  order.payableAmount,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFDC2626),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // eSewa Box
  Widget _buildEsewaBox(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF60BB46),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded,
                size: 32, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'eSewa / Digital Wallet',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF065F46),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Collect payment via eSewa / Khalti wallet or phone transfer',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                const SizedBox(height: 4),
                CurrencyText(
                  order.payableAmount,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF065F46),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Sticky Bottom Action Row
  Widget _buildStickyBottomActionRow(
      BuildContext context, AppState appState, OrderModel order) {
    final isPending = order.status == OrderStatus.pending;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.pureWhite,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cancel Order Button (Pending)
          if (isPending) ...[
            Expanded(
              flex: 2,
              child: OutlinedButton(
                onPressed: () {
                  appState.cancelOrder(order.id);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Order ${order.id} cancelled'),
                      backgroundColor: AppColors.roseRed,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.roseRed,
                  side: const BorderSide(color: AppColors.roseRed),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Cancel Order',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ] else ...[
            // Print Bill Button (Completed)
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                onPressed: () => _openReceiptPreview(context, appState, order),
                icon: const Icon(Icons.print_rounded, size: 18),
                label: const Text('Print Bill'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.emeraldPrimary,
                  side: const BorderSide(color: AppColors.emeraldPrimary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Checkout / Done Button
          Expanded(
            flex: 3,
            child: ElevatedButton.icon(
              onPressed: () {
                if (isPending) {
                  final cashGiven =
                      double.tryParse(_cashGivenController.text) ?? 0.0;
                  appState.checkoutOrder(
                    orderId: order.id,
                    method: _selectedMethod,
                    cashGiven: cashGiven,
                    customerId: _selectedMethod == PaymentMethod.customerCredit
                        ? _selectedCustomerId
                        : null,
                  );
                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Payment collected for ${order.tableName} (${CurrencyHelper.format(order.payableAmount)})',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: AppColors.emeraldPrimary,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                } else {
                  Navigator.of(context).pop();
                }
              },
              icon: Icon(
                isPending ? Icons.credit_card_rounded : Icons.check_circle_rounded,
                size: 20,
              ),
              label: Text(
                isPending ? 'Checkout' : 'Done',
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emeraldPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openReceiptPreview(
      BuildContext context, AppState appState, OrderModel order) {
    final cashGiven = double.tryParse(_cashGivenController.text);
    final text58 = ThermalFormatter.formatCustomerReceipt(
      order,
      paperSize: PaperSize.mm58,
      cafeName: appState.tenantName,
      branch: appState.activeBranch,
      serverName: appState.activeStaff,
      cashGiven: cashGiven,
    );
    final text80 = ThermalFormatter.formatCustomerReceipt(
      order,
      paperSize: PaperSize.mm80,
      cafeName: appState.tenantName,
      branch: appState.activeBranch,
      serverName: appState.activeStaff,
      cashGiven: cashGiven,
    );

    ThermalReceiptPreviewModal.show(
      context: context,
      title: 'Customer Receipt / Bill',
      subtitle: '${order.tableName} • ${order.id}',
      formattedText58mm: text58,
      formattedText80mm: text80,
      initialPaperSize: appState.printerPaperSize,
    );
  }

  // Anti-Theft Audit & History Timeline Dialog
  void _showOrderAuditHistoryDialog(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.emeraldLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.history_rounded,
                    color: AppColors.emeraldPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Audit & History',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      '${order.tableName} | ${order.id}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: order.auditLog.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user_outlined,
                            size: 48,
                            color: AppColors.textMuted.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        const Text(
                          'No Changes Recorded',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'All items match original punches. Any modifications or removals will be logged here with timestamps and staff ID.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 380),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: order.auditLog.length,
                      separatorBuilder: (_, _) => const Divider(
                          height: 16, color: AppColors.cardBorder),
                      itemBuilder: (context, index) {
                        final log = order.auditLog[index];
                        final timeStr =
                            '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}';
                        final isRemoved = log.actionDescription
                            .toLowerCase()
                            .contains('removed');
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isRemoved
                                    ? AppColors.roseLight
                                    : AppColors.amberLight,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isRemoved
                                    ? Icons.delete_outline_rounded
                                    : Icons.edit_note_rounded,
                                size: 14,
                                color: isRemoved
                                    ? AppColors.roseRed
                                    : AppColors.amberDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        log.actionDescription,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      Text(
                                        timeStr,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'By ${log.staffName}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  if (log.reason != null &&
                                      log.reason!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.alabasterBg,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                            color: AppColors.cardBorder),
                                      ),
                                      child: Text(
                                        'Reason: ${log.reason}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textDark,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
          ),
          actionsPadding: const EdgeInsets.all(16),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.alabasterBg,
                foregroundColor: AppColors.textDark,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppColors.cardBorder),
                ),
              ),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Interactive Quantity Adjustment Dialog
  void _showQuantityAdjustmentDialog(
    BuildContext context,
    AppState appState,
    OrderModel order,
    OrderLineItem lineItem,
  ) {
    int currentQty = lineItem.quantity;
    String selectedReason = 'Customer changed mind';
    final reasons = [
      'Customer changed mind',
      'Kitchen out of stock',
      'Order mistakenly punched',
      'Mistyped by waiter',
      'Wrong table punched',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_note_rounded,
                        color: AppColors.emeraldPrimary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lineItem.item.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          '${CurrencyHelper.format(lineItem.item.price)} each',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Quantity Stepper
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton.filled(
                          onPressed: currentQty > 0
                              ? () => setDialogState(() => currentQty--)
                              : null,
                          icon: const Icon(Icons.remove, size: 18),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.alabasterBg,
                            foregroundColor: AppColors.textDark,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            '$currentQty',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        IconButton.filled(
                          onPressed: () => setDialogState(() => currentQty++),
                          icon: const Icon(Icons.add, size: 18),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.emeraldLight,
                            foregroundColor: AppColors.emeraldDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Audit reason selector
                    const Text(
                      'Audit Reason / Note:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.alabasterBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedReason,
                          isExpanded: true,
                          items: reasons.map((r) {
                            return DropdownMenuItem(
                              value: r,
                              child:
                                  Text(r, style: const TextStyle(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedReason = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Anti-theft warning
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.amberLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.amberOrange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.security_rounded,
                              size: 16, color: AppColors.amberDark),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Anti-theft audit log will record any quantity modification under Staff "Addy".',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.amberDark,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                TextButton(
                  onPressed: () {
                    appState.removeOrderItem(
                      orderId: order.id,
                      itemId: lineItem.item.id,
                      staffName: 'Addy',
                      reason: selectedReason,
                    );
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Removed ${lineItem.item.name} from bill.'),
                        backgroundColor: AppColors.roseRed,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text(
                    'Remove Item',
                    style: TextStyle(
                        color: AppColors.roseRed, fontWeight: FontWeight.w700),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (currentQty == 0) {
                      appState.removeOrderItem(
                        orderId: order.id,
                        itemId: lineItem.item.id,
                        staffName: 'Addy',
                        reason: selectedReason,
                      );
                    } else {
                      appState.updateOrderItemQuantity(
                        orderId: order.id,
                        itemId: lineItem.item.id,
                        newQuantity: currentQty,
                        staffName: 'Addy',
                        reason: selectedReason,
                      );
                    }
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          currentQty == 0
                              ? 'Removed ${lineItem.item.name}'
                              : 'Updated ${lineItem.item.name} to $currentQty',
                        ),
                        backgroundColor: AppColors.emeraldPrimary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emeraldPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
