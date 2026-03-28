// Database implementation placeholder
// This will be implemented with Drift in the next phase
// For now, this is a stub to allow the project to compile

class AppDatabase {
  // TODO: Implement Drift database
  // Run: flutter pub run build_runner build
  
  static AppDatabase? _instance;
  
  static AppDatabase get instance {
    _instance ??= AppDatabase._();
    return _instance!;
  }
  
  AppDatabase._();
}
