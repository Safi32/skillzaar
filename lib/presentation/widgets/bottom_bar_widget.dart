import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:skillzaar/l10n/app_localizations.dart';

class FloatingIslandNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingIslandNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.home, 'label': AppLocalizations.of(context)!.home},
      {'icon': Icons.sell, 'label': AppLocalizations.of(context)!.ads},
      {'icon': Icons.person, 'label': AppLocalizations.of(context)!.profile},
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(100),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(items.length, (index) {
              final selected = index == currentIndex;
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onTap(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        items[index]['icon'] as IconData,
                        color: selected ? Colors.green : Colors.grey[200],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        items[index]['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                          color: selected ? Colors.green : Colors.grey[200],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
