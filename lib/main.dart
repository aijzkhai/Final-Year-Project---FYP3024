// main.dart with fixed web support
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'providers/task_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'services/storage_service.dart';
import 'services/auth_service.dart';
import 'services/database_helper.dart';
import 'services/web_storage.dart';
import 'utils/app_info.dart';
import 'dart:io';

void main() async {
  // Initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database based on platform
  if (kIsWeb) {
    print("Running on web platform - initializing web storage");
    await WebStorage.initialize();
  } else {
    if (Platform.isAndroid || Platform.isIOS) {
      // Initialize FFI SQLite for mobile platforms
      print(
          "Initializing SQLite for ${Platform.isAndroid ? 'Android' : 'iOS'}");
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;

      // Initialize database
      final dbHelper = DatabaseHelper();
      await dbHelper.initializeDatabase();

      // Ensure database tables are created properly
      await dbHelper.ensureDatabaseIsReady();

      // Repair authentication tables if needed
      await dbHelper.repairAuthentication();

      // Initialize AuthService to ensure auth tables are ready
      final authService = AuthService();
      await authService.ensureAuthTablesExist();
    }
  }

  runApp(const MyInitApp());
}

class MyInitApp extends StatefulWidget {
  const MyInitApp({Key? key}) : super(key: key);

  @override
  State<MyInitApp> createState() => _MyInitAppState();
}

class _MyInitAppState extends State<MyInitApp> {
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      if (!kIsWeb) {
        // Reset database to ensure it's in a clean state
        print("Resetting database...");
        await DatabaseHelper().resetDatabase();

        // Run migrations (native only)
        try {
          print("Running migrations...");
          await AuthService().migrateUsersToSQLite();
          await StorageService().migrateDataToSQLite();
          print("Migrations complete");
        } catch (e) {
          print("Migration error: $e");
          // Continue even if migrations fail
        }
      } else {
        print("Running on web platform - no SQLite initialization needed");
      }

      // Set loading to false when done
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Initialization error: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text("Initializing application..."),
              ],
            ),
          ),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Error initializing app:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  _error,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _initializeApp,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const MyApp();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: AppInfo.appName,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
