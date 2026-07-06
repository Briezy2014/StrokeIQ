import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/utils/social_link_utils.dart';
import '../data/models/swimmer_profile.dart';

class PassportSocialLinks extends StatelessWidget {
  const PassportSocialLinks({
    super.key,
    required this.profile,
    this.iconColor,
    this.alignment = WrapAlignment.center,
  });

  final SwimmerProfile? profile;
  final Color? iconColor;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    if (profile == null) return const SizedBox.shrink();

    final chips = <Widget>[];

    void addLink({
      required IconData icon,
      required String label,
      required String? raw,
      required String? Function(String?) urlBuilder,
    }) {
      final url = urlBuilder(raw);
      if (url == null) return;
      chips.add(
        ActionChip(
          avatar: Icon(icon, size: 18, color: iconColor),
          label: Text(label),
          onPressed: () => launchUrl(
            Uri.parse(url),
            mode: LaunchMode.externalApplication,
          ),
        ),
      );
    }

    addLink(
      icon: Icons.language,
      label: _shortSiteLabel(profile!.personalWebsite),
      raw: profile!.personalWebsite,
      urlBuilder: SocialLinkUtils.websiteUrl,
    );
    addLink(
      icon: Icons.camera_alt_outlined,
      label: 'Instagram',
      raw: profile!.instagram,
      urlBuilder: SocialLinkUtils.instagramUrl,
    );
    addLink(
      icon: Icons.music_note_outlined,
      label: 'TikTok',
      raw: profile!.tiktok,
      urlBuilder: SocialLinkUtils.tiktokUrl,
    );
    addLink(
      icon: Icons.facebook_outlined,
      label: 'Facebook',
      raw: profile!.facebook,
      urlBuilder: SocialLinkUtils.facebookUrl,
    );

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        alignment: alignment,
        spacing: 8,
        runSpacing: 8,
        children: chips,
      ),
    );
  }

  static String _shortSiteLabel(String? website) {
    final text = website?.trim();
    if (text == null || text.isEmpty) return 'Website';
    return text
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceFirst(RegExp(r'^www\.'), '')
        .split('/')
        .first;
  }
}
