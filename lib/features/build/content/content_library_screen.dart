import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/models/library.dart';

import '../nutrition/library_widgets.dart';
import 'content_sheets.dart';
import 'content_state.dart';

/// Design: ContentMobile — "Content library": videos, articles, PDFs and
/// images by category; open, edit, assign, delete; new content / category.
class ContentLibraryScreen extends ConsumerStatefulWidget {
  const ContentLibraryScreen({super.key});

  @override
  ConsumerState<ContentLibraryScreen> createState() => _ContentLibraryScreenState();
}

class _ContentLibraryScreenState extends ConsumerState<ContentLibraryScreen> {
  static const _pageSize = 8;
  String _cat = '';
  ContentKind? _kind;
  String _q = '';
  int _page = 0;

  late final _actions = ContentActions(
    context: context,
    ref: ref,
    onAdded: () => setState(() {
      _cat = '';
      _kind = null;
      _page = 0;
    }),
    onCategory: (c) => setState(() {
      _cat = c;
      _page = 0;
    }),
  );

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(contentProvider);
    final cats = ref.watch(contentCategoriesProvider);
    final shown = items
        .where((x) => (_cat.isEmpty || x.category == _cat) && (_kind == null || x.kind == _kind) && x.title.toLowerCase().contains(_q.toLowerCase()))
        .toList();
    final pages = (shown.length / _pageSize).ceil().clamp(1, 999);
    final pg = _page.clamp(0, pages - 1);
    final page = shown.skip(pg * _pageSize).take(_pageSize).toList();
    return PageScroll(
      children: [
        const SubPageHeader(title: 'Content library'),
        Text('Videos, articles, PDFs and images. Use them in exercises, programs and meal plans, or share them with clients.', style: AppText.secondary),
        Row(children: [
          Expanded(child: AppButton.outline('New category', icon: Icons.create_new_folder_outlined, expand: true, onPressed: () => _actions.newCategory(_cat))),
          const SizedBox(width: 10),
          Expanded(child: AppButton('New content', icon: Icons.add_rounded, expand: true, onPressed: () => _actions.edit(null, category: _cat))),
        ]),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final (id, t) in [('', 'All content'), for (final c in cats) (c, c)]) ...[
              CountChip(t,
                  count: id.isEmpty ? items.length : items.where((x) => x.category == id).length,
                  selected: _cat == id,
                  onTap: () => setState(() {
                        _cat = id;
                        _page = 0;
                      })),
              const SizedBox(width: 6),
            ],
          ]),
        ),
        Row(children: [
          const SizedBox(width: 72, child: ProgressBar(.23, height: 5, track: AppColors.sub)),
          const SizedBox(width: 10),
          Text('Storage: 4.6 GB of 20 GB used', style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w600)),
        ]),
        SearchField(hint: 'Search the library', onChanged: (v) => setState(() {
              _q = v;
              _page = 0;
            })),
        PillTabs<ContentKind?>(
          items: const [(null, 'All', null), (ContentKind.video, 'Videos', null), (ContentKind.article, 'Articles', null), (ContentKind.pdf, 'PDFs', null), (ContentKind.image, 'Images', null)],
          value: _kind,
          onChanged: (k) => setState(() {
            _kind = k;
            _page = 0;
          }),
        ),
        if (page.isEmpty)
          const AppCard(
            child: EmptyState(icon: Icons.video_library_outlined, title: 'Nothing in this category yet', message: 'Add a video, article, PDF or image.'),
          ),
        for (var i = 0; i < page.length; i += 2)
          IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(child: _ContentCard(item: page[i], actions: _actions)),
              const SizedBox(width: 10),
              Expanded(child: i + 1 < page.length ? _ContentCard(item: page[i + 1], actions: _actions) : const SizedBox()),
            ]),
          ),
        Row(children: [
          const SizedBox(width: 4),
          Expanded(
            child: Text(shown.isEmpty ? '0 items' : '${pg * _pageSize + 1}–${(pg * _pageSize + _pageSize).clamp(0, shown.length)} of ${shown.length} items',
                style: AppText.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
          AppIconButton(Icons.chevron_left_rounded, small: true, tooltip: 'Previous page', onPressed: pg > 0 ? () => setState(() => _page = pg - 1) : null),
          const SizedBox(width: 6),
          AppIconButton(Icons.chevron_right_rounded, small: true, tooltip: 'Next page', onPressed: pg < pages - 1 ? () => setState(() => _page = pg + 1) : null),
        ]),
      ],
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({required this.item, required this.actions});
  final ContentItem item;
  final ContentActions actions;

  @override
  Widget build(BuildContext context) {
    final x = item;
    final used = x.uses.isNotEmpty
        ? '${x.uses.first.what}: ${x.uses.first.name.split(' · ').first}${x.uses.length > 1 ? '  +${x.uses.length - 1}' : ''}'
        : 'Not used yet';
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => actions.open(x),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ContentThumb(item: x),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                height: 36,
                child: Text(x.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.bodyBold.copyWith(fontSize: 13.5, height: 1.35)),
              ),
              const SizedBox(height: 2),
              Text('${x.kind == ContentKind.image ? 'Image' : x.length} · ${x.category}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption),
              const SizedBox(height: 6),
              Tooltip(
                message: x.uses.map((u) => '${u.what}: ${u.name}').join('  |  '),
                child: GreyTag(used, blue: x.uses.isNotEmpty, icon: x.uses.isNotEmpty ? Icons.link_rounded : null),
              ),
            ]),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 2, 2),
            child: Row(children: [
              Icon(x.everyone ? Icons.public_rounded : Icons.person_outline_rounded, size: 14, color: x.everyone ? AppColors.okText : AppColors.muted),
              const SizedBox(width: 5),
              Expanded(
                child: Text(whoLabel(x),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: x.everyone ? AppColors.okText : (x.clients.isEmpty ? AppColors.muted : AppColors.text2))),
              ),
              DotsButton(onPressed: () => actions.menu(x), tooltip: 'Content options'),
            ]),
          ),
        ],
      ),
    );
  }
}
