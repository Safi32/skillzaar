import 'package:flutter/material.dart';
class JobActionButton extends StatelessWidget {
  final bool isAccepted;
  final VoidCallback onPressed;
  const JobActionButton({Key? key, required this.isAccepted, required this.onPressed}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(isAccepted ? Icons.play_arrow : Icons.check_circle),
        label: Text(isAccepted ? 'Start Work' : 'Mark Job as Complete'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
