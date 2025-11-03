import 'package:flutter/material.dart';
import 'package:skillzaar/core/services/job_request_service.dart';

class SkilledWorkerProfile extends StatefulWidget {
  final String? workerId;
  final String? workerName;
  final String? workerImage;
  final String? workerRate;
  final String? workerService;

  const SkilledWorkerProfile({
    super.key,
    this.workerId,
    this.workerName,
    this.workerImage,
    this.workerRate,
    this.workerService,
  });

  @override
  State<SkilledWorkerProfile> createState() => _SkilledWorkerProfileState();
}

class _SkilledWorkerProfileState extends State<SkilledWorkerProfile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Top Image
              Stack(
                children: [
                  Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                      image: DecorationImage(
                        image: NetworkImage(
                          widget.workerImage?.isNotEmpty == true
                              ? widget.workerImage!
                              : "https://via.placeholder.com/800x400.png?text=Worker+Image",
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              padding: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_back_ios,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 🔹 Dynamic Content with Data Fetching
              if (widget.workerId != null)
                FutureBuilder<Map<String, dynamic>?>(
                  future: JobRequestService.getSkilledWorkerDetails(
                    widget.workerId!,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.error,
                                color: Colors.red,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Error loading worker details',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('Name: ${widget.workerName ?? 'Unknown'}'),
                              Text('Service: ${widget.workerService ?? 'N/A'}'),
                            ],
                          ),
                        ),
                      );
                    }

                    final workerData = snapshot.data;
                    final displayName =
                        workerData?['displayName']?.toString() ??
                        workerData?['name']?.toString() ??
                        widget.workerName ??
                        'Skilled Worker';
                    final hourlyRate =
                        workerData?['rate']?.toString() ??
                        workerData?['Rate']?.toString() ??
                        workerData?['hourlyRate']?.toString() ??
                        widget.workerRate ??
                        'Not specified';
                    final rating = workerData?['rating']?.toString() ?? '4.5';
                    final experience =
                        workerData?['experience']?.toString() ??
                        workerData?['Experience']?.toString() ??
                        'Not specified';
                    final bio =
                        workerData?['description']?.toString() ??
                        workerData?['Description']?.toString() ??
                        workerData?['bio']?.toString() ??
                        'No description available';
                    final skills =
                        workerData?['skills']?.toString() ??
                        workerData?['Skills']?.toString() ??
                        widget.workerService ??
                        'General Service';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔹 Title + Price
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                hourlyRate != 'Not specified'
                                    ? 'Rs $hourlyRate'
                                    : 'Rate N/A',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // 🔹 Ratings
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              ...List.generate(
                                5,
                                (index) => Icon(
                                  index <
                                          (double.tryParse(rating) ?? 4.5)
                                              .floor()
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                rating,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // 🔹 Service Type chip
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Chip(
                            label: Text(
                              skills,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.green,
                              ),
                            ),
                            backgroundColor: Colors.green.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 🔹 Experience
                        if (experience != 'Not specified')
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.work,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Experience: $experience',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 20),

                        // 🔹 Description
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            bio,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                )
              else
                // Fallback content when no workerId is provided
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Title + Price
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.workerName ?? 'Skilled Worker',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            widget.workerRate != null
                                ? 'Rs ${widget.workerRate}'
                                : 'Rate N/A',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 🔹 Ratings
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: List.generate(
                          5,
                          (index) => Icon(
                            index < 4 ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 20,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 🔹 Service Type chip
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Chip(
                        label: Text(
                          widget.workerService ?? 'General Service',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                        ),
                        backgroundColor: Colors.green.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 🔹 Description
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Professional skilled worker providing quality services.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
