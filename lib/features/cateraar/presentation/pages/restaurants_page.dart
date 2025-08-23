import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class RestaurantsPage extends StatelessWidget {
  const RestaurantsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurants'),
        backgroundColor: AppColors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.business, size: 64, color: AppColors.mediumBrown),
            const SizedBox(height: 16),
            Text(
              'Restaurant Beheer',
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

