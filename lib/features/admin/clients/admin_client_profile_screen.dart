import 'package:flutter/material.dart';

import 'package:train_with_vimal/features/shared/client_profile/client_profile_controller.dart';
import 'package:train_with_vimal/features/shared/client_profile/client_profile_view.dart';

/// Design: ClientProfileMobile.dc.html — admin view: breadcrumb "Clients", can change trainer
/// and set a new password.
class AdminClientProfileScreen extends StatelessWidget {
  const AdminClientProfileScreen({super.key, required this.clientId});
  final String clientId;

  @override
  Widget build(BuildContext context) => ClientProfileView(clientId: clientId, role: ProfileRole.admin);
}
