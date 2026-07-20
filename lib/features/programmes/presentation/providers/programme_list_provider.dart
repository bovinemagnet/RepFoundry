import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../domain/models/programme.dart';

/// All programmes, live from the repository. Shared by the mobile list screen
/// and the desktop master-detail view.
final programmeListProvider =
    StreamProvider.autoDispose<List<Programme>>((ref) {
  return ref.watch(programmeRepositoryProvider).watchAllProgrammes();
});
