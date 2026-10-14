import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/trainer_mock.dart';
import 'package:train_with_vimal/data/models/trainer_app.dart';

import '../dashboard/trainer_widgets.dart';

/// "Edit my details" drawer.
Future<void> showEditMyDetails(BuildContext context) {
  return showAppSheet(
    context,
    title: 'Edit my details',
    subtitle: 'Personal and professional details',
    builder: (_) => const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetSection(title: 'Personal', children: [
          LabeledField(label: 'Full name *', initialValue: 'Aman Verma'),
          LabeledField(label: 'Mobile *', prefix: '+91', initialValue: '98201 55432', keyboardType: TextInputType.phone),
          LabeledField(label: 'Email *', initialValue: 'aman.verma@email.com', keyboardType: TextInputType.emailAddress),
          LabeledField(label: 'Gender', initialValue: 'Male'),
          LabeledField(label: 'Date of birth', initialValue: '14 / 02 / 1994'),
          LabeledField(label: 'City', initialValue: 'Mumbai'),
        ]),
        SheetSection(title: 'Professional', children: [
          LabeledField(label: 'Speciality', initialValue: 'Strength, Fat loss, Powerlifting', help: 'Separate with a comma'),
          LabeledField(label: 'Experience (years)', initialValue: '6', help: 'Since 2020', keyboardType: TextInputType.number),
          LabeledField(label: 'Trains', initialValue: 'Gym and online'),
          LabeledField(label: 'Languages', initialValue: 'Hindi, English'),
          LabeledField(label: 'Best with', initialValue: 'Beginners and busy office workers'),
          LabeledField(label: 'About you', initialValue: TrainerMock.shortBio, maxLines: 3),
        ]),
        SheetSection(
          title: 'Social media',
          help: 'Optional. Clients see these only if you switch on Social media in What clients see.',
          children: [
            LabeledField(label: 'Instagram', initialValue: '@aman.lifts'),
            LabeledField(label: 'YouTube', initialValue: 'youtube.com/@amanvermafit'),
            LabeledField(label: 'Facebook', hint: 'Page link'),
            LabeledField(label: 'Website', initialValue: 'amanlifts.in'),
          ],
        ),
        Text('Your access and client limit are set by the admin', style: TextStyle(fontSize: 12, color: AppColors.muted)),
      ],
    ),
    actions: (ctx) => [
      AppButton.outline('Cancel', onPressed: () => Navigator.of(ctx).pop()),
      AppButton('Save', icon: Icons.check_rounded, onPressed: () {
        Navigator.of(ctx).pop();
        showToast(context, 'Details saved', subtitle: 'Clients see the changes right away', kind: ToastKind.ok);
      }),
    ],
  );
}

/// "Upload a document" modal.
Future<void> showUploadDocument(BuildContext context) {
  var remind = true;
  return showAppSheet(
    context,
    title: 'Upload a document',
    subtitle: 'Certificates, ID proof or contract. PDF or photo, up to 10 MB.',
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => Spaced(children: [
        InkWell(
          onTap: () => showToast(context, 'Pick a file', subtitle: 'PDF, JPG or PNG'),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 22),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAF8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line2),
            ),
            child: Column(
              children: [
                const Icon(Icons.cloud_upload_outlined, color: AppColors.muted, size: 26),
                const SizedBox(height: 6),
                Text.rich(TextSpan(children: [
                  TextSpan(text: 'Drop a file here or ', style: AppText.bodyBold),
                  TextSpan(text: 'browse', style: AppText.bodyBold.copyWith(decoration: TextDecoration.underline, color: AppColors.accentText)),
                ])),
                Text('PDF, JPG or PNG', style: AppText.caption),
              ],
            ),
          ),
        ),
        const LabeledField(label: 'Type', initialValue: 'Certificate'),
        const LabeledField(label: 'Name', hint: 'Kettlebell Level 1'),
        const LabeledField(label: 'Issued by', hint: 'StrongFirst'),
        const LabeledField(label: 'Issued on', hint: 'MM / YYYY'),
        const LabeledField(label: 'Valid till', hint: 'MM / YYYY or no end'),
        const LabeledField(label: 'Who can see it', initialValue: 'Admins and clients', help: 'Clients see it after the admin verifies it'),
        ToggleRow(
          title: 'Remind me before it expires',
          subtitle: '30 days before, on the Dashboard',
          value: remind,
          onChanged: (v) => set(() => remind = v),
        ),
      ]),
    ),
    actions: (ctx) => [
      AppButton.outline('Cancel', onPressed: () => Navigator.of(ctx).pop()),
      AppButton('Upload', icon: Icons.upload_rounded, onPressed: () {
        Navigator.of(ctx).pop();
        showToast(context, 'Document uploaded', subtitle: 'Vimal checks it before clients see it', kind: ToastKind.ok);
      }),
    ],
  );
}

/// Document viewer (tp-viewer) with zoom and prev / next.
Future<void> showDocumentViewer(BuildContext context, int start) {
  return showDialog<void>(
    context: context,
    useRootNavigator: true,
    builder: (_) => Dialog.fullscreen(child: _DocViewer(start: start)),
  );
}

class _DocViewer extends StatefulWidget {
  const _DocViewer({required this.start});
  final int start;
  @override
  State<_DocViewer> createState() => _DocViewerState();
}

class _DocViewerState extends State<_DocViewer> {
  late int _i = widget.start;
  int _zoom = 100;

  static const _docs = TrainerMock.docs;

  @override
  Widget build(BuildContext context) {
    final d = _docs[_i];
    final (bg, fg) = d.colors;
    return SafeArea(
      child: Column(
        children: [
          Container(
            color: const Color(0xFF2A2C25),
            padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
            child: Row(
              children: [
                const Icon(Icons.description_outlined, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(d.file, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodyBold.copyWith(color: Colors.white))),
                Text('Page 1 of 1', style: AppText.caption.copyWith(color: Colors.white60)),
                IconButton(
                    tooltip: 'Zoom out',
                    onPressed: () => setState(() => _zoom = (_zoom - 25).clamp(50, 150)),
                    icon: const Icon(Icons.zoom_out_rounded, color: Colors.white)),
                Text('$_zoom%', style: AppText.caption.copyWith(color: Colors.white)),
                IconButton(
                    tooltip: 'Zoom in',
                    onPressed: () => setState(() => _zoom = (_zoom + 25).clamp(50, 150)),
                    icon: const Icon(Icons.zoom_in_rounded, color: Colors.white)),
                IconButton(
                    tooltip: 'Download',
                    onPressed: () => showToast(context, 'Downloading', subtitle: d.file),
                    icon: const Icon(Icons.download_rounded, color: Colors.white)),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFF3A3C35),
              alignment: Alignment.center,
              child: ClipRect(child: Transform.scale(scale: _zoom / 100, child: _Paper(doc: d))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                      child: Icon(d.icon, size: 16, color: fg),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.name, style: AppText.bodyBold),
                          Text('${_i + 1} of ${_docs.length} · ${d.kind}', style: AppText.caption),
                        ],
                      ),
                    ),
                    IconButton(tooltip: 'Previous', onPressed: () => _go(-1), icon: const Icon(Icons.chevron_left_rounded)),
                    IconButton(tooltip: 'Next', onPressed: () => _go(1), icon: const Icon(Icons.chevron_right_rounded)),
                    IconButton(tooltip: 'Close', onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded)),
                  ],
                ),
                const SizedBox(height: 6),
                Align(alignment: Alignment.centerLeft, child: AppBadge(d.status, tone: d.tone)),
                KvGrid.text([
                  ('Type', d.kind),
                  ('Issued by', d.by),
                  ('Issued on', d.issued),
                  ('Valid till', d.validTill),
                  ('Who can see it', d.clientsSee ? 'Clients see it' : 'Admins only'),
                  ('Uploaded', d.uploaded),
                  ('File', d.size),
                ], padding: EdgeInsets.zero),
                if (d.unchecked) ...[
                  const SizedBox(height: 8),
                  const InfoBanner(text: 'Waiting for Vimal to check it. Clients see it only after it is verified.'),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    AppButton.outline('Replace file', icon: Icons.upload_file_rounded, small: true, onPressed: () => showUploadDocument(context)),
                    const Spacer(),
                    LinkButton('Delete', icon: Icons.delete_outline_rounded, color: AppColors.bad, onTap: () async {
                      final ok = await showConfirmDialog(context,
                          title: 'Delete this document?', message: '${d.name} is removed for you and the admin.', confirmLabel: 'Delete', destructive: true);
                      if (ok && context.mounted) {
                        Navigator.of(context).pop();
                        showToast(context, 'Document deleted', subtitle: d.name, kind: ToastKind.del);
                      }
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _go(int k) => setState(() {
        _i = (_i + k + _docs.length) % _docs.length;
        _zoom = 100;
      });
}

/// The fake page in the viewer: certificate, ID card or contract.
class _Paper extends StatelessWidget {
  const _Paper({required this.doc});
  final TrainerDoc doc;

  @override
  Widget build(BuildContext context) {
    final children = switch (doc.type) {
      DocType.cert => [
          const Icon(Icons.workspace_premium_rounded, size: 40, color: Color(0xFFB45309)),
          const SizedBox(height: 8),
          Text('CERTIFICATE', style: AppText.overline.copyWith(letterSpacing: 2)),
          const SizedBox(height: 10),
          Text('This certifies that', style: AppText.caption),
          Text('Aman Verma', style: AppText.heroTitle),
          Text('has completed', style: AppText.caption),
          const SizedBox(height: 4),
          Text(doc.name, textAlign: TextAlign.center, style: AppText.cardTitle),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [_foot(doc.by, 'Issued by'), _foot(doc.issued, 'Date')],
          ),
        ],
      DocType.id => [
          Text('Government of India', style: AppText.bodyBold),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(width: 54, height: 64, color: AppColors.sub, child: const Icon(Icons.person_rounded, color: AppColors.muted)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Aman Verma', style: AppText.bodyBold),
                    Text('DOB 14/02/1994 · Male', style: AppText.caption),
                    Text('XXXX XXXX 4821', style: AppText.bodyBold.copyWith(fontFamily: 'monospace', letterSpacing: 1)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Numbers are hidden in the preview', style: AppText.caption),
        ],
      DocType.file => [
          Text('Trainer agreement', style: AppText.cardTitle),
          Text('Between Train With Vimal and Aman Verma', style: AppText.caption),
          const SizedBox(height: 12),
          for (final w in [1.0, .9, .6, 1.0, .8, .5, 1.0, .7])
            FractionallySizedBox(
              widthFactor: w,
              child: Container(height: 6, margin: const EdgeInsets.only(bottom: 7), color: AppColors.line),
            ),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_foot('Vimal', 'Signed'), _foot('Aman Verma', 'Signed')]),
        ],
    };
    return Container(
      width: 290,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  Widget _foot(String v, String k) => Column(children: [Text(v, style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.text)), Text(k, style: AppText.caption.copyWith(fontSize: 11))]);
}

/// "Ask for more access" modal. Returns the picked ask id.
Future<String?> showAskAccess(BuildContext context) {
  var pick = 'all';
  return showAppSheet<String>(
    context,
    title: 'Ask for more access',
    subtitle: 'Vimal gets your request and decides.',
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('What do you need?', style: AppText.secondary.copyWith(fontWeight: FontWeight.w700, color: AppColors.text2)),
          const SizedBox(height: 6),
          ListCard(children: [
            for (final a in TrainerMock.accessAsks)
              InkWell(
                onTap: () => set(() => pick = a.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Icon(pick == a.id ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                          size: 20, color: pick == a.id ? AppColors.accent : AppColors.line2),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.title, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                            if (a.sub.isNotEmpty) Text(a.sub, style: AppText.caption),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 12),
          const LabeledField(label: 'Why (optional)', hint: 'I cover Karan’s clients on Sundays'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: AppButton.outline('Cancel', onPressed: () => Navigator.of(ctx).pop())),
              const SizedBox(width: 10),
              Expanded(child: AppButton('Send request', onPressed: () => Navigator.of(ctx).pop(pick))),
            ],
          ),
        ],
      ),
    ),
  );
}

/// "Change password" modal. Returns true when changed.
Future<bool?> showChangePassword(BuildContext context) {
  return showAppSheet<bool>(
    context,
    title: 'Change password',
    subtitle: 'You stay logged in on this device.',
    builder: (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spaced(children: [
          LabeledField(label: 'Current password *', initialValue: '••••••••', obscure: true),
          LabeledField(label: 'New password *', hint: 'At least 8 letters and a number', obscure: true),
          LabeledField(label: 'Type it again *', obscure: true),
        ]),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: AppButton.outline('Cancel', onPressed: () => Navigator.of(ctx).pop())),
            const SizedBox(width: 10),
            Expanded(child: AppButton('Change password', onPressed: () => Navigator.of(ctx).pop(true))),
          ],
        ),
      ],
    ),
  );
}
