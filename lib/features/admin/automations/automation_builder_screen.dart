import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'widgets/automation_editor.dart';

/// Design: AutomationBuilderMobile.dc.html — edit an automation (`?id=`,
/// "Client onboarding" by default) or start from a ready-made one
/// (`?starter=`).
class AutomationBuilderScreen extends StatelessWidget {
  const AutomationBuilderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final q = GoRouterState.of(context).uri.queryParameters;
    final starter = q['starter'];
    final id = q['id'] ?? (starter == null ? 'a-onboarding' : null);
    return AutomationEditor(key: ValueKey('${id ?? ''}|${starter ?? ''}'), id: id, starterId: starter);
  }
}
