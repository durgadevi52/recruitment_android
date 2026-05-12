import 'dart:async';

import 'package:flutter/material.dart';
import 'package:recruitment/api.dart';
import 'package:recruitment/app_shell.dart';
import 'package:url_launcher/url_launcher.dart';

class AllCandidatesScreen extends StatefulWidget {
  const AllCandidatesScreen({super.key, this.openApplicationId});

  final int? openApplicationId;

  @override
  State<AllCandidatesScreen> createState() => _AllCandidatesScreenState();
}

class _AllCandidatesScreenState extends State<AllCandidatesScreen> {
  static const Color _accent = Color(0xFF5447E8);
  static const Color _textPrimary = Color(0xFF141824);
  static const Color _textSecondary = Color(0xFF6F7484);

  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  bool _loadingMore = false;
  String? _errorMessage;
  String? _selectedGender;
  String? _selectedExperience;
  int _rowsToShow = 25;
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalCandidates = 0;
  final List<ApplicantLookup> _candidates = [];
  final ScrollController _tableHorizontalController = ScrollController();
  final ScrollController _tableVerticalController = ScrollController();

  @override
  void initState() {
    super.initState();
    unawaited(_loadInitial());
    if (widget.openApplicationId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openApplicationDetail(widget.openApplicationId!);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tableHorizontalController.dispose();
    _tableVerticalController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final page = await AppSession.instance.api.getApplicants(
        search: _searchController.text,
        gender: _selectedGender,
        experience: _selectedExperience,
        perPage: _rowsToShow,
      );
      setState(() {
        _candidates
          ..clear()
          ..addAll(page.items);
        _currentPage = page.currentPage;
        _lastPage = page.lastPage;
        _totalCandidates = page.total;
      });
    } on ApiException catch (error) {
      setState(() {
        _errorMessage = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _currentPage >= _lastPage) {
      return;
    }

    setState(() {
      _loadingMore = true;
    });
    try {
      final page = await AppSession.instance.api.getApplicants(
        search: _searchController.text,
        gender: _selectedGender,
        experience: _selectedExperience,
        page: _currentPage + 1,
        perPage: _rowsToShow,
      );
      setState(() {
        _candidates.addAll(page.items);
        _currentPage = page.currentPage;
        _lastPage = page.lastPage;
        _totalCandidates = page.total;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _openApplicationDetail(int id) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _ApplicationDetailScreen(applicationId: id),
      ),
    );
  }

  Future<void> _showCreateApplicationDialog({
    String? initialSearch,
    ApplicationSummary? initialApplication,
    ApplicantLookup? initialApplicant,
  }) async {
    final applicationToApply = initialApplication;
    final applicantToApply = initialApplicant;
    final lockedApplication =
        applicationToApply != null || applicantToApply != null;
    final remarksController = TextEditingController();
    final applicantController = TextEditingController(
      text:
          applicationToApply?.candidateName ??
          applicantToApply?.name ??
          initialSearch ??
          '',
    );
    List<ApplicantLookup> applicants = const [];
    List<LookupOption> hrUsers = const [];
    List<LookupOption> positions = const [];
    List<LookupOption> branches = const [];
    ApplicantLookup? selectedApplicant = applicantToApply ??
        (applicationToApply == null
            ? null
            : ApplicantLookup(
            id: applicationToApply.applicantProfileId,
            name: applicationToApply.candidateName,
            contactNumber: applicationToApply.contact,
            email: '',
            positionApplied: applicationToApply.position,
            qualification: '',
            gender: applicationToApply.gender,
            jobExperience: applicationToApply.jobExperience,
            appliedAt: applicationToApply.createdAt,
            applicationCount: applicationToApply.applicationCount,
            profilePic: null,
            dob: null,
            age: null,
            maritalStatus: null,
            caste: null,
            aadhaarNumber: null,
            hometown: null,
            address: null,
            permanentAddress: null,
          ));
    LookupOption? selectedHrManager;
    LookupOption? selectedAssignedTo;
    LookupOption? selectedPosition;
    LookupOption? selectedBranch;
    String? submitError;
    bool loadingLookups = true;
    bool submitting = false;
    final lockedApplicantName =
        applicationToApply?.candidateName ?? applicantToApply?.name ?? '';

    ApplicantLookup? findInitialApplicant(List<ApplicantLookup> found) {
      if (applicantToApply != null) {
        return applicantToApply;
      }
      if (applicationToApply == null || found.isEmpty) {
        return null;
      }

      for (final applicant in found) {
        if (applicationToApply.applicantProfileId > 0 &&
            applicant.id == applicationToApply.applicantProfileId) {
          return applicant;
        }
      }

      for (final applicant in found) {
        if (applicant.contactNumber.isNotEmpty &&
            applicant.contactNumber == applicationToApply.contact) {
          return applicant;
        }
      }

      for (final applicant in found) {
        if (applicant.name.trim().toLowerCase() ==
            applicationToApply.candidateName.trim().toLowerCase()) {
          return applicant;
        }
      }

      return found.first;
    }

    Future<void> loadLookups(StateSetter setDialogState) async {
      try {
        final responses = await Future.wait([
          AppSession.instance.api.getHrUsers(),
          AppSession.instance.api.getDesignations(),
          AppSession.instance.api.getBranches(),
          AppSession.instance.api.searchApplicants(applicantController.text),
        ]);
        hrUsers = responses[0] as List<LookupOption>;
        positions = responses[1] as List<LookupOption>;
        branches = responses[2] as List<LookupOption>;
        applicants = responses[3] as List<ApplicantLookup>;
        if (lockedApplication) {
          selectedApplicant =
              findInitialApplicant(applicants) ?? selectedApplicant;
        }
      } on ApiException catch (error) {
        submitError = error.message;
      } finally {
        setDialogState(() {
          loadingLookups = false;
        });
      }
    }

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (loadingLookups) {
              unawaited(loadLookups(setDialogState));
            }

            Future<void> searchApplicants() async {
              setDialogState(() {
                submitError = null;
              });
              try {
                final found = await AppSession.instance.api.searchApplicants(
                  applicantController.text,
                );
                setDialogState(() {
                  applicants = found;
                });
              } on ApiException catch (error) {
                setDialogState(() {
                  submitError = error.message;
                });
              }
            }

            Future<void> submit() async {
              if (selectedApplicant == null) {
                setDialogState(() {
                  submitError = 'Please select an applicant.';
                });
                return;
              }
              if (selectedApplicant!.id <= 0) {
                setDialogState(() {
                  submitError = 'Selected applicant profile was not found.';
                });
                return;
              }

              setDialogState(() {
                submitting = true;
                submitError = null;
              });

              try {
                final created = await AppSession.instance.api.createApplication(
                  CreateApplicationRequest(
                    applicantProfileId: selectedApplicant!.id,
                    positionId: selectedPosition?.id,
                    targetBranchId: selectedBranch?.id,
                    hrManagerId: selectedHrManager?.id,
                    assignedToUserId: selectedAssignedTo?.id,
                    remarks: remarksController.text,
                  ),
                );
                if (!mounted || !dialogContext.mounted) {
                  return;
                }
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        'Application created for ${created.candidate}',
                      ),
                    ),
                  );
                await _loadInitial();
                if (mounted) {
                  await _openApplicationDetail(created.id);
                }
              } on ApiException catch (error) {
                setDialogState(() {
                  submitError = error.message;
                });
              } finally {
                setDialogState(() {
                  submitting = false;
                });
              }
            }

            Widget buildHrManagerField() {
              return _DropdownField(
                label: 'HR Manager',
                value: selectedHrManager,
                items: hrUsers,
                hint: 'Select HR Manager',
                onChanged: (value) {
                  setDialogState(() {
                    selectedHrManager = value;
                  });
                },
              );
            }

            Widget buildInterviewerField() {
              return _DropdownField(
                label: 'Assign L1 Interviewer',
                value: selectedAssignedTo,
                items: hrUsers,
                hint: 'Select Interviewer',
                onChanged: (value) {
                  setDialogState(() {
                    selectedAssignedTo = value;
                  });
                },
              );
            }

            Widget buildPositionField() {
              return _DropdownField(
                label: 'Position',
                value: selectedPosition,
                items: positions,
                hint: 'Select Position',
                onChanged: (value) {
                  setDialogState(() {
                    selectedPosition = value;
                  });
                },
              );
            }

            Widget buildBranchField() {
              return _DropdownField(
                label: 'Target Branch',
                value: selectedBranch,
                items: branches,
                hint: 'Select Branch',
                onChanged: (value) {
                  setDialogState(() {
                    selectedBranch = value;
                  });
                },
              );
            }

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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  lockedApplication
                                      ? 'New Application — $lockedApplicantName'
                                      : 'Create Application',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: _textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      if (lockedApplication) ...[
                        const SizedBox(height: 14),
                        const SizedBox.shrink(),
                      ] else ...[
                        const SizedBox(height: 14),
                        const Text(
                          'Applicant Search',
                          style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 0.4,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF555D6E),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: applicantController,
                                decoration: InputDecoration(
                                  hintText: 'Search by name / phone / Aadhaar',
                                  filled: true,
                                  fillColor: Colors.white,
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
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              height: 48,
                              child: FilledButton(
                                onPressed: () => searchApplicants(),
                                style: FilledButton.styleFrom(
                                  backgroundColor: _accent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('Search'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (loadingLookups)
                          const Center(child: CircularProgressIndicator())
                        else
                          Container(
                            constraints: const BoxConstraints(maxHeight: 180),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFE5EAF6),
                              ),
                            ),
                            child: applicants.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text('No applicants found.'),
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    itemCount: applicants.length,
                                    separatorBuilder: (_, _) => const Divider(
                                      height: 1,
                                      color: Color(0xFFE9EDF5),
                                    ),
                                    itemBuilder: (context, index) {
                                      final applicant = applicants[index];
                                      final selected =
                                          selectedApplicant?.id == applicant.id;
                                      return ListTile(
                                        onTap: () {
                                          setDialogState(() {
                                            selectedApplicant = applicant;
                                          });
                                        },
                                        selected: selected,
                                        title: Text(applicant.name),
                                        subtitle: Text(
                                          '${applicant.contactNumber} • ${applicant.qualification}',
                                        ),
                                        trailing: selected
                                            ? const Icon(
                                                Icons.check_circle,
                                                color: _accent,
                                              )
                                            : null,
                                      );
                                    },
                                  ),
                          ),
                      ],
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth < 420) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                buildPositionField(),
                                const SizedBox(height: 14),
                                buildBranchField(),
                                const SizedBox(height: 14),
                                buildHrManagerField(),
                                const SizedBox(height: 14),
                                buildInterviewerField(),
                              ],
                            );
                          }

                          return Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: buildPositionField()),
                                const SizedBox(width: 12),
                                Expanded(child: buildBranchField()),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: buildHrManagerField()),
                                const SizedBox(width: 12),
                                Expanded(child: buildInterviewerField()),
                              ],
                            ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Remarks / Notes',
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 0.4,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF555D6E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: remarksController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Any internal notes...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      if (submitError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          submitError!,
                          style: const TextStyle(
                            color: Color(0xFFB42318),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed:
                                  submitting ||
                                      (lockedApplication && loadingLookups)
                                  ? null
                                  : () => submit(),
                              style: FilledButton.styleFrom(
                                backgroundColor: _accent,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: submitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Create Application'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(96, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 720;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      bottomNavigationBar: const AppBottomNav(selectedTab: AppTab.candidates),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildPortalTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 12 : 18,
                  isMobile ? 14 : 18,
                  isMobile ? 12 : 18,
                  26,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildContentHeader(),
                    const SizedBox(height: 18),
                    if (_loading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_errorMessage != null)
                      _ErrorCard(message: _errorMessage!, onRetry: _loadInitial)
                    else if (_candidates.isEmpty)
                      _EmptyCard(
                        message: 'No candidates found for the current filters.',
                      )
                    else
                      _buildCandidatesTable(),
                    if (!_loading &&
                        _errorMessage == null &&
                        _candidates.isNotEmpty &&
                        _currentPage < _lastPage) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton(
                          onPressed: _loadingMore ? null : () => _loadMore(),
                          child: _loadingMore
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Load More (${_currentPage + 1}/$_lastPage)',
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _candidateCountSummary {
    if (_loading) {
      return 'Loading candidates...';
    }
    if (_errorMessage != null) {
      return 'Unable to load candidates';
    }

    final filteredCount = _filteredCandidates.length;
    final visibleCount = _visibleApplications.length;
    final total = _totalCandidates > 0 ? _totalCandidates : filteredCount;
    if (total == 0 || visibleCount == 0) {
      return 'Showing 0 of 0 candidates';
    }

    return 'Showing 1-$visibleCount of $total candidates';
  }

  List<ApplicantLookup> get _filteredCandidates {
    return _candidates.where((application) {
      if (_selectedGender != null &&
          _normalizedGender(application.gender).toLowerCase() !=
              _selectedGender!.toLowerCase()) {
        return false;
      }

      if (_selectedExperience != null) {
        final experienced = _isExperienced(application);
        if (_selectedExperience == 'yes' && !experienced) {
          return false;
        }
        if (_selectedExperience == 'no' && experienced) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  List<ApplicantLookup> get _visibleApplications {
    return _filteredCandidates;
  }

  Widget _buildPortalTopBar(BuildContext context) {
    final user = AppSession.instance.user;
    final isMobile = MediaQuery.sizeOf(context).width < 720;

    if (isMobile) {
      return Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFE1E6F0))),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: _accent,
              child: Text(
                _userInitials(user?.name),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Candidates',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF06142F),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    user?.name ?? 'Super Admin',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF8A96AD),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: _loadInitial,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              color: const Color(0xFF596174),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE1E6F0))),
      ),
      child: Row(
        children: [
          const Text(
            'PAFT Recruitment Portal',
            style: TextStyle(
              color: Color(0xFF06142F),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 28),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'SECTION',
                style: TextStyle(
                  color: Color(0xFF9BA7BC),
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'Candidates',
                style: TextStyle(
                  color: Color(0xFF06142F),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(width: 30),
          _TopNavItem(
            label: 'All Candidates',
            selected: true,
            onTap: () {},
          ),
          _TopNavItem(
            label: 'Job Apply Page',
            selected: false,
            onTap: () => _showCreateApplicationDialog(),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Search',
            onPressed: () {},
            icon: const Icon(Icons.search_rounded, size: 18),
            color: const Color(0xFF8D99AE),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded, size: 18),
            color: const Color(0xFF8D99AE),
          ),
          IconButton(
            tooltip: 'Theme',
            onPressed: () {},
            icon: const Icon(Icons.dark_mode_outlined, size: 17),
            color: const Color(0xFF8D99AE),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 30, color: const Color(0xFFE1E6F0)),
          const SizedBox(width: 14),
          CircleAvatar(
            radius: 13,
            backgroundColor: _accent,
            child: Text(
              _userInitials(user?.name),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 126),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'Super Administra...',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF06142F),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  user?.employeeCode ?? 'SUPER001',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF9AA4B7),
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF8D99AE),
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildContentHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 560;
        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'All Candidates',
              style: TextStyle(
                color: Color(0xFF06142F),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _candidateCountSummary,
              style: const TextStyle(
                color: Color(0xFF8A96AD),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
        final actions = Row(
          mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Flexible(
              fit: isMobile ? FlexFit.tight : FlexFit.loose,
              child: _HeaderButton(
                label: 'Refresh',
                icon: Icons.refresh_rounded,
                onPressed: _loadInitial,
                outlined: true,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              fit: isMobile ? FlexFit.tight : FlexFit.loose,
              child: _HeaderButton(
                label: 'Job Apply',
                icon: Icons.add_rounded,
                onPressed: () => _showCreateApplicationDialog(),
              ),
            ),
          ],
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: 12),
              actions,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleBlock),
            actions,
          ],
        );
      },
    );
  }

  String _userInitials(String? name) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'SU';
    }
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
  Widget _buildCandidatesTable() {
    final visibleApplications = _visibleApplications;
    if (visibleApplications.isEmpty) {
      return const _EmptyCard(
        message: 'No candidates found for the current filters.',
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD8DEE9)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTableToolbar(),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 720) {
                return _buildMobileCandidateList(visibleApplications);
              }

              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 520),
                child: Scrollbar(
                  controller: _tableVerticalController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _tableVerticalController,
                    child: Scrollbar(
                      controller: _tableHorizontalController,
                      thumbVisibility: true,
                      notificationPredicate: (notification) =>
                          notification.depth == 1,
                      child: SingleChildScrollView(
                        controller: _tableHorizontalController,
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: constraints.maxWidth,
                          ),
                          child: DataTable(
                            headingRowHeight: 31,
                            dataRowMinHeight: 46,
                            dataRowMaxHeight: 46,
                            columnSpacing: 30,
                            horizontalMargin: 12,
                            dividerThickness: 0.7,
                            headingRowColor: WidgetStateProperty.all(
                              const Color(0xFF0B1736),
                            ),
                            columns: const [
                              DataColumn(label: _HeaderCell('#')),
                              DataColumn(label: _HeaderCell('Candidate')),
                              DataColumn(label: _HeaderCell('Phone')),
                              DataColumn(label: _HeaderCell('Gender')),
                              DataColumn(label: _HeaderCell('Qualification')),
                              DataColumn(label: _HeaderCell('Experience')),
                              DataColumn(label: _HeaderCell('Applied On')),
                              DataColumn(label: _HeaderCell('Applications')),
                              DataColumn(label: _HeaderCell('Action')),
                            ],
                            rows: [
                              for (
                                var index = 0;
                                index < visibleApplications.length;
                                index++
                              )
                                _buildCandidateRow(
                                  visibleApplications[index],
                                  index,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCandidateList(List<ApplicantLookup> applications) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: applications.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _buildMobileCandidateCard(applications[index], index);
      },
    );
  }

  Widget _buildMobileCandidateCard(ApplicantLookup application, int index) {
    final experienced = _isExperienced(application);
    final initials = application.name.trim().isEmpty
        ? '?'
        : application.name.trim().substring(0, 1).toUpperCase();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: index.isOdd ? const Color(0xFFF8FAFE) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5EAF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: const Color(0xFFE7EAFF),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Color(0xFF2532A5),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _candidateValue(application.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF06142F),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _candidateValue(application.email),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF8190AD),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _Pill(
                label: '#${index + 1}',
                backgroundColor: const Color(0xFFF1F3F8),
                textColor: const Color(0xFF8B94A8),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(
                label: _genderLabel(application),
                backgroundColor:
                    _normalizedGender(application.gender) == 'Female'
                    ? const Color(0xFFEDE5FF)
                    : const Color(0xFFE5EEFF),
                textColor: _normalizedGender(application.gender) == 'Female'
                    ? const Color(0xFF7137D8)
                    : const Color(0xFF235FE5),
              ),
              _Pill(
                label: experienced ? 'Experienced' : 'Fresher',
                backgroundColor: experienced
                    ? const Color(0xFFDDF8E9)
                    : const Color(0xFFF1F3F7),
                textColor: experienced
                    ? const Color(0xFF047A45)
                    : const Color(0xFF3F4656),
              ),
              _Pill(
                label: '${application.applicationCount} Applications',
                backgroundColor: const Color(0xFFFFF3D9),
                textColor: const Color(0xFF9A5B00),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MobileInfoLine(
            icon: Icons.phone_rounded,
            text: _candidateValue(application.contactNumber),
          ),
          _MobileInfoLine(
            icon: Icons.school_rounded,
            text: application.qualification.isNotEmpty
                ? application.qualification
                : _candidateValue(application.positionApplied),
          ),
          _MobileInfoLine(
            icon: Icons.event_rounded,
            text: 'Applied ${_candidateValue(application.appliedAt)}',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showCandidatePreview(application),
                  icon: const Icon(Icons.visibility_rounded, size: 16),
                  label: const Text('View'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _accent,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                    side: const BorderSide(color: Color(0xFFD9E0EC)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _showCreateApplicationDialog(
                    initialApplicant: application,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 17),
                  label: const Text('Apply'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  DataRow _buildCandidateRow(ApplicantLookup application, int index) {
    final experienced = _isExperienced(application);
    return DataRow(
      color: WidgetStateProperty.resolveWith((states) {
        if (index.isOdd) {
          return const Color(0xFFF6F8FC);
        }
        return Colors.white;
      }),
      cells: [
        DataCell(_MutedText('${index + 1}')),
        DataCell(_CandidateIdentity(application: application)),
        DataCell(_BodyText(_candidateValue(application.contactNumber))),
        DataCell(
          _Pill(
            label: _genderLabel(application),
            backgroundColor: _normalizedGender(application.gender) == 'Female'
                ? const Color(0xFFEDE5FF)
                : const Color(0xFFE5EEFF),
            textColor: _normalizedGender(application.gender) == 'Female'
                ? const Color(0xFF7137D8)
                : const Color(0xFF235FE5),
          ),
        ),
        DataCell(
          _BodyText(
            application.qualification.isNotEmpty
                ? application.qualification
                : _candidateValue(application.positionApplied),
          ),
        ),
        DataCell(
          _Pill(
            label: experienced ? 'Experienced' : 'Fresher',
            backgroundColor: experienced
                ? const Color(0xFFDDF8E9)
                : const Color(0xFFF1F3F7),
            textColor: experienced
                ? const Color(0xFF047A45)
                : const Color(0xFF3F4656),
          ),
        ),
        DataCell(_BodyText(_candidateValue(application.appliedAt))),
        DataCell(
          _Pill(
            label: '${application.applicationCount}',
            backgroundColor: const Color(0xFFF1F3F8),
            textColor: const Color(0xFF8B94A8),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => _showCandidatePreview(application),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFE7EAFF),
                  foregroundColor: _accent,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(42, 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: const Text(
                  'View',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 6),
              FilledButton(
                onPressed: () =>
                    _showCreateApplicationDialog(initialApplicant: application),
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(56, 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: const Text(
                  '+ Apply',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isExperienced(ApplicantLookup application) {
    if (application.jobExperience) {
      return true;
    }

    return false;
  }

  String _normalizedGender(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'm' || normalized == 'male') {
      return 'Male';
    }
    if (normalized == 'f' || normalized == 'female') {
      return 'Female';
    }
    return value.trim();
  }

  String _genderLabel(ApplicantLookup application) {
    final normalized = _normalizedGender(application.gender);
    return normalized.isEmpty ? '-' : normalized;
  }

  String _candidateValue(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? '-' : trimmed;
  }

  Future<void> _showCandidatePreview(ApplicantLookup candidate) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final profileFuture = AppSession.instance.api
            .getCandidateProfileFromAllCandidates(candidate);

        return Dialog(
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 20,
          ),
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: FutureBuilder<CandidateProfile>(
              future: profileFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _CandidatePreviewLoadingCard();
                }

                final profile = snapshot.hasData
                    ? snapshot.data!
                    : CandidateProfile.fromApplicantLookup(candidate);

                return _CandidatePreviewShell(
                  errorMessage: snapshot.hasError
                      ? snapshot.error.toString()
                      : null,
                  profile: profile,
                  applicationCount: candidate.applicationCount,
                  value: _candidateValue,
                  ageLabel: _candidateAgeLabel,
                  aadhaarLabel: _candidateValue,
                  onClose: () => Navigator.of(dialogContext).pop(),
                  onApply: () {
                    Navigator.of(dialogContext).pop();
                    _showCreateApplicationDialog(initialApplicant: candidate);
                  },
                  onOpenFile: _openCandidateFile,
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _candidateAgeLabel(int? age) {
    if (age == null) {
      return '-';
    }
    return '${age.abs()} yrs';
  }

  Future<void> _openCandidateFile(String path) async {
    final url = ApiConfig.resolveFileUrl(path);
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Could not open file: $url')));
    }
  }

  Widget _buildTableToolbar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 560;
        final genderFilter = _buildToolbarDropdown(
          label: 'Gender',
          value: _selectedGender,
          hint: 'All Genders',
          expanded: isMobile,
          items: const [
            DropdownMenuItem(value: null, child: Text('All Genders')),
            DropdownMenuItem(value: 'Male', child: Text('Male')),
            DropdownMenuItem(value: 'Female', child: Text('Female')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedGender = value;
            });
            unawaited(_loadInitial());
          },
        );
        final experienceFilter = _buildToolbarDropdown(
          label: 'Experience',
          value: _selectedExperience,
          hint: 'All',
          expanded: isMobile,
          items: const [
            DropdownMenuItem(value: null, child: Text('All')),
            DropdownMenuItem(
              value: 'yes',
              child: Text('Experienced'),
            ),
            DropdownMenuItem(value: 'no', child: Text('Fresher')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedExperience = value;
            });
            unawaited(_loadInitial());
          },
        );

        return Container(
          padding: EdgeInsets.fromLTRB(14, 10, 14, isMobile ? 12 : 10),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: isMobile ? double.infinity : 304,
                child: _buildSearchField(),
              ),
              const SizedBox(height: 10),
              genderFilter,
              const SizedBox(height: 8),
              experienceFilter,
              const SizedBox(height: 8),
              _buildShowDropdown(expanded: isMobile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShowDropdown({bool expanded = false}) {
    return Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      children: [
        const SizedBox(width: 86, child: _ToolbarLabel('SHOW')),
        Flexible(
          fit: expanded ? FlexFit.tight : FlexFit.loose,
          child: SizedBox(
            width: expanded ? null : 118,
            child: DropdownButtonFormField<int>(
              initialValue: _rowsToShow,
              decoration: _toolbarInputDecoration(),
              items: const [
                DropdownMenuItem(value: 10, child: Text('10')),
                DropdownMenuItem(value: 25, child: Text('25')),
                DropdownMenuItem(value: 50, child: Text('50')),
                DropdownMenuItem(value: 100, child: Text('100')),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _rowsToShow = value;
                });
                unawaited(_loadInitial());
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return SizedBox(
      height: 38,
      child: TextField(
        controller: _searchController,
        onSubmitted: (_) => _loadInitial(),
        style: const TextStyle(fontSize: 12),
        decoration: _toolbarInputDecoration().copyWith(
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 18,
            color: Color(0xFF9AA4B7),
          ),
          hintText: 'Search name, phone, email, Aadhar...',
        ),
      ),
    );
  }

  Widget _buildToolbarDropdown({
    required String label,
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String?>> items,
    required ValueChanged<String?> onChanged,
    bool expanded = false,
  }) {
    return Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      children: [
        SizedBox(width: 86, child: _ToolbarLabel(label.toUpperCase())),
        Flexible(
          fit: expanded ? FlexFit.tight : FlexFit.loose,
          child: SizedBox(
            width: expanded ? null : 118,
            child: DropdownButtonFormField<String?>(
              initialValue: value,
              decoration: _toolbarInputDecoration(),
              hint: Text(hint),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _toolbarInputDecoration() {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      hintStyle: const TextStyle(color: Color(0xFF9AA4B7), fontSize: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD8DEE9)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _accent),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

}

class _MobileInfoLine extends StatelessWidget {
  const _MobileInfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFF8A96AD)),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF596174),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidatePreviewLoadingCard extends StatelessWidget {
  const _CandidatePreviewLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 14),
          Text(
            'Loading candidate details...',
            style: TextStyle(
              color: Color(0xFF596174),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidatePreviewErrorBanner extends StatelessWidget {
  const _CandidatePreviewErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFD0CC)),
      ),
      child: Text(
        'Could not load full details. Showing available data. $message',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFFB42318),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CandidatePreviewShell extends StatelessWidget {
  const _CandidatePreviewShell({
    required this.profile,
    required this.applicationCount,
    required this.value,
    required this.ageLabel,
    required this.aadhaarLabel,
    required this.onClose,
    required this.onApply,
    required this.onOpenFile,
    this.errorMessage,
  });

  final CandidateProfile profile;
  final int applicationCount;
  final String Function(String? value) value;
  final String Function(int? age) ageLabel;
  final String Function(String? value) aadhaarLabel;
  final VoidCallback onClose;
  final VoidCallback onApply;
  final Future<void> Function(String path) onOpenFile;
  final String? errorMessage;

  String _fileName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final parts = normalized.split('/');
    return parts.isEmpty ? path : parts.last;
  }

  String _addressValue(String? value) {
    if (value == null || value.isEmpty) {
      return '--';
    }
    return value;
  }

  IconData _documentIcon(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) {
      return Icons.picture_as_pdf_outlined;
    }
    return Icons.image_outlined;
  }

  String _documentStatus(String status) {
    if (status.trim().isEmpty) {
      return 'Pending';
    }
    return status
        .replaceAll('_', ' ')
        .trim()
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  Widget _buildSummary() {
    return _DetailSectionCard(
      title: 'Profile',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CandidatePhoto(candidate: profile),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value(profile.name),
                  style: const TextStyle(
                    color: _AllCandidatesScreenState._textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusPill(
                      label: profile.jobExperience ? 'Experienced' : 'Fresher',
                      color: const Color(0xFF1D7D52),
                    ),
                    if (applicationCount > 0)
                      _StatusPill(
                        label: '$applicationCount application${applicationCount == 1 ? '' : 's'}',
                        color: _AllCandidatesScreenState._accent,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _IconLine(
                  icon: Icons.call_outlined,
                  text: value(profile.contactNumber),
                ),
                _IconLine(
                  icon: Icons.mail_outline_rounded,
                  text: value(profile.email),
                ),
                _IconLine(
                  icon: Icons.work_outline_rounded,
                  text: value(profile.positionApplied),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocuments() {
    final hasResume = profile.resume != null && profile.resume!.isNotEmpty;
    final submittedCount = (hasResume ? 1 : 0) + profile.documents.length;

    return _DetailSectionCard(
      title: 'Documents',
      titleTrailing: Text(
        '$submittedCount submitted',
        style: const TextStyle(
          color: _AllCandidatesScreenState._accent,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
      child: Column(
        children: [
          if (hasResume)
            _DocumentTile(
              icon: Icons.picture_as_pdf_outlined,
              title: _fileName(profile.resume!),
              subtitle: 'Resume',
              trailing: Icons.open_in_new_rounded,
              onTap: () => onOpenFile(profile.resume!),
            ),
          if (!hasResume && profile.documents.isEmpty)
            const _EmptyInline(message: 'No documents available from API.'),
          ...profile.documents.map(
            (document) => Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _DocumentTile(
                icon: _documentIcon(document.fileName),
                title: value(document.title),
                subtitle: value(document.fileName),
                trailing: Icons.open_in_new_rounded,
                onTap: document.filePath == null || document.filePath!.isEmpty
                    ? null
                    : () => onOpenFile(document.filePath!),
                statusLabel: document.isApproved
                    ? 'Approved'
                    : _documentStatus(document.status),
                statusColor: document.isApproved
                    ? const Color(0xFF18A960)
                    : const Color(0xFFD99813),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height - 40,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE7EBF2))),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Candidate Details',
                      style: TextStyle(
                        color: _AllCandidatesScreenState._textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (errorMessage != null) ...[
                      _CandidatePreviewErrorBanner(message: errorMessage!),
                      const SizedBox(height: 12),
                    ],
                    _buildSummary(),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final twoColumn = constraints.maxWidth >= 650;
                        final personal = _DetailSectionCard(
                          title: 'Personal',
                          child: Column(
                            children: [
                              _InfoRow(
                                label: 'Phone',
                                value: value(profile.contactNumber),
                              ),
                              _InfoRow(
                                label: 'Email',
                                value: value(profile.email),
                              ),
                              _InfoRow(label: 'DOB', value: value(profile.dob)),
                              _InfoRow(
                                label: 'Age',
                                value: ageLabel(profile.age),
                              ),
                              _InfoRow(
                                label: 'Gender',
                                value: value(profile.gender),
                              ),
                              _InfoRow(
                                label: 'Marital',
                                value: value(profile.maritalStatus),
                              ),
                              _InfoRow(
                                label: 'Caste',
                                value: value(profile.caste),
                              ),
                              _InfoRow(
                                label: 'Aadhar',
                                value: aadhaarLabel(profile.aadhaarNumber),
                              ),
                              _AddressBlock(
                                label: 'Permanent Address',
                                value: _addressValue(profile.permanentAddress),
                                isLast: true,
                              ),
                            ],
                          ),
                        );
                        final career = _DetailSectionCard(
                          title: 'Education & Career',
                          child: _EducationCareerOverview(
                            candidate: profile,
                            value: value,
                          ),
                        );

                        if (!twoColumn) {
                          return Column(
                            children: [
                              personal,
                              const SizedBox(height: 12),
                              career,
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: personal),
                            const SizedBox(width: 12),
                            Expanded(child: career),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _DetailSectionCard(
                      title: 'Skills & Mobility',
                      child: Column(
                        children: [
                          _TagInfoRow(
                            label: 'Languages',
                            value: profile.languages.isEmpty
                                ? '--'
                                : profile.languages.join(', '),
                            highlightColor: const Color(0xFF6A4CF3),
                          ),
                          _TagInfoRow(
                            label: '2-Wheeler',
                            value: profile.twoWheeler ? 'Yes' : 'No',
                          ),
                          _TagInfoRow(
                            label: '4-Wheeler',
                            value: profile.fourWheeler ? 'Yes' : 'No',
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DetailSectionCard(
                      title: 'Preferred Branches',
                      child: profile.preferredBranches.isEmpty
                          ? const _EmptyInline(
                              message: 'No preferred branches available.',
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: profile.preferredBranches
                                  .map(
                                    (branch) => _StatusPill(
                                      label: branch,
                                      color: _AllCandidatesScreenState._accent,
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                    const SizedBox(height: 12),
                    _buildDocuments(),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE7EBF2))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onClose,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(42),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: onApply,
                      style: FilledButton.styleFrom(
                        backgroundColor: _AllCandidatesScreenState._accent,
                        minimumSize: const Size.fromHeight(42),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopNavItem extends StatelessWidget {
  const _TopNavItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected
                  ? _AllCandidatesScreenState._accent
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? _AllCandidatesScreenState._accent
                : const Color(0xFF515B73),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.outlined = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(8);
    if (outlined) {
      return SizedBox(
        height: 28,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 14),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF111827),
            textStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            side: const BorderSide(color: Color(0xFFD9E0EC)),
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
          ),
        ),
      );
    }

    return SizedBox(
      height: 28,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 14),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: _AllCandidatesScreenState._accent,
          textStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFF9AB3EA),
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _ToolbarLabel extends StatelessWidget {
  const _ToolbarLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF9AA4B7),
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _BodyText extends StatelessWidget {
  const _BodyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xFF172036),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _MutedText extends StatelessWidget {
  const _MutedText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF8A96AD),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _CandidateIdentity extends StatelessWidget {
  const _CandidateIdentity({required this.application});

  final ApplicantLookup application;

  @override
  Widget build(BuildContext context) {
    final initials = application.name.trim().isEmpty
        ? '?'
        : application.name.trim().substring(0, 1).toUpperCase();
    final email = application.email.trim().isEmpty ? '-' : application.email;

    return SizedBox(
      width: 230,
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: const Color(0xFFE7EAFF),
            child: Text(
              initials,
              style: const TextStyle(
                color: Color(0xFF2532A5),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  application.name.trim().isEmpty
                      ? '-'
                      : application.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF06142F),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF8190AD),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
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

class _Pill extends StatelessWidget {
  const _Pill({
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ApplicationDetailScreen extends StatefulWidget {
  const _ApplicationDetailScreen({required this.applicationId});

  final int applicationId;

  @override
  State<_ApplicationDetailScreen> createState() =>
      _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<_ApplicationDetailScreen> {
  late Future<ApplicationDetail> _detailFuture;

  String _stageLabel(int stage) {
    switch (stage) {
      case 0:
        return 'Level 1 / Pre-Screening';
      case 1:
        return 'Level 2';
      case 2:
        return 'Level 3';
      case 3:
        return 'Level 4 / Salary Finalisation';
      default:
        return '$stage';
    }
  }

  String _actionLabel(String action) {
    switch (action) {
      case 'created':
        return 'Created';
      case 'pre_screen_proceed':
        return 'Pre-Screen Passed';
      case 'pre_screen_not_responding':
        return 'Not Responding';
      case 'pre_screen_rejected':
        return 'Rejected in Pre-Screen';
      case 'pre_screen_no_vacancy':
        return 'No Vacancy';
      case 'proceed':
        return 'Proceeded';
      case 'hold':
        return 'On Hold';
      case 'reject':
        return 'Rejected';
      default:
        return action;
    }
  }

  @override
  void initState() {
    super.initState();
    _detailFuture = AppSession.instance.api.getApplicationDetail(
      widget.applicationId,
    );
  }

  Future<void> _reload() async {
    setState(() {
      _detailFuture = AppSession.instance.api.getApplicationDetail(
        widget.applicationId,
      );
    });
    await _detailFuture;
  }

  Future<void> _showDocumentPreview(StageAttachment attachment) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(attachment.type),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('File: ${attachment.fileName}'),
              const SizedBox(height: 8),
              Text('Type: ${attachment.fileType}'),
              const SizedBox(height: 8),
              Text('Size: ${attachment.fileSize} bytes'),
              const SizedBox(height: 8),
              Text('Uploaded by: ${attachment.uploadedBy}'),
              const SizedBox(height: 8),
              const Text(
                'Preview placeholder. Hook this to your file URL/viewer when backend file URLs are available.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _value(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '--';
    }
    return value;
  }

  String _addressValue(String? value) {
    if (value == null || value.isEmpty) {
      return '--';
    }
    return value;
  }

  String _fileName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final parts = normalized.split('/');
    return parts.isEmpty ? path : parts.last;
  }

  String _ageLabel(int? age) {
    if (age == null) {
      return '--';
    }
    return '${age.abs()} yrs';
  }

  Widget _buildProfileSummary(ApplicationDetail detail) {
    final candidate = detail.candidate;
    return _DetailSectionCard(
      title: 'Profile',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CandidatePhoto(candidate: candidate),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _value(candidate.name),
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: _AllCandidatesScreenState._textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StatusPill(
                          label: detail.statusLabel.isEmpty
                              ? 'Application'
                              : detail.statusLabel,
                          color: const Color(0xFF5447E8),
                        ),
                        _StatusPill(
                          label: _stageLabel(detail.currentStage),
                          color: const Color(0xFF1D7D52),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _IconLine(
                      icon: Icons.call_outlined,
                      text: _value(candidate.contactNumber),
                    ),
                    _IconLine(
                      icon: Icons.mail_outline_rounded,
                      text: _value(candidate.email),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openFile(String path) async {
    final url = ApiConfig.resolveFileUrl(path);
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Could not open file: $url')),
        );
    }
  }

  Widget _buildDocumentSection(ApplicationDetail detail) {
    final candidate = detail.candidate;
    final attachments = detail.stages
        .expand((stage) => stage.attachments)
        .toList(growable: false);
    final hasResume = candidate.resume != null && candidate.resume!.isNotEmpty;
    final submittedCount =
        (hasResume ? 1 : 0) + candidate.documents.length + attachments.length;

    return _DetailSectionCard(
      title: 'Documents',
      titleTrailing: Text(
        '$submittedCount submitted',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: _AllCandidatesScreenState._accent,
        ),
      ),
      child: Column(
        children: [
          if (hasResume)
            _DocumentTile(
              icon: Icons.picture_as_pdf_outlined,
              title: _fileName(candidate.resume!),
              subtitle: 'Click to view / download',
              trailing: Icons.open_in_new_rounded,
              onTap: () => _openFile(candidate.resume!),
            ),
          if (candidate.documents.isEmpty &&
              attachments.isEmpty &&
              (candidate.resume == null || candidate.resume!.isEmpty))
            const _EmptyInline(message: 'No documents uploaded yet.'),
          ...candidate.documents.map(
            (document) => Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _DocumentTile(
                icon: _documentIcon(document.fileName),
                title: _value(document.title),
                subtitle: _value(document.fileName),
                onTap: document.filePath == null || document.filePath!.isEmpty
                    ? null
                    : () => _openFile(document.filePath!),
                statusLabel: document.isApproved
                    ? 'Approved'
                    : _documentStatus(document.status),
                statusColor: document.isApproved
                    ? const Color(0xFF18A960)
                    : const Color(0xFFD99813),
              ),
            ),
          ),
          ...attachments.map(
            (attachment) => Padding(
              padding: const EdgeInsets.only(top: 10),
              child: InkWell(
                onTap: () => _showDocumentPreview(attachment),
                borderRadius: BorderRadius.circular(12),
                child: _DocumentTile(
                  icon: _documentIcon(attachment.fileName),
                  title: attachment.type.isEmpty
                      ? attachment.fileName
                      : attachment.type,
                  subtitle: attachment.fileName,
                  statusLabel: 'Approved',
                  statusColor: const Color(0xFF18A960),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _documentIcon(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) {
      return Icons.picture_as_pdf_outlined;
    }
    return Icons.image_outlined;
  }

  String _documentStatus(String status) {
    if (status.trim().isEmpty) {
      return 'Pending';
    }
    final normalized = status.replaceAll('_', ' ').trim();
    return normalized
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return AppPageLayout(
      selectedTab: AppTab.candidates,
      sectionLabel: 'Application View',
      title: 'Application Detail',
      subtitle: 'Candidate profile, stages and attachments from live API data.',
      titleTrailing: const AppTopAction(icon: Icons.badge_outlined),
      showBackButton: true,
      child: FutureBuilder<ApplicationDetail>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : 'Unable to load application detail.';
            return _ErrorCard(message: message, onRetry: _reload);
          }
          final detail = snapshot.data!;
          final candidate = detail.candidate;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileSummary(detail),
              const SizedBox(height: 14),
              _DetailSectionCard(
                title: 'Personal',
                child: Column(
                  children: [
                    _InfoRow(
                      label: 'Phone',
                      value: _value(candidate.contactNumber),
                    ),
                    _InfoRow(label: 'Email', value: _value(candidate.email)),
                    _InfoRow(label: 'DOB', value: _value(candidate.dob)),
                    _InfoRow(label: 'Age', value: _ageLabel(candidate.age)),
                    _InfoRow(label: 'Gender', value: _value(candidate.gender)),
                    _InfoRow(
                      label: 'Marital',
                      value: _value(candidate.maritalStatus),
                    ),
                    _InfoRow(label: 'Caste', value: _value(candidate.caste)),
                    _InfoRow(
                      label: 'Aadhar',
                      value: _value(candidate.aadhaarNumber),
                    ),
                    _AddressBlock(
                      label: 'Permanent Address',
                      value: _addressValue(candidate.permanentAddress),
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _DetailSectionCard(
                title: 'Education & Career',
                child: _EducationCareerOverview(
                  candidate: candidate,
                  value: _value,
                  mappedPosition: detail.position == null
                      ? null
                      : '${detail.position!.shortName} - ${detail.position!.fullName}',
                ),
              ),
              const SizedBox(height: 14),
              _DetailSectionCard(
                title: 'Application',
                child: Column(
                  children: [
                    _InfoRow(
                      label: 'Status',
                      value: _value(detail.statusLabel),
                    ),
                    _InfoRow(
                      label: 'Status Code',
                      value: _value(detail.statusCode),
                    ),
                    _InfoRow(
                      label: 'Current Stage',
                      value: _stageLabel(detail.currentStage),
                    ),
                    _InfoRow(
                      label: 'Target Branch',
                      value: _value(detail.targetBranch?.name),
                    ),
                    _InfoRow(
                      label: 'HR Manager',
                      value: _value(detail.hrManager?.name),
                    ),
                    _InfoRow(
                      label: 'Assigned To',
                      value: _value(detail.assignedTo?.name),
                    ),
                    _InfoRow(
                      label: 'Applied On',
                      value: _value(candidate.appliedAt),
                    ),
                    _InfoRow(label: 'Created At', value: _value(detail.createdAt)),
                    _InfoRow(label: 'Updated At', value: _value(detail.updatedAt)),
                    _InfoRow(
                      label: 'Lag Days',
                      value: detail.lagDays == null
                          ? '--'
                          : '${detail.lagDays} days',
                    ),
                    _InfoRow(
                      label: 'Remarks',
                      value: _value(detail.remarks),
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _DetailSectionCard(
                title: 'Skills & Attributes',
                child: Column(
                  children: [
                    _TagInfoRow(
                      label: 'Languages',
                      value: candidate.languages.isEmpty
                          ? '--'
                          : candidate.languages.join(', '),
                      highlightColor: const Color(0xFF6A4CF3),
                    ),
                    _TagInfoRow(
                      label: '2-Wheeler',
                      value: candidate.twoWheeler ? 'Yes' : 'No',
                    ),
                    _TagInfoRow(
                      label: '4-Wheeler',
                      value: candidate.fourWheeler ? 'Yes' : 'No',
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _DetailSectionCard(
                title: 'Preferred Branches',
                child: candidate.preferredBranches.isEmpty
                    ? const _EmptyInline(message: 'No preferred branches added.')
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: candidate.preferredBranches
                            .map(
                              (branch) => _StatusPill(
                                label: branch,
                                color: const Color(0xFF5447E8),
                              ),
                            )
                            .toList(),
                      ),
              ),
              const SizedBox(height: 14),
              _DetailSectionCard(
                title: 'Offer / Joining',
                child: Column(
                  children: [
                    _InfoRow(
                      label: 'Offer Status',
                      value: detail.offerConsent?.status ?? 'Not released',
                    ),
                    _InfoRow(
                      label: 'Offer Releases',
                      value: '${detail.offerConsent?.totalReleases ?? 0}',
                    ),
                    _InfoRow(
                      label: 'Salary Offered',
                      value: _value(detail.salaryOffered),
                    ),
                    _InfoRow(
                      label: 'Joining Status',
                      value: detail.joiningForm?.employeeStatus ?? '--',
                    ),
                    _InfoRow(
                      label: 'Joining Submitted',
                      value: detail.joiningForm?.submittedAt ?? '--',
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildDocumentSection(detail),
              const SizedBox(height: 14),
              const Text(
                'STAGE TIMELINE',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 2.2,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF80859A),
                ),
              ),
              const SizedBox(height: 14),
              ...detail.stages.map(
                (stage) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _StageCard(
                    stage: stage,
                    actionLabel: _actionLabel(stage.actionTaken),
                    onOpenAttachment: _showDocumentPreview,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.stage,
    required this.actionLabel,
    required this.onOpenAttachment,
  });

  final ApplicationStage stage;
  final String actionLabel;
  final Future<void> Function(StageAttachment attachment) onOpenAttachment;

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
                  stage.stageName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _AllCandidatesScreenState._textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2EEFF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _AllCandidatesScreenState._accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Completed: ${stage.completedAt ?? '--'}',
            style: const TextStyle(
              color: _AllCandidatesScreenState._textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Done By: ${stage.doneBy ?? '--'}',
            style: const TextStyle(
              color: _AllCandidatesScreenState._textSecondary,
            ),
          ),
          if (stage.remarks != null && stage.remarks!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(stage.remarks!),
          ],
          if (stage.attachments.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Attachments',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...stage.attachments.map(
              (attachment) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => onOpenAttachment(attachment),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.attach_file_rounded,
                          color: _AllCandidatesScreenState._accent,
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(attachment.fileName)),
                        const Icon(Icons.open_in_new_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.items,
    required this.hint,
    required this.onChanged,
    this.value,
  });

  final String label;
  final List<LookupOption> items;
  final LookupOption? value;
  final String hint;
  final ValueChanged<LookupOption?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            letterSpacing: 0.4,
            fontWeight: FontWeight.w700,
            color: Color(0xFF555D6E),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<LookupOption>(
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          hint: Text(hint),
          items: items
              .map(
                (item) => DropdownMenuItem<LookupOption>(
                  value: item,
                  child: Text(
                    item.subtitle == null || item.subtitle!.isEmpty
                        ? item.title
                        : '${item.title} (${item.subtitle})',
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _DetailSectionCard extends StatelessWidget {
  const _DetailSectionCard({
    required this.title,
    required this.child,
    this.titleTrailing,
  });

  final String title;
  final Widget child;
  final Widget? titleTrailing;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3C4255),
                  ),
                ),
              ),
              ?titleTrailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _CandidatePhoto extends StatelessWidget {
  const _CandidatePhoto({required this.candidate});

  final CandidateProfile candidate;

  @override
  Widget build(BuildContext context) {
    final photo = candidate.profilePic;
    final initials = candidate.name.trim().isEmpty
        ? '?'
        : candidate.name.trim().substring(0, 1).toUpperCase();

    return Container(
      width: 92,
      height: 108,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFE9ECF6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE3F0)),
      ),
      child: photo == null || photo.isEmpty
          ? Center(
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: _AllCandidatesScreenState._accent,
                ),
              ),
            )
          : Image.network(
              ApiConfig.resolveFileUrl(photo),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: _AllCandidatesScreenState._accent,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF7C8498)),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF596174),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _EducationCareerOverview extends StatelessWidget {
  const _EducationCareerOverview({
    required this.candidate,
    required this.value,
    this.mappedPosition,
  });

  final CandidateProfile candidate;
  final String Function(String? value) value;
  final String? mappedPosition;

  String _salaryLabel(String? salary) {
    final raw = value(salary);
    if (raw == '--' || raw.startsWith('Rs') || raw.startsWith('₹')) {
      return raw;
    }
    return 'Rs $raw';
  }

  String _iibfCertifiedLabel(String? certified) {
    final raw = certified?.trim() ?? '';
    if (raw.isEmpty) {
      return '--';
    }
    final normalized = raw.toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return 'Yes';
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return 'No';
    }
    return raw;
  }

  List<EducationDetail> get _educationRows {
    if (candidate.educationDetails.isNotEmpty) {
      return candidate.educationDetails;
    }
    if (candidate.qualification.trim().isEmpty) {
      return const [];
    }
    return [
      EducationDetail(
        qualification: candidate.qualification,
        year: candidate.dateOfPassout ?? '',
        score: '',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final rows = _educationRows;
    final details = [
      _CareerLineData(
        'Post Applied For',
        value(candidate.positionApplied),
      ),
      if (mappedPosition != null && mappedPosition!.trim().isNotEmpty)
        _CareerLineData('Mapped Position', mappedPosition!),
      _CareerLineData(
        'Experience',
        candidate.jobExperience ? 'Experienced' : 'Fresher',
      ),
      _CareerLineData('Exp. Salary', _salaryLabel(candidate.expectedSalary)),
      _CareerLineData('Join Timing', value(candidate.timingJoining)),
      _CareerLineData('System Knowledge', value(candidate.systemKnowledge)),
      _CareerLineData(
        'IIBF Certified',
        _iibfCertifiedLabel(candidate.iibfCertified),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUALIFICATIONS',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w800,
            color: Color(0xFF98A0B3),
          ),
        ),
        const SizedBox(height: 8),
        _QualificationTable(rows: rows, value: value),
        const SizedBox(height: 4),
        ...details.asMap().entries.map(
          (entry) => _CareerLine(
            label: entry.value.label,
            value: entry.value.value,
            isLast: entry.key == details.length - 1,
          ),
        ),
      ],
    );
  }
}

class _CareerLineData {
  const _CareerLineData(this.label, this.value);

  final String label;
  final String value;
}

class _QualificationTable extends StatelessWidget {
  const _QualificationTable({required this.rows, required this.value});

  final List<EducationDetail> rows;
  final String Function(String? value) value;

  @override
  Widget build(BuildContext context) {
    final visibleRows = rows.isEmpty
        ? const [
            EducationDetail(qualification: '--', year: '--', score: '--'),
          ]
        : rows;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE9EDF5)),
      ),
      child: Column(
        children: [
          const _QualificationRow(
            qualification: 'Qualification',
            year: 'Year',
            score: '% / CGPA',
            isHeader: true,
          ),
          ...visibleRows.asMap().entries.map(
            (entry) {
              final item = entry.value;
              return _QualificationRow(
                qualification: value(item.qualification),
                year: value(item.year),
                score: value(item.score),
                isLast: entry.key == visibleRows.length - 1,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QualificationRow extends StatelessWidget {
  const _QualificationRow({
    required this.qualification,
    required this.year,
    required this.score,
    this.isHeader = false,
    this.isLast = false,
  });

  final String qualification;
  final String year;
  final String score;
  final bool isHeader;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: isHeader ? 10 : 12,
      fontWeight: isHeader ? FontWeight.w800 : FontWeight.w700,
      color: isHeader ? const Color(0xFF98A0B3) : const Color(0xFF232938),
      letterSpacing: isHeader ? 0.6 : 0,
    );

    return Container(
      constraints: BoxConstraints(minHeight: isHeader ? 38 : 46),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isHeader ? const Color(0xFFF7F9FC) : Colors.white,
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFEFF2F7))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              isHeader ? qualification.toUpperCase() : qualification,
              style: style,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              isHeader ? year.toUpperCase() : year,
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              isHeader ? score.toUpperCase() : score,
              textAlign: TextAlign.right,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}

class _CareerLine extends StatelessWidget {
  const _CareerLine({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF0F2F7))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8A91A4),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF232938),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.statusLabel,
    this.statusColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final IconData? trailing;
  final String? statusLabel;
  final Color? statusColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8EDF7)),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF101828), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF252B37),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7C8498),
                      ),
                    ),
                  ],
                ),
              ),
              if (statusLabel != null && statusLabel!.isNotEmpty)
                _ApprovalPill(
                  label: statusLabel!,
                  color: statusColor ?? const Color(0xFF18A960),
                )
              else if (trailing != null)
                Icon(
                  trailing,
                  size: 18,
                  color: onTap == null
                      ? const Color(0xFF8A91A4)
                      : _AllCandidatesScreenState._accent,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApprovalPill extends StatelessWidget {
  const _ApprovalPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyInline extends StatelessWidget {
  const _EmptyInline({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF7C8498),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF0F2F7))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8A91A4),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF232938),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressBlock extends StatelessWidget {
  const _AddressBlock({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF0F2F7))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w800,
              color: Color(0xFF8A91A4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: Color(0xFF232938),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagInfoRow extends StatelessWidget {
  const _TagInfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
    this.highlightColor = const Color(0xFF19A466),
  });

  final String label;
  final String value;
  final bool isLast;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF0F2F7))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF232938),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: highlightColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: highlightColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

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
          const Icon(
            Icons.cloud_off_rounded,
            size: 42,
            color: Color(0xFF9AA1B1),
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: () => onRetry(), child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 15,
          color: _AllCandidatesScreenState._textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
