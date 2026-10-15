import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../state/app_state.dart';
import '../../state/app_state_scope.dart';
import '../../widgets/currency_text.dart';
import 'order_card.dart';

class BillsScreen extends StatefulWidget {
  final Function(String tableName)? onNavigateToMenuForTable;

  const BillsScreen({
    super.key,
    this.onNavigateToMenuForTable,
  });

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  String _sortBy = 'By Time';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final activeStatus = appState.activeOrderStatusFilter;

    // Filter orders
    var filteredOrders = appState.orders.where((o) {
      if (o.status != activeStatus) return false;
      if (appState.orderSearchQuery.isNotEmpty) {
        final q = appState.orderSearchQuery.toLowerCase();
        final matchesTable = o.tableName.toLowerCase().contains(q);
        final matchesId = o.id.toLowerCase().contains(q);
        final matchesItem =
            o.items.any((l) => l.item.name.toLowerCase().contains(q));
        if (!matchesTable && !matchesId && !matchesItem) return false;
      }
      return true;
    }).toList();

    // Sub-filter for Completed tab (Anti-Theft filters)
    if (activeStatus == OrderStatus.completed) {
      if (appState.activeCompletedFilter == 'Item Removed') {
        filteredOrders =
            filteredOrders.where((o) => o.hasRemovedItems).toList();
      } else if (appState.activeCompletedFilter == 'Item Unserved') {
        filteredOrders =
            filteredOrders.where((o) => o.hasUnservedItems).toList();
      }
    }

    // Sort
    if (_sortBy == 'By Time') {
      filteredOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      filteredOrders.sort((a, b) => b.payableAmount.compareTo(a.payableAmount));
    }

    final pendingCount =
        appState.orders.where((o) => o.status == OrderStatus.pending).length;
    final completedCount =
        appState.orders.where((o) => o.status == OrderStatus.completed).length;
    final cancelledCount =
        appState.orders.where((o) => o.status == OrderStatus.cancelled).length;

    final currentTotal = filteredOrders.fold(
        0.0, (sum, order) => sum + order.payableAmount);

    return Scaffold(
      backgroundColor: AppColors.alabasterBg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Top Emerald Header App Bar with Segmented Bar
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: AppGradients.emeraldHeader,
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        children: [
                          // Top App Bar Row
                          Row(
                            children: [
                              // Date Picker Pill
                              InkWell(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Filter date: 08 Oct selected'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: const [
                                      Icon(Icons.calendar_today_rounded,
                                          size: 14, color: Colors.white),
                                      SizedBox(width: 6),
                                      Text(
                                        '08 Oct',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(width: 2),
                                      Icon(Icons.arrow_drop_down_rounded,
                                          size: 16, color: Colors.white),
                                    ],
                                  ),
                                ),
                              ),
                              const Spacer(),
                              const Text(
                                'Order History',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const Spacer(),
                              // PDF Export
                              IconButton(
                                icon: const Icon(Icons.picture_as_pdf_outlined,
                                    color: Colors.white, size: 22),
                                tooltip: 'Daily Order Register',
                                onPressed: () =>
                                    _showDailyOrderRegisterModal(context, appState),
                              ),
                              // Refresh
                              IconButton(
                                icon: const Icon(Icons.refresh_rounded,
                                    color: Colors.white, size: 22),
                                tooltip: 'Refresh',
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Orders Refreshed!'),
                                      behavior: SnackBarBehavior.floating,
                                      duration: Duration(milliseconds: 1200),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Primary Status Segmented Bar
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              children: [
                                _buildStatusTab(
                                  context: context,
                                  appState: appState,
                                  label: 'Pending',
                                  status: OrderStatus.pending,
                                  count: pendingCount,
                                  isActive: activeStatus == OrderStatus.pending,
                                  activeColor: AppColors.amberOrange,
                                ),
                                _buildStatusTab(
                                  context: context,
                                  appState: appState,
                                  label: 'Completed',
                                  status: OrderStatus.completed,
                                  count: completedCount,
                                  isActive: activeStatus == OrderStatus.completed,
                                  activeColor: Colors.white,
                                  activeTextColor: AppColors.emeraldPrimary,
                                ),
                                _buildStatusTab(
                                  context: context,
                                  appState: appState,
                                  label: 'Cancelled',
                                  status: OrderStatus.cancelled,
                                  count: cancelledCount,
                                  isActive: activeStatus == OrderStatus.cancelled,
                                  activeColor: Colors.white,
                                  activeTextColor: AppColors.roseRed,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Sub-Filters Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                  child: activeStatus == OrderStatus.pending
                      ? _buildPendingSubFilters(appState)
                      : _buildCompletedSubFilters(appState),
                ),
              ),

              // Orders List
              if (filteredOrders.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 56,
                          color: AppColors.textSubtle.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No ${activeStatus.name} orders found',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, idx) {
                        final order = filteredOrders[idx];
                        return OrderCard(
                          order: order,
                          onAddItems: () {
                            if (widget.onNavigateToMenuForTable != null) {
                              widget.onNavigateToMenuForTable!(order.tableName);
                            }
                          },
                        );
                      },
                      childCount: filteredOrders.length,
                    ),
                  ),
                ),
            ],
          ),

          // Floating Total Pill (Bottom-Right)
          Positioned(
            bottom: 20,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showOrdersBreakdownDialog(
                  context,
                  activeStatus,
                  filteredOrders,
                  currentTotal,
                ),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldPrimary,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33059669),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Total: ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      CurrencyText(
                        currentTotal,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.info_outline_rounded,
                          size: 16, color: Colors.white70),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTab({
    required BuildContext context,
    required AppState appState,
    required String label,
    required OrderStatus status,
    required int count,
    required bool isActive,
    required Color activeColor,
    Color activeTextColor = Colors.white,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => appState.setActiveOrderStatusFilter(status),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive ? activeTextColor : Colors.white70,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? (activeTextColor == Colors.white
                          ? Colors.white.withValues(alpha: 0.25)
                          : activeTextColor.withValues(alpha: 0.12))
                      : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isActive ? activeTextColor : Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingSubFilters(AppState appState) {
    return Row(
      children: [
        // Search Input
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search table...',
                hintStyle: TextStyle(fontSize: 13, color: AppColors.textSubtle),
                prefixIcon: Icon(Icons.search_rounded,
                    size: 18, color: AppColors.textMuted),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (val) => appState.setOrderSearchQuery(val),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Sort Dropdown
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.pureWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _sortBy,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 18, color: AppColors.textMuted),
              items: const [
                DropdownMenuItem(
                  value: 'By Time',
                  child: Text(
                    'By Time',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: 'By Amount',
                  child: Text(
                    'By Amount',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _sortBy = val);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedSubFilters(AppState appState) {
    final completedOrders = appState.orders
        .where((o) => o.status == OrderStatus.completed)
        .toList();
    final removedCount =
        completedOrders.where((o) => o.hasRemovedItems).length;
    final unservedCount =
        completedOrders.where((o) => o.hasUnservedItems).length;

    final chips = [
      {'key': 'All', 'label': 'All'},
      {'key': 'Item Removed', 'label': 'Item Removed ($removedCount)'},
      {'key': 'Item Unserved', 'label': 'Item Unserved ($unservedCount)'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips.map((c) {
          final isSelected = appState.activeCompletedFilter == c['key'] ||
              (appState.activeCompletedFilter == 'All' && c['key'] == 'All');
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => appState.setActiveCompletedFilter(c['key']!),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.emeraldPrimary
                      : AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.emeraldPrimary
                        : AppColors.cardBorder,
                  ),
                ),
                child: Text(
                  c['label']!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textDark,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ----------------------------------------------------
  // Daily Order Register Modal
  // ----------------------------------------------------
  void _showDailyOrderRegisterModal(BuildContext context, AppState appState) {
    final pendingOrders =
        appState.orders.where((o) => o.status == OrderStatus.pending).toList();
    final completedOrders =
        appState.orders.where((o) => o.status == OrderStatus.completed).toList();
    final cancelledOrders =
        appState.orders.where((o) => o.status == OrderStatus.cancelled).toList();

    final pendingTotal = pendingOrders.fold(0.0, (sum, o) => sum + o.payableAmount);
    final completedTotal =
        completedOrders.fold(0.0, (sum, o) => sum + o.payableAmount);
    final grossSubtotal =
        completedOrders.fold(0.0, (sum, o) => sum + o.subtotal);
    final totalDiscounts =
        completedOrders.fold(0.0, (sum, o) => sum + o.discountAmount);

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 660),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 14, 12, 12),
                  decoration: const BoxDecoration(
                    gradient: AppGradients.emeraldHeader,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.picture_as_pdf_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Daily Order Register Report',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Saan Cafe & Lounge • 08 Oct 2026',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),

                // Register Metrics Bento Grid
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: [
                      // Pending Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pending (${pendingOrders.length})',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              CurrencyText(
                                pendingTotal,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFB45309),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Completed Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.greenTint,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.emeraldLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Completed (${completedOrders.length})',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.emeraldDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              CurrencyText(
                                completedTotal,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.emeraldPrimary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Discounts Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFECDD3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Discounts',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF9F1239),
                                ),
                              ),
                              const SizedBox(height: 4),
                              CurrencyText(
                                totalDiscounts,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFE11D48),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Register Orders Table
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: const [
                      Expanded(
                        child: Text(
                          'Audit Trail & Orders Log',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      Text(
                        '18 total bills',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: appState.orders.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: AppColors.cardBorder),
                    itemBuilder: (c, idx) {
                      final order = appState.orders[idx];
                      final isPending = order.status == OrderStatus.pending;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isPending
                                    ? const Color(0xFFFEF3C7)
                                    : AppColors.emeraldLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isPending ? 'PENDING' : 'PAID',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: isPending
                                      ? const Color(0xFFB45309)
                                      : AppColors.emeraldDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${order.tableName} • ${order.id}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  Text(
                                    '${order.items.length} items • ${order.takenByStaff}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            CurrencyText(
                              order.payableAmount,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isPending
                                  ? const Color(0xFFB45309)
                                  : AppColors.textDark,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Export / Action Row
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.cardBorder)),
                  ),
                  child: Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          final buffer = StringBuffer();
                          buffer.writeln('=== SAAN CAFE & LOUNGE ===');
                          buffer.writeln('DAILY ORDER REGISTER • 08 OCT 2026');
                          buffer.writeln('Pending Orders: ${CurrencyHelper.format(pendingTotal)} (${pendingOrders.length})');
                          buffer.writeln('Completed Orders: ${CurrencyHelper.format(completedTotal)} (${completedOrders.length})');
                          buffer.writeln('Cancelled Orders: ${cancelledOrders.length}');
                          buffer.writeln('Gross Subtotal: ${CurrencyHelper.format(grossSubtotal)}');
                          buffer.writeln('Total Discounts: ${CurrencyHelper.format(totalDiscounts)}');
                          buffer.writeln('Net Collection: ${CurrencyHelper.format(completedTotal)}');
                          Clipboard.setData(ClipboardData(text: buffer.toString()));

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Daily register summary copied to clipboard!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Copy Register'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textDark,
                          side: const BorderSide(color: AppColors.cardBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emeraldPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ----------------------------------------------------
  // Enhanced Orders Breakdown Dialog (Floating Total Pill)
  // ----------------------------------------------------
  void _showOrdersBreakdownDialog(
    BuildContext context,
    OrderStatus activeStatus,
    List<OrderModel> filteredOrders,
    double currentTotal,
  ) {
    final count = filteredOrders.length;
    final grossSubtotal =
        filteredOrders.fold(0.0, (sum, o) => sum + o.subtotal);
    final discounts =
        filteredOrders.fold(0.0, (sum, o) => sum + o.discountAmount);
    final aov = count > 0 ? (currentTotal / count) : 0.0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              child: const Icon(Icons.analytics_rounded,
                  color: AppColors.emeraldPrimary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Financial Breakdown',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    'Filter: ${activeStatus.name.toUpperCase()} (08 Oct 2026)',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(height: 1, color: AppColors.cardBorder),
            const SizedBox(height: 12),
            _buildBreakdownRow('Total Order Count:', '$count orders', isBold: true),
            const SizedBox(height: 8),
            _buildBreakdownRow('Gross Subtotal:', CurrencyHelper.format(grossSubtotal)),
            const SizedBox(height: 8),
            _buildBreakdownRow('Total Discounts:', '-${CurrencyHelper.format(discounts)}', color: AppColors.roseRed),
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.cardBorder),
            const SizedBox(height: 10),
            _buildBreakdownRow('Net Payable Total:', CurrencyHelper.format(currentTotal), isBold: true, color: AppColors.emeraldPrimary, fontSize: 15),
            const SizedBox(height: 8),
            _buildBreakdownRow('Average Bill Value:', CurrencyHelper.format(aov)),
            const SizedBox(height: 12),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emeraldPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
    double fontSize = 13,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: color ?? AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
