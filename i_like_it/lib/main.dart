import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'core/auth/user_session_manager.dart';
import 'core/theme/theme_manager.dart';
import 'features/onboarding/initial_setup_screen.dart';
import 'features/onboarding/splash_screen.dart';
import 'theme/app_theme.dart';
import 'features/folders/folder_screen.dart';
import 'features/onboarding/reset_password_screen.dart';
import 'features/share/share_save_screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/sync/remote_datasource.dart';
import 'core/sync/sync_manager.dart';
import 'core/services/folder_classification_service.dart';

import 'config/app_config.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

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

  if (AppConfig.instance.supabaseUrl.isNotEmpty &&
      AppConfig.instance.supabaseAnonKey.isNotEmpty) {
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

  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  State<ILikeItApp> createState() => _ILikeItAppState();
}

class _ILikeItAppState extends State<ILikeItApp> {
  static const _channel = MethodChannel('shared_link');
  String? _sharedLink;
  bool _showSplash = true;
  bool _isPasswordRecovery = false;

  @override
  void initState() {
    super.initState();

    // Listen to Auth state changes for password recovery deep link
    if (AppConfig.instance.supabaseUrl.isNotEmpty &&
        AppConfig.instance.supabaseAnonKey.isNotEmpty) {
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        final AuthChangeEvent event = data.event;
        if (event == AuthChangeEvent.passwordRecovery) {
          if (ILikeItApp.navigatorKey.currentState != null) {
            ILikeItApp.navigatorKey.currentState!.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
              (route) => false,
            );
          } else {
            setState(() {
              _isPasswordRecovery = true;
            });
          }
        }
      });
    }

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

    // Pull initial shared text in case of cold start
    _getInitialSharedText();
  }

  Future<void> _getInitialSharedText() async {
    try {
      final String? initialText = await _channel.invokeMethod<String>(
        'getSharedText',
      );
      if (initialText != null) {
        setState(() {
          _sharedLink = initialText;
        });
        // Clear it on the native side so it isn't pulled again on hot restart
        await _channel.invokeMethod('clearSharedText');
      }
    } catch (e) {
      print('Error getting initial shared text: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.instance.themeModeNotifier,
      builder: (context, themeMode, child) {
        return MaterialApp(
          navigatorKey: ILikeItApp.navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          themeAnimationDuration:
              Duration.zero, // Instant transition as requested
          themeAnimationCurve: Curves.linear,
          home: _showSplash
              ? CustomSplashScreen(
                  onInitializationComplete: () {
                    setState(() {
                      _showSplash = false;
                    });
                  },
                )
              : (_isPasswordRecovery
                  ? const ResetPasswordScreen()
                  : (_sharedLink != null
                      ? ShareSaveScreen(
                          sharedLink: _sharedLink!,
                          onLinkSaved: _clearSharedLink,
                        )
                      : (widget.isBackedUp
                          ? const FolderScreen()
                          : const InitialSetupScreen()))),
        );
      },
    );
  }

  void _clearSharedLink() {
    setState(() {
      _sharedLink = null;
    });
    _channel.invokeMethod('clearSharedText').catchError((e) {
      print('Error clearing shared text on native side: $e');
    });
  }
}
