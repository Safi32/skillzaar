import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/ui_state_provider.dart';
import '../../widgets/job_title_input.dart';
import '../../widgets/job_description_input.dart';
import '../../widgets/job_location_picker.dart';
import '../../widgets/job_image_picker.dart';
import '../../widgets/post_job_button.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PostJobScreen extends StatelessWidget {
  const PostJobScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<JobProvider, UIStateProvider>(
      builder: (context, jobProvider, uiProvider, child) {
        return _PostJobContent(
          jobProvider: jobProvider,
          uiProvider: uiProvider,
        );
      },
    );
  }
}

class _PostJobContent extends StatefulWidget {
  final JobProvider jobProvider;
  final UIStateProvider uiProvider;

  const _PostJobContent({required this.jobProvider, required this.uiProvider});

  @override
  State<_PostJobContent> createState() => _PostJobContentState();
}

class _PostJobContentState extends State<_PostJobContent> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final List<File> images = [];
  String selectedAddress = '';
  double? selectedLatitude;
  double? selectedLongitude;

  Future<void> pickImage() async {
    if (images.length >= 3) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (picked != null) {
        setState(() {
          images.add(File(picked.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void removeImage(int index) {
    setState(() {
      images.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Post Job',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.08,
            vertical: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              JobTitleInput(controller: titleController),
              const SizedBox(height: 24),
              JobDescriptionInput(controller: descriptionController),
              const SizedBox(height: 24),
              JobLocationPicker(
                onLocationSelected: (address, lat, lng) {
                  setState(() {
                    selectedAddress = address;
                    selectedLatitude = lat;
                    selectedLongitude = lng;
                  });
                },
              ),
              const SizedBox(height: 24),
              JobImagePicker(
                images: images,
                onAddImage: pickImage,
                onRemoveImage: removeImage,
              ),
              const SizedBox(height: 32),
              PostJobButton(
                isLoading: widget.uiProvider.isLoading,
                onPressed: widget.uiProvider.isLoading
                    ? () {}
                    : () async {
                        if (titleController.text.isEmpty ||
                            descriptionController.text.isEmpty ||
                            selectedAddress.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill all required fields'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        widget.uiProvider.setLoading(true);
                        try {
                          await widget.jobProvider.postJob(
                            name_en: titleController.text,
                            name_ur: titleController.text,
                            description_en: descriptionController.text,
                            description_ur: descriptionController.text,
                            image: images.isNotEmpty ? images.first : null,
                            location: selectedAddress,
                            address: selectedAddress,
                            latitude: selectedLatitude ?? 0.0,
                            longitude: selectedLongitude ?? 0.0,
                          );
                          if (widget.jobProvider.success != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(widget.jobProvider.success!),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                            titleController.clear();
                            descriptionController.clear();
                            setState(() {
                              images.clear();
                              selectedAddress = '';
                              selectedLatitude = null;
                              selectedLongitude = null;
                            });
                            Navigator.of(context).pop();
                          } else if (widget.jobProvider.error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(widget.jobProvider.error!),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error posting job: $e'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        } finally {
                          widget.uiProvider.setLoading(false);
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
