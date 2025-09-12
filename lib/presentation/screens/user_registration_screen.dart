import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/phone_auth_provider.dart';
import '../providers/ui_state_provider.dart';

class UserRegistrationScreen extends StatelessWidget {
  const UserRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Registration')),
      body: Consumer2<PhoneAuthProvider, UIStateProvider>(
        builder: (context, phoneAuthProvider, uiProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Enter your phone number to register',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: phoneAuthProvider.phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                uiProvider.isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                      onPressed: () async {
                        uiProvider.startLoading();
                        await phoneAuthProvider.sendOtp(
                          phoneAuthProvider.phoneController.text.trim(),
                          context,
                          isUser: true,
                        );

                        if (phoneAuthProvider.error == null &&
                            phoneAuthProvider.verificationId != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (_) => UserOtpScreen(
                                    phoneNumber:
                                        phoneAuthProvider.phoneController.text
                                            .trim(),
                                  ),
                            ),
                          );
                        } else if (phoneAuthProvider.error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(phoneAuthProvider.error!)),
                          );
                        }
                        uiProvider.stopLoading();
                      },
                      child: const Text('Send OTP'),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class UserOtpScreen extends StatelessWidget {
  final String phoneNumber;
  const UserOtpScreen({super.key, required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return Consumer2<PhoneAuthProvider, UIStateProvider>(
      builder: (context, phoneAuthProvider, uiProvider, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Enter OTP')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('OTP sent to $phoneNumber'),
                const SizedBox(height: 20),
                TextField(
                  controller: phoneAuthProvider.otpController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'OTP',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                uiProvider.isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                      onPressed: () async {
                        uiProvider.startLoading();
                        await phoneAuthProvider.verifyOtp(
                          phoneAuthProvider.otpController.text.trim(),
                          context,
                          isUser: true,
                        );

                        if (phoneAuthProvider.error == null) {
                          Navigator.of(
                            context,
                          ).pushReplacementNamed('/role-selection');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(phoneAuthProvider.error!)),
                          );
                        }
                        uiProvider.stopLoading();
                      },
                      child: const Text('Verify OTP'),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}
