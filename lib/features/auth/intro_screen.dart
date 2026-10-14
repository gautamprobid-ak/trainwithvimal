import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/auth_mock.dart';
import 'package:train_with_vimal/data/state/session.dart';

import 'widgets/auth_widgets.dart';

/// Design: ClientIntro.dc.html — 4-slide welcome guide. Skip / Get started finish
/// onboarding and open the client home.
class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen> {
  final _pages = PageController();
  int _i = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  int get _n => AuthMock.intro.length;

  void _to(int k) {
    if (k < 0 || k >= _n || k == _i) return;
    _pages.animateToPage(k, duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
  }

  void _finish() {
    final router = GoRouter.of(context);
    final session = ref.read(sessionProvider);
    if (session == null) {
      router.go(Routes.welcome);
      return;
    }
    ref.read(sessionProvider.notifier).completeOnboarding();
    router.go(session.role == Role.client ? Routes.cHome : homeFor(session.role));
  }

  @override
  Widget build(BuildContext context) {
    final last = _i == _n - 1;
    return Column(
      children: [
        _Top(showSkip: !last, onSkip: _finish),
        Expanded(
          child: PageView.builder(
            controller: _pages,
            itemCount: _n,
            onPageChanged: (k) => setState(() => _i = k),
            itemBuilder: (_, k) => _Slide(AuthMock.intro[k], numbers: k >= 2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 26),
          child: Column(
            children: [
              _Dots(count: _n, index: _i, onTap: _to),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (_i > 0) ...[
                    SizedBox(width: 48, child: AppButton.outline('', icon: Icons.arrow_back_rounded, onPressed: () => _to(_i - 1))),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: last
                        ? AppButton('Get started', icon: Icons.arrow_forward_rounded, expand: true, onPressed: _finish)
                        : AppButton('Next', icon: Icons.arrow_forward_rounded, expand: true, onPressed: () => _to(_i + 1)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Top extends StatelessWidget {
  const _Top({required this.showSkip, required this.onSkip});
  final bool showSkip;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 6, 14, 0),
        child: Row(
          children: [
            const Flexible(child: BrandRow(size: 30, fontSize: 15)),
            const Spacer(),
            if (showSkip)
              TextButton(
                onPressed: onSkip,
                child: Text('Skip', style: AppText.bodyBold.copyWith(fontSize: 13.5, color: AppColors.text2)),
              ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide(this.s, {required this.numbers});
  final IntroSlide s;
  final bool numbers;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                const BoxShadow(color: Color(0x0A171717), blurRadius: 2, offset: Offset(0, 1)),
                BoxShadow(color: AppColors.accent.withValues(alpha: .08), blurRadius: 24, offset: const Offset(0, 8)),
              ],
            ),
            child: Illustration(s.icon, height: 230, background: Colors.white),
          ),
          const SizedBox(height: 22),
          Text(s.kicker, style: AppText.overline.copyWith(fontSize: 11, letterSpacing: 1.3, color: AppColors.accent)),
          const SizedBox(height: 6),
          Text(s.title, style: AppText.pageTitle.copyWith(height: 1.15)),
          const SizedBox(height: 6),
          Text(s.body, style: AppText.secondary.copyWith(fontSize: 14.5, height: 1.5)),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < s.points.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _Point(s.points[i], numbers: numbers)),
              ],
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point(this.p, {required this.numbers});
  final KeyValue p;
  final bool numbers;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p.label,
              style: AppText.bodyBold.copyWith(
                fontSize: numbers ? 17 : 13.5,
                fontWeight: FontWeight.w800,
                color: numbers ? AppColors.accent : AppColors.text,
              )),
          const SizedBox(height: 1),
          Text(p.value, style: AppText.caption.copyWith(fontSize: 11.5, height: 1.3)),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index, required this.onTap});
  final int count;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var k = 0; k < count; k++)
          GestureDetector(
            onTap: () => onTap(k),
            child: Semantics(
              label: 'Slide ${k + 1} of $count',
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: k == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: k == index ? AppColors.accent : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
