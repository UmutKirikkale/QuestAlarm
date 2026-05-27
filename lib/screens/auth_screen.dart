import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/player_service.dart';
import '../theme/pixel_text.dart';
import '../theme/quest_theme.dart';
import '../widgets/retro_arcade_button.dart';
import '../widgets/retro_window.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegisterMode = false;
  bool _isBusy = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final credential = await AuthService.instance.signInWithGoogle();
      final isNew = credential?.additionalUserInfo?.isNewUser ?? false;
      if (isNew) {
        await PlayerService.instance.initializeProfileForNewUser();
      } else {
        await PlayerService.instance.syncFromCloudIfSignedIn();
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/initial');
    } catch (e) {
      _showError('Google giriş başarısız: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _handleEmailAuth() async {
    if (_isBusy) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isBusy = true);
    try {
      if (_isRegisterMode) {
        final credential = await AuthService.instance.registerWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (credential.additionalUserInfo?.isNewUser ?? false) {
          await PlayerService.instance.initializeProfileForNewUser();
        }
      } else {
        await AuthService.instance.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        await PlayerService.instance.syncFromCloudIfSignedIn();
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/initial');
    } catch (e) {
      _showError('Kimlik doğrulama başarısız: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
        backgroundColor: QuestTheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuestTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: RetroWindow(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'QUEST ALARM',
                      textAlign: TextAlign.center,
                      style: pixelTextStyle(
                        fontSize: 18,
                        color: QuestTheme.primary,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Giriş gerekli',
                      textAlign: TextAlign.center,
                      style: pixelTextStyle(
                        fontSize: 12,
                        color: QuestTheme.onSurfaceMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    RetroArcadeButton(
                      label: _isBusy ? 'BEKLEYIN...' : 'GOOGLE ILE GIRIS',
                      icon: '☁️',
                      backgroundColor: const Color(0xFF2D3D5A),
                      foregroundColor: QuestTheme.secondary,
                      onPressed: _handleGoogleSignIn,
                    ),
                    const SizedBox(height: 14),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'E-posta',
                            ),
                            validator: (value) {
                              final v = value?.trim() ?? '';
                              if (v.isEmpty || !v.contains('@')) {
                                return 'Geçerli bir e-posta girin';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Şifre',
                            ),
                            validator: (value) {
                              final v = value?.trim() ?? '';
                              if (v.length < 6) return 'Şifre en az 6 karakter olmalı';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          RetroArcadeButton(
                            label: _isBusy
                                ? 'BEKLEYIN...'
                                : _isRegisterMode
                                    ? 'E-POSTA ILE KAYIT OL'
                                    : 'E-POSTA ILE GIRIS YAP',
                            icon: _isRegisterMode ? '🆕' : '🔑',
                            onPressed: _handleEmailAuth,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _isBusy
                          ? null
                          : () => setState(() => _isRegisterMode = !_isRegisterMode),
                      child: Text(
                        _isRegisterMode
                            ? 'Zaten hesabın var mı? Giriş yap'
                            : 'İlk kez mi? Kayıt ol',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
