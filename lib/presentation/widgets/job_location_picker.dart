import 'package:flutter/material.dart';
import 'package:skillzaar/l10n/app_localizations.dart';
import 'package:skillzaar/presentation/widgets/location_picker_widget.dart';

typedef LocationSelected =
    void Function(String address, double lat, double lng);

class JobLocationPicker extends StatelessWidget {
  final LocationSelected onLocationSelected;
  const JobLocationPicker({Key? key, required this.onLocationSelected})
    : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.jobLocation,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        // Use your existing LocationPickerWidget here
        LocationPickerWidget(onLocationSelected: onLocationSelected),
      ],
    );
  }
}
