import 'package:flutter/material.dart';
import 'package:skillzaar/presentation/widgets/banner.dart';
import 'package:skillzaar/presentation/screens/job_poster/post_job_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedService = 'All';

  List<Map<String, String>> _getSubcategoriesFor(String serviceType) {
    final cleaning = [
      {
        'title': 'House Cleaning',
        'desc': 'Rooms, kitchen, bathrooms',
        'asset': 'assets/broom.png',
      },
      {
        'title': 'Car Cleaning',
        'desc': 'Interior & exterior',
        'asset': 'assets/carwash.png',
      },
      {
        'title': 'Sofa Cleaning',
        'desc': 'Fabric & leather care',
        'asset': 'assets/carpenter.png',
      },
      {
        'title': 'Water Tank Cleaning',
        'desc': 'Rooftop & underground',
        'asset': 'assets/window-cleaning.png',
      },
    ];

    switch (serviceType) {
      case 'Cleaning Services':
        return cleaning;
      case 'Plumbing Services':
        return [
          {
            'title': 'Leak Repair',
            'desc': 'Tap, pipe, shower leaks',
            'asset': 'assets/plumber.png',
          },
          {
            'title': 'Drain Cleaning',
            'desc': 'Clogs and slow drains',
            'asset': 'assets/plumber.png',
          },
          {
            'title': 'Fixture Install',
            'desc': 'Faucets, toilets, valves',
            'asset': 'assets/plumber.png',
          },
          {
            'title': 'Pipe Replacement',
            'desc': 'PVC & metal fitting',
            'asset': 'assets/plumber.png',
          },
        ];
      case 'Carpentry & Furniture':
        return [
          {
            'title': 'Furniture Repair',
            'desc': 'Chairs, tables, cabinets',
            'asset': 'assets/carpenter.png',
          },
          {
            'title': 'Assembly',
            'desc': 'Beds, wardrobes, shelves',
            'asset': 'assets/carpenter.png',
          },
          {
            'title': 'Polishing',
            'desc': 'Wood finishing & touch-ups',
            'asset': 'assets/carpenter.png',
          },
          {
            'title': 'Door/Frame Work',
            'desc': 'Install & adjustment',
            'asset': 'assets/carpenter.png',
          },
        ];
      case 'Painting & Finishing':
        return [
          {
            'title': 'Wall Painting',
            'desc': 'Per room or full house',
            'asset': 'assets/painter.png',
          },
          {
            'title': 'Furniture Paint',
            'desc': 'Doors, windows, frames',
            'asset': 'assets/painter.png',
          },
          {
            'title': 'Patch & Repair',
            'desc': 'Cracks, plaster, putty',
            'asset': 'assets/painter.png',
          },
          {
            'title': 'Polishing',
            'desc': 'Wood/marble finishing',
            'asset': 'assets/painter.png',
          },
        ];
      case 'Masonry & Metalwork':
        return [
          {
            'title': 'Brickwork Repair',
            'desc': 'Walls, edges, gaps',
            'asset': 'assets/brickwork.png',
          },
          {
            'title': 'Boundary Wall',
            'desc': 'Repair & rebuild',
            'asset': 'assets/brickwork.png',
          },
          {
            'title': 'Gate/Grill Welding',
            'desc': 'Repair & fabrication',
            'asset': 'assets/brickwork.png',
          },
          {
            'title': 'Metal Frames',
            'desc': 'Fix & reinforce',
            'asset': 'assets/brickwork.png',
          },
        ];
      case 'Roofing Services':
        return [
          {
            'title': 'Leak Repair',
            'desc': 'Seal and waterproof',
            'asset': 'assets/roof.png',
          },
          {
            'title': 'Tile Replacement',
            'desc': 'Shingle & sheet fix',
            'asset': 'assets/roof.png',
          },
          {
            'title': 'Roof Cleaning',
            'desc': 'Debris & wash',
            'asset': 'assets/roof.png',
          },
          {
            'title': 'Coating',
            'desc': 'Heat & waterproof layer',
            'asset': 'assets/roof.png',
          },
        ];
      case 'Glass & Installation':
        return [
          {
            'title': 'Glass Replace',
            'desc': 'Windows & mirrors',
            'asset': 'assets/window-cleaning.png',
          },
          {
            'title': 'TV Mount/Shelf',
            'desc': 'Install & leveling',
            'asset': 'assets/window-cleaning.png',
          },
          {
            'title': 'Curtains/Blinds',
            'desc': 'Rod & blind install',
            'asset': 'assets/window-cleaning.png',
          },
          {
            'title': 'Door/Window Align',
            'desc': 'Adjust & fix',
            'asset': 'assets/window-cleaning.png',
          },
        ];
      case 'Outdoor & Gardening':
        return [
          {
            'title': 'Lawn Mowing',
            'desc': 'Trim & edging',
            'asset': 'assets/gardener.png',
          },
          {
            'title': 'Hedge Trimming',
            'desc': 'Shape & prune',
            'asset': 'assets/gardener.png',
          },
          {
            'title': 'Exterior Wash',
            'desc': 'Driveway & house front',
            'asset': 'assets/gardener.png',
          },
          {
            'title': 'Planting',
            'desc': 'New plants & care',
            'asset': 'assets/gardener.png',
          },
        ];
      case 'Electrical Services':
        return [
          {
            'title': 'Install/Replace',
            'desc': 'Lights, fans, sockets',
            'asset': 'assets/electrician.png',
          },
          {
            'title': 'Repair',
            'desc': 'Fan/light, small wiring',
            'asset': 'assets/electrician.png',
          },
          {
            'title': 'Troubleshoot',
            'desc': 'Faults & fuses',
            'asset': 'assets/electrician.png',
          },
          {
            'title': 'Outdoor Lighting',
            'desc': 'Garden & facade',
            'asset': 'assets/electrician.png',
          },
        ];
      case 'Labour & Moving':
        return [
          {
            'title': 'General Labour',
            'desc': 'Per hour help',
            'asset': 'assets/labour-day.png',
          },
          {
            'title': 'Load/Unload',
            'desc': 'Furniture & goods',
            'asset': 'assets/labour-day.png',
          },
          {
            'title': 'Packing',
            'desc': 'Wrap & organize',
            'asset': 'assets/labour-day.png',
          },
          {
            'title': 'Moving Help',
            'desc': 'Shifting support',
            'asset': 'assets/labour-day.png',
          },
        ];
      case 'Car Care Services':
        return [
          {
            'title': 'Exterior Wash',
            'desc': 'Foam & rinse',
            'asset': 'assets/carwash.png',
          },
          {
            'title': 'Interior Clean',
            'desc': 'Vacuum & wipe',
            'asset': 'assets/carwash.png',
          },
          {
            'title': 'Detailing',
            'desc': 'Polish & protect',
            'asset': 'assets/carwash.png',
          },
          {
            'title': 'Towing',
            'desc': 'Recovery services',
            'asset': 'assets/carwash.png',
          },
        ];
      case 'Catering & Events':
        return [
          {
            'title': 'Catering',
            'desc': 'Small to large events',
            'asset': 'assets/catering.png',
          },
          {
            'title': 'Event Setup',
            'desc': 'Serving & layout',
            'asset': 'assets/catering.png',
          },
          {
            'title': 'Snacks & Tea',
            'desc': 'Quick service',
            'asset': 'assets/catering.png',
          },
          {
            'title': 'Cleanup',
            'desc': 'Post-event',
            'asset': 'assets/catering.png',
          },
        ];
      case 'Outdoor Construction':
        return [
          {
            'title': 'Landscaping',
            'desc': 'Garden design',
            'asset': 'assets/brickwork.png',
          },
          {
            'title': 'Driveway/Walk',
            'desc': 'Paving & repair',
            'asset': 'assets/brickwork.png',
          },
          {
            'title': 'Gates & Grills',
            'desc': 'Install & repair',
            'asset': 'assets/brickwork.png',
          },
          {
            'title': 'Pergolas',
            'desc': 'Outdoor spaces',
            'asset': 'assets/brickwork.png',
          },
        ];
      case 'All':
        return const [];
      default:
        return const [];
    }
  }

  // Get all service types from the simple dropdown
  List<String> _getServiceTypes() {
    return [
      'All',
      'Cleaning Services',
      'Plumbing Services',
      'Carpentry & Furniture',
      'Painting & Finishing',
      'Masonry & Metalwork',
      'Roofing Services',
      'Glass & Installation',
      'Outdoor & Gardening',
      'Electrical Services',
      'Labour & Moving',
      'Car Care Services',
      'Catering & Events',
      'Outdoor Construction',
    ];
  }

  // Get emoji for each service type
  String _getServiceEmoji(String serviceType) {
    switch (serviceType) {
      case 'All':
        return 'assets/workers.png';
      case 'Cleaning Services':
        return 'assets/broom.png';
      case 'Plumbing Services':
        return 'assets/plumber.png';
      case 'Carpentry & Furniture':
        return 'assets/carpenter.png';
      case 'Painting & Finishing':
        return 'assets/painter.png';
      case 'Masonry & Metalwork':
        return 'assets/brickwork.png';
      case 'Roofing Services':
        return 'assets/roof.png';
      case 'Glass & Installation':
        return 'assets/window-cleaning.png';
      case 'Outdoor & Gardening':
        return 'assets/gardener.png';
      case 'Electrical Services':
        return 'assets/electrician.png';
      case 'Labour & Moving':
        return 'assets/labour-day.png';
      case 'Car Care Services':
        return 'assets/carwash.png';
      case 'Catering & Events':
        return 'assets/catering.png';
      case 'Outdoor Construction':
        return 'assets/brickwork.png';
      default:
        return '🛠';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const HireBanner(),
          const SizedBox(height: 12),

          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _getServiceTypes().length,
              itemBuilder: (context, index) {
                final serviceType = _getServiceTypes()[index];
                return _buildChip(
                  serviceType,
                  _getServiceEmoji(serviceType),
                  serviceType,
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Builder(
              builder: (context) {
                if (_selectedService == 'All') {
                  final categories =
                      _getServiceTypes().where((e) => e != 'All').toList();
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categories.length,
                    itemBuilder: (context, sectionIndex) {
                      final selected = categories[sectionIndex];
                      final subcats = _getSubcategoriesFor(selected);
                      if (subcats.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                _getServiceEmoji(selected),
                                height: 28,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                selected,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 1.05,
                                ),
                            itemCount: subcats.length,
                            itemBuilder: (context, index) {
                              final item = subcats[index];
                              return _SubCategoryCard(
                                title: item['title'] ?? '',
                                subtitle: item['desc'] ?? '',
                                imageAsset:
                                    item['asset'] ?? 'assets/workers.png',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => PostJobScreen(
                                            initialTitle: item['title'] ?? '',
                                            initialDescription:
                                                item['desc'] ?? '',
                                            initialServiceType: selected,
                                          ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  );
                }

                final subcats = _getSubcategoriesFor(_selectedService);
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          _getServiceEmoji(_selectedService),
                          height: 28,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedService,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.05,
                          ),
                      itemCount: subcats.length,
                      itemBuilder: (context, index) {
                        final item = subcats[index];
                        return _SubCategoryCard(
                          title: item['title'] ?? '',
                          subtitle: item['desc'] ?? '',
                          imageAsset: item['asset'] ?? 'assets/workers.png',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => PostJobScreen(
                                      initialTitle: item['title'] ?? '',
                                      initialDescription: item['desc'] ?? '',
                                      initialServiceType: _selectedService,
                                    ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String emoji, String serviceType) {
    final isSelected = _selectedService == serviceType;
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedService = serviceType;
          });
        },
        child: Container(
          width: 70,
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            color:
                isSelected ? Colors.green.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border:
                isSelected ? Border.all(color: Colors.green, width: 2) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(emoji, height: 45),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.green : Colors.black87,
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  height: 1.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubCategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageAsset;
  final VoidCallback onTap;

  const _SubCategoryCard({
    required this.title,
    required this.subtitle,
    required this.imageAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            color: Colors.white,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: Image.asset(imageAsset, fit: BoxFit.cover),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🔹 Updated Job Card Widget
// Removed unused _JobCard (worker list) since we now display only categories/subcategories
