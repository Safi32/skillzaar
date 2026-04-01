import 'package:flutter/material.dart';
import 'package:skillzaar/l10n/app_localizations.dart';

class CategoriesSection extends StatelessWidget {
  final List<String> allCategories;
  final List<String> selectedCategories;
  final void Function(String) onToggleCategory;
  final VoidCallback onCustomCategory;
  const CategoriesSection({
    Key? key,
    required this.allCategories,
    required this.selectedCategories,
    required this.onToggleCategory,
    required this.onCustomCategory,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String getLocalizedCategory(String cat) {
      switch (cat) {
        case 'Electrical':
          return l10n.catElectrical;
        case 'Plumbing':
          return l10n.catPlumbing;
        case 'Carpentry':
          return l10n.catCarpentry;
        case 'Cleaning':
          return l10n.catCleaning;
        case 'Other':
          return l10n.catOther;
        default:
          return cat;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.selectSkills,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            TextButton.icon(
              onPressed: onCustomCategory,
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.custom),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          l10n.chooseSkillsDesc,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              allCategories.map((category) {
                final isSelected = selectedCategories.contains(category);
                return GestureDetector(
                  onTap: () => onToggleCategory(category),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.green : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isSelected ? Colors.green : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow:
                          isSelected
                              ? [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ]
                              : null,
                    ),
                    child: Text(
                      getLocalizedCategory(category),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
        if (selectedCategories.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.selectedCategoriesCount(
                    selectedCategories.length.toString(),
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
