import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/user_profile.dart';
import 'my_orders_page.dart';
import 'address_form_page.dart';

class CheckoutPage extends StatefulWidget {
  final Map<String, dynamic>? directOrderData;

  const CheckoutPage({super.key, this.directOrderData});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  List<dynamic> _savedAddresses = [];
  dynamic _selectedAddress; // Map or Object
  bool _isLoading = true;
  String? _selectedPaymentMethod = 'COD';
  UserProfile? _userProfile;
  
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

  Future<void> _loadData({dynamic newSelectedAddress}) async {
    setState(() => _isLoading = true);
    try {
      final userId = await StorageService.getUserId();
      if (userId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Fetch Addresses (Saved + Profile)
      final addressResult = await ApiService.getUserAddresses(userId);
      
      // Fetch Profile (just in case we need user details like name) - optional if addressResult has profile addr
      final profileResult = await ApiService.getProfile(userId);

      if (mounted) {
         setState(() {
           if (profileResult['success'] == true) {
             _userProfile = profileResult['data'];
           }

           if (addressResult['success'] == true) {
              final data = addressResult['data'];
              final profileAddr = data['profile_address'];
              final saved = data['saved_addresses'] as List;
              
              _savedAddresses = [if (profileAddr != null) profileAddr, ...saved];
              
              if (newSelectedAddress != null) {
                 // Try to match the newly returned address exactly from the freshly loaded list, or just use the object
                 try {
                     _selectedAddress = _savedAddresses.firstWhere((a) => a['id'] == newSelectedAddress['id']);
                 } catch (e) {
                     _selectedAddress = newSelectedAddress;
                 }
              }
              // Default select profile address or first default
              else if (_savedAddresses.isNotEmpty) {
                try {
                  _selectedAddress = _savedAddresses.firstWhere((addr) => addr['is_default'] == true);
                } catch (e) {
                  _selectedAddress = _savedAddresses.first; 
                }
              }
           }
         });
      }
    } catch (e) {
      debugPrint("Error loading checkout data: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addNewAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddressFormPage()),
    );

    if (result != null) {
      _loadData(newSelectedAddress: result); // Refresh addresses and select new one
    }
  }

  Future<void> _editAddress(Map<String, dynamic> address) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddressFormPage(initialData: address)),
    );

    if (result != null) {
      _loadData(newSelectedAddress: result); // Refresh addresses and select updated one
    }
  }

  Future<void> _deleteAddress(Map<String, dynamic> address) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final userId = await StorageService.getUserId();
      // Ensure ID is valid (int)
      if (address['id'] is int) {
         final result = await ApiService.deleteUserAddress(userId!, address['id']);
         if (result['success'] == true) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address deleted')));
            _loadData();
         } else {
            setState(() => _isLoading = false);
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${result['error']}')));
         }
      } else {
         setState(() => _isLoading = false); // Should not happen for saved addresses
      }
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

    dynamic result;
    if (widget.directOrderData != null) {
      // Merge direct order details (product_id, quantity, unit_value)
      orderData.addAll(widget.directOrderData!);
      result = await ApiService.placeDirectOrder(userId, orderData);
    } else {
      result = await ApiService.placeOrder(userId, orderData);
    }

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
                // Navigator.of(context).pop(); // REMOVED: Do not close Cart, let MyOrders sit on top of Home/Cart
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyOrdersPage(showBackButton: true)),
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
      // backgroundColor: AppTheme.softBeige,
      appBar: AppBar(
        title: const Text('Checkout'),
        elevation: 0,
      body: Responsive.centeredWebContainer(
        context,
        maxWidth: 600,
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
              ),
            )
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
                        child: Column(
                          children: [
                            RadioListTile<dynamic>(
                              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(subtitle),
                              value: addr,
                              groupValue: _selectedAddress,
                              onChanged: (val) => setState(() => _selectedAddress = val),
                              activeColor: Colors.green,
                            ),
                            // Only show actions for saved addresses, not profile default if needed (though API treats all as address objects)
                            // Assuming 'profile' ID is special or we check if it's deletable.
                            // The backend returns 'profile_address' separate from 'saved_addresses' usually, but here we merged them.
                            // Profile address has ID 'profile' which is string, others are int.
                            if (addr['id'] != 'profile') 
                              Padding(
                                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      icon: const Icon(Icons.edit, size: 16),
                                      label: const Text('Edit'),
                                      onPressed: () => _editAddress(addr),
                                      style: TextButton.styleFrom(foregroundColor: Colors.blue),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      icon: const Icon(Icons.delete, size: 16),
                                      label: const Text('Delete'),
                                      onPressed: () => _deleteAddress(addr),
                                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                          ],
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
                      onPressed: _isLoading ? null : _placeOrder,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Place Order',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}
