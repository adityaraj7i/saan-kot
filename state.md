# Saan KOT - Master State & Phase Tracker

**Last Updated:** Phase 6 Execution & Audit (100% Completed)  
**Platform:** Flutter (Android, iOS, Web, Desktop)  
**State Architecture:** Clean In-Memory Central Store (`AppState` & `AppStateScope`)  
**Design Standard:** Deep Forest Emerald (`#059669`) & Warm Amber (`#F59E0B`), Alabaster Surface (`#F8FAFC`), Rose Red (`#E11D48`), Tabular Figures Currency (`Rs. X.XX`)

---

## 1. Six-Phase Architecture Roadmap

| Phase | Description | Status | Verification |
|---|---|---|---|
| **Phase 1** | **Foundation & Navigation Shell**<br>Theme system, 4-tab bottom navigation (`Bills`, `Take Order`, `Customers`, `Analytics`), shared in-memory data store, reference seed models. | **Completed & Audited** | `widget_test.dart`, `seed_data_audit_test.dart` |
| **Phase 2** | **Screen 2: Take Order & Menu Punching**<br>2-Column responsive table grid, custom groups (`Fancy wala`, `Masu wala`, etc.), `+ Add Table` card, Restaurant Menu with 7 categories, `- 0 +` steppers, grid/list toggle, sticky KOT bar (`Send KOT` / `Save & View Bill`). | **Completed & Audited** | `flow_test.dart` (Flow 1 & 2), `seed_data_audit_test.dart` |
| **Phase 3** | **Screen 1: Bills, Anti-Theft Audit Tracking & Order Details Checkout Sheet**<br>Top app bar (`08 Oct` date pill, `Order History`, `PDF`, `Refresh`), Amber active pill (`#F59E0B`) on `Pending`, dynamic sub-filters on `Completed` (`All`, `Item Removed (2)`, `Item Unserved (1)`), bottom-right floating Emerald total pill (`Total: Rs 505.00` on Pending, `Total: Rs 3070.00` on Completed), Order Details Sheet with audit log timeline dialog (`History (i)`), interactive line item `Qty` dialog with `-` / `+` steppers, reason selector (`Customer changed mind`, `Kitchen out of stock`, etc.) and `Remove Item` logging to `OrderAuditEntry`, discount calculator, 2x2 payment grid (`Cash` with return change calculation, `Customer Credit` with customer picker updating due balance, `Fonepay QR`, `eSewa`), sticky bottom row with `Cancel Order` and `Checkout`. | **Completed & Audited** | `phase_3_bills_audit_test.dart`, `flow_test.dart`, `seed_data_audit_test.dart` |
| **Phase 4** | **Screen 3: My Customers (Khata Credit Ledger), Credit Settlement Engine & Staff Advances**<br>Deep Emerald top header with `My Customers` and `Refresh` icon button, search bar filtering by name, phone, or address, customer cards with exact reference avatar colors and initials (`Ajaya` `#D97706`, `Bharat Bhanja` `#6366F1`, `Bijay` `#10B981`, `Gyalzan S` `#7C3AED`, `Himal` `#6D28D9`, `Jar Wala` `#C2410C`), right wallet/credit status tags (`No Dues` or bold red `Rs. 4890.00`), floating action button for `Add / Edit Customer` with `Is Staff Member` switch, interactive `CustomerKhataSheet` with debit/credit ledger, quick chips (`Full Due`, `50%`), payment method selector (`Cash`, `Fonepay`, `Digital Wallet`, `Bank`, `Staff Advance`), credit discount calculator, manual due entry dialog, and shareable WhatsApp statement preview. | **Completed & Audited** | `phase_4_customers_khata_test.dart`, `flow_test.dart` |
| **Phase 5** | **Screen 4: 7-Section Analytics Dashboard & Stocks/Inventory Recipe BOM Engine**<br>Deep Emerald header with PDF export & Addy profile badge `A`; Section 1 Total Revenue Bento Grid (`Total Amount: Rs. 3070.00`, `Net Amount: Rs. 3070.00`, `Total Discount: Rs. 140.00`, `Total Orders: 18`, `Avg. Order Value: Rs. 170.56`); Section 2 Payment Collections (`Cash: Rs. 290.00`, `Fonepay: Rs. 250.00`, `Digital Wallet: Rs. 0.00`, `Bank: Rs. 0.00`); Section 3 Credit Analytics (`Credit Sales: Rs. 845.00`, `Credit Collected: Rs. 6820.00`, `Credit Discount: Rs. 0.00`, `Past Dues: Rs. 4890.00`) with `Total Sales (i)` badge; Section 4 Credit Collections Breakdown (`Cash: Rs. 6820.00`, `Staff Credit Added to Advance: Rs. 0.00`); Section 5 Total Collection Summary (`Total Collection: Rs. 7360.00`, `Cash: Rs. 7110.00`, `Fonepay: Rs. 250.00`); Section 6 Order Status Summary (`Completed: 17`, `Pending: 1`, `Date: Oct 08, 2026 | Revenue: Rs. 3070.00`); Section 7 Dual Leaderboards with `Top` vs `Non` toggles (`Top Categories` & `Top Sellings Leaderboard`); Complete 4-tab Stocks & Inventory module (`All Stock`, `Low / Out (3)`, `Recipes (BOM)`, `Stock Log`) with automated Recipe BOM raw ingredient stock deduction upon POS checkout, restock purchase sheets, and wastage adjustment sheets. | **Completed & Audited** | `phase_5_analytics_inventory_test.dart`, `flow_test.dart` |
| **Phase 6** | **58mm/80mm Thermal Printing, Interactive PDF Reports, Multi-Tenant Settings & Production Hardening**<br>Thermal printing service (`thermal_printer_service.dart`) with 58mm (32 cols) & 80mm (48 cols) formats, raw ESC/POS command generation (`EscPosGenerator`), realistic `ThermalReceiptPreviewModal` with perforated edges, interactive `DailyOrderRegisterModal` in Bills, `OrdersBreakdownDialog` on floating total pill, `EndOfDayZReportModal` in Analytics, Multi-Tenant Branch, Printer & Sync `SettingsSheet` (triggered via profile badge `A`) with `Reset Demo Data to Baseline`, full 16-table Supabase PostgreSQL DDL migration with tenant/branch RLS policies (`001_saan_kot_schema.sql`), and 100% test pass across all 7 test suites. | **Completed & Audited** | `flutter analyze` (0 issues), `flutter test` (40 of 40 tests passing across 7 suites) |

---

## 2. Reference Cafe Seed Data Audit Checklist

### A. Tables & Named Customer Groups (21 Total)
- [x] **T1–T11**: 11 standard dine-in tables (`T1`, `T2`, `T3`, `T4`, `T5`, `T6`, `T7`, `T8`, `T9`, `T10`, `T11`).
- [x] **Fancy wala**: Occupied with active Pending Order `ORD-13229` for **Rs. 505.00** taken by **Addy** (elapsed: 24 mins).
- [x] **Masu wala**: Empty table tab ready for instant order punching.
- [x] **Parlor wala**: Empty custom cafe group tab.
- [x] **Pack**: Empty takeaway / packaging tab.
- [x] **Raj Group**: Custom customer group tab.
- [x] **Dipesh Vai**: Custom customer group tab.
- [x] **Navin Vaii**: Custom customer group tab.
- [x] **Bharat Oli**: Custom customer group tab.
- [x] **Ridam**: Custom customer group tab.
- [x] **Bijay**: Custom customer group tab.
- [x] **`+ Add Table` Card**: Final dashed card allowing staff to instantly create tables or custom tabs.

### B. Menu Categories & Items with Exact Rs. Prices (7 Categories)
1. **Coffee**:
   - `Black Coffee` - Rs. 50.00
   - `Blackcoffe double` - Rs. 80.00
   - `Milk coffee` - Rs. 55.00
   - `Cold coffee` - Rs. 85.00
   - `Iced americano` - Rs. 75.00
   - `Milk` - Rs. 70.00
   - `Cafe Latte` - Rs. 180.00
   - `Cappuccino` - Rs. 190.00
   - `Americano` - Rs. 130.00
   - `Hot Chocolate` - Rs. 210.00
   - `Espresso Single` - Rs. 90.00
2. **Cold Beverages**:
   - `Peach Iced Tea` - Rs. 180.00
   - `Virgin Mojito` - Rs. 220.00
   - `Lemon Mint Soda` - Rs. 125.00
   - `Red Bull Chill` - Rs. 250.00
   - `Blue Ocean Soda` - Rs. 190.00
   - `Water` - Rs. 20.00
3. **Hookah**:
   - `1 Normal Hookah` - Rs. 230.00
   - `2 Normal cloud Hookah` - Rs. 300.00
   - `Normal Cloud Hookah` - Rs. 650.00
   - `Brain Freezer Hookah` - Rs. 750.00
   - `Double Apple Al Fakher` - Rs. 700.00
   - `Mint Blast Hookah` - Rs. 650.00
4. **Premium Hookah**:
   - `Night Queen Premium` - Rs. 950.00
   - `Russian Exotica Hookah` - Rs. 1200.00
   - `Dubai Gold Special` - Rs. 1100.00
5. **Momo & Noodles**:
   - `C. Chicken Momo - Jhol` - Rs. 140.00
   - `Fried Buff Momo` - Rs. 240.00
   - `Steam Paneer Momo` - Rs. 220.00
   - `Spicy Schezwan Chicken Chowmein` - Rs. 260.00
   - `Sadeko Wai Wai` - Rs. 120.00
6. **Smoke**:
   - `Surya Red (Stick)` - Rs. 25.00
   - `Surya Light (Stick)` - Rs. 25.00
   - `Shikhar ice (Stick)` - Rs. 20.00
   - `Marlboro Gold (Stick)` - Rs. 30.00
   - `Surya Red (Full Pack)` - Rs. 500.00
7. **Tea**:
   - `Regular tea` - Rs. 30.00
   - `Milk Tea (Special Dudh Chiya)` - Rs. 50.00
   - `Black Tea` - Rs. 40.00
   - `Masala Chiya` - Rs. 60.00
   - `Hot Lemon Honey` - Rs. 120.00
   - `Green Tea` - Rs. 80.00
   - `Matka Chiya` - Rs. 70.00

### C. Active Pending Order ORD-13229 (Exact Reference Cafe)
- **Table:** `Fancy wala`
- **Taken By:** `Addy`
- **Created At:** `08 Oct, 16:56`
- **Items (6 total):**
  1. `Milk coffee` (x1) = Rs. 55.00
  2. `Iced americano` (x1) = Rs. 75.00
  3. `Cold coffee` (x1) = Rs. 85.00
  4. `Blackcoffe double` (x1) = Rs. 80.00
  5. `Milk` (x1) = Rs. 70.00
  6. `C. Chicken Momo - Jhol` (x1) = Rs. 140.00
- **Total Payable:** **Rs. 505.00**

### D. Completed Orders (17 Orders Totaling Exactly Rs. 3070.00)
- **1. T1 | ORD-13230** (16:59, Rs. 120.00: Black Coffee x1 Rs. 50.00, Milk x1 Rs. 70.00)
- **2. T1 | ORD-13228** (14:34, Rs. 70.00: Rs. 120 with Rs. 50 discount)
- **3. Raj Group | ORD-13227** (13:39, Rs. 530.00: 1 Normal Hookah x1 Rs. 230.00, 2 Normal cloud Hookah x1 Rs. 300.00)
- **4. Masu wala | ORD-13226** (13:12, Rs. 205.00: Shikhar ice x4 Rs. 80.00, Regular tea x1 Rs. 30.00, Lemon Mint Soda x1 Rs. 125.00 with Rs. 30 discount)
- **5. T3 | ORD-13225** (12:45, Rs. 130.00: Americano x1 Rs. 130.00)
- **6. T5 | ORD-13211** (12:00, Rs. 0.00: 100% complimentary / courtesy tab)
- **7. T4 | ORD-13210** (11:20, Rs. 70.00: Matka Chiya x1 Rs. 70.00)
- **8–17 Remaining Completed Orders:**
  - `ORD-13209`: T2 (Rs. 240.00)
  - `ORD-13208`: T7 (`hasRemovedItems: true`, Rs. 180.00)
  - `ORD-13207`: T6 (Rs. 220.00)
  - `ORD-13206`: Pack (Rs. 280.00)
  - `ORD-13205`: Dipesh Vai (Rs. 230.00)
  - `ORD-13204`: Parlor wala (`hasRemovedItems: true`, Rs. 190.00)
  - `ORD-13203`: Bijay (Rs. 160.00)
  - `ORD-13202`: Navin Vaii (`hasUnservedItems: true`, Rs. 150.00)
  - `ORD-13201`: T9 (Rs. 140.00)
  - `ORD-13200`: T10 (Rs. 155.00)
- **Completed Total:** **Rs. 3070.00**

### E. Customers & Khata Dues (6 Reference Cafe Customers with Exact Video Colors)
- [x] **Ajaya**: `9812345678`, Amber `#D97706`, `Total Due: Rs. 0.00` (Initials: `A`, `No Dues`).
- [x] **Bharat Bhanja**: `9866234475`, Indigo `#6366F1`, `Total Due: Rs. 0.00` (Initials: `BB`, `No Dues`).
- [x] **Bijay**: `9845896631`, Emerald `#10B981`, `Total Due: Rs. 0.00` (Initials: `B`, `No Dues`).
- [x] **Gyalzan S**: `9865741236`, Purple `#7C3AED`, `Total Due: Rs. 0.00` (Initials: `GS`, `No Dues`).
- [x] **Himal**: `9846849186`, Deep Purple `#6D28D9`, `Total Due: Rs. 4890.00` (Initials: `H`, itemized Khata ledger with `ORD-13101` and `ORD-13180`).
- [x] **Jar Wala**: `9866556525`, Burnt Orange `#C2410C`, `Total Due: Rs. 0.00` (Initials: `JW`, `No Dues`).

### F. Financial Baseline Collections & Khata Reconciliation
- **Immediate Order Collections on Completed Orders:**
  - `Cash`: **Rs. 290.00**
  - `Fonepay`: **Rs. 250.00**
  - `Digital Wallet`: **Rs. 0.00**
  - `Bank`: **Rs. 0.00**
  - `Credit Sales`: **Rs. 845.00**
- **Seeded Historical Credit Collections Today:**
  - `Cash`: **Rs. 6820.00**
  - `Fonepay`: **Rs. 0.00**
  - `Digital Wallet`: **Rs. 0.00**
  - `Bank`: **Rs. 0.00**
  - `Credit Discount`: **Rs. 0.00**
  - `Staff Credit Added to Advance`: **Rs. 0.00**
- **Total Collection Summary (Immediate Collections + Credit Collections):**
  - `Total Collection`: **Rs. 7360.00** (`Cash: Rs. 7110.00`, `Fonepay: Rs. 250.00`, `Digital Wallet: Rs. 0.00`, `Bank: Rs. 0.00`).

---

## 3. Codebase File Structure

```
lib/
├── main.dart                               # App entry point with SaanKotApp & global theme
├── core/
│   └── services/
│       └── thermal_printer_service.dart    # 58mm/80mm formatters, raw ESC/POS byte generator & perforated thermal modal
├── theme/
│   └── app_theme.dart                      # AppColors, AppGradients, CurrencyHelper (Rs. X.XX)
├── models/
│   ├── customer_model.dart                 # CustomerModel (isStaff) & CustomerCreditTransaction (paymentMethod, creditDiscount, isStaffAdvance)
│   ├── inventory_model.dart                # InventoryItem (lowStock), RecipeBOM, RecipeIngredient, StockLogEntry, StockLogType
│   ├── menu_item_model.dart                # MenuItem & OrderLineItem
│   ├── order_model.dart                    # OrderModel, OrderAuditEntry, OrderStatus, PaymentMethod, DiscountPreset
│   └── table_model.dart                    # TableModel (dine-in, custom groups, timers, totals)
├── state/
│   ├── app_state.dart                      # Central store pre-seeded with exact bills, customer colors, & credit collection counters
│   └── app_state_scope.dart                # InheritedNotifier scope for reactivity
├── widgets/
│   ├── currency_text.dart                  # Tabular figures formatting widget for Rs. X.XX
│   └── custom_badges.dart                  # StatusBadge, CategoryPill, FilterPill
└── screens/
    ├── main_shell.dart                     # 4-tab bottom navigation container (IndexedStack)
    ├── bills/
    │   ├── bills_screen.dart               # Order History (Pending, Completed, Cancelled tabs, dynamic subfilters, floating total pill)
    │   ├── order_card.dart                 # Order card with items breakdown, quick '+', & audit badges
    │   └── order_details_sheet.dart        # Full checkout sheet with audit log timeline, interactive Qty adjustment, discount calculator, & 2x2 payment
    ├── take_order/
    │   ├── take_order_screen.dart          # 2-column table grid + "+ Add Table" card + Stocks pill with dynamic low stock badge
    │   ├── table_card.dart                 # Table card with Occupied timer / Empty states
    │   └── menu_punch_screen.dart          # Menu item punching with 7 categories, - 0 +, and KOT bar
    ├── customers/
    │   └── customers_screen.dart           # Customers directory, search, credit khata sheet, settlement drawer, manual dues, & WhatsApp share
    ├── inventory/
    │   └── inventory_screen.dart           # 4-tab inventory module (All Stock, Low / Out, Recipes BOM, Stock Log) + Purchase & Adjust sheets
    └── analytics/
        ├── analytics_screen.dart           # 7-section analytics dashboard, dual Top vs Non leaderboards, & inventory shortcut
        └── settings_sheet.dart             # Multi-tenant branch switcher, thermal printer config (58mm/80mm, IP/BT), & reset baseline
supabase/
└── migrations/
    └── 001_saan_kot_schema.sql             # 16-table PostgreSQL migration with tenant & branch Row-Level Security (RLS) policies
test/
├── widget_test.dart                        # Bottom navigation & initial load smoke test
├── flow_test.dart                          # End-to-end table order, menu punch, discount & checkout tests
├── seed_data_audit_test.dart               # Phase 1 & 2 seed data verification suite
├── phase_3_bills_audit_test.dart           # Phase 3 Bills, anti-theft audit log, & checkout sheet verification suite
├── phase_4_customers_khata_test.dart       # Phase 4 Customers, Khata ledger, settlement engine, & staff advance test suite
├── phase_5_analytics_inventory_test.dart   # Phase 5 Analytics dashboard (7 sections), dual leaderboards, & recipe BOM engine test suite
└── phase_6_production_hardening_test.dart  # Phase 6 Thermal printing formatters, ESC/POS generator, & preview modal test suite
```

---

## 4. Current Quality & Build Metrics
- **Flutter Analyze:** 0 errors, 0 warnings, 0 infos (`No issues found!`).
- **Flutter Test:** 7 test suites passing (100% test success across all 40 test cases).
- **Compliance:** Full alignment with `AGENTS.md` and `SAAN_KOT_UI_SPEC.md`.

