import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/swim_event_options.dart';

/// Web-safe event picker (dropdowns inside bottom sheets often fail on Flutter web).
Future<SwimEventOption?> showSwimEventPicker({
  required BuildContext context,
  required List<SwimEventOption> options,
  SwimEventOption? selected,
  String title = 'Select event',
}) async {
  if (options.isEmpty) return null;

  return showDialog<SwimEventOption>(
    context: context,
    builder: (dialogContext) => _SwimEventPickerDialog(
      options: options,
      selected: selected,
      title: title,
    ),
  );
}

class _SwimEventPickerDialog extends StatefulWidget {
  const _SwimEventPickerDialog({
    required this.options,
    required this.title,
    this.selected,
  });

  final List<SwimEventOption> options;
  final SwimEventOption? selected;
  final String title;

  @override
  State<_SwimEventPickerDialog> createState() => _SwimEventPickerDialogState();
}

class _SwimEventPickerDialogState extends State<_SwimEventPickerDialog> {
  final _controller = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _filter.trim().toLowerCase();
    final filtered = query.isEmpty
        ? widget.options
        : widget.options
            .where((o) => o.label.toLowerCase().contains(query))
            .toList();

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Search events',
                hintText: 'e.g. 100 Butterfly',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _filter = value),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 320,
              child: filtered.isEmpty
                  ? const Center(child: Text('No events match that search.'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final option = filtered[index];
                        final isSelected = widget.selected == option;
                        return ListTile(
                          dense: true,
                          selected: isSelected,
                          selectedTileColor:
                              AppColors.primary.withValues(alpha: 0.12),
                          title: Text(
                            option.label,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w900
                                  : FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(option.course),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primaryDeep,
                                )
                              : null,
                          onTap: () => Navigator.of(context).pop(option),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

/// Looks like a dropdown field; opens [showSwimEventPicker] on tap.
class SwimEventPickerField extends StatelessWidget {
  const SwimEventPickerField({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.enabled = true,
    this.labelText = 'Event',
    this.validator,
  });

  final List<SwimEventOption> options;
  final SwimEventOption? selected;
  final ValueChanged<SwimEventOption> onSelected;
  final bool enabled;
  final String labelText;
  final FormFieldValidator<SwimEventOption>? validator;

  @override
  Widget build(BuildContext context) {
    return FormField<SwimEventOption>(
      key: ValueKey(
        '${selected?.distance}-${selected?.stroke}-${selected?.course}-'
        '${options.length}',
      ),
      initialValue: selected,
      validator: validator ??
          (value) => (selected ?? value) == null ? 'Pick an event' : null,
      builder: (field) {
        final value = selected ?? field.value;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: !enabled || options.isEmpty
                ? null
                : () async {
                    final picked = await showSwimEventPicker(
                      context: context,
                      options: options,
                      selected: value,
                    );
                    if (picked == null) return;
                    field.didChange(picked);
                    onSelected(picked);
                  },
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              isEmpty: value == null,
              decoration: InputDecoration(
                labelText: labelText,
                errorText: field.errorText,
                suffixIcon: const Icon(Icons.arrow_drop_down),
                enabled: enabled && options.isNotEmpty,
              ),
              child: Text(
                value?.label ?? 'Tap to choose event',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: value == null
                          ? Colors.grey.shade600
                          : AppColors.textDark,
                      fontWeight:
                          value == null ? FontWeight.w600 : FontWeight.w700,
                    ),
              ),
            ),
          ),
        );
      },
    );
  }
}
