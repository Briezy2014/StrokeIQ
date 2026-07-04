import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/meet_result.dart';
import '../providers/app_providers.dart';
import '../utils/swim_time.dart';
import '../widgets/empty_state.dart';

class MeetResultsScreen extends ConsumerStatefulWidget {
  const MeetResultsScreen({super.key});

  @override
  ConsumerState<MeetResultsScreen> createState() => _MeetResultsScreenState();
}

class _MeetResultsScreenState extends ConsumerState<MeetResultsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _meetNameController = TextEditingController();
  final _eventController = TextEditingController();
  final _timeController = TextEditingController();

  static const _courses = ['SCY', 'SCM', 'LCM'];

  String _course = _courses.first;
  DateTime _meetDate = DateTime.now();
  bool _saving = false;
  bool _showForm = false;

  @override
  void dispose() {
    _meetNameController.dispose();
    _eventController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _meetDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _meetDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final swimmer = ref.read(activeSwimmerProvider);
    if (swimmer == null) return;

    setState(() => _saving = true);

    try {
      final swimTime = SwimTime.toSeconds(_timeController.text);
      final result = MeetResult(
        swimmerName: swimmer,
        meetName: _meetNameController.text.trim(),
        meetDate: DateFormat('yyyy-MM-dd').format(_meetDate),
        event: _eventController.text.trim(),
        swimTime: swimTime,
        course: _course,
      );

      await ref.read(supabaseServiceProvider).insertMeetResult(result);
      refreshData(ref);

      if (!mounted) return;

      _meetNameController.clear();
      _eventController.clear();
      _timeController.clear();
      setState(() {
        _showForm = false;
        _meetDate = DateTime.now();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meet result saved.')),
      );
    } on FormatException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter result time like 35.43 or 1:24.32.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save meet result: $e')),
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
      error: (error, _) => Center(child: Text('Could not load meet results: $error')),
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
                      TextFormField(
                        controller: _meetNameController,
                        decoration: const InputDecoration(labelText: 'Meet Name'),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Meet Date',
                            suffixIcon: Icon(Icons.calendar_today_rounded),
                          ),
                          child: Text(DateFormat('MMM d, yyyy').format(_meetDate)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _eventController,
                        decoration: const InputDecoration(
                          labelText: 'Event',
                          hintText: 'Example: 100 Butterfly',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _timeController,
                        decoration: const InputDecoration(
                          labelText: 'Result Time',
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
                      DropdownButtonFormField<String>(
                        initialValue: _course,
                        decoration: const InputDecoration(labelText: 'Result Course'),
                        items: _courses
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) => setState(() => _course = v!),
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
                                  : const Text('Save Result'),
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
                    label: const Text('Add Meet Result'),
                  ),
                ),
              const SizedBox(height: 16),
              if (data.meetResults.isEmpty)
                const EmptyState(
                  icon: Icons.sports_score_outlined,
                  title: 'No meet results yet',
                  message: 'Record your meet performances to track competition history.',
                )
              else
                ...data.meetResults.map(
                  (result) => Card(
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
                          Icons.sports_score_rounded,
                          color: SwimIQTheme.accentBlue,
                        ),
                      ),
                      title: Text(
                        result.event,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '${result.meetName}\n${result.course} · ${result.meetDate}',
                      ),
                      isThreeLine: true,
                      trailing: Text(
                        SwimTime.fromSeconds(result.swimTime),
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
