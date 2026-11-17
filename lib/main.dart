
import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() => runApp(const NabehJuliaApp());

class NabehJuliaApp extends StatelessWidget {
  const NabehJuliaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nabeh & Julia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF69B4),
          brightness: Brightness.dark,
        ),
      ),
      home: const PaintArena(),
    );
  }
}

class PaintArena extends StatefulWidget {
  const PaintArena({super.key});

  @override
  State<PaintArena> createState() => _PaintArenaState();
}

class _PaintArenaState extends State<PaintArena> with TickerProviderStateMixin {
  static const List<Color> palette = [
    Color(0xFFFF4F9A),
    Color(0xFF35D9FF),
    Color(0xFFFFD166),
    Color(0xFFB58CFF),
    Color(0xFF8DF06A),
  ];
  static const List<String> colorNames = ['Rose', 'Ocean', 'Golden', 'Dream', 'Mint'];

  late final AnimationController _floatController;
  late final AnimationController _ambientController;
  late final AnimationController _winController;
  final List<PaintMark> _marks = [];
  final List<ShotBurst> _bursts = [];
  final math.Random _random = math.Random();

  int _hits = 0;
  int _requiredHits = 22;
  int _selected = 0;
  bool _won = false;
  bool _showIntro = true;

  Color get _paint => palette[_selected];
  double get _progress => (_hits / _requiredHits).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat(reverse: true);
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 28),
    )..repeat();
    _winController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _ambientController.dispose();
    _winController.dispose();
    for (final burst in _bursts) {
      burst.controller.dispose();
    }
    super.dispose();
  }

  void _shoot(TapDownDetails details, Size size) {
    if (_won) return;
    final local = details.localPosition;
    final mark = PaintMark(
      position: Offset(
        (local.dx / size.width).clamp(0.04, 0.96),
        (local.dy / size.height).clamp(0.08, 0.92),
      ),
      color: _paint,
      radius: 15 + _random.nextDouble() * 13,
      rotation: _random.nextDouble() * math.pi * 2,
    );
    final burst = ShotBurst(
      controller: AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 720),
      ),
      position: local,
      color: _paint,
    );
    setState(() {
      _hits = math.min(_hits + 1, _requiredHits);
      _marks.add(mark);
      _bursts.add(burst);
      _showIntro = false;
    });
    burst.controller.forward().whenComplete(() {
      if (mounted) {
        setState(() => _bursts.remove(burst));
        burst.controller.dispose();
      }
    });
    if (_hits >= _requiredHits) {
      _won = true;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _winController.forward(from: 0);
      });
    }
  }

  void _restart() {
    setState(() {
      _hits = 0;
      _marks.clear();
      _won = false;
      _showIntro = true;
    });
    _winController.reset();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _ambientController,
              builder: (_, __) => CustomPaint(
                painter: UniversePainter(_ambientController.value),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 9),
                _topBar(),
                const SizedBox(height: 13),
                _progressPanel(),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final stageSize = Size(constraints.maxWidth, constraints.maxHeight);
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            bottom: 34,
                            child: Container(
                              width: size.width * .72,
                              height: 45,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                                boxShadow: [
                                  BoxShadow(
                                    color: _paint.withOpacity(.28),
                                    blurRadius: 55,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _floatController,
                            builder: (context, child) {
                              final t = _floatController.value * math.pi;
                              return Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.0015)
                                  ..rotateX(.075 + math.sin(t) * .025)
                                  ..rotateY(-.10 + math.sin(t * .7) * .045)
                                  ..translate(0.0, math.sin(t) * -9.0),
                                child: child,
                              );
                            },
                            child: GestureDetector(
                              onTapDown: (d) => _shoot(d, stageSize),
                              child: SizedBox(
                                width: size.width * .92,
                                height: math.min(350, constraints.maxHeight * .72),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CustomPaint(
                                      painter: PaintMarksPainter(_marks),
                                    ),
                                    Center(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _extrudedText('Nabeh', 76, const Color(0xFFFFF4FA)),
                                            const SizedBox(height: 2),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                _tinyHeart(),
                                                const SizedBox(width: 10),
                                                _extrudedText('& Julia', 70, const Color(0xFFFFDDEC)),
                                                const SizedBox(width: 10),
                                                _tinyHeart(),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    ..._bursts.map((b) => AnimatedBuilder(
                                      animation: b.controller,
                                      builder: (_, __) {
                                        final v = Curves.easeOut.transform(b.controller.value);
                                        return Positioned(
                                          left: b.position.dx - 22 - v * 16,
                                          top: b.position.dy - 22 - v * 16,
                                          child: Opacity(
                                            opacity: (1 - v).clamp(0.0, 1.0),
                                            child: Transform.scale(
                                              scale: .5 + v * 1.7,
                                              child: Icon(Icons.favorite,
                                                color: b.color, size: 38,
                                                shadows: [Shadow(color: b.color, blurRadius: 20)],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    )),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (_showIntro)
                            Positioned(
                              bottom: 13,
                              child: _glassPill('TAP THE NAMES TO THROW PAINT ✦'),
                            ),
                          if (_won)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: AnimatedBuilder(
                                  animation: _winController,
                                  builder: (_, __) => Opacity(
                                    opacity: _winController.value,
                                    child: Center(
                                      child: Transform.scale(
                                        scale: .75 + _winController.value * .25,
                                        child: const Text('♥  FOREVER  ♥',
                                          style: TextStyle(
                                            fontSize: 26, fontWeight: FontWeight.w900,
                                            letterSpacing: 3, color: Color(0xFFFFD6EA),
                                            shadows: [Shadow(color: Colors.pink, blurRadius: 24)],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                _palettePicker(),
                const SizedBox(height: 9),
                _bottomMessage(),
                const SizedBox(height: 12),
              ],
            ),
          ),
          if (_won) _winOverlay(),
        ],
      ),
    );
  }

  Widget _topBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(
      children: [
        const Icon(Icons.auto_awesome, color: Color(0xFFFFB7D7), size: 19),
        const SizedBox(width: 8),
        const Expanded(
          child: Text('OUR LITTLE UNIVERSE',
            style: TextStyle(fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.w800, color: Color(0xFFE8D9F7))),
        ),
        IconButton(
          tooltip: 'Restart',
          onPressed: _restart,
          icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
        ),
      ],
    ),
  );

  Widget _progressPanel() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 18),
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(.075),
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: Colors.white.withOpacity(.13)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Container(width: 12, height: 12,
              decoration: BoxDecoration(color: _paint, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _paint.withOpacity(.7), blurRadius: 12)])),
            const SizedBox(width: 8),
            Text('PAINT: ${colorNames[_selected].toUpperCase()}',
              style: const TextStyle(fontSize: 10, letterSpacing: 1.8, fontWeight: FontWeight.w800)),
            const Spacer(),
            Text('${(_progress * 100).round()}%',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _progress),
            duration: const Duration(milliseconds: 350),
            builder: (_, value, __) => LinearProgressIndicator(
              value: value, minHeight: 7,
              backgroundColor: Colors.white.withOpacity(.10),
              valueColor: AlwaysStoppedAnimation(_paint),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _palettePicker() => Column(
    children: [
      const Text('CHOOSE YOUR LOVE COLOR',
        style: TextStyle(fontSize: 9, letterSpacing: 2.2, color: Color(0xFFDBCAE9), fontWeight: FontWeight.w800)),
      const SizedBox(height: 11),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(palette.length, (i) {
          final selected = i == _selected;
          return GestureDetector(
            onTap: () => setState(() => _selected = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: selected ? 43 : 35,
              height: selected ? 43 : 35,
              decoration: BoxDecoration(
                color: palette[i], shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(selected ? .95 : .35), width: selected ? 3 : 1.5),
                boxShadow: [BoxShadow(color: palette[i].withOpacity(selected ? .65 : .25), blurRadius: selected ? 18 : 8)],
              ),
              child: selected ? const Icon(Icons.favorite, size: 16, color: Colors.white) : null,
            ),
          );
        }),
      ),
    ],
  );

  Widget _bottomMessage() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18),
    child: Text(
      _won ? 'You made a little universe of your own.' : 'Every splash brings your two names closer to forever.',
      textAlign: TextAlign.center,
      style: const TextStyle(color: Color(0xFFE7D7EF), fontSize: 11, letterSpacing: .35),
    ),
  );

  Widget _extrudedText(String text, double size, Color color) => Stack(
    children: [
      Text(text, style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, letterSpacing: -3,
        foreground: Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = Colors.white)),
      Transform.translate(
        offset: const Offset(5, 8),
        child: Text(text, style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, letterSpacing: -3,
          color: const Color(0xFF571C63),
          shadows: const [Shadow(color: Colors.black54, blurRadius: 3, offset: Offset(2, 3))])),
      ),
      Text(text, style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, letterSpacing: -3,
        color: color,
        shadows: const [
          Shadow(color: Color(0xFFFF7DBB), blurRadius: 17, offset: Offset(0, 0)),
          Shadow(color: Color(0xFFB74FFF), blurRadius: 28, offset: Offset(0, 4)),
          Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(2, 5)),
        ])),
    ],
  );

  Widget _tinyHeart() => const Icon(Icons.favorite, size: 17, color: Color(0xFFFF8FC5),
    shadows: [Shadow(color: Colors.pinkAccent, blurRadius: 14)]);

  Widget _glassPill(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
    decoration: BoxDecoration(color: Colors.black.withOpacity(.25),
      borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white24)),
    child: Text(label, style: const TextStyle(fontSize: 9, letterSpacing: 1.6, fontWeight: FontWeight.w800)),
  );

  Widget _winOverlay() => Positioned.fill(
    child: Container(
      color: const Color(0xCC090719),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(26),
          padding: const EdgeInsets.fromLTRB(25, 30, 25, 25),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF44204F), Color(0xFF171A3B)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFFFB5D8).withOpacity(.55)),
            boxShadow: [BoxShadow(color: Colors.pink.withOpacity(.24), blurRadius: 45, spreadRadius: 3)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('💖', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              const Text('A MASTERPIECE',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 10),
              const Text('Nabeh & Julia', style: TextStyle(fontSize: 26, color: Color(0xFFFFB6D7), fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text('Two names. One universe. One forever.',
                textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFEADDED), fontSize: 13)),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _restart,
                icon: const Icon(Icons.replay_rounded),
                label: const Text('PLAY AGAIN'),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF72B6), foregroundColor: const Color(0xFF31112C),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class PaintMark {
  final Offset position;
  final Color color;
  final double radius;
  final double rotation;
  PaintMark({required this.position, required this.color, required this.radius, required this.rotation});
}

class ShotBurst {
  final AnimationController controller;
  final Offset position;
  final Color color;
  ShotBurst({required this.controller, required this.position, required this.color});
}

class PaintMarksPainter extends CustomPainter {
  final List<PaintMark> marks;
  PaintMarksPainter(this.marks);

  @override
  void paint(Canvas canvas, Size size) {
    for (final mark in marks) {
      final center = Offset(mark.position.dx * size.width, mark.position.dy * size.height);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(mark.rotation);
      final paint = Paint()..color = mark.color.withOpacity(.94);
      canvas.drawCircle(Offset.zero, mark.radius, paint);
      for (int i = 0; i < 9; i++) {
        final a = i * math.pi * 2 / 9;
        final r = mark.radius * (1.05 + (i % 3) * .15);
        canvas.drawCircle(Offset(math.cos(a) * r, math.sin(a) * r),
          mark.radius * (.16 + (i % 2) * .05), paint);
      }
      final highlight = Paint()..color = Colors.white.withOpacity(.32);
      canvas.drawCircle(Offset(-mark.radius * .28, -mark.radius * .3), mark.radius * .22, highlight);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant PaintMarksPainter oldDelegate) => true;
}

class UniversePainter extends CustomPainter {
  final double phase;
  UniversePainter(this.phase);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bg = Paint()..shader = const LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFF080B20), Color(0xFF241238), Color(0xFF101D39)],
    ).createShader(rect);
    canvas.drawRect(rect, bg);

    final glow1 = Paint()..shader = RadialGradient(
      colors: [const Color(0xFF9B4DAB).withOpacity(.32), Colors.transparent],
    ).createShader(Rect.fromCircle(center: Offset(size.width * .18, size.height * .28), radius: size.width * .55));
    canvas.drawCircle(Offset(size.width * .18, size.height * .28), size.width * .55, glow1);

    final glow2 = Paint()..shader = RadialGradient(
      colors: [const Color(0xFFE64C9A).withOpacity(.19), Colors.transparent],
    ).createShader(Rect.fromCircle(center: Offset(size.width * .92, size.height * .62), radius: size.width * .48));
    canvas.drawCircle(Offset(size.width * .92, size.height * .62), size.width * .48, glow2);

    // A softly glowing moon.
    final moonCenter = Offset(size.width * .82, size.height * .16);
    canvas.drawCircle(moonCenter, 29, Paint()..color = const Color(0xFFFFE8F3).withOpacity(.08)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20));
    canvas.drawCircle(moonCenter, 17, Paint()..color = const Color(0xFFFFE8F3).withOpacity(.78));
    canvas.drawCircle(moonCenter.translate(7, -5), 16, Paint()..color = const Color(0xFF17142D));

    // Floating stars move slowly across the sky.
    for (int i = 0; i < 65; i++) {
      final x = ((i * 73.13) % 997) / 997 * size.width;
      final baseY = ((i * 47.71) % 991) / 991 * size.height;
      final y = (baseY + phase * (i.isEven ? 24 : -18) + size.height) % size.height;
      final twinkle = .35 + .65 * (math.sin(phase * math.pi * 2 + i) + 1) / 2;
      final radius = i % 9 == 0 ? 1.8 : .8;
      canvas.drawCircle(Offset(x, y), radius,
        Paint()..color = Colors.white.withOpacity(twinkle * .75));
    }

    // Drifting tiny heart constellations.
    for (int i = 0; i < 6; i++) {
      final x = size.width * (.12 + i * .15) + math.sin(phase * math.pi * 2 + i) * 10;
      final y = size.height * (.38 + (i % 3) * .19) + math.cos(phase * math.pi * 2 + i) * 9;
      _drawHeart(canvas, Offset(x, y), 4.5, const Color(0xFFFFA9D1).withOpacity(.34));
    }
  }

  void _drawHeart(Canvas canvas, Offset c, double s, Color color) {
    final path = Path()
      ..moveTo(c.dx, c.dy + s * .85)
      ..cubicTo(c.dx - s * 1.8, c.dy - s * .25, c.dx - s, c.dy - s * 1.35, c.dx, c.dy - s * .35)
      ..cubicTo(c.dx + s, c.dy - s * 1.35, c.dx + s * 1.8, c.dy - s * .25, c.dx, c.dy + s * .85)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant UniversePainter oldDelegate) => oldDelegate.phase != phase;
}
