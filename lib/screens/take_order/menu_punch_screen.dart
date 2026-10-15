import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/menu_item_model.dart';
import '../../state/app_state.dart';
import '../../state/app_state_scope.dart';
import '../../widgets/custom_badges.dart';
import '../../widgets/currency_text.dart';
import '../../core/services/thermal_printer_service.dart';
import '../bills/order_details_sheet.dart';

class MenuPunchScreen extends StatefulWidget {
  final String tableName;
  final String? existingOrderId;
  final VoidCallback onOrderCompleted;

  const MenuPunchScreen({
    super.key,
    required this.tableName,
    this.existingOrderId,
    required this.onOrderCompleted,
  });

  @override
  State<MenuPunchScreen> createState() => _MenuPunchScreenState();
}

class _MenuPunchScreenState extends State<MenuPunchScreen> {
  final Map<String, int> _selectedQuantities = {};
  String _selectedCategory = 'Coffee';
  bool _isGridView = false;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'Coffee',
    'Cold Beverages',
    'Hookah',
    'Premium Hookah',
    'Momo & Noodles',
    'Smoke',
    'Tea',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _totalSelectedCount {
    return _selectedQuantities.values.fold(0, (sum, q) => sum + q);
  }

  double _calculateSubtotal(List<MenuItem> allItems) {
    double total = 0.0;
    _selectedQuantities.forEach((itemId, qty) {
      if (qty > 0) {
        final item = allItems.firstWhere((m) => m.id == itemId);
        total += item.price * qty;
      }
    });
    return total;
  }

  List<OrderLineItem> _buildLineItems(List<MenuItem> allItems) {
    final List<OrderLineItem> result = [];
    _selectedQuantities.forEach((itemId, qty) {
      if (qty > 0) {
        final item = allItems.firstWhere((m) => m.id == itemId);
        result.add(OrderLineItem(item: item, quantity: qty));
      }
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final allMenuItems = appState.menuItems;

    // Filter items by category and search
    final displayedItems = allMenuItems.where((item) {
      if (item.category != _selectedCategory) return false;
      if (_searchController.text.isNotEmpty) {
        return item.name
            .toLowerCase()
            .contains(_searchController.text.toLowerCase());
      }
      return true;
    }).toList();

    final subtotal = _calculateSubtotal(allMenuItems);
    final hasItemsSelected = _totalSelectedCount > 0;

    return Scaffold(
      backgroundColor: AppColors.alabasterBg,
      appBar: AppBar(
        backgroundColor: AppColors.pureWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Restaurant Menu',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            Text(
              'Order for ${widget.tableName}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.emeraldPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
              color: AppColors.textMuted,
            ),
            tooltip: 'Toggle Grid / List',
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          // Add custom menu item button
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: AppColors.emeraldPrimary),
            tooltip: 'Add Custom Item',
            onPressed: () => _showAddCustomItemDialog(context, appState),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Category Bar
          Container(
            color: AppColors.pureWhite,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              children: [
                // Quick Search Bar
                Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.alabasterBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search items in menu...',
                      hintStyle:
                          TextStyle(fontSize: 12, color: AppColors.textSubtle),
                      prefixIcon: Icon(Icons.search_rounded,
                          size: 16, color: AppColors.textMuted),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (v) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 10),

                // Horizontal Category Bar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((category) {
                      final isActive = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.amberOrange
                                  : AppColors.alabasterBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isActive
                                    ? AppColors.amberOrange
                                    : AppColors.cardBorder,
                              ),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isActive ? Colors.white : AppColors.textDark,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.cardBorder),

          // Menu Items List / Grid
          Expanded(
            child: displayedItems.isEmpty
                ? Center(
                    child: Text(
                      'No items found in $_selectedCategory',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  )
                : _isGridView
                    ? GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.95,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: displayedItems.length,
                        itemBuilder: (ctx, idx) {
                          final item = displayedItems[idx];
                          final qty = _selectedQuantities[item.id] ?? 0;
                          return _buildMenuItemGridCard(item, qty);
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        itemCount: displayedItems.length,
                        itemBuilder: (ctx, idx) {
                          final item = displayedItems[idx];
                          final qty = _selectedQuantities[item.id] ?? 0;
                          return _buildMenuItemRow(appState, item, qty);
                        },
                      ),
          ),
        ],
      ),

      // Sticky Bottom KOT Bar (Appears when items > 0)
      bottomSheet: hasItemsSelected
          ? _buildStickyKOTBar(context, appState, allMenuItems, subtotal)
          : null,
    );
  }

  Widget _buildMenuItemGridCard(MenuItem item, int qty) {
    IconData categoryIcon = Icons.local_cafe_rounded;
    if (item.category == 'Cold Beverages') {
      categoryIcon = Icons.local_bar_rounded;
    } else if (item.category == 'Hookah' || item.category == 'Premium Hookah') {
      categoryIcon = Icons.cloud_rounded;
    } else if (item.category == 'Momo & Noodles') {
      categoryIcon = Icons.ramen_dining_rounded;
    } else if (item.category == 'Smoke') {
      categoryIcon = Icons.smoking_rooms_rounded;
    } else if (item.category == 'Tea') {
      categoryIcon = Icons.emoji_food_beverage_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: qty > 0 ? AppColors.emeraldPrimary : AppColors.cardBorder,
          width: qty > 0 ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.alabasterBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(categoryIcon,
                    size: 18, color: AppColors.emeraldPrimary),
              ),
              if (item.isLowStock) StatusBadge.lowStock(item.stockCount),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          CurrencyText(
            item.price,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (qty > 0) ...[
                _buildStepperButton(
                  icon: Icons.remove_rounded,
                  onTap: () {
                    setState(() {
                      _selectedQuantities[item.id] = qty - 1;
                    });
                  },
                ),
                Container(
                  width: 28,
                  alignment: Alignment.center,
                  child: Text(
                    '$qty',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.emeraldPrimary,
                    ),
                  ),
                ),
              ],
              _buildStepperButton(
                icon: Icons.add_rounded,
                isPrimary: true,
                onTap: () {
                  setState(() {
                    _selectedQuantities[item.id] = qty + 1;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemRow(AppState appState, MenuItem item, int qty) {
    IconData categoryIcon = Icons.local_cafe_rounded;
    if (item.category == 'Cold Beverages') {
      categoryIcon = Icons.local_bar_rounded;
    } else if (item.category == 'Hookah' || item.category == 'Premium Hookah') {
      categoryIcon = Icons.cloud_rounded;
    } else if (item.category == 'Momo & Noodles') {
      categoryIcon = Icons.ramen_dining_rounded;
    } else if (item.category == 'Smoke') {
      categoryIcon = Icons.smoking_rooms_rounded;
    } else if (item.category == 'Tea') {
      categoryIcon = Icons.emoji_food_beverage_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: qty > 0 ? AppColors.emeraldPrimary : AppColors.cardBorder,
          width: qty > 0 ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Category Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.alabasterBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(categoryIcon,
                size: 20, color: AppColors.emeraldPrimary),
          ),
          const SizedBox(width: 12),

          // Item Name, Price, Low Stock
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
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () =>
                          _showEditMenuItemDialog(context, appState, item),
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(3.0),
                        child: Icon(Icons.edit_outlined,
                            size: 14, color: AppColors.textSubtle),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    CurrencyText(
                      item.price,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                    if (item.isLowStock) ...[
                      const SizedBox(width: 8),
                      StatusBadge.lowStock(item.stockCount),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Stepper Buttons (-  Qty  +)
          Row(
            children: [
              if (qty > 0) ...[
                _buildStepperButton(
                  icon: Icons.remove_rounded,
                  onTap: () {
                    setState(() {
                      _selectedQuantities[item.id] = qty - 1;
                    });
                  },
                ),
                Container(
                  width: 32,
                  alignment: Alignment.center,
                  child: Text(
                    '$qty',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.emeraldPrimary,
                    ),
                  ),
                ),
              ],
              _buildStepperButton(
                icon: Icons.add_rounded,
                isPrimary: true,
                onTap: () {
                  setState(() {
                    _selectedQuantities[item.id] = qty + 1;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    bool isPrimary = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.emeraldPrimary : AppColors.alabasterBg,
          shape: BoxShape.circle,
          border: isPrimary ? null : Border.all(color: AppColors.cardBorder),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isPrimary ? Colors.white : AppColors.textDark,
        ),
      ),
    );
  }

  // Sticky Bottom KOT Bar
  Widget _buildStickyKOTBar(BuildContext context, AppState appState,
      List<MenuItem> allMenuItems, double subtotal) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: AppColors.pureWhite,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_totalSelectedCount Items',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.emeraldDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Subtotal: ',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CurrencyText(
                    subtotal,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.emeraldPrimary,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Send KOT Button
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final lineItems = _buildLineItems(allMenuItems);
                    if (lineItems.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Select at least 1 item to send KOT'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    final kotData = KotPrintData(
                      kotNumber:
                          'KOT #${DateTime.now().millisecondsSinceEpoch % 10000}',
                      tableName: widget.tableName,
                      serverName: appState.activeStaff,
                      timestamp: DateTime.now(),
                      items: lineItems,
                    );

                    final text58 = ThermalFormatter.formatKot(kotData,
                        paperSize: PaperSize.mm58);
                    final text80 = ThermalFormatter.formatKot(kotData,
                        paperSize: PaperSize.mm80);

                    ThermalReceiptPreviewModal.show(
                      context: context,
                      title: 'Kitchen Order Ticket (KOT)',
                      subtitle: '${widget.tableName} • ${kotData.kotNumber}',
                      formattedText58mm: text58,
                      formattedText80mm: text80,
                      initialPaperSize: appState.printerPaperSize,
                    );
                  },
                  icon: const Icon(Icons.print_outlined, size: 18),
                  label: const Text(
                    'Send KOT',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textDark,
                    side: const BorderSide(color: AppColors.cardBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Save & View Bill
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final lineItems = _buildLineItems(allMenuItems);
                    if (widget.existingOrderId != null) {
                      appState.addItemsToOrder(
                          widget.existingOrderId!, lineItems);
                    } else {
                      final orderId = appState.createOrderForTable(
                        tableName: widget.tableName,
                        items: lineItems,
                      );
                      Navigator.of(context).pop();
                      widget.onOrderCompleted();
                      // Open Order Details sheet
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (context.mounted) {
                          OrderDetailsSheet.show(context, orderId);
                        }
                      });
                      return;
                    }
                    Navigator.of(context).pop();
                    widget.onOrderCompleted();
                  },
                  icon: const Icon(Icons.receipt_rounded, size: 18),
                  label: const Text(
                    'Save & View Bill',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emeraldPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddCustomItemDialog(BuildContext context, AppState appState) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Custom Menu Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Item Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price (Rs.)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(priceCtrl.text) ?? 100.0;
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                final newItem = MenuItem(
                  id: 'm_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  category: _selectedCategory,
                  price: price,
                  code: 'CUST-01',
                );
                appState.menuItems.add(newItem);
                setState(() {});
              }
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emeraldPrimary,
            ),
            child: const Text('Add Item', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditMenuItemDialog(
      BuildContext context, AppState appState, MenuItem item) {
    final nameCtrl = TextEditingController(text: item.name);
    final priceCtrl = TextEditingController(text: item.price.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Item Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price (Rs.)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newPrice = double.tryParse(priceCtrl.text) ?? item.price;
              final newName = nameCtrl.text.trim();
              if (newName.isNotEmpty) {
                final idx =
                    appState.menuItems.indexWhere((m) => m.id == item.id);
                if (idx != -1) {
                  appState.menuItems[idx] = item.copyWith(
                    name: newName,
                    price: newPrice,
                  );
                  setState(() {});
                }
              }
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emeraldPrimary,
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
