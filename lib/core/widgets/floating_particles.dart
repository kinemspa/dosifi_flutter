import 'dart:math' as math;
import 'package:flutter/material.dart';

class FloatingParticles extends StatefulWidget {
  final int particleCount;
  final Color particleColor;
  final double minSize;
  final double maxSize;
  final Duration animationDuration;

  const FloatingParticles({
    super.key,
    this.particleCount = 15,
    this.particleColor = const Color(0x33FFFFFF),
    this.minSize = 4.0,
    this.maxSize = 12.0,
    this.animationDuration = const Duration(seconds: 20),
  });

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<Offset>> _animations;
  late List<double> _particleSizes;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controllers = [];
    _animations = [];
    _particleSizes = [];

    for (int i = 0; i < widget.particleCount; i++) {
      final controller = AnimationController(
        duration: Duration(
          milliseconds: widget.animationDuration.inMilliseconds + 
            _random.nextInt(5000) - 2500,
        ),
        vsync: this,
      );

      final animation = Tween<Offset>(
        begin: Offset(
          _random.nextDouble() * 2 - 1,
          1.2,
        ),
        end: Offset(
          _random.nextDouble() * 2 - 1,
          -1.2,
        ),
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.linear,
      ));

      final size = widget.minSize + 
        _random.nextDouble() * (widget.maxSize - widget.minSize);

      _controllers.add(controller);
      _animations.add(animation);
      _particleSizes.add(size);

      // Start animation with random delay
      Future.delayed(Duration(milliseconds: _random.nextInt(3000)), () {
        if (mounted) {
          controller.repeat();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: Stack(
          children: List.generate(widget.particleCount, (index) {
            return AnimatedBuilder(
              animation: _animations[index],
              builder: (context, child) {
                return Positioned(
                  left: MediaQuery.of(context).size.width * 
                    (_animations[index].value.dx + 1) / 2,
                  top: MediaQuery.of(context).size.height * 
                    (_animations[index].value.dy + 1) / 2,
                  child: Container(
                    width: _particleSizes[index],
                    height: _particleSizes[index],
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.particleColor,
                      boxShadow: [
                        BoxShadow(
                          color: widget.particleColor,
                          blurRadius: _particleSizes[index] / 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
