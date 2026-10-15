// Inside lib/screens/bills/bills_screen.dart AppBar container
PreferredSizeWidget buildHeader(BuildContext context) {
  return AppBar(
    backgroundColor: const Color(0xFF26B14C),
    title: Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFF58216),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '08 Oct',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Expanded(
          child: Text(
            'Order History',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () {},
        ),
      ],
    ),
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(48),
      child: Container(
        color: const Color(0xFF26B14C),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: ['Pending', 'Completed', 'Cancelled'].map((tab) {
            final isSelected = _selectedTab == tab;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = tab),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFF58216)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tab,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    ),
  );
}
