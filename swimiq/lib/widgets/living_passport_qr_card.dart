import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/recruiting/living_passport_payload.dart';
import '../core/theme/app_theme.dart';
import '../providers/swimmer_data_provider.dart';

/// Living Passport QR — coaches scan for live times, Power Index, technique cues.
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
            'Coaches scan this code to open a live snapshot: SwimIQ score, '
            'Power Index, top times, upcoming meet, and latest technique priorities. '
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
                label: const Text('Open coach view'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Public coach-facing Living Passport (opened via `?lp=`).
class LivingPassportPublicScreen extends StatelessWidget {
  const LivingPassportPublicScreen({super.key, required this.payload});

  final LivingPassportPayload payload;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SwimIQ Living Passport')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            payload.displayName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDeep,
                ),
          ),
          const SizedBox(height: 6),
          Text('Coach snapshot · generated ${payload.generatedAtIso}'),
          const SizedBox(height: 16),
          _tile('SwimIQ Score', '${payload.swimIqScore}'),
          _tile('Highest cut', payload.highestCut),
          _tile('Readiness', payload.readiness),
          _tile('Power Index', payload.powerIndexLine),
          _tile('Upcoming meet', payload.nextMeet),
          if (payload.latestClipLabel != null &&
              payload.latestClipLabel!.trim().isNotEmpty)
            _tile('Latest AI clip', payload.latestClipLabel!),
          const SizedBox(height: 12),
          Text(
            'Top times',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          if (payload.topTimes.isEmpty)
            const Text('No times shared yet.')
          else
            ...payload.topTimes.map((t) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.timer_outlined),
                  title: Text(t),
                )),
          const SizedBox(height: 8),
          Text(
            'Latest technique priorities',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          if (payload.latestTechniquePriorities.isEmpty)
            const Text('No video analysis priorities yet.')
          else
            ...payload.latestTechniquePriorities.map((p) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.videocam_outlined),
                  title: Text(p),
                )),
          const SizedBox(height: 20),
          Text(
            'This Living Passport refreshes when the athlete regenerates the QR in SwimIQ.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _tile(String label, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(value),
    );
  }
}
