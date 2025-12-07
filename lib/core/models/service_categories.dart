class ServiceCategory {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final List<ServiceSubCategory> subCategories;

  const ServiceCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.subCategories,
  });
}

class ServiceSubCategory {
  final String id;
  final String name;
  final String description;
  final List<String> services;

  const ServiceSubCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.services,
  });
}

class ServiceCategories {
  static const List<ServiceCategory> allCategories = [
    // 1. Maintenance Services
    ServiceCategory(
      id: 'maintenance',
      name: 'Maintenance Services',
      emoji: '🛠',
      description:
          'Regular maintenance and repair services for homes and offices',
      subCategories: [
        ServiceSubCategory(
          id: 'cleaning',
          name: 'Cleaning Services',
          description: 'Professional cleaning services for all areas',
          services: [
            'Full House Deep Cleaning',
            'Room Deep Cleaning',
            'Kitchen Deep Cleaning',
            'Bathroom/Washroom Deep Cleaning',
            'Sofa Cleaning (per seat)',
            'Carpet Cleaning (per sq ft)',
            'Mattress Cleaning',
            'Curtain Cleaning',
            'Window Cleaning (interior & exterior)',
            'Water Tank Cleaning (rooftop & underground)',
            'Gutter & Drain Cleaning',
            'Office Cleaning (per office/desk)',
            'Post-Renovation Cleaning',
            'Move-in / Move-out Cleaning',
          ],
        ),
        ServiceSubCategory(
          id: 'plumbing',
          name: 'Plumbing Services',
          description: 'All plumbing repairs and installations',
          services: [
            'Leak Repair (tap, pipe, shower)',
            'Faucet/Tap Installation',
            'Pipe Replacement',
            'Bathroom Fixture Installation',
            'Drain Cleaning',
            'Pipe Insulation',
            'Water Heater Maintenance (non-electric)',
            'Clogged Toilet Repair',
            'PVC & Metal Pipe Cutting & Fitting',
            'Valve Replacement',
            'Toilet Seat Replacement',
          ],
        ),
        ServiceSubCategory(
          id: 'carpentry',
          name: 'Carpentry & Furniture',
          description: 'Furniture assembly, repair, and woodwork',
          services: [
            'Furniture Assembly / Disassembly',
            'Wardrobe Installation / Repair',
            'Bed Frame Assembly / Repair',
            'Chair / Stool Repair',
            'Table Repair / Polishing',
            'Cupboard / Door Repair',
            'Wooden Shelf Installation',
            'Furniture Polishing & Finishing',
            'Cabinet Door Alignment',
            'Door & Window Frame Installation / Adjustment',
          ],
        ),
        ServiceSubCategory(
          id: 'painting',
          name: 'Painting & Finishing',
          description: 'Painting and surface finishing services',
          services: [
            'Wall Painting (per room)',
            'Furniture Painting',
            'Door / Window Frame Painting',
            'Wall Patch & Repair',
            'Wood Polishing',
            'Marble Polishing',
            'Tile Polishing / Replacement',
            'Plaster Repair / Patching',
            'Wall Crack Repair',
          ],
        ),
        ServiceSubCategory(
          id: 'masonry',
          name: 'Masonry & Metalwork',
          description: 'Brickwork, metal repairs, and structural work',
          services: [
            'Brickwork Repair',
            'Boundary Wall Repair',
            'Gate Repair',
            'Grills / Bars Welding',
            'Metal Frame Repair',
            'Hand Rail Repair',
            'Metal Furniture Repair',
          ],
        ),
        ServiceSubCategory(
          id: 'roofing',
          name: 'Roofing Services',
          description: 'Roof maintenance and repair services',
          services: [
            'Roof Leak Repair',
            'Shingle / Tile Replacement',
            'Roof Cleaning',
            'Waterproof Coating',
          ],
        ),
        ServiceSubCategory(
          id: 'glass_installation',
          name: 'Glass & Installation',
          description: 'Glass work and general installation services',
          services: [
            'Window Glass Replacement',
            'Mirror Installation / Repair',
            'Shower Cabin Glass Installation',
            'TV Wall Mounting',
            'Shelf Installation',
            'Curtain Rod Installation',
            'Blinds Installation',
            'Door / Window Alignment',
            'Hook / Hanger Installation',
          ],
        ),
        ServiceSubCategory(
          id: 'outdoor_gardening',
          name: 'Outdoor & Gardening',
          description: 'Outdoor maintenance and gardening services',
          services: [
            'Lawn Mowing',
            'Hedge Trimming',
            'Planting / Gardening',
            'Driveway Pressure Washing',
            'House Front / Exterior Washing',
            'Boundary Wall Cleaning',
          ],
        ),
        ServiceSubCategory(
          id: 'electrical',
          name: 'Electrical Services',
          description: 'Electrical repairs and installations',
          services: [
            'Light / Fan Installation',
            'Switch / Socket Installation & Repair',
            'Fan / Light Repair',
            'Ceiling Fan Wiring',
            'Tube Light / LED Installation',
            'LED / Bulb Replacement',
            'Electrical Fault Troubleshooting',
            'Circuit Breaker / Fuse Replacement',
            'Panel / DB Box Maintenance',
            'Outdoor / Garden Lighting Installation',
            'Small Appliance Wiring Repair',
            'Wiring for New Rooms / Additions',
          ],
        ),
        ServiceSubCategory(
          id: 'appliance_cleaning',
          name: 'Appliance Deep Cleaning',
          description: 'Deep cleaning of household appliances',
          services: [
            'Washing Machine',
            'Refrigerator',
            'Oven',
            'Microwave',
            'Air Conditioner (non-electric)',
          ],
        ),
        ServiceSubCategory(
          id: 'labour_moving',
          name: 'Labour & Moving',
          description: 'General labour and moving services',
          services: [
            'General Labour (per hour)',
            'Load & Unload Furniture / Goods',
            'Run Errands (market, pick-up/drop-off)',
            'Packing & Unpacking',
            'Moving / Shifting Help',
          ],
        ),
      ],
    ),

    // 2. Specialty Services
    ServiceCategory(
      id: 'specialty',
      name: 'Specialty Services',
      emoji: '⚡',
      description:
          'Unique, occasional, or specialized services beyond regular maintenance',
      subCategories: [
        ServiceSubCategory(
          id: 'car_care',
          name: 'Car Care Services',
          description: 'Automotive cleaning and maintenance',
          services: [
            'Exterior Wash',
            'Interior Cleaning',
            'Full Car Detailing',
            'Remote Car Mechanics',
            'Towing Services',
          ],
        ),
        ServiceSubCategory(
          id: 'water_utility',
          name: 'Water & Utility',
          description: 'Water supply and utility services',
          services: ['Water Tankers', 'Water Bore (underground water supply)'],
        ),
        ServiceSubCategory(
          id: 'catering_events',
          name: 'Catering & Events',
          description: 'Food and event services',
          services: ['Catering Services (small & large events)'],
        ),
      ],
    ),

    // 3. Design & Construction
    ServiceCategory(
      id: 'construction',
      name: 'Design & Construction',
      emoji: '🏗',
      description: 'End-to-end building, renovation, and designing solutions',
      subCategories: [
        ServiceSubCategory(
          id: 'residential_commercial',
          name: 'Residential & Commercial Construction',
          description: 'Complete construction projects',
          services: [
            'House Construction (Grey Structure & Finishing)',
            'Plaza / Commercial Building Construction',
            'Industrial Construction (factories, sheds, warehouses)',
            'Boundary Wall Construction',
            'Extension / Additional Floor Construction',
          ],
        ),
        ServiceSubCategory(
          id: 'design_planning',
          name: 'Design & Planning',
          description: 'Architectural and structural design services',
          services: [
            'Architectural Design',
            'Structural Design & Engineering',
            '3D Modeling & Visualization',
            'Bill of Quantities (BOQ) & Cost Estimation',
            'Approvals & NOCs (CDA, RDA, LDA, etc.)',
          ],
        ),
        ServiceSubCategory(
          id: 'renovation_finishing',
          name: 'Renovation & Finishing',
          description: 'Home and office renovation services',
          services: [
            'Kitchen & Bathroom Renovation',
            'Complete House Renovation',
            'Flooring (marble, tiles, wood, vinyl)',
            'Ceiling Design (false ceiling, gypsum, POP)',
            'Wall Finishes (paint, wallpaper, cladding, texture)',
            'Exterior Elevation Works',
          ],
        ),
        ServiceSubCategory(
          id: 'specialized_works',
          name: 'Specialized Works',
          description: 'Specialized construction and installation work',
          services: [
            'Plumbing Layout Installation',
            'Electrical Wiring (new builds)',
            'HVAC Installation (ducting, cooling, heating)',
            'Waterproofing & Heatproofing',
            'Smart Home Setup (automation, security systems)',
            'Demolition & Site Clearing',
          ],
        ),
        ServiceSubCategory(
          id: 'outdoor_construction',
          name: 'Outdoor Construction',
          description: 'Outdoor construction and landscaping',
          services: [
            'Landscaping & Gardening for New Builds',
            'Driveway / Walkway Construction',
            'Garage / Car Porch Construction',
            'Gates & Grills Installation',
            'Pergolas, Gazebos & Outdoor Spaces',
            'Swimming Pool Construction',
          ],
        ),
      ],
    ),
  ];

  // Get all main categories
  static List<ServiceCategory> get mainCategories => allCategories;

  // Get category by ID
  static ServiceCategory? getCategoryById(String id) {
    try {
      return allCategories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get subcategory by ID
  static ServiceSubCategory? getSubCategoryById(
    String categoryId,
    String subCategoryId,
  ) {
    final category = getCategoryById(categoryId);
    if (category == null) return null;

    try {
      return category.subCategories.firstWhere(
        (sub) => sub.id == subCategoryId,
      );
    } catch (e) {
      return null;
    }
  }

  // Get all services for a subcategory
  static List<String> getServicesForSubCategory(
    String categoryId,
    String subCategoryId,
  ) {
    final subCategory = getSubCategoryById(categoryId, subCategoryId);
    return subCategory?.services ?? [];
  }

  // Search services by keyword
  static List<Map<String, dynamic>> searchServices(String keyword) {
    final results = <Map<String, dynamic>>[];
    final lowerKeyword = keyword.toLowerCase();

    for (final category in allCategories) {
      for (final subCategory in category.subCategories) {
        for (final service in subCategory.services) {
          if (service.toLowerCase().contains(lowerKeyword)) {
            results.add({
              'service': service,
              'categoryId': category.id,
              'categoryName': category.name,
              'subCategoryId': subCategory.id,
              'subCategoryName': subCategory.name,
              'emoji': category.emoji,
            });
          }
        }
      }
    }

    return results;
  }

  // Get popular services (first 3 from each main category)
  static List<Map<String, dynamic>> getPopularServices() {
    final results = <Map<String, dynamic>>[];

    for (final category in allCategories) {
      for (final subCategory in category.subCategories.take(1)) {
        for (final service in subCategory.services.take(3)) {
          results.add({
            'service': service,
            'categoryId': category.id,
            'categoryName': category.name,
            'subCategoryId': subCategory.id,
            'subCategoryName': subCategory.name,
            'emoji': category.emoji,
          });
        }
      }
    }

    return results;
  }
}
