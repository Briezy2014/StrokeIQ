import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/recruiting/living_passport_payload.dart';
import '../core/theme/app_theme.dart';
import '../providers/swimmer_data_provider.dart';

/// Living Passport QR — coaches scan for the public Living Passport snapshot.
class LivingPassportQrCard extends StatelessWidget {
  const LivingPassportQrCard({
    super.key,
    required this.data,
    required this.swimmer,
  });

  final SwimmerData data;
  final String swimmer;

  @override
  Widget build(BuildContext context) {
    final payload = LivingPassportPayload.fromData(data: data, swimmer: swimmer);
    final url = payload.shareUrl();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Living Passport QR',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDeep,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Scan opens the Living Passport coach snapshot (no login) — '
            'SwimIQ score, Power Index chart, top times, meet, and technique. '
            'It does not open the full private app. '
            'Tip: use http://swimiqapp.com if HTTPS shows Coming Soon.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: url,
                  size: 132,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payload.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Score ${payload.swimIqScore} · ${payload.highestCut}'),
                    Text('Power Index: ${payload.powerIndexLine}'),
                    Text('Meet: ${payload.nextMeet}'),
                    if (payload.latestTechniquePriorities.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Technique: ${payload.latestTechniquePriorities.first}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: url));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Living Passport link copied.')),
                  );
                },
                icon: const Icon(Icons.link, size: 18),
                label: const Text('Copy link'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  final uri = Uri.tryParse(url);
                  if (uri == null) return;
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Open Living Passport'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
