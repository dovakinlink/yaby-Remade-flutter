import 'package:flutter/material.dart';

/// 闪烁光标组件，用于显示AI正在思考
class ThinkingCursor extends StatefulWidget {
  const ThinkingCursor({
    super.key,
    this.color,
    this.width = 2.0,
    this.height = 16.0,
  });

  final Color? color;
  final double width;
  final double height;

  @override
  State<ThinkingCursor> createState() => _ThinkingCursorState();
}

class _ThinkingCursorState extends State<ThinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = widget.color ?? 
        (isDark ? Colors.white70 : Colors.black87);
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        );
      },
    );
  }
}

