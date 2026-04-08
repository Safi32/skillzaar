import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../providers/skilled_worker_provider.dart';

class CnicScreen extends StatefulWidget {
  const CnicScreen({super.key});

  @override
  State<CnicScreen> createState() => _CnicScreenState();
}

class _CnicScreenState extends State<CnicScreen> {
  File? frontImage;
  File? backImage;
  bool isUploading = false;

  Future<void> pickImage(bool isFront) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        if (isFront) {
          frontImage = File(picked.path);
        } else {
          backImage = File(picked.path);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Upload CNIC'),
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned(
            bottom: -size.height * 0.15,
            right: -size.width * 0.25,
            child: Container(
              width: size.width * 0.8,
              height: size.width * 0.8,
              decoration: const BoxDecoration(
                color: Color.fromRGBO(19, 185, 75, 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.transparent,
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
                      'Upload CNIC',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Upload your National ID (front & back)',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: _CnicImagePicker(
                            label: 'Front',
                            image: frontImage,
                            onTap: () => pickImage(true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _CnicImagePicker(
                            label: 'Back',
                            image: backImage,
                            onTap: () => pickImage(false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed:
                            (frontImage == null ||
                                    backImage == null ||
                                    isUploading)
                                ? null
                                : () async {
                                  setState(() => isUploading = true);
                                  try {
                                    // store temp images in provider to upload later
                                    final provider =
                                        Provider.of<SkilledWorkerProvider>(
                                          context,
                                          listen: false,
                                        );
                                    // Upload immediately and store URLs
                                    await provider.uploadCnicImages(
                                      front: frontImage!,
                                      back: backImage!,
                                    );

                                    // Redirect to profile screen after CNIC upload
                                    Navigator.pushNamed(
                                      context,
                                      '/skilled-worker-profile',
                                    );
                                  } finally {
                                    if (mounted)
                                      setState(() => isUploading = false);
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
                            isUploading
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : const Text(
                                  'Next',
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
        ],
      ),
    );
  }
}

class _CnicImagePicker extends StatelessWidget {
  final String label;
  final File? image;
  final VoidCallback onTap;

  const _CnicImagePicker({
    required this.label,
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: image != null ? AppColors.green : Colors.grey.shade300,
            width: image != null ? 2 : 1,
          ),
        ),
        child:
            image != null
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(image!, fit: BoxFit.cover),
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo,
                      color: Colors.grey.shade600,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
