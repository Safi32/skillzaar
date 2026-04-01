import 'package:flutter/material.dart';
import '../../core/models/service_categories.dart';
import '../../core/services/performance_monitor.dart';

class ServiceTypeSelector extends StatefulWidget {
  final String? selectedCategoryId;
  final String? selectedSubCategoryId;
  final String? selectedService;
  final Function(String categoryId, String subCategoryId, String service)
  onServiceSelected;

  const ServiceTypeSelector({
    Key? key,
    this.selectedCategoryId,
    this.selectedSubCategoryId,
    this.selectedService,
    required this.onServiceSelected,
  }) : super(key: key);

  @override
  State<ServiceTypeSelector> createState() => _ServiceTypeSelectorState();
}

class _ServiceTypeSelectorState extends State<ServiceTypeSelector>
    with PerformanceMonitoringMixin {
  String? _selectedCategoryId;
  String? _selectedSubCategoryId;
  String? _selectedService;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.selectedCategoryId;
    _selectedSubCategoryId = widget.selectedSubCategoryId;
    _selectedService = widget.selectedService;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onServiceSelected(
    String categoryId,
    String subCategoryId,
    String service,
  ) {
    setState(() {
      _selectedCategoryId = categoryId;
      _selectedSubCategoryId = subCategoryId;
      _selectedService = service;
    });
    widget.onServiceSelected(categoryId, subCategoryId, service);
  }

  void _onSearchChanged(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    // Use isolate for search to prevent UI blocking
    final results = await monitorMethod('service_search', () async {
      // For now, use the original search method
      // In a real implementation, you would pass all services to the isolate
      return ServiceCategories.searchServices(query);
    });

    if (mounted) {
      setState(() {
        _searchResults = results;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Service Type',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),

        // Search bar
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search for a service...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon:
                _searchController.text.isNotEmpty
                    ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                    : null,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Show search results or category selection
        if (_searchResults.isNotEmpty)
          _buildSearchResults()
        else
          _buildCategorySelection(),
      ],
    );
  }

  Widget _buildSearchResults() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final result = _searchResults[index];
          final isSelected = _selectedService == result['service'];

          return ListTile(
            leading: Text(
              result['emoji'],
              style: const TextStyle(fontSize: 20),
            ),
            title: Text(result['service']),
            subtitle: Text(
              '${result['categoryName']} - ${result['subCategoryName']}',
            ),
            trailing:
                isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
            selected: isSelected,
            onTap: () {
              _onServiceSelected(
                result['categoryId'],
                result['subCategoryId'],
                result['service'],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCategorySelection() {
    return Column(
      children: [
        // Selected service display
        if (_selectedService != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border.all(color: Colors.blue.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      ServiceCategories.getCategoryById(
                            _selectedCategoryId!,
                          )?.emoji ??
                          '🛠',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedService!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        setState(() {
                          _selectedCategoryId = null;
                          _selectedSubCategoryId = null;
                          _selectedService = null;
                        });
                      },
                    ),
                  ],
                ),
                if (_selectedCategoryId != null &&
                    _selectedSubCategoryId != null)
                  Text(
                    '${ServiceCategories.getCategoryById(_selectedCategoryId!)?.name} - ${ServiceCategories.getSubCategoryById(_selectedCategoryId!, _selectedSubCategoryId!)?.name}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
              ],
            ),
          ),

        if (_selectedService == null) ...[
          const SizedBox(height: 16),
          const Text(
            'Select a service category:',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),

          // Category selection
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.builder(
              itemCount: ServiceCategories.mainCategories.length,
              itemBuilder: (context, index) {
                final category = ServiceCategories.mainCategories[index];
                final isSelected = _selectedCategoryId == category.id;

                return ExpansionTile(
                  leading: Text(
                    category.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                  title: Text(category.name),
                  subtitle: Text(category.description),
                  trailing:
                      isSelected
                          ? const Icon(Icons.check, color: Colors.blue)
                          : null,
                  children:
                      category.subCategories.map((subCategory) {
                        return ListTile(
                          title: Text(subCategory.name),
                          subtitle: Text(subCategory.description),
                          onTap:
                              () => _showServiceSelection(
                                category.id,
                                subCategory.id,
                              ),
                        );
                      }).toList(),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  void _showServiceSelection(String categoryId, String subCategoryId) {
    final subCategory = ServiceCategories.getSubCategoryById(
      categoryId,
      subCategoryId,
    );
    if (subCategory == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            expand: false,
            builder:
                (context, scrollController) => Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        subCategory.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subCategory.description,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: subCategory.services.length,
                          itemBuilder: (context, index) {
                            final service = subCategory.services[index];
                            return ListTile(
                              title: Text(service),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                              ),
                              onTap: () {
                                _onServiceSelected(
                                  categoryId,
                                  subCategoryId,
                                  service,
                                );
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }
}
