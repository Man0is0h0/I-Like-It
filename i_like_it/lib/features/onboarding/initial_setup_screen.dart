import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_config.dart';
import '../../core/auth/user_session_manager.dart';
import '../../core/sync/sync_manager.dart';
import '../folders/folder_screen.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../core/widgets/glass_container.dart';

class InitialSetupScreen extends StatefulWidget {
  const InitialSetupScreen({super.key});

  @override
  State<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  // Tabs state
  bool _isLogin = true;
  bool _isLoading = false;

  // Validation state
  String? _emailErrorText;
  Timer? _usernameDebounce;
  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable; // null = untouched, true = valid, false = taken
  String _lastCheckedUsername = '';

  void _onUsernameChanged(String username) {
    final val = username.trim();
    if (val.isEmpty) {
      setState(() {
        _isUsernameAvailable = null;
        _isCheckingUsername = false;
        _lastCheckedUsername = '';
      });
      _usernameDebounce?.cancel();
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _isUsernameAvailable = null;
    });

    _usernameDebounce?.cancel();
    _usernameDebounce = Timer(const Duration(milliseconds: 600), () {
      _checkUsernameAvailability(val);
    });
  }

  Future<void> _checkUsernameAvailability(String username) async {
    if (username.isEmpty || !mounted) return;
    try {
      final exists = await Supabase.instance.client.rpc(
        'check_username_exists',
        params: {'username_to_check': username},
      );

      if (mounted && _usernameController.text.trim() == username) {
        setState(() {
          _isUsernameAvailable = !(exists as bool);
          _isCheckingUsername = false;
          _lastCheckedUsername = username;
        });
      }
    } catch (e) {
      if (mounted && _usernameController.text.trim() == username) {
        setState(() {
          _isCheckingUsername = false;
          _isUsernameAvailable =
              null; // Don't show error to disrupt, just don't show available
        });
        print('Error checking username: $e');
      }
    }
  }

  void _validateEmail(String value) {
    if (value.isEmpty) {
      setState(() => _emailErrorText = null);
      return;
    }
    final bool emailValid = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9-]+\.[a-zA-Z]+",
    ).hasMatch(value);
    setState(() {
      _emailErrorText = emailValid ? null : 'Invalid email address';
    });
  }

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Password Visibility
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Checkbox state (Signup only)
  bool _termsAccepted = false;

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String urlString) async {
    if (urlString.isEmpty) return;
    final url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch URL';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open page: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GradientScaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                // App Logo
                GlassContainer(
                  borderRadius: BorderRadius.circular(100),
                  height: 100,
                  width: 100,
                  padding: const EdgeInsets.all(20),
                  child: Icon(
                    Icons.favorite_rounded,
                    size: 56,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'I Like It',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Keep track of links and folders you like, synced securely.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Form Container
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Tab Selector
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color:
                              theme.cardTheme.color?.withOpacity(0.3) ??
                              Colors.black12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isLogin = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isLogin
                                        ? colorScheme.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Login',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _isLogin
                                            ? colorScheme.onPrimary
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isLogin = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: !_isLogin
                                        ? colorScheme.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: !_isLogin
                                            ? colorScheme.onPrimary
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (_isLogin)
                        _buildLoginForm(colorScheme, theme)
                      else
                        _buildSignupForm(colorScheme, theme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // LOGIN FORM
  Widget _buildLoginForm(ColorScheme colorScheme, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Welcome Back',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          onChanged: _validateEmail,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            labelText: 'Email Address',
            errorText: _emailErrorText,
            filled: true,
            fillColor: theme.cardTheme.color?.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.email_outlined),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            labelText: 'Password',
            filled: true,
            fillColor: theme.cardTheme.color?.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _showForgotPasswordDialog,
            child: Text(
              'Forgot Password?',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _isLoading ? null : _login,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: colorScheme.onPrimary,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Log In',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }

  // SIGNUP FORM
  Widget _buildSignupForm(ColorScheme colorScheme, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Create Account',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // Username field
        Builder(
          builder: (context) {
            Widget? suffixIcon;
            if (_isCheckingUsername) {
              suffixIcon = const Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            } else if (_isUsernameAvailable == true) {
              suffixIcon = const Icon(Icons.check_circle, color: Colors.green);
            } else if (_isUsernameAvailable == false) {
              suffixIcon = const Icon(Icons.cancel, color: Colors.red);
            }

            String? errorText;
            if (_isUsernameAvailable == false) {
              errorText = 'This username is already taken';
            }

            return TextField(
              controller: _usernameController,
              onChanged: _onUsernameChanged,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                labelText: 'Username',
                errorText: errorText,
                filled: true,
                fillColor: theme.cardTheme.color?.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.person_outline),
                suffixIcon: suffixIcon,
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        // Email field
        TextField(
          controller: _emailController,
          onChanged: _validateEmail,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            labelText: 'Email Address',
            errorText: _emailErrorText,
            filled: true,
            fillColor: theme.cardTheme.color?.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.email_outlined),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        // Password field
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            labelText: 'Password',
            filled: true,
            fillColor: theme.cardTheme.color?.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Confirm Password field
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            filled: true,
            fillColor: theme.cardTheme.color?.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legal Checkbox
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _termsAccepted,
                onChanged: (val) =>
                    setState(() => _termsAccepted = val ?? false),
                activeColor: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: theme.textTheme.bodyMedium,
                  children: [
                    const TextSpan(text: 'I agree to the '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () =>
                            _launchUrl(AppConfig.instance.privacyPolicyUrl),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Terms of Use',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () =>
                            _launchUrl(AppConfig.instance.termsUseUrl),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _signup,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: colorScheme.onPrimary,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Sign Up',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }

  // FORGOT PASSWORD DIALOG
  void _showForgotPasswordDialog() {
    final forgotEmailController = TextEditingController(
      text: _emailController.text,
    );
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) {
        bool dialogLoading = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Reset Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Enter your email address to receive a password reset link.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: forgotEmailController,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      filled: true,
                      fillColor: theme.cardTheme.color?.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: dialogLoading
                      ? null
                      : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: dialogLoading
                      ? null
                      : () async {
                          final email = forgotEmailController.text
                              .trim()
                              .toLowerCase();
                          if (email.isEmpty || !email.contains('@')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a valid email'),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => dialogLoading = true);
                          try {
                            await Supabase.instance.client.auth
                                .resetPasswordForEmail(
                                  email,
                                  redirectTo: 'ilikeit://reset-password',
                                );
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Reset link sent! Please check your email inbox.',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error sending reset link: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            setDialogState(() => dialogLoading = false);
                          }
                        },
                  child: dialogLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send Reset Link'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // LOGIN LOGIC
  Future<void> _login() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    final bool emailValid = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9-]+\.[a-zA-Z]+",
    ).hasMatch(email);
    if (email.isEmpty || !emailValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      final session = response.session;

      if (user != null && session != null) {
        await UserSessionManager.loginWithEmail(user.id, user.email!);

        // Trigger sync since user is now logged in
        SyncManager.instance.resetUserCreated();
        SyncManager.instance.sync();

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const FolderScreen()),
          );
        }
      } else {
        throw 'Failed to sign in. Please verify your email is confirmed.';
      }
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('email not confirmed') ||
          e.code == 'email_not_confirmed') {
        // Automatically resend OTP and show the verification dialog
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Email not verified. Resending verification code...',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        try {
          await Supabase.instance.client.auth.resend(
            type: OtpType.signup,
            email: email,
          );
          if (mounted) {
            _showOtpVerificationDialog(email);
          }
        } catch (resendError) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Failed to resend verification code. Please try signing up again.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        String errorMessage = e.message;
        if (e.message.toLowerCase().contains('invalid login credentials')) {
          errorMessage = 'Invalid email or password. Please try again.';
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // SIGNUP LOGIC
  Future<void> _signup() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (username.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a username')));
      return;
    }

    final bool emailValid = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9-]+\.[a-zA-Z]+",
    ).hasMatch(email);
    if (email.isEmpty || !emailValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid email address (e.g. name@example.com)',
          ),
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You must accept the Privacy Policy and Terms of Use to sign up',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Final synchronous validation for username to prevent race conditions
      if (_isUsernameAvailable == false ||
          (_isUsernameAvailable == null && username.isNotEmpty)) {
        final bool usernameExists = await Supabase.instance.client.rpc(
          'check_username_exists',
          params: {'username_to_check': username},
        );
        if (usernameExists) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isUsernameAvailable = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'This username is already taken. Please choose another.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      // Check if email already exists in the database
      final bool emailExists = await Supabase.instance.client.rpc(
        'check_email_exists',
        params: {'email_to_check': email},
      );

      if (emailExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'This email address is already registered. Please log in instead.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );

      final user = response.user;
      final session = response.session;

      if (user != null) {
        if (session != null) {
          // Instant login if confirmations are disabled in Supabase
          await UserSessionManager.loginWithEmail(user.id, user.email!);

          SyncManager.instance.resetUserCreated();
          SyncManager.instance.sync();

          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const FolderScreen()),
            );
          }
        } else {
          // Confirmation is required - show OTP Verification Dialog
          if (mounted) {
            _showOtpVerificationDialog(email);
          }
        }
      }
    } on AuthException catch (e) {
      String errorMessage = e.message;
      if (e.message.toLowerCase().contains('user already registered') ||
          e.code == 'user_already_exists') {
        errorMessage =
            'This email address is already registered. Please log in instead.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign up failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // OTP VERIFICATION DIALOG
  void _showOtpVerificationDialog(String email) {
    final otpController = TextEditingController();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isVerifying = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.dialogBackgroundColor ?? Colors.grey[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Verify Email',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'We sent a verification code to $email. Please enter it below to confirm your account.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    style: theme.textTheme.bodyMedium,
                    maxLength: 8,
                    decoration: InputDecoration(
                      labelText: 'Verification Code',
                      hintText: 'Enter code',
                      counterText: '',
                      filled: true,
                      fillColor: theme.cardTheme.color?.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.pin_outlined),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isVerifying
                          ? null
                          : () async {
                              try {
                                await Supabase.instance.client.auth.resend(
                                  type: OtpType.signup,
                                  email: email,
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'A new verification code has been sent!',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Failed to resend code. Please try again.',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                      child: Text(
                        'Resend Code',
                        style: TextStyle(color: colorScheme.primary),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isVerifying
                      ? null
                      : () {
                          Navigator.pop(context);
                          setState(() {
                            _isLogin = true; // Switch back to login page
                            _passwordController.clear();
                            _confirmPasswordController.clear();
                          });
                        },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isVerifying
                      ? null
                      : () async {
                          final otp = otpController.text.trim();
                          if (otp.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter the verification code',
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isVerifying = true);
                          try {
                            final response = await Supabase.instance.client.auth
                                .verifyOTP(
                                  email: email,
                                  token: otp,
                                  type: OtpType.signup,
                                );

                            final user = response.user;
                            final session = response.session;

                            if (user != null && session != null) {
                              await UserSessionManager.loginWithEmail(
                                user.id,
                                user.email!,
                              );

                              // Trigger sync since user is now logged in
                              SyncManager.instance.resetUserCreated();
                              SyncManager.instance.sync();

                              if (mounted) {
                                Navigator.pop(context); // Close dialog
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => const FolderScreen(),
                                  ),
                                );
                              }
                            } else {
                              throw 'Verification failed. Please try again.';
                            }
                          } on AuthException catch (e) {
                            if (mounted) {
                              String errorMessage = e.message;
                              if (errorMessage.toLowerCase().contains(
                                    'expired',
                                  ) ||
                                  errorMessage.toLowerCase().contains(
                                    'invalid',
                                  )) {
                                errorMessage =
                                    'The verification code has expired or is invalid. Please request a new one.';
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(errorMessage),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'An unexpected error occurred. Please try again.',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            setDialogState(() => isVerifying = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isVerifying
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Verify'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
