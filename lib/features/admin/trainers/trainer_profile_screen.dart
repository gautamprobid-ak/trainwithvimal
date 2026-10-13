import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';

/// Design: TrainerProfileMobile.dc.html — TODO: build.
class TrainerProfileScreen extends StatelessWidget {
  const TrainerProfileScreen({super.key, required this.trainerId});
  final String trainerId;

  @override
  Widget build(BuildContext context) {
    return PageScroll(children: [PageHeader(title: 'TrainerProfileScreen')]);
  }
}
