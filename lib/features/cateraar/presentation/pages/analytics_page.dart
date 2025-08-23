import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: AppColors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics, size: 64, color: AppColors.mediumBrown),
            const SizedBox(height: 16),
            Text(
              'Analytics Dashboard',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Text('Deze pagina wordt binnenkort geïmplementeerd'),
          ],
        ),
      ),
    );
  }
}

