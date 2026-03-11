import 'package:flutter/material.dart';
import '../../core/auth/user_session_manager.dart';
import '../../core/sync/remote_datasource.dart';
import '../../core/sync/sync_manager.dart';
import '../folders/folder_screen.dart';
import '../../core/widgets/gradient_scaffold.dart'; // New
import '../../core/widgets/glass_container.dart'; // New
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/encryption_helper.dart';

class RestoreScreen extends StatefulWidget {
  const RestoreScreen({super.key});

  @override
  State<RestoreScreen> createState() => _RestoreScreenState();
}

class _RestoreScreenState extends State<RestoreScreen> {
  final _codeController = TextEditingController();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  
  bool _isLoading = false;
  String? _error;
  bool _otpSent = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GradientScaffold(
      appBar: AppBar(
        title: Text('Restore Data', style: theme.textTheme.headlineMedium?.copyWith(fontSize: 20)),
        backgroundColor: Colors.transparent, // Transparent for gradient
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(24),
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter Recovery Code',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter the 16-character code you saved when you first installed the app.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _codeController,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        labelText: 'Recovery Code (e.g. ABCD-1234...)',
                        filled: true,
                        fillColor: theme.cardTheme.color?.withOpacity(0.5),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        errorText: _error,
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _restoreWithCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          disabledBackgroundColor: colorScheme.onSurface.withOpacity(0.12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading 
                            ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 2)) 
                            : const Text('Restore with Code', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              Row(children: [
                Expanded(child: Divider(color: colorScheme.outline.withOpacity(0.5))), 
                Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 16), 
                   child: Text("OR", style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold))
                ),
                Expanded(child: Divider(color: colorScheme.outline.withOpacity(0.5)))
              ]),
              const SizedBox(height: 32),
              
              GlassContainer(
                padding: const EdgeInsets.all(24),
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Restore with Email',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'If you linked an email, enter it here to receive a verification code.',
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
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _sendOtp,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: colorScheme.primary.withOpacity(0.5), width: 1.5),
                            foregroundColor: colorScheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Send Verification Code', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ] else ...[
                      TextField(
                        controller: _otpController,
                        style: theme.textTheme.bodyMedium,
                        decoration: InputDecoration(
                          labelText: 'Enter Verification Code',
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
                          onPressed: _isLoading ? null : _verifyOtpAndRestore,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary, // Ensure text is visible
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            disabledBackgroundColor: colorScheme.onSurface.withOpacity(0.12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Verify & Restore', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Future<void> _restoreWithCode() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final code = _codeController.text.trim();
      if (code.isEmpty) {
        throw 'Please enter a code';
      }

      final hash = UserSessionManager.hashRecoveryCode(code);
      
      // We need to access RemoteDataSource. 
      // But SyncManager holds it locally. A cleaner way would be dependency injection or a service locator.
      // For now, assume we can instantiate one or access via singleton logic if we exposed it.
      // SyncManager is a singleton, let's expose remote? No that's breaking encapsulation slightly but pragmatic here.
      // Better: Create a temporary Supabase client or use global Supabase.instance.client
      
      final client = Supabase.instance.client;
      final remote = RemoteDataSource(client);
      
      final userId = await remote.findUserIdByRecoveryHash(hash);
      
      if (userId != null) {
        // Success!
        await UserSessionManager.restoreSession(userId, code);
        
        // Reset SyncManager state since user changed
        SyncManager.instance.resetUserCreated();
        
        // Trigger sync
        SyncManager.instance.sync();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account restored successfully!')),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const FolderScreen()),
            (route) => false,
          );
        }
      } else {
        throw 'Invalid recovery code';
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
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
             const SnackBar(content: Text('OTP sent to your email')),
           );
        }
      } else {
        throw 'Failed to send OTP';
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sending OTP: $e')),
         );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtpAndRestore() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    
    if (otp.length < 6) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Please enter valid 6-digit code')),
       );
       return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await SyncManager.instance.remoteDataSource.verifyOtp(email, otp);
      
      if (success) {
         // OTP Verified. Now find the user associated with this email.
         final userId = await SyncManager.instance.remoteDataSource.findUserIdByEmail(email);
         
         if (userId != null) {
            // Restore!
            // Try to fetch the encrypted recovery code
            final encryptedCode = await SyncManager.instance.remoteDataSource.fetchEncryptedRecoveryCode(userId);
            String recoveryCodeValue = "RESTORED-VIA-EMAIL"; // fallback
            
            if (encryptedCode != null && encryptedCode.isNotEmpty) {
               final decrypted = EncryptionHelper.decrypt(encryptedCode);
               if (decrypted.isNotEmpty) {
                 recoveryCodeValue = decrypted;
               }
            }
            
            await UserSessionManager.restoreSession(userId, recoveryCodeValue);
            
            // Reset SyncManager state since user changed
            SyncManager.instance.resetUserCreated(); 
            
            SyncManager.instance.sync();
            
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const FolderScreen()),
                (route) => false,
              );
            }
         } else {
           throw 'Account not found for this email';
         }
      } else {
        throw 'Invalid OTP';
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
