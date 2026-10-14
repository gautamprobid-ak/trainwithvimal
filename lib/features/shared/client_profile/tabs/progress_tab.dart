import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/client_profile_mock.dart';
import 'package:train_with_vimal/data/models/client_profile.dart';

import '../client_profile_controller.dart';
import '../cp_widgets.dart';
import '../sheets/detail_sheets.dart';
import 'logs_tab.dart';
import 'overview_tab.dart';

typedef _M = ClientProfileMock;

class ProgressTab extends StatelessWidget {
  const ProgressTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    return Spaced(
      children: [
        LayoutBuilder(builder: (context, box) {
          final w = (box.maxWidth - 10) / 2;
          return Wrap(spacing: 10, runSpacing: 10, children: [for (final s in _M.progressStats) SizedBox(width: w, child: _PStat(s))]);
        }),
        const CpCard(title: 'Weight', cap: '30 days · goal 68 kg', trailing: RangeButton(), child: WeightChart()),
        CpCard(
          title: 'Measurements',
          cap: 'Taken every 2 weeks',
          child: PfCards([
            for (final m in [..._M.measurements, _M.measurementChange]) _measure(m, m == _M.measurementChange),
          ]),
        ),
        CpCard(
          title: 'Progress photos',
          cap: 'Start vs latest',
          action: 'All photos',
          onAction: () => showAllPhotosSheet(context, c),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: LayoutBuilder(builder: (context, box) {
              final w = (box.maxWidth - 10) / 2;
              return Wrap(spacing: 10, runSpacing: 12, children: [
                for (final (i, p) in _M.startVsLatest.indexed)
                  SizedBox(
                    width: w,
                    child: GestureDetector(
                      onTap: () => showPhotoViewer(context, c, date: p.$1 == '12 Jan' ? 0 : 4, angle: i < 2 ? 'Front' : 'Side'),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        AspectRatio(aspectRatio: 3 / 4, child: MediaBox(tone: p.$3, icon: Icons.person_outline_rounded)),
                        const SizedBox(height: 4),
                        Text.rich(TextSpan(style: AppText.caption, children: [
                          TextSpan(text: p.$1, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.text)),
                          TextSpan(text: ' · ${p.$2}'),
                        ])),
                      ]),
                    ),
                  ),
              ]);
            }),
          ),
        ),
        CpCard(
          title: 'Personal bests',
          cap: 'Heaviest set logged',
          child: PfCards([
            for (final b in _M.personalBests)
              PfItem(
                head: Text(b.exercise),
                fields: [
                  ('Start', PfText(b.start)),
                  ('Best', PfText(b.best)),
                  ('Change', PfText(b.change, bold: true, color: AppColors.okText)),
                ],
              ),
          ]),
        ),
      ],
    );
  }

  PfItem _measure(Measurement m, bool change) {
    Widget v(String s) => PfText(s, bold: change, color: change ? AppColors.okText : null);
    return PfItem(
      head: Text(m.date),
      fields: [
        ('Weight', v(m.weight)),
        ('Waist', v(m.waist)),
        ('Hips', v(m.hips)),
        ('Chest', v(m.chest)),
        ('Arm', v(m.arm)),
        ('Body fat', v(m.bodyFat)),
      ],
    );
  }
}

class _PStat extends StatelessWidget {
  const _PStat(this.s);
  final ProgressStat s;
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(s.label, style: AppText.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(color: AppColors.okBg, borderRadius: BorderRadius.circular(5)),
              child: Text(s.delta, style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.okText)),
            ),
          ]),
          const SizedBox(height: 4),
          Text(s.value, style: AppText.bigNumber.copyWith(fontSize: 20)),
          Text(s.sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption),
        ],
      ),
    );
  }
}
