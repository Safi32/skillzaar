import 'package:flutter/material.dart';
import 'package:skillzaar/l10n/app_localizations.dart';

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

  String _getLocalizedServiceName(String service, AppLocalizations l10n) {
    switch (service) {
      case 'Cleaning Services':
        return l10n.cleaningServices;
      case 'Plumbing Services':
        return l10n.plumbingServices;
      case 'Carpentry & Furniture':
        return l10n.carpentryFurniture;
      case 'Painting & Finishing':
        return l10n.paintingFinishing;
      case 'Masonry & Metalwork':
        return l10n.masonryMetalwork;
      case 'Roofing Services':
        return l10n.roofingServices;
      case 'Glass & Installation':
        return l10n.glassInstallation;
      case 'Outdoor & Gardening':
        return l10n.outdoorGardening;
      case 'Electrical Services':
        return l10n.electricalServices;
      case 'Appliance Deep Cleaning':
        return l10n.applianceDeepCleaning;
      case 'Labour & Moving':
        return l10n.labourMoving;
      case 'Car Care Services':
        return l10n.carCareServices;
      case 'Water & Utility':
        return l10n.waterUtility;
      case 'Catering & Events':
        return l10n.cateringEvents;
      case 'Residential & Commercial Construction':
        return l10n.resCommConstruction;
      case 'Design & Planning':
        return l10n.designPlanning;
      case 'Renovation & Finishing':
        return l10n.renovationFinishing;
      case 'Specialized Works':
        return l10n.specializedWorks;
      case 'Outdoor Construction':
        return l10n.outdoorConstruction;
      default:
        return service;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.serviceType,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
              hint: Text(AppLocalizations.of(context)!.selectServiceType),
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              items:
                  _serviceTypes.map((String service) {
                    return DropdownMenuItem<String>(
                      value: service,
                      child: Text(_getLocalizedServiceName(service, l10n)),
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
