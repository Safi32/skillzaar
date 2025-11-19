import 'package:flutter/material.dart';
import '../../widgets/simple_service_dropdown.dart';

class SimpleServiceDemo extends StatefulWidget {
  const SimpleServiceDemo({Key? key}) : super(key: key);

  @override
  State<SimpleServiceDemo> createState() => _SimpleServiceDemoState();
}

class _SimpleServiceDemoState extends State<SimpleServiceDemo> {
  String? selectedService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Service Dropdown Demo'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Service Type Selection',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            const Text(
              'This is a simple dropdown with all service types:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            SimpleServiceDropdown(
              selectedService: selectedService,
              onServiceSelected: (service) {
                setState(() {
                  selectedService = service;
                });
              },
            ),

            const SizedBox(height: 24),

            if (selectedService != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected Service:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedService!,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            const Text(
              'Available Service Types:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: ListView.builder(
                itemCount: 19, // Total number of service types
                itemBuilder: (context, index) {
                  final services = [
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

                  return ListTile(
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text(services[index]),
                    onTap: () {
                      setState(() {
                        selectedService = services[index];
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
