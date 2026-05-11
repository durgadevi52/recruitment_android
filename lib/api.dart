import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const _productionHost = 'https://hr.patgroup.org';
  static const _productionApiBaseUrl = '$_productionHost/api';

  static String get baseUrl {
    return candidateBaseUrls.first;
  }

  static String resolveFileUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    final base = Uri.parse(candidateBaseUrls.first);
    final origin =
        '${base.scheme}://${base.host}${base.hasPort ? ':${base.port}' : ''}';
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    if (cleanPath.startsWith('storage/')) {
      return '$origin/$cleanPath';
    }
    return '$origin/storage/$cleanPath';
  }

  static List<String> get candidateBaseUrls {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) {
      return [_normalizeBaseUrl(override)];
    }

    if (kIsWeb) {
      return const [
        _productionApiBaseUrl,
        _productionHost,
        'http://localhost/api',
        'http://localhost',
      ];
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const [
          _productionApiBaseUrl,
          _productionHost,
          'http://10.0.2.2/api',
          'http://10.0.2.2',
        ];
      default:
        return const [
          _productionApiBaseUrl,
          _productionHost,
          'http://localhost/api',
          'http://localhost',
        ];
    }
  }

  static String _normalizeBaseUrl(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.errors});

  final String message;
  final int? statusCode;
  final Map<String, List<String>>? errors;

  @override
  String toString() => message;
}

int _readInt(dynamic value, {int fallback = 0}) {
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim()) ?? fallback;
  }
  return fallback;
}

Map<String, dynamic> _readMap(dynamic value) {
  if (value is Map) {
    return value.cast<String, dynamic>();
  }
  return <String, dynamic>{};
}

dynamic _readFirst(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key) && json[key] != null) {
      return json[key];
    }
  }
  return null;
}

dynamic _readFirstFilled(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (!json.containsKey(key) || json[key] == null) {
      continue;
    }
    final value = json[key];
    if (value is String && value.trim().isEmpty) {
      continue;
    }
    return value;
  }
  return null;
}

String? _readStringFirst(Map<String, dynamic> json, List<String> keys) {
  final value = _readFirstFilled(json, keys);
  if (value == null || value is Map || value is List) {
    return null;
  }
  return value.toString();
}

Map<String, dynamic> _readAddressMap(Map<String, dynamic> json) {
  for (final key in const [
    'address',
    'addresses',
    'address_details',
    'address_detail',
    'candidate_address',
    'candidateAddress',
  ]) {
    final value = json[key];
    if (value is Map) {
      return value.cast<String, dynamic>();
    }
  }
  return <String, dynamic>{};
}

String? _readCurrentAddress(Map<String, dynamic> json) {
  final addressMap = _readAddressMap(json);
  return _readStringFirst(json, const [
        'current_address',
        'currentAddress',
        'present_address',
        'presentAddress',
        'communication_address',
        'communicationAddress',
        'residential_address',
        'residentialAddress',
      ]) ??
      _readStringFirst(addressMap, const [
        'current_address',
        'currentAddress',
        'current',
        'present_address',
        'presentAddress',
        'present',
        'communication_address',
        'communicationAddress',
        'communication',
        'residential_address',
        'residentialAddress',
        'residential',
        'full_address',
        'fullAddress',
        'line',
      ]) ??
      _readStringFirst(json, const ['address']);
}

String? _readPermanentAddress(Map<String, dynamic> json) {
  final addressMap = _readAddressMap(json);
  return _readStringFirst(json, const [
        'permanent_address',
        'permanentAddress',
        'permanentaddress',
        'permanent_adress',
        'permanentAdress',
        
        'permanent_add',
        'permanentAdd',
        'permanent_addr',
        'permanentAddr',
        'permanent',
        'address_permanent',
        'addressPermanent',
        'permanant_address',
        'permenant_address',
      ]) ??
      _readStringFirst(addressMap, const [
        'permanent_address',
        'permanentAddress',
        'permanentaddress',
        'permanent_adress',
        'permanentAdress',
        'permanent_add',
        'permanentAdd',
        'permanent_addr',
        'permanentAddr',
        'permanent',
        'address_permanent',
        'addressPermanent',
        'permanant_address',
        'permenant_address',
      ]) ??
      _readStringFirst(json, const ['address']);
}

Map<String, dynamic> _readCandidateProfilePayload(Map<String, dynamic> json) {
  final candidate = _readMap(json['candidate']);
  final merged = <String, dynamic>{};

  for (final key in const [
    'applicant_profile',
    'applicantProfile',
    'applicant',
    'profile',
    'candidate_profile',
    'candidateProfile',
  ]) {
    merged.addAll(_readMap(json[key]));
  }

  merged.addAll(candidate);

  final permanentAddress =
      _readPermanentAddress(merged) ?? _readPermanentAddress(json);
  if (permanentAddress != null && permanentAddress.trim().isNotEmpty) {
    merged['permanent_address'] = permanentAddress;
  }

  final currentAddress = _readCurrentAddress(merged) ?? _readCurrentAddress(json);
  if (currentAddress != null && currentAddress.trim().isNotEmpty) {
    merged['current_address'] = currentAddress;
  }

  return merged;
}

class SessionUser {
  const SessionUser({
    required this.id,
    required this.name,
    required this.employeeCode,
    required this.email,
    required this.roleName,
    required this.roleSlug,
    required this.isHr,
  });

  final int id;
  final String name;
  final String employeeCode;
  final String email;
  final String roleName;
  final String roleSlug;
  final bool isHr;

  factory SessionUser.fromJson(Map<String, dynamic> json) {
    final role = (json['role'] as Map?)?.cast<String, dynamic>() ?? {};
    return SessionUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      employeeCode: (json['employee_code'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      roleName: (role['name'] ?? '').toString(),
      roleSlug: (role['slug'] ?? '').toString(),
      isHr: json['is_hr'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'employee_code': employeeCode,
      'email': email,
      'role': {'name': roleName, 'slug': roleSlug},
      'is_hr': isHr,
    };
  }
}

class LoginResult {
  const LoginResult({required this.token, required this.user});

  final String token;
  final SessionUser user;

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      token: (json['token'] ?? '').toString(),
      user: SessionUser.fromJson(
        (json['user'] as Map<dynamic, dynamic>).cast<String, dynamic>(),
      ),
    );
  }
}

class DashboardData {
  const DashboardData({
    required this.stats,
    required this.manpower,
    required this.recentApplications,
  });

  final DashboardStats stats;
  final ManpowerData manpower;
  final List<ApplicationSummary> recentApplications;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final payload = _readMap(json['data']).isNotEmpty
        ? _readMap(json['data'])
        : json;
    final statsJson = _readMap(
      _readFirst(payload, const ['stats', 'dashboard_stats', 'counts']) ??
          payload,
    );
    final manpowerJson = _readMap(
      _readFirst(payload, const ['manpower', 'manpower_data', 'overview']),
    );
    final recentApplicationsJson =
        (_readFirst(payload, const [
              'recent_applications',
              'recentApplications',
            ])
            as List?) ??
        [];

    return DashboardData(
      stats: DashboardStats.fromJson(statsJson),
      manpower: ManpowerData.fromJson(manpowerJson),
      recentApplications: recentApplicationsJson
          .map(
            (item) => ApplicationSummary.fromJson(
              (item as Map<dynamic, dynamic>).cast<String, dynamic>(),
            ),
          )
          .toList(),
    );
  }
}

class DashboardStats {
  const DashboardStats({
    required this.totalApplications,
    required this.todayApplications,
    required this.totalApplicants,
    required this.pendingL1,
    required this.pendingL2,
    required this.pendingL3,
    required this.pendingL4,
    required this.joinedThisMonth,
    required this.onHold,
    required this.offersReleased,
    required this.rejected,
    required this.completedThisMonth,
  });

  final int totalApplications;
  final int todayApplications;
  final int totalApplicants;
  final int pendingL1;
  final int pendingL2;
  final int pendingL3;
  final int pendingL4;
  final int joinedThisMonth;
  final int onHold;
  final int offersReleased;
  final int rejected;
  final int completedThisMonth;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    int read(List<String> keys) => _readInt(_readFirst(json, keys));
    return DashboardStats(
      totalApplications: read(const [
        'total_applications',
        'totalApplications',
        'applications_total',
      ]),
      todayApplications: read(const [
        'today_applications',
        'todayApplications',
        'today_application',
      ]),
      totalApplicants: read(const [
        'total_applicants',
        'totalApplicants',
        'applicants_total',
      ]),
      pendingL1: read(const [
        'pending_l1',
        'pendingL1',
        'pending_pre_screening',
      ]),
      pendingL2: read(const ['pending_l2', 'pendingL2']),
      pendingL3: read(const ['pending_l3', 'pendingL3']),
      pendingL4: read(const ['pending_l4', 'pendingL4']),
      joinedThisMonth: read(const [
        'joined_this_month',
        'joinedThisMonth',
        'joined_month',
      ]),
      onHold: read(const ['on_hold', 'onHold', 'hold']),
      offersReleased: read(const [
        'offers_released',
        'offersReleased',
        'offer_released',
      ]),
      rejected: read(const ['rejected', 'rejected_count']),
      completedThisMonth: read(const [
        'completed_this_month',
        'completedThisMonth',
        'completed_month',
      ]),
    );
  }
}

class ManpowerData {
  const ManpowerData({
    required this.totalRequired,
    required this.totalCurrent,
    required this.totalVacancy,
    required this.noticePeriod,
    required this.fillRate,
    required this.branches,
    required this.designations,
  });

  final int totalRequired;
  final int totalCurrent;
  final int totalVacancy;
  final int noticePeriod;
  final int fillRate;
  final int branches;
  final List<DesignationStrength> designations;

  factory ManpowerData.fromJson(Map<String, dynamic> json) {
    int read(String key) => _readInt(json[key]);
    return ManpowerData(
      totalRequired: read('total_required'),
      totalCurrent: read('total_current'),
      totalVacancy: read('total_vacancy'),
      noticePeriod: read('notice_period'),
      fillRate: read('fill_rate'),
      branches: read('branches'),
      designations: ((json['designations'] as List?) ?? [])
          .map(
            (item) => DesignationStrength.fromJson(
              (item as Map<dynamic, dynamic>).cast<String, dynamic>(),
            ),
          )
          .toList(),
    );
  }
}

class DesignationStrength {
  const DesignationStrength({
    required this.name,
    required this.full,
    required this.requiredCount,
    required this.currentCount,
    required this.vacancy,
  });

  final String name;
  final String full;
  final int requiredCount;
  final int currentCount;
  final int vacancy;

  factory DesignationStrength.fromJson(Map<String, dynamic> json) {
    return DesignationStrength(
      name: (json['name'] ?? '').toString(),
      full: (json['full'] ?? '').toString(),
      requiredCount: _readInt(json['req']),
      currentCount: _readInt(json['cur']),
      vacancy: _readInt(json['vacancy']),
    );
  }
}

class ApplicationPage {
  const ApplicationPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  final List<ApplicationSummary> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  factory ApplicationPage.fromJson(Map<String, dynamic> json) {
    return ApplicationPage(
      items: ((json['items'] as List?) ?? [])
          .map(
            (item) => ApplicationSummary.fromJson(
              (item as Map<dynamic, dynamic>).cast<String, dynamic>(),
            ),
          )
          .toList(),
      currentPage: _readInt(json['current_page'], fallback: 1),
      lastPage: _readInt(json['last_page'], fallback: 1),
      perPage: _readInt(json['per_page'], fallback: 20),
      total: _readInt(json['total']),
    );
  }
}

class ApplicationSummary {
  const ApplicationSummary({
    required this.id,
    required this.applicantProfileId,
    required this.candidateName,
    required this.contact,
    required this.email,
    required this.gender,
    required this.qualification,
    required this.jobExperience,
    required this.position,
    required this.branch,
    required this.statusCode,
    required this.statusLabel,
    required this.stage,
    required this.preScreening,
    required this.assignedTo,
    required this.hrManager,
    required this.createdAt,
    required this.applicationCount,
  });

  final int id;
  final int applicantProfileId;
  final String candidateName;
  final String contact;
  final String email;
  final String gender;
  final String qualification;
  final bool jobExperience;
  final String position;
  final String branch;
  final String statusCode;
  final String statusLabel;
  final int stage;
  final String? preScreening;
  final String? assignedTo;
  final String? hrManager;
  final String createdAt;
  final int applicationCount;

  factory ApplicationSummary.fromJson(Map<String, dynamic> json) {
    return ApplicationSummary(
      id: _readInt(json['id']),
      applicantProfileId: _readInt(
        _readFirst(json, const [
          'applicant_profile_id',
          'applicant_id',
          'candidate_id',
          'profile_id',
        ]),
      ),
      candidateName: (json['candidate_name'] ?? '').toString(),
      contact: (json['contact'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      gender: (json['gender'] ?? '').toString(),
      qualification: (json['qualification'] ?? '').toString(),
      jobExperience: _readJobExperience(json['job_experience']),
      position: (json['position'] ?? '').toString(),
      branch: (json['branch'] ?? '').toString(),
      statusCode: (json['status_code'] ?? '').toString(),
      statusLabel: (json['status_label'] ?? '').toString(),
      stage: _readInt(json['stage']),
      preScreening: json['pre_screening']?.toString(),
      assignedTo: json['assigned_to']?.toString(),
      hrManager: json['hr_manager']?.toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      applicationCount: _readInt(
        _readFirst(json, const [
          'application_count',
          'applications_count',
          'applications',
        ]),
      ),
    );
  }
}

class ApplicationDetail {
  const ApplicationDetail({
    required this.id,
    required this.currentStage,
    required this.statusCode,
    required this.statusLabel,
    required this.preScreening,
    required this.salaryOffered,
    required this.remarks,
    required this.lagDays,
    required this.createdAt,
    required this.updatedAt,
    required this.candidate,
    required this.position,
    required this.targetBranch,
    required this.assignedTo,
    required this.hrManager,
    required this.stages,
    required this.offerConsent,
    required this.joiningForm,
  });

  final int id;
  final int currentStage;
  final String statusCode;
  final String statusLabel;
  final String? preScreening;
  final String? salaryOffered;
  final String? remarks;
  final int? lagDays;
  final String createdAt;
  final String updatedAt;
  final CandidateProfile candidate;
  final PositionDetail? position;
  final BranchDetail? targetBranch;
  final SimpleUser? assignedTo;
  final SimpleUser? hrManager;
  final List<ApplicationStage> stages;
  final OfferConsent? offerConsent;
  final JoiningForm? joiningForm;

  factory ApplicationDetail.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? readMap(String key) =>
        (json[key] as Map?)?.cast<String, dynamic>();

    return ApplicationDetail(
      id: _readInt(json['id']),
      currentStage: _readInt(json['current_stage']),
      statusCode: (json['status_code'] ?? '').toString(),
      statusLabel: (json['status_label'] ?? '').toString(),
      preScreening: json['pre_screening']?.toString(),
      salaryOffered: json['salary_offered']?.toString(),
      remarks: json['remarks']?.toString(),
      lagDays: json['lag_days'] == null ? null : _readInt(json['lag_days']),
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),
      candidate: CandidateProfile.fromJson(_readCandidateProfilePayload(json)),
      position: readMap('position') == null
          ? null
          : PositionDetail.fromJson(readMap('position')!),
      targetBranch: readMap('target_branch') == null
          ? null
          : BranchDetail.fromJson(readMap('target_branch')!),
      assignedTo: readMap('assigned_to') == null
          ? null
          : SimpleUser.fromJson(readMap('assigned_to')!),
      hrManager: readMap('hr_manager') == null
          ? null
          : SimpleUser.fromJson(readMap('hr_manager')!),
      stages: ((json['stages'] as List?) ?? [])
          .map(
            (item) => ApplicationStage.fromJson(
              (item as Map<dynamic, dynamic>).cast<String, dynamic>(),
            ),
          )
          .toList(),
      offerConsent: readMap('offer_consent') == null
          ? null
          : OfferConsent.fromJson(readMap('offer_consent')!),
      joiningForm: readMap('joining_form') == null
          ? null
          : JoiningForm.fromJson(readMap('joining_form')!),
    );
  }
}

class CandidateProfile {
  const CandidateProfile({
    required this.id,
    required this.name,
    required this.dob,
    required this.age,
    required this.gender,
    required this.contactNumber,
    required this.email,
    required this.qualification,
    required this.positionApplied,
    required this.jobExperience,
    required this.expectedSalary,
    required this.maritalStatus,
    required this.caste,
    required this.aadhaarNumber,
    required this.hometown,
    required this.address,
    required this.permanentAddress,
    required this.languages,
    required this.twoWheeler,
    required this.fourWheeler,
    required this.profilePic,
    required this.resume,
    required this.documents,
    required this.preferredBranches,
    required this.appliedAt,
  });

  final int id;
  final String name;
  final String? dob;
  final int? age;
  final String gender;
  final String contactNumber;
  final String email;
  final String qualification;
  final String positionApplied;
  final bool jobExperience;
  final String? expectedSalary;
  final String? maritalStatus;
  final String? caste;
  final String? aadhaarNumber;
  final String? hometown;
  final String? address;
  final String? permanentAddress;
  final List<String> languages;
  final bool twoWheeler;
  final bool fourWheeler;
  final String? profilePic;
  final String? resume;
  final List<CandidateDocument> documents;
  final List<String> preferredBranches;
  final String? appliedAt;

  factory CandidateProfile.fromJson(Map<String, dynamic> json) {
    return CandidateProfile(
      id: _readInt(
        _readFirst(json, const ['id', 'applicant_profile_id', 'candidate_id']),
      ),
      name:
          (_readFirst(json, const ['name', 'candidate_name', 'full_name']) ?? '')
              .toString(),
      dob:
          _readFirst(json, const ['dob', 'date_of_birth', 'dateOfBirth'])
              ?.toString(),
      age: (json['age'] as num?)?.toInt(),
      gender: (json['gender'] ?? '').toString(),
      contactNumber:
          (_readFirst(json, const ['contact_number', 'contact', 'phone']) ?? '')
              .toString(),
      email: (_readFirst(json, const ['email', 'email_id']) ?? '').toString(),
      qualification:
          (_readFirst(json, const ['qualification', 'education']) ?? '')
              .toString(),
      positionApplied:
          (_readFirst(json, const ['position_applied', 'position']) ?? '')
              .toString(),
      jobExperience: _readJobExperience(json['job_experience']),
      expectedSalary:
          _readFirst(json, const ['expected_salary', 'expectedSalary'])
              ?.toString(),
      maritalStatus:
          _readFirst(json, const ['marital_status', 'maritalStatus', 'marital'])
              ?.toString(),
      caste: _readFirst(json, const ['caste', 'community'])?.toString(),
      aadhaarNumber:
          _readFirst(json, const [
            'aadhaar_number',
            'aadhar_number',
            'aadhaar',
            'aadhar',
          ])?.toString(),
      hometown:
          _readFirst(json, const [
            'hometown',
            'home_town',
            'native_place',
            'nativePlace',
            'city',
          ])?.toString(),
      address: _readCurrentAddress(json),
      permanentAddress: _readPermanentAddress(json),
      languages: ((json['languages'] as List?) ?? []).map((e) => '$e').toList(),
      twoWheeler: json['two_wheeler'] == true,
      fourWheeler: json['four_wheeler'] == true,
      profilePic:
          _readFirst(json, const [
            'profile_pic',
            'profilePic',
            'photo',
            'image',
            'avatar',
          ])?.toString(),
      resume: json['resume']?.toString(),
      documents: CandidateDocument.listFromCandidateJson(json),
      preferredBranches: ((json['preferred_branches'] as List?) ?? [])
          .map((item) {
            if (item is Map) {
              final map = item.cast<String, dynamic>();
              return (map['name'] ?? map['code'] ?? map['id'] ?? '')
                  .toString();
            }
            return '$item';
          })
          .where((item) => item.trim().isNotEmpty)
          .toList(),
      appliedAt: json['applied_at']?.toString(),
    );
  }

  factory CandidateProfile.fromApplicantLookup(ApplicantLookup candidate) {
    return CandidateProfile(
      id: candidate.id,
      name: candidate.name,
      dob: candidate.dob,
      age: candidate.age,
      gender: candidate.gender,
      contactNumber: candidate.contactNumber,
      email: candidate.email,
      qualification: candidate.qualification,
      positionApplied: candidate.positionApplied,
      jobExperience: candidate.jobExperience,
      expectedSalary: null,
      maritalStatus: candidate.maritalStatus,
      caste: candidate.caste,
      aadhaarNumber: candidate.aadhaarNumber,
      hometown: candidate.hometown,
      address: candidate.address,
      permanentAddress: candidate.permanentAddress,
      languages: const [],
      twoWheeler: false,
      fourWheeler: false,
      profilePic: candidate.profilePic,
      resume: null,
      documents: const [],
      preferredBranches: const [],
      appliedAt: candidate.appliedAt,
    );
  }
}

class CandidateDocument {
  const CandidateDocument({
    required this.title,
    required this.fileName,
    required this.filePath,
    required this.status,
    required this.isApproved,
  });

  final String title;
  final String fileName;
  final String? filePath;
  final String status;
  final bool isApproved;

  static List<CandidateDocument> listFromCandidateJson(
    Map<String, dynamic> json,
  ) {
    final fromArray =
        ((_readFirst(json, const [
                  'documents',
                  'candidate_documents',
                  'uploaded_documents',
                ])
                as List?) ??
            [])
        .whereType<Map>()
        .map((item) => CandidateDocument.fromJson(item.cast<String, dynamic>()))
        .toList();
    if (fromArray.isNotEmpty) {
      return fromArray;
    }

    const fieldDocuments = [
      _DocumentField('Bank Book Front Page', [
        'bank_book_front_page',
        'bank_book',
        'bank_passbook',
        'passbook',
      ]),
      _DocumentField('Aadhar Card', [
        'aadhaar_card',
        'aadhar_card',
        'aadhaar_document',
        'aadhar_document',
      ]),
      _DocumentField('PAN Card', [
        'pan_card',
        'pan_document',
        'pan',
      ]),
      _DocumentField('Voter ID', [
        'voter_id',
        'voter_card',
        'voter_document',
      ]),
      _DocumentField('Driving Licence / LLR', [
        'driving_licence',
        'driving_license',
        'driving_licence_llr',
        'driving_license_llr',
        'llr',
      ]),
    ];

    return fieldDocuments
        .map((field) {
          final path = _readFirst(json, field.keys)?.toString();
          if (path == null || path.trim().isEmpty) {
            return null;
          }
          return CandidateDocument.fromFile(
            title: field.title,
            filePath: path,
            status: 'approved',
          );
        })
        .whereType<CandidateDocument>()
        .toList();
  }

  factory CandidateDocument.fromFile({
    required String title,
    required String filePath,
    String status = '',
  }) {
    final approved = status.trim().toLowerCase() == 'approved';
    return CandidateDocument(
      title: title,
      fileName: _fileNameFromPath(filePath),
      filePath: filePath,
      status: status,
      isApproved: approved,
    );
  }

  factory CandidateDocument.fromJson(Map<String, dynamic> json) {
    final path = _readFirst(json, const [
      'file_path',
      'path',
      'url',
      'file_url',
      'document',
    ])?.toString();
    final fileName =
        _readFirst(json, const [
          'file_name',
          'filename',
          'original_name',
          'name',
        ])?.toString() ??
        path ??
        '';
    final status = (_readFirst(json, const [
              'status',
              'approval_status',
              'verification_status',
            ]) ??
            '')
        .toString();
    final approvedValue = _readFirst(json, const ['is_approved', 'approved']);
    final isApproved =
        approvedValue == true || status.trim().toLowerCase() == 'approved';

    return CandidateDocument(
      title:
          (_readFirst(json, const [
                    'type',
                    'document_type',
                    'title',
                    'label',
                  ]) ??
                  fileName)
              .toString(),
      fileName: fileName,
      filePath: path,
      status: status,
      isApproved: isApproved,
    );
  }
}

class _DocumentField {
  const _DocumentField(this.title, this.keys);

  final String title;
  final List<String> keys;
}

String _fileNameFromPath(String path) {
  final normalized = path.replaceAll('\\', '/');
  final parts = normalized.split('/');
  return parts.isEmpty ? path : parts.last;
}

class PositionDetail {
  const PositionDetail({
    required this.id,
    required this.shortName,
    required this.fullName,
    required this.category,
    required this.interviewLevels,
  });

  final int id;
  final String shortName;
  final String fullName;
  final String category;
  final int interviewLevels;

  factory PositionDetail.fromJson(Map<String, dynamic> json) {
    return PositionDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      shortName: (json['short_name'] ?? '').toString(),
      fullName: (json['full_name'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      interviewLevels: (json['interview_levels'] as num?)?.toInt() ?? 0,
    );
  }
}

class BranchDetail {
  const BranchDetail({
    required this.id,
    required this.name,
    required this.code,
    required this.zone,
    required this.cluster,
    required this.state,
    required this.city,
  });

  final int id;
  final String name;
  final String code;
  final String? zone;
  final String? cluster;
  final String? state;
  final String? city;

  factory BranchDetail.fromJson(Map<String, dynamic> json) {
    return BranchDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      zone: json['zone']?.toString() ?? json['zone_name']?.toString(),
      cluster: json['cluster']?.toString() ?? json['cluster_name']?.toString(),
      state: json['state']?.toString(),
      city: json['city']?.toString(),
    );
  }
}

class SimpleUser {
  const SimpleUser({
    required this.id,
    required this.name,
    required this.role,
    required this.designation,
    required this.employeeCode,
  });

  final int id;
  final String name;
  final String? role;
  final String? designation;
  final String? employeeCode;

  factory SimpleUser.fromJson(Map<String, dynamic> json) {
    return SimpleUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      role: json['role']?.toString(),
      designation: json['designation']?.toString(),
      employeeCode: json['employee_code']?.toString(),
    );
  }
}

class ApplicationStage {
  const ApplicationStage({
    required this.id,
    required this.stageNumber,
    required this.stageName,
    required this.actionTaken,
    required this.remarks,
    required this.interviewSlot,
    required this.completedAt,
    required this.doneBy,
    required this.interviewer,
    required this.attachments,
  });

  final int id;
  final int stageNumber;
  final String stageName;
  final String actionTaken;
  final String? remarks;
  final String? interviewSlot;
  final String? completedAt;
  final String? doneBy;
  final SimpleUser? interviewer;
  final List<StageAttachment> attachments;

  factory ApplicationStage.fromJson(Map<String, dynamic> json) {
    return ApplicationStage(
      id: _readInt(json['id']),
      stageNumber: _readInt(json['stage_number']),
      stageName: (json['stage_name'] ?? '').toString(),
      actionTaken: (json['action_taken'] ?? '').toString(),
      remarks: json['remarks']?.toString(),
      interviewSlot: json['interview_slot']?.toString(),
      completedAt: json['completed_at']?.toString(),
      doneBy: json['done_by']?.toString(),
      interviewer: (json['interviewer'] as Map?) == null
          ? null
          : SimpleUser.fromJson(
              (json['interviewer'] as Map<dynamic, dynamic>)
                  .cast<String, dynamic>(),
            ),
      attachments: ((json['attachments'] as List?) ?? [])
          .map(
            (item) => StageAttachment.fromJson(
              (item as Map<dynamic, dynamic>).cast<String, dynamic>(),
            ),
          )
          .toList(),
    );
  }
}

class StageAttachment {
  const StageAttachment({
    required this.id,
    required this.fileName,
    required this.type,
    required this.fileType,
    required this.fileSize,
    required this.uploadedBy,
    required this.createdAt,
  });

  final int id;
  final String fileName;
  final String type;
  final String fileType;
  final int fileSize;
  final String uploadedBy;
  final String createdAt;

  factory StageAttachment.fromJson(Map<String, dynamic> json) {
    return StageAttachment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fileName: (json['file_name'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      fileType: (json['file_type'] ?? '').toString(),
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      uploadedBy: (json['uploaded_by'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}

class OfferConsent {
  const OfferConsent({
    required this.status,
    required this.respondedAt,
    required this.expiresAt,
    required this.isExpired,
    required this.totalReleases,
  });

  final String status;
  final String? respondedAt;
  final String? expiresAt;
  final bool isExpired;
  final int totalReleases;

  factory OfferConsent.fromJson(Map<String, dynamic> json) {
    return OfferConsent(
      status: (json['status'] ?? '').toString(),
      respondedAt: json['responded_at']?.toString(),
      expiresAt: json['expires_at']?.toString(),
      isExpired: json['is_expired'] == true,
      totalReleases: (json['total_releases'] as num?)?.toInt() ?? 0,
    );
  }
}

class JoiningForm {
  const JoiningForm({
    required this.id,
    required this.submittedAt,
    required this.employeeStatus,
  });

  final int id;
  final String? submittedAt;
  final String? employeeStatus;

  factory JoiningForm.fromJson(Map<String, dynamic> json) {
    return JoiningForm(
      id: (json['id'] as num?)?.toInt() ?? 0,
      submittedAt: json['submitted_at']?.toString(),
      employeeStatus: json['employee_status']?.toString(),
    );
  }
}

class ProfileData {
  const ProfileData({
    required this.id,
    required this.name,
    required this.employeeCode,
    required this.email,
    required this.isActive,
    required this.isHr,
    required this.role,
    required this.designation,
    required this.branch,
    required this.activity,
    required this.recentLogins,
  });

  final int id;
  final String name;
  final String employeeCode;
  final String email;
  final bool isActive;
  final bool isHr;
  final RoleInfo role;
  final DesignationInfo? designation;
  final BranchDetail? branch;
  final ActivityInfo activity;
  final List<LoginSessionInfo> recentLogins;

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      id: _readInt(json['id']),
      name: (json['name'] ?? '').toString(),
      employeeCode: (json['employee_code'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      isActive: json['is_active'] == true,
      isHr: json['is_hr'] == true,
      role: RoleInfo.fromJson(
        ((json['role'] as Map?) ?? <String, dynamic>{}).cast<String, dynamic>(),
      ),
      designation: (json['designation'] as Map?) == null
          ? null
          : DesignationInfo.fromJson(
              (json['designation'] as Map<dynamic, dynamic>)
                  .cast<String, dynamic>(),
            ),
      branch: (json['branch'] as Map?) == null
          ? null
          : BranchDetail.fromJson(
              (json['branch'] as Map<dynamic, dynamic>).cast<String, dynamic>(),
            ),
      activity: ActivityInfo.fromJson(
        ((json['activity'] as Map?) ?? <String, dynamic>{})
            .cast<String, dynamic>(),
      ),
      recentLogins: ((json['recent_logins'] as List?) ?? [])
          .map(
            (item) => LoginSessionInfo.fromJson(
              (item as Map<dynamic, dynamic>).cast<String, dynamic>(),
            ),
          )
          .toList(),
    );
  }
}

class RoleInfo {
  const RoleInfo({required this.id, required this.name, required this.slug});

  final int id;
  final String name;
  final String slug;

  factory RoleInfo.fromJson(Map<String, dynamic> json) {
    return RoleInfo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
    );
  }
}

class DesignationInfo {
  const DesignationInfo({
    required this.id,
    required this.shortName,
    required this.fullName,
  });

  final int id;
  final String shortName;
  final String fullName;

  factory DesignationInfo.fromJson(Map<String, dynamic> json) {
    return DesignationInfo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      shortName: (json['short_name'] ?? '').toString(),
      fullName: (json['full_name'] ?? '').toString(),
    );
  }
}

class ActivityInfo {
  const ActivityInfo({
    required this.assignedApplications,
    required this.managedApplications,
  });

  final int assignedApplications;
  final int managedApplications;

  factory ActivityInfo.fromJson(Map<String, dynamic> json) {
    return ActivityInfo(
      assignedApplications: _readInt(json['assigned_applications']),
      managedApplications: _readInt(json['managed_applications']),
    );
  }
}

class LoginSessionInfo {
  const LoginSessionInfo({
    required this.status,
    required this.ipAddress,
    required this.loggedInAt,
    required this.loggedOutAt,
  });

  final String status;
  final String? ipAddress;
  final String? loggedInAt;
  final String? loggedOutAt;

  factory LoginSessionInfo.fromJson(Map<String, dynamic> json) {
    return LoginSessionInfo(
      status: (json['status'] ?? '').toString(),
      ipAddress: json['ip_address']?.toString(),
      loggedInAt: json['logged_in_at']?.toString(),
      loggedOutAt: json['logged_out_at']?.toString(),
    );
  }
}

class LookupOption {
  const LookupOption({required this.id, required this.title, this.subtitle});

  final int id;
  final String title;
  final String? subtitle;
}

class ApplicantLookup {
  const ApplicantLookup({
    required this.id,
    required this.name,
    required this.contactNumber,
    required this.email,
    required this.positionApplied,
    required this.qualification,
    required this.gender,
    required this.jobExperience,
    required this.appliedAt,
    required this.applicationCount,
    required this.profilePic,
    this.dob,
    this.age,
    this.maritalStatus,
    this.caste,
    this.aadhaarNumber,
    this.hometown,
    this.address,
    this.permanentAddress,
  });

  final int id;
  final String name;
  final String contactNumber;
  final String email;
  final String positionApplied;
  final String qualification;
  final String gender;
  final bool jobExperience;
  final String appliedAt;
  final int applicationCount;
  final String? profilePic;
  final String? dob;
  final int? age;
  final String? maritalStatus;
  final String? caste;
  final String? aadhaarNumber;
  final String? hometown;
  final String? address;
  final String? permanentAddress;

  factory ApplicantLookup.fromJson(Map<String, dynamic> json) {
    return ApplicantLookup(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      contactNumber: (json['contact_number'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      positionApplied: (json['position_applied'] ?? '').toString(),
      qualification: (json['qualification'] ?? '').toString(),
      gender: (json['gender'] ?? '').toString(),
      jobExperience: _readJobExperience(json['job_experience']),
      appliedAt:
          _readFirst(json, const ['applied_at', 'created_at', 'createdAt'])
              ?.toString() ??
          '',
      applicationCount: _readInt(
        _readFirst(json, const [
          'application_count',
          'applications_count',
          'applications',
        ]),
      ),
      profilePic:
          _readFirst(json, const [
            'profile_pic',
            'profilePic',
            'photo',
            'image',
            'avatar',
          ])?.toString(),
      dob:
          _readFirst(json, const ['dob', 'date_of_birth', 'dateOfBirth'])
              ?.toString(),
      age: (json['age'] as num?)?.toInt(),
      maritalStatus:
          _readFirst(json, const ['marital_status', 'maritalStatus', 'marital'])
              ?.toString(),
      caste: _readFirst(json, const ['caste', 'community'])?.toString(),
      aadhaarNumber:
          _readFirst(json, const [
            'aadhaar_number',
            'aadhar_number',
            'aadhaar',
            'aadhar',
          ])?.toString(),
      hometown:
          _readFirst(json, const [
            'hometown',
            'home_town',
            'native_place',
            'nativePlace',
            'city',
          ])?.toString(),
      address: _readCurrentAddress(json),
      permanentAddress: _readPermanentAddress(json),
    );
  }
}

bool _readJobExperience(dynamic value) {
  if (value == true || value == 1) {
    return true;
  }
  final normalized = value?.toString().trim().toLowerCase() ?? '';
  return normalized == 'true' ||
      normalized == 'yes' ||
      normalized == '1' ||
      normalized == 'experienced' ||
      normalized == 'experience';
}

class CreatedApplication {
  const CreatedApplication({
    required this.id,
    required this.candidate,
    required this.position,
    required this.branch,
    required this.statusCode,
    required this.statusLabel,
    required this.createdAt,
  });

  final int id;
  final String candidate;
  final String position;
  final String branch;
  final String statusCode;
  final String statusLabel;
  final String createdAt;

  factory CreatedApplication.fromJson(Map<String, dynamic> json) {
    return CreatedApplication(
      id: (json['id'] as num?)?.toInt() ?? 0,
      candidate: (json['candidate'] ?? '').toString(),
      position: (json['position'] ?? '').toString(),
      branch: (json['branch'] ?? '').toString(),
      statusCode: (json['status_code'] ?? '').toString(),
      statusLabel: (json['status_label'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}

class CreateApplicationRequest {
  const CreateApplicationRequest({
    required this.applicantProfileId,
    this.positionId,
    this.targetBranchId,
    this.hrManagerId,
    this.assignedToUserId,
    this.remarks,
  });

  final int applicantProfileId;
  final int? positionId;
  final int? targetBranchId;
  final int? hrManagerId;
  final int? assignedToUserId;
  final String? remarks;

  Map<String, dynamic> toJson() {
    return {
      'applicant_profile_id': applicantProfileId,
      if (positionId != null) 'position_id': positionId,
      if (targetBranchId != null) 'target_branch_id': targetBranchId,
      if (hrManagerId != null) 'hr_manager_id': hrManagerId,
      if (assignedToUserId != null) 'assigned_to_user_id': assignedToUserId,
      if (remarks != null && remarks!.trim().isNotEmpty) 'remarks': remarks,
    };
  }
}

class ApiClient {
  ApiClient._();

  AppSession get _session => AppSession.instance;

  Future<LoginResult> login({
    required String employeeCode,
    required String password,
  }) async {
    final payload = {
      'employee_code': employeeCode.trim().toUpperCase(),
      'password': password,
    };

    final json = await _request(
      method: 'POST',
      path: '/auth/login',
      body: payload,
      requiresAuth: false,
    );
    return LoginResult.fromJson(json);
  }

  Future<void> logout() async {
    await _request(method: 'POST', path: '/auth/logout');
  }

  Future<DashboardData> getDashboard() async {
    final json = await _request(method: 'GET', path: '/dashboard');
    return DashboardData.fromJson(json);
  }

  Future<ApplicationPage> getApplications({
    String? search,
    String? status,
    int? branchId,
    int page = 1,
    int perPage = 20,
    bool myApps = false,
  }) async {
    final json = await _request(
      method: 'GET',
      path: '/applications',
      query: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (status != null && status.isNotEmpty) 'status': status,
        if (branchId != null) 'branch_id': '$branchId',
        if (myApps) 'my_apps': '1',
        'page': '$page',
        'per_page': '$perPage',
      },
    );
    return ApplicationPage.fromJson(
      (json['data'] as Map<dynamic, dynamic>).cast<String, dynamic>(),
    );
  }

  Future<ApplicationDetail> getApplicationDetail(int id) async {
    final json = await _request(method: 'GET', path: '/applications/$id');
    return ApplicationDetail.fromJson(
      (json['data'] as Map<dynamic, dynamic>).cast<String, dynamic>(),
    );
  }

  Future<ProfileData> getProfile() async {
    final json = await _request(method: 'GET', path: '/profile');
    return ProfileData.fromJson(
      (json['data'] as Map<dynamic, dynamic>).cast<String, dynamic>(),
    );
  }

  Future<List<LookupOption>> getDesignations() async {
    final json = await _request(method: 'GET', path: '/meta/designations');
    return ((json['data'] as List?) ?? []).map((item) {
      final map = (item as Map<dynamic, dynamic>).cast<String, dynamic>();
      return LookupOption(
        id: (map['id'] as num?)?.toInt() ?? 0,
        title: (map['short_name'] ?? '').toString(),
        subtitle: (map['full_name'] ?? '').toString(),
      );
    }).toList();
  }

  Future<List<LookupOption>> getBranches() async {
    final json = await _request(method: 'GET', path: '/meta/branches');
    return ((json['data'] as List?) ?? []).map((item) {
      final map = (item as Map<dynamic, dynamic>).cast<String, dynamic>();
      return LookupOption(
        id: (map['id'] as num?)?.toInt() ?? 0,
        title: (map['name'] ?? '').toString(),
        subtitle: (map['code'] ?? '').toString(),
      );
    }).toList();
  }

  Future<List<LookupOption>> getHrUsers() async {
    final json = await _request(method: 'GET', path: '/meta/hr-users');
    return ((json['data'] as List?) ?? []).map((item) {
      final map = (item as Map<dynamic, dynamic>).cast<String, dynamic>();
      return LookupOption(
        id: (map['id'] as num?)?.toInt() ?? 0,
        title: (map['name'] ?? '').toString(),
        subtitle: (map['designation'] ?? map['role'] ?? '').toString(),
      );
    }).toList();
  }

  Future<List<ApplicantLookup>> searchApplicants(String search) async {
    return getCandidates(search: search);
  }

  Future<List<ApplicantLookup>> getCandidates({String? search}) async {
    final json = await _request(
      method: 'GET',
      path: '/meta/applicants',
      query: {
        if (search != null && search.trim().isNotEmpty)
          'search': search.trim(),
      },
    );
    return ((json['data'] as List?) ?? [])
        .map(
          (item) => ApplicantLookup.fromJson(
            (item as Map<dynamic, dynamic>).cast<String, dynamic>(),
          ),
        )
        .toList();
  }

  Future<CandidateProfile> getCandidateProfile(int id) async {
    ApiException? lastError;
    for (final path in [
      '/meta/applicants/$id',
      '/applicants/$id',
      '/applicant-profiles/$id',
      '/applicant_profiles/$id',
      '/candidates/$id',
      '/candidate/$id',
      '/profiles/$id',
    ]) {
      try {
        final json = await _request(method: 'GET', path: path);
        return CandidateProfile.fromJson(_extractCandidateMap(json));
      } on ApiException catch (error) {
        lastError = error;
      }
    }

    throw lastError ?? ApiException('Unable to load candidate profile.');
  }

  Future<CandidateProfile> getCandidateProfileFromAllCandidates(
    ApplicantLookup candidate,
  ) async {
    if (candidate.id > 0) {
      try {
        return await getCandidateProfile(candidate.id);
      } on ApiException {
        // Fall back to the applicant lookup endpoint below. Some deployments
        // only expose `/meta/applicants` for the All Candidates listing.
      }
    }

    final query = candidate.contactNumber.trim().isNotEmpty
        ? candidate.contactNumber
        : candidate.name;
    final candidates = await getCandidates(search: query);

    for (final item in candidates) {
      if (item.id == candidate.id) {
        return CandidateProfile.fromApplicantLookup(item);
      }
    }
    for (final item in candidates) {
      if (item.contactNumber.isNotEmpty &&
          item.contactNumber == candidate.contactNumber) {
        return CandidateProfile.fromApplicantLookup(item);
      }
    }
    for (final item in candidates) {
      if (item.name.trim().toLowerCase() ==
          candidate.name.trim().toLowerCase()) {
        return CandidateProfile.fromApplicantLookup(item);
      }
    }
    if (candidates.isNotEmpty) {
      return CandidateProfile.fromApplicantLookup(candidates.first);
    }

    return CandidateProfile.fromApplicantLookup(candidate);
  }

  Map<String, dynamic> _extractCandidateMap(Map<String, dynamic> json) {
    Map<String, dynamic> normalize(dynamic value) {
      if (value is Map<dynamic, dynamic>) {
        return value.cast<String, dynamic>();
      }
      return <String, dynamic>{};
    }

    final data = normalize(json['data']);
    for (final container in [data, json]) {
      for (final key in const [
        'candidate',
        'applicant',
        'applicant_profile',
        'applicantProfile',
        'profile',
        'user',
      ]) {
        final nested = normalize(container[key]);
        if (nested.isNotEmpty) {
          return nested;
        }
      }
      if (container.isNotEmpty) {
        return container;
      }
    }

    return json;
  }

  Future<CreatedApplication> createApplication(
    CreateApplicationRequest request,
  ) async {
    final json = await _request(
      method: 'POST',
      path: '/applications',
      body: request.toJson(),
    );
    return CreatedApplication.fromJson(
      (json['data'] as Map<dynamic, dynamic>).cast<String, dynamic>(),
    );
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required String path,
    Map<String, String>? query,
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    final token = _session.token;
    if (requiresAuth && (token == null || token.isEmpty)) {
      throw ApiException('Please log in first.');
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (requiresAuth) 'Authorization': 'Bearer $token',
    };

    ApiException? lastError;
    for (final baseUrl in ApiConfig.candidateBaseUrls) {
      final uri = Uri.parse(
        '$baseUrl$path',
      ).replace(queryParameters: query == null || query.isEmpty ? null : query);

      late http.Response response;
      try {
        debugPrint('ApiClient: $method $uri');
        if (method == 'GET') {
          response = await http.get(uri, headers: headers);
        } else if (method == 'POST') {
          response = await http.post(
            uri,
            headers: headers,
            body: body == null ? null : jsonEncode(body),
          );
        } else {
          throw UnsupportedError('Unsupported method $method');
        }
      } on Exception catch (error) {
        debugPrint('ApiClient: $method $uri connection failed: $error');
        lastError = ApiException(
          'Could not connect to $baseUrl. Check that the API server is running and reachable from this device.',
        );
        continue;
      }

      final responseBody = response.body.trim();
      final contentType = response.headers['content-type'] ?? '';
      debugPrint(
        'ApiClient: $method $uri -> ${response.statusCode} ${response.reasonPhrase ?? ''}',
      );

      if (responseBody.isNotEmpty && !_looksLikeJson(responseBody)) {
        debugPrint(
          'ApiClient: $method $uri returned non-JSON response: ${responseBody.length} chars',
        );
        lastError = ApiException(
          _buildNonJsonResponseMessage(
            uri: uri,
            statusCode: response.statusCode,
            contentType: contentType,
            body: responseBody,
          ),
          statusCode: response.statusCode,
        );
        continue;
      }

      final decoded = responseBody.isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(responseBody) as Map<dynamic, dynamic>)
                .cast<String, dynamic>();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('ApiClient: $method $uri succeeded');
        return decoded;
      }

      final errorsJson = decoded['errors'];
      Map<String, List<String>>? errors;
      if (errorsJson is Map) {
        errors = errorsJson.map(
          (key, value) => MapEntry(
            '$key',
            ((value as List?) ?? []).map((item) => '$item').toList(),
          ),
        );
      }

      final message =
          (decoded['message'] ??
                  decoded['error'] ??
                  'Request failed (${response.statusCode}).')
              .toString();
      debugPrint('ApiClient: $method $uri failed: $message');

      throw ApiException(
        message,
        statusCode: response.statusCode,
        errors: errors,
      );
    }

    throw lastError ??
        ApiException(
          'Could not connect to any configured API base URL. '
          'Tried: ${ApiConfig.candidateBaseUrls.join(', ')}',
          statusCode: 500,
        );
  }

  bool _looksLikeJson(String body) {
    return body.startsWith('{') || body.startsWith('[');
  }

  String _buildNonJsonResponseMessage({
    required Uri uri,
    required int statusCode,
    required String contentType,
    required String body,
  }) {
    final preview = body.replaceAll(RegExp(r'\s+'), ' ');
    final shortPreview = preview.length > 120
        ? '${preview.substring(0, 120)}...'
        : preview;

    if (body.startsWith('<!DOCTYPE html') || body.startsWith('<html')) {
      return 'Login failed because $uri returned an HTML page instead of JSON. '
          'Check that the API base URL is correct and that the `/auth/login` route exists. '
          'Status: $statusCode. Preview: $shortPreview';
    }

    final type = contentType.isEmpty ? 'unknown content type' : contentType;
    return 'Request to $uri returned a non-JSON response ($type). '
        'Status: $statusCode. Preview: $shortPreview';
  }
}

class AppSession extends ChangeNotifier {
  AppSession._() : api = ApiClient._();

  static final AppSession instance = AppSession._();

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  final ApiClient api;

  String? _token;
  SessionUser? _user;
  bool _isReady = false;

  String? get token => _token;
  SessionUser? get user => _user;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty && _user != null;
  bool get isReady => _isReady;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final rawUser = prefs.getString(_userKey);
    if (rawUser != null && rawUser.isNotEmpty) {
      _user = SessionUser.fromJson(
        (jsonDecode(rawUser) as Map<dynamic, dynamic>).cast<String, dynamic>(),
      );
    }
    _isReady = true;
    notifyListeners();
  }

  Future<void> saveLogin(LoginResult result) async {
    _token = result.token;
    _user = result.user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, result.token);
    await prefs.setString(_userKey, jsonEncode(result.user.toJson()));
    notifyListeners();
  }

  Future<void> clear() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    notifyListeners();
  }
}
