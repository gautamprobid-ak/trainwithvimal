import 'package:flutter/material.dart';

import 'package:train_with_vimal/features/shared/client_profile/client_profile_controller.dart';
import 'package:train_with_vimal/features/shared/client_profile/client_profile_view.dart';

/// Design: TrainerClientProfileMobile.dc.html — trainer view: breadcrumb "My clients",
/// "Your client since …", no Change trainer (only Vimal can change it), reset link only.
class TrainerClientProfileScreen extends StatelessWidget {
  const TrainerClientProfileScreen({super.key, required this.clientId});
  final String clientId;

  @override
  Widget build(BuildContext context) => ClientProfileView(clientId: clientId, role: ProfileRole.trainer);
}
