import 'package:flutter/material.dart';

class DynamicHomeDemo extends StatelessWidget {
  const DynamicHomeDemo({Key? key}) : super(key: key);

  // Get all service types (same as in home screen)
  List<String> _getServiceTypes() {
    return [
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
  }

  // Get emoji for each service type (same as in home screen)
  String _getServiceEmoji(String serviceType) {
    switch (serviceType) {
      case 'Cleaning Services':
        return '🧹';
      case 'Plumbing Services':
        return '🔧';
      case 'Carpentry & Furniture':
        return '🪑';
      case 'Painting & Finishing':
        return '🎨';
      case 'Masonry & Metalwork':
        return '🧱';
      case 'Roofing Services':
        return '🏠';
      case 'Glass & Installation':
        return '🪟';
      case 'Outdoor & Gardening':
        return '🌳';
      case 'Electrical Services':
        return '💡';
      case 'Appliance Deep Cleaning':
        return '🏠';
      case 'Labour & Moving':
        return '👷';
      case 'Car Care Services':
        return '🚗';
      case 'Water & Utility':
        return '💧';
      case 'Catering & Events':
        return '🍴';
      case 'Residential & Commercial Construction':
        return '🏗';
      case 'Design & Planning':
        return '📐';
      case 'Renovation & Finishing':
        return '🛠';
      case 'Specialized Works':
        return '⚙';
      case 'Outdoor Construction':
        return '🌳';
      default:
        return '🛠';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dynamic Home Screen Demo'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Dynamic Service Type Chips',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'These chips are now dynamically generated from the same service types used in the dropdown:',
              style: TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 16),

          // Dynamic service type chips (same as home screen)
          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children:
                  _getServiceTypes().map((serviceType) {
                    return _buildChip(
                      serviceType,
                      _getServiceEmoji(serviceType),
                      serviceType,
                    );
                  }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'All Service Types:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _getServiceTypes().length,
              itemBuilder: (context, index) {
                final serviceType = _getServiceTypes()[index];
                return ListTile(
                  leading: Text(
                    _getServiceEmoji(serviceType),
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(serviceType),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Selected: $serviceType'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String emoji, String serviceType) {
    return GestureDetector(
      onTap: () {
        print('Selected service type: $serviceType');
      },
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 9,
                fontWeight: FontWeight.w500,
                height: 1.1,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
