/// Analytics events for the heart rate feature.
enum HrAnalyticsEvent {
  onboardingCompleted,
  healthFieldCompleted,
  cautionModeActivated,
  zoneMethodSelected,
  warningDisplayed,
  customCapUsed,
  timeInZoneSummaryViewed,
}

/// Abstract reporter — swap implementations for production analytics.
abstract class HrAnalyticsReporter {
  void trackEvent(HrAnalyticsEvent event, [Map<String, Object>? properties]);
}
