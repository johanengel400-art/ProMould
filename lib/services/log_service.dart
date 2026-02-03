// lib/services/log_service.dart
// Centralized logging service for ProMould

import 'package:logger/logger.dart';

/// Centralized logging service to replace print statements.
/// Provides structured logging with different levels and better formatting.
class LogService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: Level.debug,
  );

  static final Logger _productionLogger = Logger(
    printer: SimplePrinter(colors: false),
    level: Level.info,
  );

  static bool _isProduction = false;

  /// Set production mode (disables debug logs, uses simple printer)
  static void setProductionMode(bool isProduction) {
    _isProduction = isProduction;
  }

  static Logger get _activeLogger =>
      _isProduction ? _productionLogger : _logger;

  /// Log debug information (development only)
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _activeLogger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log general information
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _activeLogger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warnings
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _activeLogger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log errors
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _activeLogger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log fatal errors
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _activeLogger.f(message, error: error, stackTrace: stackTrace);
  }

  /// Log service-specific messages with context
  static void service(String serviceName, String message,
      {dynamic error, StackTrace? stackTrace}) {
    _activeLogger.i('[$serviceName] $message',
        error: error, stackTrace: stackTrace);
  }

  /// Log sync operations
  static void sync(String message, {dynamic error}) {
    if (error != null) {
      _activeLogger.e('[Sync] $message', error: error);
    } else {
      _activeLogger.i('[Sync] $message');
    }
  }

  /// Log authentication events
  static void auth(String message, {dynamic error}) {
    if (error != null) {
      _activeLogger.e('[Auth] $message', error: error);
    } else {
      _activeLogger.i('[Auth] $message');
    }
  }

  /// Log database operations
  static void database(String message, {dynamic error}) {
    if (error != null) {
      _activeLogger.e('[Database] $message', error: error);
    } else {
      _activeLogger.d('[Database] $message');
    }
  }

  /// Log UI events
  static void ui(String message) {
    _activeLogger.d('[UI] $message');
  }

  /// Log performance metrics
  static void performance(String operation, Duration duration) {
    _activeLogger
        .i('[Performance] $operation took ${duration.inMilliseconds}ms');
  }

  /// Log audit events
  static void audit(String message, {dynamic error}) {
    if (error != null) {
      _activeLogger.w('[Audit] $message', error: error);
    } else {
      _activeLogger.i('[Audit] $message');
    }
  }
}
