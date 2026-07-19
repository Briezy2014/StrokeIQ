import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/swimiq_standards_profile.dart';
import '../../data/models/swimmer_profile.dart';
import '../../core/utils/passport_metrics.dart';
import '../../providers/swimmer_data_provider.dart';
import '../../screens/recruiting/college_recruiting_hub_screen.dart';
import '../../widgets/athlete_recruiting_business_card.dart';
import '../../widgets/recruiting_card_export_bar.dart';
import '../../widgets/passport_hub.dart';
import '../../widgets/swimiq_page_hero.dart';
import '../../widgets/swimmer_screen.dart';
import '../../widgets/swimiq_ui.dart';
import '../../widgets/swimiq_media_picker.dart';

/// Brand-new Athlete Passport — text fields and date picker only.
class AthletePassportV2Screen extends ConsumerStatefulWidget {
  const AthletePassportV2Screen({super.key});

  @override
  ConsumerState<AthletePassportV2Screen> createState() =>
      _AthletePassportV2ScreenState();
}

class _AthletePassportV2ScreenState extends ConsumerState<AthletePassportV2Screen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _preferredNameController;
  late final TextEditingController _usaIdController;
  late final TextEditingController _genderController;
  late final TextEditingController _clubController;
  late final TextEditingController _coachController;
  late final TextEditingController _schoolController;
  late final TextEditingController _graduationYearController;
  late final TextEditingController _primaryStrokeController;
  late final TextEditingController _secondaryStrokeController;
  late final TextEditingController _favoriteEventController;
  late final TextEditingController _notesController;
  late final TextEditingController _gpaController;
  late final TextEditingController _websiteController;
  late final TextEditingController _interestsController;
  late final TextEditingController _academicHonorsController;
  late final TextEditingController _athleticHonorsController;
  late final TextEditingController _collegeInterestsController;
  late final TextEditingController _leadershipController;
  late final TextEditingController _satController;
  late final TextEditingController _actController;
  late final TextEditingController _intendedMajorController;
  late final TextEditingController _recruitingStatusController;
  late final TextEditingController _coachEmailController;
  late final TextEditingController _coachPhoneController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _dominantHandController;

  DateTime? _birthday;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  Object? _syncedProfileKey;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _preferredNameController = TextEditingController();
    _usaIdController = TextEditingController();
    _genderController = TextEditingController();
    _clubController = TextEditingController();
    _coachController = TextEditingController();
    _schoolController = TextEditingController();
    _graduationYearController = TextEditingController();
    _primaryStrokeController = TextEditingController();
    _secondaryStrokeController = TextEditingController();
    _favoriteEventController = TextEditingController();
    _notesController = TextEditingController();
    _gpaController = TextEditingController();
    _websiteController = TextEditingController();
    _interestsController = TextEditingController();
    _academicHonorsController = TextEditingController();
    _athleticHonorsController = TextEditingController();
    _collegeInterestsController = TextEditingController();
    _leadershipController = TextEditingController();
    _satController = TextEditingController();
    _actController = TextEditingController();
    _intendedMajorController = TextEditingController();
    _recruitingStatusController = TextEditingController();
    _coachEmailController = TextEditingController();
    _coachPhoneController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _dominantHandController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeSyncForm(ref.read(swimmerDataProvider).value?.profile);
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _preferredNameController.dispose();
    _usaIdController.dispose();
    _genderController.dispose();
    _clubController.dispose();
    _coachController.dispose();
    _schoolController.dispose();
    _graduationYearController.dispose();
    _primaryStrokeController.dispose();
    _secondaryStrokeController.dispose();
    _favoriteEventController.dispose();
    _notesController.dispose();
    _gpaController.dispose();
    _websiteController.dispose();
    _interestsController.dispose();
    _academicHonorsController.dispose();
    _athleticHonorsController.dispose();
    _collegeInterestsController.dispose();
    _leadershipController.dispose();
    _satController.dispose();
    _actController.dispose();
    _intendedMajorController.dispose();
    _recruitingStatusController.dispose();
    _coachEmailController.dispose();
    _coachPhoneController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _dominantHandController.dispose();
    _scrollController.dispose();
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

  void _maybeSyncForm(SwimmerProfile? profile) {
    final key = Object.hash(
      profile?.id,
      profile?.swimmerName,
      profile?.athleteNotes,
      profile?.graduationYear,
      profile?.coachName,
    );
    if (_syncedProfileKey == key) return;
    _syncedProfileKey = key;
    _syncForm(profile);
  }

  void _syncForm(SwimmerProfile? profile) {
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
    _genderController.text = profile?.gender ?? '';
    _clubController.text = profile?.team ?? '';
    _coachController.text = profile?.coachName ?? '';
    _schoolController.text = profile?.school ?? '';
    _graduationYearController.text =
        profile?.graduationYear?.toString() ?? '';
    _primaryStrokeController.text = profile?.primaryStroke ?? '';
    _secondaryStrokeController.text = profile?.secondaryStroke ?? '';
    _favoriteEventController.text = profile?.favoriteEvent ?? '';
    _notesController.text = profile?.notesBody ?? '';
    _gpaController.text = profile?.gpa ?? '';
    _websiteController.text = profile?.athleteWebsite ?? '';
    _interestsController.text = profile?.otherInterests ?? '';
    _academicHonorsController.text = profile?.academicHonors ?? '';
    _athleticHonorsController.text = profile?.athleticHonors ?? '';
    _collegeInterestsController.text = profile?.collegeInterests ?? '';
    _leadershipController.text = profile?.leadershipService ?? '';
    _satController.text = profile?.satScore ?? '';
    _actController.text = profile?.actScore ?? '';
    _intendedMajorController.text = profile?.intendedMajor ?? '';
    _recruitingStatusController.text = profile?.recruitingStatus ?? '';
    _coachEmailController.text =
        profile?.coachEmail ?? profile?.recruitingEmail ?? '';
    _coachPhoneController.text = profile?.coachPhone ?? '';
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
      athleteNotes: SwimmerProfile.composeAthleteNotes(
        gender: _genderController.text,
        height: _heightController.text,
        weight: _weightController.text,
        dominantHand: _dominantHandController.text,
        profilePhotoUrl: existing?.profilePhotoUrl,
        gpa: _gpaController.text,
        athleteWebsite: _websiteController.text,
        otherInterests: _interestsController.text,
        academicHonors: _academicHonorsController.text,
        athleticHonors: _athleticHonorsController.text,
        collegeInterests: _collegeInterestsController.text,
        leadershipService: _leadershipController.text,
        satScore: _satController.text,
        actScore: _actController.text,
        intendedMajor: _intendedMajorController.text,
        recruitingStatus: _recruitingStatusController.text,
        coachEmail: _coachEmailController.text,
        coachPhone: _coachPhoneController.text,
        notes: _notesController.text,
      ),
    );

    final error =
        await ref.read(swimmerDataProvider.notifier).saveProfile(profile);

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      if (error == null) {
        _syncedProfileKey = null;
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
    final picked = await pickSwimIqMedia(
      context,
      kind: SwimIqMediaKind.image,
    );
    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);
    final error = await ref.read(swimmerDataProvider.notifier).uploadProfilePhoto(
          fileName: picked.fileName,
          bytes: picked.bytes,
        );
    if (!mounted) return;
    setState(() {
      _isUploadingPhoto = false;
      if (error == null) _syncedProfileKey = null;
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
    ref.listen(swimmerDataProvider, (previous, next) {
      _maybeSyncForm(next.value?.profile);
    });

    return SwimmerScreen(
      builder: (context, ref, data, swimmer) {
        final profile = data.profile;
        final displayName = profile?.displayName ?? swimmer;
        final dateFormat = DateFormat('MM/dd/yyyy');

        final snapshot = data.passportSnapshot(swimmer);

        return ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            const SwimIqPageHero(
              title: 'Athlete Passport',
              subtitle:
                  'Wallet recruiting card coaches remember — print, cut, hand off',
            ),
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final topEvents = AthleteRecruitingBusinessCard.topEventLines(
                  data.personalBests,
                ).isNotEmpty
                    ? AthleteRecruitingBusinessCard.topEventLines(
                        data.personalBests,
                      )
                    : snapshot.personalBests.take(2).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RecruitingCardExportBar(
                      snapshot: RecruitingCardSnapshot(
                        displayName: displayName,
                        swimIqScore: snapshot.swimIqScore,
                        highestCut: snapshot.highestCut,
                        team: profile?.team,
                        gpa: profile?.gpa,
                        website: profile?.athleteWebsite,
                        topEvents: topEvents,
                        graduationYear: profile?.graduationYear,
                        usaSwimmingId: profile?.usaSwimmingId,
                        profilePhotoUrl: profile?.profilePhotoUrl,
                        fileSafeName:
                            swimmer.replaceAll(RegExp(r'[^\w\-]'), '_'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    AthleteRecruitingBusinessCard(
                      displayName: displayName,
                      swimIqScore: snapshot.swimIqScore,
                      highestCut: snapshot.highestCut,
                      team: profile?.team,
                      gpa: profile?.gpa,
                      website: profile?.athleteWebsite,
                      graduationYear: profile?.graduationYear,
                      profilePhotoUrl: profile?.profilePhotoUrl,
                      usaSwimmingId: profile?.usaSwimmingId,
                      topEvents: topEvents,
                      isUploadingPhoto: _isUploadingPhoto,
                      onUploadPhoto: _uploadProfilePhoto,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            _CompactAthleteStatusStrip(snapshot: snapshot),
            const SizedBox(height: 16),
            PassportHub(
              data: data,
              swimmer: swimmer,
              snapshot: snapshot,
              onOpenRecruitingCenter: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CollegeRecruitingHubScreen(),
                  ),
                );
              },
            ),
            if (!SwimIqStandardsProfile.isReady(profile)) ...[
              const SizedBox(height: 16),
              const SwimIqStandardsSetupBanner(),
            ],
            const SizedBox(height: 16),
            const SwimIqScreenHeader(title: 'Athlete Details'),
            const SizedBox(height: 8),
            SwimIqSectionCard(
              title: 'USA Motivational Standards',
              lines: snapshot.usaStandardsSummary.split('\n'),
            ),
            const SizedBox(height: 8),
            SwimIqSectionCard(
              title: 'Athlete Identity',
              lines: [
                'Display Name: $displayName',
                'Birthday: ${_passportLabel(profile?.birthday != null ? dateFormat.format(profile!.birthday!) : null)}',
                'Age: ${_passportLabel(profile?.age?.toString())}',
                'Graduation Year: ${_passportLabel(profile?.graduationYear?.toString())}',
                'School: ${_passportLabel(profile?.school)}',
              ],
            ),
            const SizedBox(height: 8),
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
            const SizedBox(height: 8),
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
            const SizedBox(height: 8),
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
            const Divider(),
            const SizedBox(height: 16),
            const SwimIqScreenHeader(title: 'Edit Athlete Passport'),
            const SizedBox(height: 8),
            Text(
              'Your profile is saved and synced for $swimmer.',
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
                      _dateTile(dateFormat),
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
                      _field(
                        controller: _genderController,
                        label: 'Gender',
                        hint: 'Example: Female, Male, Non-binary',
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
                      const SizedBox(height: 8),
                      Text(
                        'Recruiting profile',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 12),
                      _field(
                        controller: _recruitingStatusController,
                        label: 'Recruiting status',
                        hint: 'Freshman, Sophomore, Junior, or Senior',
                      ),
                      _field(
                        controller: _coachEmailController,
                        label: 'Coach email',
                        hint: 'coach@clubteam.com',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      _field(
                        controller: _coachPhoneController,
                        label: 'Coach phone',
                        hint: 'Example: (555) 123-4567',
                        keyboardType: TextInputType.phone,
                      ),
                      _field(
                        controller: _gpaController,
                        label: 'Grade point average (GPA)',
                        hint: 'Example: 3.85',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      _field(
                        controller: _satController,
                        label: 'SAT score (optional)',
                        hint: 'Example: 1280',
                        keyboardType: TextInputType.number,
                      ),
                      _field(
                        controller: _actController,
                        label: 'ACT score (optional)',
                        hint: 'Example: 28',
                        keyboardType: TextInputType.number,
                      ),
                      _field(
                        controller: _intendedMajorController,
                        label: 'Intended major',
                        hint: 'Example: Biology, Engineering, Business…',
                      ),
                      _field(
                        controller: _academicHonorsController,
                        label: 'Academic honors',
                        hint: 'National Honor Society, AP Scholar, honor roll…',
                        maxLines: 2,
                      ),
                      _field(
                        controller: _athleticHonorsController,
                        label: 'Athletic honors',
                        hint: 'State finalist, team captain, conference champion…',
                        maxLines: 2,
                      ),
                      _field(
                        controller: _collegeInterestsController,
                        label: 'College interests',
                        hint: 'Division level, regions, academic majors…',
                        maxLines: 2,
                      ),
                      _field(
                        controller: _leadershipController,
                        label: 'Leadership & service',
                        hint: 'Community service, mentoring, club leadership…',
                        maxLines: 2,
                      ),
                      _field(
                        controller: _websiteController,
                        label: 'Athlete website',
                        hint: 'https://your-recruiting-site.com',
                        keyboardType: TextInputType.url,
                      ),
                      _field(
                        controller: _interestsController,
                        label: 'Other interests',
                        hint: 'Music, community service, other sports…',
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

String _passportLabel(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return 'Not added yet';
  return trimmed;
}

class _CompactAthleteStatusStrip extends StatelessWidget {
  const _CompactAthleteStatusStrip({required this.snapshot});

  final PassportSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final chips = [
      _StatusChip('Focus', snapshot.currentFocus),
      _StatusChip('Readiness', snapshot.readiness),
      _StatusChip('Latest meet', snapshot.nextMeet),
      _StatusChip('IMX / IMR', snapshot.imxScore),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textDark,
                height: 1.2,
              ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textDark.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
