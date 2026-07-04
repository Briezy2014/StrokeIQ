import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/swimmer_profile.dart';
import '../providers/app_providers.dart';
import '../utils/personal_bests.dart';
import '../utils/swimiq_score.dart';
import '../widgets/metric_card.dart';
import '../widgets/section_header.dart';

class AthletePassportScreen extends ConsumerStatefulWidget {
  const AthletePassportScreen({super.key});

  @override
  ConsumerState<AthletePassportScreen> createState() =>
      _AthletePassportScreenState();
}

class _AthletePassportScreenState extends ConsumerState<AthletePassportScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _editing = false;
  bool _saving = false;
  bool _formInitialized = false;

  TextEditingController? _firstNameController;
  TextEditingController? _lastNameController;
  TextEditingController? _preferredNameController;
  TextEditingController? _teamController;
  TextEditingController? _coachController;
  TextEditingController? _favoriteEventController;
  TextEditingController? _usaIdController;
  TextEditingController? _schoolController;
  TextEditingController? _notesController;

  String _primaryStroke = 'Freestyle';
  String _secondaryStroke = 'Freestyle';
  int _graduationYear = 2032;
  DateTime _birthday = DateTime(2012, 1, 1);

  static const _strokes = [
    'Freestyle',
    'Backstroke',
    'Breaststroke',
    'Butterfly',
    'IM',
  ];

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    _firstNameController?.dispose();
    _lastNameController?.dispose();
    _preferredNameController?.dispose();
    _teamController?.dispose();
    _coachController?.dispose();
    _favoriteEventController?.dispose();
    _usaIdController?.dispose();
    _schoolController?.dispose();
    _notesController?.dispose();
    _firstNameController = null;
    _lastNameController = null;
    _preferredNameController = null;
    _teamController = null;
    _coachController = null;
    _favoriteEventController = null;
    _usaIdController = null;
    _schoolController = null;
    _notesController = null;
    _formInitialized = false;
  }

  void _initControllers(SwimmerProfile? profile, String swimmer) {
    _disposeControllers();
    _firstNameController = TextEditingController(text: profile?.firstName ?? '');
    _lastNameController = TextEditingController(text: profile?.lastName ?? '');
    _preferredNameController =
        TextEditingController(text: profile?.preferredName ?? swimmer);
    _teamController = TextEditingController(text: profile?.team ?? '');
    _coachController = TextEditingController(text: profile?.coachName ?? '');
    _favoriteEventController =
        TextEditingController(text: profile?.favoriteEvent ?? '');
    _usaIdController =
        TextEditingController(text: profile?.usaSwimmingId ?? '');
    _schoolController = TextEditingController(text: profile?.school ?? '');
    _notesController =
        TextEditingController(text: profile?.athleteNotes ?? '');

    _primaryStroke = profile?.primaryStroke ?? 'Butterfly';
    _secondaryStroke = profile?.secondaryStroke ?? 'Freestyle';
    _graduationYear = profile?.graduationYear ?? 2032;

    if (profile?.birthday != null) {
      _birthday = DateTime.tryParse(profile!.birthday!) ?? DateTime(2012, 1, 1);
    }
    _formInitialized = true;
  }

  String _displayValue(String? value, {String fallback = 'Not added yet'}) {
    if (value == null || value.trim().isEmpty) return fallback;
    return value.trim();
  }

  int _calculateAge(DateTime birthday) {
    final today = DateTime.now();
    var age = today.year - birthday.year;
    if (today.month < birthday.month ||
        (today.month == birthday.month && today.day < birthday.day)) {
      age--;
    }
    return age;
  }

  Future<void> _pickBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _birthday = picked);
  }

  Future<void> _save(SwimmerProfile? existing, String swimmer) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final profile = SwimmerProfile(
        id: existing?.id,
        swimmerName: swimmer,
        firstName: _firstNameController!.text.trim(),
        lastName: _lastNameController!.text.trim(),
        preferredName: _preferredNameController!.text.trim(),
        birthday: DateFormat('yyyy-MM-dd').format(_birthday),
        graduationYear: _graduationYear,
        team: _teamController!.text.trim(),
        coachName: _coachController!.text.trim(),
        primaryStroke: _primaryStroke,
        secondaryStroke: _secondaryStroke,
        favoriteEvent: _favoriteEventController!.text.trim(),
        usaSwimmingId: _usaIdController!.text.trim(),
        school: _schoolController!.text.trim(),
        athleteNotes: _notesController!.text.trim(),
      );

      await ref.read(supabaseServiceProvider).saveProfile(profile);
      refreshData(ref);

      if (!mounted) return;

      setState(() {
        _editing = false;
        _formInitialized = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Athlete Passport saved.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save Athlete Passport: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(swimmerDataProvider);
    final swimmer = ref.watch(activeSwimmerProvider) ?? '';

    return dataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Could not load passport: $error')),
      data: (data) {
        final profile = data.profile;
        final displayName = profile?.displayName ?? swimmer;
        final score = SwimIQScore.calculate(data.raceLogs, data.goals);
        final pbs = PersonalBests.fromRaceLogs(data.raceLogs);
        final currentFocus = _displayValue(
          profile?.favoriteEvent,
          fallback: _displayValue(profile?.primaryStroke, fallback: 'Add focus event'),
        );

        if (!_formInitialized && _editing) {
          _initControllers(profile, swimmer);
        }

        return RefreshIndicator(
          onRefresh: () async => refreshData(ref),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: SwimIQTheme.heroGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: SwimIQTheme.primaryBlue.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          profile?.initials ?? '🏊',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: SwimIQTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ATHLETE PASSPORT™',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      displayName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _displayValue(profile?.team),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Coach: ${_displayValue(profile?.coachName)} · '
                      '${_displayValue(profile?.primaryStroke)} Specialist · '
                      'Class of ${_displayValue(profile?.graduationYear?.toString())}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Athlete Status'),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.6,
                      children: [
                        MetricCard(
                          label: 'SwimIQ Score™',
                          value: '$score',
                          highlight: true,
                        ),
                        MetricCard(label: 'Current Focus', value: currentFocus),
                        const MetricCard(label: 'Highest Cut', value: 'Coming Soon'),
                        const MetricCard(label: 'Next Meet', value: 'Coming Soon'),
                        const MetricCard(label: 'IMX / IMR', value: 'Coming Soon'),
                        const MetricCard(label: 'Readiness', value: 'Coming Soon'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const SectionHeader(title: 'Athlete Details'),
                    _DetailCard(
                      title: 'Athlete Identity',
                      rows: [
                        ('Display Name', displayName),
                        ('Birthday', profile?.birthday != null
                            ? DateFormat('MM/dd/yyyy')
                                .format(DateTime.parse(profile!.birthday!))
                            : 'Not added yet'),
                        ('Age', profile?.birthday != null
                            ? '${_calculateAge(DateTime.parse(profile!.birthday!))} years old'
                            : 'Not added yet'),
                        ('Graduation Year',
                            _displayValue(profile?.graduationYear?.toString())),
                        ('School', _displayValue(profile?.school)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _DetailCard(
                      title: 'USA Swimming Profile',
                      rows: [
                        ('USA Swimming ID', _displayValue(profile?.usaSwimmingId)),
                        ('Club Team', _displayValue(profile?.team)),
                        ('Coach', _displayValue(profile?.coachName)),
                        ('Primary Stroke', _displayValue(profile?.primaryStroke)),
                        ('Secondary Stroke', _displayValue(profile?.secondaryStroke)),
                        ('Favorite Event', _displayValue(profile?.favoriteEvent)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _DetailCard(
                      title: 'SwimIQ Activity',
                      rows: [
                        ('Current Goals', '${data.goals.length}'),
                        ('Personal Bests', '${pbs.length}'),
                        ('Training Sessions', '${data.raceLogs.length}'),
                        ('Meet Results', '${data.meetResults.length}'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ATHLETE NOTES',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: SwimIQTheme.accentBlue,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _displayValue(
                                profile?.athleteNotes,
                                fallback: 'No athlete notes added yet.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: SwimIQTheme.softBlue,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: SwimIQTheme.borderBlue),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Coming Soon to Athlete Passport™',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: SwimIQTheme.accentBlue,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '🤖 AI Coach  ·  🧬 SwimDNA™  ·  🎓 Recruiting Center\n'
                            '🎥 Video Lab  ·  🏁 Race Intelligence™  ·  📊 USA Swimming Standards',
                            style: TextStyle(
                              color: SwimIQTheme.darkNavy,
                              fontWeight: FontWeight.w600,
                              height: 1.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SectionHeader(title: 'Edit Athlete Passport'),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              if (_editing) {
                                _editing = false;
                                _disposeControllers();
                              } else {
                                _initControllers(profile, swimmer);
                                _editing = true;
                              }
                            });
                          },
                          icon: Icon(_editing ? Icons.close : Icons.edit_rounded),
                          label: Text(_editing ? 'Cancel' : 'Edit'),
                        ),
                      ],
                    ),
                    if (_editing && _formInitialized)
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
                            InkWell(
                              onTap: _pickBirthday,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Birthday',
                                  suffixIcon: Icon(Icons.calendar_today_rounded),
                                ),
                                child: Text(DateFormat('MM/dd/yyyy').format(_birthday)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<int>(
                              initialValue: _graduationYear,
                              decoration:
                                  const InputDecoration(labelText: 'Graduation Year'),
                              items: List.generate(20, (i) {
                                final year = 2026 + i;
                                return DropdownMenuItem(
                                  value: year,
                                  child: Text('$year'),
                                );
                              }),
                              onChanged: (v) => setState(() => _graduationYear = v!),
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
                              initialValue: _primaryStroke,
                              decoration:
                                  const InputDecoration(labelText: 'Primary Stroke'),
                              items: _strokes
                                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                  .toList(),
                              onChanged: (v) => setState(() => _primaryStroke = v!),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _secondaryStroke,
                              decoration:
                                  const InputDecoration(labelText: 'Secondary Stroke'),
                              items: _strokes
                                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                  .toList(),
                              onChanged: (v) => setState(() => _secondaryStroke = v!),
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
                              decoration: const InputDecoration(labelText: 'Athlete Notes'),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _saving ? null : () => _save(profile, swimmer),
                                child: _saving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Save Athlete Passport'),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.title, required this.rows});

  final String title;
  final List<(String, String)> rows;

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
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: SwimIQTheme.accentBlue,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
            ),
            const SizedBox(height: 12),
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 130,
                      child: Text(
                        row.$1,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.$2,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
