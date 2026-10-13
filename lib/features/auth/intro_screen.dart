import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';

/// Design: ClientIntro.dc.html — TODO: build.
class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScroll(children: [PageHeader(title: 'IntroScreen')]);
  }
}
