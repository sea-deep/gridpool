import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central API configuration
class ApiConfig {
  ApiConfig._();
  
  /// Base URL for the backend API
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://gridpool.up.railway.app/api';
}
