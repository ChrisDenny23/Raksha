// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:raksha/settings.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePictureOptionsSheet extends StatelessWidget {
  final ImagePicker _picker = ImagePicker();

  ProfilePictureOptionsSheet({super.key});

  Future<void> _pickAndUpdateImage(
      BuildContext context, ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (image == null) return;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 15),
                const Text(
                  'Updating...',
                  style: TextStyle(fontFamily: 'poppy'),
                ),
              ],
            ),
          ),
        ),
      );

      // Save image to local storage
      final appDir = await getApplicationDocumentsDirectory();
      final localPath = '${appDir.path}/profile_picture.jpg';

      // Copy the image to the application directory
      final File imageFile = File(image.path);
      await imageFile.copy(localPath);

      // Save the path to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_picture_path', localPath);

      // Close loading dialog and bottom sheet
      Navigator.of(context).pop();
      Navigator.of(context).pop();

      // Refresh the settings page

      Navigator.of(context)
          .pop(true); // Close the bottom sheet and pass true to refresh

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Profile picture updated successfully',
            style: TextStyle(fontFamily: 'poppy'),
          ),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      // Close dialogs
      Navigator.of(context).pop(); // Close loading dialog
      Navigator.of(context).pop(); // Close bottom sheet

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error updating profile picture: ${e.toString()}',
            style: const TextStyle(fontFamily: 'poppy'),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Change Profile Picture',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'poppy',
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildOptionItem(
                context,
                Icons.camera_alt,
                'Camera',
                () => _pickAndUpdateImage(context, ImageSource.camera),
              ),
              _buildOptionItem(
                context,
                Icons.photo_library,
                'Gallery',
                () => _pickAndUpdateImage(context, ImageSource.gallery),
              ),
              _buildOptionItem(
                context,
                Icons.delete,
                'Remove',
                () => _removeProfilePicture(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionItem(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'poppy',
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removeProfilePicture(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
      );

      // Remove profile picture from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final imagePath = prefs.getString('profile_picture_path');

      // Delete the image file if it exists
      if (imagePath != null) {
        final imageFile = File(imagePath);
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
        await prefs.remove('profile_picture_path');
      }

      // Close loading dialog and bottom sheet
      Navigator.of(context).pop();
      Navigator.of(context).pop();

      // Refresh the settings page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SettingsPage()),
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Profile picture removed',
            style: TextStyle(fontFamily: 'poppy'),
          ),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      // Close dialogs
      Navigator.of(context).pop();
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error removing profile picture: ${e.toString()}',
            style: const TextStyle(fontFamily: 'poppy'),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}
