import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'widgets/connectivity_wrapper.dart';
import 'theme/app_theme.dart';

import 'pages/home_customer_page.dart';
import 'pages/home_vendor_page.dart';
import 'pages/home_women_merchant_page.dart';
import 'services/storage_service.dart';

// Global key for Navigator state
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global callback for theme updates
void Function(bool)? onThemeUpdateCallback;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
    // Set global callback
    onThemeUpdateCallback = _updateTheme;
  }

  @override
  void dispose() {
    onThemeUpdateCallback = null;
    super.dispose();
  }

  Future<void> _loadThemePreference() async {
    final isDark = await StorageService.getDarkMode();
    if (mounted) {
      setState(() {
        _isDarkMode = isDark;
      });
    }
  }

  void _updateTheme(bool isDark) {
    if (mounted) {
      setState(() {
        _isDarkMode = isDark;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shaaka',
      navigatorKey: navigatorKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
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
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: value,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.eco,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: const Text(
                    'Shaaka',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                      letterSpacing: 1,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
