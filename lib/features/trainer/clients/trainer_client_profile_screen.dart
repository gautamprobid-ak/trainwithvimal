import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';

/// Design: TrainerClientProfileMobile.dc.html — TODO: build.
class TrainerClientProfileScreen extends StatelessWidget {
  const TrainerClientProfileScreen({super.key, required this.clientId});
  final String clientId;

  @override
  Widget build(BuildContext context) {
    return PageScroll(children: [PageHeader(title: 'TrainerClientProfileScreen')]);
  }
}
