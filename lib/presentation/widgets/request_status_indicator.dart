import 'package:flutter/material.dart';
class RequestStatusIndicator extends StatelessWidget {
  final String? status;
  const RequestStatusIndicator({Key? key, this.status}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label = status?.toUpperCase() ?? 'PENDING';
    if (status == 'accepted') {
      bg = Colors.green.shade100;
      fg = Colors.green.shade700;
    } else if (status == 'rejected') {
      bg = Colors.red.shade100;
      fg = Colors.red.shade700;
    } else {
      bg = Colors.orange.shade100;
      fg = Colors.orange.shade700;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text('Status: $label', style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}
