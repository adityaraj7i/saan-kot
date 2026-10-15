import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/table_model.dart';
import '../../widgets/currency_text.dart';
import '../bills/order_details_sheet.dart';

class TableCard extends StatelessWidget {
  final TableModel table;
  final VoidCallback onTap;
  final VoidCallback onAddItems;

  const TableCard({
    super.key,
    required this.table,
    required this.onTap,
    required this.onAddItems,
  });

  @override
  Widget build(BuildContext context) {
    if (table.isOccupied) {
      return _buildOccupiedCard(context);
    } else {
      return _buildEmptyCard(context);
    }
  }

  // Occupied Card State
  Widget _buildOccupiedCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (table.activeOrderId != null) {
              OrderDetailsSheet.show(context, table.activeOrderId!);
            } else {
              onTap();
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Highlighted Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  color: AppColors.emeraldLight,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        table.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.emeraldDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.shopping_cart_outlined,
                            size: 13, color: AppColors.emeraldDark),
                        const SizedBox(width: 4),
                        Text(
                          '${table.orderCount} Order',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.emeraldDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Card Body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Running Total
                      CurrencyText(
                        table.runningTotal,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.emeraldPrimary,
                      ),
                      const SizedBox(height: 6),
                      // Elapsed Timer Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.alabasterBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time_filled_rounded,
                                size: 11, color: AppColors.amberDark),
                            const SizedBox(width: 4),
                            Text(
                              '${table.elapsedMinutes}m ago',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 1, color: AppColors.cardBorder),

              // Bottom Quick Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Edit/View Order
                    IconButton(
                      icon: const Icon(Icons.edit_note_rounded,
                          size: 20, color: AppColors.textMuted),
                      tooltip: 'View/Edit Order',
                      onPressed: () {
                        if (table.activeOrderId != null) {
                          OrderDetailsSheet.show(context, table.activeOrderId!);
                        }
                      },
                    ),
                    // Add items
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded,
                          size: 20, color: AppColors.emeraldPrimary),
                      tooltip: 'Add Items',
                      onPressed: onAddItems,
                    ),
                    // Print KOT
                    IconButton(
                      icon: const Icon(Icons.print_outlined,
                          size: 19, color: AppColors.textMuted),
                      tooltip: 'Print KOT',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('KOT Printed for ${table.name}'),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Empty Card State
  Widget _buildEmptyCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Soft Tinted Top Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  color: AppColors.alabasterBg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        table.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: const [
                        Icon(Icons.shopping_cart_outlined,
                            size: 13, color: AppColors.textSubtle),
                        SizedBox(width: 4),
                        Text(
                          '0 Order',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSubtle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Body: Service Cloche Illustration & Prompt
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.alabasterBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.dinner_dining_rounded,
                        size: 28,
                        color: AppColors.textSubtle,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap To Create Order',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.emeraldPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
