import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/passport_metrics.dart';
import '../../core/utils/swim_stroke_utils.dart';
import '../../core/utils/swim_time.dart';
import '../../data/models/meet_result.dart';
import '../../data/models/swimmer_profile.dart';
import '../../data/models/video_models.dart';
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

  late final TextEditingController _nameController;
  late final TextEditingController _teamController;
  late final TextEditingController _trainingGroupController;
  late final TextEditingController _coachController;
  late final TextEditingController _primaryStrokeController;
  late final TextEditingController _secondaryStrokeController;
  late final TextEditingController _favoriteEventController;
  late final TextEditingController _usaIdController;
  late final TextEditingController _schoolController;
  late final TextEditingController _notesController;

  DateTime? _birthday;
  bool _isSaving = false;
  int? _syncedProfileId;

  static const _strokeFieldHint =
      'Freestyle, Backstroke, Breaststroke, Butterfly, or IM';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _teamController = TextEditingController();
    _trainingGroupController = TextEditingController();
    _coachController = TextEditingController();
    _primaryStrokeController = TextEditingController();
    _secondaryStrokeController = TextEditingController();
    _favoriteEventController = TextEditingController();
    _usaIdController = TextEditingController();
    _schoolController = TextEditingController();
    _notesController = TextEditingController();
  }

  String? _optionalSaveText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _strokeFromField(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    final normalized = SwimStrokeUtils.canonical(text);
    if (normalized.isEmpty) return null;
    return AppConstants.strokes.contains(normalized) ? normalized : text;
  }

  void _syncProfileForm(SwimmerProfile? profile, String swimmer) {
    if (_syncedProfileId == profile?.id && profile?.id != null) return;
    _syncedProfileId = profile?.id;

    _nameController.text = profile?.displayName ?? swimmer;
    _teamController.text = profile?.team ?? '';
    _trainingGroupController.text = profile?.trainingGroup ?? '';
    _coachController.text = profile?.coachName ?? '';
    _primaryStrokeController.text = profile?.primaryStroke ?? '';
    _secondaryStrokeController.text = profile?.secondaryStroke ?? '';
    _favoriteEventController.text = profile?.favoriteEvent ?? '';
    _usaIdController.text = profile?.usaSwimmingId ?? '';
    _schoolController.text = profile?.school ?? '';
    _notesController.text = profile?.notesBody ?? '';
    _birthday = profile?.birthday;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _teamController.dispose();
    _trainingGroupController.dispose();
    _coachController.dispose();
    _primaryStrokeController.dispose();
    _secondaryStrokeController.dispose();
    _favoriteEventController.dispose();
    _usaIdController.dispose();
    _schoolController.dispose();
    _notesController.dispose();
    super.dispose();
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
      preferredName: _optionalSaveText(_nameController.text),
      birthday: _birthday,
      team: _optionalSaveText(_teamController.text),
      coachName: _optionalSaveText(_coachController.text),
      primaryStroke: _strokeFromField(_primaryStrokeController.text),
      secondaryStroke: _strokeFromField(_secondaryStrokeController.text),
      favoriteEvent: _optionalSaveText(_favoriteEventController.text),
      usaSwimmingId: _optionalSaveText(_usaIdController.text),
      school: _optionalSaveText(_schoolController.text),
      athleteNotes: SwimmerProfile.composeAthleteNotes(
        trainingGroup: _trainingGroupController.text.trim(),
        notes: _notesController.text.trim(),
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

  List<String> _meetResultLines(List<MeetResult> results, DateFormat format) {
    if (results.isEmpty) return ['No meet results logged yet.'];
    final sorted = [...results]
      ..sort((a, b) => b.meetDate.compareTo(a.meetDate));
    return sorted.take(6).map((result) {
      final time = SwimTime.fromSeconds(result.swimTime);
      return '${format.format(result.meetDate)} · ${result.meetName} · '
          '${result.event} · $time ${result.course}';
    }).toList();
  }

  List<String> _videoLines(List<SwimVideo> videos) {
    if (videos.isEmpty) return ['No videos uploaded yet.'];
    return videos.take(6).map((video) => video.displayTitle).toList();
  }

  List<String> _latestAnalysisLines(SwimmerData data, PassportSnapshot snapshot) {
    final analyses = data.userFacingVideoAnalyses;
    if (analyses.isEmpty) {
      return [snapshot.latestAnalysisSummary];
    }

    final latest = [...analyses]
      ..sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

    final analysis = latest.first;
    final event = analysis.analysisJson?['event']?.toString();
    final quickSummary = analysis.coachingSections['Quick Summary'];

    return [
      if (event != null) 'Event: $event',
      snapshot.latestAnalysisSummary,
      if (quickSummary != null && quickSummary.isNotEmpty) quickSummary,
      if (analysis.topPriorities.isNotEmpty)
        'Top priority: ${analysis.topPriorities.first}',
    ];
  }

  @override
  Widget build(BuildContext context) {
    assert(() {
      debugPrint(
        '[AthletePassport] build: stroke inputs are TextFormField only '
        '(file=lib/screens/athlete_passport/athlete_passport_screen.dart)',
      );
      return true;
    }());

    return SwimmerScreen(
      builder: (context, ref, data, swimmer) {
        _syncProfileForm(data.profile, swimmer);
        final profile = data.profile;
        final snapshot = data.passportSnapshot(swimmer);
        final dateFormat = DateFormat.yMMMd();

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _PassportHero(
              displayName: snapshot.displayName,
              swimmerName: swimmer,
              team: profile?.team,
              coach: profile?.coachName,
              trainingGroup: profile?.trainingGroup,
              primaryStroke: profile?.primaryStroke,
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
            OutlinedButton.icon(
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
            const SizedBox(height: 24),
            const SwimIqScreenHeader(title: 'Performance Snapshot'),
            const SizedBox(height: 12),
            SwimIqSectionCard(
              title: 'Personal Bests',
              lines: snapshot.personalBests.isEmpty
                  ? ['No personal bests logged yet.']
                  : snapshot.personalBests,
            ),
            const SizedBox(height: 12),
            SwimIqSectionCard(
              title: 'Goals',
              lines: snapshot.goalLines.isEmpty
                  ? ['No active goals yet.']
                  : snapshot.goalLines,
            ),
            const SizedBox(height: 12),
            SwimIqSectionCard(
              title: 'Meet Results',
              lines: _meetResultLines(data.meetResults, dateFormat),
            ),
            const SizedBox(height: 12),
            SwimIqSectionCard(
              title: 'Uploaded Videos',
              lines: [
                '${data.userFacingVideos.length} video(s) in Video Lab',
                ..._videoLines(data.userFacingVideos),
              ],
            ),
            const SizedBox(height: 12),
            SwimIqSectionCard(
              title: 'Latest AI Analysis',
              lines: _latestAnalysisLines(data, snapshot),
            ),
            const SizedBox(height: 12),
            SwimIqSectionCard(
              title: 'USA Standards Comparison',
              lines: [snapshot.usaStandardsSummary],
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
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date of Birth'),
                    subtitle: Text(
                      _birthday != null
                          ? DateFormat('MM/dd/yyyy').format(_birthday!)
                          : 'Not set',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _pickBirthday,
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
                    controller: _teamController,
                    decoration: const InputDecoration(labelText: 'Club'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _trainingGroupController,
                    decoration: const InputDecoration(
                      labelText: 'Training Group',
                      hintText: 'Example: Senior, Age Group Blue',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _coachController,
                    decoration: const InputDecoration(labelText: 'Coach'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _primaryStrokeController,
                    decoration: const InputDecoration(
                      labelText: 'Primary Stroke',
                      hintText: _strokeFieldHint,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _secondaryStrokeController,
                    decoration: const InputDecoration(
                      labelText: 'Secondary Stroke',
                      hintText: _strokeFieldHint,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _favoriteEventController,
                    decoration: const InputDecoration(
                      labelText: 'Preferred Events',
                      hintText: 'Example: 50 Butterfly LCM, 100 Fly SCY',
                    ),
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
    this.trainingGroup,
    this.primaryStroke,
  });

  final String displayName;
  final String swimmerName;
  final String? team;
  final String? coach;
  final String? trainingGroup;
  final String? primaryStroke;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[];
    if (coach != null && coach!.isNotEmpty) {
      subtitleParts.add('Coach: $coach');
    }
    if (trainingGroup != null && trainingGroup!.isNotEmpty) {
      subtitleParts.add(trainingGroup!);
    }
    if (primaryStroke != null && primaryStroke!.isNotEmpty) {
      subtitleParts.add('$primaryStroke specialist');
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
          if (team != null && team!.isNotEmpty) ...[
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
