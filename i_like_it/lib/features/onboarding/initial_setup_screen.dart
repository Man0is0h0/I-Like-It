import 'package:flutter/material.dart';
import '../../core/auth/user_session_manager.dart';
import '../../core/sync/sync_manager.dart';
import '../folders/folder_screen.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../core/widgets/glass_container.dart';
import 'package:uuid/uuid.dart';

class InitialSetupScreen extends StatefulWidget {
  const InitialSetupScreen({super.key});

  @override
  State<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  
  bool _isLoading = false;
  bool _otpSent = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GradientScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              GlassContainer(
                borderRadius: BorderRadius.circular(100),
                height: 120, 
                width: 120,
                padding: const EdgeInsets.all(24),
                child: Icon(
                  Icons.email_outlined,
                  size: 64,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Welcome to I Like It',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Log in or sign up securely using your email address.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              GlassContainer(
                padding: const EdgeInsets.all(24),
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _otpSent ? 'Enter Verification Code' : 'Enter Your Email',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _otpSent 
                        ? 'We sent a 6-digit code to ${_emailController.text}.' 
                        : 'We will send you a one-time verification code.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    if (!_otpSent) ...[
                      TextField(
                        controller: _emailController,
                        style: theme.textTheme.bodyMedium,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          filled: true,
                          fillColor: theme.cardTheme.color?.withOpacity(0.5),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _sendOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            disabledBackgroundColor: colorScheme.onSurface.withOpacity(0.12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading 
                            ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 2)) 
                            : const Text('Send Code', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ] else ...[
                      TextField(
                        controller: _otpController,
                        style: theme.textTheme.bodyMedium,
                        decoration: InputDecoration(
                          labelText: 'Verification Code',
                          filled: true,
                          fillColor: theme.cardTheme.color?.withOpacity(0.5),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _verifyOtpAndLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            disabledBackgroundColor: colorScheme.onSurface.withOpacity(0.12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading 
                             ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 2)) 
                             : const Text('Verify & Continue', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _otpSent = false;
                              _otpController.clear();
                            });
                          },
                          child: const Text('Change Email'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Please enter a valid email')),
       );
       return;
    }

    setState(() => _isLoading = true);
    
    try {
      final success = await SyncManager.instance.remoteDataSource.requestOtp(email);
      if (success) {
        if (mounted) {
           setState(() {
             _otpSent = true; 
           });
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Verification code sent!')),
           );
        }
      } else {
        throw 'Failed to send verification code. Please try again.';
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e')),
         );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtpAndLogin() async {
    final email = _emailController.text.trim().toLowerCase();
    final otp = _otpController.text.trim();
    
    if (otp.length < 6) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Please enter valid 6-digit code')),
       );
       return;
    }

    setState(() => _isLoading = true);

    try {
      final remote = SyncManager.instance.remoteDataSource;
      final success = await remote.verifyOtp(email, otp);
      
      if (success) {
         // OTP Verified. Now find the user associated with this email.
         String? userId = await remote.findUserIdByEmail(email);
         
         if (userId == null) {
            // New user Signup
            userId = const Uuid().v4();
            await remote.createUserWithEmail(userId, email);
         }
            
         await UserSessionManager.loginWithEmail(userId, email);
         
         // Trigger sync since user is now logged in
         SyncManager.instance.resetUserCreated();
         SyncManager.instance.sync();
         
         if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const FolderScreen()),
            );
         }
      } else {
        throw 'Invalid verification code';
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verification failed: $e')),
         );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
