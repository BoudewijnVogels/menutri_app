import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  static const _storage = FlutterSecureStorage();

  ApiService._internal() {
    // Dio direct één keer aanmaken
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Interceptors slechts één keer toevoegen
    _dio.interceptors.add(_AuthInterceptor());
    _dio.interceptors.add(_LoggingInterceptor());
    _dio.interceptors.add(_ErrorInterceptor());
  }

  // initialize kan nu optioneel nog extra config doen,
  // maar probeert _dio niet meer opnieuw te overschrijven
  void initialize({String? baseUrl}) {
    if (baseUrl != null && baseUrl != _dio.options.baseUrl) {
      _dio.options.baseUrl = baseUrl;
    }
  }

  Dio get client => _dio;

  // Auth endpoints
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
    String? voornaam,
    String? achternaam,
    String? restaurantNaam,
    String? telefoon,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'role': role,
      if (voornaam != null) 'voornaam': voornaam,
      if (achternaam != null) 'achternaam': achternaam,
      if (restaurantNaam != null) 'restaurant_naam': restaurantNaam,
      if (telefoon != null) 'telefoon': telefoon,
    });
    return response.data;
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

  // Restaurant endpoints
  Future<Map<String, dynamic>> getRestaurants({
    int page = 1,
    int perPage = 20,
    String? search,
    String? stad,
  }) async {
    final response = await _dio.get('/restaurants/', queryParameters: {
      'page': page,
      'per_page': perPage,
      if (search != null) 'search': search,
      if (stad != null) 'stad': stad,
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

  // Menu endpoints
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

  Future<Map<String, dynamic>> createMenu(Map<String, dynamic> menuData) async {
    final response = await _dio.post('/menus/', data: menuData);
    return response.data;
  }

  Future<Map<String, dynamic>> updateMenu(int id, Map<String, dynamic> menuData) async {
    final response = await _dio.put('/menus/$id', data: menuData);
    return response.data;
  }

  Future<void> deleteMenu(int id) async {
    await _dio.delete('/menus/$id');
  }

  Future<Map<String, dynamic>> getMenuQR(int id) async {
    final response = await _dio.get('/menus/$id/qr');
    return response.data;
  }

  // Health Profile endpoints
  Future<Map<String, dynamic>> getHealthProfile() async {
    final response = await _dio.get('/health/user-health-profile');
    return response.data;
  }

  Future<Map<String, dynamic>> updateHealthProfile(Map<String, dynamic> profileData) async {
    final response = await _dio.put('/health/user-health-profile', data: profileData);
    return response.data;
  }

  // Nutrition Log endpoints
  Future<Map<String, dynamic>> getNutritionLogs() async {
    final response = await _dio.get('/health/nutrition-logs');
    return response.data;
  }

  Future<Map<String, dynamic>> addNutritionLog(Map<String, dynamic> logData) async {
    final response = await _dio.post('/health/nutrition-logs', data: logData);
    return response.data;
  }

  Future<void> deleteNutritionLog(int id) async {
    await _dio.delete('/health/nutrition-logs/$id');
  }

  // Favorites endpoints
  Future<Map<String, dynamic>> getFavorites() async {
    final response = await _dio.get('/favorites');
    return response.data;
  }

  Future<Map<String, dynamic>> addFavorite(Map<String, dynamic> favoriteData) async {
    final response = await _dio.post('/favorites', data: favoriteData);
    return response.data;
  }

  Future<Map<String, dynamic>> updateFavorite(int id, Map<String, dynamic> favoriteData) async {
    final response = await _dio.patch('/favorites/$id', data: favoriteData);
    return response.data;
  }

  Future<void> deleteFavorite(int id) async {
    await _dio.delete('/favorites/$id');
  }

  // Collections endpoints
  Future<Map<String, dynamic>> getCollections() async {
    final response = await _dio.get('/collections');
    return response.data;
  }

  Future<Map<String, dynamic>> createCollection(Map<String, dynamic> collectionData) async {
    final response = await _dio.post('/collections', data: collectionData);
    return response.data;
  }

  Future<Map<String, dynamic>> updateCollection(int id, Map<String, dynamic> collectionData) async {
    final response = await _dio.put('/collections/$id', data: collectionData);
    return response.data;
  }

  Future<void> deleteCollection(int id) async {
    await _dio.delete('/collections/$id');
  }

  // Activities endpoints
  Future<Map<String, dynamic>> getActivities({
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

  Future<Map<String, dynamic>> logActivity(Map<String, dynamic> activityData) async {
    final response = await _dio.post('/activities', data: activityData);
    return response.data;
  }

  // Notifications endpoints
  Future<Map<String, dynamic>> getNotifications({bool? unread}) async {
    final response = await _dio.get('/notifications', queryParameters: {
      if (unread != null) 'unread': unread,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> markNotificationRead(int id) async {
    final response = await _dio.put('/notifications/$id/read');
    return response.data;
  }

  Future<void> deleteNotification(int id) async {
    await _dio.delete('/notifications/$id');
  }

  Future<Map<String, dynamic>> getNotificationPreferences() async {
    final response = await _dio.get('/notifications/preferences');
    return response.data;
  }

  Future<Map<String, dynamic>> updateNotificationPreferences(Map<String, dynamic> preferences) async {
    final response = await _dio.put('/notifications/preferences', data: preferences);
    return response.data;
  }

  // Eaten endpoints
  Future<Map<String, dynamic>> addEaten(Map<String, dynamic> eatenData) async {
    final response = await _dio.post('/eaten', data: eatenData);
    return response.data;
  }

  Future<Map<String, dynamic>> getEatenHistory() async {
    final response = await _dio.get('/eaten');
    return response.data;
  }

  // Meal Recommendations endpoints
  Future<Map<String, dynamic>> getMealRecommendations() async {
    final response = await _dio.get('/meal-recommendations');
    return response.data;
  }

  // CATERAAR ENDPOINTS

  // My Restaurants (Cateraar)
  Future<Map<String, dynamic>> getMyRestaurants() async {
    final response = await _dio.get('/restaurants/my');
    return response.data;
  }

  Future<Map<String, dynamic>> createRestaurant(Map<String, dynamic> restaurantData) async {
    final response = await _dio.post('/restaurants/', data: restaurantData);
    return response.data;
  }

  Future<Map<String, dynamic>> updateRestaurant(int id, Map<String, dynamic> restaurantData) async {
    final response = await _dio.put('/restaurants/$id', data: restaurantData);
    return response.data;
  }

  Future<void> deleteRestaurant(int id) async {
    await _dio.delete('/restaurants/$id');
  }

  // Recipes endpoints
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

  Future<Map<String, dynamic>> createRecipe(Map<String, dynamic> recipeData) async {
    final response = await _dio.post('/recipes/', data: recipeData);
    return response.data;
  }

  Future<Map<String, dynamic>> updateRecipe(int id, Map<String, dynamic> recipeData) async {
    final response = await _dio.put('/recipes/$id', data: recipeData);
    return response.data;
  }

  Future<void> deleteRecipe(int id) async {
    await _dio.delete('/recipes/$id');
  }

  Future<Map<String, dynamic>> getRecipeNutrition(int id, {double portionFactor = 1.0}) async {
    final response = await _dio.get('/recipes/$id/nutrition', queryParameters: {
      'portion_factor': portionFactor,
    });
    return response.data;
  }

  // Ingredients endpoints
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

  Future<Map<String, dynamic>> getIngredientSuggestions(String query, {int limit = 10, bool verifiedOnly = false}) async {
    final response = await _dio.get('/ingredients/suggest', queryParameters: {
      'q': query,
      'limit': limit,
      'verified_only': verifiedOnly,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> searchIngredients(String query, {int limit = 20, bool external = false}) async {
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

  Future<Map<String, dynamic>> createIngredient(Map<String, dynamic> ingredientData) async {
    final response = await _dio.post('/ingredients/', data: ingredientData);
    return response.data;
  }

  Future<Map<String, dynamic>> updateIngredient(int id, Map<String, dynamic> ingredientData) async {
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

  Future<Map<String, dynamic>> calculateNutrition(int ingredientId, double amountG) async {
    final response = await _dio.post('/ingredients/nutrition/$ingredientId', data: {
      'amount_g': amountG,
    });
    return response.data;
  }

  // Analytics endpoints
  Future<Map<String, dynamic>> getAnalytics({
    required String metric,
    String period = 'week',
    int? restaurantId,
  }) async {
    final response = await _dio.get('/analytics', queryParameters: {
      'metric': metric,
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

  // Categories endpoints
  Future<Map<String, dynamic>> getCategories({int? menuId}) async {
    final response = await _dio.get('/categories', queryParameters: {
      if (menuId != null) 'menu_id': menuId,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getCategory(int id) async {
    final response = await _dio.get('/categories/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> categoryData) async {
    final response = await _dio.post('/categories', data: categoryData);
    return response.data;
  }

  Future<Map<String, dynamic>> updateCategory(int id, Map<String, dynamic> categoryData) async {
    final response = await _dio.put('/categories/$id', data: categoryData);
    return response.data;
  }

  Future<void> deleteCategory(int id) async {
    await _dio.delete('/categories/$id');
  }

  // Menu Items endpoints
  Future<Map<String, dynamic>> getMenuItem(int id) async {
    final response = await _dio.get('/menu-items/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> createMenuItem(Map<String, dynamic> menuItemData) async {
    final response = await _dio.post('/menu-items', data: menuItemData);
    return response.data;
  }

  Future<Map<String, dynamic>> updateMenuItem(int id, Map<String, dynamic> menuItemData) async {
    final response = await _dio.put('/menu-items/$id', data: menuItemData);
    return response.data;
  }

  Future<void> deleteMenuItem(int id) async {
    await _dio.delete('/menu-items/$id');
  }

  Future<Map<String, dynamic>> addMenuItemToMenu(int menuId, Map<String, dynamic> itemData) async {
    final response = await _dio.post('/menus/$menuId/items', data: itemData);
    return response.data;
  }

  // Teams endpoints
  Future<Map<String, dynamic>> getRestaurantTeam(int restaurantId) async {
    final response = await _dio.get('/restaurants/$restaurantId/team');
    return response.data;
  }

  Future<Map<String, dynamic>> updateRestaurantTeam(int restaurantId, Map<String, dynamic> teamData) async {
    final response = await _dio.put('/restaurants/$restaurantId/team', data: teamData);
    return response.data;
  }

  Future<Map<String, dynamic>> getTeamMembers(int restaurantId) async {
    final response = await _dio.get('/restaurants/$restaurantId/teams');
    return response.data;
  }

  Future<Map<String, dynamic>> addTeamMember(int restaurantId, Map<String, dynamic> memberData) async {
    final response = await _dio.post('/restaurants/$restaurantId/teams', data: memberData);
    return response.data;
  }

  Future<Map<String, dynamic>> updateTeamMember(int restaurantId, int membershipId, Map<String, dynamic> memberData) async {
    final response = await _dio.put('/restaurants/$restaurantId/teams/$membershipId', data: memberData);
    return response.data;
  }

  Future<void> removeTeamMember(int restaurantId, int membershipId) async {
    await _dio.delete('/restaurants/$restaurantId/teams/$membershipId');
  }

  // Reviews endpoints
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

  Future<Map<String, dynamic>> createReview(Map<String, dynamic> reviewData) async {
    final response = await _dio.post('/reviews', data: reviewData);
    return response.data;
  }

  Future<Map<String, dynamic>> updateReview(int id, Map<String, dynamic> reviewData) async {
    final response = await _dio.put('/reviews/$id', data: reviewData);
    return response.data;
  }

  Future<void> deleteReview(int id) async {
    await _dio.delete('/reviews/$id');
  }

  Future<Map<String, dynamic>> replyToReview(int reviewId, String message) async {
    final response = await _dio.post('/reviews/$reviewId/reply', data: {
      'message': message,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> voteReviewHelpful(int reviewId, bool isHelpful) async {
    final response = await _dio.post('/reviews/$reviewId/helpful', data: {
      'is_helpful': isHelpful,
    });
    return response.data;
  }

  // Share endpoints
  Future<Map<String, dynamic>> createShareLink(String targetType, int targetId) async {
    final response = await _dio.post('/share/$targetType/$targetId');
    return response.data;
  }

  // User management endpoints
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
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

  // External integrations
  Future<String> getMyFitnessPalAuthUrl() async {
    final response = await _dio.get('/integrations/myfitnesspal/authorize');
    return response.data['auth_url'];
  }

  Future<Map<String, dynamic>> getMyFitnessPalToken() async {
    final response = await _dio.get('/integrations/myfitnesspal/token');
    return response.data;
  }

  // Favorites endpoints
  Future<List<dynamic>> getFavorites() async {
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

  Future<void> removeFavorite(int favoriteId) async {
    await _dio.delete('/favorites/$favoriteId');
  }

  // Health profile endpoints
  Future<Map<String, dynamic>?> getHealthProfile() async {
    final response = await _dio.get('/user-health-profile');
    return response.data['health_profile'];
  }

  Future<Map<String, dynamic>> updateHealthProfile(
      Map<String, dynamic> data) async {
    final response = await _dio.put('/user-health-profile', data: data);
    return response.data;
  }

  // Nutrition log endpoints
  Future<List<dynamic>> getNutritionLogs() async {
    final response = await _dio.get('/nutrition-logs');
    return response.data['logs'];
  }

  Future<Map<String, dynamic>> addNutritionLog(
      Map<String, dynamic> data) async {
    final response = await _dio.post('/nutrition-logs', data: data);
    return response.data;
  }

  Future<void> deleteNutritionLog(int logId) async {
    await _dio.delete('/nutrition-logs/$logId');
  }

  // Eaten endpoints
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

  // Analytics endpoints (for cateraars)
  Future<List<dynamic>> getAnalytics({
    required String metric,
    String period = 'week',
    int? restaurantId,
  }) async {
    final response = await _dio.get('/analytics', queryParameters: {
      'metric': metric,
      'period': period,
      if (restaurantId != null) 'restaurant_id': restaurantId,
    });
    return response.data;
  }

  // Notifications endpoints
  Future<List<dynamic>> getNotifications({bool unreadOnly = false}) async {
    final response = await _dio.get('/notifications', queryParameters: {
      if (unreadOnly) 'unread': true,
    });
    return response.data;
  }

  Future<void> markNotificationRead(int notificationId) async {
    await _dio.put('/notifications/$notificationId/read');
  }

  // Share endpoints
  Future<Map<String, dynamic>> createShareLink({
    required String targetType,
    required int targetId,
  }) async {
    final response = await _dio.post('/share/$targetType/$targetId');
    return response.data;
  }

  // Generic GET request
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  // Generic POST request
  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  // Generic PUT request
  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  // Generic DELETE request
  Future<Response> delete(String path) {
    return _dio.delete(path);
  }
}

// Auth interceptor to add JWT token to requests
class _AuthInterceptor extends Interceptor {
  static const _storage = FlutterSecureStorage();

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Try to refresh token
      try {
        final refreshToken =
            await _storage.read(key: AppConstants.refreshTokenKey);
        if (refreshToken != null) {
          final response = await Dio().post(
            '${AppConstants.baseUrl}/auth/refresh',
            data: {'refresh_token': refreshToken},
          );

          final newToken = response.data['access_token'];
          await _storage.write(
              key: AppConstants.accessTokenKey, value: newToken);

          // Retry the original request
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          final cloneReq = await Dio().fetch(opts);
          handler.resolve(cloneReq);
          return;
        }
      } catch (e) {
        // Refresh failed, clear tokens and redirect to login
        await _storage.deleteAll();
      }
    }
    handler.next(err);
  }
}

// Logging interceptor for debugging
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('🌐 ${options.method} ${options.uri}');
    if (options.data != null) {
      print('📤 ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('✅ ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('❌ ${err.response?.statusCode} ${err.requestOptions.uri}');
    print('Error: ${err.message}');
    handler.next(err);
  }
}

// Error interceptor for handling common errors
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
            message = err.response?.data['error'] ?? 'Ongeldige aanvraag';
            break;
          case 401:
            message = AppConstants.authErrorMessage;
            break;
          case 403:
            message = 'Geen toegang tot deze resource';
            break;
          case 404:
            message = 'Resource niet gevonden';
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

    err = err.copyWith(message: message);
    handler.next(err);
  }
}
