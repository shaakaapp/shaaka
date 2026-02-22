import 'package:flutter/material.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import 'product_details_page.dart';
import '../utils/responsive.dart';

class CategoryProductsPage extends StatelessWidget {
  final String category;
  final List<Product> products;

  const CategoryProductsPage({
    super.key,
    required this.category,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category),
        elevation: 0,
      ),
      body: products.isEmpty
          ? const Center(child: Text('No products found'))
          : Responsive.centeredWebContainer(
              context,
              child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: Responsive.getGridCrossAxisCount(context, mobile: 2, tablet: 4, desktop: 5),
                childAspectRatio: 0.75, // Increased from 0.7 for tighter spacing
                crossAxisSpacing: 12, // Reduced spacing
                mainAxisSpacing: 12,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return ProductCard(
                  product: products[index],
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ProductDetailsPage(product: products[index]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
    );
  }
}
