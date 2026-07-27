import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/services/parent_race_pulse_service.dart';
import '../core/theme/app_theme.dart';
import '../providers/swimmer_data_provider.dart';

/// Weekly plain-English Parent Race Pulse with email/share.
class ParentRacePulseCard extends StatelessWidget {
  const ParentRacePulseCard({
    super.key,
    required this.data,
    required this.swimmer,
  });

  final SwimmerData data;
  final String swimmer;

  @override
  Widget build(BuildContext context) {
    final pulse = ParentRacePulseService.build(data: data, swimmer: swimmer);
    final parentEmail = data.profile?.athleteEmail?.trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDeep.withValues(alpha: 0.08),
            AppColors.surfaceLight,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Parent Race Pulse',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDeep,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            'Week of ${pulse.weekLabel} · plain-English progress for parents',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                ),
          ),
          const SizedBox(height: 10),
          ...pulse.paragraphs.skip(1).map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(p, style: const TextStyle(height: 1.35)),
                ),
              ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: pulse.shareBody));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Race Pulse copied.')),
                  );
                },
                icon: const Icon(Icons.copy_outlined, size: 18),
                label: const Text('Copy'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  final email = parentEmail;
                  final uri = Uri(
                    scheme: 'mailto',
                    path: email ?? '',
                    queryParameters: {
                      'subject': pulse.headline,
                      'body': pulse.shareBody,
                    },
                  );
                  final ok = await launchUrl(uri);
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Could not open email. Copy the pulse instead.',
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.email_outlined, size: 18),
                label: Text(
                  parentEmail == null || parentEmail.isEmpty
                      ? 'Email pulse'
                      : 'Email parent',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
