# Saan KOT - Premium UI/UX & Screen Specification

## 1. Visual Design System (Premium Upgrade)
- **Brand Colors:**
  - Primary Header & Active Accents: Deep Emerald (`#059669`) with subtle gradient to (`#10B981`).
  - Secondary / Active Filter Pill: Warm Amber Orange (`#F59E0B`) for active status tabs (`Pending`, active menu categories).
  - Background: Crisp Alabaster (`#F8FAFC`) with pure white (`#FFFFFF`) elevated cards (`border-radius: 16px`, subtle border `#E2E8F0`, soft shadow).
  - Danger / Credit Due / Discount Text: Rose Red (`#E11D48`).
- **Currency & Locale:** Always format currency as `Rs. X.XX` (e.g., `Rs. 505.00`). Use tabular numerals for all price columns.
- **Bottom Navigation Bar (4 Fixed Tabs):**
  1. `Bills` (Receipt icon)
  2. `Take Order` (Storefront/Table icon)
  3. `Customers` (User profile icon)
  4. `Analytics` (Bar chart icon)

---

## 2. Screen 1: `Bills` (Order History & Checkout Bottom Sheet)
- **Top App Bar:** Emerald header with Date Picker pill on left (e.g., `08 Oct`), centered title `Order History`, and right action icons: `PDF Export` and `Refresh`.
- **Primary Status Segmented Bar:** 3 tabs inside the header: `Pending` (Amber pill when active), `Completed`, `Cancelled`.
- **Sub-Filters:**
  - On `Pending`: Search input (`Search table...`) + Sort dropdown (`By Time`).
  - On `Completed`: Horizontal filter chips (`All`, `Item Removed (0)`, `Item Unserved (0)`).
- **Order Cards:**
  - Header row: Bold `<Table/Group Name> | ORD-<Number>` (e.g., `Fancy wala | ORD-13229` or `T1 | ORD-13230`), quick `+` icon button to add more items, and 3-dot overflow menu.
  - Body: Clean list of items with `Item Name`, `xQty`, and right-aligned `Rs. Price`.
  - Footer row: Total price in bold (`Rs. 505.00`), order time (`16:56`), and an Emerald pill button `Checkout ->` (for Pending orders).
- **Floating Total Pill:** Bottom-right floating emerald badge displaying `Total: Rs 3070.00 (i)`.

### Modal Bottom Sheet: `Order Details` (Triggered on tapping an Order Card or Checkout)
- **Sheet Header:** Icon + `Order Details`, `PDF` button chip, and Close `X` button.
- **Order Metadata Card:** `# Order ID ORD-13229` with amber `PENDING` badge, `Created at <Date, Time>`, `Table : <Name>`, `Taken By : <Staff Name>` (highlighted in green badge).
- **Order Items Section:** Shows count badge (`6 Items`) and `History` button. Lists `Item | Qty (in bordered rounded box) | Total`.
- **Discount Section:**
  - Label `Discount (Rs.)` with right-aligned numeric input box.
  - Quick-tap Discount Chips below: `No Disc`, `5% Off`, `10% Off`, `- Rs. 20`, `- Rs. 50`.
- **Bill Summary Box:**
  - `Subtotal`: `Rs. 505.00`
  - `Discount`: `- Rs. 0.00` (in Rose Red)
  - `Payable Amount`: `Rs. 505.00` (in bold Emerald Green)
- **Payment Collection Grid (2x2 Selectable Cards):**
  1. `Cash` (with cash icon)
  2. `Fonepay QR` (with QR/phone icon)
  3. `eSewa / Wallet` (with wallet icon)
  4. `Customer Credit` (with credit card/user icon - selecting this prompts selecting a Customer from the Customers list)
- **Cash Calculator Box (Visible when Cash is selected):**
  - Left: `Cash Received (Optional)` and green live text `Return Change: Rs. 0.00`.
  - Right: Input field `Rs. Given`.
- **Sticky Bottom Action Row:** Outlined `Cancel Order` button (left) + Solid Emerald `Checkout` button with card icon (right).

---

## 3. Screen 2: `Take Order` (Manage Orders & Restaurant Menu)
- **Top App Bar:** Title `Manage Orders` on left; bordered pill buttons on right for `Menu`, `Stocks` (Inventory shortcut), and `Refresh`.
- **Search Bar:** `Search table...` filter bar.
- **2-Column Table & Group Grid:**
  - Supports standard tables (`T1`–`T10`), custom named customer/group tabs (`Fancy wala`, `Masu wala`, `Raj Group`, `Dipesh Vai`), and `Pack` (Takeaway).
  - **Empty Card State:** Soft tinted top header with table name, cart icon `0 Order`, service cloche illustration, and `Tap To Create Order`.
  - **Occupied Card State:** Highlighted header, cart icon `1 Order` (or KOT count), bold live total `Rs. 505.00`, elapsed timer badge, and bottom quick-action icons: `Edit/View Order (pencil)`, `Add Items (+)`, and `Print KOT`.
  - **Final Grid Item:** Dashed border card `+ Add Table` allowing staff to instantly create a new table or named customer tab.

### Sub-Screen: `Restaurant Menu` & Order Punching
- **Top App Bar:** Back button, QR/Grid view toggle, title `Restaurant Menu`, and `+ Add` button (to add a new menu item).
- **Category Bar:** Horizontal scrolling pills (`Coffee`, `Cold Beverages`, `Hookah`, `Momo & Noodles`, `Premium Hookah`) with active category highlighted in Amber Orange.
- **Menu Item Rows:** Cloche/Category icon on left, bold Item Name with inline `Edit pencil` icon, `Rs. Price` subtitle, low-stock indicator badge, and right-aligned `-  0  +` circular stepper buttons.
- **Sticky Bottom KOT Bar (Appears when items > 0):** Shows selected item count and subtotal with `"Send KOT"` and `"Save & View Bill"` buttons.

---

## 4. Screen 3: `Customers` (My Customers & Credit Khata)
- **Top App Bar:** Title `My Customers` and `Refresh` icon.
- **Search Bar:** `Search by name, phone, address...`
- **Customer List Cards:**
  - Colored circular avatar with 1–2 letter initials (`A`, `BB`, `GS`, `H`).
  - Customer Name in bold + phone icon with number below.
  - Right-aligned Credit Status: Shows muted `No Dues` badge if balance is 0, or `Total Due` label with bold red `Rs. 4890.00` if they have an outstanding credit balance.
- **Floating Action Button:** Circular green `+` FAB at bottom-right to add a new customer.

---

## 5. Screen 4: `Analytics` (Analytics Dashboard)
- **Top App Bar:** PDF report export icon on left, `Analytics Dashboard` title, and staff/profile avatar on right.
- **Section 1: Total Revenue (Bento Grid of Soft Tinted Cards):**
  - Full-width green-tinted card: `Total Amount` (`Rs. 3070.00`).
  - 2x2 Grid: `Net Amount`, `Total Discount` (pink tint), `Total Orders` (blue tint), `Avg. Order Value` (rose tint).
- **Section 2: Payment Collections (2x2 Tinted Grid):**
  - `Cash`, `Fonepay`, `Digital Wallet`, `Bank`.
- **Section 3: Credit Analytics (2x2 Grid with `Total Sales` badge):**
  - `Credit Sales`, `Credit Collected`, `Credit Discount`, `Past Dues`.
- **Section 4: Credit Collections:**
  - Breakdown of how past credit was collected (`Cash`, `Fonepay`, `Digital Wallet`, `Bank`, and full-width `Staff Credit Added to Advance`).
- **Section 5: Total Collection Summary:**
  - Full-width warm amber card for `Total Collection` (`Rs. 7360.00`) + 2x2 breakdown (`Cash`, `Fonepay`, `Digital Wallet`, `Bank`).
- **Section 6: Order Status Summary & Revenue Analysis:**
  - Status counts with colored dots (`Completed: 17`, `Pending: 1`) and date-wise revenue row.
- **Section 7: Top Categories & Top Sellings Leaderboards:**
  - Ranked list (`1` to `5` in colored square badges) showing Category/Item Name, `Revenue: Rs. XXX.XX`, and green pill badge `13 sold`. Includes `Top` vs `Non` (non-selling items) toggle switch.