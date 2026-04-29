import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/app/cyclecare_app.dart';

void main() {
  runApp(
    const ProviderScope(
      child: CycleCareApp(),
    ),
  );
}
