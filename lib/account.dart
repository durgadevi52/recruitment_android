import 'package:flutter/material.dart';
import 'package:recruitment/allcandidates.dart';
import 'package:recruitment/dashboard.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  static const Color _primary = Color(0xFF4C63F1);
  static const Color _pageBackground = Color(0xFFF4F7FC);
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _textSecondary = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    const performanceItems = [
      _PerformanceItem(
        value: '0',
        label: 'Total Managed',
        accent: Color(0xFF4C63F1),
      ),
      _PerformanceItem(
        value: '0',
        label: 'Awaiting Pre-Screen',
        accent: Color(0xFF7C3AED),
      ),
      _PerformanceItem(
        value: '0',
        label: 'LEVEL 2',
        accent: Color(0xFFF59E0B),
      ),
      _PerformanceItem(
        value: '0',
        label: 'LEVEL 3',
        accent: Color(0xFF8B5CF6),
      ),
      _PerformanceItem(
        value: '0',
        label: 'LEVEL 4 / Salary',
        accent: Color(0xFF06B6D4),
      ),
      _PerformanceItem(
        value: '0',
        label: 'Joined',
        accent: Color(0xFF10B981),
      ),
      _PerformanceItem(
        value: '0',
        label: 'Offers Released',
        accent: Color(0xFF60A5FA),
      ),
      _PerformanceItem(
        value: '0',
        label: 'On Hold',
        accent: Color(0xFFF59E0B),
      ),
      _PerformanceItem(
        value: '0',
        label: 'Rejected',
        accent: Color(0xFFEF4444),
      ),
    ];

    const hrStaff = [
      _HrStaffItem(
        initials: 'JE',
        name: 'Jerome S',
        role: 'HR',
        total: '2',
        passed: '2',
        atL2: '1',
        atL4: '1',
      ),
      _HrStaffItem(
        initials: 'NA',
        name: 'Nandhini',
        role: 'HR',
        total: '0',
        passed: '0',
      ),
      _HrStaffItem(
        initials: 'SU',
        name: 'Super Administrator',
        role: 'Super Admin',
        total: '0',
        passed: '0',
      ),
      _HrStaffItem(
        initials: 'VI',
        name: 'Vinoth S',
        role: 'HR',
        total: '0',
        passed: '0',
      ),
    ];

    return Scaffold(
      backgroundColor: _pageBackground,
      bottomNavigationBar: _buildBottomNav(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 42,
                    height: 42,
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
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: _primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildProfileCard(),
              const SizedBox(height: 26),
              const Text(
                'MY PERFORMANCE',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF7B8498),
                ),
              ),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: performanceItems.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.36,
                ),
                itemBuilder: (context, index) {
                  return _PerformanceCard(item: performanceItems[index]);
                },
              ),
              const SizedBox(height: 12),
              _buildClosureCard(),
              const SizedBox(height: 26),
              const Text(
                'HR STAFF PERFORMANCE OVERVIEW',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF7B8498),
                ),
              ),
              const SizedBox(height: 14),
              ...hrStaff.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _HrStaffCard(item: item),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4C63F1), Color(0xFF2656E8)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: const Text(
              'SU',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Super Administrator',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                    _StatusPill(label: 'Active'),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'Code: SUPER001',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textSecondary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Email: superadmin@patgroup.com',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _textSecondary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Role: Super Admin',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClosureCard() {
    const items = [
      _ClosureMetric(label: 'Not Responding', value: '0', color: Color(0xFFEF4444)),
      _ClosureMetric(label: 'Rejected', value: '0', color: Color(0xFFEF4444)),
      _ClosureMetric(label: 'No Vacancy', value: '0', color: Color(0xFF3B82F6)),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PRE-SCREEN CLOSURE',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w800,
              color: Color(0xFF818AA0),
            ),
          ),
          const SizedBox(height: 14),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    item.value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: item.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
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
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const DashboardScreen(),
                ),
              );
            },
          ),
          _BottomNavItem(
            icon: Icons.group_outlined,
            label: 'ALL CANDIDATES',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const AllCandidatesScreen(),
                ),
              );
            },
          ),
          const _BottomNavItem(
            icon: Icons.insert_chart_outlined_rounded,
            label: 'INSIGHTS',
          ),
          const _BottomNavItem(
            icon: Icons.person_outline_rounded,
            label: 'PROFILE',
            selected: true,
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAFBF3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF129B62),
        ),
      ),
    );
  }
}

class _PerformanceItem {
  const _PerformanceItem({
    required this.value,
    required this.label,
    required this.accent,
  });

  final String value;
  final String label;
  final Color accent;
}

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard({required this.item});

  final _PerformanceItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border(top: BorderSide(color: item.accent, width: 3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.value,
            style: TextStyle(
              fontSize: 28,
              height: 1,
              fontWeight: FontWeight.w800,
              color: item.accent,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: AccountScreen._textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosureMetric {
  const _ClosureMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;
}

class _HrStaffItem {
  const _HrStaffItem({
    required this.initials,
    required this.name,
    required this.role,
    required this.total,
    required this.passed,
    this.atL2 = '0',
    this.atL4 = '0',
  });

  final String initials;
  final String name;
  final String role;
  final String total;
  final String passed;
  final String atL2;
  final String atL4;
}

class _HrStaffCard extends StatelessWidget {
  const _HrStaffCard({required this.item});

  final _HrStaffItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EEFF),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  item.initials,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AccountScreen._primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AccountScreen._textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.role,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AccountScreen._textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFEEF3FF),
                  foregroundColor: AccountScreen._primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'View',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: 'Total',
                  value: item.total,
                  color: const Color(0xFF111827),
                ),
              ),
              Expanded(
                child: _MiniMetric(
                  label: 'PS Passed',
                  value: item.passed,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              Expanded(
                child: _MiniMetric(
                  label: 'At L2',
                  value: item.atL2,
                  color: const Color(0xFFF59E0B),
                ),
              ),
              Expanded(
                child: _MiniMetric(
                  label: 'At L4',
                  value: item.atL4,
                  color: const Color(0xFF06B6D4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AccountScreen._textSecondary,
          ),
        ),
      ],
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.selected = false,
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
          color: selected ? AccountScreen._primary : Colors.transparent,
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
