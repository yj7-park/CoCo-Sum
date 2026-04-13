import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/entities/air_quality.dart';

/// 코코 — 공기 상태에 따라 표정이 바뀌는 구름 마스코트.
///
/// 애니메이션:
/// - 둥실둥실 떠다니기 (3초 루프)
/// - 눈 깜빡임 (3~5초 간격)
class CocoCharacter extends StatefulWidget {
  final AirQualityGrade grade;
  final double size;

  const CocoCharacter({
    super.key,
    required this.grade,
    this.size = 200,
  });

  @override
  State<CocoCharacter> createState() => _CocoCharacterState();
}

class _CocoCharacterState extends State<CocoCharacter>
    with TickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final AnimationController _blinkCtrl;
  late final Animation<double> _floatAnim;
  late final Animation<double> _blinkAnim;

  @override
  void initState() {
    super.initState();

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );

    _blinkAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _blinkCtrl, curve: Curves.easeIn),
    );

    _scheduleBlink();
  }

  void _scheduleBlink() async {
    while (mounted) {
      final delay = 3000 + math.Random().nextInt(2000);
      await Future.delayed(Duration(milliseconds: delay));
      if (!mounted) break;
      await _blinkCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 80));
      if (!mounted) break;
      await _blinkCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _blinkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatAnim, _blinkAnim]),
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, _floatAnim.value),
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _CocoPainter(
              grade: widget.grade,
              blinkProgress: _blinkAnim.value,
            ),
          ),
        );
      },
    );
  }
}

class _CocoPainter extends CustomPainter {
  final AirQualityGrade grade;
  final double blinkProgress; // 0=open, 1=closed

  const _CocoPainter({required this.grade, this.blinkProgress = 0});

  // ── 좌표 헬퍼 ────────────────────────────────────────────
  // 캔버스 크기에 대한 비율로 좌표를 계산해 모든 size에서 동일하게 보임

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // 구름 중심 (약간 아래)
    final cx = w * 0.5;
    final cy = h * 0.56;

    _drawDropShadow(canvas, cx, h * 0.92, w);
    _drawCloudBody(canvas, cx, cy, w);
    _drawEyes(canvas, cx, cy, w);
    _drawExpression(canvas, cx, cy, w);
    if (grade == AirQualityGrade.best || grade == AirQualityGrade.good) {
      _drawCheeks(canvas, cx, cy, w);
    }
  }

  // ── 지면 그림자 ───────────────────────────────────────────

  void _drawDropShadow(Canvas canvas, double cx, double sy, double w) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, sy),
        width: w * 0.55,
        height: w * 0.07,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  // ── 구름 몸통 ─────────────────────────────────────────────

  void _drawCloudBody(Canvas canvas, double cx, double cy, double w) {
    final color = _bodyColor();
    final r = w * 0.36; // 본체 반지름

    // 구름을 구성하는 원들 (그림자 → 본체 순서로 그림)
    final circles = [
      // (x_offset, y_offset, radius_factor)
      (0.0, 0.0, 1.0), // 메인 본체
      (-0.52, -0.28, 0.55), // 왼쪽 범프
      (0.0, -0.58, 0.60), // 위 중앙 범프 (제일 높음)
      (0.52, -0.28, 0.55), // 오른쪽 범프
    ];

    // 공통 그림자
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    for (final (dx, dy, rf) in circles) {
      canvas.drawCircle(
        Offset(cx + dx * r + 2, cy + dy * r + 6),
        r * rf,
        shadowPaint,
      );
    }

    // 구름 본체
    final bodyPaint = Paint()..color = color;
    for (final (dx, dy, rf) in circles) {
      canvas.drawCircle(Offset(cx + dx * r, cy + dy * r), r * rf, bodyPaint);
    }

    // 은은한 하이라이트 (왼쪽 상단)
    canvas.drawCircle(
      Offset(cx - r * 0.3, cy - r * 0.45),
      r * 0.28,
      Paint()..color = Colors.white.withValues(alpha: 0.5),
    );
  }

  Color _bodyColor() => switch (grade) {
        AirQualityGrade.best => const Color(0xFFFEFEFF),
        AirQualityGrade.good => const Color(0xFFF5FCFF),
        AirQualityGrade.fine => const Color(0xFFF0FDFB),
        AirQualityGrade.moderate => const Color(0xFFFFFDE7),
        AirQualityGrade.bad => const Color(0xFFFFF8E1),
        AirQualityGrade.quiteBad => const Color(0xFFFFF3E0),
        AirQualityGrade.veryBad => const Color(0xFFFFF5F5),
        AirQualityGrade.worst => const Color(0xFFF3E5F5),
      };

  // ── 눈 ───────────────────────────────────────────────────

  void _drawEyes(Canvas canvas, double cx, double cy, double w) {
    final eyeR = w * 0.085;
    final eyeY = cy - w * 0.04;
    final eyeOx = w * 0.125; // 눈 좌우 오프셋

    for (final sign in [-1.0, 1.0]) {
      final ex = cx + sign * eyeOx;
      _drawSingleEye(canvas, ex, eyeY, eyeR);
    }
  }

  void _drawSingleEye(Canvas canvas, double ex, double ey, double r) {
    // 흰자
    canvas.drawCircle(
      Offset(ex, ey),
      r,
      Paint()..color = Colors.white,
    );

    if (blinkProgress < 0.85) {
      final openRatio = 1 - blinkProgress;

      // 홍채
      canvas.drawCircle(
        Offset(ex, ey),
        r * 0.65 * openRatio,
        Paint()..color = _irisColor(),
      );

      // 동공
      canvas.drawCircle(
        Offset(ex, ey),
        r * 0.3 * openRatio,
        Paint()..color = const Color(0xFF1A0A00),
      );

      // 하이라이트
      canvas.drawCircle(
        Offset(ex - r * 0.18, ey - r * 0.22),
        r * 0.17 * openRatio,
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );
    }

    // 눈꺼풀 (깜빡임)
    if (blinkProgress > 0.05) {
      final lidH = r * 2.1 * blinkProgress;
      canvas.drawRect(
        Rect.fromLTWH(ex - r - 1, ey - r - 1, r * 2 + 2, lidH),
        Paint()..color = _bodyColor(),
      );
    }

    // 눈 테두리
    canvas.drawCircle(
      Offset(ex, ey),
      r,
      Paint()
        ..color = const Color(0xFFBBBBBB).withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  Color _irisColor() => switch (grade) {
        AirQualityGrade.best => const Color(0xFF29B6F6),
        AirQualityGrade.good => const Color(0xFF64B5F6),
        AirQualityGrade.fine => const Color(0xFF4DB6AC),
        AirQualityGrade.moderate => const Color(0xFF81C784),
        AirQualityGrade.bad => const Color(0xFFFFD54F),
        AirQualityGrade.quiteBad => const Color(0xFFFFB74D),
        AirQualityGrade.veryBad => const Color(0xFFFF8A65),
        AirQualityGrade.worst => const Color(0xFFCE93D8),
      };

  // ── 표정 ─────────────────────────────────────────────────

  void _drawExpression(Canvas canvas, double cx, double cy, double w) {
    switch (grade) {
      case AirQualityGrade.best:
      case AirQualityGrade.good:
        _drawBigSmile(canvas, cx, cy, w);
      case AirQualityGrade.fine:
      case AirQualityGrade.moderate:
        _drawSmallSmile(canvas, cx, cy, w);
      case AirQualityGrade.bad:
      case AirQualityGrade.quiteBad:
        _drawMask(canvas, cx, cy, w);
      case AirQualityGrade.veryBad:
      case AirQualityGrade.worst:
        _drawWorriedFace(canvas, cx, cy, w);
    }
  }

  void _drawBigSmile(Canvas canvas, double cx, double cy, double w) {
    final paint = Paint()
      ..color = const Color(0xFF8B4513)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.028
      ..strokeCap = StrokeCap.round;

    final my = cy + w * 0.09;
    final r = w * 0.15;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, my - r * 0.1), width: r * 2, height: r * 1.6),
      0.15,
      math.pi * 0.7,
      false,
      paint,
    );

    // 웃음 보조선 (볼 옆)
    canvas.drawLine(
      Offset(cx - r * 0.95, my + r * 0.1),
      Offset(cx - r * 1.1, my - r * 0.1),
      paint..strokeWidth = w * 0.018,
    );
    canvas.drawLine(
      Offset(cx + r * 0.95, my + r * 0.1),
      Offset(cx + r * 1.1, my - r * 0.1),
      paint,
    );
  }

  void _drawSmallSmile(Canvas canvas, double cx, double cy, double w) {
    final paint = Paint()
      ..color = const Color(0xFF8B4513)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.025
      ..strokeCap = StrokeCap.round;

    final my = cy + w * 0.10;
    final r = w * 0.09;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, my), width: r * 2, height: r * 1.4),
      0.2,
      math.pi * 0.6,
      false,
      paint,
    );
  }

  void _drawMask(Canvas canvas, double cx, double cy, double w) {
    final maskCy = cy + w * 0.1;
    final maskW = w * 0.40;
    final maskH = w * 0.20;

    // 마스크 본체
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, maskCy),
        width: maskW,
        height: maskH,
      ),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(
      rrect,
      Paint()..color = const Color(0xFFE3F2FD),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFF90CAF9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // 주름선 3개
    final pleatPaint = Paint()
      ..color = const Color(0xFF90CAF9).withValues(alpha: 0.55)
      ..strokeWidth = 1.0;
    for (final dy in [-maskH * 0.22, 0.0, maskH * 0.22]) {
      canvas.drawLine(
        Offset(cx - maskW * 0.42, maskCy + dy),
        Offset(cx + maskW * 0.42, maskCy + dy),
        pleatPaint,
      );
    }

    // 귀걸이 끈
    final strapPaint = Paint()
      ..color = const Color(0xFF90CAF9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    final eyeY = cy - w * 0.04;
    canvas.drawLine(
      Offset(cx - maskW * 0.5, maskCy - maskH * 0.3),
      Offset(cx - maskW * 0.65, eyeY + w * 0.04),
      strapPaint,
    );
    canvas.drawLine(
      Offset(cx + maskW * 0.5, maskCy - maskH * 0.3),
      Offset(cx + maskW * 0.65, eyeY + w * 0.04),
      strapPaint,
    );
  }

  void _drawWorriedFace(Canvas canvas, double cx, double cy, double w) {
    final eyeY = cy - w * 0.04;
    final eyeOx = w * 0.125;

    // 걱정 눈썹 (안쪽이 올라감)
    final browPaint = Paint()
      ..color = const Color(0xFF795548)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.028
      ..strokeCap = StrokeCap.round;

    // 왼쪽 눈썹: 바깥→안쪽이 높아짐
    canvas.drawLine(
      Offset(cx - eyeOx - w * 0.07, eyeY - w * 0.12),
      Offset(cx - eyeOx + w * 0.05, eyeY - w * 0.18),
      browPaint,
    );
    // 오른쪽 눈썹
    canvas.drawLine(
      Offset(cx + eyeOx - w * 0.05, eyeY - w * 0.18),
      Offset(cx + eyeOx + w * 0.07, eyeY - w * 0.12),
      browPaint,
    );

    // 슬픈 입 (아래로 굽은 곡선)
    final mouthPaint = Paint()
      ..color = const Color(0xFF8B4513)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.025
      ..strokeCap = StrokeCap.round;

    final mPath = Path();
    final my = cy + w * 0.12;
    mPath.moveTo(cx - w * 0.09, my);
    mPath.quadraticBezierTo(cx, my + w * 0.06, cx + w * 0.09, my);
    canvas.drawPath(mPath, mouthPaint);
  }

  void _drawCheeks(Canvas canvas, double cx, double cy, double w) {
    final eyeY = cy - w * 0.04;
    final eyeOx = w * 0.125;
    final cheekPaint = Paint()
      ..color = const Color(0xFFFFB3C1).withValues(alpha: 0.65);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - eyeOx - w * 0.07, eyeY + w * 0.07),
        width: w * 0.13,
        height: w * 0.08,
      ),
      cheekPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + eyeOx + w * 0.07, eyeY + w * 0.07),
        width: w * 0.13,
        height: w * 0.08,
      ),
      cheekPaint,
    );
  }

  @override
  bool shouldRepaint(_CocoPainter old) =>
      old.grade != grade || old.blinkProgress != blinkProgress;
}
