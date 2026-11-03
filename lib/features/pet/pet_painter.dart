import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'pet_care.dart';
import 'pet_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Pet character
//
// Drawn rather than shipped as artwork: there are no image assets, and a
// painter lets one character carry four species, five moods, three growth
// stages, breathing and blinking without a sprite sheet.
//
// The shapes stay deliberately simple and round, the style of Finch and
// Tamagotchi characters, because a simple face reads at a glance and a
// detailed one drawn in code tends to look uncanny.
//
// Each species is told apart by silhouette (ears and tail), never by colour
// alone, so the pet is recognisable in any palette and in dark mode.
// ─────────────────────────────────────────────────────────────────────────────

class PetLook {
  const PetLook({
    required this.fur,
    required this.belly,
    required this.ink,
    required this.cheek,
  });

  final Color fur;
  final Color belly;

  /// Eyes, nose and mouth.
  final Color ink;
  final Color cheek;

  static PetLook of(PetType type) => switch (type) {
        PetType.bunny => const PetLook(
            fur: Color(0xFFF3EEF2),
            belly: Color(0xFFFFFFFF),
            ink: Color(0xFF3A2F38),
            cheek: Color(0xFFF7A9C0),
          ),
        PetType.cat => const PetLook(
            fur: Color(0xFFF2C79A),
            belly: Color(0xFFFFF1E2),
            ink: Color(0xFF3A2C24),
            cheek: Color(0xFFF2A08C),
          ),
        PetType.bear => const PetLook(
            fur: Color(0xFFB88A66),
            belly: Color(0xFFE9D3BF),
            ink: Color(0xFF2E2420),
            cheek: Color(0xFFE59A8B),
          ),
        PetType.fox => const PetLook(
            fur: Color(0xFFEE8A4E),
            belly: Color(0xFFFFF4EA),
            ink: Color(0xFF2E2420),
            cheek: Color(0xFFF7A08A),
          ),
      };
}

class PetPainter extends CustomPainter {
  PetPainter({
    required this.type,
    required this.mood,
    required this.stage,
    required this.breath,
    required this.blink,
    required this.bounce,
  });

  final PetType type;
  final PetMood mood;
  final PetStage stage;

  /// 0 to 1, a slow sine for idle breathing.
  final double breath;

  /// 0 when open, 1 when shut.
  final double blink;

  /// 0 to 1, a quick hop after a tap.
  final double bounce;

  @override
  void paint(Canvas canvas, Size size) {
    final look = PetLook.of(type);
    final s = size.shortestSide;

    // Babies have a bigger head for their body, which is most of what makes
    // something read as young.
    final scale = switch (stage) {
      PetStage.baby => 0.78,
      PetStage.young => 0.9,
      PetStage.grown => 1.0,
    };
    final headRatio = switch (stage) {
      PetStage.baby => 0.62,
      PetStage.young => 0.55,
      PetStage.grown => 0.5,
    };

    canvas.save();
    canvas.translate(size.width / 2, size.height * 0.56);
    canvas.translate(0, -math.sin(bounce * math.pi) * s * 0.08);
    canvas.scale(scale);

    final u = s * 0.5; // one unit: half the box
    final squash = 1 + (breath - 0.5) * 0.035;

    _shadow(canvas, u);
    _tail(canvas, u, look);
    _body(canvas, u, look, squash);
    final headY = -u * 0.42;
    final headR = u * headRatio;
    _ears(canvas, u, look, headY, headR);
    _head(canvas, look, headY, headR);
    _face(canvas, look, headY, headR);

    canvas.restore();
  }

  void _shadow(Canvas canvas, double u) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, u * 0.62),
        width: u * 1.1 * (1 - bounce * 0.25),
        height: u * 0.16,
      ),
      Paint()..color = Colors.black.withOpacity(0.10),
    );
  }

  void _body(Canvas canvas, double u, PetLook look, double squash) {
    final rect = Rect.fromCenter(
      center: Offset(0, u * 0.18),
      width: u * 1.0 * squash,
      height: u * 0.9 / squash,
    );
    canvas.drawOval(rect, Paint()..color = look.fur);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, u * 0.28),
        width: u * 0.6,
        height: u * 0.55,
      ),
      Paint()..color = look.belly,
    );
    // Feet.
    for (final x in [-0.26, 0.26]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(u * x, u * 0.6),
          width: u * 0.3,
          height: u * 0.16,
        ),
        Paint()..color = look.fur,
      );
    }
  }

  void _tail(Canvas canvas, double u, PetLook look) {
    final fur = Paint()..color = look.fur;
    switch (type) {
      case PetType.bunny:
        canvas.drawCircle(Offset(u * 0.46, u * 0.36), u * 0.13,
            Paint()..color = look.belly);
      case PetType.bear:
        canvas.drawCircle(Offset(u * 0.44, u * 0.34), u * 0.09, fur);
      case PetType.cat:
        final p = Path()
          ..moveTo(u * 0.38, u * 0.4)
          ..quadraticBezierTo(u * 0.95, u * 0.35, u * 0.72, -u * 0.18);
        canvas.drawPath(
          p,
          Paint()
            ..color = look.fur
            ..style = PaintingStyle.stroke
            ..strokeWidth = u * 0.12
            ..strokeCap = StrokeCap.round,
        );
      case PetType.fox:
        final p = Path()
          ..moveTo(u * 0.32, u * 0.42)
          ..quadraticBezierTo(u * 1.05, u * 0.5, u * 0.78, -u * 0.12)
          ..quadraticBezierTo(u * 0.66, u * 0.22, u * 0.32, u * 0.3)
          ..close();
        canvas.drawPath(p, fur);
        // White tip: the fox's one unmistakable mark.
        canvas.drawCircle(
            Offset(u * 0.77, -u * 0.08), u * 0.09, Paint()..color = look.belly);
    }
  }

  void _ears(Canvas canvas, double u, PetLook look, double y, double r) {
    final fur = Paint()..color = look.fur;
    final inner = Paint()..color = look.cheek.withOpacity(0.8);
    for (final side in [-1.0, 1.0]) {
      switch (type) {
        case PetType.bunny:
          // Tall ears, the slightly drooped one lower when tired.
          final droop = mood == PetMood.sleepy || mood == PetMood.sad;
          final tilt = side * (droop ? 0.45 : 0.18);
          canvas.save();
          canvas.translate(side * r * 0.45, y - r * 0.7);
          canvas.rotate(tilt);
          final ear = Rect.fromCenter(
              center: Offset(0, -r * 0.55), width: r * 0.42, height: r * 1.2);
          canvas.drawOval(ear, fur);
          canvas.drawOval(ear.deflate(r * 0.09), inner);
          canvas.restore();
        case PetType.cat:
        case PetType.fox:
          final tall = type == PetType.fox ? 0.95 : 0.75;
          final base = Offset(side * r * 0.55, y - r * 0.6);
          final p = Path()
            ..moveTo(base.dx - side * r * 0.32, base.dy + r * 0.12)
            ..lineTo(base.dx + side * r * 0.12, base.dy - r * tall)
            ..lineTo(base.dx + side * r * 0.42, base.dy + r * 0.2)
            ..close();
          canvas.drawPath(p, fur);
          final q = Path()
            ..moveTo(base.dx - side * r * 0.14, base.dy + r * 0.08)
            ..lineTo(base.dx + side * r * 0.1, base.dy - r * tall * 0.65)
            ..lineTo(base.dx + side * r * 0.26, base.dy + r * 0.12)
            ..close();
          canvas.drawPath(q, inner);
        case PetType.bear:
          final c = Offset(side * r * 0.72, y - r * 0.68);
          canvas.drawCircle(c, r * 0.3, fur);
          canvas.drawCircle(c, r * 0.17, inner);
      }
    }
  }

  void _head(Canvas canvas, PetLook look, double y, double r) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, y), width: r * 2.1, height: r * 1.9),
      Paint()..color = look.fur,
    );
    // Muzzle, which carries most of the species' face shape.
    final muzzleW = type == PetType.fox ? r * 0.95 : r * 0.85;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(0, y + r * 0.38), width: muzzleW, height: r * 0.62),
      Paint()..color = look.belly,
    );
  }

  void _face(Canvas canvas, PetLook look, double y, double r) {
    final ink = Paint()..color = look.ink;
    final eyeY = y - r * 0.05;
    final eyeX = r * 0.42;
    final eyeR = r * 0.14;

    for (final side in [-1.0, 1.0]) {
      final c = Offset(side * eyeX, eyeY);
      if (mood == PetMood.happy || mood == PetMood.excited) {
        // Happy eyes are upturned arcs: the most readable "smiling eyes".
        final arc = Path()
          ..moveTo(c.dx - eyeR, c.dy + eyeR * 0.3)
          ..quadraticBezierTo(c.dx, c.dy - eyeR * 1.2, c.dx + eyeR, c.dy + eyeR * 0.3);
        canvas.drawPath(
          arc,
          Paint()
            ..color = look.ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.07
            ..strokeCap = StrokeCap.round,
        );
      } else {
        final sleepy = mood == PetMood.sleepy;
        final open = (1 - blink) * (sleepy ? 0.45 : 1.0);
        canvas.drawOval(
          Rect.fromCenter(
            center: c,
            width: eyeR * 2,
            height: math.max(eyeR * 2 * open, r * 0.05),
          ),
          ink,
        );
        if (open > 0.5) {
          canvas.drawCircle(c + Offset(-eyeR * 0.35, -eyeR * 0.4),
              eyeR * 0.32, Paint()..color = Colors.white);
        }
      }
      // Cheeks.
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(side * r * 0.66, y + r * 0.3),
          width: r * 0.3,
          height: r * 0.18,
        ),
        Paint()..color = look.cheek.withOpacity(mood == PetMood.sad ? 0.3 : 0.75),
      );
    }

    // Nose.
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(0, y + r * 0.24), width: r * 0.2, height: r * 0.13),
      ink,
    );

    // Mouth.
    final m = Offset(0, y + r * 0.44);
    final w = r * 0.22;
    final curve = switch (mood) {
      PetMood.excited => r * 0.2,
      PetMood.happy => r * 0.14,
      PetMood.neutral => r * 0.05,
      PetMood.sleepy => r * 0.02,
      PetMood.sad => -r * 0.1,
    };
    final mouth = Path()
      ..moveTo(m.dx - w, m.dy)
      ..quadraticBezierTo(m.dx, m.dy + curve, m.dx + w, m.dy);
    canvas.drawPath(
      mouth,
      Paint()
        ..color = look.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.06
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(PetPainter old) =>
      old.type != type ||
      old.mood != mood ||
      old.stage != stage ||
      old.breath != breath ||
      old.blink != blink ||
      old.bounce != bounce;
}
