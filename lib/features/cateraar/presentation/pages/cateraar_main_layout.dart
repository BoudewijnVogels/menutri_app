import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class CateraarMainLayout extends StatelessWidget {
  final Widget child;

  const CateraarMainLayout({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: AppColors.white,
        child: const Text(
          'Cateraar navigatie wordt binnenkort geïmplementeerd',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

