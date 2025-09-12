import 'package:flutter/material.dart';
class PostJobButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  const PostJobButton({Key? key, required this.isLoading, required this.onPressed}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Posting Job...',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            : const Text(
                'Post Job',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
