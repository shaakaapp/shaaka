import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'widgets/connectivity_wrapper.dart';

import 'pages/home_customer_page.dart';
import 'pages/home_vendor_page.dart';
import 'pages/home_women_merchant_page.dart';
import 'services/storage_service.dart';

// Global key for Navigator state
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shaaka',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return ConnectivityWrapper(child: child!);
      },
      // initialRoute: '/login', // REMOVED
      home: const AuthCheck(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
      },
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final userId = await StorageService.getUserId();
    final userCategory = await StorageService.getUserCategory();

    if (!mounted) return;

    if (userId != null && userCategory != null) {
      // User is logged in, navigate to appropriate home
      Widget homePage;
      switch (userCategory) {
        case 'Customer':
          homePage = const HomeCustomerPage();
          break;
        case 'Vendor':
          homePage = const HomeVendorPage();
          break;
        case 'Women Merchant':
          homePage = const HomeWomenMerchantPage();
          break;
        default:
          homePage = const HomeCustomerPage();
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => homePage),
      );
    } else {
      // User not logged in, go to login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
