import 'package:flutter/material.dart';
import 'package:skillzaar/l10n/app_localizations.dart';

class FilterDialog extends StatelessWidget {
  final String selectedJobType;
  final double selectedRadius;
  final ValueChanged<String> onJobTypeChanged;
  final ValueChanged<double> onRadiusChanged;
  final VoidCallback onReset;
  final VoidCallback onApply;
  const FilterDialog({
    Key? key,
    required this.selectedJobType,
    required this.selectedRadius,
    required this.onJobTypeChanged,
    required this.onRadiusChanged,
    required this.onReset,
    required this.onApply,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.filterJobs),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.jobType),
          DropdownButton<String>(
            value: selectedJobType,
            isExpanded: true,
            items:
                ['All'].map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type == 'All' ? l10n.all : type),
                  );
                }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) onJobTypeChanged(newValue);
            },
          ),
          const SizedBox(height: 16),
          Text(l10n.radiusKm),
          Slider(
            value: selectedRadius,
            min: 1,
            max: 200,
            divisions: 199,
            label: '${selectedRadius.round()} km',
            onChanged: onRadiusChanged,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: onReset, child: Text(l10n.reset)),
        TextButton(onPressed: onApply, child: Text(l10n.apply)),
      ],
    );
  }
}
