import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../../providers/skilled_worker_provider.dart';
import '../../providers/ui_state_provider.dart';
import '../../../core/theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  final SkilledWorkerProvider skilledWorkerProvider;
  final UIStateProvider uiProvider;

  const ProfileScreen({
    super.key,
    required this.skilledWorkerProvider,
    required this.uiProvider,
  });

  @override
  Widget build(BuildContext context) {
    return _ProfileContent(
      skilledWorkerProvider: skilledWorkerProvider,
      uiProvider: uiProvider,
    );
  }
}

class _ProfileContent extends StatefulWidget {
  final SkilledWorkerProvider skilledWorkerProvider;
  final UIStateProvider uiProvider;

  const _ProfileContent({
    required this.skilledWorkerProvider,
    required this.uiProvider,
  });

  @override
  State<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<_ProfileContent> {
  File? _profileImage;

  Future<void> _pickProfileImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
      });
      // Try uploading immediately and persist URL
      try {
        await widget.skilledWorkerProvider.uploadProfileImage(_profileImage!);
      } catch (_) {}
    }
  }

  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController workingRadiusController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Setup'),
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.08,
              vertical: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profile Setup',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.green,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Complete your profile to get started',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 32),

                Center(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(60),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 3,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(60),
                              child:
                                  _profileImage != null
                                      ? Image.file(
                                        _profileImage!,
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      )
                                      : Image.network(
                                        'https://via.placeholder.com/120x120/4CAF50/FFFFFF?text=Profile',
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Container(
                                            color: Colors.grey.shade200,
                                            child: Icon(
                                              Icons.person,
                                              size: 60,
                                              color: Colors.grey.shade600,
                                            ),
                                          );
                                        },
                                      ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () async {
                                showModalBottomSheet(
                                  context: context,
                                  builder:
                                      (context) => SafeArea(
                                        child: Wrap(
                                          children: [
                                            ListTile(
                                              leading: const Icon(
                                                Icons.camera_alt,
                                              ),
                                              title: const Text('Take Photo'),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _pickProfileImage(
                                                  ImageSource.camera,
                                                );
                                              },
                                            ),
                                            ListTile(
                                              leading: const Icon(
                                                Icons.photo_library,
                                              ),
                                              title: const Text(
                                                'Choose from Gallery',
                                              ),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _pickProfileImage(
                                                  ImageSource.gallery,
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(8),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Profile Picture',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your profile picture will be visible to clients',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Full Name
                const Text(
                  'Full Name',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Enter your full name',
                    prefixIcon: const Icon(
                      Icons.person,
                      color: AppColors.green,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Age
                const Text(
                  'Age',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Enter your age',
                    prefixIcon: const Icon(
                      Icons.calendar_today,
                      color: AppColors.green,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // City
                const Text(
                  'City',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: cityController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Enter your city',
                    prefixIcon: const Icon(
                      Icons.location_city,
                      color: AppColors.green,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Working Radius
                const Text(
                  'Working Radius',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: workingRadiusController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Working Radius',
                    hintText: 'Enter working radius in km',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Finish Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty ||
                          ageController.text.isEmpty ||
                          cityController.text.isEmpty ||
                          workingRadiusController.text.isEmpty) {
                        // Show warning toast instead of SnackBar
                        context.read<UIStateProvider>().showWarningToast(
                          context,
                          'Fields Required',
                          'Please fill all fields before continuing.',
                        );
                        return;
                      }

                      widget.uiProvider.startLoading();

                      try {
                        await widget.skilledWorkerProvider.postSkilledWorker(
                          name: nameController.text,
                          age: int.parse(ageController.text),
                          city: cityController.text,
                          workingRadiusKm:
                              int.tryParse(workingRadiusController.text) ?? 0,
                          profileImage: _profileImage,
                        );

                        // Show success toast instead of SnackBar
                        context.read<UIStateProvider>().showSuccessToast(
                          context,
                          'Profile Completed!',
                          'Your profile has been completed successfully! Your application is now under review.',
                        );

                        // Admin-created accounts are auto-approved, no approval waiting needed
                        // Profile completed successfully - user can continue using the app
                      } catch (e) {
                        // Show error toast instead of SnackBar
                        context.read<UIStateProvider>().showErrorToast(
                          context,
                          'Profile Creation Failed',
                          'Unable to create profile. Please try again.',
                        );
                      } finally {
                        widget.uiProvider.stopLoading();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 1,
                    ),
                    child:
                        widget.uiProvider.isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text(
                              'Finish',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
