import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
import '../../state/app_state_scope.dart';
import '../../models/inventory_model.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final lowStockCount = appState.lowStockItemsCount;

    return Scaffold(
      backgroundColor: AppColors.alabasterBg,
      appBar: AppBar(
        backgroundColor: AppColors.emeraldPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stocks & Inventory (BOM)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              lowStockCount > 0
                  ? '$lowStockCount items low on stock'
                  : 'All ingredient levels normal',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFD1FAE5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _showPurchaseSheet(context, appState),
            icon: const Icon(Icons.add_shopping_cart_rounded,
                color: Colors.white, size: 18),
            label: const Text(
              '+ Purchase',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
            tooltip: 'Adjust Stock (±)',
            onPressed: () => _showAdjustSheet(context, appState),
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.amberOrange,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFFA7F3D0),
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            const Tab(
              icon: Icon(Icons.inventory_2_outlined, size: 18),
              text: 'All Stock',
            ),
            Tab(
              icon: const Icon(Icons.warning_amber_rounded, size: 18),
              text: 'Low / Out ($lowStockCount)',
            ),
            const Tab(
              icon: Icon(Icons.menu_book_rounded, size: 18),
              text: 'Recipes (BOM)',
            ),
            const Tab(
              icon: Icon(Icons.history_rounded, size: 18),
              text: 'Stock Log',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllStockTab(appState, showLowOnly: false),
          _buildAllStockTab(appState, showLowOnly: true),
          _buildRecipesTab(appState),
          _buildStockLogTab(appState),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // Tab 1 & 2: Stock List (All or Low Stock Only)
  // ----------------------------------------------------
  Widget _buildAllStockTab(AppState appState, {required bool showLowOnly}) {
    var items = appState.inventoryItems;
    if (showLowOnly) {
      items = items.where((i) => i.isLowStock).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      items = items
          .where((i) =>
              i.name.toLowerCase().contains(q) ||
              i.category.toLowerCase().contains(q))
          .toList();
    }

    return Column(
      children: [
        // Search bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.alabasterBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.search_rounded,
                    color: AppColors.textMuted, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: const InputDecoration(
                      hintText: 'Search stock by name or category...',
                      hintStyle: TextStyle(
                          fontSize: 13, color: AppColors.textMuted),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _searchQuery = ''),
                    child: const Icon(Icons.close_rounded,
                        color: AppColors.textMuted, size: 18),
                  ),
              ],
            ),
          ),
        ),

        // Items count header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                showLowOnly
                    ? 'Items Needing Immediate Reorder'
                    : 'Active Inventory Balances',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                '${items.length} Items',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        showLowOnly
                            ? Icons.check_circle_outline_rounded
                            : Icons.inventory_2_outlined,
                        size: 48,
                        color: showLowOnly
                            ? AppColors.emeraldPrimary
                            : AppColors.textMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        showLowOnly
                            ? 'All stocks are currently above threshold!'
                            : 'No inventory items match your search',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                  itemCount: items.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final item = items[i];
                    return _buildInventoryCard(item, appState);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildInventoryCard(InventoryItem item, AppState appState) {
    final isLow = item.isLowStock;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLow ? const Color(0xFFFECACA) : AppColors.cardBorder,
          width: isLow ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isLow
                  ? const Color(0xFFFEF2F2)
                  : (item.isDirectRetail
                      ? const Color(0xFFEFF6FF)
                      : const Color(0xFFECFDF5)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isLow
                  ? Icons.warning_amber_rounded
                  : (item.isDirectRetail
                      ? Icons.sell_rounded
                      : Icons.kitchen_rounded),
              color: isLow
                  ? const Color(0xFFDC2626)
                  : (item.isDirectRetail
                      ? const Color(0xFF2563EB)
                      : AppColors.emeraldPrimary),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.alabasterBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.unit,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      item.category,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• Min: ${item.minThreshold.toStringAsFixed(0)} ${item.unit}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Current Stock & Badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.currentStock.toStringAsFixed(item.unit == 'pcs' ? 0 : 1)} ${item.unit}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: isLow ? const Color(0xFFDC2626) : AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isLow
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isLow ? 'Low Stock' : 'In Stock',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isLow
                        ? const Color(0xFFDC2626)
                        : AppColors.emeraldDark,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // Tab 3: Recipes & Bill-Of-Materials (BOM)
  // ----------------------------------------------------
  Widget _buildRecipesTab(AppState appState) {
    final boms = appState.recipeBoms;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
      itemCount: boms.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final bom = boms[i];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: ExpansionTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.restaurant_menu_rounded,
                  color: AppColors.emeraldPrimary, size: 20),
            ),
            title: Text(
              bom.menuItemName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            subtitle: Text(
              '${bom.ingredients.length} raw ingredients per portion',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            children: [
              const Divider(height: 1, color: AppColors.cardBorder),
              const SizedBox(height: 10),
              ...bom.ingredients.map((ing) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_right_rounded,
                          size: 20, color: AppColors.emeraldPrimary),
                      Expanded(
                        child: Text(
                          ing.inventoryItemName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.alabasterBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Text(
                          '${ing.quantityRequired.toStringAsFixed(ing.unit == 'pcs' ? 0 : 1)} ${ing.unit}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.emeraldDark,
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
      },
    );
  }

  // ----------------------------------------------------
  // Tab 4: Stock Log Timeline
  // ----------------------------------------------------
  Widget _buildStockLogTab(AppState appState) {
    final logs = appState.stockLogs;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
      itemCount: logs.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final log = logs[i];
        final isPositive = log.changeAmount > 0;

        Color badgeColor = AppColors.emeraldPrimary;
        Color badgeBg = const Color(0xFFECFDF5);
        String typeLabel = 'Purchase';

        if (log.type == StockLogType.saleDeduction) {
          badgeColor = const Color(0xFFDC2626);
          badgeBg = const Color(0xFFFEF2F2);
          typeLabel = 'POS Sale';
        } else if (log.type == StockLogType.adjustmentWastage) {
          badgeColor = AppColors.amberDark;
          badgeBg = const Color(0xFFFEF3C7);
          typeLabel = 'Adjustment';
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.inventoryItemName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (log.note != null && log.note!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          log.note!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _formatTimestamp(log.timestamp),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${isPositive ? '+' : ''}${log.changeAmount.toStringAsFixed(log.unit == 'pcs' ? 0 : 1)} ${log.unit}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: isPositive
                      ? AppColors.emeraldPrimary
                      : const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} Oct, $hour:$minute';
  }

  // ----------------------------------------------------
  // Bottom Sheets: + Purchase Stock & Adjust Stock (±)
  // ----------------------------------------------------
  void _showPurchaseSheet(BuildContext context, AppState appState) {
    String selectedItemId = appState.inventoryItems.first.id;
    final qtyController = TextEditingController();
    final costController = TextEditingController();
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final selectedItem = appState.inventoryItems
                .firstWhere((i) => i.id == selectedItemId);

            return Container(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Restock / Purchase Stock',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Select Item
                  const Text('Select Item',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.alabasterBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedItemId,
                        isExpanded: true,
                        items: appState.inventoryItems.map((item) {
                          return DropdownMenuItem(
                            value: item.id,
                            child: Text(
                              '${item.name} (${item.unit})',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() => selectedItemId = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Quantity
                  Text('Quantity Received (${selectedItem.unit})',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: qtyController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: 'e.g., 50',
                      filled: true,
                      fillColor: AppColors.alabasterBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.cardBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Total Purchase Cost
                  const Text('Total Cost (Optional Rs.)',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: costController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: 'e.g., 1500.00',
                      filled: true,
                      fillColor: AppColors.alabasterBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.cardBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Supplier Note
                  const Text('Supplier / Invoice Note',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      hintText: 'e.g., Himalayan Distributors Invoice #841',
                      filled: true,
                      fillColor: AppColors.alabasterBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.cardBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        final qty = double.tryParse(qtyController.text) ?? 0.0;
                        final cost =
                            double.tryParse(costController.text) ?? 0.0;
                        if (qty > 0) {
                          appState.purchaseStock(
                            inventoryItemId: selectedItemId,
                            quantity: qty,
                            cost: cost,
                            supplierNote: noteController.text.trim().isNotEmpty
                                ? noteController.text.trim()
                                : null,
                          );
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Restocked +$qty ${selectedItem.unit} of ${selectedItem.name}'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppColors.emeraldPrimary,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emeraldPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Confirm Stock Purchase',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAdjustSheet(BuildContext context, AppState appState) {
    String selectedItemId = appState.inventoryItems.first.id;
    final newStockController = TextEditingController();
    String selectedReason = 'Spoilage/Wastage';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final selectedItem = appState.inventoryItems
                .firstWhere((i) => i.id == selectedItemId);

            return Container(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Adjust Stock / Log Wastage (±)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Select Item
                  const Text('Select Item',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.alabasterBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedItemId,
                        isExpanded: true,
                        items: appState.inventoryItems.map((item) {
                          return DropdownMenuItem(
                            value: item.id,
                            child: Text(
                              '${item.name} (${item.unit})',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() => selectedItemId = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Current Balance Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.alabasterBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Current Recorded Balance:',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textMuted)),
                        Text(
                          '${selectedItem.currentStock.toStringAsFixed(1)} ${selectedItem.unit}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // New Physical Count
                  Text('New Actual Count (${selectedItem.unit})',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: newStockController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: 'Enter verified physical count',
                      filled: true,
                      fillColor: AppColors.alabasterBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.cardBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Reason
                  const Text('Reason for Adjustment',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.alabasterBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedReason,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                              value: 'Spoilage/Wastage',
                              child: Text('Spoilage / Wastage')),
                          DropdownMenuItem(
                              value: 'Count discrepancy',
                              child: Text('Count Discrepancy Audit')),
                          DropdownMenuItem(
                              value: 'Breakage',
                              child: Text('Accidental Breakage')),
                          DropdownMenuItem(
                              value: 'Staff tasting',
                              child: Text('Staff Tasting / QC')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() => selectedReason = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        final newStock =
                            double.tryParse(newStockController.text);
                        if (newStock != null && newStock >= 0) {
                          appState.adjustStock(
                            inventoryItemId: selectedItemId,
                            newStock: newStock,
                            reason: selectedReason,
                          );
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Adjusted ${selectedItem.name} to $newStock ${selectedItem.unit}'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppColors.amberDark,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.amberDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Apply Stock Adjustment',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
