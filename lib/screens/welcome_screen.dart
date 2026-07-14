import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../main.dart'; // To access themeNotifier
import '../ui/app_theme.dart';
import '../ui/app_widgets.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                _buildHero(context),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 32),
                      _buildStatsSection(context),
                      const SizedBox(height: 40),
                      _buildFeaturesSection(context),
                      const SizedBox(height: 40),
                      _buildFeaturedRaces(context),
                      const SizedBox(height: 40),
                      _buildCTA(context),
                      const SizedBox(height: 48),
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [context.colors.primary, context.colors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.emoji_events_rounded, color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'ERMS',
            style: TextStyle(
               fontFamily: context.typography.fontFamily,
               fontSize: 16,
               fontWeight: FontWeight.w800,
               color: context.colors.text,
               letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              context.isDark ? Icons.light_mode : Icons.dark_mode,
              color: context.colors.text2,
            ),
            onPressed: () {
              themeNotifier.value = context.isDark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => context.goNamed('Login'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle: TextStyle(
                fontFamily: context.typography.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(borderRadius: context.radii.sm),
            ),
            child: const Text('Đăng nhập'),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      height: 380,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: context.radii.lg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: context.radii.lg,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuBm_LN5oeZeYaR3sYCdiQp6wzE_iWsWveVll_Ty41EfiWwU-zloTjxlOrDuWhh8UcZq5RUBXDfQrzdK6z0hCt8XMLs9vxLE651q0OW2AjqnW9slOprPaxlJ1W2sA-Vo3lA8AfgS816nNMQxr9kuDMewIOpEk2tRlfXJss2ULlLp-fh_jjhhw-Y2fquvCd7biikftJIBaqQqYLhuJgBDQBkr6XhHUPPdZ38n2ovi-7eQu9xXNgEiYxKKaSIoPiW0L3DHdB1SVS9Pnddm',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: context.colors.primaryDark,
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined, color: Colors.white, size: 40),
                  ),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.3),
                      borderRadius: context.radii.full,
                      border: Border.all(color: context.colors.primary.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      'NỀN TẢNG ERMS',
                      style: context.typography.captionUpper.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Nâng Tầm Đẳng Cấp\nĐua Ngựa',
                    style: context.typography.h1.copyWith(
                      color: Colors.white,
                      height: 1.2,
                      fontSize: 26,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Hệ thống quản lý chuyên nghiệp, minh bạch và hiện đại hàng đầu dành cho các giải đua ngựa quốc tế.',
                    style: TextStyle(
                      fontFamily: context.typography.fontFamily,
                      fontSize: 13,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Khám Phá Ngay',
                          icon: Icons.explore_outlined,
                          onPressed: () => context.goNamed('Register'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              children: [
                Icon(Icons.sports_score_outlined, color: context.colors.primary, size: 22),
                const SizedBox(height: 8),
                Text(
                  '128+',
                  style: context.typography.h2.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 2),
                Text(
                  'Giải đua tổ chức',
                  style: context.typography.captionUpper.copyWith(fontSize: 8),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              children: [
                Icon(Icons.pets_outlined, color: context.colors.purple, size: 22),
                const SizedBox(height: 8),
                Text(
                  '500+',
                  style: context.typography.h2.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 2),
                Text(
                  'Chiến mã tinh anh',
                  style: context.typography.captionUpper.copyWith(fontSize: 8),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              children: [
                Icon(Icons.military_tech_outlined, color: context.colors.accent, size: 22),
                const SizedBox(height: 8),
                Text(
                  '10+',
                  style: context.typography.h2.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 2),
                Text(
                  'Giải đấu lớn',
                  style: context.typography.captionUpper.copyWith(fontSize: 8),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    final features = [
      (
        title: 'Quản lý chuyên nghiệp',
        desc: 'Quy trình vận hành chuẩn quốc tế, bảo mật tuyệt đối.',
        icon: Icons.verified_user_outlined,
        color: context.colors.primary,
      ),
      (
        title: 'Kết quả trực tiếp',
        desc: 'Cập nhật kết quả tức thì với độ trễ gần như bằng không.',
        icon: Icons.speed_outlined,
        color: context.colors.info,
      ),
      (
        title: 'Đăng ký dễ dàng',
        desc: 'Đăng ký tham gia dễ dàng qua nền tảng trực tuyến.',
        icon: Icons.app_registration_outlined,
        color: context.colors.purple,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tính Năng Ưu Việt', style: context.typography.h2),
        const SizedBox(height: 16),
        ...features.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: f.color.withValues(alpha: 0.15),
                    borderRadius: context.radii.sm,
                  ),
                  child: Icon(f.icon, color: f.color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f.title,
                        style: context.typography.h3.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        f.desc,
                        style: context.typography.bodyMuted.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildFeaturedRaces(BuildContext context) {
    final races = [
      (
        title: 'Cúp Quốc gia Grand National',
        desc: 'Giải đấu quy mô lớn nhất năm với sự góp mặt của các chiến mã huyền thoại.',
        status: 'Sắp diễn ra',
        date: '25/12/2024',
        image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuC_-LGsB-NXPY1FIQ9-AbkVAt0zjgOABU7YKQ3ba_wNEuLWH8uT1grak3vUg1zP_bPSt1phKpPf1-c56j6uyW3rMrrNnI07jgQiIZDcH9JqZ_fu9GnjqN5iCZHHGoY1vtQLG6mgelbIjW5tGR5TZScEO7IBBd0UrzNrlFL0HfmUzGr1Eow0MTKTrvS280R8xk7kqHXUJon_UGFBIXvcOVS0tq4I-X6EaM9kzWl0eEK57MZ3Ssf8IzVenxJyTyLIBI0O3M_P18EqyCa1',
        badgeColor: context.colors.primary,
      ),
      (
        title: 'Giải đua Glacier Sprint',
        desc: 'Tốc độ là tất cả. Những vòng chạy kịch tính trên mặt sân cỏ tiêu chuẩn.',
        status: 'Trực tiếp',
        date: 'Đang diễn ra',
        image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuC1SbKBCegDjoAWAIpTG4fa2rNVldov6CYPM5etTwDVtMu5AQcdWaGqwvO1j7d-GD2lo_reMvtY7gTV3CGhYNxmnng_7PTHOROqMoQgHCU8EjXzO06jpfV3Qoom6RRJp9DVgNI8141aOuRAgOZmW7LfZ_el_f9-5VZj0QyhrYOdE7tLgdCEswrWsjvx_qtoXvSW5JtMmI_Zpw9-qxLP217biu7Ws3AAZ6KXcYPMAgK9w1JD40pb0rvDwg-AfLCnWrzInBw6h7NOdxkw',
        badgeColor: context.colors.purple,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Giải Đua Nổi Bật', style: context.typography.h2),
        const SizedBox(height: 16),
        ...races.map((r) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: context.radii.lg,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
             borderRadius: context.radii.lg,
             child: Container(
               color: context.isDark ? context.colors.surface3.withValues(alpha: 0.5) : Colors.white,
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.stretch,
                 children: [
                   SizedBox(
                     height: 140,
                     child: Stack(
                       fit: StackFit.expand,
                       children: [
                         Image.network(
                           r.image,
                           fit: BoxFit.cover,
                           errorBuilder: (context, error, stackTrace) => Container(
                             color: context.colors.surface2,
                             child: const Icon(Icons.broken_image_outlined),
                           ),
                         ),
                         Positioned(
                           top: 12,
                           right: 12,
                           child: Container(
                             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                             decoration: BoxDecoration(
                               color: r.badgeColor,
                               borderRadius: context.radii.full,
                             ),
                             child: Text(
                               r.status,
                               style: const TextStyle(
                                 color: Colors.white,
                                 fontSize: 10,
                                 fontWeight: FontWeight.w800,
                               ),
                             ),
                           ),
                         ),
                       ],
                     ),
                   ),
                   Padding(
                     padding: const EdgeInsets.all(16),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(r.title, style: context.typography.h3),
                         const SizedBox(height: 6),
                         Text(
                           r.desc,
                           style: context.typography.bodyMuted.copyWith(fontSize: 12),
                         ),
                         const SizedBox(height: 12),
                         Container(height: 1, color: context.colors.border),
                         const SizedBox(height: 10),
                         Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                             Text(
                               r.date,
                               style: TextStyle(
                                 color: r.badgeColor,
                                 fontWeight: FontWeight.bold,
                                 fontSize: 12,
                               ),
                             ),
                             GestureDetector(
                               onTap: () => context.goNamed('Login'),
                               child: Row(
                                 children: [
                                   Text(
                                     'Chi tiết',
                                     style: TextStyle(
                                       color: context.colors.text,
                                       fontWeight: FontWeight.w600,
                                       fontSize: 12,
                                     ),
                                   ),
                                   const SizedBox(width: 4),
                                   Icon(Icons.arrow_forward_rounded, size: 14, color: context.colors.text),
                                 ],
                               ),
                             ),
                           ],
                         ),
                       ],
                     ),
                   ),
                 ],
               ),
             ),
           ),
        )),
      ],
    );
  }

  Widget _buildCTA(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Sẵn Sàng Nâng Tầm Hệ Thống Của Bạn?',
            style: context.typography.h2.copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Gia nhập cộng đồng quản trị viên chuyên nghiệp và trải nghiệm công nghệ hàng đầu thế giới ngay hôm nay.',
            style: context.typography.bodyMuted.copyWith(fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          AppButton(
            label: 'Bắt Đầu Miễn Phí',
            icon: Icons.rocket_launch_outlined,
            onPressed: () => context.goNamed('Register'),
          ),
        ],
      ),
    );
  }
}
