import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/auth/user_session_manager.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/utils/countries.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _usernameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();

  CountryCode _selectedCountry = const CountryCode(name: 'India', code: '+91', flag: '🇮🇳', minLength: 10, maxLength: 10);
  bool _isLoading = false;
  bool _isSaving = false;
  String? _mobileErrorText;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _validateMobile(String value) {
    if (value.isEmpty) {
      setState(() => _mobileErrorText = null);
      return;
    }
    final digitsOnly = RegExp(r'^\d+$');
    if (!digitsOnly.hasMatch(value)) {
      setState(() => _mobileErrorText = 'Only digits are allowed');
      return;
    }
    if (value.length < _selectedCountry.minLength ||
        value.length > _selectedCountry.maxLength) {
      final lengthMsg = _selectedCountry.minLength == _selectedCountry.maxLength
          ? '${_selectedCountry.minLength}'
          : '${_selectedCountry.minLength}-${_selectedCountry.maxLength}';
      setState(() {
        _mobileErrorText =
            'Please enter a valid $lengthMsg-digit mobile number';
      });
      return;
    }
    setState(() => _mobileErrorText = null);
  }

  void _loadProfileData() async {
    // 1. Load from local cache first for instant display / offline support
    _emailController.text = UserSessionManager.email ?? '';
    _usernameController.text = UserSessionManager.username ?? '';
    
    final cachedMobile = UserSessionManager.mobile;
    _parsePhoneNumber(cachedMobile);

    // 2. Fetch fresh details from Supabase if online
    final connectivity = await Connectivity().checkConnectivity();
    if (!connectivity.contains(ConnectivityResult.none)) {
      setState(() => _isLoading = true);
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          final userData = await Supabase.instance.client
              .from('users')
              .select('username, mobile_number')
              .eq('id', user.id)
              .maybeSingle();

          String remoteUsername = '';
          String remoteMobile = '';

          if (userData != null) {
            remoteUsername = userData['username'] ?? '';
            remoteMobile = userData['mobile_number'] ?? '';
          }

          if (remoteUsername.isEmpty) {
            remoteUsername = user.userMetadata?['username'] ?? '';
          }
          if (remoteMobile.isEmpty) {
            remoteMobile = user.userMetadata?['mobile_number'] ?? '';
          }

          if (mounted) {
            setState(() {
              if (remoteUsername.isNotEmpty) {
                _usernameController.text = remoteUsername;
              }
              if (remoteMobile.isNotEmpty) {
                _parsePhoneNumber(remoteMobile);
              }
            });
            // Update local cache
            await UserSessionManager.saveUserProfile(
              _usernameController.text.trim(),
              remoteMobile.isNotEmpty ? remoteMobile : (cachedMobile ?? ''),
            );
          }
        }
      } catch (e) {
        print('Error fetching profile from cloud: $e');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _parsePhoneNumber(String? mobile) {
    if (mobile == null || mobile.isEmpty) return;
    for (var country in countries) {
      if (mobile.startsWith(country.code)) {
        setState(() {
          _selectedCountry = country;
          _mobileController.text = mobile.substring(country.code.length);
        });
        return;
      }
    }
    _mobileController.text = mobile;
  }

  void _selectCountry() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String filter = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final colorScheme = theme.colorScheme;
            final filteredCountries = countries.where((c) {
              return c.name.toLowerCase().contains(filter.toLowerCase()) ||
                  c.code.contains(filter);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                color: theme.colorScheme.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      autofocus: true,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Search country or code...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          filter = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredCountries.length,
                      itemBuilder: (context, index) {
                        final country = filteredCountries[index];
                        return ListTile(
                          leading: Text(country.flag, style: const TextStyle(fontSize: 24)),
                          title: Text(country.name),
                          trailing: Text(
                            country.code,
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedCountry = country;
                              if (_mobileController.text.length > country.maxLength) {
                                _mobileController.text = _mobileController.text.substring(0, country.maxLength);
                              }
                              _validateMobile(_mobileController.text);
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveChanges() async {
    final username = _usernameController.text.trim();
    final mobileNumber = _mobileController.text.trim();

    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username cannot be empty')),
      );
      return;
    }

    if (mobileNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mobile number cannot be empty')),
      );
      return;
    }

    _validateMobile(mobileNumber);
    if (_mobileErrorText != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mobileErrorText!)),
      );
      return;
    }

    final fullMobile = '${_selectedCountry.code}$mobileNumber';

    setState(() => _isSaving = true);

    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        // Offline flow: save locally
        await UserSessionManager.saveUserProfile(username, fullMobile);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated locally. Changes will sync when online.'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        // Online flow: update Supabase public.users and auth metadata
        final userId = UserSessionManager.userId;
        
        await Supabase.instance.client.from('users').update({
          'username': username,
          'mobile_number': fullMobile,
        }).eq('id', userId);

        await Supabase.instance.client.auth.updateUser(
          UserAttributes(
            data: {
              'username': username,
              'mobile_number': fullMobile,
            },
          ),
        );

        await UserSessionManager.saveUserProfile(username, fullMobile);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      // Fallback to local save if Supabase write fails
      await UserSessionManager.saveUserProfile(username, fullMobile);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sync. Profile saved locally. ($e)'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Get initials for avatar
    final currentUsername = _usernameController.text.isNotEmpty 
        ? _usernameController.text 
        : (UserSessionManager.email ?? 'U');
    final initials = currentUsername.isNotEmpty ? currentUsername[0].toUpperCase() : 'U';

    return GradientScaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 120.0,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: GlassContainer(
                  padding: const EdgeInsets.all(8),
                  borderRadius: BorderRadius.circular(12),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: colorScheme.onSurface,
                    size: 16,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Text(
                  'My Profile',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(24.0),
              sliver: SliverToBoxAdapter(
                child: GlassContainer(
                  padding: const EdgeInsets.all(24),
                  borderRadius: BorderRadius.circular(24),
                  child: _isLoading
                      ? const SizedBox(
                          height: 300,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Beautiful Avatar
                            Center(
                              child: Container(
                                height: 96,
                                width: 96,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.primaryColor,
                                      AppTheme.primaryColor.withOpacity(0.6),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withOpacity(0.3),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Email Address (Read-only)
                            TextField(
                              controller: _emailController,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                              enabled: false,
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                labelStyle: TextStyle(
                                  color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                                ),
                                prefixIcon: const Icon(Icons.email_outlined),
                                filled: true,
                                fillColor: colorScheme.onSurface.withOpacity(0.04),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Username
                            TextField(
                              controller: _usernameController,
                              style: theme.textTheme.bodyMedium,
                              decoration: InputDecoration(
                                labelText: 'Username',
                                labelStyle: TextStyle(
                                  color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                                ),
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Mobile Number field with country code picker
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  InkWell(
                                    onTap: _selectCountry,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _selectedCountry.flag,
                                            style: const TextStyle(fontSize: 20),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _selectedCountry.code,
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          Icon(
                                            Icons.arrow_drop_down,
                                            color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: _mobileController,
                                      onChanged: _validateMobile,
                                      style: theme.textTheme.bodyMedium,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(_selectedCountry.maxLength),
                                      ],
                                      decoration: InputDecoration(
                                        labelText: 'Mobile Number',
                                        labelStyle: TextStyle(
                                          color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                                        ),
                                        errorText: _mobileErrorText != null ? '' : null,
                                        errorStyle: const TextStyle(height: 0.01, fontSize: 0),
                                        prefixIcon: const Icon(Icons.phone_outlined),
                                      ),
                                      keyboardType: TextInputType.phone,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_mobileErrorText != null) ...[
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.only(left: 4.0),
                                child: Text(
                                  _mobileErrorText!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.error,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 32),

                            // Save Button
                            ElevatedButton(
                              onPressed: _isSaving ? null : _saveChanges,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isSaving
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: colorScheme.onPrimary,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Save Changes',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
