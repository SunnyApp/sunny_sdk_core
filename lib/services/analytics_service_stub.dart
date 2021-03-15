import 'package:sunny_dart/sunny_get.dart';

/// Service that acts as a clearing house for analytics providers
abstract class IAnalyticsService {
  void logEvent(dynamic name, [Map<String, dynamic>? parameters]);
}

IAnalyticsService get analyticsService => sunny.get();
