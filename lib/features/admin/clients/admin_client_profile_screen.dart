import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';

/// Design: ClientProfileMobile.dc.html — TODO: build.
class AdminClientProfileScreen extends StatelessWidget {
  const AdminClientProfileScreen({super.key, required this.clientId});
  final String clientId;

  @override
  Widget build(BuildContext context) {
    return PageScroll(children: [PageHeader(title: 'AdminClientProfileScreen')]);
  }
}
