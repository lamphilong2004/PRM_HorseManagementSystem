import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/api/api_client.dart';
import '../core/auth/auth_controller.dart';
import '../core/models/app_models.dart';
import '../ui/app_theme.dart';
import '../ui/app_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.auth});

  final AuthController auth;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Nút quay về trang chủ ───────────────────────────
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.go('/'),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.colors.surface2,
                          borderRadius: context.radii.base,
                          border: Border.all(color: context.colors.border),
                        ),
                        child: Icon(Icons.arrow_back_ios_new,
                            size: 16, color: context.colors.muted),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Quay lại trang chủ',
                      style: context.typography.bodyMuted.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildBrandHeader(),
                const SizedBox(height: 36),
                _buildLoginCard(),
                const SizedBox(height: 24),
                _buildRegisterLink(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [context.colors.primary, context.colors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: context.colors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.emoji_events_rounded, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'ERMS',
          style: TextStyle(
            fontFamily: context.typography.fontFamily,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: context.colors.text,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Hệ thống Quản lý Giải đấu',
          style: TextStyle(
            fontFamily: context.typography.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: context.colors.muted,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Đăng Nhập', style: context.typography.h2),
          const SizedBox(height: 6),
          Text('Vui lòng nhập thông tin tài khoản để tiếp tục.', style: context.typography.bodyMuted),
          const SizedBox(height: 24),

          // ── Email ──────────────────────────────────────────
          Text('Địa chỉ Email', style: context.typography.label),
          const SizedBox(height: 6),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textCapitalization: TextCapitalization.none,
            style: context.typography.body,
            decoration: InputDecoration(
              hintText: 'you@example.com',
              prefixIcon: Icon(Icons.email_outlined, size: 18, color: context.colors.muted),
            ),
          ),

          const SizedBox(height: 18),

          // ── Password ───────────────────────────────────────
          Text('Mật khẩu', style: context.typography.label),
          const SizedBox(height: 6),
          TextField(
            controller: _passwordController,
            obscureText: _obscure,
            style: context.typography.body,
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: Icon(Icons.lock_outline, size: 18, color: context.colors.muted),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 18,
                  color: context.colors.muted,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ── Login button ──────────────────────────────────
          AppButton(
            label: 'Đăng nhập',
            icon: Icons.login_rounded,
            isLoading: _loading,
            onPressed: _loading ? null : _handleLogin,
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Chưa có tài khoản? ", style: context.typography.bodyMuted),
        GestureDetector(
          onTap: () => context.pushNamed('Register'),
          child: Text(
            'Đăng ký ngay',
            style: TextStyle(
              fontFamily: context.typography.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.colors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      await showAppAlert(context, 'Thiếu thông tin', 'Vui lòng nhập đầy đủ email và mật khẩu.', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await widget.auth.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: Role.spectator, // Backend automatically determines the actual user role on login
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException ? error.message : 'Đăng nhập thất bại';
      await showAppAlert(context, 'Đăng Nhập Thất Bại', message, isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
