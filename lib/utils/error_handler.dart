// lib/utils/error_handler.dart

import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ErrorHandler {
  static Exception handleError(dynamic error) {
    if (error is SocketException) {
      return Exception('Network error. Please check your internet connection.');
    } else if (error is FormatException) {
      return Exception('Invalid response format from server.');
    } else if (error is Exception) {
      return error;
    } else {
      return Exception('An unexpected error occurred.');
    }
  }

  static Future<Exception> handleHttpError(http.Response response) async {
    String message = 'Server error occurred.';

    try {
      final body = json.decode(response.body);
      if (body['message'] != null) {
        message = body['message'];
      }
    } catch (e) {
      // If we can't parse the error message, use status code
      message = _getErrorMessageForStatus(response.statusCode);
    }

    switch (response.statusCode) {
      case 400:
        return Exception('Bad request: $message');
      case 401:
        return Exception('Unauthorized. Please login again.');
      case 403:
        return Exception('Forbidden. You don\'t have permission.');
      case 404:
        return Exception('Resource not found.');
      case 409:
        return Exception('Conflict: $message');
      case 422:
        return Exception('Validation error: $message');
      case 429:
        return Exception('Too many requests. Please try again later.');
      case 500:
        return Exception('Internal server error. Please try again later.');
      case 502:
        return Exception('Bad gateway. Please try again later.');
      case 503:
        return Exception('Service unavailable. Please try again later.');
      default:
        return Exception('Error ${response.statusCode}: $message');
    }
  }

  static String _getErrorMessageForStatus(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not found';
      case 409:
        return 'Conflict';
      case 422:
        return 'Validation error';
      case 429:
        return 'Too many requests';
      case 500:
        return 'Internal server error';
      case 502:
        return 'Bad gateway';
      case 503:
        return 'Service unavailable';
      default:
        return 'HTTP error $statusCode';
    }
  }
}
