import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/client_profile_mock.dart';
import 'package:train_with_vimal/data/models/client_profile.dart';

import '../client_profile_controller.dart';
import '../cp_widgets.dart';
import '../sheets/detail_sheets.dart';
import '../sheets/profile_sheets.dart';

typedef _M = ClientProfileMock;

class ContentTab extends StatefulWidget {
  const ContentTab({super.key});
  @override
  State<ContentTab> createState() => _ContentTabState();
}

class _ContentTabState extends State<ContentTab> {
  String filter = 'all';

  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    final visible = _M.content.where((x) => !c.hiddenContent.contains(x.title)).toList();
    final counts = {
      'all': visible.length,
      'assigned': visible.where((x) => x.group == 'assigned').length,
      'plans': visible.where((x) => x.group == 'plans').length,
      'everyone': visible.where((x) => x.group == 'everyone').length,
    };
    final list = visible.where((x) => filter == 'all' || x.group == filter).toList();
    return CpCard(
      titleWidget: Row(children: [
        Expanded(
          child: FChipBar(
            items: [('all', 'All'), ('assigned', 'Assigned to ${c.first}'), ('plans', 'From her plans'), ('everyone', 'Everyone')],
            value: filter,
            counts: counts,
            onChanged: (v) => setState(() => filter = v),
          ),
        ),
        InfoTip('Everything ${c.first} sees in the Library of her app, and why. Content from a plan goes away when that plan ends.'),
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: AppButton.outline('Assign content', icon: Icons.add_rounded, small: true, onPressed: () => showAssignContentSheet(context, c)),
          ),
          if (list.isEmpty)
            const EmptyState(icon: Icons.video_library_outlined, title: 'Nothing here', message: 'Try another filter.')
          else
            PfCards(columns: 2, [for (final x in list) _item(context, c, x)]),
        ],
      ),
    );
  }

  PfItem _item(BuildContext context, ClientProfileController c, ClientContent x) {
    final icon = switch (x.type) {
      'Video' => Icons.play_circle_outline_rounded,
      'PDF' => Icons.picture_as_pdf_outlined,
      'Image' => Icons.image_outlined,
      _ => Icons.article_outlined,
    };
    return PfItem(
      onTap: () => showContentSheet(context, c, x),
      head: Row(children: [CpIcon(icon, size: 28), const SizedBox(width: 8), Expanded(child: Text(x.title))]),
      action: IconButton(
        tooltip: 'More actions',
        icon: const Icon(Icons.more_horiz_rounded, size: 20, color: AppColors.text2),
        onPressed: () => _menu(context, c, x),
      ),
      fields: [
        ('Type', PfText(x.type)),
        ('Added by', PfText(x.by)),
        ('Why ${c.first} sees it', Align(alignment: Alignment.centerLeft, child: AppBadge(c.r(x.why), tone: x.whyTone))),
        ('Seen', x.seenBadge ? Align(alignment: Alignment.centerLeft, child: AppBadge(x.seen)) : PfText(x.seen, muted: true)),
      ],
    );
  }

  void _menu(BuildContext context, ClientProfileController c, ClientContent x) {
    final verb = x.assigned ? 'Remove' : 'Hide';
    showActionSheet(context, title: x.title, actions: [
      SheetAction('Preview', Icons.visibility_outlined, () => showContentSheet(context, c, x)),
      SheetAction('Change how long', Icons.schedule_rounded, () async {
        final v = await pickOption(context, title: 'How long she keeps it', options: const ['Always', 'Until plan ends', 'Until a date'], current: x.until == 'Always' ? 'Always' : 'Until plan ends');
        if (v != null && context.mounted) showToast(context, 'Updated how long she keeps it', subtitle: '${x.title} · $v', kind: ToastKind.ok);
      }),
      SheetAction('Remind her to open it', Icons.notifications_active_outlined, () => showToast(context, 'Reminder sent to ${c.first}', subtitle: x.title, kind: ToastKind.ok)),
      SheetAction('Open in library', Icons.open_in_new_rounded, () => showToast(context, 'Opened in the content library', subtitle: x.title, kind: ToastKind.info)),
      SheetAction('$verb for ${c.first}', Icons.delete_outline_rounded, destructive: true, () {
        c.hideContent(x.title);
        showToast(context, '${verb == 'Remove' ? 'Removed' : 'Hidden'} for ${c.first}', subtitle: x.title, kind: ToastKind.del, onUndo: () => c.showContent(x.title));
      }),
    ]);
  }
}
