import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../models/customer_model.dart';
import '../../models/order_model.dart';
import '../../state/app_state.dart';
import '../../state/app_state_scope.dart';
import '../../widgets/currency_text.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    // Filter customers
    final filteredCustomers = appState.customers.where((c) {
      if (appState.customerSearchQuery.isNotEmpty) {
        final q = appState.customerSearchQuery.toLowerCase();
        return c.name.toLowerCase().contains(q) ||
            c.phone.toLowerCase().contains(q) ||
            c.address.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    final totalDues =
        appState.customers.fold(0.0, (sum, c) => sum + c.totalDue);

    return Scaffold(
      backgroundColor: AppColors.alabasterBg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Top Emerald Header App Bar
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: AppGradients.emeraldHeader,
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Row(
                        children: [
                          const SizedBox(width: 40),
                          const Spacer(),
                          const Text(
                            'My Customers',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded,
                                color: Colors.white, size: 22),
                            tooltip: 'Refresh Dues',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Customer dues refreshed'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(milliseconds: 1000),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Search & Outstanding Credit Banner
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.pureWhite,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    children: [
                      // Search Input
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.alabasterBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search by name, phone, address...',
                            hintStyle: TextStyle(
                                fontSize: 13, color: AppColors.textSubtle),
                            prefixIcon: Icon(Icons.search_rounded,
                                size: 20, color: AppColors.textMuted),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 11),
                          ),
                          onChanged: (val) =>
                              appState.setCustomerSearchQuery(val),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Total Outstanding Dues Banner
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.roseLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFECDD3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.account_balance_wallet_outlined,
                                    size: 18, color: AppColors.roseRed),
                                SizedBox(width: 8),
                                Text(
                                  'Total Outstanding Credit:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF9F1239),
                                  ),
                                ),
                              ],
                            ),
                            CurrencyText(
                              totalDues,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.roseRed,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Customers List
              if (filteredCustomers.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No customers found',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, idx) {
                        final customer = filteredCustomers[idx];
                        return _buildCustomerCard(context, appState, customer);
                      },
                      childCount: filteredCustomers.length,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),

      // Circular Green FAB (+ Add Customer)
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCustomerDialog(context, appState),
        backgroundColor: AppColors.emeraldPrimary,
        tooltip: 'Add New Customer',
        child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
      ),
    );
  }

  Widget _buildCustomerCard(
      BuildContext context, AppState appState, CustomerModel customer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showCustomerKhataSheet(context, appState, customer),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Circular Colored Avatar with Initials
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Color(customer.avatarColorValue),
                  child: Text(
                    customer.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Name & Contact Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              customer.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (customer.isStaff) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: AppColors.emeraldLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Staff',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.emeraldDark,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.phone_rounded,
                              size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            customer.phone,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        customer.address,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSubtle,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Right-aligned Credit Due or No Dues
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (customer.hasDues) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.account_balance_wallet_rounded,
                              size: 13, color: AppColors.roseRed),
                          SizedBox(width: 3),
                          Text(
                            'Total Due',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      CurrencyText(
                        customer.totalDue,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.roseRed,
                      ),
                    ] else ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.credit_card_rounded,
                              size: 13, color: AppColors.emeraldDark),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.emeraldLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'No Dues',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.emeraldDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCustomerKhataSheet(
      BuildContext context, AppState appState, CustomerModel customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CustomerKhataSheet(
        customer: customer,
        appState: appState,
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context, AppState appState) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController(text: 'Kathmandu, Nepal');
    final dueCtrl = TextEditingController();
    bool isStaff = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add New Customer',
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
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Customer Name *',
                      hintText: 'e.g. Raj Shrestha',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number *',
                      hintText: 'e.g. 9841234567',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressCtrl,
                    decoration: InputDecoration(
                      labelText: 'Address',
                      hintText: 'e.g. Thamel, Kathmandu',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dueCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Initial Opening Due (Rs. Optional)',
                      hintText: '0.00',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Staff toggle
                  SwitchListTile(
                    value: isStaff,
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppColors.emeraldPrimary,
                    title: const Text(
                      'Is Staff Member',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    subtitle: const Text(
                      'Enables Staff Credit Advance tracking for salary deductions',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    onChanged: (val) => setModalState(() => isStaff = val),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        final name = nameCtrl.text.trim();
                        final phone = phoneCtrl.text.trim();
                        final initialDue =
                            double.tryParse(dueCtrl.text) ?? 0.0;
                        if (name.isNotEmpty && phone.isNotEmpty) {
                          appState.addCustomer(
                            name: name,
                            phone: phone,
                            address: addressCtrl.text.trim(),
                            initialDue: initialDue,
                            isStaff: isStaff,
                          );
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added customer "$name"'),
                              backgroundColor: AppColors.emeraldPrimary,
                              behavior: SnackBarBehavior.floating,
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
                        'Save Customer',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CustomerKhataSheet extends StatefulWidget {
  final CustomerModel customer;
  final AppState appState;

  const _CustomerKhataSheet({
    required this.customer,
    required this.appState,
  });

  @override
  State<_CustomerKhataSheet> createState() => _CustomerKhataSheetState();
}

class _CustomerKhataSheetState extends State<_CustomerKhataSheet> {
  final TextEditingController _amountReceivedCtrl = TextEditingController();
  final TextEditingController _creditDiscountCtrl = TextEditingController();
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _isStaffAdvance = false;

  @override
  void dispose() {
    _amountReceivedCtrl.dispose();
    _creditDiscountCtrl.dispose();
    super.dispose();
  }

  void _showAddManualDueDialog(
      BuildContext context, AppState appState, CustomerModel customer) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController(text: 'Manual Tab Due');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.add_circle_outline_rounded,
                color: AppColors.roseRed),
            const SizedBox(width: 8),
            Text('Add Due: ${customer.name}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Due Amount (Rs.)',
                hintText: 'e.g. 500',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Note / Reason',
                hintText: 'e.g. Smoke packet / past tab',
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
              final amount = double.tryParse(amountCtrl.text) ?? 0.0;
              if (amount > 0) {
                appState.addManualCustomerDue(
                  customerId: customer.id,
                  amount: amount,
                  note: noteCtrl.text.trim().isEmpty
                      ? 'Manual Tab Due'
                      : noteCtrl.text.trim(),
                );
                Navigator.of(ctx).pop();
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Added ${CurrencyHelper.format(amount)} due for ${customer.name}'),
                    backgroundColor: AppColors.amberDark,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emeraldPrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Due'),
          ),
        ],
      ),
    );
  }

  void _showShareStatementDialog(
      BuildContext context, CustomerModel customer) {
    final buffer = StringBuffer();
    buffer.writeln('=== SAAN CAFE & RESTRO - KHATA STATEMENT ===');
    buffer.writeln('Customer: ${customer.name} (${customer.phone})');
    buffer.writeln('Address: ${customer.address}');
    buffer.writeln('Date: 08 Oct 2026');
    buffer.writeln('--------------------------------------------');
    buffer.writeln('Current Balance Due: ${CurrencyHelper.format(customer.totalDue)}');
    buffer.writeln('--------------------------------------------');
    buffer.writeln('Recent Khata Ledger:');
    if (customer.transactions.isEmpty) {
      buffer.writeln('• No recorded transactions.');
    } else {
      for (final tx in customer.transactions.take(5)) {
        final sign = tx.isPayment ? '-' : '+';
        buffer.writeln(
            '• ${tx.date.day} Oct: ${tx.note} ($sign${CurrencyHelper.format(tx.amount)})');
      }
    }
    buffer.writeln('--------------------------------------------');
    buffer.writeln('Please settle your outstanding due at your convenience.');
    buffer.writeln('Thank you for your business!');

    final statementText = buffer.toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.share_rounded, color: AppColors.emeraldPrimary),
            SizedBox(width: 8),
            Text('Customer Statement',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.alabasterBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: SingleChildScrollView(
            child: Text(
              statementText,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: AppColors.textDark,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: statementText));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Statement copied to clipboard! (Ready for WhatsApp / SMS)'),
                  backgroundColor: AppColors.emeraldPrimary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy Statement'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emeraldPrimary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customer = widget.appState.customers.firstWhere(
      (c) => c.id == widget.customer.id,
      orElse: () => widget.customer,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
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
              width: 44,
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
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Color(customer.avatarColorValue),
                  child: Text(
                    customer.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              customer.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (customer.isStaff) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.emeraldLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Staff Member',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.emeraldDark,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '${customer.phone} • ${customer.address}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
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
                // Total Due Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: customer.hasDues
                        ? AppColors.roseLight
                        : AppColors.emeraldLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: customer.hasDues
                          ? const Color(0xFFFECDD3)
                          : const Color(0xFFA7F3D0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.hasDues
                                ? 'Outstanding Credit Due'
                                : 'Khata Account Status',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: customer.hasDues
                                  ? const Color(0xFF9F1239)
                                  : AppColors.emeraldDark,
                            ),
                          ),
                          if (customer.hasDues)
                            const Text(
                              'Unsettled tab balance',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.textMuted),
                            )
                          else
                            const Text(
                              'All credit cleared',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.emeraldDark),
                            ),
                        ],
                      ),
                      CurrencyText(
                        customer.totalDue,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: customer.hasDues
                            ? AppColors.roseRed
                            : AppColors.emeraldDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Quick Action Buttons (+ Add Due, Share Statement)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showAddManualDueDialog(
                            context, widget.appState, customer),
                        icon: const Icon(Icons.add_circle_outline_rounded,
                            size: 16),
                        label: const Text('Add Due'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.roseRed,
                          side: const BorderSide(color: AppColors.roseRed),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showShareStatementDialog(context, customer),
                        icon: const Icon(Icons.share_rounded, size: 16),
                        label: const Text('Share Statement'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.emeraldPrimary,
                          side: const BorderSide(color: AppColors.emeraldPrimary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Settle Credit Section (Visible when customer has dues)
                if (customer.hasDues) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.alabasterBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Settle Credit / Receive Payment',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Quick Amount Chips
                        Wrap(
                          spacing: 8,
                          children: [
                            ActionChip(
                              label: Text(
                                  'Full Due (${CurrencyHelper.format(customer.totalDue)})'),
                              labelStyle: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w700),
                              backgroundColor: AppColors.emeraldLight,
                              onPressed: () {
                                setState(() {
                                  _amountReceivedCtrl.text =
                                      customer.totalDue.toStringAsFixed(0);
                                  _creditDiscountCtrl.clear();
                                });
                              },
                            ),
                            ActionChip(
                              label: Text(
                                  '50% (${CurrencyHelper.format(customer.totalDue / 2)})'),
                              labelStyle: const TextStyle(fontSize: 11),
                              backgroundColor: AppColors.pureWhite,
                              onPressed: () {
                                setState(() {
                                  _amountReceivedCtrl.text =
                                      (customer.totalDue / 2)
                                          .toStringAsFixed(0);
                                });
                              },
                            ),
                            ActionChip(
                              label: const Text('Clear'),
                              labelStyle: const TextStyle(fontSize: 11),
                              onPressed: () {
                                setState(() {
                                  _amountReceivedCtrl.clear();
                                  _creditDiscountCtrl.clear();
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Amount Received & Credit Discount Inputs
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: _amountReceivedCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Amount Received (Rs.) *',
                                  hintText: customer.totalDue.toStringAsFixed(0),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _creditDiscountCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Discount (Rs.)',
                                  hintText: '0.00',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Payment Collection Method Selector
                        const Text(
                          'Payment Collection Method:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('Cash'),
                              selected: _paymentMethod == PaymentMethod.cash &&
                                  !_isStaffAdvance,
                              onSelected: (val) {
                                if (val) {
                                  setState(() {
                                    _paymentMethod = PaymentMethod.cash;
                                    _isStaffAdvance = false;
                                  });
                                }
                              },
                            ),
                            ChoiceChip(
                              label: const Text('Fonepay'),
                              selected:
                                  _paymentMethod == PaymentMethod.fonepay &&
                                      !_isStaffAdvance,
                              onSelected: (val) {
                                if (val) {
                                  setState(() {
                                    _paymentMethod = PaymentMethod.fonepay;
                                    _isStaffAdvance = false;
                                  });
                                }
                              },
                            ),
                            ChoiceChip(
                              label: const Text('Digital Wallet'),
                              selected: _paymentMethod == PaymentMethod.esewa &&
                                  !_isStaffAdvance,
                              onSelected: (val) {
                                if (val) {
                                  setState(() {
                                    _paymentMethod = PaymentMethod.esewa;
                                    _isStaffAdvance = false;
                                  });
                                }
                              },
                            ),
                            ChoiceChip(
                              label: const Text('Bank'),
                              selected: _paymentMethod == PaymentMethod.bank &&
                                  !_isStaffAdvance,
                              onSelected: (val) {
                                if (val) {
                                  setState(() {
                                    _paymentMethod = PaymentMethod.bank;
                                    _isStaffAdvance = false;
                                  });
                                }
                              },
                            ),
                            if (customer.isStaff)
                              ChoiceChip(
                                label: const Text('Add to Staff Advance'),
                                selected: _isStaffAdvance,
                                selectedColor: AppColors.amberLight,
                                onSelected: (val) {
                                  setState(() => _isStaffAdvance = val);
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Record Settlement Button
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final amount = double.tryParse(
                                      _amountReceivedCtrl.text) ??
                                  customer.totalDue;
                              final discount = double.tryParse(
                                      _creditDiscountCtrl.text) ??
                                  0.0;
                              if (amount > 0 || discount > 0) {
                                widget.appState.settleCustomerCredit(
                                  customerId: customer.id,
                                  amount: amount,
                                  creditDiscount: discount,
                                  method: _paymentMethod,
                                  isStaffAdvance: _isStaffAdvance,
                                );
                                setState(() {
                                  _amountReceivedCtrl.clear();
                                  _creditDiscountCtrl.clear();
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Settlement of ${CurrencyHelper.format(amount)} recorded for ${customer.name}!'),
                                    backgroundColor: AppColors.emeraldPrimary,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.check_circle_rounded,
                                size: 18),
                            label: const Text(
                              'Record Settlement',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.emeraldPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Khata Ledger List Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Khata Ledger & Credit History (${customer.transactions.length})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Transactions List
                if (customer.transactions.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    alignment: Alignment.center,
                    child: const Text(
                      'No recorded transactions yet',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                else
                  ...customer.transactions.reversed.map((tx) {
                    final isPayment = tx.isPayment;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.pureWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isPayment
                                  ? AppColors.emeraldLight
                                  : AppColors.roseLight,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isPayment
                                  ? Icons.arrow_downward_rounded
                                  : Icons.arrow_upward_rounded,
                              color: isPayment
                                  ? AppColors.emeraldDark
                                  : AppColors.roseRed,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx.note,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      '${tx.orderId} • ${tx.date.day} Oct, ${tx.date.hour.toString().padLeft(2, '0')}:${tx.date.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    if (tx.isStaffAdvance) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: AppColors.amberLight,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'Staff Advance',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.amberDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (tx.creditDiscount > 0) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Discount given: ${CurrencyHelper.format(tx.creditDiscount)}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.roseRed,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          CurrencyText(
                            tx.amount,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isPayment
                                ? AppColors.emeraldDark
                                : AppColors.roseRed,
                            isNegative: isPayment,
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
