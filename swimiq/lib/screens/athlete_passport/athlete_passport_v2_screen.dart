import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/swimmer_profile.dart';
import '../../providers/swimmer_data_provider.dart';
import '../../widgets/swimmer_screen.dart';
import '../../widgets/swimiq_ui.dart';

/// Brand-new Athlete Passport — text fields and date picker only.
class AthletePassportV2Screen extends ConsumerStatefulWidget {
  const AthletePassportV2Screen({super.key});

  @override
  ConsumerState<AthletePassportV2Screen> createState() =>
      _AthletePassportV2ScreenState();
}

class _AthletePassportV2ScreenState extends ConsumerState<AthletePassportV2Screen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _preferredNameController;
  late final TextEditingController _usaIdController;
  late final TextEditingController _genderController;
  late final TextEditingController _clubController;
  late final TextEditingController _coachController;
  late final TextEditingController _schoolController;
  late final TextEditingController _graduationYearController;
  late final TextEditingController _primaryStrokeController;
  late final TextEditingController _secondaryStrokeController;
  late final TextEditingController _notesController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _dominantHandController;

  DateTime? _birthday;
  bool _isSaving = false;
  int? _syncedProfileId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _preferredNameController = TextEditingController();
    _usaIdController = TextEditingController();
    _genderController = TextEditingController();
    _clubController = TextEditingController();
    _coachController = TextEditingController();
    _schoolController = TextEditingController();
    _graduationYearController = TextEditingController();
    _primaryStrokeController = TextEditingController();
    _secondaryStrokeController = TextEditingController();
    _notesController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _dominantHandController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _preferredNameController.dispose();
    _usaIdController.dispose();
    _genderController.dispose();
    _clubController.dispose();
    _coachController.dispose();
    _schoolController.dispose();
    _graduationYearController.dispose();
    _primaryStrokeController.dispose();
    _secondaryStrokeController.dispose();
    _notesController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _dominantHandController.dispose();
    super.dispose();
  }

  String? _optionalText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  int? _graduationYearFromField() {
    final text = _graduationYearController.text.trim();
    if (text.isEmpty) return null;
    return int.tryParse(text);
  }

  void _syncForm(SwimmerProfile? profile) {
    if (_syncedProfileId == profile?.id && profile?.id != null) return;
    _syncedProfileId = profile?.id;

    _nameController.text = profile?.legalName ?? '';
    _preferredNameController.text = profile?.preferredName ?? '';
    _usaIdController.text = profile?.usaSwimmingId ?? '';
    _genderController.text = profile?.gender ?? '';
    _clubController.text = profile?.team ?? '';
    _coachController.text = profile?.coachName ?? '';
    _schoolController.text = profile?.school ?? '';
    _graduationYearController.text =
        profile?.graduationYear?.toString() ?? '';
    _primaryStrokeController.text = profile?.primaryStroke ?? '';
    _secondaryStrokeController.text = profile?.secondaryStroke ?? '';
    _notesController.text = profile?.notesBody ?? '';
    _heightController.text = profile?.height ?? '';
    _weightController.text = profile?.weight ?? '';
    _dominantHandController.text = profile?.dominantHand ?? '';
    _birthday = profile?.birthday;
  }

  Future<void> _pickBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(2012, 1, 1),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _birthday = picked);
    }
  }

  Future<void> _save(SwimmerProfile? existing, String swimmer) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final legalName = SwimmerProfile.splitLegalName(_nameController.text);
    final profile = SwimmerProfile(
      id: existing?.id,
      swimmerName: swimmer,
      firstName: legalName.firstName,
      lastName: legalName.lastName,
      preferredName: _optionalText(_preferredNameController.text),
      birthday: _birthday,
      graduationYear: _graduationYearFromField(),
      team: _optionalText(_clubController.text),
      coachName: _optionalText(_coachController.text),
      school: _optionalText(_schoolController.text),
      primaryStroke: _optionalText(_primaryStrokeController.text),
      secondaryStroke: _optionalText(_secondaryStrokeController.text),
      usaSwimmingId: _optionalText(_usaIdController.text),
      athleteNotes: SwimmerProfile.composeAthleteNotes(
        gender: _genderController.text,
        height: _heightController.text,
        weight: _weightController.text,
        dominantHand: _dominantHandController.text,
        notes: _notesController.text,
      ),
    );

    final error =
        await ref.read(swimmerDataProvider.notifier).saveProfile(profile);

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      if (error == null) {
        _syncedProfileId = null;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null
              ? 'Athlete Passport saved.'
              : 'Could not save Athlete Passport: $error',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SwimmerScreen(
      builder: (context, ref, data, swimmer) {
        final profile = data.profile;
        _syncForm(profile);
        final displayName = profile?.displayName ?? swimmer;
        final dateFormat = DateFormat('MM/dd/yyyy');

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _PassportHero(
              displayName: displayName,
              swimmerName: swimmer,
              club: profile?.team,
              coach: profile?.coachName,
            ),
            const SizedBox(height: 24),
            const SwimIqScreenHeader(
              title: 'Athlete Passport',
              subtitle:
                  'Every field loads from Supabase, edits here, and saves back.',
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _field(
                        controller: _nameController,
                        label: 'Name',
                        hint: 'Legal / full name',
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Name is required'
                                : null,
                      ),
                      _field(
                        controller: _preferredNameController,
                        label: 'Preferred Name',
                        hint: 'Name used on deck and in results',
                      ),
                      _field(
                        controller: _usaIdController,
                        label: 'USA Swimming ID',
                        hint: 'Example: 1234ABCD',
                      ),
                      _dateTile(dateFormat),
                      _field(
                        controller: _genderController,
                        label: 'Gender',
                        hint: 'Example: Female, Male, Non-binary',
                      ),
                      _field(
                        controller: _clubController,
                        label: 'Club',
                        hint: 'Example: COA',
                      ),
                      _field(
                        controller: _coachController,
                        label: 'Coach',
                        hint: 'Example: Gunner Lehr',
                      ),
                      _field(
                        controller: _schoolController,
                        label: 'School',
                      ),
                      _field(
                        controller: _graduationYearController,
                        label: 'Graduation Year',
                        hint: 'Example: 2032',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) return null;
                          if (int.tryParse(text) == null) {
                            return 'Enter a four-digit year';
                          }
                          return null;
                        },
                      ),
                      _field(
                        controller: _primaryStrokeController,
                        label: 'Primary Stroke',
                        hint: 'Freestyle, Backstroke, Breaststroke, Butterfly, IM',
                      ),
                      _field(
                        controller: _secondaryStrokeController,
                        label: 'Secondary Stroke',
                        hint: 'Freestyle, Backstroke, Breaststroke, Butterfly, IM',
                      ),
                      _field(
                        controller: _heightController,
                        label: 'Height',
                        hint: 'Example: 5\'4" or 163 cm',
                      ),
                      _field(
                        controller: _weightController,
                        label: 'Weight',
                        hint: 'Example: 120 lbs or 54 kg',
                      ),
                      _field(
                        controller: _dominantHandController,
                        label: 'Dominant Hand',
                        hint: 'Left or Right',
                      ),
                      _field(
                        controller: _notesController,
                        label: 'Notes',
                        hint: 'Training focus, meet prep, injury history, etc.',
                        maxLines: 4,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Swimmer key: $swimmer',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 20),
                      SwimIqSaveButton(
                        label: 'Save Athlete Passport',
                        isSaving: _isSaving,
                        onPressed: () => _save(profile, swimmer),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }

  Widget _dateTile(DateFormat dateFormat) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Date of Birth'),
        subtitle: Text(
          _birthday != null ? dateFormat.format(_birthday!) : 'Not set',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.calendar_today),
          tooltip: 'Pick date of birth',
          onPressed: _pickBirthday,
        ),
      ),
    );
  }
}

class _PassportHero extends StatelessWidget {
  const _PassportHero({
    required this.displayName,
    required this.swimmerName,
    this.club,
    this.coach,
  });

  final String displayName;
  final String swimmerName;
  final String? club;
  final String? coach;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[];
    if (coach != null && coach!.trim().isNotEmpty) {
      subtitleParts.add('Coach: ${coach!.trim()}');
    }
    if (club != null && club!.trim().isNotEmpty) {
      subtitleParts.add(club!.trim());
    }
    final subtitle = subtitleParts.isEmpty
        ? 'Swimmer: $swimmerName'
        : subtitleParts.join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.accent,
            AppColors.surfaceLight,
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.badge_outlined, size: 46, color: AppColors.primary),
          ),
          const SizedBox(height: 18),
          Text(
            'ATHLETE PASSPORT™',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
