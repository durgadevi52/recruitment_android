# Mobile API Integration Reference

**Recruitment Portal — PAFT HRMS**

---

## Overview

| Property | Value |
|----------|-------|
| Base URL | `https://yourdomain.com/api` |
| Content-Type | `application/json` |
| Authentication | Bearer Token (Laravel Sanctum) |
| Token Header | `Authorization: Bearer {token}` |

All protected routes require a valid Bearer token obtained from the login endpoint.
All request and response bodies are JSON.

---

## Table of Contents

1. [Authentication](#1-authentication)
   - [1.1 Login](#11-login)
   - [1.2 Logout](#12-logout)
2. [Profile](#2-profile)
   - [2.1 Get My Profile](#21-get-my-profile)
3. [Dashboard](#3-dashboard)
   - [3.1 Get Dashboard Data](#31-get-dashboard-data)
4. [Applications](#4-applications)
   - [4.1 List Applications](#41-list-applications)
   - [4.2 Get Single Application](#42-get-single-application)
   - [4.3 Create New Application](#43-create-new-application)
5. [Applicants](#5-applicants)
   - [5.1 List Applicants](#51-list-applicants)
   - [5.2 Get Applicant Profile](#52-get-applicant-profile)
6. [Meta / Lookup Endpoints](#6-meta--lookup-endpoints)
   - [6.1 Get Designations](#61-get-designations-positions)
   - [6.2 Get Active Branches](#62-get-active-branches)
   - [6.3 Get HR Users](#63-get-hr-users)
   - [6.4 Search Applicants](#64-search-applicants-autocomplete)
7. [Status Codes & Stage Reference](#7-status-codes--stage-reference)
8. [Global Error Responses](#8-global-error-responses)
9. [Integration Checklist](#9-integration-checklist)

---

## Quick Reference — All Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `POST` | `/api/auth/login` | Public | Login and get Bearer token |
| `POST` | `/api/auth/logout` | Bearer | Revoke current token |
| `GET` | `/api/profile` | Bearer | Current user profile |
| `GET` | `/api/dashboard` | Bearer (HR only) | Stats, manpower, recent apps |
| `GET` | `/api/applications` | Bearer | Paginated applications list |
| `POST` | `/api/applications` | Bearer (HR only) | Create new application |
| `GET` | `/api/applications/{id}` | Bearer | Full application detail |
| `GET` | `/api/applicants` | Bearer (HR only) | Paginated applicant list |
| `GET` | `/api/applicants/{id}` | Bearer | Full applicant profile |
| `GET` | `/api/meta/designations` | Bearer | All positions / designations |
| `GET` | `/api/meta/branches` | Bearer | All active branches |
| `GET` | `/api/meta/hr-users` | Bearer (HR only) | HR staff list |
| `GET` | `/api/meta/applicants` | Bearer (HR only) | Search applicants (autocomplete) |

---

## 1. Authentication

---

### 1.1 Login

```
POST /api/auth/login
```

Public endpoint — no token required.

**Request Body**

```json
{
  "employee_code": "EMP001",
  "password": "your_password"
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `employee_code` | string | Yes | Automatically converted to uppercase |
| `password` | string | Yes | Plain text — hashed server-side |

**Success Response `200`**

```json
{
  "success": true,
  "message": "Login successful.",
  "token": "1|aBcDeFgHiJkLmNoPqRsTuVwXyZ1234567890",
  "user": {
    "id": 5,
    "name": "John Kumar",
    "employee_code": "EMP001",
    "email": "john@example.com",
    "role": {
      "id": 2,
      "name": "HR Manager",
      "slug": "hr_manager"
    },
    "designation": {
      "id": 3,
      "name": "BM",
      "full_name": "Branch Manager"
    },
    "branch": {
      "id": 7,
      "name": "Chennai Central",
      "code": "CHN01"
    },
    "is_hr": true
  }
}
```

| Field | Type | Notes |
|-------|------|-------|
| `token` | string | Save securely — required for all protected requests |
| `user.is_hr` | boolean | `true` for `superadmin`, `hr_manager`, `hr_executive`. Use to show/hide HR screens |
| `user.role.slug` | string | `superadmin` / `hr_manager` / `hr_executive` / other role slugs |

**Error — Wrong Credentials `401`**

```json
{
  "success": false,
  "message": "Invalid employee code or password."
}
```

**Error — Account Deactivated `403`**

```json
{
  "success": false,
  "message": "Your account has been deactivated. Please contact HR."
}
```

**Error — Validation Failed `422`**

```json
{
  "message": "The employee code field is required.",
  "errors": {
    "employee_code": ["The employee code field is required."],
    "password": ["The password field is required."]
  }
}
```

---

### 1.2 Logout

```
POST /api/auth/logout
Authorization: Bearer {token}
```

Revokes the current device token and records logout time in the login audit log.

**Request Body**

None.

**Success Response `200`**

```json
{
  "success": true,
  "message": "Logged out successfully."
}
```

**Error — Unauthenticated `401`**

```json
{
  "message": "Unauthenticated."
}
```

---

## 2. Profile

---

### 2.1 Get My Profile

```
GET /api/profile
Authorization: Bearer {token}
```

Returns the authenticated user's full profile, activity summary, and last 5 login sessions.

**Request Body**

None.

**Success Response `200`**

```json
{
  "success": true,
  "data": {
    "id": 5,
    "name": "John Kumar",
    "employee_code": "EMP001",
    "email": "john@example.com",
    "is_active": true,
    "is_hr": true,

    "role": {
      "id": 2,
      "name": "HR Manager",
      "slug": "hr_manager"
    },

    "designation": {
      "id": 3,
      "short_name": "BM",
      "full_name": "Branch Manager"
    },

    "branch": {
      "id": 7,
      "name": "Chennai Central",
      "code": "CHN01",
      "zone": "South Zone",
      "cluster": "TN Cluster",
      "state": "Tamil Nadu",
      "city": "Chennai"
    },

    "activity": {
      "assigned_applications": 12,
      "managed_applications": 45
    },

    "recent_logins": [
      {
        "status": "success",
        "ip_address": "103.10.20.5",
        "logged_in_at": "2026-04-24 09:15:00",
        "logged_out_at": "2026-04-24 17:45:00"
      },
      {
        "status": "success",
        "ip_address": "103.10.20.5",
        "logged_in_at": "2026-04-23 08:55:00",
        "logged_out_at": null
      }
    ]
  }
}
```

| Field | Notes |
|-------|-------|
| `activity.managed_applications` | Always `0` for non-HR users |
| `recent_logins.status` | `success` / `failed` / `deactivated` |
| `recent_logins.logged_out_at` | `null` if the session was not cleanly closed |

---

## 3. Dashboard

---

### 3.1 Get Dashboard Data

```
GET /api/dashboard
Authorization: Bearer {token}
```

Returns recruitment statistics, manpower fill rates, and the 10 most recent applications.
**Accessible only to HR roles** (`superadmin`, `hr_manager`, `hr_executive`).

**Request Body**

None.

**Success Response `200`**

```json
{
  "success": true,

  "stats": {
    "total_applications": 320,
    "today_applications": 5,
    "total_applicants": 280,
    "pending_l1": 45,
    "pending_l2": 22,
    "pending_l3": 10,
    "pending_l4": 6,
    "joined_this_month": 8,
    "on_hold": 14,
    "offers_released": 9,
    "rejected": 37,
    "completed_this_month": 31
  },

  "manpower": {
    "total_required": 150,
    "total_current": 112,
    "total_vacancy": 38,
    "notice_period": 5,
    "fill_rate": 75,
    "branches": 18,
    "designations": [
      {
        "name": "BM",
        "full": "Branch Manager",
        "req": 18,
        "cur": 15,
        "vacancy": 3
      },
      {
        "name": "CS",
        "full": "Customer Service",
        "req": 54,
        "cur": 40,
        "vacancy": 14
      }
    ]
  },

  "recent_applications": [
    {
      "id": 201,
      "candidate_name": "Ravi Shankar",
      "contact": "9876543210",
      "position": "BM",
      "branch": "Madurai North",
      "status_code": "00",
      "status_label": "New Application",
      "stage": 0,
      "hr_manager": "John Kumar",
      "assigned_to": null,
      "created_at": "2026-04-24 10:30:00"
    }
  ]
}
```

| Field | Notes |
|-------|-------|
| `manpower.fill_rate` | Integer percentage, e.g. `75` means 75% |
| `manpower.notice_period` | Employees currently on notice period (counted in `total_current`) |
| `recent_applications` | Last 10 applications ordered by newest first |

**Error — Non-HR Access `403`**

```json
{
  "success": false,
  "message": "Access denied. HR role required."
}
```

---

## 4. Applications

---

### 4.1 List Applications

```
GET /api/applications
Authorization: Bearer {token}
```

Returns a paginated list of applications.
Non-HR users see **only applications where they are the current `assigned_to` user**. Past interviewer history does not grant access.

**Query Parameters**

| Param | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `status` | string | No | — | Filter by pipeline stage (see values below) |
| `search` | string | No | — | Search by candidate name or contact number |
| `branch_id` | integer | No | — | Filter by target branch ID |
| `my_apps` | boolean | No | `0` | HR only — `1` shows only apps assigned to or managed by the current user |
| `per_page` | integer | No | `20` | Items per page (max `50`) |
| `page` | integer | No | `1` | Page number |

**`status` Filter Values**

| Value | Pipeline Stage |
|-------|----------------|
| `prescreening` | New application — pre-screening call pending |
| `l1` | Pre-screening passed — L1 interview |
| `l2` | L1 done — L2 interview (Cluster/Zonal Manager) |
| `l3` | L2 done — L3 interview (Ops Head / COO) |
| `l4` | L3 done — Salary finalisation |
| `salary` | Salary finalised |
| `offer_released` | Offer letter sent to candidate |
| `offer_accepted` | Candidate accepted the offer |
| `joining_initiated` | Offer accepted — joining form not yet submitted |
| `joining_pending` | Joining form submitted — awaiting HR action |
| `joined` | Candidate joined |
| `hold` | Candidate on hold |
| `rejected` | PAFT rejected |
| `no_vacancy` | No vacancy available |
| `not_responding` | Candidate not responding |

**Example Request**

```
GET /api/applications?status=l1&search=ravi&per_page=15&page=1
Authorization: Bearer {token}
```

**Success Response `200`**

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": 201,
        "candidate_name": "Ravi Shankar",
        "contact": "9876543210",
        "gender": "Male",
        "position": "BM",
        "branch": "Madurai North",
        "status_code": "00",
        "status_label": "New Application",
        "stage": 0,
        "pre_screening": "passed",
        "assigned_to": "Suresh CM",
        "hr_manager": "John Kumar",
        "created_at": "2026-04-20"
      },
      {
        "id": 198,
        "candidate_name": "Raviraj D",
        "contact": "9123456780",
        "gender": "Male",
        "position": "CS",
        "branch": "Coimbatore East",
        "status_code": "01",
        "status_label": "Level-1 Completed",
        "stage": 1,
        "pre_screening": "passed",
        "assigned_to": "Karthik ZM",
        "hr_manager": "John Kumar",
        "created_at": "2026-04-18"
      }
    ],
    "current_page": 1,
    "last_page": 4,
    "per_page": 15,
    "total": 52
  }
}
```

| Field | Notes |
|-------|-------|
| `data.items` | Array of application summary objects |
| `data.total` | Total matching records across all pages |
| `data.last_page` | Use this to detect if more pages exist |
| `pre_screening` | `null` / `passed` / `not_responding` / `rejected` / `no_vacancy` |
| `assigned_to` | `null` if not yet assigned to any user |

---

### 4.2 Get Single Application

```
GET /api/applications/{id}
Authorization: Bearer {token}
```

Returns full application detail including candidate profile, all interview stages, attachments, offer consent status, and joining form.
Non-HR users can only fetch applications where they are the **current** `assigned_to` user. Being a past interviewer on a completed stage does not grant access.

**URL Parameter**

| Param | Type | Description |
|-------|------|-------------|
| `id` | integer | Application ID |

**Success Response `200`**

```json
{
  "success": true,
  "data": {
    "id": 201,
    "current_stage": 1,
    "status_code": "01",
    "status_label": "Level-1 Completed",
    "pre_screening": "passed",
    "salary_offered": "18000.00",
    "remarks": "Good candidate. Recommended for L2.",
    "lag_days": 4,
    "deleted": false,
    "created_at": "2026-04-20 09:00:00",
    "updated_at": "2026-04-22 14:30:00",

    "candidate": {
      "id": 145,
      "name": "Ravi Shankar",
      "dob": "1998-06-15",
      "age": 27,
      "gender": "Male",
      "contact_number": "9876543210",
      "email": "ravi@gmail.com",
      "qualification": "B.Com",
      "position_applied": "Branch Manager",
      "job_experience": true,
      "expected_salary": "20000",
      "marital_status": "Single",
      "hometown": "Madurai",
      "address": "12 Gandhi Rd, Madurai, Tamil Nadu, 625001",
      "languages": ["Tamil", "English"],
      "two_wheeler": true,
      "four_wheeler": false,
      "profile_pic": "profiles/ravi_pic.jpg",
      "resume": "resumes/ravi_resume.pdf",
      "preferred_branches": [7, 12],
      "applied_at": "2026-04-19 08:45:00"
    },

    "position": {
      "id": 3,
      "short_name": "BM",
      "full_name": "Branch Manager",
      "category": "Operations",
      "interview_levels": 3
    },

    "target_branch": {
      "id": 7,
      "name": "Madurai North",
      "code": "MDU01",
      "zone": "South Zone",
      "cluster": "TN Cluster",
      "state": "Tamil Nadu",
      "city": "Madurai"
    },

    "approved_branch_ids": [7, 12],

    "assigned_to": {
      "id": 9,
      "name": "Suresh CM",
      "employee_code": "EMP009",
      "role": "Cluster Manager",
      "designation": "CM"
    },

    "hr_manager": {
      "id": 5,
      "name": "John Kumar",
      "designation": "HRM"
    },

    "stages": [
      {
        "id": 301,
        "stage_number": 0,
        "stage_name": "Application Created",
        "action_taken": "created",
        "remarks": null,
        "scheduled_at": null,
        "interview_slot": null,
        "completed_at": "2026-04-20 09:00:00",
        "done_by": "John Kumar",
        "interviewer": null,
        "approved_branches": [],
        "attachments": []
      },
      {
        "id": 302,
        "stage_number": 0,
        "stage_name": "Pre-Screening",
        "action_taken": "pre_screen_proceed",
        "remarks": "Candidate confirmed availability",
        "scheduled_at": "2026-04-21 10:00:00",
        "interview_slot": "10:00 AM - 11:00 AM",
        "completed_at": "2026-04-21 11:00:00",
        "done_by": "John Kumar",
        "interviewer": {
          "id": 9,
          "name": "Suresh CM",
          "designation": "CM"
        },
        "approved_branches": [7, 12],
        "attachments": [
          {
            "id": 15,
            "file_name": "aadhar_ravi.pdf",
            "type": "Aadhar Card",
            "file_type": "application/pdf",
            "file_size": 204800,
            "uploaded_by": "John Kumar",
            "created_at": "2026-04-21 11:05:00"
          }
        ]
      },
      {
        "id": 303,
        "stage_number": 1,
        "stage_name": "L1 Interview",
        "action_taken": "proceed",
        "remarks": "Strong communication. Approved for L2.",
        "scheduled_at": "2026-04-22 14:00:00",
        "interview_slot": "2:00 PM - 3:00 PM",
        "completed_at": "2026-04-22 14:30:00",
        "done_by": "Suresh CM",
        "interviewer": null,
        "approved_branches": [7],
        "attachments": []
      }
    ],

    "offer_consent": {
      "status": "pending",
      "responded_at": null,
      "expires_at": "2026-04-27 09:00:00",
      "is_expired": false,
      "total_releases": 1
    },

    "joining_form": {
      "id": 88,
      "submitted_at": "2026-04-24 09:00:00",
      "employee_status": "ACTIVE",
      "employee_code": "EMP042"
    },

    "emp_master_deleted": false
  }
}
```

| Field | Notes |
|-------|-------|
| `lag_days` | Days elapsed since L1 started. `null` if pre-screening not yet passed |
| `deleted` | `true` means soft-deleted — visible only to superadmin |
| `approved_branch_ids` | Branch IDs approved for this candidate across all stages |
| `stages` | Ordered array of all stage records from creation to current |
| `stages[].action_taken` | See full table in [§6 Stage Action Reference](#stages-action_taken-values) |
| `stages[].file_size` | In bytes |
| `offer_consent` | `null` if no offer has been released yet |
| `offer_consent.total_releases` | Max allowed is 3 |
| `joining_form` | `null` if not yet generated. Also `null` if a previously submitted joining form was deleted (employee master deletion). Check `emp_master_deleted` flag below |
| `emp_master_deleted` | `true` if an `employee_master_deleted` stage exists AND no new submitted joining form is present. Indicates HR must re-initiate the joining process. `false` otherwise |

**Error — Not Assigned `403`**

```json
{
  "success": false,
  "message": "You are not assigned to this application."
}
```

**Error — Not Found `404`**

```json
{
  "message": "No query results for model [App\\Models\\Application] 999"
}
```

---

### 4.3 Create New Application

```
POST /api/applications
Authorization: Bearer {token}
```

Creates a new application for an existing applicant profile.
**Accessible only to HR roles.**

**Request Body**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `applicant_profile_id` | integer | **Yes** | Applicant ID — use `/api/meta/applicants` to search |
| `position_id` | integer | No | Designation/position ID — use `/api/meta/designations` |
| `target_branch_id` | integer | No | Branch ID — use `/api/meta/branches` |
| `hr_manager_id` | integer | No | Responsible HR manager user ID — use `/api/meta/hr-users` |
| `assigned_to_user_id` | integer | No | Initially assigned user ID — use `/api/meta/hr-users` |
| `remarks` | string | No | Internal notes. Max 2000 characters |

```json
{
  "applicant_profile_id": 145,
  "position_id": 3,
  "target_branch_id": 7,
  "hr_manager_id": 5,
  "assigned_to_user_id": 5,
  "remarks": "Walk-in candidate. Priority hire."
}
```

**Success Response `201`**

```json
{
  "success": true,
  "message": "Application created successfully.",
  "data": {
    "id": 202,
    "candidate": "Ravi Shankar",
    "position": "BM",
    "branch": "Madurai North",
    "status_code": "00",
    "status_label": "New Application",
    "created_at": "2026-04-24 11:00:00"
  }
}
```

**Error — Non-HR `403`**

```json
{
  "success": false,
  "message": "Only HR staff can create applications."
}
```

**Error — Validation Failed `422`**

```json
{
  "message": "The applicant profile id field is required.",
  "errors": {
    "applicant_profile_id": ["The applicant profile id field is required."],
    "position_id": ["The selected position id is invalid."]
  }
}
```

---

## 5. Applicants

---

### 5.1 List Applicants

```
GET /api/applicants
Authorization: Bearer {token}
```

Paginated list of applicant profiles. **HR roles only.**

**Query Parameters**

| Param | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `search` | string | No | — | Name, mobile, email, or Aadhar number |
| `gender` | string | No | — | `Male` / `Female` / `Other` |
| `experience` | string | No | — | `yes` / `no` — filter by job experience flag |
| `per_page` | integer | No | `25` | Items per page (max `100`) |
| `page` | integer | No | `1` | Page number |

**Success Response `200`**

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": 145,
        "name": "Ravi Shankar",
        "contact_number": "9876543210",
        "email": "ravi@gmail.com",
        "gender": "Male",
        "qualification": "B.Com",
        "position_applied": "Branch Manager",
        "job_experience": true,
        "profile_pic": "profiles/ravi_pic.jpg",
        "applications_count": 2,
        "applied_at": "2026-04-19 08:45:00"
      }
    ],
    "current_page": 1,
    "last_page": 6,
    "per_page": 25,
    "total": 140
  }
}
```

**Error — Non-HR `403`**

```json
{
  "success": false,
  "message": "Access denied. HR role required."
}
```

---

### 5.2 Get Applicant Profile

```
GET /api/applicants/{id}
Authorization: Bearer {token}
```

Full applicant profile including education, employment history, documents, and linked applications.

**HR users** can access any profile. **Non-HR users** can only access profiles linked to applications where they are the current `assigned_to` user or a stage interviewer.

**URL Parameter**

| Param | Type | Description |
|-------|------|-------------|
| `id` | integer | Applicant profile ID |

**Success Response `200`**

```json
{
  "success": true,
  "data": {
    "id": 145,
    "name": "Ravi Shankar",
    "contact_number": "9876543210",
    "email": "ravi@gmail.com",
    "gender": "Male",
    "dob": "1998-06-15",
    "age": 27,
    "marital_status": "Single",
    "caste": "OC",
    "hometown": "Madurai",
    "aadhar_number": "452145214521",

    "address": {
      "line1": "12 Gandhi Rd",
      "line2": null,
      "city": "Madurai",
      "district": "Madurai",
      "state": "Tamil Nadu",
      "pincode": "625001"
    },

    "profile_pic": "profiles/ravi_pic.jpg",
    "resume": "resumes/ravi_resume.pdf",

    "education": {
      "qualification": "B.Com",
      "date_of_passout": "2020-05-01",
      "rows": [
        { "level": 1, "qualification": "10th", "year": "2016", "percentage": "82%" },
        { "level": 2, "qualification": "12th", "year": "2018", "percentage": "76%" },
        { "level": 3, "qualification": "B.Com", "year": "2020", "percentage": "71%" }
      ]
    },

    "employment": {
      "job_experience": true,
      "iibf_certified": false,
      "system_knowledge": "MS Office, Tally",
      "timing_joining": "Immediate",
      "expected_salary": "18000",
      "position_applied": "Branch Manager",
      "experience_rows": [
        {
          "index": 1,
          "company": "ABC Finance Ltd",
          "designation": "Branch Executive",
          "from": "Jan 2021",
          "to": "Mar 2024",
          "salary": "15000"
        }
      ],
      "reason_relieving": "Better opportunity"
    },

    "languages": ["Tamil", "English"],

    "mobility": {
      "two_wheeler": "Own",
      "four_wheeler": "None",
      "willing_outside": true
    },

    "source": {
      "external_source": "PAT Employee Reference (EMP010)",
      "reference_details": "Referred by branch staff"
    },

    "preferred_branch_ids": [7, 12],

    "documents": [
      {
        "id": 22,
        "type": "Aadhar Card",
        "file_path": "docs/aadhar_ravi.pdf",
        "status": "approved",
        "reviewed_by": "John Kumar",
        "uploaded_at": "2026-04-19 09:00:00"
      }
    ],

    "applications": [
      {
        "id": 201,
        "position": "BM",
        "branch": "Madurai North",
        "status_code": "01",
        "status_label": "Level-1 Completed",
        "stage": 1,
        "created_at": "2026-04-20"
      }
    ],

    "applied_at": "2026-04-19 08:45:00"
  }
}
```

| Field | Notes |
|-------|-------|
| `aadhar_number` | Full 12-digit Aadhar number (HR-only endpoint — protected by auth) |
| `education.rows` | Structured from `education_details`. Empty array if only `qualification` field is set |
| `employment.experience_rows` | Structured from `experience_details`. Empty array if no experience or details not yet parsed |
| `mobility.two_wheeler` | `None` / `Drive` / `Own` |
| `mobility.four_wheeler` | `None` / `Drive` / `Own` |
| `documents[].status` | `pending` / `approved` / `rejected` |
| `applications` | Summary list of all linked applications for this candidate |

**Error — Forbidden `403`**

```json
{
  "success": false,
  "message": "You do not have access to this applicant profile."
}
```

**Error — Not Found `404`**

```json
{
  "message": "No query results for model [App\\Models\\ApplicantProfile] 999"
}
```

---

## 6. Meta / Lookup Endpoints

These endpoints supply dropdown and autocomplete data for the Create Application form.
`meta/designations` and `meta/branches` require a Bearer token.
`meta/hr-users` and `meta/applicants` require a Bearer token **and an HR role** (`superadmin`, `hr_manager`, `hr_executive`) — they contain PII (contact numbers, email, Aadhar search) and internal org structure.

---

### 6.1 Get Designations (Positions)

```
GET /api/meta/designations
Authorization: Bearer {token}
```

**Success Response `200`**

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "short_name": "CS",
      "full_name": "Customer Service",
      "category": "Operations",
      "interview_levels": 2
    },
    {
      "id": 3,
      "short_name": "BM",
      "full_name": "Branch Manager",
      "category": "Operations",
      "interview_levels": 3
    }
  ]
}
```

| Field | Notes |
|-------|-------|
| `interview_levels` | Number of interview rounds required (1 to 3) |

---

### 6.2 Get Active Branches

```
GET /api/meta/branches
Authorization: Bearer {token}
```

**Success Response `200`**

```json
{
  "success": true,
  "data": [
    {
      "id": 7,
      "name": "Madurai North",
      "code": "MDU01",
      "zone_name": "South Zone",
      "cluster_name": "TN Cluster",
      "state": "Tamil Nadu",
      "city": "Madurai",
      "district": "Madurai"
    },
    {
      "id": 12,
      "name": "Coimbatore East",
      "code": "CBE02",
      "zone_name": "South Zone",
      "cluster_name": "TN Cluster",
      "state": "Tamil Nadu",
      "city": "Coimbatore",
      "district": "Coimbatore"
    }
  ]
}
```

---

### 6.3 Get HR Users

```
GET /api/meta/hr-users
Authorization: Bearer {token}
```

Returns all active users with HR roles (`superadmin`, `hr_manager`, `hr_executive`).
Use for the **HR Manager** and **Assigned To** dropdowns.

**Success Response `200`**

```json
{
  "success": true,
  "data": [
    {
      "id": 5,
      "name": "John Kumar",
      "role": "hr_manager",
      "designation": "HRM"
    },
    {
      "id": 6,
      "name": "Priya R",
      "role": "hr_executive",
      "designation": "HRE"
    }
  ]
}
```

---

### 6.4 Search Applicants (Autocomplete)

```
GET /api/meta/applicants?search={query}
Authorization: Bearer {token}
```

Searches applicant profiles by name, contact number, or Aadhar number.
Returns up to 30 results. Use for the applicant autocomplete field.

**Query Parameters**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `search` | string | No | Name, mobile number, or Aadhar number |

**Example**

```
GET /api/meta/applicants?search=ravi
```

**Success Response `200`**

```json
{
  "success": true,
  "data": [
    {
      "id": 145,
      "name": "Ravi Shankar",
      "contact_number": "9876543210",
      "email": "ravi@gmail.com",
      "position_applied": "Branch Manager",
      "qualification": "B.Com"
    },
    {
      "id": 148,
      "name": "Raviraj D",
      "contact_number": "9123456780",
      "email": "raviraj@gmail.com",
      "position_applied": "Customer Service",
      "qualification": "BA"
    }
  ]
}
```

---

## 7. Status Codes & Stage Reference

---

### Application `status_code` Values

| Code | Label |
|------|-------|
| `00` | New Application |
| `01` | Level-1 Completed |
| `02` | Level-2 Completed |
| `03` | Level-3 Completed |
| `04` | Salary Finalisation Completed |
| `05` | Offer letter released |
| `06` | Offer letter accepted |
| `07` | Candidate yet to Join (joining form sent, or re-initiation required after employee master deletion — check `emp_master_deleted`) |
| `08` | Candidate on Hold |
| `09` | Candidate Joined |
| `10` | Not Responding |
| `11` | PAFT rejected |
| `12` | No Vacancy |

---

### `current_stage` Values

| Stage | Interview Level |
|-------|----------------|
| `0` | Pre-screening / L1 HR Interview |
| `1` | L2 — Cluster Manager / Zonal Manager |
| `2` | L3 — Ops Head / COO |
| `3` | L4 — Salary Finalisation (HR only) |

---

### `pre_screening` Values

| Value | Meaning |
|-------|---------|
| `null` | Not yet screened |
| `passed` | Pre-screening passed — application enters L1 |
| `not_responding` | Candidate could not be reached |
| `rejected` | Screened out during pre-screening call |
| `no_vacancy` | No vacancy at time of screening |

---

### `stages[].action_taken` Values

| Value | Meaning |
|-------|---------|
| `created` | Application was created |
| `pre_screen_proceed` | Pre-screening passed — L1 started |
| `pre_screen_not_responding` | Marked not responding during pre-screen |
| `pre_screen_rejected` | Rejected during pre-screen |
| `pre_screen_no_vacancy` | No vacancy at pre-screen |
| `proceed` | Stage passed — moved to next level |
| `hold` | Candidate placed on hold |
| `reject` | Candidate rejected at this stage |
| `not_responding` | Candidate not responding |
| `no_vacancy` | No vacancy at this stage |
| `salary_finalised` | Salary negotiation completed (L4) |
| `offer_released` | Offer letter sent to candidate |
| `offer_accepted` | Candidate accepted the offer |
| `offer_rejected_by_applicant` | Candidate rejected the offer |
| `offer_link_regenerated` | Consent link re-sent after expiry or rejection |
| `joining_form_generated` | Joining form link sent to candidate |
| `joining_form_submitted` | Candidate submitted the joining form |
| `joined` | HR confirmed joining — employee code assigned |
| `employee_master_deleted` | Superadmin deleted the employee master record. Status reverted to `07`. HR must re-generate the joining form |
| `document_uploaded` | An attachment was added to this stage |
| `deactivated` | Application was soft-deleted |
| `restored` | Soft-deleted application was restored |

---

### `offer_consent.status` Values

| Value | Meaning |
|-------|---------|
| `pending` | Offer link sent — awaiting candidate response |
| `accepted` | Candidate accepted the offer |
| `rejected` | Candidate rejected the offer |

---

### `joining_form.employee_status` Values

| Value | Meaning |
|-------|---------|
| `null` | Submitted but not yet verified by HR |
| `ACTIVE` | Verified — currently active employee |
| `INACTIVE` | Employee has left the organisation |
| `NOTICE_PERIOD` | Currently serving notice period |

---

### `recent_logins.status` Values

| Value | Meaning |
|-------|---------|
| `success` | Successful login |
| `failed` | Wrong credentials |
| `deactivated` | Login attempted but account is deactivated |

---

## 8. Global Error Responses

| HTTP Code | Meaning | Example Body |
|-----------|---------|--------------|
| `401` | Missing or expired token | `{"message": "Unauthenticated."}` |
| `403` | Authenticated but no permission | `{"success": false, "message": "Access denied."}` |
| `404` | Resource not found | `{"message": "No query results for model..."}` |
| `422` | Validation failed | `{"message": "...", "errors": { "field": ["reason"] }}` |
| `500` | Server error | `{"message": "Server Error"}` |

---

## 9. Integration Checklist

```
Authentication
  ✓ POST /api/auth/login
    → Save token securely (e.g. SecureStorage / Keychain)
    → Save user object (id, name, is_hr, role.slug) for UI decisions
    → Redirect to Dashboard if is_hr = true, else to Applications list

  ✓ POST /api/auth/logout
    → Delete token from storage
    → Clear user session
    → Redirect to Login screen

──────────────────────────────────────────────────

Dashboard Screen  (show only if is_hr = true)
  ✓ GET  /api/dashboard
    → Render stats cards (total, today, pending per stage)
    → Render manpower fill rate bar
    → Render recent applications list with tap-to-detail

──────────────────────────────────────────────────

Applications List Screen
  ✓ GET  /api/applications
    → Default load (no filters)
    → Implement status tab/filter using ?status= param
    → Implement search bar using ?search= param
    → Implement branch filter using ?branch_id= (load from /meta/branches)
    → Implement pagination: load next page using ?page= when scrolling

  ✓ GET  /api/applications?my_apps=1
    → "My Applications" toggle for HR users

──────────────────────────────────────────────────

Application Detail Screen
  ✓ GET  /api/applications/{id}
    → Display candidate info card
    → Display stage timeline from data.stages array
    → Display attachments per stage
    → Display offer consent status badge
    → Display joining form status if present
    → Show/hide HR action buttons based on is_hr flag
    → If emp_master_deleted = true (status_code = "07", joining_form = null):
        Show red warning banner: "Employee master record deleted — joining process must be re-initiated"
        HR users: show "Re-generate Joining Form" action button
    → If emp_master_deleted = false and stages contain action_taken = "employee_master_deleted":
        Show muted audit note: "Employee master was previously deleted and subsequently re-initiated"
    → stage action_taken = "joined" → show employee code from joining_form if available

──────────────────────────────────────────────────

Applicants List Screen  (show only if is_hr = true)
  ✓ GET  /api/applicants
    → Default load (no filters)
    → Implement search bar using ?search= param
    → Implement gender / experience filters
    → Implement pagination when scrolling

──────────────────────────────────────────────────

Applicant Profile Screen
  ✓ GET  /api/applicants/{id}
    → Display personal / contact / address info
    → Render education.rows table (fallback to qualification field if rows is empty)
    → Render employment.experience_rows table if job_experience = true
    → Show mobility badges (two_wheeler / four_wheeler / willing_outside)
    → Show documents checklist with status badges (pending / approved / rejected)
    → List linked applications with tap-to-detail navigation
    → Show source / referral info if present
    → Display full aadhar_number (12 digits) — endpoint is HR-auth protected

──────────────────────────────────────────────────

Create Application Screen  (show only if is_hr = true)
  On screen load (parallel fetch):
  ✓ GET  /api/meta/designations   → Position dropdown
  ✓ GET  /api/meta/branches       → Branch dropdown
  ✓ GET  /api/meta/hr-users       → HR Manager + Assigned To dropdowns

  Applicant search field (two options):
  ✓ GET  /api/meta/applicants?search=  → Autocomplete as user types (debounce 300ms)
  ✓ GET  /api/applicants/{id}          → Tap result to load full profile before confirming selection

  On submit:
  ✓ POST /api/applications
    → On 201: navigate to the new application's detail screen
    → On 422: display field-level validation errors inline

──────────────────────────────────────────────────

Profile Screen
  ✓ GET  /api/profile
    → Display user details card
    → Display assigned / managed application counts
    → Display recent login history table
```

---

*Generated for PAFT HRMS Recruitment Portal — May 2026*
