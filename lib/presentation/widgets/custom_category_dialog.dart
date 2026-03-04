import 'package:flutter/material.dart';
import 'package:skillzaar/l10n/app_localizations.dart';

class CustomCategoryDialog extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onCancel;
  final VoidCallback onAdd;

  const CustomCategoryDialog({
    Key? key,
    required this.controller,
    required this.onCancel,
    required this.onAdd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.addCustomCategory),
      content: Material(
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: l10n.enterCustomCategoryName,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
      ),
      actions: [
        TextButton(onPressed: onCancel, child: Text(l10n.cancel)),
        ElevatedButton(onPressed: onAdd, child: Text(l10n.add)),
      ],
    );
  }
}
