import 'package:flutter/material.dart';
import 'package:skillzaar/core/models/service_categories.dart';

class ServiceCategoriesDemo extends StatelessWidget {
  const ServiceCategoriesDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Categories Demo'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Service Categories Overview',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Search functionality demo
            const Text(
              'Search Services',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildSearchDemo(),

            const SizedBox(height: 24),

            // Categories overview
            const Text(
              'All Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            ...ServiceCategories.allCategories.map((category) {
              return _buildCategoryCard(category);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchDemo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Try searching for: "cleaning", "plumbing", "painting"'),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search services...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (query) {
              if (query.isNotEmpty) {
                final results = ServiceCategories.searchServices(query);
                print('Search results for "$query": ${results.length} found');
                for (final result in results.take(3)) {
                  print('- ${result['service']} (${result['categoryName']})');
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(ServiceCategory category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: Text(category.emoji, style: const TextStyle(fontSize: 24)),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          category.description,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        children:
            category.subCategories.map((subCategory) {
              return ListTile(
                title: Text(subCategory.name),
                subtitle: Text(subCategory.description),
                trailing: Text(
                  '${subCategory.services.length} services',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                onTap: () {
                  _showServicesDialog(subCategory);
                },
              );
            }).toList(),
      ),
    );
  }

  void _showServicesDialog(ServiceSubCategory subCategory) {
    // This would show a dialog with all services in the subcategory
    // For now, just print them
    print('Services in ${subCategory.name}:');
    for (final service in subCategory.services) {
      print('- $service');
    }
  }
}
