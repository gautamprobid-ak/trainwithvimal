import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';

/// Design: ClientWelcome.dc.html — TODO: build.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScroll(children: [PageHeader(title: 'WelcomeScreen')]);
  }
}
