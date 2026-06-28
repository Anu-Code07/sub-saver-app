class ServerException implements Exception {
  const ServerException([this.message = 'Server error']);

  final String message;
}

class CacheException implements Exception {
  const CacheException([this.message = 'Cache error']);

  final String message;
}

class NetworkException implements Exception {
  const NetworkException([this.message = 'No internet connection']);

  final String message;
}

class AuthException implements Exception {
  const AuthException([this.message = 'Authentication failed']);

  final String message;
}

class ValidationException implements Exception {
  const ValidationException(this.message);

  final String message;
}
