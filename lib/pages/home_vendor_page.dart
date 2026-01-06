import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'login_page.dart';
import 'profile_page.dart';
import 'store_page.dart';
import 'add_product_page.dart';

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
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Shaaka Store' : 'My Dashboard'),
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
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await StorageService.clearAll();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const LoginPage(),
                  ),
                );
              }
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
            icon: Icon(Icons.inventory),
            label: 'My Products',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        onTap: _onItemTapped,
      ),
      // Show FAB only on "My Products" tab to avoid confusion? 
      // Or allow adding from Home too? The user wants "add products" efficiently.
      // Let's keep it on My Products tab for clarity, or both? 
      // If on Home, we need to refresh My Products tab somehow or just navigate.
      floatingActionButton: FloatingActionButton(
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
      ),
    );
  }
}
