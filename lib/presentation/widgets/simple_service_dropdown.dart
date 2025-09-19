import 'package:flutter/material.dart';

class SimpleServiceDropdown extends StatefulWidget {
  final String? selectedService;
  final Function(String service) onServiceSelected;

  const SimpleServiceDropdown({
    Key? key,
    this.selectedService,
    required this.onServiceSelected,
  }) : super(key: key);

  @override
  State<SimpleServiceDropdown> createState() => _SimpleServiceDropdownState();
}

class _SimpleServiceDropdownState extends State<SimpleServiceDropdown> {
  String? _selectedService;

  // All service types as a simple list
  static const List<String> _serviceTypes = [
    'Cleaning Services',
    'Plumbing Services',
    'Carpentry & Furniture',
    'Painting & Finishing',
    'Masonry & Metalwork',
    'Roofing Services',
    'Glass & Installation',
    'Outdoor & Gardening',
    'Electrical Services',
    'Appliance Deep Cleaning',
    'Labour & Moving',
    'Car Care Services',
    'Water & Utility',
    'Catering & Events',
    'Residential & Commercial Construction',
    'Design & Planning',
    'Renovation & Finishing',
    'Specialized Works',
    'Outdoor Construction',
  ];

  @override
  void initState() {
    super.initState();
    _selectedService = widget.selectedService;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Service Type',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedService,
              hint: const Text('Select a service type'),
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              items:
                  _serviceTypes.map((String service) {
                    return DropdownMenuItem<String>(
                      value: service,
                      child: Text(service),
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedService = newValue;
                  });
                  widget.onServiceSelected(newValue);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
