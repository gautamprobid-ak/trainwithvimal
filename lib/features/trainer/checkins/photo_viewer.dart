import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/models/trainer_app.dart';

/// Full screen progress photo viewer (pv-back / phv): angles, zoom,
/// compare with last time, prev / next and thumbnails.
Future<void> showCheckinPhotos(BuildContext context, TrainerCheckin c, int start) {
  return showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierColor: const Color(0xE6101010),
    builder: (_) => Dialog.fullscreen(backgroundColor: const Color(0xFF151515), child: _PhotoViewer(checkin: c, start: start)),
  );
}

class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.checkin, required this.start});
  final TrainerCheckin checkin;
  final int start;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late int _i = widget.start;
  int _zoom = 100;
  bool _compare = false;

  TrainerCheckin get c => widget.checkin;
  int get n => c.photos.length;
  String get _day => c.sent.split(',').first;

  void _go(int k) => setState(() => _i = (_i + k + n) % n);

  @override
  Widget build(BuildContext context) {
    final sub = '${c.kindLabel} · ${c.sent} · photo ${_i + 1} of $n';
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${c.client} · ${c.photos[_i]}', style: AppText.cardTitle.copyWith(color: Colors.white)),
                      Text(sub, style: AppText.caption.copyWith(color: Colors.white70)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          _toolbar(),
          Expanded(child: _compare ? _two() : _one()),
          if (_compare) _diff(),
          _thumbs(),
        ],
      ),
    );
  }

  Widget _toolbar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          for (var j = 0; j < n; j++) ...[
            if (j > 0) const SizedBox(width: 4),
            _darkPill(c.photos[j], on: j == _i, onTap: () => setState(() => _i = j)),
          ],
          const SizedBox(width: 12),
          _zoomBtn(Icons.remove_rounded, 'Zoom out', () => setState(() => _zoom = (_zoom - 25).clamp(50, 200))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text('$_zoom%', style: AppText.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          _zoomBtn(Icons.add_rounded, 'Zoom in', () => setState(() => _zoom = (_zoom + 25).clamp(50, 200))),
          const SizedBox(width: 12),
          _darkPill('Compare with last time', icon: Icons.compare_rounded, on: _compare, onTap: () => setState(() => _compare = !_compare)),
        ],
      ),
    );
  }

  Widget _darkPill(String label, {required bool on, required VoidCallback onTap, IconData? icon}) {
    return Material(
      color: on ? Colors.white : const Color(0xFF2A2A2A),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 15, color: on ? AppColors.text : Colors.white), const SizedBox(width: 5)],
              Text(label, style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: on ? AppColors.text : Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _zoomBtn(IconData icon, String tip, VoidCallback onTap) => IconButton(
        onPressed: onTap,
        tooltip: tip,
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(backgroundColor: const Color(0xFF2A2A2A)),
        icon: Icon(icon, color: Colors.white, size: 18),
      );

  Widget _img(String tag, int tone) {
    const tones = [Color(0xFF3A3F47), Color(0xFF41474F), Color(0xFF4A4540)];
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: tones[tone % 3],
        child: Stack(
          children: [
            Center(
              child: Transform.scale(
                scale: _zoom / 100,
                child: const Icon(Icons.accessibility_new_rounded, size: 120, color: Color(0x55FFFFFF)),
              ),
            ),
            Positioned(
              left: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                child: Text(tag, style: AppText.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _one() {
    return Row(
      children: [
        IconButton(onPressed: () => _go(-1), tooltip: 'Previous photo', icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 30)),
        Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: _img('${c.photos[_i]} · $_day', _i))),
        IconButton(onPressed: () => _go(1), tooltip: 'Next photo', icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 30)),
      ],
    );
  }

  Widget _two() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(child: _img('${c.photos[_i]} · ${c.lastPhotoDate}', 2)),
          const SizedBox(width: 8),
          Expanded(child: _img('${c.photos[_i]} · $_day', _i)),
        ],
      ),
    );
  }

  Widget _diff() {
    final items = [
      ('Weight', '${c.lastWeight} → ${c.kpis[0].value}'),
      ('Change', c.kpis[1].value),
      ('Between', '${c.lastPhotoDate} and $_day'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 16,
        runSpacing: 4,
        children: [
          for (final (k, v) in items)
            Text.rich(TextSpan(children: [
              TextSpan(text: '$k  ', style: AppText.caption.copyWith(color: Colors.white60, fontWeight: FontWeight.w600)),
              TextSpan(text: v, style: AppText.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
            ])),
        ],
      ),
    );
  }

  Widget _thumbs() {
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        itemCount: n,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, j) => GestureDetector(
          onTap: () => setState(() => _i = j),
          child: Container(
            width: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: j == _i ? Colors.white : Colors.transparent, width: 2),
            ),
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(c.photos[j], style: AppText.caption.copyWith(fontSize: 10.5, color: Colors.white70, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}
