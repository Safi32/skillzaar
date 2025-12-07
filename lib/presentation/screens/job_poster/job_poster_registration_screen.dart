// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../providers/phone_auth_provider.dart';
// import '../../../core/theme/app_theme.dart';

// class JobPosterRegistrationScreen extends StatefulWidget {
//   const JobPosterRegistrationScreen({super.key});

//   @override
//   State<JobPosterRegistrationScreen> createState() => _JobPosterRegistrationScreenState();
// }

// class _JobPosterRegistrationScreenState extends State<JobPosterRegistrationScreen> {
//   final TextEditingController phoneController = TextEditingController();

//   @override
//   void dispose() {
//     phoneController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     final phoneAuthProvider = Provider.of<PhoneAuthProvider>(context);

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: EdgeInsets.symmetric(
//               horizontal: size.width * 0.08,
//               vertical: size.height * 0.08,
//             ),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const SizedBox(height: 40),
//                 Icon(Icons.lock_outline, size: 48, color: Colors.green),
//                 const SizedBox(height: 16),
//                 const Text(
//                   'Job Poster Sign Up',
//                   style: TextStyle(
//                     fontSize: 26,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.green,
//                   ),
//                 ),
//                 const SizedBox(height: 32),
//                 TextField(
//                   controller: phoneController,
//                   keyboardType: TextInputType.phone,
//                   decoration: InputDecoration(
//                     labelText: 'Phone Number',
//                     hintText: 'Enter Your Phone Number',
//                     prefixIcon: const Icon(Icons.phone, color: Colors.green),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   enabled: !phoneAuthProvider.isLoading,
//                 ),
//                 const SizedBox(height: 24),
//                 if (phoneAuthProvider.error != null)
//                   Padding(
//                     padding: const EdgeInsets.only(bottom: 8.0),
//                     child: Text(
//                       phoneAuthProvider.error!,
//                       style: const TextStyle(color: Colors.red),
//                     ),
//                   ),
//                 SizedBox(
//                   width: double.infinity,
//                   height: 48,
//                   child: ElevatedButton(
//                     onPressed:
//                         phoneAuthProvider.isLoading
//                             ? null
//                             : () async {
//                               final rawInput = phoneController.text.trim();
//                               if (rawInput.isEmpty) {
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   const SnackBar(
//                                     content: Text(
//                                       'Please enter a phone number',
//                                     ),
//                                     backgroundColor: Colors.red,
//                                   ),
//                                 );
//                                 return;
//                               }

//                               // Send OTP
//                               await phoneAuthProvider.sendOtp(
//                                 rawInput,
//                                 context,
//                                 isUser: false,
//                               );
                              
//                               if (phoneAuthProvider.error == null &&
//                                   phoneAuthProvider.verificationId != null) {
//                                 Navigator.pushNamed(context, '/job-poster-otp');
//                               } else if (phoneAuthProvider.error != null) {
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   SnackBar(
//                                     content: Text(phoneAuthProvider.error!),
//                                   ),
//                                 );
//                               }
//                             },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppColors.green,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       elevation: 1,
//                     ),
//                     child:
//                         phoneAuthProvider.isLoading
//                             ? const CircularProgressIndicator(
//                               color: Colors.white,
//                             )
//                             : const Text(
//                               'Send OTP',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 18,
//                               ),
//                             ),
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text(
//                       "Already have an account?",
//                       style: TextStyle(color: Colors.black54),
//                     ),
//                     TextButton(
//                       onPressed: () {
//                         Navigator.pushNamed(context, '/login');
//                       },
//                       child: const Text(
//                         'Login',
//                         style: TextStyle(
//                           color: Colors.green,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
