import 'package:flutter/material.dart';

class EnhancedLoadingWidget extends StatefulWidget {
  final String? message;
  final bool showProgress;
  final double? progress;
  final Color? color;
  final double size;
  final LoadingType type;

  const EnhancedLoadingWidget({
    super.key,
    this.message,
    this.showProgress = false,
    this.progress,
    this.color,
    this.size = 40.0,
    this.type = LoadingType.circular,
  });

  @override
  State<EnhancedLoadingWidget> createState() => _EnhancedLoadingWidgetState();
}

class _EnhancedLoadingWidgetState extends State<EnhancedLoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
    
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
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLoadingIndicator(),
            if (widget.message != null) ...[
              const SizedBox(height: 16),
              Text(
                widget.message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: widget.color ?? Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (widget.showProgress && widget.progress != null) ...[
              const SizedBox(height: 12),
              _buildProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    
    switch (widget.type) {
      case LoadingType.circular:
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        );
      
      case LoadingType.dots:
        return _buildDotsIndicator(color);
      
      case LoadingType.pulse:
        return _buildPulseIndicator(color);
      
      case LoadingType.wave:
        return _buildWaveIndicator(color);
    }
  }

  Widget _buildDotsIndicator(Color color) {
    return SizedBox(
      width: widget.size,
      height: widget.size / 3,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final delay = index * 0.2;
              final animationValue = (_controller.value - delay).clamp(0.0, 1.0);
              final scale = 0.5 + (0.5 * (1 - (animationValue - 0.5).abs() * 2));
              
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.size / 6,
                  height: widget.size / 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildPulseIndicator(Color color) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3 + 0.7 * _controller.value),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: widget.size * 0.6,
              height: widget.size * 0.6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaveIndicator(Color color) {
    return SizedBox(
      width: widget.size,
      height: widget.size / 2,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(4, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final delay = index * 0.1;
              final animationValue = (_controller.value + delay) % 1.0;
              final height = widget.size / 4 + (widget.size / 4 * animationValue);
              
              return Container(
                width: widget.size / 8,
                height: height,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(widget.size / 16),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      width: 200,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: widget.progress,
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

enum LoadingType {
  circular,
  dots,
  pulse,
  wave,
}

class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? loadingMessage;
  final LoadingType loadingType;
  final Color? backgroundColor;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.loadingMessage,
    this.loadingType = LoadingType.circular,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: backgroundColor ?? Colors.black.withOpacity(0.3),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: EnhancedLoadingWidget(
                  message: loadingMessage,
                  type: loadingType,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.grey[300]!,
                  Colors.grey[100]!,
                  Colors.grey[300]!,
                ],
                stops: [
                  (_animation.value - 0.3).clamp(0.0, 1.0),
                  _animation.value.clamp(0.0, 1.0),
                  (_animation.value + 0.3).clamp(0.0, 1.0),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class LessonCardSkeleton extends StatelessWidget {
  const LessonCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(width: double.infinity, height: 20),
          SizedBox(height: 8),
          SkeletonLoader(width: 150, height: 16),
          SizedBox(height: 12),
          SkeletonLoader(width: 100, height: 12),
        ],
      ),
    );
  }
}
