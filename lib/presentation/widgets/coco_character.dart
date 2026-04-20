import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/entities/air_quality.dart';

/// 코수미 — 공기 상태에 따라 표정·액세서리가 바뀌는 구름 마스코트.
///
/// 8단계 표현:
/// - 최고       : 하트 눈 + 큰 미소 + 볼터치 + 반짝이
/// - 좋음       : 둥근 눈 + 큰 미소 + 볼터치
/// - 양호       : 둥근 눈 + 작은 미소 + 볼터치
/// - 보통       : 둥근 눈 + 일자 미소
/// - 나쁨       : 마스크 착용
/// - 상당히 나쁨 : 걱정 눈썹 + 마스크
/// - 매우 나쁨   : 걱정 눈썹 + 방독면 (중앙 필터)
/// - 최악       : 감긴 눈 + 걱정 눈썹 + 방독면 + 땀방울
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

  bool get _hasCheeks =>
      grade == AirQualityGrade.best ||
      grade == AirQualityGrade.good ||
      grade == AirQualityGrade.fine;

  bool get _hasWorriedBrows =>
      grade == AirQualityGrade.quiteBad ||
      grade == AirQualityGrade.veryBad ||
      grade == AirQualityGrade.worst;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.56;

    _drawDropShadow(canvas, cx, h * 0.92, w);
    _drawCloudBody(canvas, cx, cy, w);

    if (grade == AirQualityGrade.best) {
      _drawSparkles(canvas, cx, cy, w);
    }

    // 눈 ─ 단계별로 다르게
    switch (grade) {
      case AirQualityGrade.best:
        _drawHeartEyes(canvas, cx, cy, w);
      case AirQualityGrade.worst:
        _drawClosedEyes(canvas, cx, cy, w);
      default:
        _drawEyes(canvas, cx, cy, w);
    }

    if (_hasWorriedBrows) {
      _drawWorriedBrows(canvas, cx, cy, w);
    }

    // 입 / 마스크 / 방독면
    switch (grade) {
      case AirQualityGrade.best:
      case AirQualityGrade.good:
        _drawBigSmile(canvas, cx, cy, w);
      case AirQualityGrade.fine:
        _drawSmallSmile(canvas, cx, cy, w);
      case AirQualityGrade.moderate:
        _drawFlatMouth(canvas, cx, cy, w);
      case AirQualityGrade.bad:
      case AirQualityGrade.quiteBad:
        _drawMask(canvas, cx, cy, w);
      case AirQualityGrade.veryBad:
      case AirQualityGrade.worst:
        _drawGasMask(canvas, cx, cy, w);
    }

    if (_hasCheeks) {
      _drawCheeks(canvas, cx, cy, w);
    }

    if (grade == AirQualityGrade.worst) {
      _drawSweatDrop(canvas, cx, cy, w);
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
    final r = w * 0.36;

    final circles = [
      (0.0, 0.0, 1.0),
      (-0.52, -0.28, 0.55),
      (0.0, -0.58, 0.60),
      (0.52, -0.28, 0.55),
    ];

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

    final bodyPaint = Paint()..color = color;
    for (final (dx, dy, rf) in circles) {
      canvas.drawCircle(Offset(cx + dx * r, cy + dy * r), r * rf, bodyPaint);
    }

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

  // ── 눈 (기본) ────────────────────────────────────────────

  void _drawEyes(Canvas canvas, double cx, double cy, double w) {
    final eyeR = w * 0.085;
    final eyeY = cy - w * 0.04;
    final eyeOx = w * 0.125;

    for (final sign in [-1.0, 1.0]) {
      final ex = cx + sign * eyeOx;
      _drawSingleEye(canvas, ex, eyeY, eyeR);
    }
  }

  void _drawSingleEye(Canvas canvas, double ex, double ey, double r) {
    canvas.drawCircle(
      Offset(ex, ey),
      r,
      Paint()..color = Colors.white,
    );

    if (blinkProgress < 0.85) {
      final openRatio = 1 - blinkProgress;

      canvas.drawCircle(
        Offset(ex, ey),
        r * 0.65 * openRatio,
        Paint()..color = _irisColor(),
      );

      canvas.drawCircle(
        Offset(ex, ey),
        r * 0.3 * openRatio,
        Paint()..color = const Color(0xFF1A0A00),
      );

      canvas.drawCircle(
        Offset(ex - r * 0.18, ey - r * 0.22),
        r * 0.17 * openRatio,
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );
    }

    if (blinkProgress > 0.05) {
      final lidH = r * 2.1 * blinkProgress;
      canvas.drawRect(
        Rect.fromLTWH(ex - r - 1, ey - r - 1, r * 2 + 2, lidH),
        Paint()..color = _bodyColor(),
      );
    }

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

  // ── 눈: 하트 (최고) ───────────────────────────────────────

  void _drawHeartEyes(Canvas canvas, double cx, double cy, double w) {
    final eyeY = cy - w * 0.04;
    final eyeOx = w * 0.125;
    final s = w * 0.095;
    for (final sign in [-1.0, 1.0]) {
      _drawHeart(canvas, cx + sign * eyeOx, eyeY, s);
    }
  }

  void _drawHeart(Canvas canvas, double cx, double cy, double s) {
    final path = Path();
    path.moveTo(cx, cy + s * 0.5);
    path.cubicTo(
      cx + s * 1.2, cy - s * 0.2,
      cx + s * 0.5, cy - s * 0.9,
      cx, cy - s * 0.25,
    );
    path.cubicTo(
      cx - s * 0.5, cy - s * 0.9,
      cx - s * 1.2, cy - s * 0.2,
      cx, cy + s * 0.5,
    );
    path.close();
    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFFEF5B5B),
    );
    canvas.drawCircle(
      Offset(cx - s * 0.35, cy - s * 0.35),
      s * 0.18,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
  }

  // ── 눈: 감김 ㅠㅠ (최악) ──────────────────────────────────

  void _drawClosedEyes(Canvas canvas, double cx, double cy, double w) {
    final eyeY = cy - w * 0.04;
    final eyeOx = w * 0.125;
    final r = w * 0.085;
    final paint = Paint()
      ..color = const Color(0xFF5D4037)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.028
      ..strokeCap = StrokeCap.round;

    for (final sign in [-1.0, 1.0]) {
      final ex = cx + sign * eyeOx;
      // 아래로 굽은 호 (슬픈 눈)
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(ex, eyeY + r * 0.3),
          width: r * 1.9,
          height: r * 1.3,
        ),
        math.pi * 1.05,
        math.pi * 0.9,
        false,
        paint,
      );
      // 눈물 한 방울
      canvas.drawCircle(
        Offset(ex, eyeY + r * 0.55),
        r * 0.22,
        Paint()..color = const Color(0xFF4FC3F7).withValues(alpha: 0.85),
      );
    }
  }

  // ── 표정 ─────────────────────────────────────────────────

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

  void _drawFlatMouth(Canvas canvas, double cx, double cy, double w) {
    final paint = Paint()
      ..color = const Color(0xFF8B4513)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.024
      ..strokeCap = StrokeCap.round;
    final my = cy + w * 0.11;
    final r = w * 0.06;
    // 거의 일자에 가까운 아주 작은 호
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, my), width: r * 2.2, height: r * 0.6),
      0.1,
      math.pi * 0.85,
      false,
      paint,
    );
  }

  // ── 마스크 (나쁨·상당히 나쁨) ────────────────────────────

  void _drawMask(Canvas canvas, double cx, double cy, double w) {
    final maskCy = cy + w * 0.1;
    final maskW = w * 0.40;
    final maskH = w * 0.20;

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

  // ── 방독면 (매우 나쁨·최악) ──────────────────────────────

  void _drawGasMask(Canvas canvas, double cx, double cy, double w) {
    final maskCy = cy + w * 0.13;
    final maskW = w * 0.54;
    final maskH = w * 0.30;

    // 본체 (둥근 직사각형, 어두운 고무색)
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, maskCy),
        width: maskW,
        height: maskH,
      ),
      Radius.circular(w * 0.13),
    );
    canvas.drawRRect(
      rrect,
      Paint()..color = const Color(0xFF607D8B),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFF263238)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.012,
    );

    // 하이라이트 (좌상단)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - maskW * 0.22, maskCy - maskH * 0.22),
        width: maskW * 0.28,
        height: maskH * 0.18,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.15),
    );

    // 중앙 필터 canister
    final filterR = w * 0.095;
    final filterCy = maskCy + w * 0.025;
    canvas.drawCircle(
      Offset(cx, filterCy),
      filterR,
      Paint()..color = const Color(0xFF37474F),
    );
    canvas.drawCircle(
      Offset(cx, filterCy),
      filterR,
      Paint()
        ..color = const Color(0xFF1C2529)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.012,
    );
    // 그릴 (동심원)
    for (final rf in [0.65, 0.4]) {
      canvas.drawCircle(
        Offset(cx, filterCy),
        filterR * rf,
        Paint()
          ..color = const Color(0xFF90A4AE)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.008,
      );
    }
    // 중앙 점
    canvas.drawCircle(
      Offset(cx, filterCy),
      filterR * 0.12,
      Paint()..color = const Color(0xFF90A4AE),
    );

    // 끈 (위·아래)
    final strapPaint = Paint()
      ..color = const Color(0xFF37474F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.016
      ..strokeCap = StrokeCap.round;
    final eyeY = cy - w * 0.04;
    canvas.drawLine(
      Offset(cx - maskW * 0.48, maskCy - maskH * 0.25),
      Offset(cx - maskW * 0.72, eyeY - w * 0.01),
      strapPaint,
    );
    canvas.drawLine(
      Offset(cx + maskW * 0.48, maskCy - maskH * 0.25),
      Offset(cx + maskW * 0.72, eyeY - w * 0.01),
      strapPaint,
    );
    canvas.drawLine(
      Offset(cx - maskW * 0.48, maskCy + maskH * 0.2),
      Offset(cx - maskW * 0.70, maskCy + maskH * 0.45),
      strapPaint,
    );
    canvas.drawLine(
      Offset(cx + maskW * 0.48, maskCy + maskH * 0.2),
      Offset(cx + maskW * 0.70, maskCy + maskH * 0.45),
      strapPaint,
    );
  }

  // ── 걱정 눈썹 ────────────────────────────────────────────

  void _drawWorriedBrows(Canvas canvas, double cx, double cy, double w) {
    final eyeY = cy - w * 0.04;
    final eyeOx = w * 0.125;
    final browPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.028
      ..strokeCap = StrokeCap.round;

    // 왼쪽 눈썹: 안쪽(오른쪽 끝)이 올라감
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
  }

  // ── 반짝이 (최고) ────────────────────────────────────────

  void _drawSparkles(Canvas canvas, double cx, double cy, double w) {
    final paint = Paint()..color = const Color(0xFFFFD740);
    final items = <(Offset, double)>[
      (Offset(cx - w * 0.36, cy - w * 0.34), w * 0.045),
      (Offset(cx + w * 0.37, cy - w * 0.38), w * 0.050),
      (Offset(cx - w * 0.42, cy + w * 0.04), w * 0.030),
      (Offset(cx + w * 0.41, cy - w * 0.02), w * 0.035),
    ];
    for (final (pos, r) in items) {
      _drawSparkle(canvas, pos, r, paint);
    }
  }

  void _drawSparkle(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    path.moveTo(c.dx, c.dy - r);
    path.lineTo(c.dx + r * 0.3, c.dy - r * 0.3);
    path.lineTo(c.dx + r, c.dy);
    path.lineTo(c.dx + r * 0.3, c.dy + r * 0.3);
    path.lineTo(c.dx, c.dy + r);
    path.lineTo(c.dx - r * 0.3, c.dy + r * 0.3);
    path.lineTo(c.dx - r, c.dy);
    path.lineTo(c.dx - r * 0.3, c.dy - r * 0.3);
    path.close();
    canvas.drawPath(path, paint);
  }

  // ── 땀방울 (최악) ────────────────────────────────────────

  void _drawSweatDrop(Canvas canvas, double cx, double cy, double w) {
    final tx = cx + w * 0.28;
    final ty = cy - w * 0.24;
    final s = w * 0.055;

    final path = Path();
    path.moveTo(tx, ty - s);
    path.quadraticBezierTo(tx + s * 0.9, ty, tx, ty + s * 0.6);
    path.quadraticBezierTo(tx - s * 0.9, ty, tx, ty - s);
    path.close();

    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFF4FC3F7),
    );
    canvas.drawCircle(
      Offset(tx - s * 0.25, ty - s * 0.2),
      s * 0.2,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
  }

  // ── 볼터치 ───────────────────────────────────────────────

  void _drawCheeks(Canvas canvas, double cx, double cy, double w) {
    final eyeY = cy - w * 0.04;
    final eyeOx = w * 0.125;
    final alpha = grade == AirQualityGrade.fine ? 0.45 : 0.65;
    final cheekPaint = Paint()
      ..color = const Color(0xFFFFB3C1).withValues(alpha: alpha);

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
