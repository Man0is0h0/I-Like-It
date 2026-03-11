import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/auth/user_session_manager.dart';
import '../folders/folder_screen.dart';
import 'restore_screen.dart';
import '../../core/widgets/gradient_scaffold.dart'; // New
import '../../core/widgets/glass_container.dart'; // New

class InitialSetupScreen extends StatefulWidget {
  const InitialSetupScreen({super.key});

  @override
  State<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  bool _copied = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _ensureSession();
  }

  Future<void> _ensureSession() async {
    if (UserSessionManager.recoveryCode == null) {
      setState(() => _isLoading = true);
      await UserSessionManager.initialize();
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
       return GradientScaffold(
         body: Center(child: CircularProgressIndicator(color: colorScheme.primary)),
       );
    }

    final code = UserSessionManager.recoveryCode ?? 'ERROR-CODE';

    return GradientScaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                 GlassContainer(
                  borderRadius: BorderRadius.circular(100),
                  height: 120, 
                  width: 120,
                  padding: const EdgeInsets.all(24),
                  child: Icon(
                    Icons.security,
                    size: 64,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Backup Your Recovery Code',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'This code is the ONLY way to restore your data if you lose this device or reinstall the app. We do not store your personal information.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  borderRadius: BorderRadius.circular(16),
                  color: theme.cardTheme.color?.withOpacity(0.5),
                  child: Column(
                    children: [
                       SelectableText(
                        code,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontFamily: 'Courier',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          color: colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: code));
                          setState(() => _copied = true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Code copied to clipboard')),
                          );
                        },
                        icon: Icon(_copied ? Icons.check : Icons.copy),
                        label: Text(_copied ? 'Copied' : 'Copy Code'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _copied ? Colors.green : colorScheme.surface,
                          foregroundColor: _copied ? Colors.white : colorScheme.primary,
                          elevation: 0,
                          side: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: _copied
                      ? () async {
                          await UserSessionManager.markAsBackedUp();
                          if (mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const FolderScreen(),
                              ),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    disabledBackgroundColor: colorScheme.onSurface.withOpacity(0.12),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('I have saved my code'),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: TextButton(
                    onPressed: () {
                       Navigator.push(
                         context,
                         MaterialPageRoute(builder: (_) => const RestoreScreen()),
                       );
                    },
                    child: const Text('Already have an account? Restore Data'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
