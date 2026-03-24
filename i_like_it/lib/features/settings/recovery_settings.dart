import 'package:flutter/material.dart';
import '../../core/sync/sync_manager.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../core/widgets/glass_container.dart';

class RecoverySettingsScreen extends StatefulWidget {
  const RecoverySettingsScreen({super.key});

  @override
  State<RecoverySettingsScreen> createState() => _RecoverySettingsScreenState();
}

class _RecoverySettingsScreenState extends State<RecoverySettingsScreen> {
  final _emailController = TextEditingController();
  
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
          _isLoadingEmail = false;
          _isEditing = email == null;
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GradientScaffold(
      appBar: AppBar(
        title: Text('Account Settings', style: theme.textTheme.headlineMedium?.copyWith(fontSize: 20)),
        backgroundColor: Colors.transparent,
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
               title: 'Your Account Email',
               description: 'The email address associated with your account.',
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
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
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
              labelText: 'Email Address',
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
