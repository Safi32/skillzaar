import '../../widgets/profile_completion_card.dart';
import '../../widgets/categories_section.dart';
import '../../widgets/experience_section.dart';
import '../../widgets/hourly_rate_section.dart';
import '../../widgets/availability_section.dart';
import '../../widgets/editable_bio_section.dart';
import '../../widgets/editable_portfolio_section.dart';
import '../../widgets/save_portfolio_button.dart';
import '../../widgets/custom_category_dialog.dart';
import '../../widgets/dialogs.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/home_profile_provider.dart';


class HomeProfileScreen extends StatelessWidget {
  const HomeProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProfileProvider>(
      builder: (context, homeProfileProvider, child) {
        return _HomeProfileContent(homeProfileProvider: homeProfileProvider);
      },
    );
  }
}

class _HomeProfileContent extends StatefulWidget {
  final HomeProfileProvider homeProfileProvider;

  const _HomeProfileContent({required this.homeProfileProvider});

  @override
  State<_HomeProfileContent> createState() => _HomeProfileContentState();
}

class _HomeProfileContentState extends State<_HomeProfileContent> {
  final TextEditingController customCategoryController =
      TextEditingController();

  @override
  void dispose() {
    customCategoryController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Load existing skill profile data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.homeProfileProvider.loadPortfolioFromFirestore();
    });
  }

  void _showCustomCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomCategoryDialog(
          controller: customCategoryController,
          onCancel: () {
            Navigator.of(context).pop();
            customCategoryController.clear();
          },
          onAdd: () {
            if (customCategoryController.text.isNotEmpty) {
              widget.homeProfileProvider.addCustomCategory(
                customCategoryController.text.trim(),
              );
              Navigator.of(context).pop();
              customCategoryController.clear();
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
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
              _buildProfileCompletionCard(),
              const SizedBox(height: 32),

              // Select Categories
              _buildCategoriesSection(),
              const SizedBox(height: 32),

              // Years of Experience
              _buildExperienceSection(),
              const SizedBox(height: 32),

              // Hourly Rate
              _buildHourlyRateSection(),
              const SizedBox(height: 32),

              // Availability
              _buildAvailabilitySection(),
              const SizedBox(height: 32),

              // Short Bio
              _buildBioSection(),
              const SizedBox(height: 32),

              // Portfolio Pictures
              _buildPortfolioSection(),
              const SizedBox(height: 40),

              // Next Button
              _buildNextButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCompletionCard() {
    return ProfileCompletionCard(
      isProfileComplete: widget.homeProfileProvider.isProfileComplete,
      completionPercentage: widget.homeProfileProvider.profileCompletionPercentage,
      completionMessage: widget.homeProfileProvider.profileCompletionMessage,
      onHelp: () => _showProfileHelpDialog(context),
    );
  }

  Widget _buildCategoriesSection() {
    return CategoriesSection(
      allCategories: widget.homeProfileProvider.allCategories,
      selectedCategories: widget.homeProfileProvider.selectedCategories,
      onToggleCategory: (category) => widget.homeProfileProvider.toggleCategory(category),
      onCustomCategory: () => _showCustomCategoryDialog(context),
    );
  }

  Widget _buildExperienceSection() {
    return ExperienceSection(
      controller: widget.homeProfileProvider.experienceController,
      onChanged: (_) => widget.homeProfileProvider.updateProfileCompletion(),
    );
  }

  Widget _buildHourlyRateSection() {
    return HourlyRateSection(
      controller: widget.homeProfileProvider.hourlyRateController,
      onChanged: (_) => widget.homeProfileProvider.updateProfileCompletion(),
    );
  }

  Widget _buildAvailabilitySection() {
    return AvailabilitySection(
      controller: widget.homeProfileProvider.availabilityController,
      onChanged: (_) => widget.homeProfileProvider.updateProfileCompletion(),
    );
  }

  Widget _buildBioSection() {
    return EditableBioSection(
      controller: widget.homeProfileProvider.bioController,
      onChanged: (_) => widget.homeProfileProvider.updateProfileCompletion(),
    );
  }

  Widget _buildPortfolioSection() {
    return EditablePortfolioSection(
      images: List<String>.from(widget.homeProfileProvider.portfolioImages),
      onAddImage: widget.homeProfileProvider.addPortfolioImage,
      onRemoveImage: (index) => widget.homeProfileProvider.removePortfolioImage(index),
    );
  }

  Widget _buildNextButton() {
    return SavePortfolioButton(
      isFormValid: widget.homeProfileProvider.isFormValid,
      onPressed: widget.homeProfileProvider.isFormValid ? () => _saveSkillProfile(context) : null,
    );
  }

  void _saveSkillProfile(BuildContext context) async {
    // ...existing code...
    if (widget.homeProfileProvider.selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one skill category'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    if (widget.homeProfileProvider.experienceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your years of experience'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    if (widget.homeProfileProvider.bioController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write a bio about yourself'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    if (widget.homeProfileProvider.bioController.text.trim().length < 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bio must be at least 20 characters long'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.green),
                SizedBox(height: 16),
                Text('Saving your portfolio...'),
              ],
            ),
          );
        },
      );
      final success = await widget.homeProfileProvider.savePortfolioToFirestore();
      if (!mounted) return;
      Navigator.of(context).pop();
      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Portfolio saved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop();
      } else {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return RetryDialog(
              onCancel: () => Navigator.of(context).pop(),
              onRetry: () {
                Navigator.of(context).pop();
                _saveSkillProfile(context);
              },
            );
          },
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving portfolio: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // _showRetryDialog is now handled by RetryDialog widget

  void _showProfileHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ProfileHelpDialog(
          onGotIt: () => Navigator.of(context).pop(),
        );
      },
    );
  }
}
