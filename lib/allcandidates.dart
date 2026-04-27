import 'dart:async';

import 'package:flutter/material.dart';
import 'package:recruitment/api.dart';
import 'package:recruitment/app_shell.dart';

class AllCandidatesScreen extends StatefulWidget {
  const AllCandidatesScreen({
    super.key,
    this.openApplicationId,
  });

  final int? openApplicationId;

  @override
  State<AllCandidatesScreen> createState() => _AllCandidatesScreenState();
}

class _AllCandidatesScreenState extends State<AllCandidatesScreen> {
  static const Color _primary = Color(0xFF315DE7);
  static const Color _accent = Color(0xFF5447E8);
  static const Color _textPrimary = Color(0xFF141824);
  static const Color _textSecondary = Color(0xFF6F7484);
  static const Color _chipBackground = Color(0xFFE8E9ED);

  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  bool _loadingMore = false;
  bool _myAppsOnly = false;
  String? _errorMessage;
  String? _selectedStatus;
  int? _selectedBranchId;
  int _currentPage = 1;
  int _lastPage = 1;
  final List<ApplicationSummary> _applications = [];
  List<LookupOption> _branches = const [];

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
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      _branches = await AppSession.instance.api.getBranches();
      final page = await AppSession.instance.api.getApplications(
        search: _searchController.text,
        status: _selectedStatus,
        branchId: _selectedBranchId,
        myApps: _myAppsOnly,
      );
      setState(() {
        _applications
          ..clear()
          ..addAll(page.items);
        _currentPage = page.currentPage;
        _lastPage = page.lastPage;
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
      final page = await AppSession.instance.api.getApplications(
        search: _searchController.text,
        status: _selectedStatus,
        branchId: _selectedBranchId,
        myApps: _myAppsOnly,
        page: _currentPage + 1,
      );
      setState(() {
        _applications.addAll(page.items);
        _currentPage = page.currentPage;
        _lastPage = page.lastPage;
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

  Future<void> _showCreateApplicationDialog({String? initialSearch}) async {
    final remarksController = TextEditingController();
    final applicantController = TextEditingController(text: initialSearch ?? '');
    List<ApplicantLookup> applicants = const [];
    List<LookupOption> hrUsers = const [];
    List<LookupOption> designations = const [];
    final branches = _branches;
    ApplicantLookup? selectedApplicant;
    LookupOption? selectedHrManager;
    LookupOption? selectedAssignedTo;
    LookupOption? selectedDesignation;
    LookupOption? selectedBranch;
    String? submitError;
    bool loadingLookups = true;
    bool submitting = false;

    Future<void> loadLookups(StateSetter setDialogState) async {
      try {
        final responses = await Future.wait([
          AppSession.instance.api.getDesignations(),
          AppSession.instance.api.getHrUsers(),
          AppSession.instance.api.searchApplicants(applicantController.text),
        ]);
        designations = responses[0] as List<LookupOption>;
        hrUsers = responses[1] as List<LookupOption>;
        applicants = responses[2] as List<ApplicantLookup>;
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

              setDialogState(() {
                submitting = true;
                submitError = null;
              });

              try {
                final created = await AppSession.instance.api.createApplication(
                  CreateApplicationRequest(
                    applicantProfileId: selectedApplicant!.id,
                    positionId: selectedDesignation?.id,
                    targetBranchId: selectedBranch?.id,
                    hrManagerId: selectedHrManager?.id,
                    assignedToUserId: selectedAssignedTo?.id,
                    remarks: remarksController.text,
                  ),
                );
                if (!mounted) {
                  return;
                }
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text('Application created for ${created.candidate}'),
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

            return Dialog(
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
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
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'NEW APPLICATION',
                                  style: TextStyle(
                                    color: _accent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Create Application',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: _textPrimary,
                                  ),
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
                                  borderSide: const BorderSide(color: Color(0xFFD6DBE7)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFD6DBE7)),
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
                            border: Border.all(color: const Color(0xFFE5EAF6)),
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
                                  separatorBuilder: (_, _) =>
                                      const Divider(height: 1, color: Color(0xFFE9EDF5)),
                                  itemBuilder: (context, index) {
                                    final applicant = applicants[index];
                                    final selected = selectedApplicant?.id == applicant.id;
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
                                          ? const Icon(Icons.check_circle, color: _accent)
                                          : null,
                                    );
                                  },
                                ),
                        ),
                      const SizedBox(height: 14),
                      _DropdownField(
                        label: 'Position',
                        value: selectedDesignation,
                        items: designations,
                        hint: 'Select designation',
                        onChanged: (value) {
                          setDialogState(() {
                            selectedDesignation = value;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      _DropdownField(
                        label: 'Target Branch',
                        value: selectedBranch,
                        items: branches,
                        hint: 'Select branch',
                        onChanged: (value) {
                          setDialogState(() {
                            selectedBranch = value;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      _DropdownField(
                        label: 'HR Manager',
                        value: selectedHrManager,
                        items: hrUsers,
                        hint: 'Select HR manager',
                        onChanged: (value) {
                          setDialogState(() {
                            selectedHrManager = value;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      _DropdownField(
                        label: 'Assign L1 Interviewer',
                        value: selectedAssignedTo,
                        items: hrUsers,
                        hint: 'Select assigned user',
                        onChanged: (value) {
                          setDialogState(() {
                            selectedAssignedTo = value;
                          });
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
                              onPressed: submitting ? null : () => submit(),
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
    return AppPageLayout(
      selectedTab: AppTab.candidates,
      sectionLabel: 'All Candidates',
      title: 'Applications',
      subtitle: 'Live applications feed with search, filters and detail view.',
      titleTrailing: const AppTopAction(icon: Icons.group_outlined),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildSearchField()),
              const SizedBox(width: 10),
              SizedBox(
                height: 58,
                child: FilledButton.icon(
                  onPressed: () => _showCreateApplicationDialog(),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildBranchFilter(),
              ),
              const SizedBox(width: 12),
              FilterChip(
                label: const Text('My Apps'),
                selected: _myAppsOnly,
                onSelected: (value) async {
                  setState(() {
                    _myAppsOnly = value;
                  });
                  await _loadInitial();
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSectionLabel('STATUS FILTER'),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _statusChips
                .map(
                  (chip) => _buildFilterChip(
                    label: chip.label,
                    selected: _selectedStatus == chip.value,
                    onTap: () async {
                      setState(() {
                        _selectedStatus = chip.value;
                      });
                      await _loadInitial();
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ))
          else if (_errorMessage != null)
            _ErrorCard(message: _errorMessage!, onRetry: _loadInitial)
          else if (_applications.isEmpty)
            _EmptyCard(message: 'No applications found for the current filters.')
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _applications.length,
              itemBuilder: (context, index) {
                final application = _applications[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 22),
                  child: _ApplicationCard(
                    application: application,
                    count: index + 1,
                    onView: () => _openApplicationDetail(application.id),
                    onApply: () => _showCreateApplicationDialog(
                      initialSearch: application.candidateName,
                    ),
                  ),
                );
              },
            ),
          if (!_loading &&
              _errorMessage == null &&
              _applications.isNotEmpty &&
              _currentPage < _lastPage) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _loadingMore ? null : () => _loadMore(),
                child: _loadingMore
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Load More (${_currentPage + 1}/$_lastPage)'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EAEE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: _textSecondary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _loadInitial(),
              decoration: const InputDecoration(
                hintText: 'Search by candidate name or phone...',
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _loadInitial(),
            icon: const Icon(Icons.arrow_forward_rounded, color: _primary),
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

  Widget _buildBranchFilter() {
    return DropdownButtonFormField<int?>(
      value: _selectedBranchId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Branch Filter',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDCE1EA)),
        ),
      ),
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('All Branches')),
        ..._branches.map(
          (branch) => DropdownMenuItem<int?>(
            value: branch.id,
            child: Text(branch.title),
          ),
        ),
      ],
      onChanged: (value) async {
        setState(() {
          _selectedBranchId = value;
        });
        await _loadInitial();
      },
    );
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _primary : _chipBackground,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF27304A),
          ),
        ),
      ),
    );
  }

  List<_StatusChipData> get _statusChips => const [
        _StatusChipData(label: 'All', value: null),
        _StatusChipData(label: 'Pre-Screen', value: 'prescreening'),
        _StatusChipData(label: 'L1', value: 'l1'),
        _StatusChipData(label: 'L2', value: 'l2'),
        _StatusChipData(label: 'L3', value: 'l3'),
        _StatusChipData(label: 'Joined', value: 'joined'),
        _StatusChipData(label: 'Hold', value: 'hold'),
        _StatusChipData(label: 'Rejected', value: 'rejected'),
      ];
}

class _StatusChipData {
  const _StatusChipData({
    required this.label,
    required this.value,
  });

  final String label;
  final String? value;
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
    required this.count,
    required this.onView,
    required this.onApply,
  });

  final ApplicationSummary application;
  final int count;
  final VoidCallback onView;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final initials = application.candidateName.isEmpty
        ? '?'
        : application.candidateName.substring(0, 1).toUpperCase();
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
                  color: const Color(0xFFB5C0FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7EAFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Application : $count',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF35478C),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      application.candidateName,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF151926),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      application.contact,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4E5566),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F1F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  application.createdAt,
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
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(
                label: application.gender.isEmpty ? 'Unknown' : application.gender,
                backgroundColor: const Color(0xFFE7EAFF),
                textColor: const Color(0xFF35478C),
              ),
              _InfoChip(
                label: application.position,
                backgroundColor: const Color(0xFFFFDDCB),
                textColor: const Color(0xFF8B421B),
              ),
              _InfoChip(
                label: application.branch,
                backgroundColor: const Color(0xFFE7E8ED),
                textColor: const Color(0xFF343A4A),
              ),
              _InfoChip(
                label: application.statusLabel,
                backgroundColor: const Color(0xFFF2EEFF),
                textColor: const Color(0xFF5447E8),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'View',
                  onTap: onView,
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

class _ApplicationDetailScreen extends StatefulWidget {
  const _ApplicationDetailScreen({required this.applicationId});

  final int applicationId;

  @override
  State<_ApplicationDetailScreen> createState() => _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<_ApplicationDetailScreen> {
  late Future<ApplicationDetail> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = AppSession.instance.api.getApplicationDetail(widget.applicationId);
  }

  Future<void> _reload() async {
    setState(() {
      _detailFuture = AppSession.instance.api.getApplicationDetail(widget.applicationId);
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

  @override
  Widget build(BuildContext context) {
    return AppPageLayout(
      selectedTab: AppTab.candidates,
      sectionLabel: 'Application View',
      title: 'Application Detail',
      subtitle: 'Candidate profile, stages and attachments from live API data.',
      titleTrailing: const AppTopAction(icon: Icons.badge_outlined),
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
              _DetailSectionCard(
                title: 'Candidate',
                child: Column(
                  children: [
                    _InfoRow(label: 'Name', value: candidate.name),
                    _InfoRow(label: 'Phone', value: candidate.contactNumber),
                    _InfoRow(label: 'Email', value: candidate.email),
                    _InfoRow(label: 'Qualification', value: candidate.qualification),
                    _InfoRow(label: 'Position Applied', value: candidate.positionApplied),
                    _InfoRow(label: 'Gender', value: candidate.gender),
                    _InfoRow(label: 'Age', value: '${candidate.age ?? '--'}'),
                    _InfoRow(label: 'DOB', value: candidate.dob ?? '--'),
                    _InfoRow(
                      label: 'Expected Salary',
                      value: candidate.expectedSalary ?? '--',
                    ),
                    _InfoRow(
                      label: 'Address',
                      value: candidate.address ?? '--',
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _DetailSectionCard(
                title: 'Application Info',
                child: Column(
                  children: [
                    _InfoRow(label: 'Status', value: detail.statusLabel),
                    _InfoRow(label: 'Current Stage', value: '${detail.currentStage}'),
                    _InfoRow(
                      label: 'Target Branch',
                      value: detail.targetBranch?.name ?? '--',
                    ),
                    _InfoRow(
                      label: 'HR Manager',
                      value: detail.hrManager?.name ?? '--',
                    ),
                    _InfoRow(
                      label: 'Assigned To',
                      value: detail.assignedTo?.name ?? '--',
                    ),
                    _InfoRow(label: 'Created At', value: detail.createdAt),
                    _InfoRow(label: 'Updated At', value: detail.updatedAt),
                    _InfoRow(
                      label: 'Remarks',
                      value: detail.remarks ?? '--',
                      isLast: true,
                    ),
                  ],
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
              _DetailSectionCard(
                title: 'Languages & Mobility',
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
    required this.onOpenAttachment,
  });

  final ApplicationStage stage;
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2EEFF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  stage.actionTaken,
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
            style: const TextStyle(color: _AllCandidatesScreenState._textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Done By: ${stage.doneBy ?? '--'}',
            style: const TextStyle(color: _AllCandidatesScreenState._textSecondary),
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
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
  });

  final String title;
  final Widget child;

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
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3C4255),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
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
            : const Border(
                bottom: BorderSide(color: Color(0xFFF0F2F7)),
              ),
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
            : const Border(
                bottom: BorderSide(color: Color(0xFFF0F2F7)),
              ),
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
