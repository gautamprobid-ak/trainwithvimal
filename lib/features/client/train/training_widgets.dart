import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/client_training_mock.dart';
import 'package:train_with_vimal/data/models/training.dart';

/// ch-ic colour names from the design → tint.
Tint tintOf(String c) => switch (c) {
      'amber' => Tint.amber,
      'blue' => Tint.blue,
      'green' => Tint.green,
      'purple' => Tint.purple,
      'warm' => Tint.orange,
      'red' => Tint.red,
      _ => Tint.gray,
    };

IconData feedIcon(FeedIcon i) => switch (i) {
      FeedIcon.form => Icons.assignment_outlined,
      FeedIcon.dumbbell => Icons.fitness_center_rounded,
      FeedIcon.bell => Icons.notifications_none_rounded,
      FeedIcon.calendar => Icons.event_rounded,
      FeedIcon.flag => Icons.flag_outlined,
    };

// ---------------------------------------------------------------- sheets

/// Body of a sheet whose title/subtitle/actions can change while it is open.
class SheetContent extends StatelessWidget {
  const SheetContent({super.key, required this.title, this.subtitle, required this.body, this.actions = const [], this.scrollable = true});
  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget> actions;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppText.cardTitle.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: AppText.secondary.copyWith(fontSize: 12.5)),
                      ],
                    ],
                  ),
                ),
                AppIconButton(Icons.close_rounded, small: true, onPressed: () => Navigator.of(context).pop()),
              ],
            ),
          ),
          Flexible(
            child: scrollable
                ? SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: body)
                : Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: body),
          ),
          if (actions.isNotEmpty)
            Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
              child: Row(
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: actions[i]),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Bottom sheet with local state: [builder] returns a [SheetContent].
Future<T?> showLiveSheet<T>(BuildContext context, {required Widget Function(BuildContext ctx, StateSetter setSheet) builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .88),
    builder: (ctx) => StatefulBuilder(builder: builder),
  );
}

// ---------------------------------------------------------------- small pieces

/// fd-pill: small rounded label.
class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.tone = 'gray'});
  final String text;
  final String tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      'green' => (AppColors.okBg, AppColors.okText),
      'amber' => (const Color(0xFFFFF4DB), const Color(0xFFA15C00)),
      'blue' => (AppColors.infoBg, AppColors.infoText),
      'red' => (AppColors.badBg, AppColors.badText),
      _ => (AppColors.sub, AppColors.text2),
    };
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(text, style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

/// Green "✓ Done" / "Taken" label (ch-ok).
class OkLabel extends StatelessWidget {
  const OkLabel(this.text, {super.key, this.icon = true});
  final String text;
  final bool icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon) ...[const Icon(Icons.check_rounded, size: 14, color: AppColors.okText), const SizedBox(width: 3)],
        Text(text, style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.okText)),
      ],
    );
  }
}

/// Soft gradient head of a workout card (ch-whero).
class WorkoutHero extends StatelessWidget {
  const WorkoutHero({super.key, required this.label, required this.icon, required this.title, this.trailing, this.gradient = AppColors.greenHero, this.bottom});
  final String label;
  final IconData icon;
  final String title;
  final Widget? trailing;
  final Gradient gradient;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(gradient: gradient, border: const Border(bottom: BorderSide(color: AppColors.line))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: AppColors.text2),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label.toUpperCase(),
                    style: AppText.overline.copyWith(fontSize: 11.5, letterSpacing: .6, color: AppColors.text2)),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 4),
          Text(title, style: AppText.heroTitle.copyWith(fontSize: 21)),
          if (bottom != null) ...[const SizedBox(height: 6), bottom!],
        ],
      ),
    );
  }
}

/// White tag inside the hero (ch-wtags).
class HeroTag extends StatelessWidget {
  const HeroTag(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .85),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(text, style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.text2)),
    );
  }
}

/// Progress line with "x of y done" (ch-wf).
class DoneProgress extends StatelessWidget {
  const DoneProgress({super.key, required this.value, required this.label, this.color = const Color(0xFF22C55E)});
  final double value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: ProgressBar(value, color: color)),
        const SizedBox(width: 10),
        Text(label, style: AppText.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// Blue strip: "Session with Aman · 6:30 pm · Gym floor" (ch-sess).
class SessionStrip extends StatelessWidget {
  const SessionStrip({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const fg = Color(0xFF1E3A8A);
    final st = AppText.secondary.copyWith(fontSize: compact ? 12.5 : 13, color: fg);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 11, vertical: compact ? 7 : 9),
      decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          const Icon(Icons.event_rounded, size: 16, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(TextSpan(style: st, children: [
              const TextSpan(text: 'Session with '),
              TextSpan(text: ClientTrainingMock.coach, style: st.copyWith(fontWeight: FontWeight.w800)),
              const TextSpan(text: ' · 6:30 pm · Gym floor'),
            ])),
          ),
        ],
      ),
    );
  }
}

/// Coach note card (ch-coach).
class CoachNoteCard extends StatelessWidget {
  const CoachNoteCard({super.key, required this.title, required this.subtitle, required this.text, this.compact = false});
  final String title;
  final String subtitle;
  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Avatar('AV', size: 32, color: AvatarColor.c2),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.cardTitle.copyWith(fontWeight: FontWeight.w800)),
                    Text(subtitle, style: AppText.secondary.copyWith(fontSize: 12.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(text, style: AppText.body.copyWith(fontSize: compact ? 13 : 14, height: 1.5, color: AppColors.text2)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- exercise guide

/// Full screen exercise guide (video, coach note, target, how to, cues, muscles, details).
Future<void> showExerciseGuide(BuildContext context, int index) {
  return showDialog<void>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) => Dialog.fullscreen(backgroundColor: AppColors.bg, child: SafeArea(child: ExerciseGuide(index: index))),
  );
}

class ExerciseGuide extends StatelessWidget {
  const ExerciseGuide({super.key, required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    final list = ClientTrainingMock.todayExercises;
    final g = list[index];
    void close() => Navigator.of(context).pop();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              AppIconButton(Icons.arrow_back_rounded, small: true, onPressed: close),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Exercise guide', style: AppText.cardTitle.copyWith(fontWeight: FontWeight.w800)),
                    Text('${ClientTrainingMock.todayTitle} · Exercise ${index + 1} of ${list.length}', style: AppText.caption),
                  ],
                ),
              ),
              AppIconButton(Icons.close_rounded, small: true, onPressed: close),
            ],
          ),
        ),
        Expanded(
          child: PageScroll(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(g.name, style: AppText.sectionTitle.copyWith(fontSize: 23)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: [for (final t in [g.group, g.equipment, g.level]) AppChip(t)]),
                ],
              ),
              _GuideVideo(g: g),
              _GuideNote(g: g),
              _GuideTarget(g: g),
              _GuideSteps(g: g),
              _GuideCues(g: g),
              _GuideMuscles(g: g),
              _GuideDetails(g: g),
            ],
          ),
        ),
      ],
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({required this.title, this.count, required this.children});
  final String title;
  final int? count;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Text(title, style: AppText.cardTitle.copyWith(fontWeight: FontWeight.w800)),
            if (count != null) ...[const SizedBox(width: 6), Text('$count', style: AppText.caption.copyWith(fontWeight: FontWeight.w700))],
          ]),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _GuideVideo extends StatelessWidget {
  const _GuideVideo({required this.g});
  final LogExercise g;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => showToast(context, g.video, subtitle: 'Video plays from the content library', kind: ToastKind.info),
          child: Container(
            height: 190,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(colors: [Color(0xFF1F2937), Color(0xFF374151)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Stack(
              children: [
                Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), shape: BoxShape.circle),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 10,
                  child: Text(g.videoLength, style: AppText.caption.copyWith(color: Colors.white.withValues(alpha: .85), fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.play_circle_outline_rounded, size: 15, color: AppColors.text2),
            const SizedBox(width: 5),
            Expanded(child: Text(g.video, style: AppText.secondary.copyWith(fontWeight: FontWeight.w700, color: AppColors.text2))),
            Text('From content library', style: AppText.caption),
          ],
        ),
      ],
    );
  }
}

class _GuideNote extends StatelessWidget {
  const _GuideNote({required this.g});
  final LogExercise g;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                Text('Note from ${ClientTrainingMock.coach}', style: AppText.caption.copyWith(fontWeight: FontWeight.w800, color: AppColors.okText)),
                const SizedBox(height: 2),
                Text(g.note, style: AppText.body.copyWith(fontSize: 13.5, color: AppColors.text)),
                const SizedBox(height: 2),
                Text('On this exercise in ${ClientTrainingMock.programName}', style: AppText.caption.copyWith(fontSize: 11.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideTarget extends StatelessWidget {
  const _GuideTarget({required this.g});
  final LogExercise g;

  @override
  Widget build(BuildContext context) {
    return _GuideCard(
      title: 'Today’s target',
      children: [
        Row(
          children: [
            for (var i = 0; i < g.tiles.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    children: [
                      Text(g.tiles[i].$1, style: AppText.cardTitle.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
                      Text(g.tiles[i].$2, style: AppText.caption),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Text(g.extra, style: AppText.secondary.copyWith(color: AppColors.text2)),
        const SizedBox(height: 4),
        Text('Last time: ${g.prev.join(' · ')}${g.pr.isNotEmpty ? ' · PR ${g.pr}' : ''}', style: AppText.caption),
      ],
    );
  }
}

class _NumberedRow extends StatelessWidget {
  const _NumberedRow({required this.lead, required this.text, this.accent = false});
  final Widget lead;
  final String text;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: accent ? AppColors.accentSoft : AppColors.sub, shape: BoxShape.circle),
            child: lead,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(text, style: AppText.secondary.copyWith(fontSize: 12.5, height: 1.45, color: AppColors.text2)),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideSteps extends StatelessWidget {
  const _GuideSteps({required this.g});
  final LogExercise g;

  @override
  Widget build(BuildContext context) {
    return _GuideCard(
      title: 'How to',
      count: g.steps.length,
      children: [
        for (var i = 0; i < g.steps.length; i++)
          _NumberedRow(lead: Text('${i + 1}', style: AppText.caption.copyWith(fontWeight: FontWeight.w800, color: AppColors.text2)), text: g.steps[i]),
      ],
    );
  }
}

class _GuideCues extends StatelessWidget {
  const _GuideCues({required this.g});
  final LogExercise g;

  @override
  Widget build(BuildContext context) {
    return _GuideCard(
      title: 'Form cues',
      count: g.cues.length,
      children: [
        for (final c in g.cues) _NumberedRow(lead: const Icon(Icons.check_rounded, size: 14, color: AppColors.accent), text: c, accent: true),
      ],
    );
  }
}

class _GuideMuscles extends StatelessWidget {
  const _GuideMuscles({required this.g});
  final LogExercise g;

  @override
  Widget build(BuildContext context) {
    return _GuideCard(
      title: 'Muscles',
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PRIMARY MUSCLE', style: AppText.overline.copyWith(fontSize: 10.5)),
              Text(g.primary, style: AppText.cardTitle.copyWith(fontWeight: FontWeight.w800)),
              Text(g.primarySub, style: AppText.caption),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text('ALSO WORKS', style: AppText.overline.copyWith(fontSize: 10.5)),
        const SizedBox(height: 6),
        for (final a in g.also)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.name, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                      Text(a.sub, style: AppText.caption),
                    ],
                  ),
                ),
                for (var i = 0; i < 3; i++)
                  Container(
                    width: 8,
                    height: 14,
                    margin: const EdgeInsets.only(left: 2),
                    decoration: BoxDecoration(
                      color: i == 0 || (i == 1 && a.level == 'Strong') ? AppColors.accent : AppColors.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                const SizedBox(width: 8),
                SizedBox(width: 44, child: Text(a.level, style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.text2))),
              ],
            ),
          ),
        const SizedBox(height: 4),
        const _BodyMap(),
      ],
    );
  }
}

class _BodyMap extends StatelessWidget {
  const _BodyMap();

  @override
  Widget build(BuildContext context) {
    Widget fig(String cap) => Expanded(
          child: Column(
            children: [
              const Icon(Icons.accessibility_new_rounded, size: 84, color: Color(0xFFA8C2F7)),
              Text(cap, style: AppText.caption.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        );
    Widget leg(Color c, String t) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 5),
          Text(t, style: AppText.caption),
        ]);
    return Column(
      children: [
        Row(children: [fig('Front'), fig('Back')]),
        const SizedBox(height: 8),
        Wrap(spacing: 14, children: [
          leg(AppColors.accent, 'Primary'),
          leg(const Color(0xFF7CA6F5), 'Strong'),
          leg(const Color(0xFFC7D7FB), 'Light'),
        ]),
      ],
    );
  }
}

class _GuideDetails extends StatelessWidget {
  const _GuideDetails({required this.g});
  final LogExercise g;

  @override
  Widget build(BuildContext context) {
    final rows = [('Muscle group', g.group), ('Equipment', g.equipment), ('Level', g.level), ('You log', g.logs), ('Cover image', g.cover)];
    return _GuideCard(
      title: 'Details',
      children: [
        for (var i = 0; i < rows.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(border: i == 0 ? null : const Border(top: BorderSide(color: AppColors.line))),
            child: Row(
              children: [
                Expanded(child: Text(rows[i].$1, style: AppText.secondary)),
                Text(rows[i].$2, style: AppText.bodyBold.copyWith(fontSize: 13)),
              ],
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------- past workouts

/// "Past workouts" sheet: filter, list, then one workout's sets.
Future<void> showPastWorkouts(BuildContext context, {bool thisOnly = false}) {
  var filterThis = thisOnly;
  PastWorkout? sel;
  return showLiveSheet(
    context,
    builder: (ctx, setSheet) {
      final all = ClientTrainingMock.pastWorkouts;
      final list = all.where((w) => !filterThis || w.name == ClientTrainingMock.todayTitle).toList();
      final s = sel;
      if (s != null) {
        return SheetContent(
          title: s.name,
          subtitle: '${TDate.wdm(s.date)} · ${s.minutes} min',
          body: _PastDetail(w: s, onBack: () => setSheet(() => sel = null)),
        );
      }
      return SheetContent(
        title: 'Past workouts',
        subtitle: '${list.length} ${list.length == 1 ? 'workout' : 'workouts'}${filterThis ? ' · this workout only' : ' · since 18 Sep'}',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedTabs<bool>(
              items: const [(true, ClientTrainingMock.todayTitle), (false, 'All workouts')],
              value: filterThis,
              onChanged: (v) => setSheet(() => filterThis = v),
            ),
            const SizedBox(height: 10),
            if (list.isEmpty)
              Text('No past workouts yet.', style: AppText.secondary)
            else
              Container(
                decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(12)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < list.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      _PastRow(w: list[i], onTap: () => setSheet(() => sel = list[i])),
                    ],
                  ],
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _PrTag extends StatelessWidget {
  const _PrTag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: AppColors.warnBg, borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.emoji_events_rounded, size: 11, color: AppColors.warnText),
        const SizedBox(width: 3),
        Text(text, style: AppText.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.warnText)),
      ]),
    );
  }
}

class _PastRow extends StatelessWidget {
  const _PastRow({required this.w, required this.onTap});
  final PastWorkout w;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 48,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(9)),
              child: Column(children: [
                Text(TDate.dm(w.date), style: AppText.bodyBold.copyWith(fontSize: 13, height: 1.2)),
                Text(TDate.wd(w.date), style: AppText.caption.copyWith(fontSize: 10.5, fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(w.name, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                  Text('${w.minutes} min · ${w.exercises.length} exercises · ${w.setCount} sets',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption),
                ],
              ),
            ),
            if (w.hasPr) ...[const _PrTag('PR'), const SizedBox(width: 6)],
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _PastDetail extends StatelessWidget {
  const _PastDetail({required this.w, required this.onBack});
  final PastWorkout w;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final tiles = [('Time', '${w.minutes} min'), ('Exercises', '${w.exercises.length} of ${w.exercises.length}'), ('Effort', '${w.effort} / 10')];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            onTap: onBack,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.chevron_left_rounded, size: 18, color: AppColors.accent),
                Text('All past workouts', style: AppText.secondary.copyWith(color: AppColors.accent, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ),
        Row(
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(10)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(tiles[i].$1, style: AppText.caption.copyWith(fontSize: 11)),
                    Text(tiles[i].$2, style: AppText.bodyBold),
                  ]),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        if (w.note.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(10)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Your note', style: AppText.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.infoText)),
              Text(w.note, style: AppText.secondary.copyWith(fontSize: 12.5, color: AppColors.text2)),
            ]),
          ),
          const SizedBox(height: 10),
        ],
        Container(
          decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              for (var i = 0; i < w.exercises.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _PastExerciseRow(e: w.exercises[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PastExerciseRow extends StatelessWidget {
  const _PastExerciseRow({required this.e});
  final PastExercise e;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(e.name, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
            if (e.pr) ...[const SizedBox(width: 6), const _PrTag('New best')],
            const Spacer(),
            Text('${e.sets.length} ${e.sets.length == 1 ? 'set' : 'sets'}', style: AppText.caption),
          ]),
          const SizedBox(height: 6),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              for (var k = 0; k < e.sets.length; k++)
                Container(
                  padding: const EdgeInsets.fromLTRB(4, 3, 8, 3),
                  decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 16,
                      height: 16,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Text('${k + 1}', style: AppText.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 5),
                    Text(e.sets[k], style: AppText.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.text)),
                  ]),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
