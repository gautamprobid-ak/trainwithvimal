import 'dart:async';

import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/client_mock.dart';
import 'package:train_with_vimal/data/models/client_app.dart';

import '../more/client_ui.dart';

(Color, Color) libraryTone(int tone) => switch (tone) {
      1 => (const Color(0xFFEAF0FE), const Color(0xFF1D4ED8)),
      2 => (const Color(0xFFE8F6EE), const Color(0xFF11663D)),
      3 => (const Color(0xFFFFF4E0), const Color(0xFF9A5B00)),
      _ => (const Color(0xFFF1ECFE), const Color(0xFF6D28D9)),
    };

IconData libraryIcon(LibraryKind k) => switch (k) {
      LibraryKind.video => Icons.play_circle_rounded,
      LibraryKind.pdf => Icons.picture_as_pdf_rounded,
      LibraryKind.image => Icons.image_rounded,
      LibraryKind.article => Icons.article_rounded,
    };

/// 52 px tinted thumbnail with the kind icon (lb-th).
class LibraryThumb extends StatelessWidget {
  const LibraryThumb({super.key, required this.item});
  final LibraryItem item;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = libraryTone(item.tone);
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Stack(
        children: [
          Center(child: Icon(libraryIcon(item.kind), size: 22, color: fg)),
          if (item.kind == LibraryKind.video)
            Positioned(
              right: 3,
              bottom: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .88), borderRadius: BorderRadius.circular(4)),
                child: Text(item.length, style: AppText.caption.copyWith(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.text)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Viewer sheet: video player (fast demo playback), PDF pages, image or article.
class LibraryViewer extends StatefulWidget {
  const LibraryViewer({
    super.key,
    required this.item,
    required this.isSaved,
    required this.isDone,
    required this.onSave,
    required this.onDone,
    required this.onFinished,
  });
  final LibraryItem item;
  final bool Function() isSaved;
  final bool Function() isDone;
  final VoidCallback onSave;
  final VoidCallback onDone;
  final VoidCallback onFinished;

  @override
  State<LibraryViewer> createState() => _LibraryViewerState();
}

class _LibraryViewerState extends State<LibraryViewer> {
  int _pos = 0;
  int _page = 0;
  bool _playing = false;
  Timer? _timer;

  LibraryItem get _x => widget.item;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _mm(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  void _play(bool on) {
    _timer?.cancel();
    setState(() {
      _playing = on;
      if (on && _pos >= _x.duration) _pos = 0;
    });
    if (!on) return;
    // Plays fast in the demo: 15 s per second; finishing marks it done.
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final np = (_pos + 15).clamp(0, _x.duration);
      setState(() => _pos = np);
      if (np >= _x.duration) {
        t.cancel();
        setState(() => _playing = false);
        widget.onFinished();
      }
    });
  }

  int get _chapter {
    var ci = 0;
    for (var i = 0; i < _x.chapters.length; i++) {
      if (_pos >= _x.chapters[i].$1) ci = i;
    }
    return ci;
  }

  @override
  Widget build(BuildContext context) {
    final saved = widget.isSaved(), done = widget.isDone();
    return ClientSheet(
      title: _x.title,
      subtitle: '${_x.kind.label} · ${_x.length} · ${_x.source}',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...switch (_x.kind) {
            LibraryKind.video => [_video()],
            LibraryKind.pdf => [_pdf()],
            LibraryKind.image => [_image()],
            LibraryKind.article => const <Widget>[],
          },
          if (_x.note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.okBg, borderRadius: BorderRadius.circular(12)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Avatar('AV', size: 32, color: AvatarColor.c2),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('From Aman', style: AppText.bodyBold.copyWith(fontSize: 13)),
                        Text(_x.note, style: AppText.body.copyWith(fontSize: 13.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(_x.description, style: AppText.body.copyWith(color: AppColors.text2)),
          if (_x.kind == LibraryKind.video) ...[
            const Overline('Chapters', padding: EdgeInsets.only(top: 14, bottom: 4)),
            for (var i = 0; i < _x.chapters.length; i++)
              InkWell(
                onTap: () {
                  setState(() => _pos = _x.chapters[i].$1);
                  _play(true);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                  decoration: BoxDecoration(color: _pos > 0 && i == _chapter ? AppColors.accentSoft : null, borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    SizedBox(width: 44, child: Text(_mm(_x.chapters[i].$1), style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.accentText))),
                    Expanded(child: Text(_x.chapters[i].$2, style: AppText.bodyBold.copyWith(fontSize: 13.5))),
                  ]),
                ),
              ),
          ],
          if (_x.kind == LibraryKind.article) ...[
            const SizedBox(height: 4),
            for (final p in _x.body) Padding(padding: const EdgeInsets.only(top: 10), child: Text(p, style: AppText.body)),
          ],
        ],
      ),
      actions: [
        AppButton.outline(saved ? 'Saved' : 'Save for later', icon: saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, onPressed: () {
          widget.onSave();
          setState(() {});
        }),
        done
            ? AppButton.outline('Done · undo', icon: Icons.check_circle_rounded, onPressed: () {
                _play(false);
                widget.onDone();
                setState(() {});
              })
            : AppButton('Mark as done', icon: Icons.check_rounded, onPressed: () {
                _play(false);
                widget.onDone();
                setState(() {});
              }),
      ],
    );
  }

  Widget _video() {
    final (bg, fg) = libraryTone(_x.tone);
    final ch = _x.chapters[_chapter].$2;
    final label = _playing
        ? 'Playing · $ch'
        : _pos >= _x.duration
            ? 'Finished · tap to watch again'
            : _pos > 0
                ? 'Paused · $ch'
                : 'Tap to play';
    return Container(
      height: 190,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Icon(Icons.videocam_rounded, size: 15, color: fg),
            const SizedBox(width: 5),
            Expanded(child: Text(label, style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: fg))),
          ]),
          Expanded(
            child: Center(
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _play(!_playing),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 30, color: fg),
                  ),
                ),
              ),
            ),
          ),
          ProgressBar(_pos / _x.duration, color: fg, track: Colors.white70, height: 4),
          const SizedBox(height: 4),
          Row(children: [
            Text(_mm(_pos), style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: fg)),
            const Spacer(),
            Text(_x.length, style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: fg)),
          ]),
        ],
      ),
    );
  }

  Widget _pdf() {
    final pages = _x.pages;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 200,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_x.file ?? '', style: AppText.caption.copyWith(fontSize: 10.5)),
              const SizedBox(height: 10),
              Text(pages[_page].$1, style: AppText.bodyBold.copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(pages[_page].$2, style: AppText.body.copyWith(fontSize: 13)),
              const Spacer(),
              for (final w in const [1.0, 1.0, .6]) ...[
                FractionallySizedBox(widthFactor: w, child: Container(height: 6, decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(3)))),
                const SizedBox(height: 6),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Opacity(
              opacity: _page == 0 ? .4 : 1,
              child: AppIconButton(Icons.chevron_left_rounded, small: true, tooltip: 'Previous page', onPressed: () => _page > 0 ? setState(() => _page--) : null),
            ),
            const SizedBox(width: 8),
            Text('Page ${_page + 1} of ${pages.length}', style: AppText.caption.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Opacity(
              opacity: _page == pages.length - 1 ? .4 : 1,
              child: AppIconButton(Icons.chevron_right_rounded,
                  small: true, tooltip: 'Next page', onPressed: () => _page < pages.length - 1 ? setState(() => _page++) : null),
            ),
            const Spacer(),
            AppButton.outline('Download',
                small: true,
                icon: Icons.download_rounded,
                onPressed: () => showToast(context, 'Downloaded', subtitle: '${_x.file} · saved to your files', kind: ToastKind.ok)),
          ],
        ),
      ],
    );
  }

  Widget _image() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.okBg, borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('10 veg snacks under 200 kcal', style: AppText.bodyBold.copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
              Text('Train With Vimal · nutrition', style: AppText.caption),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 2.8,
                children: [
                  for (final (n, k) in ClientMock.vegSnacks)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(n, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodyBold.copyWith(fontSize: 11.5)),
                          Text(k, style: AppText.caption.copyWith(fontSize: 11, color: AppColors.okText, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Text('PNG image · 1 page', style: AppText.caption.copyWith(fontWeight: FontWeight.w700)),
          const Spacer(),
          AppButton.outline('Save image',
              small: true, icon: Icons.download_rounded, onPressed: () => showToast(context, 'Image saved', subtitle: 'Find it in your photos', kind: ToastKind.ok)),
        ]),
      ],
    );
  }
}
