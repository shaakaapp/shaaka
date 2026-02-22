import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// ─────────────────────────────────────────────────────────────────
//  COLOR PALETTE  (high-contrast for maximum shimmer visibility)
// ─────────────────────────────────────────────────────────────────

Color _base(BuildContext ctx) =>
    Theme.of(ctx).brightness == Brightness.dark
        ? const Color(0xFF252525)
        : const Color(0xFFE6E6E6);

Color _highlight(BuildContext ctx) =>
    Theme.of(ctx).brightness == Brightness.dark
        ? const Color(0xFF4A4A4A)
        : const Color(0xFFFFFFFF); // pure white — maximum contrast

// ─────────────────────────────────────────────────────────────────
//  CORE: combined sweep + pulse shimmer
// ─────────────────────────────────────────────────────────────────

/// Wraps child in a shimmer sweep AND a subtle breathing pulse.
/// The sweep produces the classic left-to-right glint.
/// The pulse keeps the element feeling "alive" between sweeps.
class _ShimmerPulse extends StatefulWidget {
  final Widget child;
  const _ShimmerPulse({required this.child});

  @override
  State<_ShimmerPulse> createState() => _ShimmerPulseState();
}

class _ShimmerPulseState extends State<_ShimmerPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _base(context),
      highlightColor: _highlight(context),
      period: const Duration(milliseconds: 1100),
      direction: ShimmerDirection.ltr,
      child: FadeTransition(opacity: _opacity, child: widget.child),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  STAGGERED ENTRANCE for lists
// ─────────────────────────────────────────────────────────────────

class _Stagger extends StatefulWidget {
  final int index;
  final Widget child;
  const _Stagger({required this.index, required this.child});

  @override
  State<_Stagger> createState() => _StaggerState();
}

class _StaggerState extends State<_Stagger>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450))
      ..forward();
    final curve = CurvedAnimation(
      parent: _c,
      curve: Interval(
          (widget.index * 0.08).clamp(0.0, 0.5), 1.0,
          curve: Curves.easeOut),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(curve);
    _slide =
        Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
            .animate(curve);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child),
      );
}

// ─────────────────────────────────────────────────────────────────
//  PRIMITIVE BLOCK  (rounded rectangle placeholder)
// ─────────────────────────────────────────────────────────────────

class _Block extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const _Block({this.width, required this.height, this.radius = 6});

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: _base(context),
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────
//  "TEXT LINE" GROUPS  (title + body lines at varying widths)
// ─────────────────────────────────────────────────────────────────

class _TextLines extends StatelessWidget {
  final List<double> widths; // fractions of available width, 0‥1
  final double lineHeight;
  final double spacing;

  const _TextLines({
    required this.widths,
    this.lineHeight = 12.0,
    this.spacing = 6.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final maxW = constraints.maxWidth;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < widths.length; i++) ...[
            if (i > 0) SizedBox(height: spacing),
            _Block(width: maxW * widths[i], height: lineHeight, radius: 5),
          ],
        ],
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────
//  PRODUCT CARD SHIMMER
// ─────────────────────────────────────────────────────────────────

class ProductCardShimmer extends StatelessWidget {
  const ProductCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return _ShimmerPulse(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image area with subtle inner gradient tint
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _base(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _base(context),
                          _base(context).withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Product name (2 lines, second shorter)
            _Block(width: double.infinity, height: 11, radius: 5),
            const SizedBox(height: 4),
            _Block(width: 80, height: 11, radius: 5),
            const SizedBox(height: 6),
            // Price + add button row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Block(width: 60, height: 14, radius: 5),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: _base(context),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  PRODUCT GRID SHIMMER (sliver)
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
          (_, i) => _Stagger(index: i, child: const ProductCardShimmer()),
          childCount: itemCount,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  STORE SHIMMER  (search bar + banner + categories + grid)
// ─────────────────────────────────────────────────────────────────

class StoreShimmer extends StatelessWidget {
  const StoreShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        // Search bar
        SliverToBoxAdapter(
          child: _ShimmerPulse(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              height: 50,
              decoration: BoxDecoration(
                color: _base(context),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
        // Full-width banner
        SliverToBoxAdapter(
          child: _ShimmerPulse(
            child: Container(
              height: 220,
              color: _base(context),
              margin: const EdgeInsets.only(bottom: 24),
            ),
          ),
        ),
        // Section title
        SliverToBoxAdapter(
          child: _ShimmerPulse(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _Block(width: 160, height: 18, radius: 6),
            ),
          ),
        ),
        // Category tiles (4 columns)
        SliverToBoxAdapter(
          child: _ShimmerPulse(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(4, (i) {
                  return Expanded(
                    child: _Stagger(
                      index: i,
                      child: Container(
                        height: 90,
                        margin: EdgeInsets.only(right: i < 3 ? 10 : 0),
                        decoration: BoxDecoration(
                          color: _base(context),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        // Section title 2
        SliverToBoxAdapter(
          child: _ShimmerPulse(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _Block(width: 130, height: 18, radius: 6),
            ),
          ),
        ),
        // Product grid
        const ProductGridShimmer(itemCount: 6),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  ORDER LIST SHIMMER
// ─────────────────────────────────────────────────────────────────

class OrderListShimmer extends StatelessWidget {
  final int itemCount;
  const OrderListShimmer({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: itemCount,
      itemBuilder: (context, index) => _Stagger(
        index: index,
        child: _ShimmerPulse(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _base(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product thumbnail
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _base(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Block(width: double.infinity, height: 14, radius: 5),
                      const SizedBox(height: 6),
                      _Block(width: 160, height: 12, radius: 5),
                      const SizedBox(height: 10),
                      // Status badge placeholder
                      Container(
                        height: 24,
                        width: 90,
                        decoration: BoxDecoration(
                          color: _base(context),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow icon placeholder
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _base(context),
                    shape: BoxShape.circle,
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
//  CART ITEM SHIMMER
// ─────────────────────────────────────────────────────────────────

class CartItemShimmer extends StatelessWidget {
  final int index;
  const CartItemShimmer({super.key, this.index = 0});

  @override
  Widget build(BuildContext context) {
    return _Stagger(
      index: index,
      child: _ShimmerPulse(
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Image
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _base(context),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Block(width: double.infinity, height: 14, radius: 5),
                    const SizedBox(height: 6),
                    _Block(width: 90, height: 12, radius: 5),
                    const SizedBox(height: 14),
                    // Quantity stepper placeholder
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _base(context),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _Block(width: 24, height: 16, radius: 4),
                        const SizedBox(width: 8),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _base(context),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Delete icon placeholder
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _base(context),
                  shape: BoxShape.circle,
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
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (_, i) => _Stagger(index: i, child: const ProductCardShimmer()),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  PROFILE SHIMMER  (full page)
// ─────────────────────────────────────────────────────────────────

class ProfileShimmer extends StatelessWidget {
  const ProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), elevation: 0),
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Avatar ──────────────────────────────────
            _ShimmerPulse(
              child: Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: _base(context),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _base(context),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Name + role tag under avatar
            _ShimmerPulse(
              child: Center(
                child: Column(
                  children: [
                    _Block(width: 140, height: 14, radius: 6),
                    const SizedBox(height: 6),
                    _Block(width: 80, height: 11, radius: 12),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Personal info card ───────────────────────
            _shimmerCard(
              context,
              header: 'Personal Information',
              child: Column(
                children: [
                  _fieldRow(context, icon: true),
                  const SizedBox(height: 14),
                  _fieldRow(context, icon: true),
                  const SizedBox(height: 14),
                  _fieldRow(context, icon: true),
                  const SizedBox(height: 14),
                  // Category badge
                  Row(children: [
                    _Block(width: 80, height: 12, radius: 5),
                    const SizedBox(width: 8),
                    Container(
                      height: 22,
                      width: 70,
                      decoration: BoxDecoration(
                        color: _base(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Address card ─────────────────────────────
            _shimmerCard(
              context,
              header: 'Address',
              child: Column(
                children: [
                  _fieldRow(context, icon: false, fullWidth: true),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _fieldRow(context, icon: false, fullWidth: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _fieldRow(context, icon: false, fullWidth: true)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _fieldRow(context, icon: false, fullWidth: true),
                  const SizedBox(height: 14),
                  _fieldRow(context, icon: false, fullWidth: true),
                  const SizedBox(height: 14),
                  _Block(width: double.infinity, height: 44, radius: 10),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Action row ───────────────────────────────
            _ShimmerPulse(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: _base(context),
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: _base(context),
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerCard(BuildContext ctx,
      {required String header, required Widget child}) {
    return _ShimmerPulse(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(ctx).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Block(
                width: header.length * 7.5,
                height: 15,
                radius: 6),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _fieldRow(BuildContext ctx,
      {required bool icon, bool fullWidth = false}) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _base(ctx),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(ctx).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          if (icon) ...[
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Theme.of(ctx).brightness == Brightness.dark
                    ? const Color(0xFF3A3A3A)
                    : const Color(0xFFD0D0D0),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
          ],
          _Block(
            width: fullWidth ? null : math.Random().nextDouble() * 60 + 80,
            height: 11,
            radius: 4,
          ),
        ],
      ),
    );
  }
}
