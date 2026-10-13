import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Round initials avatar.
class Avatar extends StatelessWidget {
  const Avatar(this.initials, {super.key, this.size = 38, this.color, this.online = false, this.square = false});

  final String initials;
  final double size;
  final AvatarColor? color;
  final bool online;
  final bool square;

  /// Initials from a full name: "Riya Sharma" → "RS".
  static String initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = color ?? AvatarColor.of(initials);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.bg,
              shape: square ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: square ? BorderRadius.circular(size * .26) : null,
            ),
            child: Text(
              initials,
              style: AppText.bodyBold.copyWith(fontSize: size * .34, fontWeight: FontWeight.w800, color: c.fg),
            ),
          ),
          if (online)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: size * .3,
                height: size * .3,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Overlapping row of small avatars (+N).
class AvatarStack extends StatelessWidget {
  const AvatarStack(this.initials, {super.key, this.size = 26, this.max = 4});
  final List<String> initials;
  final double size;
  final int max;

  @override
  Widget build(BuildContext context) {
    final shown = initials.take(max).toList();
    final extra = initials.length - shown.length;
    final items = [
      for (final i in shown) Avatar(i, size: size),
      if (extra > 0)
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColors.sub, shape: BoxShape.circle),
          child: Text('+$extra', style: AppText.caption.copyWith(fontSize: size * .36, fontWeight: FontWeight.w800)),
        ),
    ];
    return SizedBox(
      height: size + 4,
      width: size + (items.length - 1) * size * .7 + 4,
      child: Stack(
        children: [
          for (var i = 0; i < items.length; i++)
            Positioned(
              left: i * size * .7,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: items[i],
              ),
            ),
        ],
      ),
    );
  }
}
