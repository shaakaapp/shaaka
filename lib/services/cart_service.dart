import 'package:flutter/foundation.dart';

class CartService {
  // Global cart item count notifier for real-time badge updates across the app
  static final ValueNotifier<int> cartItemCountNotifier = ValueNotifier<int>(0);

  static void updateCount(int count) {
    cartItemCountNotifier.value = count;
  }
}
