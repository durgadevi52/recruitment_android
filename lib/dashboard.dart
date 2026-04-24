import 'package:flutter/material.dart';
import 'package:recruitment/account.dart';
import 'package:recruitment/allcandidates.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const Color _primary = Color(0xFF5B4CF0);
  static const Color _pageBackground = Color(0xFFF6F7FB);
  static const Color _darkCard = Color(0xFF2E313D);

  String _greetingForHour(int hour) {
    if (hour < 12) {
      return 'Good morning';
    }
    if (hour < 17) {
      return 'Good afternoon';
    }
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _greetingForHour(DateTime.now().hour);

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(),
                    const SizedBox(height: 24),
                    Text(
                      '$greeting, Super',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF252B37),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tuesday, October 24, 2023',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8C93A3),
                      ),
                    ),
                    const SizedBox(height: 18),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.28,
                      children: const [
                        _StatCard(
                          icon: Icons.assignment_turned_in_outlined,
                          iconBg: Color(0xFFF1EEFF),
                          iconColor: _primary,
                          value: '2',
                          label: 'JOINING\nPENDING',
                        ),
                        _StatCard(
                          icon: Icons.groups_2_outlined,
                          iconBg: Color(0xFFF8ECFF),
                          iconColor: Color(0xFFD055F5),
                          value: '12',
                          label: 'ON\nHOLD',
                        ),
                        _StatCard(
                          icon: Icons.person_add_alt_1_outlined,
                          iconBg: Color(0xFFEAF8F4),
                          iconColor: Color(0xFF48A987),
                          value: '0',
                          label: 'JOINED THIS\nMONTH',
                        ),
                        _StatCard(
                          icon: Icons.notifications_active_outlined,
                          iconBg: Color(0xFFFFEFF2),
                          iconColor: Color(0xFFE45B72),
                          value: '0',
                          label: 'SALARY\n FINALAIZED',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildOverviewCard(),
                    const SizedBox(height: 24),
                    const Text(
                      'Recruitment Funnel',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF252B37),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _FunnelCard(
                      level: 'Level 1',
                      badge: 'AWAITING 8',
                      progress: 0.15,
                    ),
                    const SizedBox(height: 12),
                    const _FunnelCard(
                      level: 'Level 2',
                      badge: 'AWAITING 2',
                      progress: 0.05,
                    ),
                    const SizedBox(height: 12),
                    const _FunnelCard(
                      level: 'Level 3',
                      badge: 'AWAITING 1',
                      progress: 0.08,
                    ),
                    const SizedBox(height: 12),
                    const _FunnelCard(
                      level: 'Offer Release',
                      badge: 'FINALIZED 3',
                      progress: 0.18,
                    ),
                    // const SizedBox(height: 12),
                    // const _FunnelCard(
                    //   level: 'On Hold',
                    //   badge: 'ON HOLD 4',
                    //   progress: 0.07,
                    // ),
                    const SizedBox(height: 24),
                    Row(
                      children: const [
                        Expanded(
                          child: Text(
                            'Designation Strength',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF252B37),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF81889B),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildTableCard(),
                  ],
                ),
              ),
            ),
            _buildBottomNav(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        const Icon(Icons.menu, color: _primary, size: 20),
        const SizedBox(width: 8),
        const Text(
          'DASHBOARD',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _primary,
          ),
        ),
        const Spacer(),
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            color: Color(0xFF272A35),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text(
            'S',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _darkCard,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manpower Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: const [
              // Expanded(
              //   child: _OverviewItem(
              //     title: 'TOTAL REQUIRED',
              //     value: '869',
              //   ),
              // ),
              Expanded(
                child: _OverviewItem(
                  title: 'OPEN VACANCIES',
                  value: '869',
                ),
              ),
              Expanded(
                child: _OverviewItem(
                  title: 'CURRENT STRENGTH',
                  value: '0',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: const [
           
              // Expanded(
              //   child: _OverviewItem(
              //     title: 'FILL RATE',
              //     value: '0%',
              //     highlight: true,
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableCard() {
    const rows = [
      ['BM', '120', '0', '120'],
      ['ABM', '85', '0', '85'],
      ['BA', '450', '0', '450'],
      ['BRO', '214', '0', '214'],
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFF0F1F5)),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'ROLE',
                    style: _TableHeaderStyle.textStyle,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'REQ',
                    style: _TableHeaderStyle.textStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'CUR',
                    style: _TableHeaderStyle.textStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'VAC',
                    style: _TableHeaderStyle.textStyle,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          for (final row in rows)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFF3F4F8)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      row[0],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3A4050),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      row[1],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF5E6678),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      row[2],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF5E6678),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      row[3],
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFF6F61),
                      ),
                    ),
                  ),
                ],
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
            selected: true,
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
          _BottomNavItem(
            icon: Icons.insert_chart_outlined_rounded,
            label: 'INSIGHTS',
          ),
          _BottomNavItem(
            icon: Icons.person_outline_rounded,
            label: 'PROFILE',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const AccountScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 30,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF252B37),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF737B8F),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _FunnelCard extends StatelessWidget {
  const _FunnelCard({
    required this.level,
    required this.badge,
    required this.progress,
  });

  final String level;
  final String badge;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final percent = '${(progress * 100).round()}% processed';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                level,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: DashboardScreen._primary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2EEFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: DashboardScreen._primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: progress,
              backgroundColor: const Color(0xFFE7E8ED),
              valueColor: const AlwaysStoppedAnimation<Color>(
                DashboardScreen._primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Status progress',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7E8596),
                ),
              ),
              const Spacer(),
              Text(
                percent,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7E8596),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewItem extends StatelessWidget {
  const _OverviewItem({
    required this.title,
    required this.value,
    this.highlight = false,
  });

  final String title;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 9,
            letterSpacing: 0.8,
            color: Color(0xFF9EA4B5),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            height: 1,
            fontWeight: FontWeight.w700,
            color: highlight ? const Color(0xFF79E5E4) : Colors.white,
          ),
        ),
      ],
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  _BottomNavItem({
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
          color: selected ? DashboardScreen._primary : Colors.transparent,
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

class _TableHeaderStyle {
  static const textStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: Color(0xFF9AA1B1),
  );
}
