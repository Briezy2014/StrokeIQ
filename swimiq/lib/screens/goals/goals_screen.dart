import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/goal_progress_analytics.dart';
import '../../core/utils/swim_event_options.dart';
import '../../core/utils/swim_time.dart';
import '../../data/models/swim_goal.dart';
import '../../providers/swimmer_data_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/goal_progress_visuals.dart';
import '../../widgets/goals_progress_chart.dart';
import '../../widgets/swimiq_page_hero.dart';
import '../../widgets/swimiq_ui.dart';
import '../../widgets/swimmer_screen.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _timeController = TextEditingController();

  String _course = AppConstants.courses.first;
  SwimEventOption? _selectedEvent;
  DateTime _targetDate = DateTime.now();
  bool _isSaving = false;
  bool _showAddForm = false;

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  List<SwimEventOption> _eventOptions(SwimmerData data) {
    return SwimEventOptions.forProfile(
      catalog: data.motivationalStandards,
      profile: data.profile,
      course: _course,
    );
  }

  SwimEventOption? _matchingSelection(List<SwimEventOption> options) {
    if (options.isEmpty) return null;
    final selected = _selectedEvent;
    if (selected == null) return options.first;
    for (final option in options) {
      if (option.distance == selected.distance &&
          option.stroke == selected.stroke &&
          option.course == selected.course) {
        return option;
      }
    }
    return options.first;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2045),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Future<void> _saveGoal(SwimmerData data, String swimmer) async {
    if (!_formKey.currentState!.validate()) return;

    final event = _matchingSelection(_eventOptions(data));
    if (event == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pick a USA Swimming event from the list so cuts can track correctly.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final goalTime = SwimTime.toSeconds(_timeController.text);
      final goal = SwimGoal(
        swimmerName: swimmer,
        event: event.meetResultEvent,
        goalTime: goalTime,
        course: _course,
        targetDate: _targetDate,
      );

      final error = await ref.read(swimmerDataProvider.notifier).addGoal(goal);

      if (!mounted) return;

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save goal: $error')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal saved.')),
        );
        _timeController.clear();
        setState(() {
          _showAddForm = false;
          _selectedEvent = event;
        });
      }
    } on FormatException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please enter target time like 35.43, 1:24.32, or 5:31.43.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteGoal(SwimGoal goal) async {
    if (goal.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete goal?'),
        content: Text('Remove goal for ${goal.event}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final error =
        await ref.read(swimmerDataProvider.notifier).deleteGoal(goal.id!);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Goal deleted.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SwimmerScreen(
      builder: (context, ref, data, swimmer) {
        final dateFormat = DateFormat.yMMMd();
        final snapshots = buildGoalSnapshots(data);
        final achieved = snapshots
            .where((s) => s.status == GoalProgressStatus.achieved)
            .length;
        final showForm = _showAddForm || data.goals.isEmpty;
        final snapshot = data.passportSnapshot(swimmer);
        final eventOptions = _eventOptions(data);
        final currentSelection = _matchingSelection(eventOptions);

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            SwimIqPageHero(
              showMark: false,
              title: 'Goals',
              subtitle:
                  'Targets, progress & USA cuts for ${data.displayName(swimmer)}',
              stats: [
                SwimIqHeroStat('${data.goals.length} active goals'),
                if (achieved > 0) SwimIqHeroStat('$achieved achieved'),
                SwimIqHeroStat('Top cut: ${snapshot.highestCut}'),
              ],
            ),
            const SizedBox(height: 16),
            if (data.goals.isNotEmpty) ...[
              GoalsCutsBanner(snapshots: snapshots),
              const SizedBox(height: 16),
              GoalsProgressChart(snapshots: snapshots),
              const SizedBox(height: 16),
              Text(
                'Your goals',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Charts use training swims and official meet results from Log.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                    ),
              ),
              const SizedBox(height: 12),
              ...snapshots.map(
                (snapshot) => GoalProgressCard(
                  snapshot: snapshot,
                  onDelete: () => _deleteGoal(snapshot.goal),
                ),
              ),
              const SizedBox(height: 8),
            ] else
              const EmptyStateMessage(
                message:
                    'Set a goal below, then log swims on the Log tab. '
                    'Progress charts and USA cuts update automatically.',
              ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: const Text(
                      'Set a new goal',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: const Text(
                      'Pick a USA event + course so progress and cuts match Log & PBs.',
                    ),
                    trailing: Icon(
                      showForm ? Icons.expand_less : Icons.expand_more,
                    ),
                    onTap: () => setState(() => _showAddForm = !_showAddForm),
                  ),
                  if (showForm)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DropdownButtonFormField<String>(
                              key: ValueKey('goal-course-$_course'),
                              initialValue: _course,
                              decoration: const InputDecoration(
                                labelText: 'Course',
                              ),
                              items: AppConstants.courses
                                  .map(
                                    (course) => DropdownMenuItem(
                                      value: course,
                                      child: Text(course),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _isSaving
                                  ? null
                                  : (value) {
                                      if (value == null) return;
                                      setState(() {
                                        _course = value;
                                        _selectedEvent = null;
                                      });
                                    },
                            ),
                            const SizedBox(height: 12),
                            if (eventOptions.isEmpty)
                              Text(
                                'Official USA events could not load for this course. '
                                'Check birthday and gender in Athlete Passport, then try again.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.grey.shade700),
                              )
                            else
                              DropdownButtonFormField<SwimEventOption>(
                                key: ValueKey(
                                  'goal-event-$_course-${currentSelection?.label}',
                                ),
                                initialValue: currentSelection,
                                decoration: const InputDecoration(
                                  labelText: 'Event',
                                  helperText:
                                      'Same USA Swimming events used for cuts on PBs & Dashboard',
                                ),
                                isExpanded: true,
                                items: eventOptions
                                    .map(
                                      (option) => DropdownMenuItem(
                                        value: option,
                                        child: Text(option.label),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _isSaving
                                    ? null
                                    : (value) =>
                                        setState(() => _selectedEvent = value),
                                validator: (value) =>
                                    value == null ? 'Pick an event' : null,
                              ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _timeController,
                              decoration: const InputDecoration(
                                labelText: 'Target time',
                                hintText: 'Example: 35.43 or 1:24.32',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Target time is required';
                                }
                                try {
                                  SwimTime.toSeconds(value);
                                } on FormatException {
                                  return 'Use 35.43 or M:SS.hh format';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Target date'),
                              subtitle: Text(dateFormat.format(_targetDate)),
                              trailing: IconButton(
                                icon: const Icon(Icons.calendar_today),
                                onPressed: _pickDate,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SwimIqSaveButton(
                              label: 'Save goal',
                              isSaving: _isSaving,
                              onPressed: () => _saveGoal(data, swimmer),
                            ),
                          ],
                        ),
                      ),
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
