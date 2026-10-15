import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
import '../../state/app_state_scope.dart';
import 'table_card.dart';
import 'menu_punch_screen.dart';
import '../inventory/inventory_screen.dart';

class TakeOrderScreen extends StatefulWidget {
  final VoidCallback onOrderCreated;

  const TakeOrderScreen({
    super.key,
    required this.onOrderCreated,
  });

  @override
  State<TakeOrderScreen> createState() => _TakeOrderScreenState();
}

class _TakeOrderScreenState extends State<TakeOrderScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToMenu(String tableName, {String? existingOrderId}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => MenuPunchScreen(
          tableName: tableName,
          existingOrderId: existingOrderId,
          onOrderCompleted: widget.onOrderCreated,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    // Filter tables
    final filteredTables = appState.tables.where((t) {
      if (appState.tableSearchQuery.isNotEmpty) {
        return t.name
            .toLowerCase()
            .contains(appState.tableSearchQuery.toLowerCase());
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.alabasterBg,
      appBar: AppBar(
        backgroundColor: AppColors.pureWhite,
        elevation: 0,
        title: const Text(
          'Manage Orders',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        actions: [
          // Menu Shortcut Pill
          _buildPillButton(
            label: 'Menu',
            icon: Icons.restaurant_menu_rounded,
            onTap: () {
              _navigateToMenu('Takeaway / Walk-in');
            },
          ),
          const SizedBox(width: 8),
          // Stocks Shortcut Pill with low-stock count
          _buildPillButton(
            label: appState.lowStockItemsCount > 0
                ? 'Stocks (${appState.lowStockItemsCount})'
                : 'Stocks',
            icon: Icons.inventory_2_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const InventoryScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.textMuted, size: 22),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tables status refreshed'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(milliseconds: 1000),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search Table Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.pureWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search table or group (e.g., T1, Fancy wala)...',
                  hintStyle:
                      TextStyle(fontSize: 13, color: AppColors.textSubtle),
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 20, color: AppColors.textMuted),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (val) => appState.setTableSearchQuery(val),
              ),
            ),
          ),

          // 2-Column Table Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.95,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filteredTables.length + 1, // +1 for "+ Add Table" card
              itemBuilder: (ctx, idx) {
                if (idx < filteredTables.length) {
                  final table = filteredTables[idx];
                  return TableCard(
                    table: table,
                    onTap: () => _navigateToMenu(table.name),
                    onAddItems: () => _navigateToMenu(
                      table.name,
                      existingOrderId: table.activeOrderId,
                    ),
                  );
                } else {
                  // Final Dashed Border Card: "+ Add Table"
                  return _buildAddTableCard(context, appState);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.textDark),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddTableCard(BuildContext context, AppState appState) {
    return InkWell(
      onTap: () => _showAddTableDialog(context, appState),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.emeraldPrimary.withValues(alpha: 0.5),
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.emeraldLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 24,
                color: AppColors.emeraldPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '+ Add Table',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.emeraldPrimary,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'or custom group tab',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSubtle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTableDialog(BuildContext context, AppState appState) {
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Table / Group Tab'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'e.g., T11, VIP Lounge, Terrace 1',
                labelText: 'Table / Tab Name',
              ),
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
              if (nameCtrl.text.trim().isNotEmpty) {
                appState.addTable(nameCtrl.text.trim());
              }
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emeraldPrimary,
            ),
            child: const Text('Add Table', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
