import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
import '../../state/app_state_scope.dart';
import '../../widgets/currency_text.dart';
import '../../core/services/thermal_printer_service.dart';
import '../inventory/inventory_screen.dart';
import 'settings_sheet.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedDateRange = 'Today';

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    // Calculated Dynamic Analytics
    final totalRevenue = appState.totalRevenue;
    final totalDiscount = appState.totalDiscountsGiven;
    final netAmount = totalRevenue; // Reference cafe net amount matches total revenue
    final totalOrders = appState.totalOrdersCount;
    final avgOrderValue = appState.avgOrderValue;

    // Payment Collections
    final cashCol = appState.immediateCashRevenue;
    final fonepayCol = appState.immediateFonepayRevenue;
    final walletCol = appState.immediateWalletRevenue;
    final bankCol = appState.immediateBankRevenue;

    // Credit Analytics
    final creditSales = appState.creditSalesRevenue;
    final creditCollected = appState.creditCollectedCash;
    final creditDiscount = appState.creditDiscountGiven;
    final pastDues = appState.totalPastCreditDues;

    // Credit Collections Breakdown
    final creditCash = appState.creditCollectedCash;
    final creditFonepay = appState.creditCollectedFonepay;
    final creditWallet = appState.creditCollectedWallet;
    final creditBank = appState.creditCollectedBank;
    final staffAdvance = appState.staffCreditAddedToAdvance;

    // Total Collection Summary
    final totalCollection = appState.totalCollectionsToday;
    final totalCash = appState.totalCashCollected;
    final totalFonepay = appState.totalFonepayCollected;
    final totalWallet = appState.totalWalletCollected;
    final totalBank = appState.totalBankCollected;

    // Section 7 Leaderboards
    final topCategories = appState.topCategoriesLeaderboard;
    final topSellings = appState.topSellingItemsLeaderboard;

    return Scaffold(
      backgroundColor: AppColors.alabasterBg,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppGradients.emeraldHeader,
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.picture_as_pdf_outlined,
              color: Colors.white, size: 22),
          tooltip: 'End-of-Day Z-Report',
          onPressed: () => _showZReportModal(context, appState),
        ),
        title: const Text(
          'Analytics Dashboard',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: InkWell(
              onTap: () => SettingsSheet.show(context),
              borderRadius: BorderRadius.circular(16),
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: Text(
                  'A',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.emeraldDark,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        children: [
          // Date Filter Pills (Today, This Week, This Month)
          _buildDateRangeSelector(),
          const SizedBox(height: 14),

          // Inventory & Recipe BOM Shortcut Banner
          _buildInventoryShortcutCard(appState),
          const SizedBox(height: 18),

          // Section 1: Total Revenue (Bento Grid)
          _buildSectionHeader('Revenue Overview', Icons.trending_up_rounded),
          const SizedBox(height: 10),
          _buildRevenueBentoGrid(
            totalRevenue: totalRevenue,
            netAmount: netAmount,
            totalDiscount: totalDiscount,
            totalOrders: totalOrders,
            avgOrderValue: avgOrderValue,
          ),
          const SizedBox(height: 22),

          // Section 2: Payment Collections (2x2 Tinted Grid)
          _buildSectionHeader(
              'Payment Collections', Icons.account_balance_rounded),
          const SizedBox(height: 10),
          _buildPaymentCollectionsGrid(
            cash: cashCol,
            fonepay: fonepayCol,
            wallet: walletCol,
            bank: bankCol,
          ),
          const SizedBox(height: 22),

          // Section 3: Credit Analytics (2x2 Grid with Total Sales badge)
          _buildCreditAnalyticsHeader(context, appState),
          const SizedBox(height: 10),
          _buildCreditAnalyticsGrid(
            context: context,
            appState: appState,
            creditSales: creditSales,
            creditCollected: creditCollected,
            creditDiscount: creditDiscount,
            pastDues: pastDues,
          ),
          const SizedBox(height: 22),

          // Section 4: Credit Collections Breakdown
          _buildSectionHeader(
              'Credit Collections Breakdown', Icons.history_rounded),
          const SizedBox(height: 10),
          _buildCreditCollectionsBreakdown(
            cash: creditCash,
            fonepay: creditFonepay,
            wallet: creditWallet,
            bank: creditBank,
            staffAdvance: staffAdvance,
          ),
          const SizedBox(height: 22),

          // Section 5: Total Collection Summary (Full-width Warm Amber Card + 2x2)
          _buildSectionHeader(
              'Total Collection Summary', Icons.savings_rounded),
          const SizedBox(height: 10),
          _buildTotalCollectionSummary(
            totalCollection: totalCollection,
            cash: totalCash,
            fonepay: totalFonepay,
            wallet: totalWallet,
            bank: totalBank,
          ),
          const SizedBox(height: 22),

          // Section 6: Order Status Summary & Revenue Analysis
          _buildSectionHeader(
              'Order Status Summary', Icons.pie_chart_outline_rounded),
          const SizedBox(height: 10),
          _buildOrderStatusSummary(appState),
          const SizedBox(height: 22),

          // Section 7: Top Categories Leaderboard
          _buildSectionHeader('Top Categories', Icons.category_rounded),
          const SizedBox(height: 10),
          _buildTopCategoriesCard(appState, topCategories),
          const SizedBox(height: 22),

          // Section 7: Top Sellings Leaderboard
          _buildSectionHeader(
              'Top Sellings Leaderboard', Icons.leaderboard_rounded),
          const SizedBox(height: 10),
          _buildTopSellingsCard(appState, topSellings),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.emeraldPrimary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeSelector() {
    final ranges = ['Today', 'This Week', 'This Month'];

    return Row(
      children: ranges.map((r) {
        final isSelected = _selectedDateRange == r;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            onTap: () => setState(() => _selectedDateRange = r),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color:
                    isSelected ? AppColors.emeraldPrimary : AppColors.pureWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.emeraldPrimary
                      : AppColors.cardBorder,
                ),
              ),
              child: Text(
                r,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.textDark,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Inventory Shortcut Card
  Widget _buildInventoryShortcutCard(AppState appState) {
    final lowCount = appState.lowStockItemsCount;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (ctx) => const InventoryScreen()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: lowCount > 0 ? const Color(0xFFFDE68A) : AppColors.cardBorder,
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: lowCount > 0
                    ? const Color(0xFFFEF3C7)
                    : const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.inventory_2_rounded,
                color: lowCount > 0
                    ? AppColors.amberDark
                    : AppColors.emeraldPrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Stocks & Recipe BOM Engine',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lowCount > 0
                        ? '$lowCount ingredient alert: needs restock'
                        : '${appState.inventoryItems.length} active inventory items tracked',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: lowCount > 0
                          ? const Color(0xFFDC2626)
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.emeraldLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: const [
                  Text(
                    'Manage',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.emeraldDark,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 10, color: AppColors.emeraldDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Section 1: Bento Grid
  Widget _buildRevenueBentoGrid({
    required double totalRevenue,
    required double netAmount,
    required double totalDiscount,
    required int totalOrders,
    required double avgOrderValue,
  }) {
    return Column(
      children: [
        // Full-width green-tinted card: Total Amount
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.greenTint,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.emeraldDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  CurrencyText(
                    totalRevenue,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.emeraldDark,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppColors.emeraldPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.currency_exchange_rounded,
                    color: Colors.white, size: 24),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 2x2 Grid: Net Amount, Total Discount, Total Orders, Avg. Order Value
        Row(
          children: [
            Expanded(
              child: _buildBentoCard(
                title: 'Net Amount',
                amount: netAmount,
                bgColor: AppColors.blueTint,
                textColor: AppColors.blueText,
                icon: Icons.account_balance_wallet_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildBentoCard(
                title: 'Total Discount',
                amount: totalDiscount,
                bgColor: AppColors.pinkTint,
                textColor: AppColors.roseRed,
                icon: Icons.local_offer_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildBentoNumberCard(
                title: 'Total Orders',
                value: '$totalOrders',
                bgColor: const Color(0xFFF0FDF4),
                textColor: AppColors.emeraldPrimary,
                icon: Icons.receipt_long_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildBentoCard(
                title: 'Avg. Order Value',
                amount: avgOrderValue,
                bgColor: AppColors.purpleTint,
                textColor: AppColors.purpleText,
                icon: Icons.analytics_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBentoCard({
    required String title,
    required double amount,
    required Color bgColor,
    required Color textColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 16, color: textColor),
            ],
          ),
          const SizedBox(height: 8),
          CurrencyText(
            amount,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildBentoNumberCard({
    required String title,
    required String value,
    required Color bgColor,
    required Color textColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 16, color: textColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // Section 2: Payment Collections (2x2 Tinted Grid)
  Widget _buildPaymentCollectionsGrid({
    required double cash,
    required double fonepay,
    required double wallet,
    required double bank,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildBentoCard(
                title: 'Cash',
                amount: cash,
                bgColor: AppColors.greenTint,
                textColor: AppColors.emeraldPrimary,
                icon: Icons.payments_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildBentoCard(
                title: 'Fonepay',
                amount: fonepay,
                bgColor: const Color(0xFFFEF2F2),
                textColor: const Color(0xFFDC2626),
                icon: Icons.qr_code_2_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildBentoCard(
                title: 'Digital Wallet',
                amount: wallet,
                bgColor: const Color(0xFFECFDF5),
                textColor: const Color(0xFF059669),
                icon: Icons.account_balance_wallet_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildBentoCard(
                title: 'Bank',
                amount: bank,
                bgColor: const Color(0xFFF8FAFC),
                textColor: AppColors.textDark,
                icon: Icons.account_balance_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Section 3: Credit Analytics Header with Total Sales badge
  Widget _buildCreditAnalyticsHeader(BuildContext context, AppState appState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: const [
            Icon(Icons.credit_score_rounded,
                size: 18, color: AppColors.emeraldPrimary),
            SizedBox(width: 8),
            Text(
              'Credit Analytics (Khata)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        InkWell(
          onTap: () => _showCreditBreakdownModal(context, appState),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFCE7F3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFBCFE8)),
            ),
            child: Row(
              children: const [
                Text(
                  'Total Sales (i)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFDB2777),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Section 3: Credit Analytics (2x2 Grid with corner arrows)
  Widget _buildCreditAnalyticsGrid({
    required BuildContext context,
    required AppState appState,
    required double creditSales,
    required double creditCollected,
    required double creditDiscount,
    required double pastDues,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCreditActionCard(
                title: 'Credit Sales',
                amount: creditSales,
                bgColor: const Color(0xFFFEF2F2),
                textColor: const Color(0xFFDC2626),
                onTap: () => appState.setActiveTab('Customers'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildCreditActionCard(
                title: 'Credit Collected',
                amount: creditCollected,
                bgColor: const Color(0xFFECFDF5),
                textColor: AppColors.emeraldPrimary,
                onTap: () => _showCreditBreakdownModal(context, appState),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildCreditActionCard(
                title: 'Credit Discount',
                amount: creditDiscount,
                bgColor: const Color(0xFFF8FAFC),
                textColor: AppColors.textMuted,
                onTap: () => _showCreditBreakdownModal(context, appState),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildCreditActionCard(
                title: 'Past Dues',
                amount: pastDues,
                bgColor: const Color(0xFFFFF1F2),
                textColor: const Color(0xFFBE123C),
                onTap: () => appState.setActiveTab('Customers'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCreditActionCard({
    required String title,
    required double amount,
    required Color bgColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: textColor.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.north_east_rounded, size: 14, color: textColor),
              ],
            ),
            const SizedBox(height: 8),
            CurrencyText(
              amount,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ],
        ),
      ),
    );
  }

  // Section 4: Credit Collections Breakdown
  Widget _buildCreditCollectionsBreakdown({
    required double cash,
    required double fonepay,
    required double wallet,
    required double bank,
    required double staffAdvance,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildBentoCard(
                title: 'Cash',
                amount: cash,
                bgColor: AppColors.pureWhite,
                textColor: AppColors.emeraldPrimary,
                icon: Icons.payments_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildBentoCard(
                title: 'Fonepay',
                amount: fonepay,
                bgColor: AppColors.pureWhite,
                textColor: const Color(0xFFDC2626),
                icon: Icons.qr_code_2_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildBentoCard(
                title: 'Digital Wallet',
                amount: wallet,
                bgColor: AppColors.pureWhite,
                textColor: const Color(0xFF059669),
                icon: Icons.account_balance_wallet_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildBentoCard(
                title: 'Bank',
                amount: bank,
                bgColor: AppColors.pureWhite,
                textColor: AppColors.textDark,
                icon: Icons.account_balance_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Full-width card: Staff Credit Added to Advance
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.badge_rounded,
                      size: 18, color: AppColors.amberDark),
                  SizedBox(width: 8),
                  Text(
                    'Staff Credit Added to Advance',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.amberDark,
                    ),
                  ),
                ],
              ),
              CurrencyText(
                staffAdvance,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.amberDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Section 5: Total Collection Summary (Warm Amber Card + 2x2)
  Widget _buildTotalCollectionSummary({
    required double totalCollection,
    required double cash,
    required double fonepay,
    required double wallet,
    required double bank,
  }) {
    return Column(
      children: [
        // Warm Amber Full-width Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.amberLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Collection',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.amberDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  CurrencyText(
                    totalCollection,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.amberDark,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppColors.amberOrange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.savings_rounded,
                    color: Colors.white, size: 24),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildBentoCard(
                title: 'Cash',
                amount: cash,
                bgColor: AppColors.pureWhite,
                textColor: AppColors.emeraldPrimary,
                icon: Icons.payments_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildBentoCard(
                title: 'Fonepay',
                amount: fonepay,
                bgColor: AppColors.pureWhite,
                textColor: const Color(0xFFDC2626),
                icon: Icons.qr_code_2_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildBentoCard(
                title: 'Digital Wallet',
                amount: wallet,
                bgColor: AppColors.pureWhite,
                textColor: const Color(0xFF059669),
                icon: Icons.account_balance_wallet_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildBentoCard(
                title: 'Bank',
                amount: bank,
                bgColor: AppColors.pureWhite,
                textColor: AppColors.textDark,
                icon: Icons.account_balance_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Section 6: Order Status Summary & Revenue Analysis
  Widget _buildOrderStatusSummary(AppState appState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusPillItem(
                label: 'Completed',
                count: appState.totalCompletedOrdersCount,
                color: AppColors.emeraldPrimary,
                bgColor: const Color(0xFFECFDF5),
              ),
              _buildStatusPillItem(
                label: 'Pending',
                count: appState.totalPendingOrdersCount,
                color: AppColors.amberDark,
                bgColor: const Color(0xFFFEF3C7),
              ),
              _buildStatusPillItem(
                label: 'Cancelled',
                count: appState.totalCancelledOrdersCount,
                color: AppColors.roseRed,
                bgColor: const Color(0xFFFEF2F2),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Date: Oct 08, 2026',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              Row(
                children: [
                  const Text(
                    'Revenue: ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  CurrencyText(
                    appState.totalRevenue,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.emeraldDark,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPillItem({
    required String label,
    required int count,
    required Color color,
    required Color bgColor,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  // Section 7A: Top Categories Leaderboard with Top | Non Toggle
  Widget _buildTopCategoriesCard(
      AppState appState, List<Map<String, dynamic>> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Top Categories',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.alabasterBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    _buildToggleChip(
                      'Top',
                      appState.analyticsCategoriesTopOnly,
                      () => appState.toggleAnalyticsCategoriesTopOnly(true),
                    ),
                    _buildToggleChip(
                      'Non',
                      !appState.analyticsCategoriesTopOnly,
                      () => appState.toggleAnalyticsCategoriesTopOnly(false),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'No categories in this view',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            )
          else
            ...items.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final data = entry.value;
              final cat = data['category'] as String;
              final sold = data['sold'] as int;
              final revenue = data['revenue'] as double;

              Color rankBadgeColor = AppColors.emeraldPrimary;
              if (rank == 1) rankBadgeColor = const Color(0xFFF59E0B);
              if (rank == 2) rankBadgeColor = const Color(0xFF64748B);
              if (rank == 3) rankBadgeColor = const Color(0xFFB45309);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: rankBadgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: rankBadgeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              const Text(
                                'Revenue: ',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              CurrencyText(
                                revenue,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: sold > 0
                            ? AppColors.emeraldLight
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$sold sold',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: sold > 0
                              ? AppColors.emeraldDark
                              : AppColors.textMuted,
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

  // Section 7B: Top Sellings Leaderboard with Top | Non Toggle
  Widget _buildTopSellingsCard(
      AppState appState, List<Map<String, dynamic>> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Top Sellings',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.alabasterBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    _buildToggleChip(
                      'Top',
                      appState.analyticsItemsTopOnly,
                      () => appState.toggleAnalyticsItemsTopOnly(true),
                    ),
                    _buildToggleChip(
                      'Non',
                      !appState.analyticsItemsTopOnly,
                      () => appState.toggleAnalyticsItemsTopOnly(false),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'No menu items in this view',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            )
          else
            ...items.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final data = entry.value;
              final name = data['name'] as String;
              final sold = data['sold'] as int;
              final revenue = data['revenue'] as double;

              Color rankBadgeColor = AppColors.emeraldPrimary;
              if (rank == 1) rankBadgeColor = const Color(0xFFF59E0B);
              if (rank == 2) rankBadgeColor = const Color(0xFF64748B);
              if (rank == 3) rankBadgeColor = const Color(0xFFB45309);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: rankBadgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: rankBadgeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              const Text(
                                'Revenue: ',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              CurrencyText(
                                revenue,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: sold > 0
                            ? AppColors.emeraldLight
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$sold sold',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: sold > 0
                              ? AppColors.emeraldDark
                              : AppColors.textMuted,
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

  Widget _buildToggleChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.emeraldPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  void _showCreditBreakdownModal(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Credit Collections Breakdown',
                  style: TextStyle(
                    fontSize: 16,
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
            const SizedBox(height: 10),
            ListTile(
              dense: true,
              title: const Text('Cash Collections Today'),
              trailing: CurrencyText(
                appState.creditCollectedCash,
                fontWeight: FontWeight.w800,
              ),
            ),
            ListTile(
              dense: true,
              title: const Text('Fonepay Collections Today'),
              trailing: CurrencyText(
                appState.creditCollectedFonepay,
                fontWeight: FontWeight.w800,
              ),
            ),
            ListTile(
              dense: true,
              title: const Text('Staff Advances Logged'),
              trailing: CurrencyText(
                appState.staffCreditAddedToAdvance,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  appState.setActiveTab('Customers');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emeraldPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('View All Customers in Khata ->',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // End-of-Day Z-Report Modal
  // ----------------------------------------------------
  void _showZReportModal(BuildContext context, AppState appState) {
    final text58 = ThermalFormatter.formatZReport(
      totalRevenue: appState.totalRevenue,
      totalDiscount: appState.totalDiscountsGiven,
      totalOrders: appState.totalOrdersCount,
      cashRevenue: appState.immediateCashRevenue,
      fonepayRevenue: appState.immediateFonepayRevenue,
      walletRevenue: appState.immediateWalletRevenue,
      bankRevenue: appState.immediateBankRevenue,
      creditSales: appState.creditSalesRevenue,
      creditCollectedCash: appState.creditCollectedCash,
      totalDrawerCash: appState.totalCashCollected,
      totalCollection: appState.totalCollectionsToday,
      lowStockCount: appState.lowStockItemsCount,
      paperSize: PaperSize.mm58,
      cashier: appState.activeStaff,
    );

    final text80 = ThermalFormatter.formatZReport(
      totalRevenue: appState.totalRevenue,
      totalDiscount: appState.totalDiscountsGiven,
      totalOrders: appState.totalOrdersCount,
      cashRevenue: appState.immediateCashRevenue,
      fonepayRevenue: appState.immediateFonepayRevenue,
      walletRevenue: appState.immediateWalletRevenue,
      bankRevenue: appState.immediateBankRevenue,
      creditSales: appState.creditSalesRevenue,
      creditCollectedCash: appState.creditCollectedCash,
      totalDrawerCash: appState.totalCashCollected,
      totalCollection: appState.totalCollectionsToday,
      lowStockCount: appState.lowStockItemsCount,
      paperSize: PaperSize.mm80,
      cashier: appState.activeStaff,
    );

    ThermalReceiptPreviewModal.show(
      context: context,
      title: 'End-of-Day Z-Report',
      subtitle: '${appState.tenantName} • Terminal #01',
      formattedText58mm: text58,
      formattedText80mm: text80,
      initialPaperSize: PaperSize.mm80,
    );
  }
}
