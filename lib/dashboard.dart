import 'package:flutter/material.dart';
import 'package:recruitment/allcandidates.dart';
import 'package:recruitment/api.dart';
import 'package:recruitment/app_shell.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<DashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = AppSession.instance.api.getDashboard();
  }

  Future<void> _reload() async {
    setState(() {
      _dashboardFuture = AppSession.instance.api.getDashboard();
    });
    await _dashboardFuture;
  }

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
    final user = AppSession.instance.user;
    final greeting = _greetingForHour(DateTime.now().hour);

    return AppPageLayout(
      selectedTab: AppTab.dashboard,
      sectionLabel: 'Dashboard',
      title: '$greeting, ${user?.name.split(' ').first ?? 'User'}',
      subtitle: 'Recruitment overview from live API data.',
      titleTrailing: const AppTopAction(icon: Icons.dashboard_customize_rounded),
      child: FutureBuilder<DashboardData>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : 'Unable to load dashboard data.';
            return _ErrorCard(message: message, onRetry: _reload);
          }

          final data = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.28,
                children: [
                  _StatCard(
                    icon: Icons.assignment_turned_in_outlined,
                    iconBg: const Color(0xFFF1EEFF),
                    iconColor: AppShell.primary,
                    value: '${data.stats.todayApplications}',
                    label: 'TODAY\nAPPLICATIONS',
                  ),
                  _StatCard(
                    icon: Icons.groups_2_outlined,
                    iconBg: const Color(0xFFF8ECFF),
                    iconColor: const Color(0xFFD055F5),
                    value: '${data.stats.onHold}',
                    label: 'ON\nHOLD',
                  ),
                  _StatCard(
                    icon: Icons.person_add_alt_1_outlined,
                    iconBg: const Color(0xFFEAF8F4),
                    iconColor: const Color(0xFF48A987),
                    value: '${data.stats.joinedThisMonth}',
                    label: 'JOINED THIS\nMONTH',
                  ),
                  _StatCard(
                    icon: Icons.mail_outline_rounded,
                    iconBg: const Color(0xFFFFEFF2),
                    iconColor: const Color(0xFFE45B72),
                    value: '${data.stats.offersReleased}',
                    label: 'OFFERS\nRELEASED',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _OverviewCard(manpower: data.manpower),
              const SizedBox(height: 24),
              const Text(
                'Recruitment Funnel',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppShell.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              _FunnelCard(
                level: 'Pre-Screening',
                badge: 'PENDING ${data.stats.pendingL1}',
                progress: _toProgress(data.stats.pendingL1, data.stats.totalApplications),
              ),
              const SizedBox(height: 12),
              _FunnelCard(
                level: 'Level 2',
                badge: 'PENDING ${data.stats.pendingL2}',
                progress: _toProgress(data.stats.pendingL2, data.stats.totalApplications),
              ),
              const SizedBox(height: 12),
              _FunnelCard(
                level: 'Level 3',
                badge: 'PENDING ${data.stats.pendingL3}',
                progress: _toProgress(data.stats.pendingL3, data.stats.totalApplications),
              ),
              const SizedBox(height: 12),
              _FunnelCard(
                level: 'Salary Finalisation',
                badge: 'PENDING ${data.stats.pendingL4}',
                progress: _toProgress(data.stats.pendingL4, data.stats.totalApplications),
              ),
              const SizedBox(height: 24),
              const Text(
                'Designation Strength',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppShell.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              _buildTableCard(data.manpower.designations),
              const SizedBox(height: 24),
              const Text(
                'Recent Applications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppShell.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              ...data.recentApplications.map(
                (application) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RecentApplicationCard(application: application),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  double _toProgress(int value, int total) {
    if (total <= 0) {
      return 0;
    }
    final raw = value / total;
    return raw.clamp(0.0, 1.0);
  }

  Widget _buildTableCard(List<DesignationStrength> rows) {
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
              border: Border(bottom: BorderSide(color: Color(0xFFF0F1F5))),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('ROLE', style: _TableHeaderStyle.textStyle)),
                Expanded(
                  flex: 2,
                  child: Text('REQ', style: _TableHeaderStyle.textStyle, textAlign: TextAlign.center),
                ),
                Expanded(
                  flex: 2,
                  child: Text('CUR', style: _TableHeaderStyle.textStyle, textAlign: TextAlign.center),
                ),
                Expanded(
                  flex: 2,
                  child: Text('VAC', style: _TableHeaderStyle.textStyle, textAlign: TextAlign.right),
                ),
              ],
            ),
          ),
          for (final row in rows)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF3F4F8))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      row.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3A4050),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('${row.requiredCount}', textAlign: TextAlign.center),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('${row.currentCount}', textAlign: TextAlign.center),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${row.vacancy}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
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
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.manpower});

  final ManpowerData manpower;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2E313D),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manpower Overview',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _OverviewItem(title: 'OPEN VACANCIES', value: '${manpower.totalVacancy}'),
              ),
              Expanded(
                child: _OverviewItem(title: 'CURRENT STRENGTH', value: '${manpower.totalCurrent}'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _OverviewItem(title: 'REQUIRED', value: '${manpower.totalRequired}'),
              ),
              Expanded(
                child: _OverviewItem(
                  title: 'FILL RATE',
                  value: '${manpower.fillRate}%',
                  highlight: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentApplicationCard extends StatelessWidget {
  const _RecentApplicationCard({required this.application});

  final ApplicationSummary application;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => AllCandidatesScreen(openApplicationId: application.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE7EAFF),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                application.candidateName.isEmpty ? '?' : application.candidateName[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppShell.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    application.candidateName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppShell.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${application.position} • ${application.branch}',
                    style: const TextStyle(fontSize: 12, color: AppShell.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1EEFF),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                application.statusLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppShell.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 42, color: Color(0xFF9AA1B1)),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => onRetry(),
            child: const Text('Retry'),
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
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
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
    final percent = '${(progress * 100).round()}% of total';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                level,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppShell.primary,
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
                    color: AppShell.primary,
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
              valueColor: const AlwaysStoppedAnimation<Color>(AppShell.primary),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Status progress',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF7E8596)),
              ),
              const Spacer(),
              Text(
                percent,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF7E8596)),
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

class _TableHeaderStyle {
  static const textStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: Color(0xFF9AA1B1),
  );
}
