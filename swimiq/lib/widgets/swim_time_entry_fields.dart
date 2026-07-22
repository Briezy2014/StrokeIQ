import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/utils/swim_time.dart';

/// Minute / second / tenth / hundredth inputs for official meet times.
class SwimTimeEntryFields extends StatefulWidget {
  const SwimTimeEntryFields({
    super.key,
    this.onChanged,
  });

  final ValueChanged<double?>? onChanged;

  @override
  State<SwimTimeEntryFields> createState() => SwimTimeEntryFieldsState();
}

class SwimTimeEntryFieldsState extends State<SwimTimeEntryFields> {
  final _minutesController = TextEditingController();
  final _secondsController = TextEditingController();
  final _tenthsController = TextEditingController();
  final _hundredthsController = TextEditingController();

  @override
  void dispose() {
    _minutesController.dispose();
    _secondsController.dispose();
    _tenthsController.dispose();
    _hundredthsController.dispose();
    super.dispose();
  }

  double? tryParseSeconds() {
    final minutes = int.tryParse(_minutesController.text.trim()) ?? 0;
    final secondsText = _secondsController.text.trim();
    final tenthsText = _tenthsController.text.trim();
    final hundredthsText = _hundredthsController.text.trim();

    if (secondsText.isEmpty || tenthsText.isEmpty || hundredthsText.isEmpty) {
      return null;
    }

    final seconds = int.tryParse(secondsText);
    final tenths = int.tryParse(tenthsText);
    final hundredths = int.tryParse(hundredthsText);
    if (seconds == null || tenths == null || hundredths == null) {
      return null;
    }

    try {
      return SwimTime.fromParts(
        minutes: minutes,
        seconds: seconds,
        tenths: tenths,
        hundredths: hundredths,
      );
    } on FormatException {
      return null;
    }
  }

  String? validate() {
    final seconds = tryParseSeconds();
    if (seconds == null) {
      return 'Enter seconds, tenths, and hundredths';
    }
    if (seconds <= 0) {
      return 'Time must be greater than zero';
    }
    return null;
  }

  /// Prefill fields from a parsed swim time (used after photo extract).
  void setFromSeconds(double totalSeconds) {
    if (totalSeconds <= 0) return;
    final minutes = totalSeconds ~/ 60;
    final remainder = totalSeconds - (minutes * 60);
    final wholeSeconds = remainder.floor();
    final fractional = ((remainder - wholeSeconds) * 100).round().clamp(0, 99);
    final tenths = fractional ~/ 10;
    final hundredths = fractional % 10;
    _minutesController.text = minutes > 0 ? '$minutes' : '';
    _secondsController.text = '$wholeSeconds';
    _tenthsController.text = '$tenths';
    _hundredthsController.text = '$hundredths';
    _notifyChanged();
  }

  void _notifyChanged() {
    widget.onChanged?.call(tryParseSeconds());
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Result time',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _TimePartField(
                controller: _minutesController,
                label: 'Min',
                hint: '0',
                maxLength: 2,
                onChanged: _notifyChanged,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
              child: Text(':', style: labelStyle),
            ),
            Expanded(
              child: _TimePartField(
                controller: _secondsController,
                label: 'Sec',
                hint: '26',
                maxLength: 2,
                onChanged: _notifyChanged,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
              child: Text('.', style: labelStyle),
            ),
            Expanded(
              child: _TimePartField(
                controller: _tenthsController,
                label: 'Tenths',
                hint: '0',
                maxLength: 1,
                onChanged: _notifyChanged,
              ),
            ),
            Expanded(
              child: _TimePartField(
                controller: _hundredthsController,
                label: 'Hundredths',
                hint: '0',
                maxLength: 1,
                onChanged: _notifyChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Example: 400 IM in 6:26.00 → Min 6, Sec 26, Tenths 0, Hundredths 0',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _TimePartField extends StatelessWidget {
  const _TimePartField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.maxLength,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLength;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: maxLength,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        isDense: true,
      ),
      onChanged: (_) => onChanged(),
    );
  }
}
