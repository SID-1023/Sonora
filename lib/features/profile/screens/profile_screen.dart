import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_outline_rounded,
              color: AppColors.secondaryText,
              size: 48,
            ),
            SizedBox(height: 12),
            Text('Your profile', style: TextStyle(color: AppColors.warmCream)),
          ],
        ),
      ),
    );
  }
}
