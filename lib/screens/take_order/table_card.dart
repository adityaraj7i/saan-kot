import 'package:flutter/material.dart';

import '../../models/table_model.dart';

class TableCard extends StatelessWidget {
  const TableCard({super.key, required this.diningTable, required this.onTap});

  final DiningTable diningTable;
  final VoidCallback onTap;

  Color getHeaderBgColor() {
    final name = diningTable.name.toUpperCase();
    if (name.contains('T1') || name.contains('T5') || name.contains('T9'))
      return const Color(0xFFE3F9E5);
    if (name.contains('T2') || name.contains('T6') || name.contains('T10'))
      return const Color(0xFFFFEFE5);
    if (name.contains('T3') || name.contains('T7'))
      return const Color(0xFFE8F1FF);
    if (name.contains('T4') || name.contains('T8'))
      return const Color(0xFFFDECF0);
    if (name.contains('MASU') || name.contains('FANCY'))
      return const Color(0xFFFEF6DF);
    return const Color(0xFFF3E8FF);
  }

  Color getHeaderTextColor() {
    final name = diningTable.name.toUpperCase();
    if (name.contains('T1') || name.contains('T5') || name.contains('T9'))
      return const Color(0xFF1F9D55);
    if (name.contains('T2') || name.contains('T6') || name.contains('T10'))
      return const Color(0xFFD95D39);
    if (name.contains('T3') || name.contains('T7'))
      return const Color(0xFF3B82F6);
    if (name.contains('T4') || name.contains('T8'))
      return const Color(0xFFE11D48);
    if (name.contains('MASU') || name.contains('FANCY'))
      return const Color(0xFFB45309);
    return const Color(0xFF7E22CE);
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Container(
                height: 38,
                decoration: BoxDecoration(
                  color: getHeaderBgColor(),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  diningTable.name,
                  style: TextStyle(
                    color: getHeaderTextColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: diningTable.orderCount == 0
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              '🛒 0 Order',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 8),
                            Icon(
                              Icons.room_service_outlined,
                              size: 28,
                              color: Color(0xFF94A3B8),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap To Create Order',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '🛒 ${diningTable.orderCount} Order',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rs. ${diningTable.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Color(0xFF26B14C),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
