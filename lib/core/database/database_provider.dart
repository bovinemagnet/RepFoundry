import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// Provides the singleton [AppDatabase] instance.
///
/// Override this in [ProviderScope] to inject the database created in `main()`.
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
    'databaseProvider must be overridden with a real AppDatabase instance.',
  );
});
