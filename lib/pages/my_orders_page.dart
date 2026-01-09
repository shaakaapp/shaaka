import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/cart_order_models.dart';
import 'order_detail_page.dart';

class MyOrdersPage extends StatefulWidget {
  final bool showBackButton;
  const MyOrdersPage({super.key, this.showBackButton = false});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  List<Order> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final userId = await StorageService.getUserId();
    if (userId == null) return;

    final result = await ApiService.getOrders(userId);
    if (mounted) {
      if (result['success'] == true) {
        setState(() {
          _orders = result['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        // Handle error
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Placed': return Colors.blue;
      case 'Processing': return Colors.orange;
      case 'Shipped': return Colors.purple;
      case 'Delivered': return Colors.green;
      case 'Cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        automaticallyImplyLeading: false, // customized leading override
        leading: widget.showBackButton 
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                   Navigator.of(context).popUntil((route) => route.isFirst);
                },
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(child: Text('No orders yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        onTap: () {
                           Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderDetailPage(orderId: order.id),
                            ),
                          );
                        },
                        title: Text('Order #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(DateFormat('MMM dd, yyyy').format(order.createdAt)),
                            Text('₹${order.totalAmount.toStringAsFixed(2)}'),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(order.status, style: const TextStyle(color: Colors.white, fontSize: 12)),
                          backgroundColor: _getStatusColor(order.status),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
