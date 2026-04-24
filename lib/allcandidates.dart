import 'package:flutter/material.dart';
import 'package:recruitment/account.dart';
import 'package:recruitment/dashboard.dart';

class AllCandidatesScreen extends StatefulWidget {
  const AllCandidatesScreen({super.key});

  @override
  State<AllCandidatesScreen> createState() => _AllCandidatesScreenState();
}

class _AllCandidatesScreenState extends State<AllCandidatesScreen> {
  static const Color _primary = Color(0xFF315DE7);
  static const Color _accent = Color(0xFF5447E8);
  static const Color _pageBackground = Color(0xFFF7F7FA);
  static const Color _textPrimary = Color(0xFF141824);
  static const Color _textSecondary = Color(0xFF6F7484);
  static const Color _chipBackground = Color(0xFFE8E9ED);

  DateTime? _selectedDate;
  String _selectedExperience = 'All';

  final List<_Candidate> _candidates = const [
    _Candidate(
      name: 'Durgadevi',
      email: 'durgadevi@example.com',
      gender: 'Female',
      experience: 'Fresher',
      degree: 'UG-BSc',
      date: '09 APR 2026',
      avatarText: 'D',
      avatarColor: Color(0xFFB5C0FF),
    ),
    _Candidate(
      name: 'Rajesh Kumar',
      email: 'rajesh.k@workmail.com',
      gender: 'Male',
      experience: '2 Years Exp',
      degree: 'UG-BTech',
      date: '08 APR 2026',
      avatarText: 'R',
      avatarColor: Color(0xFFD7DEFF),
    ),
    _Candidate(
      name: 'Anjali Sharma',
      email: 'anjali.sh@email.com',
      gender: 'Female',
      experience: 'Fresher',
      degree: 'PG-MBA',
      date: '07 APR 2026',
      avatarText: 'A',
      avatarColor: Color(0xFFFFB27D),
    ),
  ];

  List<_Candidate> get _filteredCandidates {
    return _candidates.where((candidate) {
      final matchesDate = _selectedDate == null ||
          candidate.date == _formatDate(_selectedDate!);
      final matchesExperience = _selectedExperience == 'All' ||
          (_selectedExperience == 'Fresher' &&
              candidate.experience == 'Fresher') ||
          (_selectedExperience == '1-3 Years' &&
              candidate.experience == '2 Years Exp') ||
          (_selectedExperience == '3+ Years' &&
              candidate.experience.contains('3'));

      return matchesDate && matchesExperience;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      bottomNavigationBar: _buildBottomNav(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // _buildHeader(),
              const SizedBox(height: 12),
              const Text(
                'Candidates',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              // const Text(
              //   'Reviewing potential future team members',
              //   style: TextStyle(
              //     fontSize: 15,
              //     color: _textSecondary,
              //   ),
              // ),
              // const SizedBox(height: 24),
              _buildSearchField(),
              const SizedBox(height: 32),
              _buildSectionLabel('DATE FILTER'),
              const SizedBox(height: 14),
              _buildDatePickerField(),
              const SizedBox(height: 30),
              _buildSectionLabel('Experience'),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildFilterChip(
                    label: 'All',
                    selected: _selectedExperience == 'All',
                    onTap: () => setState(() => _selectedExperience = 'All'),
                  ),
                  _buildFilterChip(
                    label: 'Fresher',
                    selected: _selectedExperience == 'Fresher',
                    onTap: () => setState(() => _selectedExperience = 'Fresher'),
                  ),
                  _buildFilterChip(
                    label: '1-3\nYears',
                    selected: _selectedExperience == '1-3 Years',
                    onTap: () =>
                        setState(() => _selectedExperience = '1-3 Years'),
                  ),
                  _buildFilterChip(
                    label: '3+\nYears',
                    selected: _selectedExperience == '3+ Years',
                    onTap: () => setState(() => _selectedExperience = '3+ Years'),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              ..._filteredCandidates.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 22),
                  child: _CandidateCard(
                    candidate: entry.value,
                    count: entry.key + 1,
                    onApply: () => _showNewApplicationDialog(entry.value),
                  ),
                ),
              ),
              if (_filteredCandidates.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'No candidates found for this filter.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: _textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
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
            selected: true,
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

  // Widget _buildHeader() {
  //   return Row(
  //     children: [
  //       const Icon(Icons.menu_rounded, color: _primary, size: 28),
  //       const SizedBox(width: 14),
  //       const Text(
  //         'Talent Scout',
  //         style: TextStyle(
  //           fontSize: 18,
  //           fontWeight: FontWeight.w700,
  //           color: _primary,
  //         ),
  //       ),
  //       const Spacer(),
  //       _HeaderIconButton(icon: Icons.search_rounded, onTap: () {}),
  //       const SizedBox(width: 10),
  //       _HeaderIconButton(icon: Icons.notifications_rounded, onTap: () {}),
  //     ],
  //   );
  // }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EAEE),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        children: [
          Icon(Icons.search_rounded, color: _textSecondary, size: 24),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Search by name or email...',
              style: TextStyle(
                fontSize: 17,
                color: Color(0xFF747A8B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        letterSpacing: 2.4,
        fontWeight: FontWeight.w700,
        color: Color(0xFF80859A),
      ),
    );
  }

  Widget _buildDatePickerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFDCE1EA)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  color: _primary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedDate == null
                        ? 'Select candidate date'
                        : _formatDate(_selectedDate!),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _selectedDate == null
                          ? const Color(0xFF8A92A6)
                          : _textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF7E879A),
                ),
              ],
            ),
          ),
        ),
        if (_selectedDate != null) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedDate = null;
              });
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Clear date filter',
              style: TextStyle(
                color: _primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2026, 4, 9),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _selectedDate = pickedDate;
    });
  }

  String _formatDate(DateTime date) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];

    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];

    return '$day $month ${date.year}';
  }

  Future<void> _showNewApplicationDialog(_Candidate candidate) async {
    final notesController = TextEditingController();
    String? selectedHrManager;
    String? selectedInterviewer;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 24,
              ),
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'NEW APPLICATION',
                                  style: TextStyle(
                                    color: _accent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'New Application — ${candidate.name}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: _textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.of(dialogContext).pop(),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F8),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Color(0xFF8B92A3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE8EAF1)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF3FF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFC7D4FF),
                              ),
                            ),
                            child: const Text(
                              'Position and target branch will be set during the pre-screening call.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6170C9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _ApplicationField(
                                  label: 'HR Manager',
                                  child: _ApplicationDropdown(
                                    value: selectedHrManager,
                                    hint: 'Select HR Manager',
                                    items: const [
                                      'Harini',
                                      'Meena',
                                      'Suresh',
                                    ],
                                    onChanged: (value) {
                                      setDialogState(() {
                                        selectedHrManager = value;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ApplicationField(
                                  label: 'Assign L1 Interviewer',
                                  child: _ApplicationDropdown(
                                    value: selectedInterviewer,
                                    hint: 'Select Interviewer',
                                    items: const [
                                      'Vinoth',
                                      'Karthik',
                                      'Priya',
                                    ],
                                    onChanged: (value) {
                                      setDialogState(() {
                                        selectedInterviewer = value;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _ApplicationField(
                            label: 'Remarks / Notes',
                            child: TextField(
                              controller: notesController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                hintText: 'Any initial notes...',
                                hintStyle: const TextStyle(
                                  color: Color(0xFFA1A8B8),
                                  fontSize: 13,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD6DBE7),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD6DBE7),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: _accent,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF5849F0),
                                          Color(0xFF4A42DA),
                                        ],
                                      ),
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(dialogContext).pop();
                                        ScaffoldMessenger.of(this.context)
                                          ..hideCurrentSnackBar()
                                          ..showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Application created for ${candidate.name}',
                                              ),
                                            ),
                                          );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        elevation: 0,
                                        shadowColor: Colors.transparent,
                                        backgroundColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Text(
                                        'Create Application',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                height: 48,
                                child: OutlinedButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Color(0xFFD2D7E3),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    foregroundColor: const Color(0xFF4C5264),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
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
          },
        );
      },
    );

    notesController.dispose();
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? _primary : _chipBackground,
          borderRadius: BorderRadius.circular(24),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x25315DE7),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : const Color(0xFF27304A),
          ),
        ),
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.candidate,
    required this.count,
    required this.onApply,
  });

  final _Candidate candidate;
  final int count;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: candidate.avatarColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  candidate.avatarText,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF27304A),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7EAFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Applications : $count',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF35478C),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      candidate.name,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF151926),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      candidate.email,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4E5566),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F1F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  candidate.date,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7B8194),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _InfoChip(
                label: candidate.gender,
                backgroundColor: const Color(0xFFE7EAFF),
                textColor: const Color(0xFF35478C),
              ),
              const SizedBox(width: 10),
              _InfoChip(
                label: candidate.experience,
                backgroundColor: const Color(0xFFFFDDCB),
                textColor: const Color(0xFF8B421B),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: _InfoChip(
                  label: candidate.degree,
                  backgroundColor: const Color(0xFFE7E8ED),
                  textColor: const Color(0xFF343A4A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'View',
                  onTap: () {},
                  backgroundColor: const Color(0xFFE8E9ED),
                  textColor: const Color(0xFF1D4FE2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ActionButton(
                  label: 'Apply',
                  onTap: onApply,
                  backgroundColor: const Color(0xFF3C63E8),
                  textColor: Colors.white,
                  addShadow: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ApplicationField extends StatelessWidget {
  const _ApplicationField({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF555D6E),
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _ApplicationDropdown extends StatelessWidget {
  const _ApplicationDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final String? value;
  final String hint;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD6DBE7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD6DBE7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _AllCandidatesScreenState._accent),
        ),
      ),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Color(0xFF6C7385),
      ),
      hint: Text(
        hint,
        style: const TextStyle(
          color: Color(0xFF4C5264),
          fontSize: 13,
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(
                  color: Color(0xFF2D3445),
                  fontSize: 13,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
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
          color: selected ? const Color(0xFF5B4CF0) : Colors.transparent,
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

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(icon, color: const Color(0xFF66758E), size: 28),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    required this.backgroundColor,
    required this.textColor,
    this.addShadow = false,
  });

  final String label;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color textColor;
  final bool addShadow;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: addShadow
            ? const [
                BoxShadow(
                  color: Color(0x26315DE7),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: SizedBox(
        height: 54,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: textColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _Candidate {
  const _Candidate({
    required this.name,
    required this.email,
    required this.gender,
    required this.experience,
    required this.degree,
    required this.date,
    required this.avatarText,
    required this.avatarColor,
  });

  final String name;
  final String email;
  final String gender;
  final String experience;
  final String degree;
  final String date;
  final String avatarText;
  final Color avatarColor;
}
