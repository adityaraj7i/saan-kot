import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../widgets/currency_text.dart';
import 'order_details_sheet.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onAddItems;

  const OrderCard({
    super.key,
    required this.order,
    required this.onAddItems,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = order.status == OrderStatus.pending;
    final timeStr =
        '${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => OrderDetailsSheet.show(context, order.id),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${order.tableName} | ${order.id}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isPending)
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded,
                            color: AppColors.emeraldPrimary, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Add Items',
                        onPressed: onAddItems,
                      ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded,
                          color: AppColors.textMuted, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Text('View Details'),
                        ),
                        if (isPending)
                          const PopupMenuItem(
                            value: 'print_kot',
                            child: Text('Reprint KOT'),
                          ),
                        if (isPending)
                          const PopupMenuItem(
                            value: 'cancel',
                            child: Text(
                              'Cancel Order',
                              style: TextStyle(color: AppColors.roseRed),
                            ),
                          ),
                      ],
                      onSelected: (val) {
                        if (val == 'view') {
                          OrderDetailsSheet.show(context, order.id);
                        } else if (val == 'print_kot') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('KOT sent to Kitchen Printer for ${order.tableName}'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Body: Clean List of Items
                ...order.items.map((lineItem) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            lineItem.item.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          ' x${lineItem.quantity}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 16),
                        CurrencyText(
                          lineItem.totalPrice,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    ),
                  );
                }),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: AppColors.cardBorder),
                ),

                // Footer Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Total: ',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        CurrencyText(
                          order.payableAmount,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 13, color: AppColors.textSubtle),
                        const SizedBox(width: 4),
                        Text(
                          timeStr,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        if (isPending) ...[
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: () =>
                                OrderDetailsSheet.show(context, order.id),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.emeraldPrimary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    'Checkout',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_rounded,
                                      color: Colors.white, size: 14),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: order.status == OrderStatus.completed
                                  ? AppColors.emeraldLight
                                  : AppColors.roseLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              order.status == OrderStatus.completed
                                  ? (order.paymentMethod ==
                                          PaymentMethod.customerCredit
                                      ? 'Credit'
                                      : 'Paid')
                                  : 'Cancelled',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: order.status == OrderStatus.completed
                                  ? AppColors.emeraldDark
                                  : AppColors.roseRed,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
