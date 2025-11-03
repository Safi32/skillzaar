import 'package:flutter/material.dart';

class SavePortfolioButton extends StatelessWidget {
  final bool isFormValid;
  final VoidCallback? onPressed;
  final String saveLabel;
  final String incompleteLabel;

  const SavePortfolioButton({
    Key? key,
    required this.isFormValid,
    required this.onPressed,
    this.saveLabel = 'Save Portfolio',
    this.incompleteLabel = 'Complete Required Fields',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isFormValid
            ? [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: isFormValid ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isFormValid ? Colors.green : Colors.grey.shade400,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isFormValid) const Icon(Icons.save, size: 20),
            if (isFormValid) const SizedBox(width: 8),
            Text(
              isFormValid ? saveLabel : incompleteLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
