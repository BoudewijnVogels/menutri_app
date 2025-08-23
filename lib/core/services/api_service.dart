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
