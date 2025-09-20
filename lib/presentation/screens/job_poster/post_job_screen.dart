import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/ui_state_provider.dart';
import '../../widgets/job_title_input.dart';
import '../../widgets/job_description_input.dart';
import '../../widgets/job_location_picker.dart';
import '../../widgets/job_image_picker.dart';
import '../../widgets/post_job_button.dart';
import '../../widgets/simple_service_dropdown.dart';

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
  final TextEditingController priceController = TextEditingController();
  final List<File> images = [];

  String selectedAddress = '';
  double? selectedLatitude;
  double? selectedLongitude;
  String? selectedServiceType;

  Future<void> pickImage() async {
    if (images.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can upload a maximum of 3 images'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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

  Future<void> _submitJob() async {
    if (titleController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        selectedAddress.isEmpty ||
        priceController.text.isEmpty ||
        selectedServiceType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill all required fields including service type',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final parsedPrice = double.tryParse(
      priceController.text.replaceAll(',', ''),
    );
    if (parsedPrice == null || parsedPrice < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid price in PKR'),
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
        price: parsedPrice,
        location: selectedAddress,
        address: selectedAddress,
        latitude: selectedLatitude ?? 0.0,
        longitude: selectedLongitude ?? 0.0,
        context: context,
        serviceType: selectedServiceType,
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
        priceController.clear();
        setState(() {
          images.clear();
          selectedAddress = '';
          selectedLatitude = null;
          selectedLongitude = null;
          selectedServiceType = null;
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
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration({required String hint, String? prefix}) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefix,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.green, width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Stack(
        children: [
          /// Background circles
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                /// Custom AppBar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        "Post Job",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),

                /// Form Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.06,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCard(
                          child: JobTitleInput(controller: titleController),
                        ),
                        _buildCard(
                          child: JobDescriptionInput(
                            controller: descriptionController,
                          ),
                        ),
                        _buildCard(
                          child: SimpleServiceDropdown(
                            selectedService: selectedServiceType,
                            onServiceSelected: (service) {
                              setState(() {
                                selectedServiceType = service;
                              });
                            },
                          ),
                        ),
                        _buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Price (PKR)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: priceController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: _inputDecoration(
                                  hint: "e.g. 1500",
                                  prefix: "₨ ",
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildCard(
                          child: JobLocationPicker(
                            onLocationSelected: (address, lat, lng) {
                              setState(() {
                                selectedAddress = address;
                                selectedLatitude = lat;
                                selectedLongitude = lng;
                              });
                            },
                          ),
                        ),
                        _buildCard(
                          child: JobImagePicker(
                            images: images,
                            onAddImage: pickImage,
                            onRemoveImage: removeImage,
                          ),
                        ),
                        const SizedBox(height: 16),
                        PostJobButton(
                          isLoading: widget.uiProvider.isLoading,
                          onPressed:
                              widget.uiProvider.isLoading ? () {} : _submitJob,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
