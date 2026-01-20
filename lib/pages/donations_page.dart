import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class DonationsPage extends StatefulWidget {
  const DonationsPage({super.key});

  @override
  State<DonationsPage> createState() => _DonationsPageState();
}

class _DonationsPageState extends State<DonationsPage> {
  final _formKey = GlobalKey<FormState>();
  String _selectedType = 'Food';
  final List<String> _donationTypes = ['Food', 'Clothes', 'Money'];
  bool _isLoading = false;

  // Controllers
  final _itemNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _pickupAddressController = TextEditingController(); // Also used for user address
  final _contactNumberController = TextEditingController(); // Also used for user mobile
  final _emailController = TextEditingController();
  final _amountController = TextEditingController();
  final _messageController = TextEditingController();

  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _itemNameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _pickupAddressController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _amountController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _selectedImage = image;
    });
  }

  Future<void> _submitDonation() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedImage == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload an image')));
       return;
    }

    setState(() => _isLoading = true);

    final userId = await StorageService.getUserId();
    if (userId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to donate')));
        return;
    }

    final Map<String, String> fields = {
      'donation_type': _selectedType,
    };

    if (_selectedType == 'Food' || _selectedType == 'Clothes') {
      fields['item_name'] = _itemNameController.text.trim();
      fields['description'] = _descriptionController.text.trim();
      fields['quantity'] = _quantityController.text.trim();
      fields['pickup_address'] = _pickupAddressController.text.trim();
      fields['contact_number'] = _contactNumberController.text.trim();
      fields['email'] = _emailController.text.trim();
    } else {
      fields['amount'] = _amountController.text.trim();
      fields['message'] = _messageController.text.trim();
    }

    final result = await ApiService.createDonation(userId, fields, _selectedImage);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Thank You!'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite, color: Colors.pink, size: 64),
              SizedBox(height: 16),
              Text('Your donation request has been submitted successfully.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      String err = result['error'] is Map ? (result['error']['error'] ?? 'Failed') : result['error'].toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donate')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Donation Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'I want to donate', border: OutlineInputBorder()),
                items: _donationTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                     setState(() {
                        _selectedType = val;
                        _selectedImage = null; // Reset image on type change
                     });
                  }
                },
              ),
              const SizedBox(height: 24),

              if (_selectedType == 'Food' || _selectedType == 'Clothes') ...[
                 TextFormField(
                   controller: _itemNameController,
                   decoration: const InputDecoration(labelText: 'Item Name * (e.g., Rice, Shirts)', border: OutlineInputBorder()),
                   validator: (v) => v!.isEmpty ? 'Required' : null,
                 ),
                 const SizedBox(height: 16),
                 TextFormField(
                   controller: _quantityController,
                   decoration: const InputDecoration(labelText: 'Quantity * (e.g., 5 kg, 2 bags)', border: OutlineInputBorder()),
                   validator: (v) => v!.isEmpty ? 'Required' : null,
                 ),
                 const SizedBox(height: 16),
                 TextFormField(
                   controller: _descriptionController,
                   decoration: const InputDecoration(labelText: 'Description *', border: OutlineInputBorder()),
                   maxLines: 3,
                   validator: (v) => v!.isEmpty ? 'Required' : null,
                 ),
                 const SizedBox(height: 16),
                 TextFormField(
                   controller: _pickupAddressController,
                   decoration: const InputDecoration(labelText: 'Pickup Address *', border: OutlineInputBorder()),
                   validator: (v) => v!.isEmpty ? 'Required' : null,
                 ),
                 const SizedBox(height: 16),
                  TextFormField(
                   controller: _contactNumberController,
                   decoration: const InputDecoration(labelText: 'Contact Number *', border: OutlineInputBorder()),
                   validator: (v) => v!.isEmpty ? 'Required' : null,
                   keyboardType: TextInputType.phone,
                 ),
                 const SizedBox(height: 16),
                 // Image Upload
                 GestureDetector(
                   onTap: _pickImage,
                   child: Container(
                     height: 150,
                     decoration: BoxDecoration(
                       border: Border.all(color: Colors.grey),
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: _selectedImage != null
                       ? Image.file(File(_selectedImage!.path), fit: BoxFit.cover)
                       : const Column(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                             Text('Add Item Image *', style: TextStyle(color: Colors.grey)),
                           ],
                         ),
                   ),
                 ),

              ] else ...[
                 // Money Donation
                 // QR Code placeholder
                 Center(
                   child: Column(
                     children: [
                        const Text('Scan to Pay via UPI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/d/d0/QR_code_for_mobile_English_Wikipedia.svg', // Placeholder QR
                          height: 200,
                          width: 200,
                        ),
                        const SizedBox(height: 5),
                        const Text('UPI ID: shaaka@upi (Example)', style: TextStyle(color: Colors.grey)),
                     ],
                   ),
                 ),
                 const SizedBox(height: 24),
                 TextFormField(
                   controller: _amountController,
                   decoration: const InputDecoration(labelText: 'Amount Paid (₹) *', border: OutlineInputBorder()),
                   validator: (v) => v!.isEmpty ? 'Required' : null,
                   keyboardType: TextInputType.number,
                 ),
                 const SizedBox(height: 16),
                  TextFormField(
                   controller: _messageController,
                   decoration: const InputDecoration(labelText: 'Message *', border: OutlineInputBorder()),
                   maxLines: 2,
                   validator: (v) => v!.isEmpty ? 'Required' : null,
                 ),
                 const SizedBox(height: 16),
                 const Text('Upload Payment Screenshot *', style: TextStyle(fontWeight: FontWeight.bold)),
                 const SizedBox(height: 8),
                 GestureDetector(
                   onTap: _pickImage,
                   child: Container(
                     height: 150,
                     decoration: BoxDecoration(
                       border: Border.all(color: Colors.grey),
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: _selectedImage != null
                       ? Image.file(File(_selectedImage!.path), fit: BoxFit.cover)
                       : const Column(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             Icon(Icons.upload_file, size: 40, color: Colors.grey),
                             Text('Tap to upload screenshot', style: TextStyle(color: Colors.grey)),
                           ],
                         ),
                   ),
                 ),
              ],

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitDonation,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading 
                   ? const CircularProgressIndicator(color: Colors.white)
                   : const Text('Submit Donation', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
