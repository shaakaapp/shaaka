import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/product.dart';

class AddProductPage extends StatefulWidget {
  final Product? product;

  const AddProductPage({super.key, this.product});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'Vegetables';
  final List<String> _categories = [
    'Fruits', 
    'Vegetables', 
    'Dairy', 
    'Grains', 
    'Spices', 
    'Veg starters', 
    'Non Veg starters',
    'Biryani', 
    'Pulao', 
    'Veg thali', 
    'Non veg Thali', 
    'Sweets', 
    'Snacks', 
    'Dry fruits', 
    'Tiffins', 
    'Drinks', 
    'Desserts', 
    'Millets',
    'Pulses',
    'Flours',
    'Tea Powders',
    'Rice',
    'Oils'
  ];

  String _selectedUnit = 'kg';
  final List<String> _units = [
    'kg',
    'g',
    'l',
    'ml',
    'pcs',
    'dozen',
    'box',
    'pack',
    'plate',
    'bunch'
  ];

  final List<String> _existingImageUrls = [];
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  // Variant Logic
  bool _hasVariants = false;
  List<Map<String, dynamic>> _variantsList = []; // {quantity, unit, price}

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _priceController.text = widget.product!.price.toString();
      _stockController.text = widget.product!.stockQuantity.toString();
      _descriptionController.text = widget.product!.description ?? '';
      _selectedUnit = widget.product!.unit;
      
      // Ensure category exists in list, else default or add
      if (_categories.contains(widget.product!.category)) {
        _selectedCategory = widget.product!.category;
      }
      
      // Load existing images
      for (var img in widget.product!.images) {
          _existingImageUrls.add(img.imageUrl);
      }
      
      // Load Variants
      if (widget.product!.variants.isNotEmpty) {
        _hasVariants = true;
        for (var v in widget.product!.variants) {
          _variantsList.add({
            'quantity': v.quantity,
            'unit': v.unit,
            'price': v.price,
            'stock_quantity': v.stockQuantity,
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate variants existence if tiered pricing is selected
    if (_hasVariants && _variantsList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one variant'), backgroundColor: Colors.red));
      return;
    }

    if (_selectedImages.isEmpty && _existingImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one image')));
      return;
    }

    setState(() => _isLoading = true);

    final userId = await StorageService.getUserId();
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Session Error. Please login again.')));
      }
      setState(() => _isLoading = false);
      return;
    }

    // 1. Upload Images First (Parallel)
    print("Starting image uploads...");
    List<String> newImageUrls = [];
    
    // Create futures for all uploads
    List<Future<Map<String, dynamic>>> uploadFutures = _selectedImages
        .map((image) => ApiService.uploadImage(image, type: 'product'))
        .toList();

    try {
      final results = await Future.wait(uploadFutures);
      
      for (int i = 0; i < results.length; i++) {
        final uploadResult = results[i];
        if (uploadResult['success'] == true) {
          newImageUrls.add(uploadResult['url']);
        } else {
           print("Upload failed: ${uploadResult['error']}");
           throw Exception(uploadResult['error'] is Map ? (uploadResult['error']['error'] ?? 'Unknown error') : uploadResult['error']);
        }
      }
      print("All images uploaded successfully. URLs: $newImageUrls");

      // Combine existing and new images
      final allImageUrls = [..._existingImageUrls, ...newImageUrls];

      // 2. Add Product with Image URLs
      // Determine price safely
      double price;
      if (_hasVariants) {
        // Use the price of the first variant as the display price
        price = _variantsList.isNotEmpty 
            ? (_variantsList.first['price'] is num ? (_variantsList.first['price'] as num).toDouble() : 0.0) 
            : 0.0;
      } else {
        price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      }

      final productData = {
        'vendor': userId,
        'name': _nameController.text.trim(),
        'category': _selectedCategory,
        'price': price,
        'unit': _selectedUnit,
        'stock_quantity': _hasVariants 
            ? _variantsList.fold<double>(0, (sum, item) => sum + (item['stock_quantity'] ?? 0))
            : (double.tryParse(_stockController.text.trim()) ?? 0.0),
        'description': _descriptionController.text.trim(),
        'images': allImageUrls,
      };

      if (_hasVariants) {
        productData['variants'] = _variantsList;
      }

      Map<String, dynamic> result;
      print("Calling API with data: ${productData['name']}, Variants: ${_hasVariants ? _variantsList.length : 0}");
      
      if (widget.product != null) {
          result = await ApiService.updateProduct(widget.product!.id, productData);
      } else {
          result = await ApiService.addProduct(productData);
      }
      print("API Response: $result");

      if (mounted) {
        setState(() => _isLoading = false);
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(widget.product != null ? 'Product Updated Successfully!' : 'Product Added Successfully!'),
              backgroundColor: Colors.green));
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(result['error'] is Map 
                  ? (result['error']['error'] ?? 'Failed to add product') 
                  : result['error'].toString()),
              backgroundColor: Colors.red));
        }
      }

    } catch (e, stack) {
      print("Exception during addProduct: $e\n$stack");
      if (mounted) {
         setState(() => _isLoading = false);
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('An error occurred: $e'), 
            backgroundColor: Colors.red
         ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Row(
        children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/logo.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(widget.product != null ? 'Edit Product' : 'Add Product'),
        ],
      )),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: 'Product Name *', border: OutlineInputBorder()),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
                decoration: const InputDecoration(
                    labelText: 'Category *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              
              const SizedBox(height: 16),

              // Pricing Toggle
              // Pricing Type Selection
              const Text('Pricing Type: ', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                   Radio<bool>(
                     value: false, 
                     groupValue: _hasVariants, 
                     onChanged: (val) => setState(() => _hasVariants = val!),
                   ),
                   const Text('Standard'),
                   const SizedBox(width: 16), // Spacing between options
                   Radio<bool>(
                     value: true, 
                     groupValue: _hasVariants, 
                     onChanged: (val) => setState(() => _hasVariants = val!),
                   ),
                   const Text('Tiered (Variants)'),
                ],
              ),
              const SizedBox(height: 8),

              if (!_hasVariants) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                              labelText: 'Price (₹) *',
                              border: OutlineInputBorder()),
                          validator: (val) {
                            if (!_hasVariants && (val == null || val.isEmpty)) return 'Required';
                            final n = int.tryParse(val ?? '');
                            if (n != null && n < 1) return 'Must be ≥ 1';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedUnit,
                          items: _units
                              .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedUnit = val!),
                          decoration: const InputDecoration(
                              labelText: 'Unit *', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
              ] else ...[
                  // Variants UI
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[50],
                    ),
                    child: Column(
                      children: [
                         ..._variantsList.asMap().entries.map((entry) {
                           int idx = entry.key;
                           Map<String, dynamic> variant = entry.value;
                           return Padding(
                             padding: const EdgeInsets.only(bottom: 12.0),
                             child: Container(
                               padding: const EdgeInsets.all(12),
                               decoration: BoxDecoration(
                                 color: Colors.white,
                                 borderRadius: BorderRadius.circular(8),
                                 border: Border.all(color: Colors.grey.shade300),
                               ),
                               child: Column(
                                 children: [
                                   Row(
                                     children: [
                                       Expanded(
                                         child: TextFormField(
                                           initialValue: variant['quantity'].toString(),
                                           keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                           decoration: const InputDecoration(labelText: 'Qty', isDense: true, border: OutlineInputBorder()),
                                           onChanged: (val) => variant['quantity'] = double.tryParse(val) ?? 0,
                                         ),
                                       ),
                                       const SizedBox(width: 8),
                                       Expanded(
                                         child: DropdownButtonFormField<String>(
                                           value: _units.contains(variant['unit']) ? variant['unit'] : _units.first,
                                           isExpanded: true,
                                           decoration: const InputDecoration(
                                             labelText: 'Unit', 
                                             isDense: true, 
                                             contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                             border: OutlineInputBorder()
                                           ),
                                           items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u, overflow: TextOverflow.ellipsis))).toList(),
                                           onChanged: (val) => variant['unit'] = val,
                                         ),
                                       ),
                                       IconButton(
                                         icon: const Icon(Icons.delete, color: Colors.red),
                                         onPressed: () => setState(() => _variantsList.removeAt(idx)),
                                       ),
                                     ],
                                   ),
                                   const SizedBox(height: 12),
                                   Row(
                                     children: [
                                       Expanded(
                                         child: TextFormField(
                                           initialValue: variant['price'].toString(),
                                           keyboardType: TextInputType.number,
                                           inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                           decoration: const InputDecoration(labelText: 'Price (₹)', isDense: true, border: OutlineInputBorder()),
                                           onChanged: (val) => variant['price'] = int.tryParse(val) ?? 0,
                                           validator: (val) {
                                             if (val == null || val.isEmpty) return 'Required';
                                             final n = int.tryParse(val);
                                             if (n == null || n < 1) return 'Must be ≥ 1';
                                             return null;
                                           },
                                         ),
                                       ),
                                       const SizedBox(width: 8),
                                       Expanded(
                                         child: TextFormField(
                                           initialValue: (variant['stock_quantity'] ?? 0).toString(),
                                           keyboardType: TextInputType.number,
                                           inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                           decoration: const InputDecoration(labelText: 'Stock', isDense: true, border: OutlineInputBorder()),
                                           onChanged: (val) => variant['stock_quantity'] = int.tryParse(val) ?? 0,
                                           validator: (val) {
                                             if (val == null || val.isEmpty) return 'Required';
                                             final n = int.tryParse(val);
                                             if (n == null || n < 1) return 'Must be ≥ 1';
                                             return null;
                                           },
                                         ),
                                       ),
                                       // Placeholder to align with the delete button above
                                       const SizedBox(width: 48),
                                     ],
                                   ),
                                 ],
                               ),
                             ),
                           );
                         }).toList(),
                         
                         OutlinedButton.icon(
                           onPressed: () {
                             setState(() {
                               _variantsList.add({'quantity': 1, 'unit': 'kg', 'price': 0, 'stock_quantity': 0});
                             });
                           },
                           icon: const Icon(Icons.add),
                           label: const Text('Add Variant'),
                         ),
                      ],
                    ),
                  ),
                  // Hidden Price Controller for base price logic if needed, 
                  // or we enforce at least one variant and use its price.
                  if (_variantsList.isEmpty)
                     const Padding(
                       padding: EdgeInsets.only(top: 4.0),
                       child: Text('Please add at least one variant', style: TextStyle(color: Colors.red, fontSize: 12)),
                     ),
              ],
              const SizedBox(height: 16),
              
              if (!_hasVariants)
                TextFormField(
                  controller: _stockController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                      labelText: 'Stock Quantity *', border: OutlineInputBorder()),
                  validator: (val) {
                    if (!_hasVariants && (val == null || val.isEmpty)) return 'Required';
                    final n = int.tryParse(val ?? '');
                    if (n != null && n < 1) return 'Must be ≥ 1';
                    return null;
                  },
                ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Description *',
                    border: OutlineInputBorder()),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              
              // Image Picker
              const Text('Images', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Existing Images
                    ..._existingImageUrls.asMap().entries.map((entry) {
                      int idx = entry.key;
                      String url = entry.value;
                      return Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(url, fit: BoxFit.cover)),
                          ),
                          Positioned(
                            top: 0,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => _removeExistingImage(idx),
                              child: const CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.red,
                                child: Icon(Icons.close,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                    
                    // New Selected Images
                    ..._selectedImages.asMap().entries.map((entry) {
                      int idx = entry.key;
                      XFile file = entry.value;
                      return Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(File(file.path), fit: BoxFit.cover)),
                          ),
                          Positioned(
                            top: 0,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => _removeImage(idx),
                              child: const CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.red,
                                child: Icon(Icons.close,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                    
                    // Add Button
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: const Icon(Icons.add_a_photo,
                            size: 40, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _addProduct,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(widget.product != null ? 'Update Product' : 'Add Product'),
              ),
              if (widget.product != null) ...[
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _isLoading ? null : _confirmDelete,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.red),
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Delete Product'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProduct();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct() async {
    setState(() => _isLoading = true);

    final result = await ApiService.deleteProduct(widget.product!.id);

    setState(() => _isLoading = false);

    if (result['success'] == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Product Deleted Successfully!'),
          backgroundColor: Colors.green));
      Navigator.pop(context, true); // Return true to refresh list
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(result['error'] is Map
                ? (result['error']['error'] ?? 'Failed to delete product')
                : result['error'].toString()),
            backgroundColor: Colors.red));
      }
    }
  }
}
