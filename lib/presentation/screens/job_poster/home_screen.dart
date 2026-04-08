import 'package:flutter/material.dart';
import 'package:skillzaar/l10n/app_localizations.dart';
import 'package:skillzaar/presentation/widgets/banner.dart';
import 'package:skillzaar/presentation/screens/job_poster/post_job_screen.dart';

class HomeScreen extends StatefulWidget {
  final String searchQuery;
  const HomeScreen({Key? key, required this.searchQuery}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String _selectedService;

  @override
  void initState() {
    super.initState();
    // Pre-select the first category so it's highlighted on first load
    _selectedService = _getServiceTypes().first;
  }

  List<Map<String, String>> _getSubcategoriesFor(
    String serviceType,
    AppLocalizations l10n,
  ) {
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
            'title': l10n.leakRepair,
            'desc': l10n.tapPipeLeaks,
            'asset': 'assets/plumber.png',
          },
          {
            'title': l10n.drainCleaning,
            'desc': l10n.clogsSlowDrains,
            'asset': 'assets/plumber.png',
          },
          {
            'title': l10n.fixtureInstall,
            'desc': l10n.faucetsToilets,
            'asset': 'assets/plumber.png',
          },
          {
            'title': l10n.pipeReplacement,
            'desc': l10n.pvcMetalFitting,
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
            'title': l10n.leakRepair,
            'desc': l10n.tapPipeLeaks,
            'asset': 'assets/roof.png',
          },
          {
            'title': l10n.leakRepair,
            'desc': l10n.tapPipeLeaks,
            'asset': 'assets/roof.png',
          },
          {
            'title': l10n.leakRepair,
            'desc': l10n.tapPipeLeaks,
            'asset': 'assets/roof.png',
          },
          {
            'title': l10n.leakRepair,
            'desc': l10n.tapPipeLeaks,
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
      'Cleaning Services',
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
    // --- Search and filter logic ---
    final _searchQuery = widget.searchQuery;
    List<String> filteredCategories =
        _getServiceTypes().where((cat) {
          if (_searchQuery.isEmpty) return true;
          return cat.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

    String selected = _selectedService;
    List<Map<String, String>> subcats =
        selected.isNotEmpty
            ? _getSubcategoriesFor(selected, l10n).where((subcat) {
              if (_searchQuery.isEmpty) return true;
              return (subcat['title']?.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ??
                      false) ||
                  (subcat['desc']?.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ??
                      false);
            }).toList()
            : [];

    return Scaffold(
      body: Column(
        children: [
          const HireBanner(),
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredCategories.length,
              itemBuilder: (context, index) {
                final serviceType = filteredCategories[index];
                final isSelected = _selectedService == serviceType;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedService = serviceType),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      width: 76,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? const Color.fromRGBO(19, 185, 75, 0.12)
                                : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                isSelected
                                    ? const Color.fromRGBO(19, 185, 75, 0.2)
                                    : Colors.black.withValues(alpha: 0.06),
                            blurRadius: isSelected ? 12 : 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            _getServiceEmoji(serviceType),
                            height: 40,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _getLocalizedServiceName(serviceType, l10n),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color:
                                  isSelected
                                      ? const Color(0xFF13B94B)
                                      : Colors.grey[700],
                              fontSize: 9,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(
                top: 10,
                left: 16,
                right: 16,
                bottom: 100,
              ),
              itemCount: subcats.length,
              itemBuilder: (context, index) {
                final item = subcats[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SubCategoryCard(
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
                                initialServiceType: selected,
                              ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
    // _SubCategoryCard class remains unchanged below
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(19, 185, 75, 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: Image.asset(imageAsset, fit: BoxFit.contain),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(19, 185, 75, 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFF13B94B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
