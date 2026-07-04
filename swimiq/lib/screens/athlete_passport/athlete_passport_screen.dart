import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/swimmer_profile.dart';
import '../../providers/app_providers.dart';
import '../../providers/swimmer_data_provider.dart';
import '../../widgets/swimmer_screen.dart';
import '../../widgets/swimiq_ui.dart';
import '../usa_standards/usa_standards_screen.dart';

class AthletePassportScreen extends ConsumerStatefulWidget {
  const AthletePassportScreen({super.key});

  @override
  ConsumerState<AthletePassportScreen> createState() =>
      _AthletePassportScreenState();
}

class _AthletePassportScreenState extends ConsumerState<AthletePassportScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _preferredNameController;
  late final TextEditingController _teamController;
  late final TextEditingController _coachController;
  late final TextEditingController _favoriteEventController;
  late final TextEditingController _usaIdController;
  late final TextEditingController _schoolController;
  late final TextEditingController _notesController;

  String? _primaryStroke;
  String? _secondaryStroke;
  DateTime? _birthday;
  int? _graduationYear;
  bool _isSaving = false;
  int? _syncedProfileId;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _preferredNameController = TextEditingController();
    _teamController = TextEditingController();
    _coachController = TextEditingController();
    _favoriteEventController = TextEditingController();
    _usaIdController = TextEditingController();
    _schoolController = TextEditingController();
    _notesController = TextEditingController();
  }

  void _syncProfileForm(SwimmerProfile? profile, String swimmer) {
    if (_syncedProfileId == profile?.id && profile?.id != null) return;
    _syncedProfileId = profile?.id;

    _firstNameController.text = profile?.firstName ?? '';
    _lastNameController.text = profile?.lastName ?? '';
    _preferredNameController.text = profile?.preferredName ?? swimmer;
    _teamController.text = profile?.team ?? '';
    _coachController.text = profile?.coachName ?? '';
    _favoriteEventController.text = profile?.favoriteEvent ?? '';
    _usaIdController.text = profile?.usaSwimmingId ?? '';
    _schoolController.text = profile?.school ?? '';
    _notesController.text = profile?.athleteNotes ?? '';
    _primaryStroke = profile?.primaryStroke;
    _secondaryStroke = profile?.secondaryStroke;
    _birthday = profile?.birthday;
    _graduationYear = profile?.graduationYear;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _preferredNameController.dispose();
    _teamController.dispose();
    _coachController.dispose();
    _favoriteEventController.dispose();
    _usaIdController.dispose();
    _schoolController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _optionalText(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }

  Future<void> _pickBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(2012, 1, 1),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _birthday = picked);
    }
  }

  Future<void> _saveProfile(SwimmerProfile? existingProfile) async {
    if (!_formKey.currentState!.validate()) return;

    final swimmer = ref.read(activeSwimmerProvider);
    if (swimmer == null) return;

    setState(() => _isSaving = true);

    final profile = SwimmerProfile(
      id: existingProfile?.id,
      swimmerName: swimmer,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      preferredName: _preferredNameController.text.trim(),
      birthday: _birthday,
      graduationYear: _graduationYear,
      team: _teamController.text.trim(),
      coachName: _coachController.text.trim(),
      primaryStroke: _primaryStroke,
      secondaryStroke: _secondaryStroke,
      favoriteEvent: _favoriteEventController.text.trim(),
      usaSwimmingId: _usaIdController.text.trim(),
      school: _schoolController.text.trim(),
      athleteNotes: _notesController.text.trim(),
    );

    final error =
        await ref.read(swimmerDataProvider.notifier).saveProfile(profile);

    if (!mounted) return;
    setState(() => _isSaving = false);

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
        _syncProfileForm(data.profile, swimmer);
        final profile = data.profile;
        final snapshot = data.passportSnapshot(swimmer);
        final dateFormat = DateFormat.yMMMd();
        final personalBestCount = data.personalBests.length;

        final team = _optionalText(profile?.team);
        final coach = _optionalText(profile?.coachName);
        final primaryStroke = _optionalText(profile?.primaryStroke);
        final secondaryStroke = _optionalText(profile?.secondaryStroke);
        final favoriteEvent = _optionalText(profile?.favoriteEvent);
        final graduationYear = profile?.graduationYear?.toString();
        final usaId = _optionalText(profile?.usaSwimmingId);
        final school = _optionalText(profile?.school);
        final notes = _optionalText(profile?.athleteNotes);
        final birthdayLabel = profile?.birthday != null
            ? DateFormat('MM/dd/yyyy').format(profile!.birthday!)
            : null;
        final ageLabel = profile?.age?.toString();

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _PassportHero(
              displayName: snapshot.displayName,
              swimmerName: swimmer,
              team: team,
              coach: coach,
              primaryStroke: primaryStroke,
              graduationYear: graduationYear,
            ),
            const SizedBox(height: 24),
            const SwimIqScreenHeader(title: 'Athlete Status'),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.45,
              children: [
                SwimIqMetricCard(
                  label: 'SwimIQ Score™',
                  value: snapshot.swimIqScore > 0
                      ? '${snapshot.swimIqScore}'
                      : '—',
                  subtitle: snapshot.swimIqExplanation,
                ),
                SwimIqMetricCard(
                  label: 'Current Focus',
                  value: snapshot.currentFocus,
                ),
                SwimIqMetricCard(
                  label: 'Highest Cut',
                  value: snapshot.highestCut,
                ),
                SwimIqMetricCard(
                  label: 'Latest Meet',
                  value: snapshot.nextMeet,
                ),
                SwimIqMetricCard(
                  label: 'IMX / IMR',
                  value: snapshot.imxScore,
                ),
                SwimIqMetricCard(
                  label: 'Readiness',
                  value: snapshot.readiness,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const UsaStandardsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.table_chart),
                    label: const Text('USA Standards'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SwimIqSectionCard(
              title: 'Best Events / Personal Bests',
              lines: snapshot.personalBests,
            ),
            const SizedBox(height: 12),
            SwimIqSectionCard(
              title: 'Goal Progress',
              lines: snapshot.goalLines,
            ),
            const SizedBox(height: 12),
            SwimIqSectionCard(
              title: 'USA Standards Comparison',
              lines: [snapshot.usaStandardsSummary],
            ),
            const SizedBox(height: 12),
            SwimIqSectionCard(
              title: 'Video Lab Summary',
              lines: [
                'Uploaded videos: ${snapshot.videoCount}',
                'AI analyses completed: ${snapshot.analysisCount}',
                snapshot.latestAnalysisSummary,
                if (snapshot.latestAnalysisEvent != null)
                  'Latest event analyzed: ${snapshot.latestAnalysisEvent}',
              ],
            ),
            const SizedBox(height: 12),
            SwimIqSectionCard(
              title: 'Next Focus',
              lines: [snapshot.nextFocus],
            ),
            const SizedBox(height: 24),
            const SwimIqScreenHeader(title: 'Athlete Details'),
            const SizedBox(height: 12),
            SwimIqSectionCard(
              title: 'Athlete Identity',
              lines: [
                'Current swimmer: $swimmer',
                if (birthdayLabel != null) 'Birthday: $birthdayLabel',
                if (ageLabel != null) 'Age: $ageLabel',
                if (graduationYear != null) 'Graduation Year: $graduationYear',
                if (school != null) 'School: $school',
                if (birthdayLabel == null &&
                    ageLabel == null &&
                    graduationYear == null &&
                    school == null)
                  'Add identity details below to complete your passport.',
              ],
            ),
            const SizedBox(height: 12),
            SwimIqSectionCard(
              title: 'USA Swimming Profile',
              lines: [
                if (usaId != null) 'USA Swimming ID: $usaId',
                if (team != null) 'Club Team: $team',
                if (coach != null) 'Coach: $coach',
                if (primaryStroke != null) 'Primary Stroke: $primaryStroke',
                if (secondaryStroke != null)
                  'Secondary Stroke: $secondaryStroke',
                if (favoriteEvent != null) 'Favorite Event: $favoriteEvent',
                if (usaId == null &&
                    team == null &&
                    coach == null &&
                    primaryStroke == null &&
                    secondaryStroke == null &&
                    favoriteEvent == null)
                  'No USA Swimming profile details saved yet.',
              ],
            ),
            const SizedBox(height: 12),
            SwimIqSectionCard(
              title: 'SwimIQ Activity',
              lines: [
                'Current goals: ${data.goals.length}',
                'Personal bests: $personalBestCount',
                'Training sessions: ${data.raceLogs.length}',
                'Meet results: ${data.meetResults.length}',
                'Uploaded videos: ${snapshot.videoCount}',
                'AI analyses: ${snapshot.analysisCount}',
              ],
            ),
            const SizedBox(height: 12),
            SwimIqSectionCard(
              title: 'Athlete Notes',
              lines: [notes ?? 'No athlete notes added yet.'],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const SwimIqScreenHeader(title: 'Edit Athlete Passport'),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(labelText: 'First Name'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _preferredNameController,
                    decoration:
                        const InputDecoration(labelText: 'Preferred Name'),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Birthday'),
                    subtitle: Text(
                      _birthday != null
                          ? dateFormat.format(_birthday!)
                          : 'Not set',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _pickBirthday,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    value: _graduationYear,
                    decoration:
                        const InputDecoration(labelText: 'Graduation Year'),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Not set'),
                      ),
                      ...List.generate(20, (index) {
                        final year = 2026 + index;
                        return DropdownMenuItem(
                            value: year, child: Text('$year'));
                      }),
                    ],
                    onChanged: (value) =>
                        setState(() => _graduationYear = value),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _teamController,
                    decoration: const InputDecoration(labelText: 'Club Team'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _coachController,
                    decoration: const InputDecoration(labelText: 'Coach'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    value: _primaryStroke,
                    decoration:
                        const InputDecoration(labelText: 'Primary Stroke'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Not set'),
                      ),
                      ...AppConstants.strokes.map(
                        (stroke) => DropdownMenuItem(
                            value: stroke, child: Text(stroke)),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _primaryStroke = value),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    value: _secondaryStroke,
                    decoration:
                        const InputDecoration(labelText: 'Secondary Stroke'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Not set'),
                      ),
                      ...AppConstants.strokes.map(
                        (stroke) => DropdownMenuItem(
                            value: stroke, child: Text(stroke)),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _secondaryStroke = value),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _favoriteEventController,
                    decoration: const InputDecoration(
                      labelText: 'Favorite Event',
                      hintText: 'Example: 50 Butterfly LCM',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _usaIdController,
                    decoration:
                        const InputDecoration(labelText: 'USA Swimming ID'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _schoolController,
                    decoration: const InputDecoration(labelText: 'School'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Athlete Notes',
                      hintText:
                          'Example: Working on 50 fly reaction time and breakout.',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  SwimIqSaveButton(
                    label: 'Save Athlete Passport',
                    isSaving: _isSaving,
                    onPressed: () => _saveProfile(profile),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PassportHero extends StatelessWidget {
  const _PassportHero({
    required this.displayName,
    required this.swimmerName,
    this.team,
    this.coach,
    this.primaryStroke,
    this.graduationYear,
  });

  final String displayName;
  final String swimmerName;
  final String? team;
  final String? coach;
  final String? primaryStroke;
  final String? graduationYear;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[];
    if (coach != null) subtitleParts.add('Coach: $coach');
    if (primaryStroke != null) subtitleParts.add('$primaryStroke specialist');
    if (graduationYear != null) subtitleParts.add('Class of $graduationYear');
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
            child: const Icon(Icons.pool, size: 46, color: AppColors.primary),
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
          if (team != null) ...[
            const SizedBox(height: 8),
            Text(
              team!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
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
