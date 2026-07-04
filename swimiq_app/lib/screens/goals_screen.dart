import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/goal.dart';
import '../providers/app_providers.dart';
import '../utils/swim_time.dart';
import '../widgets/empty_state.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _timeController = TextEditingController();

  static const _strokes = [
    'Freestyle',
    'Backstroke',
    'Breaststroke',
    'Butterfly',
    'IM',
  ];
  static const _courses = ['SCY', 'SCM', 'LCM'];

  String _stroke = _strokes.first;
  String _course = _courses.first;
  int _distance = 100;
  DateTime _targetDate = DateTime.now();
  bool _saving = false;
  bool _showForm = false;

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2040),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final swimmer = ref.read(activeSwimmerProvider);
    if (swimmer == null) return;

    setState(() => _saving = true);

    try {
      final goalTime = SwimTime.toSeconds(_timeController.text);
      final goal = Goal(
        swimmerName: swimmer,
        event: '$_distance $_stroke',
        goalTime: goalTime,
        course: _course,
        targetDate: DateFormat('yyyy-MM-dd').format(_targetDate),
      );

      await ref.read(supabaseServiceProvider).insertGoal(goal);
      refreshData(ref);

      if (!mounted) return;

      _timeController.clear();
      setState(() {
        _showForm = false;
        _distance = 100;
        _targetDate = DateTime.now();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goal saved.')),
      );
    } on FormatException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter target time like 35.43 or 1:24.32.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save goal: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(swimmerDataProvider);

    return dataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Could not load goals: $error')),
      data: (data) {
        return RefreshIndicator(
          onRefresh: () async => refreshData(ref),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_showForm) ...[
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _stroke,
                        decoration: const InputDecoration(labelText: 'Goal Stroke'),
                        items: _strokes
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) => setState(() => _stroke = v!),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: '$_distance',
                        decoration: const InputDecoration(labelText: 'Goal Distance'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          final parsed = int.tryParse(v);
                          if (parsed != null) _distance = parsed;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _course,
                        decoration: const InputDecoration(labelText: 'Goal Course'),
                        items: _courses
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) => setState(() => _course = v!),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _timeController,
                        decoration: const InputDecoration(
                          labelText: 'Target Time',
                          hintText: 'Example: 35.43 or 1:24.32',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          try {
                            SwimTime.toSeconds(v);
                            return null;
                          } catch (_) {
                            return 'Invalid time format';
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Target Date',
                            suffixIcon: Icon(Icons.calendar_today_rounded),
                          ),
                          child: Text(DateFormat('MMM d, yyyy').format(_targetDate)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => setState(() => _showForm = false),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: _saving ? null : _save,
                              child: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Save Goal'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => setState(() => _showForm = true),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Goal'),
                  ),
                ),
              const SizedBox(height: 16),
              if (data.goals.isEmpty)
                const EmptyState(
                  icon: Icons.flag_outlined,
                  title: 'No goals yet',
                  message: 'Set a goal to track your progress toward a target time.',
                )
              else
                ...data.goals.map(
                  (goal) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: SwimIQTheme.lightSky,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.flag_rounded,
                          color: SwimIQTheme.accentBlue,
                        ),
                      ),
                      title: Text(
                        goal.event,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '${goal.course} · Target: ${goal.targetDate}',
                      ),
                      trailing: Text(
                        SwimTime.fromSeconds(goal.goalTime),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: SwimIQTheme.darkNavy,
                            ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
