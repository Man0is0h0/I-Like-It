import 'package:flutter/material.dart';
import '../../core/auth/user_session_manager.dart';
import '../../core/sync/sync_manager.dart';
import 'package:flutter/services.dart';
import '../../core/widgets/gradient_scaffold.dart'; // New
import '../../core/widgets/glass_container.dart'; // New

class RecoverySettingsScreen extends StatefulWidget {
  const RecoverySettingsScreen({super.key});

  @override
  State<RecoverySettingsScreen> createState() => _RecoverySettingsScreenState();
}

class _RecoverySettingsScreenState extends State<RecoverySettingsScreen> {
  bool _showCode = false;
  final _emailController = TextEditingController();
  
  // State for email management
  bool _isLoadingEmail = true;
  String? _currentEmail;
  bool _isEditing = false;
  
  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }
  
  Future<void> _loadUserEmail() async {
    try {
      final email = await SyncManager.instance.remoteDataSource.fetchUserEmail();
      if (mounted) {
        setState(() {
          _currentEmail = email;
          // If we have an email, we show it (not editing). If none, we are ready to edit.
          _isLoadingEmail = false;
          _isEditing = email == null; // Auto-edit if no email
          if (email != null) {
            _emailController.text = email;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingEmail = false);
      }
      print('Error loading email: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = UserSessionManager.recoveryCode ?? 'Unknown';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GradientScaffold(
      appBar: AppBar(
        title: Text('Data Recovery', style: theme.textTheme.headlineMedium?.copyWith(fontSize: 20)),
        backgroundColor: Colors.transparent, // Transparent for gradient
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
             const SizedBox(height: 24),
             _buildSection(
               context,
               title: 'Recovery Code',
               description: 'This 16-character code is your primary way to restore data.',
               child: GlassContainer(
                 padding: const EdgeInsets.all(16),
                 borderRadius: BorderRadius.circular(16),
                 child: Column(
                   children: [
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Text(
                           _showCode ? code : '••••-••••-••••-••••',
                           style: theme.textTheme.titleMedium?.copyWith(
                             fontFamily: 'Courier',
                             fontWeight: FontWeight.bold,
                             fontSize: 18,
                             letterSpacing: 1.0,
                           ),
                         ),
                         IconButton(
                           icon: Icon(_showCode ? Icons.visibility_off : Icons.visibility, color: colorScheme.onSurfaceVariant),
                           onPressed: () => setState(() => _showCode = !_showCode),
                         ),
                       ],
                     ),
                     if (_showCode)
                       Padding(
                         padding: const EdgeInsets.only(top: 12),
                         child: SizedBox(
                           width: double.infinity,
                           child: ElevatedButton.icon(
                             onPressed: () {
                               Clipboard.setData(ClipboardData(text: code));
                               ScaffoldMessenger.of(context).showSnackBar(
                                 const SnackBar(content: Text('Code copied')),
                               );
                             },
                             style: ElevatedButton.styleFrom(
                               backgroundColor: colorScheme.surface.withOpacity(0.5),
                               foregroundColor: colorScheme.primary,
                               elevation: 0,
                               padding: const EdgeInsets.symmetric(vertical: 12),
                               side: BorderSide(color: colorScheme.primary.withOpacity(0.5)),
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                             ),
                             icon: const Icon(Icons.copy, size: 18),
                             label: const Text('Copy Code'),
                           ),
                         ),
                       ),
                   ],
                 ),
               ),
             ),
             
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
               child: Divider(height: 1, color: colorScheme.outline.withOpacity(0.2)),
             ),
             
             _buildSection(
               context,
               title: 'Your Mail (Optional)',
               description: 'Add an email to receive a verification code if you lose your recovery code.',
               child: _isLoadingEmail 
                  ? const Center(child: CircularProgressIndicator())
                  : _buildEmailContent(theme, colorScheme),
             ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmailContent(ThemeData theme, ColorScheme colorScheme) {
    // Case 1: Displaying Saved Email
    if (!_isEditing && _currentEmail != null) {
      return GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.email, color: colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _currentEmail!,
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(Icons.check_circle, color: Colors.green, size: 20),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                   setState(() {
                     _isEditing = true;
                     _emailController.text = _currentEmail!;
                   });
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colorScheme.primary.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Change Email'),
              ),
            ),
          ],
        ),
      );
    }
    
    // Case 2: Editing or New Email
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _emailController,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              labelText: 'Recovery Email',
              hintText: 'you@example.com',
              filled: true,
              fillColor: theme.cardTheme.color?.withOpacity(0.5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveEmail,
                  style: ElevatedButton.styleFrom(
                     backgroundColor: colorScheme.primary,
                     foregroundColor: colorScheme.onPrimary,
                     padding: const EdgeInsets.symmetric(vertical: 14),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Email', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              if (_currentEmail != null) ...[
                 const SizedBox(width: 12),
                 TextButton(
                   onPressed: () {
                     setState(() {
                        _isEditing = false;
                     });
                   },
                   style: TextButton.styleFrom(
                     padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                   ),
                   child: const Text('Cancel'),
                 ),
              ]
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required String description, required Widget child}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(description, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Future<void> _saveEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Please enter a valid email')),
       );
       return;
    }
    
    // Show spinner in button if I wanted, but blocking tap via loading dialog is easier or generic loading
    // For now simple await
    
    try {
      await SyncManager.instance.remoteDataSource.updateUserEmail(email);
      if (mounted) {
         setState(() {
           _currentEmail = email;
           _isEditing = false;
         });
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Email saved successfully')),
         );
         FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error saving email: $e')),
         );
      }
    }
  }
}
