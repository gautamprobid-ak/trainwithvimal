import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';

/// Small building blocks shared by the client Food / Habits / Check-ins /
/// Library / More screens (fd-pill, fd-kv, fd-mi, fd-step, ch-week, mo-sw …).

enum PillTone {
  gray(AppColors.sub, AppColors.text2),
  green(AppColors.okBg, AppColors.okText),
  blue(AppColors.infoBg, AppColors.infoText),
  amber(Color(0xFFFFF4DB), Color(0xFFA15C00)),
  red(AppColors.badBg, AppColors.badText);

  const PillTone(this.bg, this.fg);
  final Color bg;
  final Color fg;
}

/// Rounded status pill (fd-pill).
class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.tone = PillTone.gray, this.icon});
  final String label;
  final PillTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: tone.fg), const SizedBox(width: 3)],
          Text(label, style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700, color: tone.fg)),
        ],
      ),
    );
  }
}

/// Small square tag next to a name (fd-tag): "Planned", "Mine", "Off-plan".
class Tag extends StatelessWidget {
  const Tag(this.label, {super.key, this.amber = false});
  final String label;
  final bool amber;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: amber ? PillTone.amber.bg : AppColors.sub, borderRadius: BorderRadius.circular(5)),
      child: Text(label,
          style: AppText.caption.copyWith(fontSize: 10.5, fontWeight: FontWeight.w700, color: amber ? PillTone.amber.fg : AppColors.text2)),
    );
  }
}

/// Label / value rows separated by lines (fd-kv).
class KvList extends StatelessWidget {
  const KvList(this.rows, {super.key});
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(border: i == 0 ? null : const Border(top: BorderSide(color: AppColors.line))),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rows[i].$1, style: AppText.secondary.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(rows[i].$2, textAlign: TextAlign.right, style: AppText.bodyBold.copyWith(fontSize: 13)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Menu row with a grey icon square, title, subtitle and chevron (fd-mi).
class MenuRow extends StatelessWidget {
  const MenuRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.danger = false,
    this.chevron = true,
    this.iconBg,
    this.iconFg,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool danger;
  final bool chevron;
  final Color? iconBg;
  final Color? iconFg;

  @override
  Widget build(BuildContext context) {
    final fg = danger ? AppColors.badText : AppColors.text;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: iconBg ?? (danger ? AppColors.badBg : AppColors.sub), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 17, color: iconFg ?? (danger ? AppColors.badText : AppColors.text2)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.bodyBold.copyWith(color: fg)),
                  if (subtitle != null) Text(subtitle!, style: AppText.secondary.copyWith(fontSize: 12.5)),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            if (chevron && !danger) ...[const SizedBox(width: 6), const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted)],
          ],
        ),
      ),
    );
  }
}

/// Rows separated by thin lines (fd-menu / mo-list), optionally inside a card.
class MenuList extends StatelessWidget {
  const MenuList({super.key, required this.children, this.card = true});
  final List<Widget> children;
  final bool card;

  @override
  Widget build(BuildContext context) {
    final col = Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const Divider(height: 1),
          children[i],
        ],
      ],
    );
    return card ? AppCard(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2), child: col) : col;
  }
}

/// − value + stepper (fd-step).
class QtyStepper extends StatelessWidget {
  const QtyStepper({super.key, required this.value, required this.onMinus, required this.onPlus, this.large = false, this.minWidth});
  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final bool large;
  final double? minWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIconButton(Icons.remove_rounded, small: !large, onPressed: onMinus, tooltip: 'Less'),
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: minWidth ?? (large ? 120 : 74)),
          child: Text(value,
              textAlign: TextAlign.center,
              style: AppText.bodyBold.copyWith(fontSize: large ? 22 : 13.5, fontWeight: FontWeight.w800)),
        ),
        AppIconButton(Icons.add_rounded, small: !large, onPressed: onPlus, tooltip: 'More'),
      ],
    );
  }
}

/// Small on/off switch (mo-sw).
class MiniSwitch extends StatelessWidget {
  const MiniSwitch(this.on, {super.key});
  final bool on;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 38,
      height: 22,
      padding: const EdgeInsets.all(3),
      alignment: on ? Alignment.centerRight : Alignment.centerLeft,
      decoration: BoxDecoration(color: on ? AppColors.accent : const Color(0xFFD9D9D4), borderRadius: BorderRadius.circular(99)),
      child: Container(
        width: 16,
        height: 16,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 2, offset: Offset(0, 1))],
        ),
      ),
    );
  }
}

/// Checkbox row with title + help (fl-off).
class CheckRow extends StatelessWidget {
  const CheckRow({super.key, required this.on, required this.title, required this.subtitle, required this.onTap, this.border = true});
  final bool on;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        decoration: BoxDecoration(border: border ? const Border(top: BorderSide(color: AppColors.line)) : null),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: on ? AppColors.accent : Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: on ? AppColors.accent : AppColors.line2, width: 1.5),
              ),
              child: on ? const Icon(Icons.check_rounded, size: 13, color: Colors.white) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                  Text(subtitle, style: AppText.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Radio card option (dr-opt).
class RadioOption extends StatelessWidget {
  const RadioOption({super.key, required this.selected, required this.title, this.subtitle, this.trailing, required this.onTap, this.compact = false});
  final bool selected;
  final Widget title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(AppRadius.card);
    return Material(
      color: selected ? const Color(0xFFF7FAFF) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: r, side: BorderSide(color: selected ? AppColors.accent : AppColors.line2)),
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(borderRadius: r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: compact ? 10 : 12),
          child: Row(
            crossAxisAlignment: compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              Container(
                width: 18,
                height: 18,
                margin: EdgeInsets.only(top: compact ? 0 : 1),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: selected ? AppColors.accent : AppColors.line2, width: selected ? 5 : 1.5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultTextStyle(style: AppText.bodyBold.copyWith(fontSize: 13.5), child: title),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: AppText.secondary.copyWith(fontSize: 12.5, color: AppColors.text2)),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// Small rounded suggestion chip (fl-try button).
class TryChip extends StatelessWidget {
  const TryChip(this.label, {super.key, required this.onTap, this.selected = false});
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.text : Colors.white,
      shape: StadiumBorder(side: BorderSide(color: selected ? AppColors.text : AppColors.line)),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Container(
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          child: Text(label,
              style: AppText.caption.copyWith(fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.text2)),
        ),
      ),
    );
  }
}

/// "Try paneer dal roti" row of chips.
class TryRow extends StatelessWidget {
  const TryRow({super.key, this.label, required this.chips});
  final String? label;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (label != null) Text(label!, style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
        ...chips,
      ],
    );
  }
}

/// Dashed outline link button (fd-else).
class DashedButton extends StatelessWidget {
  const DashedButton({super.key, required this.label, required this.icon, required this.onTap, this.small = false});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: CustomPaint(
        painter: _DashedBorder(),
        child: SizedBox(
          height: small ? 38 : 42,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: AppColors.text2),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodyBold.copyWith(fontSize: small ? 13 : 13.5, color: AppColors.text2)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCFCFC9)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)));
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 5), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// One day of the week strip (ch-week / ch-d).
class WeekDay {
  const WeekDay(this.weekday, this.date, {this.done = false, this.today = false, this.partial = false});
  final String weekday;
  final int date;
  final bool done;
  final bool today;
  final bool partial;
}

class WeekStrip extends StatelessWidget {
  const WeekStrip({super.key, required this.days, required this.selected, required this.onPick});
  final List<WeekDay> days;
  final int selected;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          for (var i = 0; i < days.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(child: _DayCell(day: days[i], on: i == selected, onTap: () => onPick(i))),
          ],
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.on, required this.onTap});
  final WeekDay day;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color dotBg;
    Border? dotBorder;
    if (day.done) {
      dotBg = const Color(0xFF22C55E);
    } else if (day.today) {
      dotBg = AppColors.accentSoft;
      dotBorder = Border.all(color: AppColors.accent, width: 2);
    } else if (day.partial) {
      dotBg = const Color(0xFFFDE7C7);
    } else {
      dotBg = const Color(0xFFE8E8E4);
    }
    return Material(
      color: on ? AppColors.text : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.only(top: 7, bottom: 6),
          child: Column(
            children: [
              Text(day.weekday,
                  style: AppText.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: on ? const Color(0xFFC9C9C9) : AppColors.muted)),
              const SizedBox(height: 3),
              Text('${day.date}', style: AppText.bodyBold.copyWith(fontSize: 15, fontWeight: FontWeight.w800, color: on ? Colors.white : AppColors.text)),
              const SizedBox(height: 3),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(color: dotBg, shape: BoxShape.circle, border: dotBorder),
                child: day.done ? const Icon(Icons.check_rounded, size: 11, color: Colors.white) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grid of big number cells (hk-cells / fd-cells).
class StatCells extends StatelessWidget {
  const StatCells(this.cells, {super.key});
  final List<(String, String)> cells;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < cells.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cells[i].$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodyBold.copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 1),
                  Text(cells[i].$2, maxLines: 2, style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Grey caption paragraph (fd-cap).
class Caption extends StatelessWidget {
  const Caption(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(text, style: AppText.secondary.copyWith(fontSize: 12.5, height: 1.45));
}

/// Page top with an optional back button, big title and one line (fd-top / fl-top).
class ClientTop extends StatelessWidget {
  const ClientTop({super.key, required this.title, this.subtitle, this.onBack, this.actions = const [], this.small = false});
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onBack != null) ...[
          AppIconButton(Icons.arrow_back_rounded, small: true, onPressed: onBack, tooltip: 'Back'),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: small || onBack != null ? AppText.sectionTitle.copyWith(fontSize: 22) : AppText.pageTitle),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.secondary.copyWith(fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
        for (final a in actions) ...[const SizedBox(width: 8), a],
      ],
    );
  }
}

/// Header line inside a card: tinted icon + title + subtitle + trailing (ch-ch).
class CardHead extends StatelessWidget {
  const CardHead({super.key, required this.title, this.subtitle, this.icon, this.tint = Tint.gray, this.trailing});
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Tint tint;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[TintIcon(icon!, tint: tint, size: 32), const SizedBox(width: 10)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.bodyBold.copyWith(fontSize: 14.5, fontWeight: FontWeight.w800)),
              if (subtitle != null) Text(subtitle!, style: AppText.caption.copyWith(fontSize: 12.5)),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Green "done" strip (ch-wdone).
class DoneStrip extends StatelessWidget {
  const DoneStrip(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppColors.okBg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 17, color: AppColors.okText),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppText.bodyBold.copyWith(fontSize: 13, color: AppColors.okText))),
        ],
      ),
    );
  }
}

/// Bottom sheet with the design header whose content can rebuild
/// (use StatefulBuilder / Consumer inside [builder]).
Future<T?> showClientSheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .9),
    builder: builder,
  );
}

/// Sheet layout: title, one line of help, close, scrolling body, fixed footer.
class ClientSheet extends StatelessWidget {
  const ClientSheet({super.key, required this.title, this.subtitle, required this.body, this.actions = const [], this.footer});
  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget> actions;

  /// Custom footer instead of [actions].
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppText.cardTitle.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: AppText.secondary.copyWith(fontSize: 12.5)),
                      ],
                    ],
                  ),
                ),
                AppIconButton(Icons.close_rounded, small: true, tooltip: 'Close', onPressed: () => Navigator.of(context).pop()),
              ],
            ),
          ),
          Flexible(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: body)),
          if (footer != null || actions.isNotEmpty)
            Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
              child: footer ??
                  Row(
                    children: [
                      for (var i = 0; i < actions.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(child: actions[i]),
                      ],
                    ],
                  ),
            ),
        ],
      ),
    );
  }
}
