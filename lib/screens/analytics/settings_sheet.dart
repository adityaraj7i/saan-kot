import 'package:flutter/material.dart';
import '../../core/services/thermal_printer_service.dart';
import '../../models/menu_item_model.dart';
import '../../state/app_state.dart';
import '../../state/app_state_scope.dart';
import '../../theme/app_theme.dart';

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const SettingsSheet(),
    );
  }

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late TextEditingController _deviceAddressController;
  final List<String> _branches = [
    'Kathmandu Main Branch',
    'Lalitpur Branch',
    'Pokhara Lakeside',
  ];

  @override
  void initState() {
    super.initState();
    _deviceAddressController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = AppStateScope.of(context);
    _deviceAddressController.text = appState.printerDeviceAddress;
  }

  @override
  void dispose() {
    _deviceAddressController.dispose();
    super.dispose();
  }

  void _testPrintSampleKot(AppState appState) {
    final sampleKot = KotPrintData(
      kotNumber: 'KOT #1001',
      tableName: 'T1 (Test)',
      serverName: appState.activeStaff,
      timestamp: DateTime.now(),
      items: [
        OrderLineItem(
          item: MenuItem(
            id: 'sample_1',
            name: 'Milk coffee',
            category: 'Coffee',
            price: 55.0,
            code: 'COF-01',
          ),
          quantity: 2,
        ),
        OrderLineItem(
          item: MenuItem(
            id: 'sample_2',
            name: 'C. Chicken Momo - Jhol',
            category: 'Momo & Noodles',
            price: 140.0,
            code: 'MOM-01',
          ),
          quantity: 1,
        ),
      ],
      notes: 'Test print from Settings',
    );

    final text58 = ThermalFormatter.formatKot(sampleKot, paperSize: PaperSize.mm58);
    final text80 = ThermalFormatter.formatKot(sampleKot, paperSize: PaperSize.mm80);

    ThermalReceiptPreviewModal.show(
      context: context,
      title: 'Kitchen Ticket (Test)',
      subtitle: 'Sample KOT Printer Verification',
      formattedText58mm: text58,
      formattedText80mm: text80,
      initialPaperSize: appState.printerPaperSize,
    );
  }

  void _confirmResetBaseline(AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(Icons.restore_rounded, color: AppColors.roseRed, size: 24),
            SizedBox(width: 10),
            Text('Reset to Baseline?'),
          ],
        ),
        content: const Text(
          'This will restore all tables, completed & pending orders, customers, inventory stocks, and analytics metrics to the exact reference cafe baseline data.\n\nAre you sure you want to proceed?',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Close dialog
              appState.resetToBaselineData();
              Navigator.of(context).pop(); // Close settings sheet
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All data successfully restored to reference baseline!'),
                  backgroundColor: AppColors.emeraldPrimary,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.roseRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset Data'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

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
          // Drag Handle
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 10),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.settings_suggest_rounded,
                    color: AppColors.emeraldPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Branch & Printer Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.cardBorder),

          // Scrollable Settings Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                // Section 1: Multi-Tenant Context
                _buildSectionTitle('Multi-Tenant Cafe Context', Icons.business_rounded),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.alabasterBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appState.tenantName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tenant ID: ${appState.tenantId}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.emeraldLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.emeraldDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1, color: AppColors.cardBorder),
                      const SizedBox(height: 14),
                      // Branch Selector
                      Row(
                        children: [
                          const Icon(Icons.storefront_rounded, size: 18, color: AppColors.textMuted),
                          const SizedBox(width: 8),
                          const Text(
                            'Branch:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: appState.activeBranch,
                                  isExpanded: true,
                                  items: _branches.map((b) {
                                    return DropdownMenuItem<String>(
                                      value: b,
                                      child: Text(
                                        b,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      appState.setActiveBranch(val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Active Staff / Cashier:',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                          Text(
                            '${appState.activeStaff} (Admin)',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.emeraldPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Section 2: Thermal Printer Setup
                _buildSectionTitle('Thermal Printer Configuration', Icons.print_rounded),
                const SizedBox(height: 10),
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
                      // Paper Size Selection
                      const Text(
                        'Paper Size Format:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildChoiceChip(
                              label: '58mm (32 Chars)',
                              isSelected: appState.printerPaperSize == PaperSize.mm58,
                              onTap: () => appState.setPrinterPaperSize(PaperSize.mm58),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildChoiceChip(
                              label: '80mm (48 Chars)',
                              isSelected: appState.printerPaperSize == PaperSize.mm80,
                              onTap: () => appState.setPrinterPaperSize(PaperSize.mm80),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Connection Mode Selection
                      const Text(
                        'Printer Connection:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildChoiceChip(
                              label: 'Bluetooth',
                              icon: Icons.bluetooth_rounded,
                              isSelected:
                                  appState.printerConnectionMode == PrinterConnectionMode.bluetooth,
                              onTap: () => appState
                                  .setPrinterConnectionMode(PrinterConnectionMode.bluetooth),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildChoiceChip(
                              label: 'Wi-Fi / LAN IP',
                              icon: Icons.wifi_rounded,
                              isSelected:
                                  appState.printerConnectionMode == PrinterConnectionMode.wifiLan,
                              onTap: () => appState
                                  .setPrinterConnectionMode(PrinterConnectionMode.wifiLan),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // IP / Address field
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _deviceAddressController,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                labelText: appState.printerConnectionMode ==
                                        PrinterConnectionMode.bluetooth
                                    ? 'Bluetooth Device Name / MAC'
                                    : 'Thermal Printer IP:Port',
                                hintText: '192.168.1.200:9100',
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: AppColors.cardBorder),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      const BorderSide(color: AppColors.emeraldPrimary),
                                ),
                              ),
                              onChanged: (val) => appState.setPrinterDeviceAddress(val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Auto cut switch
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Auto-Cut Paper After Ticket:',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          Switch(
                            value: appState.autoCutPaper,
                            activeThumbColor: AppColors.emeraldPrimary,
                            onChanged: (v) => appState.setAutoCutPaper(v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Test Print Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _testPrintSampleKot(appState),
                          icon: const Icon(Icons.print_outlined, size: 18),
                          label: const Text('Test Print Sample KOT'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.emeraldPrimary,
                            side: const BorderSide(color: AppColors.emeraldPrimary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Section 3: Offline Sync & Production Resilience
                _buildSectionTitle('Offline-First Sync Status', Icons.cloud_done_rounded),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.alabasterBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.emeraldPrimary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'All records synced • Offline-First Ready',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.emeraldDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Local queue: 0 pending records • Sync latency: 12ms',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: AppColors.cardBorder),
                      const SizedBox(height: 16),

                      // Reset Demo Data Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _confirmResetBaseline(appState),
                          icon: const Icon(Icons.restart_alt_rounded, size: 18),
                          label: const Text('Reset Demo Data to Baseline'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFEE2E2),
                            foregroundColor: AppColors.roseRed,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.emeraldPrimary),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.emeraldLight : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.emeraldPrimary : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? AppColors.emeraldDark : AppColors.textMuted,
              ),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? AppColors.emeraldDark : AppColors.textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
