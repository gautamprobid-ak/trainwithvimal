import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/auth_mock.dart';

/// Shared building blocks for the welcome / log in / setup boards (wl-* and ac-* in twv.css).

const _amberBg = Color(0xFFFFF4DB);
const _amberFg = Color(0xFFA15C00);
const _green = Color(0xFF22C55E);

/// Page body that scrolls, with a white footer pinned at the bottom (wl-scroll + wl-foot).
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.children, this.footer = const [], this.footerBorder = true, this.gap = 14});
  final List<Widget> children;
  final List<Widget> footer;
  final bool footerBorder;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
            child: Spaced(gap: gap, children: children),
          ),
        ),
        if (footer.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
            decoration: BoxDecoration(
              color: AppColors.card,
              border: footerBorder ? const Border(top: BorderSide(color: AppColors.line)) : null,
            ),
            child: Spaced(gap: 8, children: footer),
          ),
      ],
    );
  }
}

/// Text link button (wl-lnk).
class AuthLink extends StatelessWidget {
  const AuthLink(this.label, {super.key, this.onTap, this.small = true, this.muted = false, this.underline = false, this.color});
  final String label;
  final VoidCallback? onTap;
  final bool small;
  final bool muted;
  final bool underline;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? (muted ? AppColors.muted : AppColors.accentText);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Text(
          label,
          style: AppText.bodyBold.copyWith(
            fontSize: small ? 13 : 13.5,
            color: c,
            decoration: underline ? TextDecoration.underline : null,
            decorationColor: c,
          ),
        ),
      ),
    );
  }
}

/// Row at the top of a board: optional back button, spacer, trailing (wl-top).
class AuthTop extends StatelessWidget {
  const AuthTop({super.key, this.onBack, this.leading, this.trailing});
  final VoidCallback? onBack;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 36),
      child: Row(
        children: [
          if (onBack != null) AppIconButton(Icons.arrow_back_rounded, small: true, onPressed: onBack),
          if (leading != null) Flexible(child: leading!),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

/// Round brand mark (the logo image in the design).
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 48});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF4FB8EE), AppColors.accent]),
      ),
      child: Icon(Icons.fitness_center_rounded, color: Colors.white, size: size * .5),
    );
  }
}

/// Logo + "Train With Vimal" (wl-brow).
class BrandRow extends StatelessWidget {
  const BrandRow({super.key, this.size = 36, this.fontSize = 16});
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        BrandLogo(size: size),
        const SizedBox(width: 10),
        Text('Train With Vimal', style: AppText.bodyBold.copyWith(fontSize: fontSize, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

/// Soft blue illustration box (wl-illbox). The design's drawings are drawn here with icons.
class Illustration extends StatelessWidget {
  const Illustration(this.icon, {super.key, this.height = 236, this.background = AppColors.accentSoft, this.side = const []});
  final IconData icon;
  final double height;
  final Color background;
  final List<IconData> side;

  @override
  Widget build(BuildContext context) {
    final small = side.isEmpty ? const [Icons.favorite_rounded, Icons.bolt_rounded] : side;
    return Container(
      height: height,
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: height * .62,
            height: height * .62,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: .10), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: Icon(icon, size: height * .3, color: AppColors.accent),
          ),
          Positioned(left: 38, top: 34, child: _Bubble(small[0], Tint.green)),
          if (small.length > 1) Positioned(right: 40, bottom: 36, child: _Bubble(small[1], Tint.amber)),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble(this.icon, this.tint);
  final IconData icon;
  final Tint tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Icon(icon, size: 20, color: tint.fg),
    );
  }
}

/// Title + line of help (wl-h). [center] for the result screens.
class AuthHeading extends StatelessWidget {
  const AuthHeading({super.key, required this.title, this.body, this.bodySpan, this.center = false, this.kicker});
  final String title;
  final String? body;
  final InlineSpan? bodySpan;
  final bool center;
  final String? kicker;

  @override
  Widget build(BuildContext context) {
    final align = center ? TextAlign.center : TextAlign.start;
    final pStyle = AppText.secondary.copyWith(fontSize: 13.5, height: 1.45);
    return Column(
      crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        if (kicker != null) ...[
          Text(kicker!.toUpperCase(),
              style: AppText.overline.copyWith(fontSize: 11, letterSpacing: .9, color: AppColors.accentText)),
          const SizedBox(height: 4),
        ],
        Text(title, textAlign: align, style: AppText.pageTitle.copyWith(fontSize: 24, letterSpacing: -.2)),
        if (body != null || bodySpan != null) ...[
          const SizedBox(height: 4),
          Text.rich(bodySpan ?? TextSpan(text: body), textAlign: align, style: pStyle),
        ],
      ],
    );
  }
}

/// Bold e-mail inside a heading body (ac-em).
TextSpan emSpan(String text) => TextSpan(text: text, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700));

enum BadgeKind { ok, wait, big }

/// Round result badge (wl-badge ok / wait / big).
class ResultBadge extends StatelessWidget {
  const ResultBadge(this.kind, {super.key, this.icon});
  final BadgeKind kind;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, size, ic) = switch (kind) {
      BadgeKind.ok => (AppColors.okBg, AppColors.okText, 64.0, Icons.check_rounded),
      BadgeKind.wait => (_amberBg, _amberFg, 64.0, Icons.schedule_rounded),
      BadgeKind.big => (AppColors.accentSoft, AppColors.accent, 72.0, Icons.celebration_rounded),
    };
    return Center(
      child: Container(
        margin: EdgeInsets.only(top: kind == BadgeKind.big ? 18 : 6),
        width: size,
        height: size,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon ?? ic, size: 30, color: fg),
      ),
    );
  }
}

/// Form field that looks like an input but is tapped to "type" in the demo (wl-fld + wl-in).
class FakeField extends StatelessWidget {
  const FakeField({
    super.key,
    required this.label,
    required this.value,
    this.placeholder = false,
    this.onTap,
    this.error,
    this.bad = false,
    this.toggleLabel,
    this.onToggle,
    this.trailing,
  });
  final String label;
  final String value;
  final bool placeholder;
  final VoidCallback? onTap;
  final String? error;
  final bool bad;
  final String? toggleLabel;
  final VoidCallback? onToggle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isBad = bad || (error != null && error!.isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: AppText.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.text2)),
        const SizedBox(height: 5),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isBad ? AppColors.badText : AppColors.line2),
                boxShadow: isBad ? const [BoxShadow(color: AppColors.badBg, spreadRadius: 3)] : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body.copyWith(
                        fontSize: 14.5,
                        fontWeight: placeholder ? FontWeight.w500 : FontWeight.w600,
                        color: placeholder ? AppColors.muted : AppColors.text,
                      ),
                    ),
                  ),
                  ?trailing,
                  if (toggleLabel != null) _ShowButton(toggleLabel!, onToggle),
                ],
              ),
            ),
          ),
        ),
        if (error != null && error!.isNotEmpty) ...[
          const SizedBox(height: 5),
          FieldError(error!),
        ],
      ],
    );
  }
}

/// Real text input styled like wl-in.
class AuthInput extends StatelessWidget {
  const AuthInput({super.key, required this.label, required this.controller, this.keyboardType, this.hint});
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.line2));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: AppText.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.text2)),
        const SizedBox(height: 5),
        SizedBox(
          height: 44,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            autocorrect: false,
            style: AppText.body.copyWith(fontSize: 14.5, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: border,
              enabledBorder: border,
              focusedBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShowButton extends StatelessWidget {
  const _ShowButton(this.label, this.onTap);
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.sub,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          child: Text(label, style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.text2)),
        ),
      ),
    );
  }
}

/// Red line under a field (wl-err).
class FieldError extends StatelessWidget {
  const FieldError(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.error_outline_rounded, size: 14, color: AppColors.badText),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: AppText.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.badText, height: 1.4)),
        ),
      ],
    );
  }
}

/// Small rounded checkbox (fl-cb).
class CheckBox18 extends StatelessWidget {
  const CheckBox18(this.on, {super.key});
  final bool on;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: on ? AppColors.accent : Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: on ? AppColors.accent : AppColors.line2, width: 1.5),
      ),
      child: on ? const Icon(Icons.check_rounded, size: 13, color: Colors.white) : null,
    );
  }
}

/// Checkbox row (wl-cbx). [boxed] = the bordered card version (wl-notif).
class CheckRow extends StatelessWidget {
  const CheckRow({super.key, required this.on, required this.onTap, required this.title, this.subtitle, this.titleSpan, this.boxed = false});
  final bool on;
  final VoidCallback onTap;
  final String title;
  final String? subtitle;
  final InlineSpan? titleSpan;
  final bool boxed;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      crossAxisAlignment: subtitle != null || titleSpan != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Padding(padding: EdgeInsets.only(top: subtitle != null || titleSpan != null ? 2 : 0), child: CheckBox18(on)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (titleSpan != null)
                Text.rich(titleSpan!, style: AppText.body.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.5))
              else
                Text(title, style: AppText.bodyBold.copyWith(fontSize: 13.5, fontWeight: subtitle != null ? FontWeight.w700 : FontWeight.w600)),
              if (subtitle != null) Text(subtitle!, style: AppText.caption),
            ],
          ),
        ),
      ],
    );
    final r = BorderRadius.circular(boxed ? 14 : 8);
    return Material(
      color: boxed ? AppColors.card : Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: r, side: boxed ? const BorderSide(color: AppColors.line) : BorderSide.none),
      child: InkWell(
        onTap: onTap,
        borderRadius: r,
        child: Padding(padding: boxed ? const EdgeInsets.symmetric(horizontal: 14, vertical: 12) : const EdgeInsets.symmetric(vertical: 4), child: content),
      ),
    );
  }
}

enum HintTone { blue, green, amber }

/// Tinted hint strip (wl-hint).
class Hint extends StatelessWidget {
  const Hint(this.text, {super.key, this.tone = HintTone.blue, this.icon, this.trailing});
  final String text;
  final HintTone tone;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, ic) = switch (tone) {
      HintTone.blue => (AppColors.accentSoft, AppColors.infoText, Icons.info_outline_rounded),
      HintTone.green => (AppColors.okBg, AppColors.okText, Icons.check_circle_outline_rounded),
      HintTone.amber => (_amberBg, _amberFg, Icons.warning_amber_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon ?? ic, size: 16, color: fg),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppText.secondary.copyWith(color: fg, fontWeight: FontWeight.w600, height: 1.4))),
          if (trailing != null) ...[const SizedBox(width: 6), trailing!],
        ],
      ),
    );
  }
}

/// Small rounded pill (fd-pill).
class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.tone, this.icon});
  final String label;
  final HintTone? tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      HintTone.blue => (AppColors.infoBg, AppColors.infoText),
      HintTone.green => (AppColors.okBg, AppColors.okText),
      HintTone.amber => (_amberBg, _amberFg),
      null => (AppColors.sub, AppColors.text2),
    };
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: fg), const SizedBox(width: 3)],
          Text(label, style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }
}

enum FlowState { done, current, todo }

class TimelineEntry {
  const TimelineEntry(this.title, this.subtitle, this.state);
  final String title;
  final String subtitle;
  final FlowState state;
}

/// Vertical "What happens next" timeline (wl-tl / wl-ti).
class AuthTimeline extends StatelessWidget {
  const AuthTimeline(this.items, {super.key});
  final List<TimelineEntry> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) _TimelineRow(items[i], last: i == items.length - 1),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow(this.e, {required this.last});
  final TimelineEntry e;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final done = e.state == FlowState.done;
    final cur = e.state == FlowState.current;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: done ? _green : AppColors.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: done ? _green : (cur ? AppColors.accent : AppColors.line2), width: 2),
                    boxShadow: cur ? const [BoxShadow(color: AppColors.accentSoft, spreadRadius: 3)] : null,
                  ),
                  child: done ? const Icon(Icons.check_rounded, size: 12, color: Colors.white) : null,
                ),
                if (!last) Expanded(child: Container(width: 2, color: done ? _green : AppColors.line)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.title, style: AppText.bodyBold.copyWith(color: done || cur ? AppColors.text : AppColors.muted)),
                  const SizedBox(height: 1),
                  Text(e.subtitle, style: AppText.caption.copyWith(fontSize: 12.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "What happens next" card with a timeline.
class NextCard extends StatelessWidget {
  const NextCard({super.key, required this.items, this.title = 'What happens next', this.pill, this.footer});
  final List<TimelineEntry> items;
  final String title;
  final Widget? pill;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardTitleRow(title, trailing: pill),
          const SizedBox(height: 12),
          AuthTimeline(items),
          if (footer != null) ...[const SizedBox(height: 12), footer!],
        ],
      ),
    );
  }
}

/// Card title with trailing (wl-ph1).
class CardTitleRow extends StatelessWidget {
  const CardTitleRow(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppText.cardTitle.copyWith(fontWeight: FontWeight.w800))),
        ?trailing,
      ],
    );
  }
}

/// Dashed demo box with links (ac-demo).
class DemoBox extends StatelessWidget {
  const DemoBox({super.key, this.label = 'Demo', required this.children});
  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.line2)),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 0,
        children: [
          Text(label.toUpperCase(), style: AppText.overline.copyWith(fontSize: 10.5, letterSpacing: .8)),
          ...children,
        ],
      ),
    );
  }
}

/// Small demo link inside a [DemoBox].
class DemoLink extends StatelessWidget {
  const DemoLink(this.label, {super.key, required this.onTap, this.selected = false});
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AuthLink(label, onTap: onTap, underline: selected, color: selected ? AppColors.text : null);
  }
}

/// Password strength bars (wl-str).
class StrengthMeter extends StatelessWidget {
  const StrengthMeter(this.password, {super.key});
  final String password;

  static int scoreOf(String p) {
    if (p.isEmpty) return 0;
    var s = 0;
    if (p.length >= 8) s++;
    if (RegExp('[a-zA-Z]').hasMatch(p) && RegExp(r'\d').hasMatch(p)) s++;
    if (RegExp('[^a-zA-Z0-9]').hasMatch(p)) s++;
    if (RegExp('[A-Z]').hasMatch(p)) s++;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final score = scoreOf(password);
    final empty = password.isEmpty;
    final label = empty ? 'Strength' : score >= 3 ? 'Strong' : score == 2 ? 'Okay' : 'Weak';
    final labelColor = empty ? AppColors.muted : score >= 3 ? AppColors.okText : _amberFg;
    return Row(
      children: [
        for (var k = 0; k < 4; k++) ...[
          if (k > 0) const SizedBox(width: 4),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 4,
              decoration: BoxDecoration(
                color: k < score ? (score >= 3 ? _green : const Color(0xFFF59E0B)) : AppColors.sub,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
        const SizedBox(width: 10),
        SizedBox(
          width: 56,
          child: Text(label, style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700, color: labelColor)),
        ),
      ],
    );
  }
}

/// Password rules checklist (ac-rules). [tried] turns unmet rules red.
class PasswordRules extends StatelessWidget {
  const PasswordRules(this.rules, {super.key, this.tried = false});
  final List<(String, bool)> rules;
  final bool tried;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(12)),
      child: Spaced(
        gap: 7,
        children: [
          for (final (t, ok) in rules)
            Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: ok ? _green : AppColors.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: ok ? _green : (tried ? AppColors.badText : AppColors.line2), width: 1.5),
                  ),
                  child: ok ? const Icon(Icons.check_rounded, size: 11, color: Colors.white) : null,
                ),
                const SizedBox(width: 9),
                Text(t,
                    style: AppText.secondary.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ok ? AppColors.okText : (tried ? AppColors.badText : AppColors.text2),
                    )),
              ],
            ),
        ],
      ),
    );
  }
}

/// Question heading inside a setup step (wl-q).
class QuestionHead extends StatelessWidget {
  const QuestionHead(this.title, {super.key, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.cardTitle.copyWith(fontSize: 15.5, fontWeight: FontWeight.w800)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: AppText.caption.copyWith(fontSize: 12.5)),
          ],
        ],
      ),
    );
  }
}

/// Wrap of pill chips (wl-chips). Dark when on; [small] = blue suggestion chips.
class ChipWrap extends StatelessWidget {
  const ChipWrap({super.key, required this.items, required this.isOn, required this.onTap, this.small = false, this.check = false});
  final List<String> items;
  final bool Function(String) isOn;
  final ValueChanged<String> onTap;
  final bool small;
  final bool check;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [for (final n in items) _Chip(n, on: isOn(n), small: small, check: check, onTap: () => onTap(n))],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, {required this.on, required this.small, required this.check, required this.onTap});
  final String label;
  final bool on;
  final bool small;
  final bool check;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg) = on
        ? (small ? (AppColors.accentSoft, AppColors.accent, AppColors.accentText) : (AppColors.text, AppColors.text, Colors.white))
        : (AppColors.card, AppColors.line, AppColors.text2);
    return Material(
      color: bg,
      shape: StadiumBorder(side: BorderSide(color: border)),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Container(
          height: small ? 28 : 34,
          padding: EdgeInsets.symmetric(horizontal: small ? 10 : 13),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (check && on) ...[Icon(Icons.check_rounded, size: 14, color: fg), const SizedBox(width: 5)],
              Text(label, style: AppText.secondary.copyWith(fontSize: small ? 12 : 13, fontWeight: FontWeight.w600, color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three-way segmented choice with title + subtitle (wl-seg).
class SegChoice extends StatelessWidget {
  const SegChoice({super.key, required this.items, required this.index, required this.onChanged});
  final List<TitledLine> items;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(child: _SegItem(items[i], on: i == index, onTap: () => onChanged(i))),
          ],
        ],
      ),
    );
  }
}

class _SegItem extends StatelessWidget {
  const _SegItem(this.item, {required this.on, required this.onTap});
  final TitledLine item;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: on ? AppColors.card : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: on ? AppColors.line : Colors.transparent),
          boxShadow: on ? const [BoxShadow(color: Color(0x14171717), blurRadius: 2, offset: Offset(0, 1))] : null,
        ),
        child: Column(
          children: [
            Text(item.title,
                style: AppText.bodyBold.copyWith(fontSize: 13, color: on ? AppColors.accentText : AppColors.text2)),
            const SizedBox(height: 1),
            Text(item.subtitle,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

/// Radio cards (dr-opts / dr-opt sm).
class RadioOptions extends StatelessWidget {
  const RadioOptions({super.key, required this.items, required this.index, required this.onChanged});
  final List<TitledLine> items;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Spaced(
      gap: 6,
      children: [
        for (var i = 0; i < items.length; i++) SelectCard(on: i == index, onTap: () => onChanged(i), child: _RadioBody(items[i], i == index)),
      ],
    );
  }
}

class _RadioBody extends StatelessWidget {
  const _RadioBody(this.item, this.on);
  final TitledLine item;
  final bool on;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.card,
            shape: BoxShape.circle,
            border: Border.all(color: on ? AppColors.accent : AppColors.line2, width: on ? 5 : 1.5),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
              const SizedBox(height: 2),
              Text(item.subtitle, style: AppText.caption.copyWith(fontSize: 12.5, color: AppColors.text2)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Card that gets a blue ring when selected (wl-goal / wl-dt / dr-opt).
class SelectCard extends StatelessWidget {
  const SelectCard({super.key, required this.on, required this.onTap, required this.child, this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10), this.radius = 12});
  final bool on;
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: on ? const [BoxShadow(color: AppColors.accentSoft, spreadRadius: 3)] : null,
      ),
      child: Material(
        color: on ? const Color(0xFFF7FAFF) : AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: r, side: BorderSide(color: on ? AppColors.accent : AppColors.line)),
        child: InkWell(onTap: onTap, borderRadius: r, child: Padding(padding: padding, child: child)),
      ),
    );
  }
}

/// − value + stepper (fd-step).
class ValueStepper extends StatelessWidget {
  const ValueStepper({super.key, required this.value, required this.onMinus, required this.onPlus, this.valueWidth = 74, this.expand = false});
  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final double valueWidth;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final text = Text(value,
        textAlign: TextAlign.center,
        style: AppText.bodyBold.copyWith(fontSize: expand ? 15 : 13.5, fontWeight: FontWeight.w800, fontFeatures: const [FontFeature.tabularFigures()]));
    return Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        _StepBtn(Icons.remove_rounded, onMinus),
        if (expand) Expanded(child: text) else SizedBox(width: valueWidth, child: text),
        _StepBtn(Icons.add_rounded, onPlus),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn(this.icon, this.onTap);
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9), side: const BorderSide(color: AppColors.line)),
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, size: 16, color: AppColors.text2),
        ),
      ),
    );
  }
}

/// Five-segment setup progress (wl-prog).
class SegProgress extends StatelessWidget {
  const SegProgress(this.states, {super.key});
  final List<FlowState> states;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < states.length; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: switch (states[i]) {
                  FlowState.done => _green,
                  FlowState.current => AppColors.accent,
                  FlowState.todo => const Color(0xFFE4E4DF),
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Menu row (fd-mi): leading, title + subtitle, trailing.
class MenuRow extends StatelessWidget {
  const MenuRow({super.key, this.leading, required this.title, this.subtitle, this.trailing, this.onTap, this.first = false, this.labelFirst = false});
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool first;

  /// Small grey label above a bold value (profile summary rows).
  final bool labelFirst;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        decoration: BoxDecoration(border: first ? null : const Border(top: BorderSide(color: AppColors.line))),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: labelFirst
                    ? [
                        Text(subtitle ?? '', style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 1),
                        Text(title, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                      ]
                    : [
                        Text(title, style: AppText.bodyBold),
                        if (subtitle != null) ...[
                          const SizedBox(height: 1),
                          Text(subtitle!, style: AppText.caption.copyWith(fontSize: 12.5)),
                        ],
                      ],
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

/// Grey square icon used in menu rows (fd-mic).
class MenuIcon extends StatelessWidget {
  const MenuIcon({super.key, this.icon, this.text, this.ok = false});
  final IconData? icon;
  final String? text;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: ok ? AppColors.okBg : AppColors.sub, borderRadius: BorderRadius.circular(10)),
      child: icon != null
          ? Icon(icon, size: 16, color: ok ? AppColors.okText : AppColors.text2)
          : Text(text ?? '', style: AppText.bodyBold.copyWith(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.muted)),
    );
  }
}

/// Label → value row with a top line (fd-kv).
class KvRow extends StatelessWidget {
  const KvRow(this.kv, {super.key, this.first = false});
  final KeyValue kv;
  final bool first;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: first ? null : const Border(top: BorderSide(color: AppColors.line))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(kv.label, style: AppText.secondary.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(kv.value, textAlign: TextAlign.right, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
          ),
        ],
      ),
    );
  }
}

/// Small grey caption (fd-cap), optionally with an icon.
class Caption extends StatelessWidget {
  const Caption(this.text, {super.key, this.icon});
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: 14, color: AppColors.muted), const SizedBox(width: 6)],
        Expanded(child: Text(text, style: AppText.caption.copyWith(height: 1.4))),
      ],
    );
  }
}

/// Grey rounded chip with the link url (jl-url) or when-asked label (ac-when).
class GreyTag extends StatelessWidget {
  const GreyTag(this.text, {super.key, this.icon});
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: AppColors.text2), const SizedBox(width: 6)],
          Flexible(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.text2)),
          ),
        ],
      ),
    );
  }
}

/// Two buttons side by side (cl-ebtns). [firstWidth] fixes the first one (wl-bk).
class ButtonPair extends StatelessWidget {
  const ButtonPair({super.key, required this.first, required this.second, this.firstWidth});
  final Widget first;
  final Widget second;
  final double? firstWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (firstWidth != null) SizedBox(width: firstWidth, child: first) else Expanded(child: first),
        const SizedBox(width: 10),
        Expanded(child: second),
      ],
    );
  }
}

/// Spinner block (ac-spin).
class CheckingSpinner extends StatelessWidget {
  const CheckingSpinner({super.key, required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 120, bottom: 40),
      child: Column(
        children: [
          const SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.accent, backgroundColor: AppColors.accentSoft),
          ),
          const SizedBox(height: 16),
          Text(title, style: AppText.bodyBold.copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(subtitle, style: AppText.secondary),
        ],
      ),
    );
  }
}

// ---------------- Sheets ----------------

/// "Need help?" sheet with support options; each shows a toast.
Future<void> showHelpSheet(BuildContext context, List<HelpOption> options, {String? caption}) {
  return showAppSheet(
    context,
    title: 'Need help?',
    subtitle: 'Support is available Mon–Sat, 9 am – 9 pm.',
    builder: (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < options.length; i++)
          MenuRow(
            first: i == 0,
            leading: MenuIcon(icon: options[i].icon),
            title: options[i].title,
            subtitle: options[i].subtitle,
            onTap: () {
              Navigator.of(ctx).pop();
              showToast(context, options[i].toastTitle, subtitle: options[i].toastSubtitle, kind: ToastKind.info);
            },
          ),
        if (caption != null) ...[const SizedBox(height: 8), Caption(caption)],
      ],
    ),
  );
}

/// "Terms and privacy" sheet. Returns true when the person taps I agree.
Future<bool> showTermsSheet(BuildContext context, List<TitledLine> terms, {required String subtitle}) async {
  final r = await showAppSheet<bool>(
    context,
    title: 'Terms and privacy',
    subtitle: subtitle,
    builder: (ctx) => Spaced(
      gap: 10,
      children: [
        for (final t in terms)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.title, style: AppText.bodyBold.copyWith(fontSize: 13.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(t.subtitle, style: AppText.caption.copyWith(fontSize: 12.5, color: AppColors.text2, height: 1.45)),
              ],
            ),
          ),
      ],
    ),
    actions: (ctx) => [
      AppButton.outline('Close', onPressed: () => Navigator.of(ctx).pop(false)),
      AppButton('I agree', onPressed: () => Navigator.of(ctx).pop(true)),
    ],
  );
  return r ?? false;
}

/// "I agree to the Terms of use and Privacy policy" checkbox with tappable links (wl-terms).
class TermsCheck extends StatelessWidget {
  const TermsCheck({super.key, required this.on, required this.onToggle, required this.onOpenTerms});
  final bool on;
  final VoidCallback onToggle;
  final VoidCallback onOpenTerms;

  @override
  Widget build(BuildContext context) {
    final link = AppText.bodyBold.copyWith(fontSize: 13.5, color: AppColors.accentText);
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(top: 2), child: CheckBox18(on)),
            const SizedBox(width: 10),
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('I agree to the ', style: AppText.body.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  GestureDetector(onTap: onOpenTerms, child: Text('Terms of use', style: link)),
                  Text(' and ', style: AppText.body.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  GestureDetector(onTap: onOpenTerms, child: Text('Privacy policy', style: link)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
