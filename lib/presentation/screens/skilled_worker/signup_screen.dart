import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillzaar/core/examples/services/user_data_service.dart';
import '../../providers/skilled_worker_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'package:skillzaar/l10n/app_localizations.dart';

class SkilledWorkerSignUpScreen extends StatefulWidget {
  const SkilledWorkerSignUpScreen({super.key});

  @override
  State<SkilledWorkerSignUpScreen> createState() =>
      _SkilledWorkerSignUpScreenState();
}

class _SkilledWorkerSignUpScreenState extends State<SkilledWorkerSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController phoneController = TextEditingController();
  bool isLoading = false;

  bool _isValidPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (clean.length == 11 && clean.startsWith('0')) return true;
    if (clean.length == 10) return true;
    if (clean.length == 12 && clean.startsWith('92')) return true;
    if (clean.length == 13 && clean.startsWith('+92')) return true;
    return false;
  }

  String _formatPhone(String input) {
    input = input.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (input.startsWith('+')) return input;
    if (input.startsWith('0') && input.length == 11)
      return '+92${input.substring(1)}';
    if (input.startsWith('92') && input.length == 12) return '+$input';
    if (input.length == 10) return '+92$input';
    if (input.length == 11 && !input.startsWith('0')) return '+92$input';
    return input;
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: -size.height * 0.15,
            left: -size.width * 0.25,
            child: Container(
              width: size.width * 0.8,
              height: size.width * 0.8,
              decoration: const BoxDecoration(
                color: Color.fromRGBO(19, 185, 75, 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
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
          SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: 64,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios),
                          color: AppColors.green,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Image.asset(
                            'assets/applogo.png',
                            height: 52,
                            width: 52,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.08,
                        vertical: size.height * 0.04,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.lock_outline,
                              size: 48,
                              color: AppColors.green,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.skilledWorkerSignUp,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.green,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enter your phone number to create an account',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 32),
                            TextFormField(
                              controller: phoneController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.done,
                              enabled: !isLoading,
                              decoration: InputDecoration(
                                labelText: l10n.mobileNumber,
                                labelStyle: const TextStyle(
                                  color: AppColors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                                hintText: l10n.enterPhoneHint,
                                filled: true,
                                fillColor: Colors.grey[100],
                                prefixIcon: const Icon(
                                  Icons.phone,
                                  color: AppColors.green,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: AppColors.green,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 1.5,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                final v = value?.trim() ?? '';
                                if (v.isEmpty)
                                  return 'Phone number is required';
                                if (!_isValidPhone(v))
                                  return 'Enter a valid Pakistani phone number';
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed:
                                    isLoading
                                        ? null
                                        : () async {
                                          if (!_formKey.currentState!
                                              .validate())
                                            return;

                                          setState(() => isLoading = true);
                                          try {
                                            final formattedPhone = _formatPhone(
                                              phoneController.text.trim(),
                                            );
                                            final userId =
                                                'skilled_worker_${formattedPhone.replaceAll('+', '').replaceAll(' ', '')}_${DateTime.now().millisecondsSinceEpoch}';
                                            final userExists =
                                                await UserDataService.userExistsByPhone(
                                                  phoneNumber: formattedPhone,
                                                  userType: 'skilled_worker',
                                                );

                                            if (userExists) {
                                              if (mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      l10n.userExistsError,
                                                    ),
                                                    backgroundColor:
                                                        Colors.orange,
                                                  ),
                                                );
                                              }
                                              setState(() => isLoading = false);
                                              return;
                                            }

                                            await UserDataService.createSkilledWorker(
                                              userId: userId,
                                              phoneNumber: formattedPhone,
                                              displayName: 'Skilled Worker',
                                            );

                                            final swp = Provider.of<
                                              SkilledWorkerProvider
                                            >(context, listen: false);
                                            swp.setLoggedInState(
                                              userId: userId,
                                              phoneNumber: formattedPhone,
                                            );

                                            if (mounted) {
                                              Navigator.pushNamedAndRemoveUntil(
                                                context,
                                                '/skilled-worker-cnic',
                                                (route) => false,
                                                arguments: {'userId': userId},
                                              );
                                            }
                                          } catch (e) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    '${l10n.registrationFailed}: $e',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          } finally {
                                            if (mounted)
                                              setState(() => isLoading = false);
                                          }
                                        },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 8,
                                  shadowColor: const Color.fromRGBO(
                                    19,
                                    185,
                                    75,
                                    0.5,
                                  ),
                                ),
                                child:
                                    isLoading
                                        ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : Text(
                                          l10n.signUp,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${l10n.alreadyHaveAccount} ",
                                  style: const TextStyle(color: Colors.black54),
                                ),
                                TextButton(
                                  onPressed:
                                      () => Navigator.pushNamed(
                                        context,
                                        '/skilled-worker-login',
                                      ),
                                  child: const Text(
                                    'Login',
                                    style: TextStyle(
                                      color: AppColors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
