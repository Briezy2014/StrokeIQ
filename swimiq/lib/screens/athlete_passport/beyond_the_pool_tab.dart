import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/swimmer_profile_notes.dart';
import '../../data/models/swimmer_profile.dart';
import '../../providers/swimmer_data_provider.dart';
import '../../widgets/passport_social_links.dart';
import '../../widgets/swimiq_ui.dart';

/// Athlete life outside the lane — sports, academics, passions for peers & recruiters.
class BeyondThePoolTab extends ConsumerStatefulWidget {
  const BeyondThePoolTab({
    super.key,
    required this.swimmer,
    this.readOnly = false,
    this.profile,
  });

  final String swimmer;
  final bool readOnly;
  final SwimmerProfile? profile;

  @override
  ConsumerState<BeyondThePoolTab> createState() => _BeyondThePoolTabState();
}

class _BeyondThePoolTabState extends ConsumerState<BeyondThePoolTab> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _sportsController;
  late final TextEditingController _academicsController;
  late final TextEditingController _passionsController;
  late final TextEditingController _bioController;
  bool _isSaving = false;
  int? _syncedProfileId;

  @override
  void initState() {
    super.initState();
    _sportsController = TextEditingController();
    _academicsController = TextEditingController();
    _passionsController = TextEditingController();
    _bioController = TextEditingController();
  }

  @override
  void dispose() {
    _sportsController.dispose();
    _academicsController.dispose();
    _passionsController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _syncForm(SwimmerProfile? profile) {
    _syncedProfileId = profile?.id;
    _sportsController.text = profile?.interestSports.join(', ') ?? '';
    _academicsController.text = profile?.interestAcademics.join(', ') ?? '';
    _passionsController.text = profile?.interestPassions.join(', ') ?? '';
    _bioController.text = profile?.beyondBio ?? '';
  }

  List<String> _splitList(String raw) {
    return raw
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Future<void> _save(SwimmerProfile? existing) async {
    if (!_formKey.currentState!.validate()) return;
    if (existing == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Save your Passport profile first (name & team).'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final updated = existing.copyWith(
      athleteNotes: SwimmerProfileNotes.merge(
        existing: existing,
        interestSports: _splitList(_sportsController.text),
        interestAcademics: _splitList(_academicsController.text),
        interestPassions: _splitList(_passionsController.text),
        beyondBio: _bioController.text.trim(),
      ),
    );

    final error =
        await ref.read(swimmerDataProvider.notifier).saveProfile(updated);

    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null
              ? 'Beyond the Pool profile saved.'
              : 'Could not save: $error',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile ?? ref.watch(swimmerDataProvider).value?.profile;
    if (!widget.readOnly && profile?.id != _syncedProfileId) {
      _syncForm(profile);
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        const SwimIqScreenHeader(
          title: 'Beyond the Pool',
          subtitle:
              'Help teammates and college recruiters see the full you — '
              'other sports, academics, and passions outside swimming.',
        ),
        const SizedBox(height: 16),
        if (profile != null) ...[
          SwimIqSectionCard(
            title: 'Quick snapshot',
            lines: [
              if (profile.interestSports.isNotEmpty)
                'Other sports: ${profile.interestSports.join(', ')}',
              if (profile.interestAcademics.isNotEmpty)
                'Academics & clubs: ${profile.interestAcademics.join(', ')}',
              if (profile.interestPassions.isNotEmpty)
                'Passions: ${profile.interestPassions.join(', ')}',
              if (profile.beyondBio?.trim().isNotEmpty == true)
                profile.beyondBio!.trim(),
              if (profile.interestSports.isEmpty &&
                  profile.interestAcademics.isEmpty &&
                  profile.interestPassions.isEmpty &&
                  (profile.beyondBio == null || profile.beyondBio!.isEmpty))
                'Add interests below so peers can cheer you on in and out of the pool.',
            ],
          ),
          const SizedBox(height: 12),
          PassportSocialLinks(profile: profile),
        ],
        if (!widget.readOnly) ...[
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _sportsController,
                      decoration: const InputDecoration(
                        labelText: 'Other sports',
                        hintText: 'Volleyball, track, soccer',
                        helperText: 'Comma-separated',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _academicsController,
                      decoration: const InputDecoration(
                        labelText: 'Academics & school activities',
                        hintText: 'STEM club, NHS, student council',
                        helperText: 'Comma-separated',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passionsController,
                      decoration: const InputDecoration(
                        labelText: 'Passions & hobbies',
                        hintText: 'Photography, community service, art',
                        helperText: 'Comma-separated',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bioController,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'In your own words',
                        hintText:
                            'What should teammates and recruiters know about you '
                            'beyond the pool?',
                      ),
                    ),
                    const SizedBox(height: 20),
                    SwimIqSaveButton(
                      label: 'Save Beyond the Pool',
                      isSaving: _isSaving,
                      onPressed: () => _save(profile),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
