import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/swim_time.dart';

/// Shared stroke / course dropdowns for goals, logs, and meets.
class SwimStrokeDropdown extends StatelessWidget {
  const SwimStrokeDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Stroke',
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final selected =
        AppConstants.strokes.contains(value) ? value : AppConstants.strokes.first;

    return DropdownButtonFormField<String>(
      value: selected,
      decoration: InputDecoration(labelText: label),
      items: AppConstants.strokes
          .map((stroke) => DropdownMenuItem(value: stroke, child: Text(stroke)))
          .toList(),
      onChanged: (picked) {
        if (picked != null) onChanged(picked);
      },
    );
  }
}

class SwimCourseDropdown extends StatelessWidget {
  const SwimCourseDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Course',
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final selected =
        AppConstants.courses.contains(value) ? value : AppConstants.courses.first;

    return DropdownButtonFormField<String>(
      value: selected,
      decoration: InputDecoration(labelText: label),
      items: AppConstants.courses
          .map((course) => DropdownMenuItem(value: course, child: Text(course)))
          .toList(),
      onChanged: (picked) {
        if (picked != null) onChanged(picked);
      },
    );
  }
}

String formatLoggedTime(double timeSeconds) {
  if (timeSeconds <= 0) return 'No time logged';
  return SwimTime.fromSeconds(timeSeconds);
}
