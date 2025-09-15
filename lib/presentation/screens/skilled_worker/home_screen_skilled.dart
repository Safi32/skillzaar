import 'package:flutter/material.dart';
import 'package:skillzaar/presentation/widgets/banner.dart';

class HomeScreenSkilled extends StatelessWidget {
  const HomeScreenSkilled({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const HireBanner(),
          const SizedBox(height: 12),

          // 🔹 Categories (Jobs by type)
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildChip("Plumbing", 'assets/plumber.png'),
                _buildChip("Painting", 'assets/painter.png'),
                _buildChip("Cleaning", 'assets/broom.png'),
                _buildChip("Gardening", 'assets/gardener.png'),
                _buildChip("Masonry", 'assets/brickwork.png'),
                _buildChip("Electric Work", 'assets/electrician.png'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 🔹 Jobs List (for Skilled Worker to browse)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 6,
              itemBuilder: (context, index) {
                return JobCard(
                  onTap: () {
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => const JobDetailScreen(),
                    //   ),
                    // );
                  },
                  title: "Need Plumbing Repair",
                  company: "Ali Khan",
                  location: "Islamabad, PK",
                  salary: "\$100",
                  rating: 4.7,
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
        // filter jobs
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
              style: const TextStyle(
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

// 🔹 Job Card (for Skilled Workers)
class JobCard extends StatelessWidget {
  final String title;
  final String company;
  final String location;
  final String salary;
  final double rating;
  final VoidCallback onTap;

  const JobCard({
    super.key,
    required this.title,
    required this.company,
    required this.location,
    required this.salary,
    required this.rating,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Company/Poster Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.green.withOpacity(0.2),
              child: const Icon(Icons.work, color: Colors.green),
            ),
            const SizedBox(width: 12),

            // Job Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    company,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    location,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),

            // Salary + Rating
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  salary,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      rating.toString(),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
