import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/user_profile.dart';
import 'my_orders_page.dart';
import 'address_form_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  UserProfile? _userProfile;
  List<dynamic> _savedAddresses = [];
  dynamic _selectedAddress; // Map or Object
  bool _isLoading = true;
  String? _selectedPaymentMethod = 'COD';
  
  // For new address form (if needed, or just specific address)
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final userId = await StorageService.getUserId();
    if (userId == null) return;

    // Fetch Addresses (Saved + Profile)
    final addressResult = await ApiService.getUserAddresses(userId);
    
    // Fetch Profile (just in case we need user details like name) - optional if addressResult has profile addr
    final profileResult = await ApiService.getProfile(userId);

    if (mounted) {
       setState(() {
         _isLoading = false;
         if (profileResult['success'] == true) {
           _userProfile = profileResult['data'];
         }

         if (addressResult['success'] == true) {
            final data = addressResult['data'];
            final profileAddr = data['profile_address'];
            final saved = data['saved_addresses'] as List;
            
            _savedAddresses = [profileAddr, ...saved];
            
            // Default select profile address or first default
            _selectedAddress = _savedAddresses.first; 
         }
       });
    }
  }

  Future<void> _addNewAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddressFormPage()),
    );

    if (result == true) {
      _loadData(); // Refresh addresses if added
    }
  }

  Future<void> _placeOrder() async {
    if (_selectedAddress == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a delivery address')));
       return;
    }

    setState(() => _isLoading = true);

    final userId = await StorageService.getUserId();
    if (userId == null) return;

    String shippingAddress = '';
    if (_selectedAddress['flat_house_building'] != null && _selectedAddress['flat_house_building'].isNotEmpty) {
      shippingAddress = '${_selectedAddress['flat_house_building']}, ${_selectedAddress['area_street_sector']}';
      if (_selectedAddress['landmark'] != null && _selectedAddress['landmark'].isNotEmpty) {
        shippingAddress += ' (Landmark: ${_selectedAddress['landmark']})';
      }
    } else {
      shippingAddress = _selectedAddress['address_line'] ?? '';
    }

    final city = _selectedAddress['town_city'] ?? _selectedAddress['city'] ?? '';

    final orderData = {
      'shipping_address': shippingAddress,
      'city': city,
      'state': _selectedAddress['state'],
      'pincode': _selectedAddress['pincode'],
      'payment_method': _selectedPaymentMethod,
    };

    final result = await ApiService.placeOrder(userId, orderData);

    setState(() => _isLoading = false);

    if (result['success'] == true && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Order Placed!'),
          content: const Icon(Icons.check_circle, color: Colors.green, size: 64),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close Checkout
                Navigator.of(context).pop(); // Close Cart
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyOrdersPage()),
                );
              },
              child: const Text('Go to My Orders'),
            ),
          ],
        ),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['error'] is Map ? (result['error']['error'] ?? 'Failed') : result['error'].toString()),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       const Text('Delivery Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                       TextButton.icon(
                         onPressed: _addNewAddress,
                         icon: const Icon(Icons.add),
                         label: const Text("Add New"),
                       )
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  ..._savedAddresses.map((addr) {
                      final title = addr['full_name'] != null && addr['full_name'].isNotEmpty 
                          ? addr['full_name'] 
                          : addr['name'] ?? 'Address';
                          
                      String addressText = '';
                      if (addr['flat_house_building'] != null && addr['flat_house_building'].isNotEmpty) {
                        addressText = '${addr['flat_house_building']}, ${addr['area_street_sector']}';
                      } else {
                        addressText = addr['address_line'] ?? '';
                      }
                      
                      final city = addr['town_city'] ?? addr['city'] ?? '';
                      final subtitle = "$addressText\n$city, ${addr['state']} - ${addr['pincode']}\n${addr['mobile_number'] ?? ''}";
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: RadioListTile<dynamic>(
                          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(subtitle),
                          value: addr,
                          groupValue: _selectedAddress,
                          onChanged: (val) => setState(() => _selectedAddress = val),
                          activeColor: Colors.green,
                        ),
                      );
                  }).toList(),
                  
                  const SizedBox(height: 24),
                  const Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  RadioListTile<String>(
                    title: const Text('Cash on Delivery (COD)'),
                    value: 'COD',
                    groupValue: _selectedPaymentMethod,
                    onChanged: (val) => setState(() => _selectedPaymentMethod = val),
                  ),
                  RadioListTile<String>(
                    title: const Text('Online Payment (Coming Soon)'),
                    value: 'Online',
                    groupValue: _selectedPaymentMethod,
                    onChanged: null, // Disabled
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _placeOrder,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text('Place Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
