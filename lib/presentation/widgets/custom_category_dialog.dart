import 'package:flutter/material.dart';

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
    return AlertDialog(
      title: const Text('Add Custom Category'),
      content: Material(
        child: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter custom category name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: onAdd,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
