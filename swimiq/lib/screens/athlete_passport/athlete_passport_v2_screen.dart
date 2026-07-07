import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/swimiq_standards_profile.dart';
import '../../core/utils/passport_metrics.dart';
import '../../core/utils/swimmer_profile_notes.dart';
import '../../data/models/swimmer_profile.dart';
import '../../providers/swimmer_data_provider.dart';
import '../../providers/team_schedule_provider.dart';
import '../../widgets/passport_hub.dart';
import '../../widgets/passport_social_links.dart';
import '../../widgets/swimmer_screen.dart';
import '../../widgets/swimiq_ui.dart';
import '../../widgets/swimiq_logo.dart';
import 'beyond_the_pool_tab.dart';
import 'swimmer_directory_screen.dart';

/// Brand-new Athlete Passport — text fields and date picker only.
class AthletePassportV2Screen extends ConsumerStatefulWidget {
  const AthletePassportV2Screen({super.key});

  @override
  ConsumerState<AthletePassportV2Screen> createState() =>
      _AthletePassportV2ScreenState();
}

class _AthletePassportV2ScreenState extends ConsumerState<AthletePassportV2Screen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _preferredNameController;
  late final TextEditingController _usaIdController;
  late final TextEditingController _clubController;
  late final TextEditingController _coachController;
  late final TextEditingController _schoolController;
  late final TextEditingController _graduationYearController;
  late final TextEditingController _primaryStrokeController;
  late final TextEditingController _secondaryStrokeController;
  late final TextEditingController _favoriteEventController;
  late final TextEditingController _notesController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _dominantHandController;
  late final TextEditingController _sleepController;
  late final TextEditingController _illnessController;
  late final TextEditingController _websiteController;
  late final TextEditingController _instagramController;
  late final TextEditingController _tiktokController;
  late final TextEditingController _facebookController;

  DateTime? _birthday;
  String? _selectedGender;
  String? _selectedSoreness;
  bool _publicPassport = false;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  bool _formDirty = false;
  int? _syncedProfileId;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _preferredNameController = TextEditingController();
    _usaIdController = TextEditingController();
    _clubController = TextEditingController();
    _coachController = TextEditingController();
    _schoolController = TextEditingController();
    _graduationYearController = TextEditingController();
    _primaryStrokeController = TextEditingController();
    _secondaryStrokeController = TextEditingController();
    _favoriteEventController = TextEditingController();
    _notesController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _dominantHandController = TextEditingController();
    _sleepController = TextEditingController();
    _illnessController = TextEditingController();
    _websiteController = TextEditingController();
    _instagramController = TextEditingController();
    _tiktokController = TextEditingController();
    _facebookController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _preferredNameController.dispose();
    _usaIdController.dispose();
    _clubController.dispose();
    _coachController.dispose();
    _schoolController.dispose();
    _graduationYearController.dispose();
    _primaryStrokeController.dispose();
    _secondaryStrokeController.dispose();
    _favoriteEventController.dispose();
    _notesController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _dominantHandController.dispose();
    _sleepController.dispose();
    _illnessController.dispose();
    _websiteController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    _facebookController.dispose();
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
    _syncedProfileId = profile?.id;

    _firstNameController.text = profile?.firstName ?? '';
    _lastNameController.text = profile?.lastName ?? '';
    if (_firstNameController.text.isEmpty && _lastNameController.text.isEmpty) {
      final legal = profile?.legalName ?? '';
      final split = SwimmerProfile.splitLegalName(legal);
      _firstNameController.text = split.firstName ?? '';
      _lastNameController.text = split.lastName ?? '';
    }
    _preferredNameController.text = profile?.preferredName ?? '';
    _usaIdController.text = profile?.usaSwimmingId ?? '';
    _selectedGender = _normalizeGenderSelection(profile?.gender);
    _clubController.text = profile?.team ?? '';
    _coachController.text = profile?.coachName ?? '';
    _schoolController.text = profile?.school ?? '';
    _graduationYearController.text =
        profile?.graduationYear?.toString() ?? '';
    _primaryStrokeController.text = profile?.primaryStroke ?? '';
    _secondaryStrokeController.text = profile?.secondaryStroke ?? '';
    _favoriteEventController.text = profile?.favoriteEvent ?? '';
    _notesController.text = profile?.notesBody ?? '';
    _heightController.text = profile?.height ?? '';
    _weightController.text = profile?.weight ?? '';
    _dominantHandController.text = profile?.dominantHand ?? '';
    _sleepController.text = profile?.sleepHours ?? '';
    _selectedSoreness = profile?.sorenessLevel;
    _illnessController.text = profile?.illnessNotes ?? '';
    _websiteController.text = profile?.personalWebsite ?? '';
    _instagramController.text = profile?.instagram ?? '';
    _tiktokController.text = profile?.tiktok ?? '';
    _facebookController.text = profile?.facebook ?? '';
    _publicPassport = profile?.publicPassportEnabled ?? false;
    _birthday = profile?.birthday;
    _formDirty = false;
  }

  String? _normalizeGenderSelection(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final lower = raw.trim().toLowerCase();
    if (lower.startsWith('b') || lower.startsWith('m') || lower == 'boy') {
      return 'Boys';
    }
    if (lower.startsWith('g') || lower.startsWith('f') || lower == 'girl') {
      return 'Girls';
    }
    if (raw == 'Boys' || raw == 'Girls') return raw;
    return null;
  }

  Future<void> _pickBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(2012, 1, 1),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _formDirty = true;
        _birthday = picked;
      });
    }
  }

  Future<void> _save(SwimmerProfile? existing, String swimmer) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final firstName = _optionalText(_firstNameController.text);
    final lastName = _optionalText(_lastNameController.text);
    if (firstName == null && lastName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('First or last name is required.')),
      );
      setState(() => _isSaving = false);
      return;
    }

    final profile = SwimmerProfile(
      id: existing?.id,
      swimmerName: swimmer,
      firstName: firstName,
      lastName: lastName,
      preferredName: _optionalText(_preferredNameController.text),
      birthday: _birthday,
      graduationYear: _graduationYearFromField(),
      team: _optionalText(_clubController.text),
      coachName: _optionalText(_coachController.text),
      school: _optionalText(_schoolController.text),
      primaryStroke: _optionalText(_primaryStrokeController.text),
      secondaryStroke: _optionalText(_secondaryStrokeController.text),
      favoriteEvent: _optionalText(_favoriteEventController.text),
      usaSwimmingId: _optionalText(_usaIdController.text),
      athleteNotes: SwimmerProfileNotes.merge(
        existing: existing,
        gender: _selectedGender,
        height: _heightController.text,
        weight: _weightController.text,
        dominantHand: _dominantHandController.text,
        sleepHours: _sleepController.text,
        sorenessLevel: _selectedSoreness,
        illnessNotes: _illnessController.text,
        attendingMeetIds: existing?.attendingMeetIds,
        instagram: _instagramController.text,
        tiktok: _tiktokController.text,
        facebook: _facebookController.text,
        website: _websiteController.text,
        publicPassport: _publicPassport,
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
        _formDirty = false;
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

  Future<void> _uploadProfilePhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read the selected image.')),
      );
      return;
    }

    setState(() => _isUploadingPhoto = true);
    final error = await ref.read(swimmerDataProvider.notifier).uploadProfilePhoto(
          fileName: file.name,
          bytes: file.bytes!,
        );
    if (!mounted) return;
    setState(() {
      _isUploadingPhoto = false;
      if (error == null) _syncedProfileId = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null
              ? 'Profile photo updated.'
              : 'Could not upload profile photo: $error',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<SwimmerData?>>(swimmerDataProvider, (previous, next) {
      final profile = next.value?.profile;
      final profileId = profile?.id;
      if (!_formDirty && profileId != _syncedProfileId) {
        _syncForm(profile);
      }
    });

    return SwimmerScreen(
      builder: (context, ref, data, swimmer) {
        final profile = data.profile;
        final displayName = profile?.displayName ?? swimmer;
        final dateFormat = DateFormat('MM/dd/yyyy');
        final effectiveBirthday = _birthday ?? profile?.birthday;
        final effectiveGender = _selectedGender ?? profile?.gender;

        final attendingMeets = ref.watch(attendingMeetsProvider);
        final snapshot = data.passportSnapshot(
          swimmer,
          attendingMeets: attendingMeets,
        );

        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: TabBar(
                        tabs: [
                          Tab(text: 'Passport'),
                          Tab(text: 'Beyond the Pool'),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Find a swimmer',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SwimmerDirectoryScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_search_outlined),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildPassportTab(
                      context: context,
                      data: data,
                      swimmer: swimmer,
                      profile: profile,
                      displayName: displayName,
                      dateFormat: dateFormat,
                      effectiveBirthday: effectiveBirthday,
                      effectiveGender: effectiveGender,
                      snapshot: snapshot,
                    ),
                    BeyondThePoolTab(swimmer: swimmer, profile: profile),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPassportTab({
    required BuildContext context,
    required SwimmerData data,
    required String swimmer,
    required SwimmerProfile? profile,
    required String displayName,
    required DateFormat dateFormat,
    required DateTime? effectiveBirthday,
    required String? effectiveGender,
    required PassportSnapshot snapshot,
  }) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _PassportHero(
              displayName: displayName,
              team: profile?.team,
              coach: profile?.coachName,
              primaryStroke: profile?.primaryStroke,
              graduationYear: profile?.graduationYear,
              profilePhotoUrl: profile?.profilePhotoUrl,
              profile: profile,
              isUploadingPhoto: _isUploadingPhoto,
              onUploadPhoto: _uploadProfilePhoto,
            ),
            if (!SwimIqStandardsProfile.isReady(profile)) ...[
              const SizedBox(height: 16),
              const SwimIqStandardsSetupBanner(),
            ],
            const SizedBox(height: 24),
            const SwimIqScreenHeader(title: 'Athlete Status'),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                SwimIqMetricCard(
                  label: 'SwimIQ Score™',
                  value: snapshot.swimIqScore > 0
                      ? '${snapshot.swimIqScore}'
                      : 'Coming Soon',
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
                  label: 'Last Meet',
                  value: snapshot.lastMeetResult,
                  subtitle: 'From Meet Results tab',
                ),
                SwimIqMetricCard(
                  label: 'Upcoming Meet',
                  value: snapshot.upcomingMeet,
                  subtitle: 'From Goals target date',
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
            const SizedBox(height: 24),
            const SwimIqScreenHeader(title: 'Athlete Details'),
            const SizedBox(height: 12),
            SwimIqSectionCard(
              title: 'Meet schedule',
              lines: [
                'Last meet (results logged): ${snapshot.lastMeetResult}',
                'Upcoming meet (COA calendar or goal): ${snapshot.upcomingMeet}',
              ],
            ),
            const SizedBox(height: 12),
            SwimIqSectionCard(
              title: 'USA Motivational Standards',
              lines: snapshot.usaStandardsSummary.split('\n'),
            ),
            const SizedBox(height: 12),
            SwimIqSectionCard(
              title: 'Athlete Identity',
              lines: [
                'Display Name: $displayName',
                'Birthday: ${_passportLabel(effectiveBirthday != null ? dateFormat.format(effectiveBirthday) : null)}',
                'Gender: ${_passportLabel(effectiveGender)}',
                'Age: ${_passportLabel(_ageLabel(effectiveBirthday, profile?.age))}',
                'Graduation Year: ${_passportLabel(profile?.graduationYear?.toString())}',
                'School: ${_passportLabel(profile?.school)}',
              ],
            ),
            const SizedBox(height: 12),
            SwimIqSectionCard(
              title: 'USA Swimming Profile',
              lines: [
                'USA Swimming ID: ${_passportLabel(profile?.usaSwimmingId)}',
                'Club Team: ${_passportLabel(profile?.team)}',
                'Coach: ${_passportLabel(profile?.coachName)}',
                'Primary Stroke: ${_passportLabel(profile?.primaryStroke)}',
                'Secondary Stroke: ${_passportLabel(profile?.secondaryStroke)}',
                'Favorite Event: ${_passportLabel(profile?.favoriteEvent)}',
              ],
            ),
            const SizedBox(height: 12),
            SwimIqSectionCard(
              title: 'SwimIQ Activity',
              lines: [
                'Current Goals: ${data.goals.length}',
                'Personal Bests: ${data.personalBests.length}',
                'Training Sessions: ${data.raceLogs.length}',
                'Meet Results: ${data.meetResults.length}',
                'Video Analyses: ${data.userFacingVideoAnalyses.length}',
              ],
            ),
            const SizedBox(height: 12),
            SwimIqSectionCard(
              title: 'Athlete Notes',
              lines: [
                if (profile?.notesBody?.trim().isNotEmpty == true)
                  profile!.notesBody!.trim()
                else
                  'No athlete notes added yet.',
              ],
            ),
            const SizedBox(height: 24),
            PassportHub(
              data: data,
              swimmer: swimmer,
              snapshot: snapshot,
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const SwimIqScreenHeader(title: 'Edit Athlete Passport'),
            const SizedBox(height: 8),
            Text(
              'Profile saves to Supabase for $swimmer.',
              style: Theme.of(context).textTheme.bodySmall,
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
                        controller: _firstNameController,
                        label: 'First Name',
                      ),
                      _field(
                        controller: _lastNameController,
                        label: 'Last Name',
                      ),
                      _field(
                        controller: _preferredNameController,
                        label: 'Preferred Name',
                        hint: 'Name used on deck and in results',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Required for USA Swimming motivational cuts',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      _birthdayField(dateFormat),
                      _genderPicker(),
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
                        controller: _clubController,
                        label: 'Club Team',
                        hint: 'Example: COA',
                      ),
                      _field(
                        controller: _coachController,
                        label: 'Coach',
                        hint: 'Example: Gunner Lehr',
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
                        controller: _favoriteEventController,
                        label: 'Favorite Event',
                        hint: 'Example: 100 Fly SCY',
                      ),
                      _field(
                        controller: _usaIdController,
                        label: 'USA Swimming ID',
                        hint: 'Example: 1234ABCD',
                      ),
                      _field(
                        controller: _schoolController,
                        label: 'School',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Online & recruiting (shown on Passport)',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      _field(
                        controller: _websiteController,
                        label: 'Personal website',
                        hint: 'Example: aspenbreeze.com',
                      ),
                      _field(
                        controller: _instagramController,
                        label: 'Instagram',
                        hint: '@handle or full profile URL',
                      ),
                      _field(
                        controller: _tiktokController,
                        label: 'TikTok',
                        hint: '@handle or full profile URL',
                      ),
                      _field(
                        controller: _facebookController,
                        label: 'Facebook',
                        hint: 'Profile name or URL',
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Public passport'),
                        subtitle: const Text(
                          'Let teammates and recruiters find you by name. '
                          'Shows Passport + Beyond the Pool only.',
                        ),
                        value: _publicPassport,
                        onChanged: (value) {
                          setState(() {
                            _formDirty = true;
                            _publicPassport = value;
                          });
                        },
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
                      const SizedBox(height: 4),
                      Text(
                        'Wellness check-in (feeds readiness score)',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      _field(
                        controller: _sleepController,
                        label: 'Sleep (hours last night)',
                        hint: 'Example: 8.5',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      _sorenessPicker(),
                      _field(
                        controller: _illnessController,
                        label: 'Illness / injury note',
                        hint: 'Optional — sore shoulder, cold symptoms, etc.',
                        maxLines: 2,
                      ),
                      _field(
                        controller: _notesController,
                        label: 'Athlete Notes',
                        hint: 'Training focus, meet prep, injury history, etc.',
                        maxLines: 4,
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
        onChanged: (_) => _formDirty = true,
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

  Widget _birthdayField(DateFormat dateFormat) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _pickBirthday,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Date of Birth',
            hintText: 'Tap to pick birthday',
            suffixIcon: Icon(Icons.calendar_today),
            border: OutlineInputBorder(),
          ),
          child: Text(
            _birthday != null
                ? dateFormat.format(_birthday!)
                : 'Not set — tap to choose',
            style: TextStyle(
              color: _birthday != null
                  ? null
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _genderPicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gender (USA Swimming)',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: AppConstants.genders.map((gender) {
              return ChoiceChip(
                label: Text(gender),
                selected: _selectedGender == gender,
                onSelected: (selected) {
                  setState(() {
                    _formDirty = true;
                    _selectedGender = selected ? gender : null;
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _sorenessPicker() {
    const options = ['None / Fresh', 'Mild', 'Moderate', 'High'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Soreness level',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((level) {
              return ChoiceChip(
                label: Text(level),
                selected: _selectedSoreness == level,
                onSelected: (selected) {
                  setState(() {
                    _formDirty = true;
                    _selectedSoreness = selected ? level : null;
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

String? _ageLabel(DateTime? birthday, int? savedAge) {
  if (birthday == null) {
    return savedAge?.toString();
  }
  final today = DateTime.now();
  var years = today.year - birthday.year;
  if (today.month < birthday.month ||
      (today.month == birthday.month && today.day < birthday.day)) {
    years--;
  }
  return years.toString();
}

String _passportLabel(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return 'Not added yet';
  return trimmed;
}

class _PassportHero extends StatelessWidget {
  const _PassportHero({
    required this.displayName,
    this.team,
    this.coach,
    this.primaryStroke,
    this.graduationYear,
    this.profilePhotoUrl,
    this.profile,
    this.isUploadingPhoto = false,
    this.onUploadPhoto,
  });

  final String displayName;
  final String? team;
  final String? coach;
  final String? primaryStroke;
  final int? graduationYear;
  final String? profilePhotoUrl;
  final SwimmerProfile? profile;
  final bool isUploadingPhoto;
  final VoidCallback? onUploadPhoto;

  @override
  Widget build(BuildContext context) {
    final strokeLabel = _passportLabel(primaryStroke);
    final specialist = strokeLabel == 'Not added yet'
        ? 'Not added yet Specialist'
        : '$strokeLabel Specialist';
    final classOf = graduationYear?.toString() ?? 'Not added yet';
    final coachLabel = _passportLabel(coach);
    final subtitle = 'Coach: $coachLabel · $specialist · Class of $classOf';

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
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: profilePhotoUrl != null && profilePhotoUrl!.isNotEmpty
                ? Image.network(
                    profilePhotoUrl!,
                    width: 104,
                    height: 104,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Padding(
                        padding: EdgeInsets.all(10),
                        child: SwimIqLogo(size: 84, borderRadius: 42),
                      );
                    },
                  )
                : const Padding(
                    padding: EdgeInsets.all(10),
                    child: SwimIqLogo(size: 84, borderRadius: 42),
                  ),
          ),
          if (onUploadPhoto != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: isUploadingPhoto ? null : onUploadPhoto,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70),
              ),
              icon: isUploadingPhoto
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.photo_camera_outlined, size: 18),
              label: Text(isUploadingPhoto ? 'Uploading...' : 'Upload profile photo'),
            ),
          ],
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
          if (team != null && team!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              team!.trim(),
              textAlign: TextAlign.center,
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
          PassportSocialLinks(
            profile: profile,
            iconColor: Colors.white,
          ),
        ],
      ),
    );
  }
}
