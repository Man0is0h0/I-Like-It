import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/auth/user_session_manager.dart';
import 'core/theme/theme_manager.dart';
import 'features/onboarding/initial_setup_screen.dart';
import 'theme/app_theme.dart';
import 'features/folders/folder_screen.dart';
import 'features/share/share_save_screen.dart';


import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/sync/remote_datasource.dart';
import 'core/sync/sync_manager.dart';
import 'core/services/folder_classification_service.dart';

import 'config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Configuration
  try {
    await AppConfig.instance.initialize();
  } catch (e) {
    print("Configuration Error: $e");
    // In production, you might want to show a friendly error screen here
  }
  
  // Initialize User Session FIRST
  await UserSessionManager.initialize();
  // Initialize Theme Manager
  await ThemeManager.instance.initialize();
  
  final isBackedUp = await UserSessionManager.isBackedUp();

  if (AppConfig.instance.supabaseUrl.isNotEmpty && AppConfig.instance.supabaseAnonKey.isNotEmpty) {
      await Supabase.initialize(
        url: AppConfig.instance.supabaseUrl,
        anonKey: AppConfig.instance.supabaseAnonKey,
      );
      
      final remoteDataSource = RemoteDataSource(Supabase.instance.client);
      // Initialize Sync Manager AFTER User Session is ready
      SyncManager.instance.initialize(remoteDataSource);
  }
  
  // Initialize AI
  FolderClassificationService.instance.initialize(); // New Robust Service
  
  runApp(ILikeItApp(isBackedUp: isBackedUp));
}

class ILikeItApp extends StatefulWidget {
  final bool isBackedUp;
  const ILikeItApp({super.key, required this.isBackedUp});

  @override
  State<ILikeItApp> createState() => _ILikeItAppState();
}

class _ILikeItAppState extends State<ILikeItApp> {
  static const _channel = MethodChannel('shared_link');
  String? _sharedLink;

  @override
  void initState() {
    super.initState();

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'sharedText') {
        setState(() {
          _sharedLink = call.arguments as String?;
        });
      } else if (call.method == 'clearSharedLink') {
        setState(() {
          _sharedLink = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.instance.themeModeNotifier,
      builder: (context, themeMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          themeAnimationDuration: Duration.zero, // Instant transition as requested
          themeAnimationCurve: Curves.linear,
          home: _sharedLink != null
              ? ShareSaveScreen(
                  sharedLink: _sharedLink!,
                  onLinkSaved: _clearSharedLink,
                )
              : (widget.isBackedUp
                  ? const FolderScreen()
                  : const InitialSetupScreen()),
        );
      },
    );
  }

  void _clearSharedLink() {
    setState(() {
      _sharedLink = null;
    });
  }
}