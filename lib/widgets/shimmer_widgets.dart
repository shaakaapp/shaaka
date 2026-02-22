import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// ─────────────────────────────────────────────────────────────────
//  THEME HELPERS
// ─────────────────────────────────────────────────────────────────

Color _base(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFE8E8E8);

Color _highlight(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF3D3D3D)
        : const Color(0xFFF5F5F5);

// ─────────────────────────────────────────────────────────────────
//  CORE: Advanced animated shimmer wrapper
// ─────────────────────────────────────────────────────────────────

/// A custom shimmer that uses a diagonal sweeping gradient for a premium look.
/// Wraps any child with a shimmer animation that supports custom speed and direction.
class AdvancedShimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const AdvancedShimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  State<AdvancedShimmer> createState() => _AdvancedShimmerState();
}

class _AdvancedShimmerState extends State<AdvancedShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
    _animation = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _base(context),
                _highlight(context),
                _base(context),
              ],
              stops: [
                (_animation.value - 0.5).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.5).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  PRIMITIVE BUILDING BLOCKS
// ─────────────────────────────────────────────────────────────────

/// A single shimmer rectangle, used as a building block.
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _base(context),
        borderRadius: borderRadius,
      ),
    );
  }
}

/// A circular shimmer for avatars.
class ShimmerCircle extends StatelessWidget {
  final double size;
  const ShimmerCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _base(context),
        shape: BoxShape.circle,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  STAGGERED LIST ITEM — fades + slides in with a delay offset
// ─────────────────────────────────────────────────────────────────

class _StaggeredItem extends StatefulWidget {
  final int index;
  final Widget child;
  const _StaggeredItem({required this.index, required this.child});

  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    final delayed = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        (widget.index * 0.1).clamp(0.0, 0.6),
        1.0,
        curve: Curves.easeOut,
      ),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(delayed);
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(delayed);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  PRODUCT CARD SHIMMER
// ─────────────────────────────────────────────────────────────────

class ProductCardShimmer extends StatelessWidget {
  const ProductCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _base(context),
      highlightColor: _highlight(context),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _base(context),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ShimmerBox(height: 11, width: double.infinity),
            const SizedBox(height: 4),
            ShimmerBox(height: 11, width: 70),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  PRODUCT GRID SHIMMER (Sliver)
// ─────────────────────────────────────────────────────────────────

class ProductGridShimmer extends StatelessWidget {
  final int itemCount;
  const ProductGridShimmer({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(12),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68,
          crossAxisSpacing: 8,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => const ProductCardShimmer(),
          childCount: itemCount,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  STORE SHIMMER (Banner + Categories + Grid)
// ─────────────────────────────────────────────────────────────────

class StoreShimmer extends StatelessWidget {
  const StoreShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AdvancedShimmer(
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          // Banner
          SliverToBoxAdapter(
            child: Container(
              height: 220,
              margin: const EdgeInsets.only(bottom: 24),
              color: _base(context),
            ),
          ),
          // Section label
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: ShimmerBox(height: 18, width: 160),
            ),
          ),
          // Category chips row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(4, (i) {
                  return Expanded(
                    child: Container(
                      height: 90,
                      margin: EdgeInsets.only(right: i < 3 ? 10 : 0),
                      decoration: BoxDecoration(
                        color: _base(context),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          // Product grid
          const ProductGridShimmer(itemCount: 6),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  ORDER LIST SHIMMER (staggered)
// ─────────────────────────────────────────────────────────────────

class OrderListShimmer extends StatelessWidget {
  final int itemCount;
  const OrderListShimmer({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: (context, index) => _StaggeredItem(
        index: index,
        child: Shimmer.fromColors(
          baseColor: _base(context),
          highlightColor: _highlight(context),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _base(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(height: 14, width: double.infinity),
                      const SizedBox(height: 8),
                      ShimmerBox(height: 12, width: 140),
                      const SizedBox(height: 6),
                      ShimmerBox(height: 12, width: 80),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  CART ITEM SHIMMER (staggered)
// ─────────────────────────────────────────────────────────────────

class CartItemShimmer extends StatelessWidget {
  final int index;
  const CartItemShimmer({super.key, this.index = 0});

  @override
  Widget build(BuildContext context) {
    return _StaggeredItem(
      index: index,
      child: Shimmer.fromColors(
        baseColor: _base(context),
        highlightColor: _highlight(context),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: _base(context),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(height: 14, width: double.infinity),
                    const SizedBox(height: 8),
                    ShimmerBox(height: 12, width: 80),
                    const SizedBox(height: 12),
                    ShimmerBox(height: 32, width: 120, borderRadius: BorderRadius.circular(8)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  WISHLIST SHIMMER
// ─────────────────────────────────────────────────────────────────

class WishlistShimmer extends StatelessWidget {
  const WishlistShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => _StaggeredItem(
        index: index,
        child: const ProductCardShimmer(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  PROFILE SHIMMER  ← pixel-perfect mirror of ProfilePage layout
// ─────────────────────────────────────────────────────────────────

class ProfileShimmer extends StatelessWidget {
  const ProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
      ),
      body: AdvancedShimmer(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Avatar ──────────────────────────────
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: _base(context),
                        shape: BoxShape.circle,
                        border: Border.all(color: _highlight(context), width: 3),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _base(context),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Personal Info Card ───────────────────
              _shimmerCard(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldShimmer(context),
                    const SizedBox(height: 16),
                    _fieldShimmer(context),
                    const SizedBox(height: 16),
                    _fieldShimmer(context),
                    const SizedBox(height: 16),
                    ShimmerBox(height: 14, width: 180),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Address Card ─────────────────────────
              _shimmerCard(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section header row
                    Row(
                      children: [
                        ShimmerBox(height: 18, width: 180),
                        const Spacer(),
                        ShimmerBox(height: 18, width: 80),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _fieldShimmer(context),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _fieldShimmer(context)),
                        const SizedBox(width: 12),
                        Expanded(child: _fieldShimmer(context)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _fieldShimmer(context),
                    const SizedBox(height: 16),
                    _fieldShimmer(context),
                    const SizedBox(height: 16),
                    _fieldShimmer(context),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Action Buttons Row ───────────────────
              Row(
                children: [
                  Expanded(
                    child: ShimmerBox(
                      height: 48,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ShimmerBox(
                      height: 48,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmerCard(BuildContext context, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  /// Mimics a TextFormField with label + border.
  Widget _fieldShimmer(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _base(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _highlight(context), width: 1),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ShimmerBox(height: 12, width: 120),
      ),
    );
  }
}
