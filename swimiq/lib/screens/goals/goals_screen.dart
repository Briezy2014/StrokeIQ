import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/goal_progress_analytics.dart';
import '../../core/utils/swim_time.dart';
import '../../data/models/swim_goal.dart';
import '../../providers/app_providers.dart';
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
  final _strokeController =
      TextEditingController(text: AppConstants.strokes.first);
  final _courseController =
      TextEditingController(text: AppConstants.courses.first);

  int _distance = 100;
  DateTime _targetDate = DateTime.now();
  bool _isSaving = false;
  bool _showAddForm = false;

  @override
  void dispose() {
    _timeController.dispose();
    _strokeController.dispose();
    _courseController.dispose();
    super.dispose();
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

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    final swimmer = ref.read(activeSwimmerProvider);
    if (swimmer == null) return;

    setState(() => _isSaving = true);

    try {
      final stroke = _strokeController.text.trim().isEmpty
          ? AppConstants.strokes.first
          : _strokeController.text.trim();
      final course = _courseController.text.trim().isEmpty
          ? AppConstants.courses.first
          : _courseController.text.trim();

      final goalTime = SwimTime.toSeconds(_timeController.text);
      final goal = SwimGoal(
        swimmerName: swimmer,
        event: '$_distance $stroke',
        goalTime: goalTime,
        course: course,
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
        setState(() => _showAddForm = false);
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

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            SwimIqPageHero(
              title: 'Goals',
              subtitle: 'Targets, progress & USA cuts for ${data.displayName(swimmer)}',
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
                      'Add a target time — we track progress from your logs.',
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
                          children: [
                            TextFormField(
                              controller: _strokeController,
                              decoration: const InputDecoration(
                                labelText: 'Goal stroke',
                                hintText:
                                    'Freestyle, Backstroke, Breaststroke, Butterfly, or IM',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              initialValue: '$_distance',
                              decoration: const InputDecoration(
                                labelText: 'Goal distance',
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                final parsed = int.tryParse(value);
                                if (parsed != null && parsed >= 25) {
                                  setState(() => _distance = parsed);
                                }
                              },
                              validator: (value) {
                                final parsed = int.tryParse(value ?? '');
                                if (parsed == null || parsed < 25) {
                                  return 'Distance must be at least 25';
                                }
                                return null;
                              },
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
                            TextFormField(
                              controller: _courseController,
                              decoration: const InputDecoration(
                                labelText: 'Goal course',
                                hintText: 'SCY, SCM, or LCM',
                              ),
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
                              onPressed: _saveGoal,
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
