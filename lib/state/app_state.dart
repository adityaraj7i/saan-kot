import 'package:flutter/material.dart';
import '../models/menu_item_model.dart';
import '../models/table_model.dart';
import '../models/order_model.dart';
import '../models/customer_model.dart';
import '../models/inventory_model.dart';
import '../core/services/thermal_printer_service.dart';

class AppState extends ChangeNotifier {
  // ----------------------------------------------------
  // Mock Data & Collections
  // ----------------------------------------------------
  late List<TableModel> _tables;
  late List<MenuItem> _menuItems;
  late List<OrderModel> _orders;
  late List<CustomerModel> _customers;
  late List<InventoryItem> _inventoryItems;
  late List<RecipeBOM> _recipeBoms;
  late List<StockLogEntry> _stockLogs;

  // Selected state filters
  String _activeTab = 'Bills';
  OrderStatus _activeOrderStatusFilter = OrderStatus.pending;
  String _orderSearchQuery = '';
  String _tableSearchQuery = '';
  String _customerSearchQuery = '';
  String _activeCompletedFilter = 'All'; // All, Item Removed (0), Item Unserved (0)
  String _activeMenuCategory = 'Coffee';
  bool _analyticsTopOnly = true;
  bool _analyticsCategoriesTopOnly = true;
  bool _analyticsItemsTopOnly = true;

  // Incremental sales tracking for dynamic checkouts & analytics
  final Map<String, int> _extraSalesQty = {};
  final Map<String, double> _extraSalesRev = {};
  final Map<String, int> _extraCategoryQty = {};
  final Map<String, double> _extraCategoryRev = {};

  // Financial Tracking Counters (Matching Reference Cafe Baseline)
  double _immediateCashRevenue = 290.0;
  double _immediateFonepayRevenue = 250.0;
  double _immediateWalletRevenue = 0.0;
  double _immediateBankRevenue = 0.0;
  double _creditSalesRevenue = 845.0;

  double _creditCollectedCash = 6820.0;
  double _creditCollectedFonepay = 0.0;
  double _creditCollectedWallet = 0.0;
  double _creditCollectedBank = 0.0;
  double _creditDiscountGiven = 0.0;
  final double _pastDuesCollected = 0.0;
  double _staffCreditAddedToAdvance = 0.0;

  // Multi-Tenant & Thermal Printer Configuration
  final String _tenantId = 'tnt_ktm_001';
  final String _tenantName = 'Saan Cafe & Lounge';
  String _activeBranch = 'Kathmandu Main Branch';
  final String _activeStaff = 'Addy';
  PaperSize _printerPaperSize = PaperSize.mm58;
  PrinterConnectionMode _printerConnectionMode = PrinterConnectionMode.bluetooth;
  String _printerDeviceAddress = '192.168.1.200:9100';
  bool _autoCutPaper = true;

  AppState() {
    _initData();
  }

  // Getters
  List<TableModel> get tables => _tables;
  List<MenuItem> get menuItems => _menuItems;
  List<OrderModel> get orders => _orders;
  List<CustomerModel> get customers => _customers;
  List<InventoryItem> get inventoryItems => _inventoryItems;
  List<RecipeBOM> get recipeBoms => _recipeBoms;
  List<StockLogEntry> get stockLogs => _stockLogs;
  int get lowStockItemsCount =>
      _inventoryItems.where((i) => i.isLowStock).length;

  String get activeTab => _activeTab;
  OrderStatus get activeOrderStatusFilter => _activeOrderStatusFilter;
  String get orderSearchQuery => _orderSearchQuery;
  String get tableSearchQuery => _tableSearchQuery;
  String get customerSearchQuery => _customerSearchQuery;
  String get activeCompletedFilter => _activeCompletedFilter;
  String get activeMenuCategory => _activeMenuCategory;
  bool get analyticsTopOnly => _analyticsTopOnly;
  bool get analyticsCategoriesTopOnly => _analyticsCategoriesTopOnly;
  bool get analyticsItemsTopOnly => _analyticsItemsTopOnly;
  int get totalOrdersCount => _orders.length;
  double get avgOrderValue =>
      totalOrdersCount == 0 ? 0.0 : (totalRevenue / totalOrdersCount);

  // Financial & Collection Getters
  double get immediateCashRevenue => _immediateCashRevenue;
  double get immediateFonepayRevenue => _immediateFonepayRevenue;
  double get immediateWalletRevenue => _immediateWalletRevenue;
  double get immediateBankRevenue => _immediateBankRevenue;
  double get creditSalesRevenue => _creditSalesRevenue;

  double get creditCollectedCash => _creditCollectedCash;
  double get creditCollectedFonepay => _creditCollectedFonepay;
  double get creditCollectedWallet => _creditCollectedWallet;
  double get creditCollectedBank => _creditCollectedBank;
  double get creditDiscountGiven => _creditDiscountGiven;
  double get pastDuesCollected => _pastDuesCollected;
  double get staffCreditAddedToAdvance => _staffCreditAddedToAdvance;

  // Total Collection Summary (Immediate Collections + Credit Collections)
  double get totalCashCollected => _immediateCashRevenue + _creditCollectedCash;
  double get totalFonepayCollected =>
      _immediateFonepayRevenue + _creditCollectedFonepay;
  double get totalWalletCollected =>
      _immediateWalletRevenue + _creditCollectedWallet;
  double get totalBankCollected => _immediateBankRevenue + _creditCollectedBank;
  double get totalCollectionsToday =>
      totalCashCollected +
      totalFonepayCollected +
      totalWalletCollected +
      totalBankCollected;

  void setActiveTab(String tab) {
    _activeTab = tab;
    notifyListeners();
  }

  void setActiveOrderStatusFilter(OrderStatus status) {
    _activeOrderStatusFilter = status;
    notifyListeners();
  }

  void setOrderSearchQuery(String query) {
    _orderSearchQuery = query;
    notifyListeners();
  }

  void setTableSearchQuery(String query) {
    _tableSearchQuery = query;
    notifyListeners();
  }

  void setCustomerSearchQuery(String query) {
    _customerSearchQuery = query;
    notifyListeners();
  }

  void setActiveCompletedFilter(String filter) {
    _activeCompletedFilter = filter;
    notifyListeners();
  }

  void setActiveMenuCategory(String category) {
    _activeMenuCategory = category;
    notifyListeners();
  }

  void toggleAnalyticsTopOnly(bool topOnly) {
    _analyticsTopOnly = topOnly;
    notifyListeners();
  }

  void toggleAnalyticsCategoriesTopOnly(bool topOnly) {
    _analyticsCategoriesTopOnly = topOnly;
    notifyListeners();
  }

  void toggleAnalyticsItemsTopOnly(bool topOnly) {
    _analyticsItemsTopOnly = topOnly;
    notifyListeners();
  }

  // ----------------------------------------------------
  // Initial Mock Data Population
  // ----------------------------------------------------
  void _initData() {
    // Menu items matching realistic Nepali cafe (7 categories)
    _menuItems = [
      // Coffee
      MenuItem(
        id: 'm1',
        name: 'Milk coffee',
        category: 'Coffee',
        price: 55.0,
        code: 'COF-01',
      ),
      MenuItem(
        id: 'm2',
        name: 'Iced americano',
        category: 'Coffee',
        price: 75.0,
        code: 'COF-02',
      ),
      MenuItem(
        id: 'm3',
        name: 'Blackcoffe double',
        category: 'Coffee',
        price: 80.0,
        code: 'COF-03',
      ),
      MenuItem(
        id: 'm4',
        name: 'Black Coffee',
        category: 'Coffee',
        price: 50.0,
        code: 'COF-04',
      ),
      MenuItem(
        id: 'm5',
        name: 'Cafe Latte',
        category: 'Coffee',
        price: 180.0,
        code: 'COF-05',
      ),
      MenuItem(
        id: 'm6',
        name: 'Cappuccino',
        category: 'Coffee',
        price: 190.0,
        isLowStock: true,
        stockCount: 4,
        code: 'COF-06',
      ),
      MenuItem(
        id: 'm7',
        name: 'Americano',
        category: 'Coffee',
        price: 130.0,
        code: 'COF-07',
      ),
      MenuItem(
        id: 'm8',
        name: 'Hot Chocolate',
        category: 'Coffee',
        price: 210.0,
        code: 'COF-08',
      ),
      MenuItem(
        id: 'm9',
        name: 'Espresso Single',
        category: 'Coffee',
        price: 90.0,
        code: 'COF-09',
      ),

      // Cold Beverages
      MenuItem(
        id: 'm10',
        name: 'Cold coffee',
        category: 'Cold Beverages',
        price: 85.0,
        code: 'CLD-01',
      ),
      MenuItem(
        id: 'm11',
        name: 'Water',
        category: 'Cold Beverages',
        price: 20.0,
        code: 'CLD-02',
      ),
      MenuItem(
        id: 'm12',
        name: 'Peach Iced Tea',
        category: 'Cold Beverages',
        price: 180.0,
        code: 'CLD-03',
      ),
      MenuItem(
        id: 'm13',
        name: 'Virgin Mojito',
        category: 'Cold Beverages',
        price: 220.0,
        code: 'CLD-04',
      ),
      MenuItem(
        id: 'm14',
        name: 'Lemon Mint Soda',
        category: 'Cold Beverages',
        price: 125.0,
        code: 'CLD-05',
      ),
      MenuItem(
        id: 'm15',
        name: 'Red Bull Chill',
        category: 'Cold Beverages',
        price: 250.0,
        isLowStock: true,
        stockCount: 2,
        code: 'CLD-06',
      ),
      MenuItem(
        id: 'm16',
        name: 'Blue Ocean Soda',
        category: 'Cold Beverages',
        price: 190.0,
        code: 'CLD-07',
      ),

      // Hookah
      MenuItem(
        id: 'm17',
        name: '1 Normal Hookah',
        category: 'Hookah',
        price: 230.0,
        code: 'HOK-01',
      ),
      MenuItem(
        id: 'm18',
        name: '2 Normal cloud Hookah',
        category: 'Hookah',
        price: 300.0,
        code: 'HOK-02',
      ),
      MenuItem(
        id: 'm19',
        name: 'Normal Cloud Hookah',
        category: 'Hookah',
        price: 650.0,
        code: 'HOK-03',
      ),
      MenuItem(
        id: 'm20',
        name: 'Brain Freezer Hookah',
        category: 'Hookah',
        price: 750.0,
        code: 'HOK-04',
      ),
      MenuItem(
        id: 'm21',
        name: 'Double Apple Al Fakher',
        category: 'Hookah',
        price: 700.0,
        code: 'HOK-05',
      ),
      MenuItem(
        id: 'm22',
        name: 'Mint Blast Hookah',
        category: 'Hookah',
        price: 650.0,
        code: 'HOK-06',
      ),

      // Premium Hookah
      MenuItem(
        id: 'm23',
        name: 'Night Queen Premium',
        category: 'Premium Hookah',
        price: 950.0,
        code: 'PHK-01',
      ),
      MenuItem(
        id: 'm24',
        name: 'Russian Exotica Hookah',
        category: 'Premium Hookah',
        price: 1200.0,
        code: 'PHK-02',
      ),
      MenuItem(
        id: 'm25',
        name: 'Dubai Gold Special',
        category: 'Premium Hookah',
        price: 1100.0,
        code: 'PHK-03',
      ),

      // Momo & Noodles
      MenuItem(
        id: 'm26',
        name: 'C. Chicken Momo - Jhol',
        category: 'Momo & Noodles',
        price: 140.0,
        code: 'MOM-01',
      ),
      MenuItem(
        id: 'm27',
        name: 'Fried Buff Momo',
        category: 'Momo & Noodles',
        price: 240.0,
        code: 'MOM-02',
      ),
      MenuItem(
        id: 'm28',
        name: 'Steam Paneer Momo',
        category: 'Momo & Noodles',
        price: 220.0,
        code: 'MOM-03',
      ),
      MenuItem(
        id: 'm29',
        name: 'Spicy Schezwan Chicken Chowmein',
        category: 'Momo & Noodles',
        price: 260.0,
        code: 'MOM-04',
      ),
      MenuItem(
        id: 'm30',
        name: 'Sadeko Wai Wai',
        category: 'Momo & Noodles',
        price: 120.0,
        code: 'MOM-05',
      ),
      MenuItem(
        id: 'm_keema_noodles',
        name: 'Chiken Keema Noodles',
        category: 'Momo & Noodles',
        price: 167.50,
        code: 'MOM-06',
      ),

      // Smoke
      MenuItem(
        id: 'm31',
        name: 'Shikhar ice',
        category: 'Smoke',
        price: 20.0,
        code: 'SMK-01',
      ),
      MenuItem(
        id: 'm32',
        name: 'Surya Red (Stick)',
        category: 'Smoke',
        price: 25.0,
        code: 'SMK-02',
      ),
      MenuItem(
        id: 'm33',
        name: 'Surya Light (Stick)',
        category: 'Smoke',
        price: 25.0,
        code: 'SMK-03',
      ),
      MenuItem(
        id: 'm34',
        name: 'Marlboro Gold (Stick)',
        category: 'Smoke',
        price: 30.0,
        code: 'SMK-04',
      ),
      MenuItem(
        id: 'm35',
        name: 'Surya Red (Full Pack)',
        category: 'Smoke',
        price: 500.0,
        code: 'SMK-05',
      ),

      // Tea
      MenuItem(
        id: 'm36',
        name: 'Milk',
        category: 'Tea',
        price: 70.0,
        code: 'TEA-01',
      ),
      MenuItem(
        id: 'm37',
        name: 'Regular tea',
        category: 'Tea',
        price: 30.0,
        code: 'TEA-02',
      ),
      MenuItem(
        id: 'm38',
        name: 'Milk Tea (Special Dudh Chiya)',
        category: 'Tea',
        price: 50.0,
        code: 'TEA-03',
      ),
      MenuItem(
        id: 'm39',
        name: 'Black Tea',
        category: 'Tea',
        price: 40.0,
        code: 'TEA-04',
      ),
      MenuItem(
        id: 'm40',
        name: 'Masala Chiya',
        category: 'Tea',
        price: 60.0,
        code: 'TEA-05',
      ),
      MenuItem(
        id: 'm41',
        name: 'Hot Lemon Honey',
        category: 'Tea',
        price: 120.0,
        code: 'TEA-06',
      ),
      MenuItem(
        id: 'm42',
        name: 'Green Tea',
        category: 'Tea',
        price: 80.0,
        code: 'TEA-07',
      ),
      MenuItem(
        id: 'm43',
        name: 'Matka Chiya',
        category: 'Tea',
        price: 70.0,
        code: 'TEA-08',
      ),

      // Chips
      MenuItem(
        id: 'm_chips',
        name: 'Chips',
        category: 'Chips',
        price: 10.0,
        code: 'CHP-01',
      ),
    ];

    // Pre-seeded inventory items (11 items, 3 low stock alerts)
    _inventoryItems = [
      const InventoryItem(
        id: 'inv_surya_red',
        name: 'Surya Red',
        category: 'Direct Retail',
        unit: 'pcs',
        currentStock: 12.0,
        minThreshold: 20.0,
        unitCost: 18.0,
        isDirectRetail: true,
      ),
      const InventoryItem(
        id: 'inv_shikhar',
        name: 'Shikhar ice',
        category: 'Direct Retail',
        unit: 'pcs',
        currentStock: 8.0,
        minThreshold: 15.0,
        unitCost: 15.0,
        isDirectRetail: true,
      ),
      const InventoryItem(
        id: 'inv_water',
        name: 'Water',
        category: 'Direct Retail',
        unit: 'pcs',
        currentStock: 45.0,
        minThreshold: 12.0,
        unitCost: 10.0,
        isDirectRetail: true,
      ),
      const InventoryItem(
        id: 'inv_chips',
        name: 'Chips',
        category: 'Direct Retail',
        unit: 'pcs',
        currentStock: 18.0,
        minThreshold: 10.0,
        unitCost: 6.0,
        isDirectRetail: true,
      ),
      const InventoryItem(
        id: 'inv_coffee_beans',
        name: 'Arabica Coffee Beans',
        category: 'Kitchen Raw Material',
        unit: 'g',
        currentStock: 450.0,
        minThreshold: 500.0,
        unitCost: 1.5,
      ),
      const InventoryItem(
        id: 'inv_milk',
        name: 'Full Cream Milk',
        category: 'Kitchen Raw Material',
        unit: 'ml',
        currentStock: 6500.0,
        minThreshold: 2000.0,
        unitCost: 0.12,
      ),
      const InventoryItem(
        id: 'inv_chicken_momo',
        name: 'Chicken Momo Pcs',
        category: 'Kitchen Raw Material',
        unit: 'pcs',
        currentStock: 120.0,
        minThreshold: 40.0,
        unitCost: 6.0,
      ),
      const InventoryItem(
        id: 'inv_hookah_flavour',
        name: 'Hookah Mint/Cloud Flavour',
        category: 'Bar Raw Material',
        unit: 'g',
        currentStock: 850.0,
        minThreshold: 200.0,
        unitCost: 2.0,
      ),
      const InventoryItem(
        id: 'inv_coal',
        name: 'Coconut Coal',
        category: 'Bar Raw Material',
        unit: 'pcs',
        currentStock: 350.0,
        minThreshold: 100.0,
        unitCost: 5.0,
      ),
      const InventoryItem(
        id: 'inv_tea_leaves',
        name: 'Tea Leaves',
        category: 'Kitchen Raw Material',
        unit: 'g',
        currentStock: 600.0,
        minThreshold: 150.0,
        unitCost: 0.8,
      ),
      const InventoryItem(
        id: 'inv_keema_noodles',
        name: 'Keema Noodles Pack',
        category: 'Kitchen Raw Material',
        unit: 'pcs',
        currentStock: 30.0,
        minThreshold: 10.0,
        unitCost: 40.0,
      ),
    ];

    // Recipe BOM Mappings
    _recipeBoms = [
      const RecipeBOM(
        menuItemId: 'm1',
        menuItemName: 'Milk coffee',
        ingredients: [
          RecipeIngredient(
            inventoryItemId: 'inv_coffee_beans',
            inventoryItemName: 'Arabica Coffee Beans',
            quantityRequired: 15.0,
            unit: 'g',
          ),
          RecipeIngredient(
            inventoryItemId: 'inv_milk',
            inventoryItemName: 'Full Cream Milk',
            quantityRequired: 150.0,
            unit: 'ml',
          ),
        ],
      ),
      const RecipeBOM(
        menuItemId: 'm2',
        menuItemName: 'Iced americano',
        ingredients: [
          RecipeIngredient(
            inventoryItemId: 'inv_coffee_beans',
            inventoryItemName: 'Arabica Coffee Beans',
            quantityRequired: 18.0,
            unit: 'g',
          ),
          RecipeIngredient(
            inventoryItemId: 'inv_water',
            inventoryItemName: 'Water',
            quantityRequired: 1.0,
            unit: 'pcs',
          ),
        ],
      ),
      const RecipeBOM(
        menuItemId: 'm10',
        menuItemName: 'Cold coffee',
        ingredients: [
          RecipeIngredient(
            inventoryItemId: 'inv_coffee_beans',
            inventoryItemName: 'Arabica Coffee Beans',
            quantityRequired: 15.0,
            unit: 'g',
          ),
          RecipeIngredient(
            inventoryItemId: 'inv_milk',
            inventoryItemName: 'Full Cream Milk',
            quantityRequired: 120.0,
            unit: 'ml',
          ),
        ],
      ),
      const RecipeBOM(
        menuItemId: 'm3',
        menuItemName: 'Blackcoffe double',
        ingredients: [
          RecipeIngredient(
            inventoryItemId: 'inv_coffee_beans',
            inventoryItemName: 'Arabica Coffee Beans',
            quantityRequired: 20.0,
            unit: 'g',
          ),
        ],
      ),
      const RecipeBOM(
        menuItemId: 'm4',
        menuItemName: 'Black Coffee',
        ingredients: [
          RecipeIngredient(
            inventoryItemId: 'inv_coffee_beans',
            inventoryItemName: 'Arabica Coffee Beans',
            quantityRequired: 12.0,
            unit: 'g',
          ),
        ],
      ),
      const RecipeBOM(
        menuItemId: 'm36',
        menuItemName: 'Milk',
        ingredients: [
          RecipeIngredient(
            inventoryItemId: 'inv_milk',
            inventoryItemName: 'Full Cream Milk',
            quantityRequired: 200.0,
            unit: 'ml',
          ),
        ],
      ),
      const RecipeBOM(
        menuItemId: 'm26',
        menuItemName: 'C. Chicken Momo - Jhol',
        ingredients: [
          RecipeIngredient(
            inventoryItemId: 'inv_chicken_momo',
            inventoryItemName: 'Chicken Momo Pcs',
            quantityRequired: 10.0,
            unit: 'pcs',
          ),
        ],
      ),
      const RecipeBOM(
        menuItemId: 'm37',
        menuItemName: 'Regular tea',
        ingredients: [
          RecipeIngredient(
            inventoryItemId: 'inv_tea_leaves',
            inventoryItemName: 'Tea Leaves',
            quantityRequired: 5.0,
            unit: 'g',
          ),
          RecipeIngredient(
            inventoryItemId: 'inv_milk',
            inventoryItemName: 'Full Cream Milk',
            quantityRequired: 100.0,
            unit: 'ml',
          ),
        ],
      ),
      const RecipeBOM(
        menuItemId: 'm17',
        menuItemName: '1 Normal Hookah',
        ingredients: [
          RecipeIngredient(
            inventoryItemId: 'inv_hookah_flavour',
            inventoryItemName: 'Hookah Mint/Cloud Flavour',
            quantityRequired: 20.0,
            unit: 'g',
          ),
          RecipeIngredient(
            inventoryItemId: 'inv_coal',
            inventoryItemName: 'Coconut Coal',
            quantityRequired: 3.0,
            unit: 'pcs',
          ),
        ],
      ),
      const RecipeBOM(
        menuItemId: 'm18',
        menuItemName: '2 Normal cloud Hookah',
        ingredients: [
          RecipeIngredient(
            inventoryItemId: 'inv_hookah_flavour',
            inventoryItemName: 'Hookah Mint/Cloud Flavour',
            quantityRequired: 30.0,
            unit: 'g',
          ),
          RecipeIngredient(
            inventoryItemId: 'inv_coal',
            inventoryItemName: 'Coconut Coal',
            quantityRequired: 4.0,
            unit: 'pcs',
          ),
        ],
      ),
      const RecipeBOM(
        menuItemId: 'm32',
        menuItemName: 'Surya Red (Stick)',
        ingredients: [
          RecipeIngredient(
            inventoryItemId: 'inv_surya_red',
            inventoryItemName: 'Surya Red',
            quantityRequired: 1.0,
            unit: 'pcs',
          ),
        ],
      ),
      const RecipeBOM(
        menuItemId: 'm31',
        menuItemName: 'Shikhar ice',
        ingredients: [
          RecipeIngredient(
            inventoryItemId: 'inv_shikhar',
            inventoryItemName: 'Shikhar ice',
            quantityRequired: 1.0,
            unit: 'pcs',
          ),
        ],
      ),
      const RecipeBOM(
        menuItemId: 'm11',
        menuItemName: 'Water',
        ingredients: [
          RecipeIngredient(
            inventoryItemId: 'inv_water',
            inventoryItemName: 'Water',
            quantityRequired: 1.0,
            unit: 'pcs',
          ),
        ],
      ),
      const RecipeBOM(
        menuItemId: 'm_chips',
        menuItemName: 'Chips',
        ingredients: [
          RecipeIngredient(
            inventoryItemId: 'inv_chips',
            inventoryItemName: 'Chips',
            quantityRequired: 1.0,
            unit: 'pcs',
          ),
        ],
      ),
      const RecipeBOM(
        menuItemId: 'm_keema_noodles',
        menuItemName: 'Chiken Keema Noodles',
        ingredients: [
          RecipeIngredient(
            inventoryItemId: 'inv_keema_noodles',
            inventoryItemName: 'Keema Noodles Pack',
            quantityRequired: 1.0,
            unit: 'pcs',
          ),
        ],
      ),
    ];

    // Seed initial stock logs
    _stockLogs = [
      StockLogEntry(
        id: 'log_init_1',
        timestamp: DateTime(2026, 10, 8, 8, 0),
        inventoryItemId: 'inv_coffee_beans',
        inventoryItemName: 'Arabica Coffee Beans',
        changeAmount: 500.0,
        unit: 'g',
        type: StockLogType.purchase,
        note: 'Morning Stock Intake - Himalayan Beans Ltd',
      ),
      StockLogEntry(
        id: 'log_init_2',
        timestamp: DateTime(2026, 10, 8, 8, 15),
        inventoryItemId: 'inv_milk',
        inventoryItemName: 'Full Cream Milk',
        changeAmount: 10000.0,
        unit: 'ml',
        type: StockLogType.purchase,
        note: 'Fresh Morning Dairy Delivery',
      ),
      StockLogEntry(
        id: 'log_init_3',
        timestamp: DateTime(2026, 10, 8, 8, 30),
        inventoryItemId: 'inv_surya_red',
        inventoryItemName: 'Surya Red',
        changeAmount: 50.0,
        unit: 'pcs',
        type: StockLogType.purchase,
        note: 'Distributor Pack Stock-in',
      ),
      StockLogEntry(
        id: 'log_init_4',
        timestamp: DateTime(2026, 10, 8, 9, 0),
        inventoryItemId: 'inv_chicken_momo',
        inventoryItemName: 'Chicken Momo Pcs',
        changeAmount: 150.0,
        unit: 'pcs',
        type: StockLogType.purchase,
        note: 'Kitchen Morning Batch Production',
      ),
    ];

    // Reference cafe customers with exact phone numbers and dues
    _customers = [
      CustomerModel(
        id: 'c_himal',
        name: 'Himal',
        phone: '9846849186',
        address: 'Thamel, Kathmandu',
        totalDue: 4890.0,
        initials: 'H',
        avatarColorValue: 0xFF6D28D9, // Deep Purple
        transactions: [
          CustomerCreditTransaction(
            id: 'tx1',
            date: DateTime(2026, 10, 6, 20, 15),
            orderId: 'ORD-13101',
            amount: 3240.0,
            isPayment: false,
            note: 'Night Hookah & Momo order',
          ),
          CustomerCreditTransaction(
            id: 'tx2',
            date: DateTime(2026, 10, 7, 21, 30),
            orderId: 'ORD-13180',
            amount: 1650.0,
            isPayment: false,
            note: 'Cafe party tab',
          ),
        ],
      ),
      CustomerModel(
        id: 'c_ajaya',
        name: 'Ajaya',
        phone: '9812345678',
        address: 'Patan, Lalitpur',
        totalDue: 0.0,
        initials: 'A',
        avatarColorValue: 0xFFD97706, // Amber
      ),
      CustomerModel(
        id: 'c_bharat_bhanja',
        name: 'Bharat Bhanja',
        phone: '9866234475',
        address: 'Jhamsikhel, Lalitpur',
        totalDue: 0.0,
        initials: 'BB',
        avatarColorValue: 0xFF6366F1, // Indigo
      ),
      CustomerModel(
        id: 'c_bijay',
        name: 'Bijay',
        phone: '9845896631',
        address: 'Baluwatar, Kathmandu',
        totalDue: 0.0,
        initials: 'B',
        avatarColorValue: 0xFF10B981, // Emerald
      ),
      CustomerModel(
        id: 'c_gyalzan',
        name: 'Gyalzan S',
        phone: '9865741236',
        address: 'Lazimpat, Kathmandu',
        totalDue: 0.0,
        initials: 'GS',
        avatarColorValue: 0xFF7C3AED, // Purple
      ),
      CustomerModel(
        id: 'c_jar_wala',
        name: 'Jar Wala',
        phone: '9866556525',
        address: 'Kapan, Kathmandu',
        totalDue: 0.0,
        initials: 'JW',
        avatarColorValue: 0xFFC2410C, // Burnt Orange
      ),
    ];

    MenuItem findItem(String name) =>
        _menuItems.firstWhere((m) => m.name.toLowerCase() == name.toLowerCase(),
            orElse: () => _menuItems.firstWhere((m) => m.name.toLowerCase().contains(name.toLowerCase())));

    // Line items for Fancy wala (ORD-13229) -> Exactly Rs. 505.00
    // 1. Milk coffee (55) + 2. Iced americano (75) + 3. Cold coffee (85) +
    // 4. Blackcoffe double (80) + 5. Milk (70) + 6. C. Chicken Momo - Jhol (140) = 505.00
    final fancyWalaItems = [
      OrderLineItem(item: findItem('Milk coffee'), quantity: 1),       // 55
      OrderLineItem(item: findItem('Iced americano'), quantity: 1),     // 75
      OrderLineItem(item: findItem('Cold coffee'), quantity: 1),        // 85
      OrderLineItem(item: findItem('Blackcoffe double'), quantity: 1),  // 80
      OrderLineItem(item: findItem('Milk'), quantity: 1),               // 70
      OrderLineItem(item: findItem('C. Chicken Momo - Jhol'), quantity: 1), // 140
    ];

    _orders = [
      // -----------------------------------------------------------------
      // PENDING ORDERS (1 active order: Fancy wala ORD-13229 -> Rs. 505.00)
      // -----------------------------------------------------------------
      // Pending 1: Fancy wala (Created at 08 Oct, 16:56, Taken by Addy, Rs. 505.00)
      OrderModel(
        id: 'ORD-13229',
        tableName: 'Fancy wala',
        createdAt: DateTime(2026, 10, 8, 16, 56),
        takenByStaff: 'Addy',
        items: fancyWalaItems,
        status: OrderStatus.pending,
        auditLog: [
          OrderAuditEntry(
            id: 'aud_13229_1',
            timestamp: DateTime(2026, 10, 8, 16, 56),
            staffName: 'Addy',
            actionDescription: 'Order created with 6 items',
            itemName: 'All Items',
            newQty: 6,
          ),
        ],
      ),

      // -----------------------------------------------------------------
      // COMPLETED ORDERS (17 orders totaling exactly Rs. 3070.00)
      // -----------------------------------------------------------------
      // 1. T1 | ORD-13230 (16:59, Rs. 120.00)
      OrderModel(
        id: 'ORD-13230',
        tableName: 'T1',
        createdAt: DateTime(2026, 10, 8, 16, 59),
        takenByStaff: 'Addy',
        items: [
          OrderLineItem(item: findItem('Black Coffee'), quantity: 1), // 50
          OrderLineItem(item: findItem('Milk'), quantity: 1),         // 70
        ],
        status: OrderStatus.completed,
        paymentMethod: PaymentMethod.cash,
        cashGiven: 200.0,
        cashReturn: 80.0,
      ),
      // 2. T1 | ORD-13228 (14:34, Rs. 70.00: Rs. 120 with Rs. 50 discount)
      OrderModel(
        id: 'ORD-13228',
        tableName: 'T1',
        createdAt: DateTime(2026, 10, 8, 14, 34),
        takenByStaff: 'Addy',
        items: [
          OrderLineItem(item: findItem('Black Coffee'), quantity: 1), // 50
          OrderLineItem(item: findItem('Milk'), quantity: 1),         // 70
        ],
        discountAmount: 50.0,
        discountPreset: DiscountPreset.flat50,
        status: OrderStatus.completed,
        paymentMethod: PaymentMethod.fonepay,
      ),
      // 3. Raj Group | ORD-13227 (13:39, Rs. 530.00)
      OrderModel(
        id: 'ORD-13227',
        tableName: 'Raj Group',
        createdAt: DateTime(2026, 10, 8, 13, 39),
        takenByStaff: 'Addy',
        items: [
          OrderLineItem(item: findItem('1 Normal Hookah'), quantity: 1),        // 230
          OrderLineItem(item: findItem('2 Normal cloud Hookah'), quantity: 1),  // 300
        ],
        status: OrderStatus.completed,
        paymentMethod: PaymentMethod.fonepay,
      ),
      // 4. Masu wala | ORD-13226 (05:22, Rs. 205.00)
      OrderModel(
        id: 'ORD-13226',
        tableName: 'Masu wala',
        createdAt: DateTime(2026, 10, 8, 5, 22),
        takenByStaff: 'Addy',
        items: [
          OrderLineItem(item: findItem('Water'), quantity: 2),        // 40
          OrderLineItem(item: findItem('Milk coffee'), quantity: 3),  // 165
        ],
        status: OrderStatus.completed,
        paymentMethod: PaymentMethod.cash,
        cashGiven: 500.0,
        cashReturn: 295.0,
      ),
      // 5. T3 | ORD-13225 (05:21, Rs. 130.00)
      OrderModel(
        id: 'ORD-13225',
        tableName: 'T3',
        createdAt: DateTime(2026, 10, 8, 5, 21),
        takenByStaff: 'Addy',
        items: [
          OrderLineItem(item: findItem('Iced americano'), quantity: 1), // 75
          OrderLineItem(item: findItem('Milk coffee'), quantity: 1),     // 55
        ],
        status: OrderStatus.completed,
        paymentMethod: PaymentMethod.esewa,
      ),
      // 6. T5 | ORD-13211 (17:37, Rs. 0.00: Rs. 90 with 100% discount)
      OrderModel(
        id: 'ORD-13211',
        tableName: 'T5',
        createdAt: DateTime(2026, 10, 8, 17, 37),
        takenByStaff: 'Addy',
        items: [
          OrderLineItem(item: findItem('Regular tea'), quantity: 3), // 90
        ],
        discountAmount: 90.0,
        discountPreset: DiscountPreset.custom,
        status: OrderStatus.completed,
        paymentMethod: PaymentMethod.cash,
      ),
      // 7. T4 | ORD-13210 (17:19, Rs. 70.00)
      OrderModel(
        id: 'ORD-13210',
        tableName: 'T4',
        createdAt: DateTime(2026, 10, 8, 17, 19),
        takenByStaff: 'Addy',
        items: [
          OrderLineItem(item: findItem('Shikhar ice'), quantity: 2),  // 40
          OrderLineItem(item: findItem('Regular tea'), quantity: 1),  // 30
        ],
        status: OrderStatus.completed,
        paymentMethod: PaymentMethod.cash,
        cashGiven: 100.0,
        cashReturn: 30.0,
      ),
      // 8. T2 | ORD-13209 (Rs. 240.00)
      OrderModel(
        id: 'ORD-13209',
        tableName: 'T2',
        createdAt: DateTime(2026, 10, 8, 16, 5),
        takenByStaff: 'Addy',
        items: [
          OrderLineItem(item: findItem('Fried Buff Momo'), quantity: 1), // 240
        ],
        status: OrderStatus.completed,
        paymentMethod: PaymentMethod.cash,
        cashGiven: 300.0,
        cashReturn: 60.0,
      ),
      // 9. Fancy wala | ORD-13208 (Rs. 180.00, hasRemovedItems: true)
      OrderModel(
        id: 'ORD-13208',
        tableName: 'Fancy wala',
        createdAt: DateTime(2026, 10, 8, 15, 40),
        takenByStaff: 'Addy',
        items: [
          OrderLineItem(item: findItem('Cafe Latte'), quantity: 1), // 180
        ],
        hasRemovedItems: true,
        auditLog: [
          OrderAuditEntry(
            id: 'aud_13208',
            timestamp: DateTime(2026, 10, 8, 15, 30),
            staffName: 'Addy',
            actionDescription: 'Removed 1x Cold coffee',
            reason: 'Customer changed mind',
            itemName: 'Cold coffee',
            previousQty: 1,
            newQty: 0,
          ),
        ],
        status: OrderStatus.completed,
        paymentMethod: PaymentMethod.fonepay,
      ),
      // 10. T6 | ORD-13207 (Rs. 220.00)
      OrderModel(
        id: 'ORD-13207',
        tableName: 'T6',
        createdAt: DateTime(2026, 10, 8, 15, 10),
        takenByStaff: 'Addy',
        items: [
          OrderLineItem(item: findItem('Virgin Mojito'), quantity: 1), // 220
        ],
        status: OrderStatus.completed,
        paymentMethod: PaymentMethod.esewa,
      ),
      // 11. Pack | ORD-13206 (Rs. 280.00)
      OrderModel(
        id: 'ORD-13206',
        tableName: 'Pack',
        createdAt: DateTime(2026, 10, 8, 14, 50),
        takenByStaff: 'Addy',
        items: [
          OrderLineItem(item: findItem('C. Chicken Momo - Jhol'), quantity: 2), // 280
        ],
        status: OrderStatus.completed,
        paymentMethod: PaymentMethod.fonepay,
      ),
      // 12. Dipesh Vai | ORD-13205 (Rs. 230.00)
      OrderModel(
        id: 'ORD-13205',
        tableName: 'Dipesh Vai',
        createdAt: DateTime(2026, 10, 8, 14, 15),
        takenByStaff: 'Addy',
        items: [
          OrderLineItem(item: findItem('1 Normal Hookah'), quantity: 1), // 230
        ],
        status: OrderStatus.completed,
        paymentMethod: PaymentMethod.cash,
        cashGiven: 500.0,
        cashReturn: 270.0,
      ),
      // 13. Parlor wala | ORD-13204 (Rs. 190.00, hasRemovedItems: true)
      OrderModel(
        id: 'ORD-13204',
        tableName: 'Parlor wala',
        createdAt: DateTime(2026, 10, 8, 13, 45),
        takenByStaff: 'Addy',
        items: [
          OrderLineItem(item: findItem('Blue Ocean Soda'), quantity: 1), // 190
        ],
        hasRemovedItems: true,
        auditLog: [
          OrderAuditEntry(
            id: 'aud_13204',
            timestamp: DateTime(2026, 10, 8, 13, 35),
            staffName: 'Addy',
            actionDescription: 'Reduced Milk coffee from 2 to 1',
            reason: 'Customer cancelled extra cup',
            itemName: 'Milk coffee',
            previousQty: 2,
            newQty: 1,
          ),
        ],
        status: OrderStatus.completed,
        paymentMethod: PaymentMethod.fonepay,
      ),
      // 14. T7 | ORD-13203 (Rs. 160.00)
      OrderModel(
        id: 'ORD-13203',
        tableName: 'T7',
        createdAt: DateTime(2026, 10, 8, 13, 0),
        takenByStaff: 'Addy',
        items: [
          OrderLineItem(item: findItem('Milk coffee'), quantity: 2),  // 110
          OrderLineItem(item: findItem('Black Coffee'), quantity: 1), // 50
        ],
        status: OrderStatus.completed,
        paymentMethod: PaymentMethod.cash,
        cashGiven: 200.0,
        cashReturn: 40.0,
      ),
      // 15. T8 | ORD-13202 (Rs. 150.00, hasUnservedItems: true)
      OrderModel(
        id: 'ORD-13202',
        tableName: 'T8',
        createdAt: DateTime(2026, 10, 8, 12, 30),
        takenByStaff: 'Addy',
        items: [
          OrderLineItem(item: findItem('Water'), quantity: 1),         // 20
          OrderLineItem(item: findItem('Iced americano'), quantity: 1), // 75
          OrderLineItem(item: findItem('Milk coffee'), quantity: 1),    // 55
        ],
        hasUnservedItems: true,
        status: OrderStatus.completed,
        paymentMethod: PaymentMethod.bank,
      ),
      // 16. T9 | ORD-13201 (Rs. 140.00)
      OrderModel(
        id: 'ORD-13201',
        tableName: 'T9',
        createdAt: DateTime(2026, 10, 8, 11, 45),
        takenByStaff: 'Addy',
        items: [
          OrderLineItem(item: findItem('C. Chicken Momo - Jhol'), quantity: 1), // 140
        ],
        status: OrderStatus.completed,
        paymentMethod: PaymentMethod.cash,
        cashGiven: 200.0,
        cashReturn: 60.0,
      ),
      // 17. T10 | ORD-13200 (Rs. 155.00)
      OrderModel(
        id: 'ORD-13200',
        tableName: 'T10',
        createdAt: DateTime(2026, 10, 8, 11, 10),
        takenByStaff: 'Addy',
        items: [
          OrderLineItem(item: findItem('Milk coffee'), quantity: 1),        // 55
          OrderLineItem(item: findItem('Blackcoffe double'), quantity: 1),   // 80
          OrderLineItem(item: findItem('Water'), quantity: 1),              // 20
        ],
        status: OrderStatus.completed,
        paymentMethod: PaymentMethod.cash,
        cashGiven: 500.0,
        cashReturn: 345.0,
      ),
    ];

    // Reference Cafe Tables (T1-T11, named customer groups & takeaway tabs)
    _tables = [
      TableModel(
        id: 'tb_fancy',
        name: 'Fancy wala',
        isOccupied: true,
        activeOrderId: 'ORD-13229',
        orderCount: 1,
        runningTotal: 505.0,
        elapsedMinutes: 24,
        isCustomGroup: true,
      ),
      TableModel(
        id: 'tb_masu',
        name: 'Masu wala',
        isOccupied: false,
        isCustomGroup: true,
      ),
      TableModel(
        id: 'tb_parlor',
        name: 'Parlor wala',
        isOccupied: false,
        isCustomGroup: true,
      ),
      TableModel(
        id: 'tb_pack',
        name: 'Pack',
        isOccupied: false,
        isCustomGroup: true,
      ),
      TableModel(
        id: 'tb_raj',
        name: 'Raj Group',
        isOccupied: false,
        isCustomGroup: true,
      ),
      TableModel(
        id: 'tb_dipesh',
        name: 'Dipesh Vai',
        isOccupied: false,
        isCustomGroup: true,
      ),
      TableModel(
        id: 'tb_navin',
        name: 'Navin Vaii',
        isOccupied: false,
        isCustomGroup: true,
      ),
      TableModel(
        id: 'tb_bharat',
        name: 'Bharat Oli',
        isOccupied: false,
        isCustomGroup: true,
      ),
      TableModel(
        id: 'tb_ridam',
        name: 'Ridam',
        isOccupied: false,
        isCustomGroup: true,
      ),
      TableModel(
        id: 'tb_bijay',
        name: 'Bijay',
        isOccupied: false,
        isCustomGroup: true,
      ),
      TableModel(
        id: 'tb_t1',
        name: 'T1',
        isOccupied: false,
      ),
      TableModel(
        id: 'tb_t2',
        name: 'T2',
        isOccupied: false,
      ),
      TableModel(
        id: 'tb_t3',
        name: 'T3',
        isOccupied: false,
      ),
      TableModel(
        id: 'tb_t4',
        name: 'T4',
        isOccupied: false,
      ),
      TableModel(
        id: 'tb_t5',
        name: 'T5',
        isOccupied: false,
      ),
      TableModel(
        id: 'tb_t6',
        name: 'T6',
        isOccupied: false,
      ),
      TableModel(
        id: 'tb_t7',
        name: 'T7',
        isOccupied: false,
      ),
      TableModel(
        id: 'tb_t8',
        name: 'T8',
        isOccupied: false,
      ),
      TableModel(
        id: 'tb_t9',
        name: 'T9',
        isOccupied: false,
      ),
      TableModel(
        id: 'tb_t10',
        name: 'T10',
        isOccupied: false,
      ),
      TableModel(
        id: 'tb_t11',
        name: 'T11',
        isOccupied: false,
      ),
    ];
  }

  // ----------------------------------------------------
  // Interactive Operations
  // ----------------------------------------------------

  /// Update item quantity in an order with anti-theft audit logging
  void updateOrderItemQuantity({
    required String orderId,
    required String itemId,
    required int newQuantity,
    String staffName = 'Addy',
    String? reason,
  }) {
    final orderIdx = _orders.indexWhere((o) => o.id == orderId);
    if (orderIdx == -1) return;

    final existingOrder = _orders[orderIdx];
    final lineItemIdx =
        existingOrder.items.indexWhere((l) => l.item.id == itemId);
    if (lineItemIdx == -1) return;

    final currentLine = existingOrder.items[lineItemIdx];
    final oldQty = currentLine.quantity;
    if (newQuantity == oldQty) return;

    final updatedItems = List<OrderLineItem>.from(existingOrder.items);
    final updatedAuditLog = List<OrderAuditEntry>.from(existingOrder.auditLog);
    bool hasRemoved = existingOrder.hasRemovedItems;

    if (newQuantity <= 0) {
      // Remove item completely
      updatedItems.removeAt(lineItemIdx);
      hasRemoved = true;
      updatedAuditLog.insert(
        0,
        OrderAuditEntry(
          id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
          timestamp: DateTime.now(),
          staffName: staffName,
          actionDescription: 'Removed ${currentLine.item.name} (was qty $oldQty)',
          reason: reason ?? 'Cashier item removal',
          itemName: currentLine.item.name,
          previousQty: oldQty,
          newQty: 0,
        ),
      );
    } else {
      updatedItems[lineItemIdx] = currentLine.copyWith(quantity: newQuantity);
      if (newQuantity < oldQty) {
        hasRemoved = true;
        updatedAuditLog.insert(
          0,
          OrderAuditEntry(
            id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
            timestamp: DateTime.now(),
            staffName: staffName,
            actionDescription:
                'Reduced ${currentLine.item.name} from $oldQty to $newQuantity',
            reason: reason ?? 'Quantity reduced',
            itemName: currentLine.item.name,
            previousQty: oldQty,
            newQty: newQuantity,
          ),
        );
      } else {
        updatedAuditLog.insert(
          0,
          OrderAuditEntry(
            id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
            timestamp: DateTime.now(),
            staffName: staffName,
            actionDescription:
                'Increased ${currentLine.item.name} from $oldQty to $newQuantity',
            reason: reason ?? 'Quantity increased',
            itemName: currentLine.item.name,
            previousQty: oldQty,
            newQty: newQuantity,
          ),
        );
      }
    }

    _orders[orderIdx] = existingOrder.copyWith(
      items: updatedItems,
      hasRemovedItems: hasRemoved,
      auditLog: updatedAuditLog,
    );

    // Update table running total if occupied
    final tableIdx =
        _tables.indexWhere((t) => t.name == existingOrder.tableName);
    if (tableIdx != -1) {
      _tables[tableIdx] = _tables[tableIdx].copyWith(
        runningTotal: _orders[orderIdx].payableAmount,
      );
    }

    notifyListeners();
  }

  /// Remove item completely with anti-theft audit logging
  void removeOrderItem({
    required String orderId,
    required String itemId,
    String staffName = 'Addy',
    String? reason,
  }) {
    updateOrderItemQuantity(
      orderId: orderId,
      itemId: itemId,
      newQuantity: 0,
      staffName: staffName,
      reason: reason ?? 'Removed item from order',
    );
  }

  // ----------------------------------------------------
  // Interactive Operations
  // ----------------------------------------------------

  /// Creates a new pending order from the Menu Punching flow
  String createOrderForTable({
    required String tableName,
    required List<OrderLineItem> items,
    String staffName = 'Addy',
  }) {
    final nextOrdNum = 13232 + _orders.length;
    final orderId = 'ORD-$nextOrdNum';

    final newOrder = OrderModel(
      id: orderId,
      tableName: tableName,
      createdAt: DateTime.now(),
      takenByStaff: staffName,
      items: items,
      status: OrderStatus.pending,
    );

    _orders.insert(0, newOrder);

    // Update table status
    final tableIndex = _tables.indexWhere((t) => t.name == tableName);
    if (tableIndex != -1) {
      _tables[tableIndex] = _tables[tableIndex].copyWith(
        isOccupied: true,
        activeOrderId: orderId,
        orderCount: _tables[tableIndex].orderCount + 1,
        runningTotal: _tables[tableIndex].runningTotal + newOrder.payableAmount,
        elapsedMinutes: 1,
      );
    }

    notifyListeners();
    return orderId;
  }

  /// Add items to existing order
  void addItemsToOrder(String orderId, List<OrderLineItem> newItems) {
    final orderIdx = _orders.indexWhere((o) => o.id == orderId);
    if (orderIdx == -1) return;

    final existingOrder = _orders[orderIdx];
    final mergedItems = List<OrderLineItem>.from(existingOrder.items);

    for (var newItem in newItems) {
      final existingLineIdx =
          mergedItems.indexWhere((l) => l.item.id == newItem.item.id);
      if (existingLineIdx != -1) {
        mergedItems[existingLineIdx].quantity += newItem.quantity;
      } else {
        mergedItems.add(newItem);
      }
    }

    _orders[orderIdx] = existingOrder.copyWith(items: mergedItems);

    // Update table running total
    final tableIdx = _tables.indexWhere((t) => t.name == existingOrder.tableName);
    if (tableIdx != -1) {
      _tables[tableIdx] = _tables[tableIdx].copyWith(
        runningTotal: _orders[orderIdx].payableAmount,
      );
    }

    notifyListeners();
  }

  /// Apply quick discount to order
  void applyDiscount(
    String orderId,
    DiscountPreset preset, {
    double? customAmount,
  }) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) return;

    final order = _orders[index];
    double discountVal = 0.0;

    switch (preset) {
      case DiscountPreset.none:
        discountVal = 0.0;
        break;
      case DiscountPreset.percent5:
        discountVal = order.subtotal * 0.05;
        break;
      case DiscountPreset.percent10:
        discountVal = order.subtotal * 0.10;
        break;
      case DiscountPreset.flat20:
        discountVal = 20.0;
        break;
      case DiscountPreset.flat50:
        discountVal = 50.0;
        break;
      case DiscountPreset.custom:
        discountVal = customAmount ?? 0.0;
        break;
    }

    if (discountVal > order.subtotal) {
      discountVal = order.subtotal;
    }

    _orders[index] = order.copyWith(
      discountAmount: discountVal,
      discountPreset: preset,
    );

    notifyListeners();
  }

  /// Complete Checkout
  void checkoutOrder({
    required String orderId,
    required PaymentMethod method,
    double cashGiven = 0.0,
    String? customerId,
  }) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) return;

    final order = _orders[index];
    final payable = order.payableAmount;
    final cashReturn = (method == PaymentMethod.cash && cashGiven > payable)
        ? (cashGiven - payable)
        : 0.0;

    switch (method) {
      case PaymentMethod.cash:
        _immediateCashRevenue += payable;
        break;
      case PaymentMethod.fonepay:
        _immediateFonepayRevenue += payable;
        break;
      case PaymentMethod.esewa:
        _immediateWalletRevenue += payable;
        break;
      case PaymentMethod.bank:
        _immediateBankRevenue += payable;
        break;
      case PaymentMethod.customerCredit:
        _creditSalesRevenue += payable;
        break;
    }

    String? assignedCustomerName;
    if (method == PaymentMethod.customerCredit && customerId != null) {
      final custIdx = _customers.indexWhere((c) => c.id == customerId);
      if (custIdx != -1) {
        final cust = _customers[custIdx];
        assignedCustomerName = cust.name;
        final updatedTransactions =
            List<CustomerCreditTransaction>.from(cust.transactions)
              ..add(
                CustomerCreditTransaction(
                  id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
                  date: DateTime.now(),
                  orderId: order.id,
                  amount: payable,
                  isPayment: false,
                  note: 'Credit checkout for ${order.tableName}',
                ),
              );

        _customers[custIdx] = cust.copyWith(
          totalDue: cust.totalDue + payable,
          transactions: updatedTransactions,
        );
      }
    }

    _orders[index] = order.copyWith(
      status: OrderStatus.completed,
      paymentMethod: method,
      cashGiven: cashGiven,
      cashReturn: cashReturn,
      customerId: customerId,
      customerName: assignedCustomerName,
    );

    // Free the table
    final tableIndex = _tables.indexWhere((t) => t.name == order.tableName);
    if (tableIndex != -1) {
      _tables[tableIndex] = _tables[tableIndex].copyWith(
        isOccupied: false,
        activeOrderId: null,
        orderCount: 0,
        runningTotal: 0.0,
        elapsedMinutes: 0,
      );
    }

    // Deduct raw ingredients from inventory via Recipe BOM
    for (final line in order.items) {
      final bom = _recipeBoms.firstWhere(
        (b) =>
            b.menuItemId == line.item.id ||
            b.menuItemName.toLowerCase() == line.item.name.toLowerCase() ||
            (line.item.name.startsWith('Surya Red') &&
                b.menuItemName.startsWith('Surya Red')),
        orElse: () =>
            const RecipeBOM(menuItemId: '', menuItemName: '', ingredients: []),
      );

      for (final ing in bom.ingredients) {
        final deductQty = ing.quantityRequired * line.quantity;
        final invIdx = _inventoryItems.indexWhere(
          (i) =>
              i.id == ing.inventoryItemId ||
              i.name.toLowerCase() == ing.inventoryItemName.toLowerCase(),
        );
        if (invIdx != -1) {
          final invItem = _inventoryItems[invIdx];
          _inventoryItems[invIdx] = invItem.copyWith(
            currentStock: invItem.currentStock - deductQty,
          );
          _stockLogs.insert(
            0,
            StockLogEntry(
              id: 'log_${DateTime.now().millisecondsSinceEpoch}_${ing.inventoryItemId}',
              timestamp: DateTime.now(),
              inventoryItemId: invItem.id,
              inventoryItemName: invItem.name,
              changeAmount: -deductQty,
              unit: ing.unit,
              type: StockLogType.saleDeduction,
              orderId: order.id,
              note: 'POS Checkout ${order.tableName} (${order.id})',
            ),
          );
        }
      }

      // Track incremental sales for Analytics Section 7
      final normName =
          line.item.name == 'Surya Red (Stick)' ? 'Surya Red' : line.item.name;
      _extraSalesQty[normName] =
          (_extraSalesQty[normName] ?? 0) + line.quantity;
      _extraSalesRev[normName] =
          (_extraSalesRev[normName] ?? 0.0) + line.totalPrice;
      final cat = line.item.category;
      _extraCategoryQty[cat] = (_extraCategoryQty[cat] ?? 0) + line.quantity;
      _extraCategoryRev[cat] = (_extraCategoryRev[cat] ?? 0.0) + line.totalPrice;
    }

    notifyListeners();
  }

  /// Cancel Order
  void cancelOrder(String orderId) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) return;

    final order = _orders[index];
    _orders[index] = order.copyWith(status: OrderStatus.cancelled);

    // Free table
    final tableIndex = _tables.indexWhere((t) => t.name == order.tableName);
    if (tableIndex != -1) {
      _tables[tableIndex] = _tables[tableIndex].copyWith(
        isOccupied: false,
        activeOrderId: null,
        orderCount: 0,
        runningTotal: 0.0,
        elapsedMinutes: 0,
      );
    }

    notifyListeners();
  }

  /// Settle or record customer payment
  void settleCustomerCredit({
    required String customerId,
    required double amount,
    double creditDiscount = 0.0,
    PaymentMethod method = PaymentMethod.cash,
    bool isStaffAdvance = false,
    String? note,
  }) {
    final custIdx = _customers.indexWhere((c) => c.id == customerId);
    if (custIdx == -1) return;

    final cust = _customers[custIdx];
    final totalDeduction = amount + creditDiscount;
    final updatedDue =
        (cust.totalDue - totalDeduction).clamp(0.0, double.infinity);

    if (isStaffAdvance) {
      _staffCreditAddedToAdvance += amount;
    } else {
      switch (method) {
        case PaymentMethod.cash:
          _creditCollectedCash += amount;
          break;
        case PaymentMethod.fonepay:
          _creditCollectedFonepay += amount;
          break;
        case PaymentMethod.esewa:
          _creditCollectedWallet += amount;
          break;
        case PaymentMethod.bank:
          _creditCollectedBank += amount;
          break;
        case PaymentMethod.customerCredit:
          break;
      }
    }

    if (creditDiscount > 0) {
      _creditDiscountGiven += creditDiscount;
    }

    final updatedTx = List<CustomerCreditTransaction>.from(cust.transactions)
      ..add(
        CustomerCreditTransaction(
          id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
          date: DateTime.now(),
          orderId: 'SETTLEMENT',
          amount: amount,
          isPayment: true,
          paymentMethod: method,
          creditDiscount: creditDiscount,
          isStaffAdvance: isStaffAdvance,
          note: note ??
              (isStaffAdvance
                  ? 'Staff credit advance deduction'
                  : 'Credit settlement (${method.name.toUpperCase()})'),
        ),
      );

    _customers[custIdx] = cust.copyWith(
      totalDue: updatedDue,
      transactions: updatedTx,
    );

    notifyListeners();
  }

  /// Add manual credit due to customer khata
  void addManualCustomerDue({
    required String customerId,
    required double amount,
    String note = 'Manual Tab Due',
  }) {
    final custIdx = _customers.indexWhere((c) => c.id == customerId);
    if (custIdx == -1) return;

    final cust = _customers[custIdx];
    final updatedDue = cust.totalDue + amount;
    _creditSalesRevenue += amount;

    final updatedTx = List<CustomerCreditTransaction>.from(cust.transactions)
      ..add(
        CustomerCreditTransaction(
          id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
          date: DateTime.now(),
          orderId: 'MANUAL_DUE',
          amount: amount,
          isPayment: false,
          note: note,
        ),
      );

    _customers[custIdx] = cust.copyWith(
      totalDue: updatedDue,
      transactions: updatedTx,
    );

    notifyListeners();
  }

  /// Add new customer
  void addCustomer({
    required String name,
    required String phone,
    String address = 'Kathmandu, Nepal',
    double initialDue = 0.0,
    bool isStaff = false,
  }) {
    final parts = name.trim().split(' ');
    String initials = '';
    if (parts.length >= 2) {
      initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      initials =
          parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    } else {
      initials = 'C';
    }

    final palette = [
      0xFF10B981, // Emerald
      0xFF3B82F6, // Blue
      0xFF8B5CF6, // Purple
      0xFFF59E0B, // Amber
      0xFFEC4899, // Pink
      0xFF14B8A6, // Teal
    ];
    final color = palette[_customers.length % palette.length];

    final List<CustomerCreditTransaction> txs = [];
    if (initialDue > 0) {
      _creditSalesRevenue += initialDue;
      txs.add(
        CustomerCreditTransaction(
          id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
          date: DateTime.now(),
          orderId: 'OPENING_DUE',
          amount: initialDue,
          isPayment: false,
          note: 'Opening Credit Balance',
        ),
      );
    }

    final newCust = CustomerModel(
      id: 'c_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      phone: phone.trim(),
      address: address.trim().isEmpty ? 'Kathmandu, Nepal' : address.trim(),
      totalDue: initialDue,
      initials: initials,
      avatarColorValue: color,
      isStaff: isStaff,
      transactions: txs,
    );

    _customers.insert(0, newCust);
    notifyListeners();
  }

  /// Add custom table / group
  void addTable(String name, {bool isCustomGroup = true}) {
    if (name.trim().isEmpty) return;
    final newTable = TableModel(
      id: 'tb_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      isCustomGroup: isCustomGroup,
    );
    _tables.add(newTable);
    notifyListeners();
  }

  // ----------------------------------------------------
  // Analytics Calculations
  // ----------------------------------------------------

  double get totalRevenue {
    final completedTotal = _orders
        .where((o) => o.status == OrderStatus.completed)
        .fold(0.0, (sum, o) => sum + o.payableAmount);
    return completedTotal;
  }

  double get totalDiscountsGiven {
    return _orders
        .where((o) => o.status == OrderStatus.completed)
        .fold(0.0, (sum, o) => sum + o.discountAmount);
  }

  int get totalCompletedOrdersCount {
    return _orders.where((o) => o.status == OrderStatus.completed).length;
  }

  int get totalPendingOrdersCount {
    return _orders.where((o) => o.status == OrderStatus.pending).length;
  }

  int get totalCancelledOrdersCount {
    return _orders.where((o) => o.status == OrderStatus.cancelled).length;
  }

  double get averageOrderValue {
    final count = totalCompletedOrdersCount;
    if (count == 0) return 0.0;
    return totalRevenue / count;
  }

  // Payment Breakdown
  double get cashRevenue {
    return _orders
        .where((o) =>
            o.status == OrderStatus.completed &&
            o.paymentMethod == PaymentMethod.cash)
        .fold(0.0, (sum, o) => sum + o.payableAmount);
  }

  double get fonepayRevenue {
    return _orders
        .where((o) =>
            o.status == OrderStatus.completed &&
            o.paymentMethod == PaymentMethod.fonepay)
        .fold(0.0, (sum, o) => sum + o.payableAmount);
  }

  double get walletRevenue {
    return _orders
        .where((o) =>
            o.status == OrderStatus.completed &&
            o.paymentMethod == PaymentMethod.esewa)
        .fold(0.0, (sum, o) => sum + o.payableAmount);
  }

  double get bankRevenue {
    return _orders
        .where((o) =>
            o.status == OrderStatus.completed &&
            o.paymentMethod == PaymentMethod.bank)
        .fold(0.0, (sum, o) => sum + o.payableAmount);
  }


  double get totalPastCreditDues {
    return _customers.fold(0.0, (sum, c) => sum + c.totalDue);
  }

  // ----------------------------------------------------
  // Stocks & Inventory Management Methods
  // ----------------------------------------------------
  void purchaseStock({
    required String inventoryItemId,
    required double quantity,
    required double cost,
    String? supplierNote,
  }) {
    final idx = _inventoryItems.indexWhere((i) => i.id == inventoryItemId);
    if (idx == -1) return;

    final item = _inventoryItems[idx];
    _inventoryItems[idx] = item.copyWith(
      currentStock: item.currentStock + quantity,
      unitCost: cost > 0 ? cost : item.unitCost,
    );

    _stockLogs.insert(
      0,
      StockLogEntry(
        id: 'log_pur_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        inventoryItemId: item.id,
        inventoryItemName: item.name,
        changeAmount: quantity,
        unit: item.unit,
        type: StockLogType.purchase,
        note: supplierNote ??
            'Restock Purchase (+${quantity.toStringAsFixed(1)} ${item.unit})',
      ),
    );

    notifyListeners();
  }

  void adjustStock({
    required String inventoryItemId,
    required double newStock,
    required String reason,
  }) {
    final idx = _inventoryItems.indexWhere((i) => i.id == inventoryItemId);
    if (idx == -1) return;

    final item = _inventoryItems[idx];
    final diff = newStock - item.currentStock;
    _inventoryItems[idx] = item.copyWith(currentStock: newStock);

    _stockLogs.insert(
      0,
      StockLogEntry(
        id: 'log_adj_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        inventoryItemId: item.id,
        inventoryItemName: item.name,
        changeAmount: diff,
        unit: item.unit,
        type: StockLogType.adjustmentWastage,
        note:
            '$reason (${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)} ${item.unit})',
      ),
    );

    notifyListeners();
  }

  void updateRecipeBOM({
    required String menuItemId,
    required List<RecipeIngredient> ingredients,
  }) {
    final idx = _recipeBoms.indexWhere((b) => b.menuItemId == menuItemId);
    if (idx != -1) {
      _recipeBoms[idx] = _recipeBoms[idx].copyWith(ingredients: ingredients);
    } else {
      final menuItem = _menuItems.firstWhere((m) => m.id == menuItemId);
      _recipeBoms.add(
        RecipeBOM(
          menuItemId: menuItemId,
          menuItemName: menuItem.name,
          ingredients: ingredients,
        ),
      );
    }
    notifyListeners();
  }

  // ----------------------------------------------------
  // Dual Leaderboards (Top vs Non-Selling Items & Categories)
  // ----------------------------------------------------
  List<Map<String, dynamic>> get topCategoriesLeaderboard {
    // Exact reference cafe baseline categories
    final Map<String, int> catSold = {
      'Smoke': 13,
      'Tea': 7,
      'Momo & Noodles': 4,
      'Chips': 1,
      'Hookah': 1,
      'Coffee': 0,
      'Cold Beverages': 0,
      'Premium Hookah': 0,
    };

    final Map<String, double> catRev = {
      'Smoke': 300.0,
      'Tea': 230.0,
      'Momo & Noodles': 615.0,
      'Chips': 10.0,
      'Hookah': 230.0,
      'Coffee': 0.0,
      'Cold Beverages': 0.0,
      'Premium Hookah': 0.0,
    };

    // Add extra sales from dynamically completed orders
    _extraCategoryQty.forEach((cat, qty) {
      catSold[cat] = (catSold[cat] ?? 0) + qty;
    });
    _extraCategoryRev.forEach((cat, rev) {
      catRev[cat] = (catRev[cat] ?? 0.0) + rev;
    });

    final List<Map<String, dynamic>> list = [];
    catSold.forEach((cat, sold) {
      list.add({
        'category': cat,
        'sold': sold,
        'revenue': catRev[cat] ?? 0.0,
      });
    });

    if (_analyticsCategoriesTopOnly) {
      final filtered = list.where((it) => (it['sold'] as int) > 0).toList();
      filtered.sort((a, b) => (b['sold'] as int).compareTo(a['sold'] as int));
      return filtered.take(5).toList();
    } else {
      final filtered = list.where((it) => (it['sold'] as int) == 0).toList();
      return filtered;
    }
  }

  List<Map<String, dynamic>> get topSellingItemsLeaderboard {
    // Exact reference cafe baseline menu items
    final Map<String, int> itemSold = {
      'Surya Red': 8,
      'Shikhar ice': 5,
      'Regular tea': 5,
      'Chiken Keema Noodles': 2,
      'C. Chicken Momo - Jhol': 2,
    };

    final Map<String, double> itemRev = {
      'Surya Red': 200.0,
      'Shikhar ice': 100.0,
      'Regular tea': 150.0,
      'Chiken Keema Noodles': 335.0,
      'C. Chicken Momo - Jhol': 280.0,
    };

    final Map<String, String> itemCat = {
      'Surya Red': 'Smoke',
      'Shikhar ice': 'Smoke',
      'Regular tea': 'Tea',
      'Chiken Keema Noodles': 'Momo & Noodles',
      'C. Chicken Momo - Jhol': 'Momo & Noodles',
    };

    // Populate remaining menu items with 0 sold
    for (final m in _menuItems) {
      final normName = m.name == 'Surya Red (Stick)' ? 'Surya Red' : m.name;
      itemSold.putIfAbsent(normName, () => 0);
      itemRev.putIfAbsent(normName, () => 0.0);
      itemCat.putIfAbsent(normName, () => m.category);
    }

    // Add extra sales from dynamically completed orders
    _extraSalesQty.forEach((name, qty) {
      final normName = name == 'Surya Red (Stick)' ? 'Surya Red' : name;
      itemSold[normName] = (itemSold[normName] ?? 0) + qty;
    });
    _extraSalesRev.forEach((name, rev) {
      final normName = name == 'Surya Red (Stick)' ? 'Surya Red' : name;
      itemRev[normName] = (itemRev[normName] ?? 0.0) + rev;
    });

    final List<Map<String, dynamic>> list = [];
    itemSold.forEach((name, sold) {
      list.add({
        'name': name,
        'category': itemCat[name] ?? 'General',
        'sold': sold,
        'revenue': itemRev[name] ?? 0.0,
      });
    });

    if (_analyticsItemsTopOnly) {
      final filtered = list.where((it) => (it['sold'] as int) > 0).toList();
      filtered.sort((a, b) => (b['sold'] as int).compareTo(a['sold'] as int));
      return filtered.take(5).toList();
    } else {
      final filtered = list.where((it) => (it['sold'] as int) == 0).toList();
      return filtered;
    }
  }

  // Top Items Leaderboard (Backward compatibility)
  List<Map<String, dynamic>> get topSellingItems => topSellingItemsLeaderboard;

  // ----------------------------------------------------
  // Phase 6: Multi-Tenant & Printer Configuration Getters/Setters
  // ----------------------------------------------------
  String get tenantId => _tenantId;
  String get tenantName => _tenantName;
  String get activeBranch => _activeBranch;
  String get activeStaff => _activeStaff;
  PaperSize get printerPaperSize => _printerPaperSize;
  PrinterConnectionMode get printerConnectionMode => _printerConnectionMode;
  String get printerDeviceAddress => _printerDeviceAddress;
  bool get autoCutPaper => _autoCutPaper;

  void setActiveBranch(String branch) {
    _activeBranch = branch;
    notifyListeners();
  }

  void setPrinterPaperSize(PaperSize size) {
    _printerPaperSize = size;
    notifyListeners();
  }

  void setPrinterConnectionMode(PrinterConnectionMode mode) {
    _printerConnectionMode = mode;
    notifyListeners();
  }

  void setPrinterDeviceAddress(String address) {
    _printerDeviceAddress = address;
    notifyListeners();
  }

  void setAutoCutPaper(bool autoCut) {
    _autoCutPaper = autoCut;
    notifyListeners();
  }

  /// Resets all tables, orders, customers, inventory, and counters back to reference cafe baseline
  void resetToBaselineData() {
    _extraSalesQty.clear();
    _extraSalesRev.clear();
    _extraCategoryQty.clear();
    _extraCategoryRev.clear();

    _immediateCashRevenue = 290.0;
    _immediateFonepayRevenue = 250.0;
    _immediateWalletRevenue = 0.0;
    _immediateBankRevenue = 0.0;
    _creditSalesRevenue = 845.0;

    _creditCollectedCash = 6820.0;
    _creditCollectedFonepay = 0.0;
    _creditCollectedWallet = 0.0;
    _creditCollectedBank = 0.0;
    _creditDiscountGiven = 0.0;
    _staffCreditAddedToAdvance = 0.0;

    _initData();
    notifyListeners();
  }
}
