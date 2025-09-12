import 'package:flutter/material.dart';
class FilterDialog extends StatelessWidget {
  final String selectedJobType;
  final double selectedRadius;
  final ValueChanged<String> onJobTypeChanged;
  final ValueChanged<double> onRadiusChanged;
  final VoidCallback onReset;
  final VoidCallback onApply;
  const FilterDialog({Key? key, required this.selectedJobType, required this.selectedRadius, required this.onJobTypeChanged, required this.onRadiusChanged, required this.onReset, required this.onApply}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Jobs'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Job Type:'),
          DropdownButton<String>(
            value: selectedJobType,
            isExpanded: true,
            items: [
              'All',
              'Software Engineer',
              'Developer',
              'Programmer',
              'Plumber',
              'Electrician',
              'Carpenter',
              'Painter',
              'Welder',
              'Mason',
              'Designer',
              'Marketing',
              'Sales',
              'Teacher',
              'Driver',
              'Chef',
              'Cleaner',
              'Security',
            ].map((String type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) onJobTypeChanged(newValue);
            },
          ),
          const SizedBox(height: 16),
          const Text('Radius (km):'),
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
        TextButton(
          onPressed: onReset,
          child: const Text('Reset'),
        ),
        TextButton(
          onPressed: onApply,
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
