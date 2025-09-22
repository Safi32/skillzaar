import 'package:flutter/material.dart';
import 'package:skillzaar/core/examples/services/user_data_service.dart';
import 'package:skillzaar/presentation/screens/skilled_worker/skilled_worker_profile.dart';
import 'package:skillzaar/presentation/widgets/banner.dart';
import 'package:skillzaar/core/services/performance_monitor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedService = 'All';

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
            child: FutureBuilder<QuerySnapshot>(
              future: UserDataService.getApprovedSkilledWorkersByService(
                _selectedService,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Failed to load workers: ${snapshot.error}'),
                  );
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.work_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedService == 'All'
                              ? 'No skilled workers found'
                              : 'No $_selectedService workers available',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Check back later for new workers',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return PerformanceGridView(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final imageUrl =
                        (data['ProfilePicture'] ??
                                data['profilePicture'] ??
                                data['image'] ??
                                '')
                            .toString();
                    final name =
                        (data['Name'] ??
                                data['name'] ??
                                data['displayName'] ??
                                'Skilled Worker')
                            .toString();
                    final service =
                        (data['categories']?.isNotEmpty == true
                                ? (data['categories'][0]).toString()
                                : data['skills']?.isNotEmpty == true
                                ? (data['skills'][0]).toString()
                                : 'Service')
                            .toString();
                    final rate =
                        (data['hourlyRate'] ?? data['rate'] ?? '').toString();

                    return _JobCard(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SkilledWorkerProfile(),
                          ),
                        );
                      },
                      title: name,
                      subtitle: service,
                      rating: 4.8, // static for now
                      price: rate.isNotEmpty ? 'Rs $rate' : 'Rate N/A',
                      imageUrl:
                          imageUrl.isNotEmpty
                              ? imageUrl
                              : "https://via.placeholder.com/600x800.png?text=Worker",
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

// 🔹 Updated Job Card Widget
class _JobCard extends StatelessWidget {
  final String title;
  final double rating;
  final String price;
  final String subtitle;
  final String imageUrl;
  final VoidCallback onTap;

  const _JobCard({
    required this.title,
    required this.rating,
    required this.subtitle,
    required this.price,
    required this.onTap,
    this.imageUrl =
        "https://www.mnp.ca/-/media/foundation/integrations/personnel/2020/12/16/13/57/personnel-image-4483.jpg?h=800&iar=0&w=600&hash=833D605FDB6AC3C2D2915F6BF8B4ADA4", // dummy network image
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 185,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              // Gradient for readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  margin: const EdgeInsets.all(4),
                  padding: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Title, Rating, Price
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              subtitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            price,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
