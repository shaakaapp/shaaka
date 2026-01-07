import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'login_page.dart';
import 'profile_page.dart';
import 'store_page.dart';
import 'donations_page.dart';
import 'add_product_page.dart';

class HomeWomenMerchantPage extends StatefulWidget {
  const HomeWomenMerchantPage({super.key});

  @override
  State<HomeWomenMerchantPage> createState() => _HomeWomenMerchantPageState();
}

class _HomeWomenMerchantPageState extends State<HomeWomenMerchantPage> {
  int _selectedIndex = 0; // Default to first tab (Common Store)

  static const List<Widget> _pages = <Widget>[
    StorePage(isVendorView: false), // Common Store (Amazon style)
    StorePage(isVendorView: true), // My Business
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
              icon: const Icon(Icons.volunteer_activism),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DonationsPage(),
                  ),
                );
              },
            ),
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
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront),
              label: 'My Business',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.purple,
          onTap: _onItemTapped,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AddProductPage()),
            ).then((_) => setState(() {})); 
          },
          backgroundColor: Colors.purple,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
