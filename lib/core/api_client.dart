import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_exceptions.dart';
import 'config.dart';

Dio buildDio({String? Function()? tokenProvider}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl.endsWith('/') ? apiBaseUrl : '$apiBaseUrl/',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 10),
      headers: const {'Content-Type': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokenProvider?.call();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (kDebugMode) {
          debugPrint('[DIO] ${options.method} ${options.uri}');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          debugPrint(
              '[DIO] ${response.statusCode} ${response.requestOptions.uri}');
        }
        final status = response.statusCode ?? 0;
        if (status >= 400) {
          handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              error: mapResponseError(response),
              type: DioExceptionType.badResponse,
            ),
          );
          return;
        }
        handler.next(response);
      },
      onError: (error, handler) {
        if (kDebugMode) debugPrint('[DIO] ERROR ${error.message}');
        handler.next(error);
      },
    ),
  );
  return dio;
}

ApiException mapResponseError(Response response) {
  final status = response.statusCode ?? 0;
  final data = response.data;
  final message = data is Map && data['message'] != null
      ? data['message'].toString()
      : 'Ошибка HTTP $status';
  switch (status) {
    case 400:
      return ApiException(message);
    case 401:
      return UnauthorizedException(message);
    case 403:
      return ForbiddenException(message);
    case 404:
      return NotFoundException(message);
    case 409:
      return ConflictException(message);
    case 422:
      final raw = data is Map && data['errors'] is Map
          ? data['errors'] as Map
          : const {};
      return ValidationException(
        message,
        raw.map((key, value) => MapEntry(key.toString(), value.toString())),
      );
    default:
      return ServerException(message);
  }
}

Future<T> apiGuard<T>(Future<T> Function() action, {int retries = 0}) async {
  var attempt = 0;
  while (true) {
    try {
      return await action();
    } on DioException catch (e) {
      final mapped = e.error is ApiException
          ? e.error as ApiException
          : e.response != null
              ? mapResponseError(e.response!)
              : null;
      final retryable = e.response == null &&
          (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout);
      if (retryable && attempt < retries) {
        attempt++;
        await Future<void>.delayed(Duration(milliseconds: 300 * attempt));
        continue;
      }
      if (mapped != null) throw mapped;
      throw NetworkException(
          'Сетевая ошибка: ${e.message ?? 'соединение недоступно'}');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw NetworkException('Ошибка сети: $e');
    }
  }
}
