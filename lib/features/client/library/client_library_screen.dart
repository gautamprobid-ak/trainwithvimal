import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/client_mock.dart';
import 'package:train_with_vimal/data/models/client_app.dart';

import '../more/client_ui.dart';
import 'library_viewer.dart';

/// Design: ClientLibrary.dc.html — videos, PDFs, images and articles from Aman.
class ClientLibraryScreen extends StatefulWidget {
  const ClientLibraryScreen({super.key});

  @override
  State<ClientLibraryScreen> createState() => _ClientLibraryScreenState();
}

class _ClientLibraryScreenState extends State<ClientLibraryScreen> {
  static const _items = ClientMock.library;
  static const _filters = [('all', 'All'), ('video', 'Videos'), ('pdf', 'PDFs'), ('image', 'Images'), ('article', 'Articles'), ('saved', 'Saved')];

  Set<String> _read = {...ClientMock.libraryRead0};
  Set<String> _done = {...ClientMock.libraryDone0};
  Set<String> _saved = {...ClientMock.librarySaved0};
  String _filter = 'all';
  final _search = TextEditingController();

  String get _q => _search.text.trim().toLowerCase();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _inFilter(LibraryItem x, String f) => f == 'all' || (f == 'saved' ? _saved.contains(x.id) : x.kind.name == f);

  bool _inQuery(LibraryItem x) =>
      _q.isEmpty || '${x.title} ${x.description} ${x.note} ${x.body.join(' ')}'.toLowerCase().contains(_q);

  void _toggleSave(LibraryItem x) {
    final prev = {..._saved};
    final on = _saved.contains(x.id);
    setState(() => on ? _saved.remove(x.id) : _saved.add(x.id));
    showToast(context, on ? 'Removed from saved' : 'Saved for later',
        subtitle: x.title, kind: on ? ToastKind.del : ToastKind.ok, onUndo: () => setState(() => _saved = prev));
  }

  void _toggleDone(LibraryItem x) {
    final prev = {..._done};
    final on = _done.contains(x.id);
    setState(() => on ? _done.remove(x.id) : _done.add(x.id));
    void undo() => setState(() => _done = prev);
    if (on) {
      showToast(context, 'Marked as not done', subtitle: x.title, kind: ToastKind.info, onUndo: undo);
    } else if (_done.length == _items.length) {
      showToast(context, 'All caught up!', subtitle: 'You finished everything Aman shared', kind: ToastKind.star, onUndo: undo);
    } else {
      showToast(context, 'Marked as done', subtitle: '${x.title} · ${_done.length} of ${_items.length} done', kind: ToastKind.ok, onUndo: undo);
    }
  }

  void _videoFinished(LibraryItem x) {
    if (_done.contains(x.id)) {
      showToast(context, 'Video finished', subtitle: x.title, kind: ToastKind.ok);
      return;
    }
    final prev = {..._done};
    setState(() => _done.add(x.id));
    showToast(context, 'Video finished · marked as done', subtitle: x.title, kind: ToastKind.star, onUndo: () => setState(() => _done = prev));
  }

  void _open(LibraryItem x) {
    setState(() => _read.add(x.id));
    showClientSheet<void>(
      context,
      builder: (ctx) => LibraryViewer(
        item: x,
        isSaved: () => _saved.contains(x.id),
        isDone: () => _done.contains(x.id),
        onSave: () => _toggleSave(x),
        onDone: () => _toggleDone(x),
        onFinished: () => _videoFinished(x),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shown = [for (final x in _items) if (_inFilter(x, _filter) && _inQuery(x)) x]
      ..sort((a, b) => (_read.contains(a.id) ? 1 : 0).compareTo(_read.contains(b.id) ? 1 : 0));
    final nNew = _items.where((x) => !_read.contains(x.id)).length;
    final fLabel = _filters.firstWhere((f) => f.$1 == _filter).$2;
    final cnt = _q.isNotEmpty
        ? '${shown.length}${shown.length == 1 ? ' result for “' : ' results for “'}$_q”'
        : '${_filter == 'saved' ? 'Saved for later' : _filter == 'all' ? 'Everything Aman shared with you' : fLabel} · ${shown.length}';
    final savedEmpty = _filter == 'saved' && _q.isEmpty;
    return PageScroll(
      children: [
        ClientTop(
          title: 'Library',
          subtitle: 'Videos, PDFs and guides from Aman',
          onBack: () => context.canPop() ? context.pop() : context.go(Routes.cMore),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text('${_done.length} of ${_items.length} done', style: AppText.bodyBold.copyWith(fontWeight: FontWeight.w800))),
                  Text(nNew > 0 ? '$nNew new from Aman' : 'All caught up', style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.accentText)),
                ],
              ),
              const SizedBox(height: 8),
              ProgressBar(_done.length / _items.length),
            ],
          ),
        ),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          style: AppText.bodyBold,
          decoration: InputDecoration(
            hintText: 'Search videos, PDFs and articles',
            prefixIcon: const Icon(Icons.search_rounded, size: 19, color: AppColors.muted),
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(tooltip: 'Clear search', icon: const Icon(Icons.close_rounded, size: 18), onPressed: () => setState(_search.clear)),
          ),
        ),
        TryRow(label: 'Try', chips: [
          for (final t in ClientMock.libraryTries)
            TryChip(t, selected: _q == t, onTap: () => setState(() => _search.text = _q == t ? '' : t)),
        ]),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final (id, n) in _filters) ...[
                ChoicePill(n, count: _items.where((x) => _inFilter(x, id)).length, selected: _filter == id, onTap: () => setState(() => _filter = id)),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ),
        if (shown.isNotEmpty)
          AppCard(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(cnt, style: AppText.caption.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                for (final x in shown)
                  _Row(
                    item: x,
                    isNew: !_read.contains(x.id),
                    isDone: _done.contains(x.id),
                    saved: _saved.contains(x.id),
                    onOpen: () => _open(x),
                    onSave: () => _toggleSave(x),
                  ),
              ],
            ),
          )
        else
          AppCard(
            child: EmptyState(
              icon: savedEmpty ? Icons.bookmark_border_rounded : Icons.search_off_rounded,
              title: savedEmpty ? 'Nothing saved yet' : 'Nothing found',
              message: savedEmpty ? 'Open an item and tap Save for later. It will show up here.' : 'Try another word or another type.',
              action: AppButton.outline('Show all content', small: true, onPressed: () => setState(() {
                    _filter = 'all';
                    _search.clear();
                  })),
            ),
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.item, required this.isNew, required this.isDone, required this.saved, required this.onOpen, required this.onSave});
  final LibraryItem item;
  final bool isNew;
  final bool isDone;
  final bool saved;
  final VoidCallback onOpen;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final x = item;
    final row = InkWell(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LibraryThumb(item: x),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(x.title, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                  Text('${x.kind.label} · ${x.length} · by ${x.by}', style: AppText.caption),
                  Text(x.source, style: AppText.caption.copyWith(fontSize: 11.5, color: AppColors.text2)),
                  if (x.note.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Row(children: [
                        const Icon(Icons.chat_bubble_outline_rounded, size: 12, color: AppColors.accentText),
                        const SizedBox(width: 4),
                        Text('Note from Aman', style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.accentText)),
                      ]),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isNew) const Pill('New', tone: PillTone.blue),
                if (isDone && !isNew) const Pill('Done', tone: PillTone.green, icon: Icons.check_rounded),
                IconButton(
                  tooltip: 'Save for later',
                  visualDensity: VisualDensity.compact,
                  onPressed: onSave,
                  icon: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, size: 20, color: saved ? AppColors.accent : AppColors.muted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    return isDone && !isNew ? Opacity(opacity: .8, child: row) : row;
  }
}
