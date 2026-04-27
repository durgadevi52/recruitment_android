import 'package:flutter/material.dart';
import 'package:recruitment/account.dart';
import 'package:recruitment/allcandidates.dart';
import 'package:recruitment/dashboard.dart';

enum AppTab { dashboard, candidates, profile }

class AppShell {
  static const Color primary = Color(0xFF5B4CF0);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textPrimary = Color(0xFF252B37);
  static const Color textSecondary = Color(0xFF8C93A3);
}

class AppPageLayout extends StatelessWidget {
  const AppPageLayout({
    super.key,
    required this.selectedTab,
    required this.sectionLabel,
    required this.title,
    this.subtitle,
    this.titleTrailing,
    required this.child,
  });

  final AppTab selectedTab;
  final String sectionLabel;
  final String title;
  final String? subtitle;
  final Widget? titleTrailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppShell.background,
      bottomNavigationBar: AppBottomNav(selectedTab: selectedTab),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppPageHeader(sectionLabel: sectionLabel),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppShell.textPrimary,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppShell.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (titleTrailing != null) ...[
                    const SizedBox(width: 12),
                    titleTrailing!,
                  ],
                ],
              ),
              const SizedBox(height: 20),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class AppPageHeader extends StatelessWidget {
  const AppPageHeader({super.key, required this.sectionLabel});

  final String sectionLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.menu_rounded, color: AppShell.primary, size: 22),
        const SizedBox(width: 10),
        Text(
          sectionLabel.toUpperCase(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppShell.primary,
            letterSpacing: 0.8,
          ),
        ),
        const Spacer(),
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: Color(0xFF272A35),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text(
            'S',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class AppTopAction extends StatelessWidget {
  const AppTopAction({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: AppShell.primary),
    );
  }
}

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.selectedTab});

  final AppTab selectedTab;

  void _openTab(BuildContext context, AppTab tab) {
    if (tab == selectedTab) {
      return;
    }

    final screen = switch (tab) {
      AppTab.dashboard => const DashboardScreen(),
      AppTab.candidates => const AllCandidatesScreen(),
      AppTab.profile => const AccountScreen(),
    };

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomNavItem(
            icon: Icons.home_filled,
            label: 'DASHBOARD',
            selected: selectedTab == AppTab.dashboard,
            onTap: () => _openTab(context, AppTab.dashboard),
          ),
          _BottomNavItem(
            icon: Icons.group_outlined,
            label: 'ALL CANDIDATES',
            selected: selectedTab == AppTab.candidates,
            onTap: () => _openTab(context, AppTab.candidates),
          ),
          _BottomNavItem(
            icon: Icons.person_outline_rounded,
            label: 'PROFILE',
            selected: selectedTab == AppTab.profile,
            onTap: () => _openTab(context, AppTab.profile),
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppShell.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? Colors.white : const Color(0xFF9CA4B6),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : const Color(0xFF9CA4B6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
