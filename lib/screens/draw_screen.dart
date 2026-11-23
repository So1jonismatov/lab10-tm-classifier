import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// black on white like a photo of paper
const _paper = Colors.white;
const _ink = Colors.black;
const _exportSize = 448; // 2x 224

typedef _Stroke = List<Offset>;

class _StrokesPainter extends CustomPainter {
  _StrokesPainter(this.strokes, this.version);

  final List<_Stroke> strokes;
  final int version;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _paper);
    final width = size.shortestSide * 0.07;
    final line = Paint()
      ..color = _ink
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final dot = Paint()..color = _ink;
    for (final s in strokes) {
      if (s.length == 1) {
        canvas.drawCircle(s.first, width / 2, dot);
      } else {
        canvas.drawPath(Path()..addPolygon(s, false), line);
      }
    }
  }

  @override
  bool shouldRepaint(_StrokesPainter old) => old.version != version;
}

// returns png bytes of the drawing
class DrawScreen extends StatefulWidget {
  const DrawScreen({super.key});

  @override
  State<DrawScreen> createState() => _DrawScreenState();
}

class _DrawScreenState extends State<DrawScreen> {
  final List<_Stroke> _strokes = [];
  Size _canvasSize = Size.zero;
  int _version = 0;

  Future<Uint8List> _render() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final scale = _exportSize / _canvasSize.width;
    canvas.scale(scale);
    _StrokesPainter(_strokes, _version).paint(canvas, _canvasSize);
    final image = await recorder.endRecording().toImage(_exportSize, _exportSize);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  }

  Future<void> _done() async {
    final bytes = await _render();
    if (mounted) Navigator.of(context).pop(bytes);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Draw a digit')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: LayoutBuilder(builder: (context, box) {
                      _canvasSize = box.biggest;
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.outline),
                          borderRadius: BorderRadius.circular(AppSpacing.radius),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppSpacing.radius),
                          child: GestureDetector(
                            onPanStart: (d) => setState(() {
                              _strokes.add([d.localPosition]);
                              _version++;
                            }),
                            onPanUpdate: (d) => setState(() {
                              _strokes.last.add(d.localPosition);
                              _version++;
                            }),
                            child: RepaintBoundary(
                              child: CustomPaint(
                                painter: _StrokesPainter(_strokes, _version),
                                child: const SizedBox.expand(),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _strokes.isEmpty
                          ? null
                          : () => setState(() {
                                _strokes.clear();
                                _version++;
                              }),
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: _strokes.isEmpty ? null : _done,
                      child: const Text('Classify'),
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
}
