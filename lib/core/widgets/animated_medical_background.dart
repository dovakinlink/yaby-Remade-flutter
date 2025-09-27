import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class AnimatedMedicalBackground extends StatefulWidget {
  const AnimatedMedicalBackground({
    super.key,
    this.baseColor = const Color(0xFF36CAC4),
    this.density = 1.4,
    this.showHelix = true,
  });

  final Color baseColor;
  final double density;
  final bool showHelix;

  @override
  State<AnimatedMedicalBackground> createState() => _AnimatedMedicalBackgroundState();
}

class _AnimatedMedicalBackgroundState extends State<AnimatedMedicalBackground>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;
  final Random _random = Random();

  double _elapsed = 0;
  double _lastTick = 0;
  Size _canvasSize = Size.zero;
  double _lastDensity = 0;
  bool _isPaused = false;

  List<_Particle> _particles = <_Particle>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _isPaused = true;
    } else if (state == AppLifecycleState.resumed) {
      _isPaused = false;
      _lastTick = 0;
    }
  }

  void _onTick(Duration elapsed) {
    if (!mounted || _isPaused || _canvasSize == Size.zero) {
      return;
    }

    final double seconds = elapsed.inMicroseconds / 1e6;
    double dt = seconds - _lastTick;
    if (dt <= 0) {
      return;
    }

    // Clamp delta time to avoid large jumps when app resumes.
    dt = dt.clamp(0.0, 0.05);

    _updateParticles(dt);
    _lastTick = seconds;

    setState(() {
      _elapsed += dt;
    });
  }

  void _ensureParticles(Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    final bool sizeChanged = (_canvasSize.width - size.width).abs() > 0.5 ||
        (_canvasSize.height - size.height).abs() > 0.5;
    final bool densityChanged = (_lastDensity - widget.density).abs() > 0.01;

    if (_particles.isEmpty || sizeChanged || densityChanged) {
      _canvasSize = size;
      _lastDensity = widget.density;
      _particles = _createParticles(size, widget.density);
      _elapsed = 0;
      _lastTick = 0;
    }
  }

  List<_Particle> _createParticles(Size size, double density) {
    final double area = size.width * size.height;
    final int count = max(30, (area / 10000 * density).floor());

    return List<_Particle>.generate(count, (int _) {
      final double radius = _random.nextDouble() * 2.2 + 1.4;
      final double vx = (_random.nextDouble() * 0.6) - 0.3;
      final double vy = (_random.nextDouble() * 0.6) - 0.3;
      return _Particle(
        position: Offset(
          _random.nextDouble() * (size.width - radius * 2) + radius,
          _random.nextDouble() * (size.height - radius * 2) + radius,
        ),
        velocity: Offset(vx, vy),
        radius: radius,
      );
    });
  }

  void _updateParticles(double dt) {
    if (_particles.isEmpty) {
      return;
    }

    final double frameFactor = (dt * 60).clamp(0.0, 3.0);
    final double width = _canvasSize.width;
    final double height = _canvasSize.height;

    for (final _Particle particle in _particles) {
      final Offset delta = particle.velocity * frameFactor;
      Offset position = particle.position + delta;

      if (position.dx <= particle.radius && particle.velocity.dx < 0) {
        particle.velocity = Offset(particle.velocity.dx.abs(), particle.velocity.dy);
        position = Offset(particle.radius, position.dy);
      } else if (position.dx >= width - particle.radius && particle.velocity.dx > 0) {
        particle.velocity = Offset(-particle.velocity.dx.abs(), particle.velocity.dy);
        position = Offset(width - particle.radius, position.dy);
      }

      if (position.dy <= particle.radius && particle.velocity.dy < 0) {
        particle.velocity = Offset(particle.velocity.dx, particle.velocity.dy.abs());
        position = Offset(position.dx, particle.radius);
      } else if (position.dy >= height - particle.radius && particle.velocity.dy > 0) {
        particle.velocity = Offset(particle.velocity.dx, -particle.velocity.dy.abs());
        position = Offset(position.dx, height - particle.radius);
      }

      particle.position = position;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size mediaSize = MediaQuery.of(context).size;
        final double width = constraints.maxWidth.isFinite ? constraints.maxWidth : mediaSize.width;
        final double height = constraints.maxHeight.isFinite ? constraints.maxHeight : mediaSize.height;
        final Size size = Size(width, height);

        _ensureParticles(size);

        return SizedBox.expand(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _MedicalBackgroundPainter(
                particles: _particles,
                baseColor: widget.baseColor,
                showHelix: widget.showHelix,
                time: _elapsed,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Particle {
  _Particle({
    required this.position,
    required this.velocity,
    required this.radius,
  });

  Offset position;
  Offset velocity;
  final double radius;
}

class _MedicalBackgroundPainter extends CustomPainter {
  _MedicalBackgroundPainter({
    required this.particles,
    required this.baseColor,
    required this.showHelix,
    required this.time,
  });

  final List<_Particle> particles;
  final Color baseColor;
  final bool showHelix;
  final double time;

  static const double _linkDistance = 130;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    _drawGradientBackground(canvas, size);
    _drawRadialGlow(canvas, size);
    _drawConnections(canvas, size);
    _drawParticles(canvas);
    if (showHelix) {
      _drawHelix(canvas, size);
    }
  }

  void _drawGradientBackground(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, size.height),
        const [Color(0xFF1B908B), Color(0xFF0F5F5B)],
      );
    canvas.drawRect(Offset.zero & size, paint);
  }

  void _drawRadialGlow(Canvas canvas, Size size) {
    final Offset center = Offset(size.width * 0.25, size.height * 0.3);
    final double radius = size.shortestSide * 0.7;
    final Paint paint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        [const Color(0xFF58E0D9).withValues(alpha: 0.5), Colors.transparent],
      );
    canvas.drawCircle(center, radius, paint);
  }

  void _drawParticles(Canvas canvas) {
    final Paint nodePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = baseColor.withValues(alpha: 0.78);
    for (final _Particle particle in particles) {
      canvas.drawCircle(particle.position, particle.radius, nodePaint);
    }
  }

  void _drawConnections(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i < particles.length; i++) {
      final Offset p1 = particles[i].position;
      for (int j = i + 1; j < particles.length; j++) {
        final Offset p2 = particles[j].position;
        final double distance = (p1 - p2).distance;
        if (distance < _linkDistance) {
          final double t = 1 - (distance / _linkDistance);
          final double opacity = 0.08 + t * (0.33 - 0.08);
          linePaint.color = baseColor.withValues(alpha: opacity.clamp(0.0, 1.0));
          canvas.drawLine(p1, p2, linePaint);
        }
      }
    }
  }

  void _drawHelix(Canvas canvas, Size size) {
    final int steps = 36;
    final double midX = size.width * 0.35;
    final double amplitude = min(60.0, size.height * 0.12);
    final double gapY = size.height / (steps + 1);

    final Paint rodPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.48)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final Paint nodePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < steps; i++) {
      final double y = gapY * (i + 1);
      final double phase = time + i * 0.35;
      final double dx = sin(phase) * amplitude;
      final Offset left = Offset(midX - dx, y);
      final Offset right = Offset(midX + dx, y);

      canvas.drawLine(left, right, rodPaint);
      canvas.drawCircle(left, 2.6, nodePaint);
      canvas.drawCircle(right, 2.6, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MedicalBackgroundPainter oldDelegate) {
    return oldDelegate.particles != particles ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.showHelix != showHelix ||
        oldDelegate.time != time;
  }
}
