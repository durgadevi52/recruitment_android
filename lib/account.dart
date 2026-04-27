import 'package:flutter/material.dart';
import 'package:recruitment/api.dart';
import 'package:recruitment/app_shell.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  static const Color primary = Color(0xFF4C63F1);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late Future<ProfileData> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = AppSession.instance.api.getProfile();
  }

  Future<void> _reload() async {
    setState(() {
      _profileFuture = AppSession.instance.api.getProfile();
    });
    await _profileFuture;
  }

  @override
  Widget build(BuildContext context) {
    return AppPageLayout(
      selectedTab: AppTab.profile,
      sectionLabel: 'Profile',
      title: 'Profile',
      subtitle: 'Manage user details and recent activity.',
      titleTrailing: const AppTopAction(icon: Icons.person_outline_rounded),
      child: FutureBuilder<ProfileData>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : 'Unable to load profile.';
            return _ProfileErrorCard(message: message, onRetry: _reload);
          }

          final profile = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileCard(profile),
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
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.32,
                children: [
                  _PerformanceCard(
                    value: '${profile.activity.managedApplications}',
                    label: 'Managed Applications',
                    accent: const Color(0xFF4C63F1),
                  ),
                  _PerformanceCard(
                    value: '${profile.activity.assignedApplications}',
                    label: 'Assigned Applications',
                    accent: const Color(0xFF7C3AED),
                  ),
                  _PerformanceCard(
                    value: profile.designation?.shortName ?? '--',
                    label: 'Designation',
                    accent: const Color(0xFFF59E0B),
                  ),
                  _PerformanceCard(
                    value: profile.branch?.code ?? '--',
                    label: 'Branch Code',
                    accent: const Color(0xFF06B6D4),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              const Text(
                'RECENT LOGINS',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF7B8498),
                ),
              ),
              const SizedBox(height: 14),
              ...profile.recentLogins.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _LoginHistoryCard(item: item),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(ProfileData profile) {
    final initials = profile.name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

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
            child: Text(
              initials.isEmpty ? 'U' : initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        profile.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AccountScreen.textPrimary,
                        ),
                      ),
                    ),
                    _StatusPill(label: profile.isActive ? 'Active' : 'Inactive'),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Code: ${profile.employeeCode}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AccountScreen.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Email: ${profile.email}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AccountScreen.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Role: ${profile.role.name}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AccountScreen.textSecondary,
                  ),
                ),
                if (profile.branch != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Branch: ${profile.branch!.name}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AccountScreen.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
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

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard({
    required this.value,
    required this.label,
    required this.accent,
  });

  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border(top: BorderSide(color: accent, width: 3)),
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
            value,
            style: TextStyle(
              fontSize: 28,
              height: 1,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: AccountScreen.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginHistoryCard extends StatelessWidget {
  const _LoginHistoryCard({required this.item});

  final LoginSessionInfo item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: item.status == 'success'
                        ? const Color(0xFF129B62)
                        : const Color(0xFFE45B72),
                  ),
                ),
              ),
              Text(
                item.ipAddress ?? '--',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AccountScreen.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Login: ${item.loggedInAt ?? '--'}',
            style: const TextStyle(color: AccountScreen.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Logout: ${item.loggedOutAt ?? 'Session open'}',
            style: const TextStyle(color: AccountScreen.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ProfileErrorCard extends StatelessWidget {
  const _ProfileErrorCard({
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
          const Icon(Icons.account_circle_outlined, size: 42, color: Color(0xFF9AA1B1)),
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
