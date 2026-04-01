import 'package:flutter/material.dart';
import 'package:skillzaar/l10n/app_localizations.dart';

class ServiceTypeSection extends StatelessWidget {
  final String? selectedServiceType;
  final Function(String?) onServiceTypeSelected;

  const ServiceTypeSection({
    Key? key,
    required this.selectedServiceType,
    required this.onServiceTypeSelected,
  }) : super(key: key);

  // Service types from job posting (same as SimpleServiceDropdown)
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

  String _getLocalizedServiceName(String serviceType, AppLocalizations l10n) {
    switch (serviceType) {
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
      case 'Labour & Moving':
        return l10n.labourMoving;
      case 'Car Care Services':
        return l10n.carCareServices;
      case 'Catering & Events':
        return l10n.cateringEvents;
      case 'Outdoor Construction':
        return l10n.outdoorConstruction;
      default:
        return serviceType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.primaryServiceType,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.serviceTypeDesc,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedServiceType,
              hint: Text(
                l10n.selectPrimaryServiceHint,
                style: const TextStyle(color: Colors.grey),
              ),
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
              items:
                  _serviceTypes.map((String service) {
                    return DropdownMenuItem<String>(
                      value: service,
                      child: Text(
                        _getLocalizedServiceName(service, l10n),
                        style: const TextStyle(fontSize: 16),
                      ),
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                onServiceTypeSelected(newValue);
              },
            ),
          ),
        ),
        if (selectedServiceType != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.selectedService(
                      _getLocalizedServiceName(selectedServiceType!, l10n),
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
