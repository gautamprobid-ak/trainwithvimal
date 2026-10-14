import 'package:flutter/material.dart';

import 'widgets/automation_editor.dart';

/// Design: AutomationNewMobile.dc.html — a blank automation: pick the
/// trigger, who it is for and the steps.
class AutomationNewScreen extends StatelessWidget {
  const AutomationNewScreen({super.key});

  @override
  Widget build(BuildContext context) => const AutomationEditor();
}
