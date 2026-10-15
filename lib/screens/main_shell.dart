import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../state/app_state_scope.dart';
import 'bills/bills_screen.dart';
import 'take_order/take_order_screen.dart';
import 'take_order/menu_punch_screen.dart';
import 'customers/customers_screen.dart';
import 'analytics/analytics_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _navigateToMenuForTable(String tableName) {
    final appState = AppStateScope.of(context);
    final existingOrder = appState.orders.firstWhere(
      (o) => o.tableName == tableName && o.status.name == 'pending',
      orElse: () => appState.orders.first,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => MenuPunchScreen(
          tableName: tableName,
          existingOrderId: existingOrder.id,
          onOrderCompleted: () {
            setState(() {
              _currentIndex = 0; // Switch to Bills
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      BillsScreen(
        onNavigateToMenuForTable: _navigateToMenuForTable,
      ),
      TakeOrderScreen(
        onOrderCreated: () {
          setState(() {
            _currentIndex = 0; // Switch to Bills tab
          });
        },
      ),
      const CustomersScreen(),
      const AnalyticsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.pureWhite,
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
          boxShadow: [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  label: 'Bills',
                  icon: Icons.receipt_long_rounded,
                  activeIcon: Icons.receipt_long_rounded,
                ),
                _buildNavItem(
                  index: 1,
                  label: 'Take Order',
                  icon: Icons.storefront_outlined,
                  activeIcon: Icons.storefront_rounded,
                ),
                _buildNavItem(
                  index: 2,
                  label: 'Customers',
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                ),
                _buildNavItem(
                  index: 3,
                  label: 'Analytics',
                  icon: Icons.bar_chart_rounded,
                  activeIcon: Icons.bar_chart_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: () => _onTabSelected(index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.emeraldLight.withValues(alpha: 0.7)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 22,
              color:
                  isSelected ? AppColors.emeraldPrimary : AppColors.textMuted,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color:
                    isSelected ? AppColors.emeraldPrimary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
