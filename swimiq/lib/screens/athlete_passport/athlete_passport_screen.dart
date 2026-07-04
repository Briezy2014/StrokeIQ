import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/swim_analytics.dart';
import '../../data/models/swimmer_profile.dart';
import '../../providers/app_providers.dart';
import '../../providers/swimmer_data_provider.dart';
import '../../widgets/common_widgets.dart';

class AthletePassportScreen extends ConsumerStatefulWidget {
  const AthletePassportScreen({super.key, required this.data});

  final SwimmerData data;

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

  String _primaryStroke = AppConstants.strokes[3];
  String _secondaryStroke = AppConstants.strokes.first;
  DateTime _birthday = DateTime(2012, 1, 1);
  int _graduationYear = 2032;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initControllers(widget.data.profile);
  }

  @override
  void didUpdateWidget(covariant AthletePassportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.profile != widget.data.profile) {
      _updateControllers(widget.data.profile);
    }
  }

  void _initControllers(SwimmerProfile? profile) {
    final swimmer = ref.read(activeSwimmerProvider) ?? '';
    _firstNameController =
        TextEditingController(text: profile?.firstName ?? '');
    _lastNameController = TextEditingController(text: profile?.lastName ?? '');
    _preferredNameController = TextEditingController(
      text: profile?.preferredName ?? swimmer,
    );
    _teamController = TextEditingController(text: profile?.team ?? '');
    _coachController = TextEditingController(text: profile?.coachName ?? '');
    _favoriteEventController =
        TextEditingController(text: profile?.favoriteEvent ?? '');
    _usaIdController =
        TextEditingController(text: profile?.usaSwimmingId ?? '');
    _schoolController = TextEditingController(text: profile?.school ?? '');
    _notesController =
        TextEditingController(text: profile?.athleteNotes ?? '');
    _applyProfileFields(profile);
  }

  void _updateControllers(SwimmerProfile? profile) {
    final swimmer = ref.read(activeSwimmerProvider) ?? '';
    _firstNameController.text = profile?.firstName ?? '';
    _lastNameController.text = profile?.lastName ?? '';
    _preferredNameController.text = profile?.preferredName ?? swimmer;
    _teamController.text = profile?.team ?? '';
    _coachController.text = profile?.coachName ?? '';
    _favoriteEventController.text = profile?.favoriteEvent ?? '';
    _usaIdController.text = profile?.usaSwimmingId ?? '';
    _schoolController.text = profile?.school ?? '';
    _notesController.text = profile?.athleteNotes ?? '';
    _applyProfileFields(profile);
  }

  void _applyProfileFields(SwimmerProfile? profile) {
    _primaryStroke = profile?.primaryStroke ?? AppConstants.strokes[3];
    _secondaryStroke = profile?.secondaryStroke ?? AppConstants.strokes.first;
    _birthday = profile?.birthday ?? DateTime(2012, 1, 1);
    _graduationYear = profile?.graduationYear ?? 2032;
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

  String _displayOrDefault(String? value, [String fallback = 'Not added yet']) {
    if (value == null || value.trim().isEmpty) return fallback;
    return value.trim();
  }

  Future<void> _pickBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _birthday = picked);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final swimmer = ref.read(activeSwimmerProvider);
    if (swimmer == null) return;

    setState(() => _isSaving = true);

    final profile = SwimmerProfile(
      id: widget.data.profile?.id,
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
    final profile = widget.data.profile;
    final swimmer = ref.watch(activeSwimmerProvider) ?? '';
    final displayName = profile?.displayName ?? swimmer;
    final team = _displayOrDefault(profile?.team);
    final coach = _displayOrDefault(profile?.coachName);
    final primaryStroke = _displayOrDefault(profile?.primaryStroke);
    final secondaryStroke = _displayOrDefault(profile?.secondaryStroke);
    final favoriteEvent = _displayOrDefault(profile?.favoriteEvent);
    final graduationYear =
        profile?.graduationYear?.toString() ?? 'Not added yet';
    final usaId = _displayOrDefault(profile?.usaSwimmingId);
    final school = _displayOrDefault(profile?.school);
    final notes = profile?.athleteNotes?.trim();
    final birthdayLabel = profile?.birthday != null
        ? DateFormat('MM/dd/yyyy').format(profile!.birthday!)
        : 'Not added yet';
    final ageLabel = profile?.age?.toString() ?? 'Not added yet';

    final currentFocus = favoriteEvent != 'Not added yet'
        ? favoriteEvent
        : (primaryStroke != 'Not added yet' ? primaryStroke : '100 Fly');

    final totalPbs = SwimAnalytics.personalBests(widget.data.raceLogs).length;
    final dateFormat = DateFormat.yMMMd();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _PassportHero(
          displayName: displayName,
          team: team,
          coach: coach,
          primaryStroke: primaryStroke,
          graduationYear: graduationYear,
        ),
        const SizedBox(height: 24),
        Text(
          'Athlete Status',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.8,
          children: [
            const PassportStatusCard(
              title: 'SwimIQ Score™',
              value: 'Coming Soon',
            ),
            PassportStatusCard(title: 'Current Focus', value: currentFocus),
            const PassportStatusCard(title: 'Highest Cut', value: 'Coming Soon'),
            const PassportStatusCard(title: 'Next Meet', value: 'Coming Soon'),
            const PassportStatusCard(title: 'IMX / IMR', value: 'Coming Soon'),
            const PassportStatusCard(title: 'Readiness', value: 'Coming Soon'),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Athlete Details',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 12),
        _DetailCard(
          title: 'Athlete Identity',
          lines: [
            'Display Name: $displayName',
            'Birthday: $birthdayLabel',
            'Age: $ageLabel',
            'Graduation Year: $graduationYear',
            'School: $school',
          ],
        ),
        const SizedBox(height: 12),
        _DetailCard(
          title: 'USA Swimming Profile',
          lines: [
            'USA Swimming ID: $usaId',
            'Club Team: $team',
            'Coach: $coach',
            'Primary Stroke: $primaryStroke',
            'Secondary Stroke: $secondaryStroke',
            'Favorite Event: $favoriteEvent',
          ],
        ),
        const SizedBox(height: 12),
        _DetailCard(
          title: 'SwimIQ Activity',
          lines: [
            'Current Goals: ${widget.data.goals.length}',
            'Personal Bests: $totalPbs',
            'Training Sessions: ${widget.data.raceLogs.length}',
            'Meet Results: ${widget.data.meetResults.length}',
          ],
        ),
        const SizedBox(height: 12),
        _DetailCard(
          title: 'Athlete Notes',
          lines: [
            notes != null && notes.isNotEmpty
                ? notes
                : 'No athlete notes added yet.',
          ],
        ),
        const SizedBox(height: 20),
        const ComingSoonBox(),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'Edit Athlete Passport',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w900,
              ),
        ),
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
                decoration: const InputDecoration(labelText: 'Preferred Name'),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Birthday'),
                subtitle: Text(dateFormat.format(_birthday)),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _pickBirthday,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _graduationYear,
                decoration: const InputDecoration(labelText: 'Graduation Year'),
                items: List.generate(20, (index) {
                  final year = 2026 + index;
                  return DropdownMenuItem(value: year, child: Text('$year'));
                }),
                onChanged: (value) {
                  if (value != null) setState(() => _graduationYear = value);
                },
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
              DropdownButtonFormField<String>(
                value: _primaryStroke,
                decoration: const InputDecoration(labelText: 'Primary Stroke'),
                items: AppConstants.strokes
                    .map((stroke) =>
                        DropdownMenuItem(value: stroke, child: Text(stroke)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _primaryStroke = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _secondaryStroke,
                decoration:
                    const InputDecoration(labelText: 'Secondary Stroke'),
                items: AppConstants.strokes
                    .map((stroke) =>
                        DropdownMenuItem(value: stroke, child: Text(stroke)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _secondaryStroke = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _favoriteEventController,
                decoration: const InputDecoration(
                  labelText: 'Favorite Event',
                  hintText: 'Example: 100 Butterfly',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usaIdController,
                decoration: const InputDecoration(labelText: 'USA Swimming ID'),
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
                      'Example: Strong butterfly swimmer, working on back-half speed.',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Athlete Passport'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PassportHero extends StatelessWidget {
  const _PassportHero({
    required this.displayName,
    required this.team,
    required this.coach,
    required this.primaryStroke,
    required this.graduationYear,
  });

  final String displayName;
  final String team;
  final String coach;
  final String primaryStroke;
  final String graduationYear;

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 8),
          Text(
            team,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Coach: $coach · $primaryStroke Specialist · Class of $graduationYear',
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

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
            ),
            const SizedBox(height: 8),
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  line,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
