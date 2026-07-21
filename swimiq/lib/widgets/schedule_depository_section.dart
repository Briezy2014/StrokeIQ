import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../data/models/swim_schedule_entry.dart';
import '../providers/app_providers.dart';
import '../providers/swimmer_data_provider.dart';
import '../widgets/swimiq_ui.dart';

/// Upcoming meets & practices (schedule). Official race times go on the Meets tab.
class ScheduleDepositorySection extends ConsumerStatefulWidget {
  const ScheduleDepositorySection({
    super.key,
    this.compact = false,
    this.onOpenRaceIntelligence,
  });

  final bool compact;
  final VoidCallback? onOpenRaceIntelligence;

  @override
  ConsumerState<ScheduleDepositorySection> createState() =>
      _ScheduleDepositorySectionState();
}

class _ScheduleDepositorySectionState
    extends ConsumerState<ScheduleDepositorySection> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _locationController = TextEditingController();
  final _eventsController = TextEditingController();
  final _notesController = TextEditingController();

  String _scheduleType = SwimScheduleEntry.typeMeet;
  DateTime _scheduleDate = DateTime.now().add(const Duration(days: 7));
  bool _isSaving = false;
  bool _showForm = false;
  final _saveSectionKey = GlobalKey();

  @override
  void dispose() {
    _titleController.dispose();
    _startTimeController.dispose();
    _locationController.dispose();
    _eventsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduleDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Upcoming meet or practice date',
    );
    if (picked != null) setState(() => _scheduleDate = picked);
  }

  void _openForm(String type) {
    setState(() {
      _scheduleType = type;
      _showForm = true;
      if (_scheduleDate.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
        _scheduleDate = DateTime.now().add(const Duration(days: 7));
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _saveSectionKey.currentContext;
      if (target != null) {
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          alignment: 0.85,
        );
      }
    });
  }

  void _openMeetResultsTab() {
    ref.read(homeTabIndexProvider.notifier).state = HomeTab.meetResults;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final swimmer = ref.read(activeSwimmerProvider);
    if (swimmer == null) return;

    setState(() => _isSaving = true);
    final entry = SwimScheduleEntry(
      swimmerName: swimmer,
      scheduleType: _scheduleType,
      title: _titleController.text.trim(),
      scheduleDate: _scheduleDate,
      startTime: _optional(_startTimeController.text),
      location: _optional(_locationController.text),
      eventsLine: _optional(_eventsController.text),
      notes: _optional(_notesController.text),
    );

    final error =
        await ref.read(swimmerDataProvider.notifier).addSchedule(entry);
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      if (error == null) {
        _showForm = false;
        _titleController.clear();
        _startTimeController.clear();
        _locationController.clear();
        _eventsController.clear();
        _notesController.clear();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ??
              '${_typeLabel(_scheduleType)} saved to your upcoming schedule. '
              'After the meet, log official times on the Meets tab.',
        ),
        backgroundColor: error != null ? Colors.red.shade700 : null,
      ),
    );
  }

  Future<void> _deleteEntry(SwimScheduleEntry entry) async {
    if (entry.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove schedule entry?'),
        content: Text('Delete ${entry.title}?'),
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

    final error = await ref
        .read(swimmerDataProvider.notifier)
        .deleteSchedule(entry.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Schedule removed.')),
    );
  }

  String? _optional(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(swimmerDataProvider).value;
    final schedules = data?.schedules ?? const <SwimScheduleEntry>[];
    final dateFormat = DateFormat.yMMMd();
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final upcoming = schedules
        .where(
          (entry) => !DateTime(
            entry.scheduleDate.year,
            entry.scheduleDate.month,
            entry.scheduleDate.day,
          ).isBefore(startOfToday),
        )
        .toList()
      ..sort((a, b) => a.scheduleDate.compareTo(b.scheduleDate));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.compact ? 'Upcoming schedule' : 'Upcoming meets & practices',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            if (widget.onOpenRaceIntelligence != null)
              TextButton.icon(
                onPressed: widget.onOpenRaceIntelligence,
                icon: const Icon(Icons.flag_outlined, size: 18),
                label: const Text('Race plan'),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Plan what is coming up (meets and practices). '
          'This is NOT where official race times go — use the Meets tab for results after you swim.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textDark.withValues(alpha: 0.7),
                height: 1.4,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () => _openForm(SwimScheduleEntry.typeMeet),
              icon: const Icon(Icons.emoji_events_outlined, size: 18),
              label: const Text('Add upcoming meet'),
            ),
            FilledButton.tonalIcon(
              onPressed: () => _openForm(SwimScheduleEntry.typePractice),
              icon: const Icon(Icons.pool_outlined, size: 18),
              label: const Text('Add practice'),
            ),
            OutlinedButton.icon(
              onPressed: _openMeetResultsTab,
              icon: const Icon(Icons.timer_outlined, size: 18),
              label: const Text('Log meet results (Meets tab)'),
            ),
          ],
        ),
        if (_showForm) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'New ${_typeLabel(_scheduleType)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: SwimScheduleEntry.typeMeet,
                          label: Text('Meet'),
                        ),
                        ButtonSegment(
                          value: SwimScheduleEntry.typePractice,
                          label: Text('Practice'),
                        ),
                      ],
                      selected: {_scheduleType == SwimScheduleEntry.typeRace
                          ? SwimScheduleEntry.typeMeet
                          : _scheduleType},
                      onSelectionChanged: (values) {
                        setState(() => _scheduleType = values.first);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: _titleFieldLabel(),
                        hintText: _titleFieldHint(),
                      ),
                      validator: (value) =>
                          value?.trim().isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Date'),
                      subtitle: Text(dateFormat.format(_scheduleDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _startTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Start / warm-up time (optional)',
                        hintText: '9:30 AM warm-up',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Pool / location (optional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _eventsController,
                      decoration: InputDecoration(
                        labelText: _eventsFieldLabel(),
                        hintText: _eventsFieldHint(),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        hintText: 'Heat sheet, lane, or coach notes',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    KeyedSubtree(
                      key: _saveSectionKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SwimIqSaveButton(
                            label: 'Save upcoming ${_typeLabel(_scheduleType)}',
                            isSaving: _isSaving,
                            onPressed: _save,
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _isSaving
                                ? null
                                : () => setState(() => _showForm = false),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (upcoming.isEmpty)
          Text(
            'No upcoming meets or practices yet. Tap “Add upcoming meet” above.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textDark.withValues(alpha: 0.65),
                ),
          )
        else
          ...upcoming.map(
            (entry) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(_iconForType(entry.scheduleType)),
                title: Text(entry.title),
                subtitle: Text(
                  '${entry.typeLabel} · ${dateFormat.format(entry.scheduleDate)}'
                  '${entry.startTime != null ? ' · ${entry.startTime}' : ''}'
                  '${entry.eventsLine != null ? '\n${entry.eventsLine}' : ''}'
                  '${entry.notes != null ? '\n${entry.notes}' : ''}',
                ),
                isThreeLine: entry.eventsLine != null || entry.notes != null,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteEntry(entry),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static String _typeLabel(String type) {
    switch (type) {
      case SwimScheduleEntry.typeMeet:
        return 'meet';
      case SwimScheduleEntry.typeRace:
        return 'meet';
      default:
        return 'practice';
    }
  }

  String _titleFieldLabel() {
    return _scheduleType == SwimScheduleEntry.typePractice
        ? 'Practice name'
        : 'Meet name';
  }

  String _titleFieldHint() {
    return _scheduleType == SwimScheduleEntry.typePractice
        ? 'Saturday AM aerobic'
        : 'Central Regional Champs';
  }

  String _eventsFieldLabel() {
    return _scheduleType == SwimScheduleEntry.typePractice
        ? 'Workout focus (optional)'
        : 'Events she will swim (optional)';
  }

  String _eventsFieldHint() {
    return _scheduleType == SwimScheduleEntry.typePractice
        ? 'IM focus, kick set, etc.'
        : '50 Fly, 100 IM, 200 Free\n(one per line)';
  }

  static IconData _iconForType(String type) {
    switch (type) {
      case SwimScheduleEntry.typeMeet:
      case SwimScheduleEntry.typeRace:
        return Icons.emoji_events_outlined;
      default:
        return Icons.pool_outlined;
    }
  }
}
