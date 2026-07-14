import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/api/api_client.dart';
import '../core/auth/auth_controller.dart';
import '../core/models/app_models.dart';
import '../ui/app_theme.dart';
import '../ui/app_widgets.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.auth});

  final AuthController auth;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController     = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nameController.dispose();
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
                const SizedBox(height: 16),
                // ── Back button ───────────────────────────────────
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.goNamed('Login'),
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
                    Text('Quay lại Đăng nhập', style: context.typography.bodyMuted),
                  ],
                ),
                const SizedBox(height: 32),
                _buildHeader(),
                const SizedBox(height: 28),
                _buildCard(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tạo tài khoản', style: context.typography.h1),
        const SizedBox(height: 6),
        Text(
          'Tham gia nền tảng Giải đua ngựa.',
          style: context.typography.bodyMuted,
        ),
      ],
    );
  }

  Widget _buildCard() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Name
          Text('Họ và tên', style: context.typography.label),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            style: context.typography.body,
            decoration: InputDecoration(
              hintText: 'Nguyen Van A',
              prefixIcon: Icon(Icons.person_outline, size: 18, color: context.colors.muted),
            ),
          ),
          const SizedBox(height: 16),

          // Email
          Text('Email', style: context.typography.label),
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
          const SizedBox(height: 16),

          // Password
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
          const SizedBox(height: 24),

          AppButton(
            label: 'Tạo tài khoản',
            icon: Icons.person_add_outlined,
            isLoading: _loading,
            onPressed: _loading ? null : _handleRegister,
          ),
        ],
      ),
    );
  }


  Future<void> _handleRegister() async {
    setState(() => _loading = true);
    try {
      await widget.auth.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        role: Role.spectator,
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException ? error.message : 'Tạo tài khoản thất bại';
      await showAppAlert(context, 'Đăng Ký Thất Bại', message, isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
