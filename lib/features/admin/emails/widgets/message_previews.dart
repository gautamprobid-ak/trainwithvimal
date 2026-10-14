import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';

/// Grey phone-like frame around a message preview (hb-phone).
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
      child: child,
    );
  }
}

class EmailPreview extends StatelessWidget {
  const EmailPreview({super.key, required this.subject, required this.body, this.line = 'to Sana · hello@trainwithvimal.com'});
  final String subject;
  final String body;
  final String line;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Avatar('TV', size: 28, color: AvatarColor.c1),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Train With Vimal', style: AppText.bodyBold.copyWith(fontSize: 12.5)),
                    Text(line, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(subject, style: AppText.bodyBold.copyWith(fontSize: 14)),
          const SizedBox(height: 6),
          Text(body, style: AppText.secondary.copyWith(color: AppColors.text2, height: 1.5)),
        ],
      ),
    );
  }
}

class PushPreview extends StatelessWidget {
  const PushPreview({super.key, required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .92), borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(8)),
            child: Text('TV', style: AppText.caption.copyWith(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 11)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(title, style: AppText.bodyBold.copyWith(fontSize: 13))),
                    Text('now', style: AppText.caption.copyWith(fontSize: 11)),
                  ],
                ),
                Text(body, style: AppText.secondary.copyWith(color: AppColors.text2, fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WhatsAppPreview extends StatelessWidget {
  const WhatsAppPreview({super.key, required this.body});
  final String body;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: const Color(0xFF075E54),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Text('Train With Vimal', style: AppText.bodyBold.copyWith(color: Colors.white, fontSize: 13)),
          ),
          Container(
            color: const Color(0xFFECE5DD),
            padding: const EdgeInsets.all(10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 260),
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(body, style: AppText.secondary.copyWith(color: AppColors.text, fontSize: 12.5, height: 1.45)),
                    Text('9:00 am', style: AppText.caption.copyWith(fontSize: 10, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InAppPreview extends StatelessWidget {
  const InAppPreview({super.key, required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TintIcon(Icons.notifications_rounded, tint: Tint.blue, size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.bodyBold.copyWith(fontSize: 13)),
                Text(body, style: AppText.secondary.copyWith(color: AppColors.text2, fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
