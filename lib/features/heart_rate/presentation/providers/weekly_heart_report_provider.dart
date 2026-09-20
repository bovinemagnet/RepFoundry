import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../../clients/presentation/providers/active_client_provider.dart';
import '../../application/weekly_heart_report.dart';
import 'zone_configuration_provider.dart';

/// The active client's last seven days of heart-rate activity.
final weeklyHeartReportProvider =
    FutureProvider.autoDispose<WeeklyHeartReport>((ref) async {
  final clientId = (await ref.watch(activeClientProvider.future)).id;
  final zones = ref.watch(zoneConfigurationProvider);
  return ref.watch(buildWeeklyHeartReportUseCaseProvider).execute(
        clientId: clientId,
        now: DateTime.now(),
        zones: zones,
      );
});
