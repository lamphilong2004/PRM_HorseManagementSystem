import 'package:flutter/material.dart';

import '../core/api/api_service.dart';
import '../ui/app_theme.dart';

// Tabs
import 'owner_tabs/owner_horses_tab.dart';
import 'owner_tabs/owner_registration_tab.dart';
import 'owner_tabs/owner_hire_jockey_tab.dart';
import 'owner_tabs/owner_invitations_tab.dart';
import 'owner_tabs/owner_history_tab.dart';

class HorsesScreen extends StatefulWidget {
  const HorsesScreen({super.key, required this.api});

  final ApiService api;

  @override
  State<HorsesScreen> createState() => _HorsesScreenState();
}

class _HorsesScreenState extends State<HorsesScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: context.colors.bg,
        appBar: AppBar(
          backgroundColor: context.colors.surface,
          elevation: 0,
          title: Text('Quản lý Ngựa', style: context.typography.h2),
          centerTitle: true,
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: context.colors.primary,
            labelColor: context.colors.primary,
            unselectedLabelColor: context.colors.muted,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'Ngựa của tôi'),
              Tab(text: 'Đăng ký đua'),
              Tab(text: 'Thuê nài ngựa'),
              Tab(text: 'Lời mời'),
              Tab(text: 'Lịch sử'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            OwnerHorsesTab(api: widget.api),
            OwnerRegistrationTab(api: widget.api),
            OwnerHireJockeyTab(api: widget.api),
            OwnerInvitationsTab(api: widget.api),
            OwnerHistoryTab(api: widget.api),
          ],
        ),
      ),
    );
  }
}
