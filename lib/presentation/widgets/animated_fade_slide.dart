import 'package:flutter/material.dart';

/// A reusable widget that provides fade and slide up animation
/// Similar to the animation used in the news section
class AnimatedFadeSlide extends StatefulWidget {
  final Widget child;
  final double delay;
  final Duration duration;
  final Curve curve;
  final double slideOffset;

  const AnimatedFadeSlide({
    super.key,
    required this.child,
    this.delay = 0.0,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOut,
    this.slideOffset = 0.2,
  });

  @override
  State<AnimatedFadeSlide> createState() => _AnimatedFadeSlideState();
}

class _AnimatedFadeSlideState extends State<AnimatedFadeSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.slideOffset),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // Start animation after delay
    Future.delayed(Duration(milliseconds: (widget.delay * 1000).toInt()), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(opacity: _fadeAnimation, child: widget.child),
    );
  }
}

/// A builder widget that provides staggered animations for lists
class AnimatedListBuilder extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double staggerDelay;
  final Duration itemDuration;

  const AnimatedListBuilder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.staggerDelay = 0.1,
    this.itemDuration = const Duration(milliseconds: 600),
  });

  @override
  State<AnimatedListBuilder> createState() => _AnimatedListBuilderState();
}

class _AnimatedListBuilderState extends State<AnimatedListBuilder> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        widget.itemCount,
        (index) => AnimatedFadeSlide(
          delay: index * widget.staggerDelay,
          duration: widget.itemDuration,
          child: widget.itemBuilder(context, index),
        ),
      ),
    );
  }
}

/// A simple animated switcher with fade and slide
class AnimatedSwitchFadeSlide extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const AnimatedSwitchFadeSlide({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: child,
    );
  }
}
