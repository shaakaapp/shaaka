import 'package:flutter/material.dart';
import 'profile_page.dart';
import 'store_page.dart';
import 'donations_page.dart';
import 'add_product_page.dart';
import 'cart_page.dart';
import 'my_orders_page.dart';

class HomeVendorPage extends StatefulWidget {
  const HomeVendorPage({super.key});

  @override
  State<HomeVendorPage> createState() => _HomeVendorPageState();
}

class _HomeVendorPageState extends State<HomeVendorPage> {
  int _selectedIndex = 0; // Default to first tab (Common Store)

  static const List<Widget> _pages = <Widget>[
    StorePage(isVendorView: false), // Common Store (Amazon style)
    StorePage(isVendorView: true), // My Products
    CartPage(),
    MyOrdersPage(),
    DonationsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  DateTime? _lastPressedAt;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final now = DateTime.now();
        if (_lastPressedAt == null || 
            now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
          _lastPressedAt = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Shaaka'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProfilePage(),
                  ),
                );
              },
            ),
          ],
        ),
        body: _pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed, // Needed for more than 3 items
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Store',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory),
              label: 'My Products',
            ),
             BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
             BottomNavigationBarItem(
              icon: Icon(Icons.list_alt),
              label: 'My Orders',
            ),
             BottomNavigationBarItem(
              icon: Icon(Icons.volunteer_activism),
              label: 'Donations',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.green,
          onTap: _onItemTapped,
        ),
        // Show FAB only on "My Products" tab
        floatingActionButton: _selectedIndex == 1 ? FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AddProductPage()),
            ).then((value) {
                if (value == true) {
                     setState(() {});
                }
            });
          },
          backgroundColor: Colors.green,
          child: const Icon(Icons.add),
        ) : null,
      ),
    );
  }
}
