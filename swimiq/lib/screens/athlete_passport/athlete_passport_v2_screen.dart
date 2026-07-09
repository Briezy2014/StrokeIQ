import '../../core/utils/image_pick_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/swimiq_standards_profile.dart';
import '../../data/models/swimmer_profile.dart';
import '../../providers/swimmer_data_provider.dart';
import '../../widgets/passport_hub.dart';
import '../../widgets/swimmer_screen.dart';
import '../../widgets/swimiq_ui.dart';
import '../../widgets/swimiq_logo.dart';

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
  final _recruitingSnapshotKey = GlobalKey();

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
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _dominantHandController;

  DateTime? _birthday;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  int? _syncedProfileId;

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
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _dominantHandController = TextEditingController();
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
    _heightController.dispose();
    _weightController.dispose();
    _dominantHandController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToRecruitingSnapshot() {
    final target = _recruitingSnapshotKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      alignment: 0.08,
    );
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

  Future<void> _uploadProfilePhoto() async {
    final picked = await pickImageFromUserChoice(context);
    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);
    final error = await ref.read(swimmerDataProvider.notifier).uploadProfilePhoto(
          fileName: picked.name,
          bytes: picked.bytes,
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
    return SwimmerScreen(
      builder: (context, ref, data, swimmer) {
        final profile = data.profile;
        _syncForm(profile);
        final displayName = profile?.displayName ?? swimmer;
        final dateFormat = DateFormat('MM/dd/yyyy');

        final snapshot = data.passportSnapshot(swimmer);

        return ListView(
          controller: _scrollController,
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
              swimIqScore: snapshot.swimIqScore > 0
                  ? snapshot.swimIqScore.toString()
                  : null,
              highestCut: snapshot.highestCut,
              isUploadingPhoto: _isUploadingPhoto,
              onUploadPhoto: _uploadProfilePhoto,
            ),
            const SizedBox(height: 16),
            PassportHub(
              data: data,
              swimmer: swimmer,
              snapshot: snapshot,
              onOpenRecruitingCenter: _scrollToRecruitingSnapshot,
            ),
            const SizedBox(height: 16),
            _RecruitingSnapshotCard(
              key: _recruitingSnapshotKey,
              profile: profile,
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
                      : 'Log swims to score',
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
                  label: 'Next Meet',
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
            const SizedBox(height: 24),
            const SwimIqScreenHeader(title: 'Athlete Details'),
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
                'Birthday: ${_passportLabel(profile?.birthday != null ? dateFormat.format(profile!.birthday!) : null)}',
                'Age: ${_passportLabel(profile?.age?.toString())}',
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
                        controller: _gpaController,
                        label: 'Grade point average (GPA)',
                        hint: 'Example: 3.85',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
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

class _PassportHero extends StatelessWidget {
  const _PassportHero({
    required this.displayName,
    this.team,
    this.coach,
    this.primaryStroke,
    this.graduationYear,
    this.profilePhotoUrl,
    this.swimIqScore,
    this.highestCut,
    this.isUploadingPhoto = false,
    this.onUploadPhoto,
  });

  final String displayName;
  final String? team;
  final String? coach;
  final String? primaryStroke;
  final int? graduationYear;
  final String? profilePhotoUrl;
  final String? swimIqScore;
  final String? highestCut;
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
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 420;

            return Column(
              crossAxisAlignment:
                  wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              children: [
                _HeroAvatar(photoUrl: profilePhotoUrl),
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
                    label: Text(
                      isUploadingPhoto ? 'Uploading...' : 'Upload profile photo',
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'RECRUITING PASSPORT',
                  textAlign: wide ? TextAlign.start : TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  displayName,
                  textAlign: wide ? TextAlign.start : TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                if (team != null && team!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    team!.trim(),
                    textAlign: wide ? TextAlign.start : TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: wide ? TextAlign.start : TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  alignment: wide ? WrapAlignment.start : WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _HeroMetricChip(
                      label: 'SwimIQ Score',
                      value: swimIqScore ?? '—',
                    ),
                    _HeroMetricChip(
                      label: 'Highest Cut',
                      value: highestCut ?? '—',
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeroAvatar extends StatelessWidget {
  const _HeroAvatar({this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
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
      child: photoUrl != null && photoUrl!.isNotEmpty
          ? Image.network(
              photoUrl!,
              width: 88,
              height: 88,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Padding(
                  padding: EdgeInsets.all(8),
                  child: SwimIqLogo(size: 72, borderRadius: 36),
                );
              },
            )
          : const Padding(
              padding: EdgeInsets.all(8),
              child: SwimIqLogo(size: 72, borderRadius: 36),
            ),
    );
  }
}

class _HeroMetricChip extends StatelessWidget {
  const _HeroMetricChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _RecruitingSnapshotCard extends StatelessWidget {
  const _RecruitingSnapshotCard({super.key, required this.profile});

  final SwimmerProfile? profile;

  @override
  Widget build(BuildContext context) {
    final gpa = profile?.gpa;
    final website = profile?.athleteWebsite;
    final interests = profile?.otherInterests;
    final hasGpa = gpa != null && gpa.trim().isNotEmpty;
    final hasWebsite = website != null && website.trim().isNotEmpty;
    final hasInterests = interests != null && interests.trim().isNotEmpty;
    final hasAny = hasGpa || hasWebsite || hasInterests;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.badge_outlined, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Recruiting snapshot',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (hasAny)
            Column(
              children: [
                if (hasGpa)
                  _RecruitingRow(
                    icon: Icons.school_outlined,
                    label: 'GPA',
                    value: gpa.trim(),
                    highlight: true,
                  ),
                if (hasWebsite) ...[
                  if (hasGpa) const SizedBox(height: 10),
                  _RecruitingRow(
                    icon: Icons.language_outlined,
                    label: 'Athlete website',
                    value: website.trim(),
                    isLink: true,
                  ),
                ],
                if (hasInterests) ...[
                  if (hasGpa || hasWebsite) const SizedBox(height: 10),
                  _RecruitingRow(
                    icon: Icons.interests_outlined,
                    label: 'Other interests',
                    value: interests.trim(),
                  ),
                ],
              ],
            )
          else
            Text(
              'Add GPA, your recruiting website, and other interests in Edit Athlete Passport — coaches scan this first.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textDark.withValues(alpha: 0.65),
                    height: 1.45,
                  ),
            ),
        ],
      ),
    );
  }
}

class _RecruitingRow extends StatelessWidget {
  const _RecruitingRow({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
    this.isLink = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;
  final bool isLink;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.surfaceLight
            : AppColors.comingSoonBg.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight
              ? AppColors.primary.withValues(alpha: 0.35)
              : AppColors.comingSoonBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textDark.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: highlight ? FontWeight.w900 : FontWeight.w700,
                        color: isLink ? AppColors.primary : AppColors.textDark,
                        decoration: isLink ? TextDecoration.underline : null,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
