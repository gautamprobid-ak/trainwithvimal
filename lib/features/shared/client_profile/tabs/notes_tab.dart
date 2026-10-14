import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/models/client_profile.dart';

import '../client_profile_controller.dart';
import '../cp_widgets.dart';
import 'overview_tab.dart';

class NotesTab extends StatefulWidget {
  const NotesTab({super.key});
  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> {
  final _text = TextEditingController();
  bool flag = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _save(ClientProfileController c) {
    final t = _text.text.trim();
    if (t.isEmpty) {
      showToast(context, 'Write a note first', kind: ToastKind.warn);
      return;
    }
    final by = c.isAdmin ? 'Vimal' : c.trainer;
    c.addNote(ProfileNote(t, by, 'just now', flag: flag));
    _text.clear();
    FocusScope.of(context).unfocus();
    showToast(context, flag ? 'Flag saved' : 'Note saved', subtitle: flag ? 'Shows in Needs attention' : 'Staff only', kind: ToastKind.ok);
    setState(() => flag = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    return CpCard(
      title: 'Notes',
      cap: 'Staff only. ${c.first} never sees these.',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _text, minLines: 3, maxLines: 6, style: AppText.body, decoration: InputDecoration(hintText: 'Write a note about ${c.first}…')),
            const SizedBox(height: 8),
            Row(children: [
              Checkbox(value: flag, onChanged: (v) => setState(() => flag = v ?? false), visualDensity: VisualDensity.compact),
              Expanded(child: Text('Mark as a flag (shows in Needs attention)', style: AppText.caption)),
              AppButton('Save note', small: true, onPressed: () => _save(c)),
            ]),
            const SizedBox(height: 12),
            for (final n in c.notes) ...[
              if (n.flag) _Flag(n) else NoteCard(n),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _Flag extends StatelessWidget {
  const _Flag(this.n);
  final ProfileNote n;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.warnBg, borderRadius: BorderRadius.circular(10)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.flag_rounded, size: 18, color: AppColors.warnText),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(n.text, style: AppText.bodyBold.copyWith(fontSize: 13.5, color: AppColors.warnText)),
            const SizedBox(height: 2),
            Text('Flag · ${n.by} · ${n.when}', style: AppText.caption.copyWith(color: AppColors.warnText)),
          ]),
        ),
      ]),
    );
  }
}
