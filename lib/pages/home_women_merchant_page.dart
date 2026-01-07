import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'login_page.dart';
import 'profile_page.dart';
import 'store_page.dart';
import 'donations_page.dart';
import 'add_product_page.dart';
import 'cart_page.dart';
import 'my_orders_page.dart';

class HomeWomenMerchantPage extends StatefulWidget {
  const HomeWomenMerchantPage({super.key});

  @override
  State<HomeWomenMerchantPage> createState() => _HomeWomenMerchantPageState();
}


class _HomeWomenMerchantPageState extends State<HomeWomenMerchantPage> {
  int _selectedIndex = 0; // Default to first tab (Common Store)
  int _refreshKey = 0;

  List<Widget> get _pages => <Widget>[
    StorePage(key: ValueKey('store_$_refreshKey'), isVendorView: false), // Common Store
    StorePage(key: ValueKey('my_business_$_refreshKey'), isVendorView: true), // My Business (My Products)
    CartPage(key: ValueKey('cart_$_refreshKey')),
    MyOrdersPage(key: ValueKey('orders_$_refreshKey')),
    const DonationsPage(), 
  ];

  void _refreshPages() {
    setState(() {
      _refreshKey++;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _refreshKey++; // Refresh when switching tabs
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
              icon: Icon(Icons.storefront),
              label: 'My Business',
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
          selectedItemColor: Colors.purple,
          onTap: _onItemTapped,
        ),
        floatingActionButton: _selectedIndex == 1 ? FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AddProductPage()),
            ).then((value) {
                 _refreshPages();
            }); 
          },
          backgroundColor: Colors.purple,
          child: const Icon(Icons.add),
        ) : null,
      ),
    );
  }
}
