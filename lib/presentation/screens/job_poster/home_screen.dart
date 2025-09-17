import 'package:flutter/material.dart';
import 'package:skillzaar/presentation/screens/skilled_worker/skilled_worker_profile.dart';
import 'package:skillzaar/presentation/widgets/banner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          HireBanner(),
          const SizedBox(height: 12),

          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildChip("Electrician", 'assets/electrician.png'),
                _buildChip("Plumber", 'assets/plumber.png'),
                _buildChip("Cleaning", 'assets/broom.png'),
                _buildChip("Painter", 'assets/painter.png'),
                _buildChip("Labour", 'assets/labour-day.png'),
                _buildChip("Roofing", 'assets/roof.png'),
                _buildChip("Gardener", 'assets/gardener.png'),
                _buildChip("Window", 'assets/window-cleaning.png'),
                _buildChip("Catering", 'assets/catering.png'),
                _buildChip("Car Wash", 'assets/carwash.png'),
                _buildChip("Mason", 'assets/brickwork.png'),
              ],
            ),
          ),
          const SizedBox(height: 16),          
          Expanded(
            child: FutureBuilder<QuerySnapshot>(
              future:
                  FirebaseFirestore.instance.collection('SkilledWorkers').get(),
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
                  return const Center(child: Text('No skilled workers found'));
                }

                return GridView.builder(
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
                        (data['primaryService'] ??
                                    data['service'] ??
                                    data['skills']?.isNotEmpty == true
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

  Widget _buildChip(String label, String assetPath) {
    return GestureDetector(
      onTap: () {
        // handle tap
      },
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                assetPath,
                width: 40,
                height: 40,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 180,
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
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            // Title, Rating, Price
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          price,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
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
    );
  }
}
