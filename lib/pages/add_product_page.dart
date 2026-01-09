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
    'Others'
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

  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

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

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty && widget.product == null) {
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

    // 1. Upload Images First
    List<String> imageUrls = [];
    for (var image in _selectedImages) {
      final uploadResult = await ApiService.uploadImage(image, type: 'product');
      if (uploadResult['success'] == true) {
        imageUrls.add(uploadResult['url']);
      } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Failed to upload image: ${uploadResult['error'] is Map ? (uploadResult['error']['error'] ?? 'Unknown error') : uploadResult['error']}')));
        }
        setState(() => _isLoading = false);
        return;
      }
    }

    // 2. Add Product with Image URLs
    final productData = {
      'vendor': userId,
      'name': _nameController.text.trim(),
      'category': _selectedCategory,
      'price': double.parse(_priceController.text.trim()),
      'unit': _selectedUnit,
      'stock_quantity': int.parse(_stockController.text.trim()),
      'description': _descriptionController.text.trim(),
      'images': imageUrls,
    };

    Map<String, dynamic> result;
    if (widget.product != null) {
        result = await ApiService.updateProduct(widget.product!.id, productData);
    } else {
        result = await ApiService.addProduct(productData);
    }

    setState(() => _isLoading = false);

    if (result['success'] == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.product != null ? 'Product Updated Successfully!' : 'Product Added Successfully!'),
          backgroundColor: Colors.green));
      Navigator.pop(context, true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(result['error'] is Map 
                ? (result['error']['error'] ?? 'Failed to add product') 
                : result['error'].toString()),
            backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.product != null ? 'Edit Product' : 'Add Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
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
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          labelText: 'Price (₹) *',
                          border: OutlineInputBorder()),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Required' : null,
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
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Stock Quantity *', border: OutlineInputBorder()),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
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
              
              // Image Picker UI
              const Text('Product Images *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _selectedImages.length) {
                      return GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: const Icon(Icons.add_a_photo, color: Colors.grey),
                        ),
                      );
                    }
                     return Stack(
                      children: [
                        Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(File(_selectedImages[index].path)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 4,
                          top: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: const CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.red,
                              child: Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
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
