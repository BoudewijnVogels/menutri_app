import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class RestaurantDetailPage extends StatelessWidget {
  final int restaurantId;

  const RestaurantDetailPage({
    super.key,
    required this.restaurantId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Details'),
        backgroundColor: AppColors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant, size: 64, color: AppColors.mediumBrown),
            const SizedBox(height: 16),
            Text(
              'Restaurant Details',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Restaurant ID: $restaurantId',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.grey,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Deze pagina wordt binnenkort geïmplementeerd'),
          ],
        ),
      ),
    );
  }
}

