import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';

/// Design: ExerciseDetailMobile.dc.html — TODO: build.
class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId});
  final String exerciseId;

  @override
  Widget build(BuildContext context) {
    return PageScroll(children: [PageHeader(title: 'ExerciseDetailScreen')]);
  }
}
