import 'dart:developer' as dev;

import '../domain/analytics_events.dart';

/// No-op analytics reporter for MVP — logs to debug console only.
class NoopAnalyticsReporter implements HrAnalyticsReporter {
  @override
  void trackEvent(HrAnalyticsEvent event, [Map<String, Object>? properties]) {
    dev.log('HR Analytics: ${event.name}', name: 'HeartRate');
  }
}
