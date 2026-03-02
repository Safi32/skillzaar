import 'package:flutter/material.dart';

import '../../core/widgets/animated_toast.dart';

class UIStateProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _showSnackBar = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get showSnackBar => _showSnackBar;

  // Loading state management
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void startLoading() {
    _isLoading = true;
    notifyListeners();
  }

  void stopLoading() {
    _isLoading = false;
    notifyListeners();
  }

  // Error state management
  void setError(String? error) {
    _errorMessage = error;
    _showSnackBar = error != null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _showSnackBar = false;
    notifyListeners();
  }

  // Success state management
  void setSuccess(String? success) {
    _successMessage = success;
    _showSnackBar = success != null;
    notifyListeners();
  }

  void clearSuccess() {
    _successMessage = null;
    _showSnackBar = false;
    notifyListeners();
  }

  // Clear all messages
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    _showSnackBar = false;
    notifyListeners();
  }

  // Reset all state
  void reset() {
    _isLoading = false;
    _errorMessage = null;
    _successMessage = null;
    _showSnackBar = false;
    notifyListeners();
  }

  // Toast notification methods (Now using animated toasts by default!)
  void showSuccessToast(BuildContext context, String title, String message) {
    ToastOverlay.instance.showSuccess(context, title, message);
  }

  void showErrorToast(BuildContext context, String title, String message) {
    ToastOverlay.instance.showError(context, title, message);
  }

  void showLocationToast(BuildContext context, String message) {
    ToastOverlay.instance.showLocationToast(context, message);
  }

  void showJobRequestToast(BuildContext context, String message) {
    ToastOverlay.instance.showJobRequestToast(context, message);
  }

  void showWarningToast(BuildContext context, String title, String message) {
    ToastOverlay.instance.showWarning(context, title, message);
  }

  void showInfoToast(BuildContext context, String title, String message) {
    ToastOverlay.instance.showInfo(context, title, message);
  }

  // Special method for job request accepted (most important!)
  void showJobRequestAcceptedToast(BuildContext context) {
    ToastOverlay.instance.showJobRequestToast(
      context,
      '🎉 Job Request Accepted! You can now navigate to the location.',
    );
  }

  void showAnimatedSuccessToast(
    BuildContext context,
    String title,
    String message,
  ) {
    ToastOverlay.instance.showSuccess(context, title, message);
  }

  void showAnimatedErrorToast(
    BuildContext context,
    String title,
    String message,
  ) {
    ToastOverlay.instance.showError(context, title, message);
  }

  void showAnimatedLocationToast(BuildContext context, String message) {
    ToastOverlay.instance.showLocationToast(context, message);
  }

  void showAnimatedJobRequestToast(BuildContext context, String message) {
    ToastOverlay.instance.showJobRequestToast(context, message);
  }

  void showAnimatedWarningToast(
    BuildContext context,
    String title,
    String message,
  ) {
    ToastOverlay.instance.showWarning(context, title, message);
  }

  void showAnimatedInfoToast(
    BuildContext context,
    String title,
    String message,
  ) {
    ToastOverlay.instance.showInfo(context, title, message);
  }
}
