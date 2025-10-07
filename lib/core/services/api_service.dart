import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import 'dart:typed_data';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  static const _storage = FlutterSecureStorage();

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(_AuthInterceptor());
    _dio.interceptors.add(_LoggingInterceptor());
    _dio.interceptors.add(_ErrorInterceptor());
  }

  void initialize({String? baseUrl}) {
    if (baseUrl != null && baseUrl != _dio.options.baseUrl) {
      _dio.options.baseUrl = baseUrl;
    }
  }

  Dio get client => _dio;

  // ---------------------------------------------------------------------------
  // AUTH
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String role,
    String? firstName,
    String? lastName,
    String? restaurantName,
    String? phone,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'role': role,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (restaurantName != null) 'restaurant_name': restaurantName,
      if (phone != null) 'phone': phone,
    });

    final data = response.data;

    return {
      'access_token': data['access_token'] ?? '',
      'refresh_token': data['refresh_token'] ?? '',
      'user': {
        'id': data['user']?['id'] ?? data['id'] ?? '',
        'role': data['user']?['role'] ?? data['role'] ?? role,
      }
    };
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _dio.get('/auth/me');
    return response.data;
  }

  Future<Map<String, dynamic>> refreshToken() async {
    final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
    final response = await _dio.post('/auth/refresh', data: {
      'refresh_token': refreshToken,
    });
    return response.data;
  }

  Future<void> logout() async {
    await _dio.post('/auth/logout');
    await _storage.deleteAll();
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await _dio.post('/auth/password/forgot', data: {
      'email': email,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> resetPassword(
      String token, String newPassword) async {
    final response = await _dio.post('/auth/password/reset', data: {
      'token': token,
      'new_password': newPassword,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> resendVerificationEmail(String email) async {
    final response = await _dio.post('/auth/email/resend', data: {
      'email': email,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> verifyEmail(String token) async {
    final response = await _dio.get('/auth/email/verify/$token');
    return response.data;
  }

  Future<Map<String, dynamic>> setup2FA() async {
    final response = await _dio.get('/auth/2fa/setup');
    return response.data;
  }

  Future<Map<String, dynamic>> enable2FA(String code) async {
    final response = await _dio.post('/auth/2fa/enable', data: {
      'code': code,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> disable2FA() async {
    final response = await _dio.post('/auth/2fa/disable');
    return response.data;
  }

  Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> profileData) async {
    final response = await _dio.put('/auth/profile', data: profileData);
    return response.data;
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _dio.put('/auth/profile/password', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
    return response.data;
  }

  // ---------------------------------------------------------------------------
  // USERS
  // ---------------------------------------------------------------------------

  Future<void> deleteAccount() async {
    await _dio.delete('/users/me');
  }

  Future<Map<String, dynamic>> submitFeedback(String content) async {
    final response = await _dio.post('/users/feedback', data: {
      'content': content,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> updateLanguage(String language) async {
    final response = await _dio.put('/users/language', data: {
      'language': language,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> listUsers({
    int page = 1,
    int perPage = 20,
    String? search,
  }) async {
    final response = await _dio.get('/users', queryParameters: {
      'page': page,
      'per_page': perPage,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getUserById(int userId) async {
    final response = await _dio.get('/users/$userId');
    return response.data;
  }

  Future<Map<String, dynamic>> updateUserById(
      int userId, Map<String, dynamic> body) async {
    final response = await _dio.put('/users/$userId', data: body);
    return response.data;
  }

  Future<void> deactivateUserById(int userId) async {
    await _dio.delete('/users/$userId');
  }

  Future<Map<String, dynamic>> activateUser(int userId) async {
    final response = await _dio.post('/users/$userId/activate');
    return response.data;
  }

  Future<Map<String, dynamic>> verifyUserEmailAdmin(int userId) async {
    final response = await _dio.post('/users/$userId/verify-email');
    return response.data;
  }

  Future<Map<String, dynamic>> getUserRecipes(int userId,
      {int page = 1, int perPage = 20}) async {
    final response = await _dio.get('/users/$userId/recipes', queryParameters: {
      'page': page,
      'per_page': perPage,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getUserStats() async {
    final response = await _dio.get('/users/stats');
    return response.data;
  }

  Future<Map<String, dynamic>> searchUsers(String query) async {
    final response = await _dio.get('/users/search', queryParameters: {
      'q': query,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> uploadProfileImage(String filePath) async {
    final fileName = filePath.split('/').last;
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final response = await _dio.post('/profile/image', data: formData);
    return response.data as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // BUSINESS PROFILES
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getBusinessProfile() async {
    final response = await _dio.get('/business');
    return response.data;
  }

  Future<Map<String, dynamic>> updateBusinessProfile(
      Map<String, dynamic> body) async {
    final response = await _dio.patch('/business', data: body);
    return response.data;
  }

  Future<Map<String, dynamic>> uploadCompanyLogo(String filePath) async {
    final fileName = filePath.split('/').last;
    final formData = FormData.fromMap({
      'logo': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final response = await _dio.post('/business/logo', data: formData);
    return response.data as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // RESTAURANTS
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getRestaurants({
    int page = 1,
    int perPage = 20,
    String? search,
    String? city,
  }) async {
    final response = await _dio.get('/restaurants/', queryParameters: {
      'page': page,
      'per_page': perPage,
      if (search != null) 'search': search,
      if (city != null) 'city': city,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getRestaurant(int id) async {
    final response = await _dio.get('/restaurants/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> searchRestaurants({
    required double lat,
    required double lng,
    double radius = 10.0,
    bool? openNow,
    bool? delivery,
    bool? takeaway,
    bool? wheelchair,
    String? priceRange,
    String? cuisine,
  }) async {
    final response = await _dio.get('/restaurants/search', queryParameters: {
      'lat': lat,
      'lng': lng,
      'radius': radius,
      if (openNow != null) 'open_now': openNow,
      if (delivery != null) 'delivery': delivery,
      if (takeaway != null) 'takeaway': takeaway,
      if (wheelchair != null) 'wheelchair': wheelchair,
      if (priceRange != null) 'price_range': priceRange,
      if (cuisine != null) 'cuisine': cuisine,
    });
    return response.data;
  }

  // 📌 Haal promoties op voor een specifiek restaurant
  Future<List<Map<String, dynamic>>> getRestaurantPromotions(
      int restaurantId) async {
    try {
      final response = await _dio.get('/restaurants/$restaurantId/promotions');

      if (response.statusCode == 200) {
        final data = response.data['promotions'] as List<dynamic>;
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        throw Exception('Failed to load promotions');
      }
    } catch (e) {
      print('❌ Error fetching promotions: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPromotions({
    int page = 1,
    int perPage = 20,
    int? restaurantId,
  }) async {
    final response =
        await _dio.get('/restaurants/promotions', queryParameters: {
      'page': page,
      'per_page': perPage,
      if (restaurantId != null) 'restaurant_id': restaurantId,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getMyRestaurants() async {
    final response = await _dio.get('/restaurants/my');
    return response.data;
  }

  Future<Map<String, dynamic>> createRestaurant(
      Map<String, dynamic> restaurantData) async {
    final response = await _dio.post('/restaurants/', data: restaurantData);
    return response.data;
  }

  Future<Map<String, dynamic>> updateRestaurant(
      int id, Map<String, dynamic> restaurantData) async {
    final response = await _dio.put('/restaurants/$id', data: restaurantData);
    return response.data;
  }

  Future<void> deleteRestaurant(int id) async {
    await _dio.delete('/restaurants/$id');
  }

  Future<Map<String, dynamic>> getNearbyRestaurants({
    required String city,
    int limit = 10,
  }) async {
    final response = await _dio.get('/restaurants/nearby', queryParameters: {
      'city': city,
      'limit': limit,
    });
    return response.data;
  }

  // ---------------------------------------------------------------------------
  // MENUS
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getMenus({
    int page = 1,
    int perPage = 20,
    int? restaurantId,
  }) async {
    final response = await _dio.get('/menus/', queryParameters: {
      'page': page,
      'per_page': perPage,
      if (restaurantId != null) 'restaurant_id': restaurantId,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getMenu(int id) async {
    final response = await _dio.get('/menus/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> getPublicMenu(String qrCode) async {
    final response = await _dio.get('/menus/public/$qrCode');
    return response.data;
  }

  Future<Map<String, dynamic>> createMenu({
    required int restaurantId,
    required String name,
    String status = "concept",
  }) async {
    final response = await _dio.post('/menus/', data: {
      "restaurant_id": restaurantId,
      "name": name,
      "status": status,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> updateMenu(
      int id, Map<String, dynamic> menuData) async {
    final response = await _dio.put('/menus/$id', data: menuData);
    return response.data;
  }

  Future<void> deleteMenu(int id) async {
    await _dio.delete('/menus/$id');
  }

  Future<Map<String, dynamic>> getMenuQR(int id) async {
    final response = await _dio.get('/menus/$id/qr');
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> addMenuItemToMenu(
      int menuId, Map<String, dynamic> itemData) async {
    final response = await _dio.post('/menus/$menuId/items', data: itemData);
    return response.data;
  }

  // ---------------------------------------------------------------------------
  // MENU ITEMS
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getMenuItem(int id) async {
    final response = await _dio.get('/menu-items/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> getMenuItems({
    int page = 1,
    int perPage = 20,
    int? menuId,
    int? restaurantId,
    String? search,
  }) async {
    final response = await _dio.get('/menu-items/', queryParameters: {
      'page': page,
      'per_page': perPage,
      if (menuId != null) 'menu_id': menuId,
      if (restaurantId != null) 'restaurant_id': restaurantId,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> createMenuItem(
      Map<String, dynamic> menuItemData) async {
    final response = await _dio.post('/menu-items/', data: menuItemData);
    return response.data;
  }

  Future<Map<String, dynamic>> updateMenuItem(
      int id, Map<String, dynamic> menuItemData) async {
    final response = await _dio.put('/menu-items/$id', data: menuItemData);
    return response.data;
  }

  Future<void> deleteMenuItem(int id) async {
    await _dio.delete('/menu-items/$id');
  }

  // ---------------------------------------------------------------------------
  // CATEGORIES
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getCategories({int? menuId}) async {
    final response = await _dio.get('/categories/', queryParameters: {
      if (menuId != null) 'menu_id': menuId,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getCategory(int id) async {
    final response = await _dio.get('/categories/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> createCategory(
      Map<String, dynamic> categoryData) async {
    final response = await _dio.post('/categories/', data: categoryData);
    return response.data;
  }

  Future<Map<String, dynamic>> updateCategory(
      int id, Map<String, dynamic> categoryData) async {
    final response = await _dio.put('/categories/$id', data: categoryData);
    return response.data;
  }

  Future<void> deleteCategory(int id) async {
    await _dio.delete('/categories/$id');
  }

  // ---------------------------------------------------------------------------
  // INGREDIENTS
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getIngredients({
    int page = 1,
    int perPage = 20,
    String? search,
    bool? verifiedOnly,
    bool? hasBarcode,
    String? allergen,
    String? excludeAllergen,
    double? minProtein,
    double? maxCalories,
  }) async {
    final response = await _dio.get('/ingredients/', queryParameters: {
      'page': page,
      'per_page': perPage,
      if (search != null) 'search': search,
      if (verifiedOnly != null) 'verified_only': verifiedOnly,
      if (hasBarcode != null) 'has_barcode': hasBarcode,
      if (allergen != null) 'allergen': allergen,
      if (excludeAllergen != null) 'exclude_allergen': excludeAllergen,
      if (minProtein != null) 'min_protein': minProtein,
      if (maxCalories != null) 'max_calories': maxCalories,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getIngredientSuggestions(String query,
      {int limit = 10, bool verifiedOnly = false}) async {
    final response = await _dio.get('/ingredients/suggest', queryParameters: {
      'q': query,
      'limit': limit,
      'verified_only': verifiedOnly,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> searchIngredients(String query,
      {int limit = 20, bool external = false}) async {
    final response = await _dio.get('/ingredients/search', queryParameters: {
      'q': query,
      'limit': limit,
      'external': external,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getIngredientByBarcode(String barcode) async {
    final response = await _dio.get('/ingredients/barcode/$barcode');
    return response.data;
  }

  Future<Map<String, dynamic>> getIngredient(int id) async {
    final response = await _dio.get('/ingredients/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> createIngredient(
      Map<String, dynamic> ingredientData) async {
    final response = await _dio.post('/ingredients/', data: ingredientData);
    return response.data;
  }

  Future<Map<String, dynamic>> updateIngredient(
      int id, Map<String, dynamic> ingredientData) async {
    final response = await _dio.put('/ingredients/$id', data: ingredientData);
    return response.data;
  }

  Future<void> deleteIngredient(int id) async {
    await _dio.delete('/ingredients/$id');
  }

  Future<Map<String, dynamic>> getAllergens() async {
    final response = await _dio.get('/ingredients/allergens');
    return response.data;
  }

  Future<Map<String, dynamic>> getIngredientStats() async {
    final response = await _dio.get('/ingredients/stats');
    return response.data;
  }

  Future<Map<String, dynamic>> calculateNutrition(
      int ingredientId, double amountG) async {
    final response =
        await _dio.post('/ingredients/nutrition/$ingredientId', data: {
      'amount_g': amountG,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> lookupIngredientByBarcode(String barcode) async {
    final response = await _dio.get(
      '/ingredients/lookup',
      queryParameters: {'barcode': barcode},
    );
    return response.data;
  }

  Future<void> duplicateIngredient(int id) async {
    await _dio.post('/ingredients/$id/duplicate', data: {});
  }

  Future<void> verifyIngredient(int id) async {
    await _dio.post('/ingredients/$id/verify', data: {});
  }

  Future<void> unverifyIngredient(int id) async {
    await _dio.post('/ingredients/$id/unverify', data: {});
  }

  Future<void> syncIngredients() async {
    await _dio.post('/ingredients/sync', data: {});
  }

  // ---------------------------------------------------------------------------
  // RECIPES
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getRecipes({
    int page = 1,
    int perPage = 20,
    String? search,
    int? restaurantId,
  }) async {
    final response = await _dio.get('/recipes/', queryParameters: {
      'page': page,
      'per_page': perPage,
      if (search != null) 'search': search,
      if (restaurantId != null) 'restaurant_id': restaurantId,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getRecipe(int id) async {
    final response = await _dio.get('/recipes/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> createRecipe(
      Map<String, dynamic> recipeData) async {
    final response = await _dio.post('/recipes/', data: recipeData);
    return response.data;
  }

  Future<Map<String, dynamic>> updateRecipe(
      int id, Map<String, dynamic> recipeData) async {
    final response = await _dio.put('/recipes/$id', data: recipeData);
    return response.data;
  }

  Future<void> deleteRecipe(int id) async {
    await _dio.delete('/recipes/$id');
  }

  Future<Map<String, dynamic>> getRecipeNutrition(int id,
      {double portionFactor = 1.0}) async {
    final response = await _dio.get('/recipes/$id/nutrition', queryParameters: {
      'portion_factor': portionFactor,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getRecipePortionSizes() async {
    final response = await _dio.get('/recipes/portion-sizes');
    return response.data;
  }

  Future<Map<String, dynamic>> createRecipePortionSize(
      Map<String, dynamic> body) async {
    final response = await _dio.post('/recipes/portion-sizes', data: body);
    return response.data;
  }

  // ---------------------------------------------------------------------------
  // ANALYTICS
  // ---------------------------------------------------------------------------

  Future<List<dynamic>> getAnalytics({
    String? metric,
    String period = 'week',
    int? restaurantId,
  }) async {
    final response = await _dio.get('/analytics', queryParameters: {
      if (metric != null) 'metric': metric,
      'period': period,
      if (restaurantId != null) 'restaurant_id': restaurantId,
    });
    return response.data;
  }

  Future<String> exportAnalyticsCSV({
    required String metric,
    String period = 'week',
    int? restaurantId,
  }) async {
    final response = await _dio.get('/analytics/export.csv', queryParameters: {
      'metric': metric,
      'period': period,
      if (restaurantId != null) 'restaurant_id': restaurantId,
    });
    return response.data;
  }

  Future<Uint8List> exportAnalyticsPDF({
    int? restaurantId,
    String period = 'week',
  }) async {
    final response = await _dio.get(
      '/analytics/export/pdf',
      queryParameters: {
        if (restaurantId != null) 'restaurant_id': restaurantId,
        'period': period,
      },
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data);
  }

  // ---------------------------------------------------------------------------
  // ACTIVITIES
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getUserActivity({
    String? activityType,
    int? restaurantId,
    int? menuItemId,
  }) async {
    final response = await _dio.get('/activities', queryParameters: {
      if (activityType != null) 'activity_type': activityType,
      if (restaurantId != null) 'restaurant_id': restaurantId,
      if (menuItemId != null) 'menu_item_id': menuItemId,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> logActivity({
    required String type,
    int? restaurantId,
    Map<String, dynamic>? metadata,
  }) async {
    final payload = {
      'type': type,
      if (restaurantId != null) 'restaurant_id': restaurantId,
      if (metadata != null) 'metadata': metadata,
    };
    final response = await _dio.post('/activities', data: payload);
    return response.data;
  }

  // ---------------------------------------------------------------------------
  // FAVORITES & COLLECTIONS
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getFavorites() async {
    final response = await _dio.get('/favorites');
    return response.data;
  }

  Future<Map<String, dynamic>> addFavorite({
    int? restaurantId,
    int? menuItemId,
    int? collectionId,
    String? notes,
  }) async {
    final response = await _dio.post('/favorites', data: {
      if (restaurantId != null) 'restaurant_id': restaurantId,
      if (menuItemId != null) 'menu_item_id': menuItemId,
      if (collectionId != null) 'collection_id': collectionId,
      if (notes != null) 'notes': notes,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> updateFavorite(
      int id, Map<String, dynamic> favoriteData) async {
    final response = await _dio.patch('/favorites/$id', data: favoriteData);
    return response.data;
  }

  Future<void> deleteFavorite(int id) async {
    await _dio.delete('/favorites/$id');
  }

  Future<Map<String, dynamic>> getCollections() async {
    final response = await _dio.get('/collections');
    return response.data;
  }

  Future<Map<String, dynamic>> getCollection(int id) async {
    final response = await _dio.get('/collections/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> createCollection(
      Map<String, dynamic> collectionData) async {
    final response = await _dio.post('/collections', data: collectionData);
    return response.data;
  }

  Future<Map<String, dynamic>> updateCollection(
      int id, Map<String, dynamic> collectionData) async {
    final response = await _dio.put('/collections/$id', data: collectionData);
    return response.data;
  }

  Future<void> deleteCollection(int id) async {
    await _dio.delete('/collections/$id');
  }

  Future<Map<String, dynamic>> getSharedCollectionByCode(
      String shareCode) async {
    final response = await _dio.get('/collections/$shareCode');
    return response.data;
  }

  Future<Map<String, dynamic>> shareCollection(
      int collectionId, Map<String, dynamic> body) async {
    final response =
        await _dio.post('/collections/$collectionId/share', data: body);
    return response.data;
  }

  Future<Map<String, dynamic>> acceptSharedCollection(int shareId) async {
    final response = await _dio.post('/collections/share/$shareId/accept');
    return response.data;
  }

  Future<Map<String, dynamic>> declineSharedCollection(int shareId) async {
    final response = await _dio.post('/collections/share/$shareId/decline');
    return response.data;
  }

  // ---------------------------------------------------------------------------
  // HEALTH + EATEN
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getHealthProfile() async {
    final response = await _dio.get('/health/user-health-profile');
    return response.data;
  }

  Future<Map<String, dynamic>> updateHealthProfile(
      Map<String, dynamic> profileData) async {
    final response =
        await _dio.put('/health/user-health-profile', data: profileData);
    return response.data;
  }

  Future<Map<String, dynamic>> getNutritionLogs() async {
    final response = await _dio.get('/health/nutrition-logs');
    return response.data;
  }

  Future<Map<String, dynamic>> addNutritionLog(
      Map<String, dynamic> logData) async {
    final response = await _dio.post('/health/nutrition-logs', data: logData);
    return response.data;
  }

  Future<void> deleteNutritionLog(int id) async {
    await _dio.delete('/health/nutrition-logs/$id');
  }

  Future<Map<String, dynamic>> addEaten({
    required int menuItemId,
    double portionSizeG = 100.0,
  }) async {
    final response = await _dio.post('/eaten', data: {
      'menu_item_id': menuItemId,
      'portion_size_g': portionSizeG,
    });
    return response.data;
  }

  Future<List<dynamic>> getEatenHistory() async {
    final response = await _dio.get('/eaten');
    return response.data;
  }

  // ---------------------------------------------------------------------------
  // MEAL RECOMMENDATIONS
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getMealRecommendations() async {
    final response = await _dio.get('/meal-recommendations');
    return response.data;
  }

  // ---------------------------------------------------------------------------
  // NOTIFICATIONS
  // ---------------------------------------------------------------------------

  Future<List<dynamic>> getNotifications({bool? unread}) async {
    final response = await _dio.get('/notifications', queryParameters: {
      if (unread != null) 'unread': unread,
    });

    if (response.data is List) {
      return List<Map<String, dynamic>>.from(response.data as List);
    } else {
      print('⚠️ Unexpected notifications response: ${response.data}');
      throw Exception(
          'Unexpected response format: ${response.data.runtimeType}');
    }
  }

  Future<Map<String, dynamic>> getNotification(int id) async {
    final response = await _dio.get('/notifications/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> markNotificationRead(int id) async {
    final response = await _dio.put('/notifications/$id/read');
    return response.data;
  }

  Future<Map<String, dynamic>> markAllNotificationsRead() async {
    final response = await _dio.put('/notifications/read-all');
    return response.data;
  }

  Future<void> clearAllNotifications() async {
    await _dio.delete('/notifications/clear-all');
  }

  Future<void> deleteNotification(int id) async {
    await _dio.delete('/notifications/$id');
  }

  Future<Map<String, dynamic>> getNotificationPreferences() async {
    final response = await _dio.get('/notifications/preferences');
    print('📩 [PREFS RAW] ${response.data.runtimeType} → ${response.data}');
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    } else {
      throw Exception(
        'Unexpected preferences format: ${response.data.runtimeType} → ${response.data}',
      );
    }
  }

  Future<Map<String, dynamic>> updateNotificationPreferences(
      Map<String, dynamic> preferences) async {
    final response =
        await _dio.put('/notifications/preferences', data: preferences);
    return response.data;
  }

  Future<Map<String, dynamic>> getNotificationTypes() async {
    final response = await _dio.get('/notifications/types');
    return response.data;
  }

  Future<Map<String, dynamic>> getNotificationChannels() async {
    final response = await _dio.get('/notifications/channels');
    return response.data;
  }

  Future<Map<String, dynamic>> getNotificationDeliveries(
      int notificationId) async {
    final response =
        await _dio.get('/notifications/$notificationId/deliveries');
    return response.data;
  }

  Future<Map<String, dynamic>> deliverNotification(int deliveryId) async {
    final response =
        await _dio.put('/notifications/deliveries/$deliveryId/deliver');
    return response.data;
  }

  Future<Map<String, dynamic>> failNotificationDelivery(int deliveryId) async {
    final response =
        await _dio.put('/notifications/deliveries/$deliveryId/fail');
    return response.data;
  }

  Future<Map<String, dynamic>> getNotificationTemplates() async {
    final response = await _dio.get('/notifications/templates');
    return response.data;
  }

  Future<Map<String, dynamic>> getNotificationTemplate(int templateId) async {
    final response = await _dio.get('/notifications/templates/$templateId');
    return response.data;
  }

  Future<Map<String, dynamic>> updateNotificationTemplate(
      int templateId, Map<String, dynamic> body) async {
    final response =
        await _dio.put('/notifications/templates/$templateId', data: body);
    return response.data;
  }

  // ---------------------------------------------------------------------------
  // INTEGRATIONS
  // ---------------------------------------------------------------------------

  Future<String> getMyFitnessPalAuthUrl() async {
    final response = await _dio.get('/integrations/myfitnesspal/authorize');
    return response.data['auth_url'];
  }

  Future<Map<String, dynamic>> getMyFitnessPalToken() async {
    final response = await _dio.get('/integrations/myfitnesspal/token');
    return response.data;
  }

  // ---------------------------------------------------------------------------
  // REVIEWS
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getReviews({
    int? restaurantId,
    int? menuItemId,
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _dio.get('/reviews', queryParameters: {
      if (restaurantId != null) 'restaurant_id': restaurantId,
      if (menuItemId != null) 'menu_item_id': menuItemId,
      'page': page,
      'per_page': perPage,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> createReview(
      Map<String, dynamic> reviewData) async {
    final response = await _dio.post('/reviews', data: reviewData);
    return response.data;
  }

  Future<Map<String, dynamic>> updateReview(
      int id, Map<String, dynamic> reviewData) async {
    final response = await _dio.put('/reviews/$id', data: reviewData);
    return response.data;
  }

  Future<void> deleteReview(int id) async {
    await _dio.delete('/reviews/$id');
  }

  Future<Map<String, dynamic>> replyToReview(
      int reviewId, String message) async {
    final response = await _dio.post('/reviews/$reviewId/reply', data: {
      'message': message,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> voteReviewHelpful(
      int reviewId, bool isHelpful) async {
    final response = await _dio.post('/reviews/$reviewId/helpful', data: {
      'is_helpful': isHelpful,
    });
    return response.data;
  }

  Future<void> hideReview(int reviewId) async {
    await _dio.post('/reviews/$reviewId/hide');
  }

  Future<Map<String, dynamic>> getPendingReviews({
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _dio.get('/moderation/reviews', queryParameters: {
      'page': page,
      'per_page': perPage,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> approveReview(int reviewId) async {
    final response = await _dio.post('/moderation/reviews/$reviewId/approve');
    return response.data;
  }

  Future<Map<String, dynamic>> rejectReview(int reviewId,
      {String? reason}) async {
    final response =
        await _dio.post('/moderation/reviews/$reviewId/reject', data: {
      if (reason != null) 'reason': reason,
    });
    return response.data;
  }

  // ---------------------------------------------------------------------------
  // TEAMS
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getTeamMembers() async {
    final res = await get('/teams/members');
    final members = ((res.data['members'] ?? []) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    return members;
  }

  Future<void> updateTeamMemberRole(int membershipId, String newRole) async {
    await put('/teams/members/$membershipId', data: {'role': newRole});
  }

  Future<void> suspendTeamMember(int membershipId) async {
    await put('/teams/members/$membershipId', data: {'is_active': false});
  }

  Future<void> activateTeamMember(int membershipId) async {
    await put('/teams/members/$membershipId', data: {'is_active': true});
  }

  Future<void> removeTeamMember(int membershipId) async {
    await delete('/teams/members/$membershipId');
  }

  Future<Map<String, dynamic>> getPendingInvitations() async {
    final res = await get('/teams/invitations?status=pending');
    return Map<String, dynamic>.from(res.data);
  }

  Future<void> inviteTeamMember(Map<String, dynamic> payload) async {
    await post('/teams/invitations', data: payload);
  }

  Future<void> resendInvitation(int invitationId) async {
    await post('/teams/invitations/$invitationId/resend');
  }

  Future<void> cancelInvitation(int invitationId) async {
    await delete('/teams/invitations/$invitationId');
  }

  // ---------------------------------------------------------------------------
  // SHARE
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> createShareLink({
    required String targetType,
    required int targetId,
  }) async {
    final response = await _dio.post('/share/$targetType/$targetId');
    return response.data;
  }

  Future<Map<String, dynamic>> getSharedResource(String code) async {
    final response = await _dio.get('/share/$code');
    return response.data;
  }

  // ---------------------------------------------------------------------------
  // GENERIC HELPERS
  // ---------------------------------------------------------------------------

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path) {
    return _dio.delete(path);
  }

  Future<Map<String, dynamic>> getSettings() async {
    final response = await _dio.get('/settings');
    return response.data;
  }

  Future<Map<String, dynamic>> updateSettings(
      Map<String, dynamic> settings) async {
    final response = await _dio.put('/settings', data: settings);
    return response.data;
  }

  Future<Map<String, dynamic>> resetSettings() async {
    final response = await _dio.post('/settings/reset');
    return response.data;
  }
}

// --------------------------- Interceptors ---------------------------

class _AuthInterceptor extends Interceptor {
  static const _storage = FlutterSecureStorage();

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    print('➡️ [AUTH] ${options.method} ${options.uri}');
    print('➡️ [HEADERS] ${options.headers}');
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      try {
        final refreshToken =
            await _storage.read(key: AppConstants.refreshTokenKey);
        if (refreshToken != null) {
          print('🔄 [AUTH] Refreshing token...');
          final refreshDio = Dio(BaseOptions(
            baseUrl: AppConstants.baseUrl,
            headers: {'Content-Type': 'application/json'},
          ));
          final response = await refreshDio.post(
            '/auth/refresh',
            data: {'refresh_token': refreshToken},
          );
          final newToken = response.data['access_token'];
          await _storage.write(
              key: AppConstants.accessTokenKey, value: newToken);
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          print('🔁 [AUTH] Retrying request with new token...');
          final cloneReq = await refreshDio.fetch(opts);
          handler.resolve(cloneReq);
          return;
        }
      } catch (e) {
        print('❌ [AUTH] Refresh token failed: $e');
        await _storage.deleteAll();
      }
    }
    handler.next(err);
  }
}

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('🌐 [REQ] ${options.method} ${options.uri}');
    if (options.data != null) {
      print('📤 [DATA] ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('✅ [RES] ${response.statusCode} ${response.requestOptions.uri}');
    print('📩 [BODY] ${response.data}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('❌ [ERR] ${err.response?.statusCode} ${err.requestOptions.uri}');
    print('💥 [MESSAGE] ${err.message}');
    handler.next(err);
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String message;
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        message = AppConstants.networkErrorMessage;
        break;
      case DioExceptionType.badResponse:
        switch (err.response?.statusCode) {
          case 400:
            message = err.response?.data['error'] ?? 'Invalid request';
            break;
          case 401:
            message = AppConstants.authErrorMessage;
            break;
          case 403:
            message = 'No access to this resource';
            break;
          case 404:
            message = 'Resource not found';
            break;
          case 500:
            message = AppConstants.serverErrorMessage;
            break;
          default:
            message = AppConstants.unknownErrorMessage;
        }
        break;
      default:
        message = AppConstants.networkErrorMessage;
    }
    print('⚠️ [ERROR HANDLER] $message');
    handler.next(err.copyWith(message: message));
  }
}
