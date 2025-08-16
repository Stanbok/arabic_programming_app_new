import 'package:flutter/material.dart';

class FloatingActionMenu extends StatefulWidget {
  final List<FloatingActionMenuItem> items;
  final Widget mainButton;
  final Color? backgroundColor;

  const FloatingActionMenu({
    Key? key,
    required this.items,
    required this.mainButton,
    this.backgroundColor,
  }) : super(key: key);

  @override
  State<FloatingActionMenu> createState() => _FloatingActionMenuState();
}

class _FloatingActionMenuState extends State<FloatingActionMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
    });
    if (_isOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...widget.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final slideAnimation = Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _controller,
                curve: Interval(
                  index * 0.1,
                  1.0,
                  curve: Curves.easeOut,
                ),
              ));

              return SlideTransition(
                position: slideAnimation,
                child: FadeTransition(
                  opacity: _controller,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: FloatingActionButton(
                      mini: true,
                      onPressed: item.onPressed,
                      backgroundColor: item.backgroundColor,
                      child: item.icon,
                    ),
                  ),
                ),
              );
            },
          );
        }).toList().reversed,
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: widget.backgroundColor,
          child: AnimatedRotation(
            turns: _isOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 300),
            child: widget.mainButton,
          ),
        ),
      ],
    );
  }
}

class FloatingActionMenuItem {
  final Widget icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;

  FloatingActionMenuItem({
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
  });
}
