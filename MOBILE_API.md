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
5. [Meta / Lookup Endpoints](#5-meta--lookup-endpoints)
   - [5.1 Get Designations](#51-get-designations-positions)
   - [5.2 Get Active Branches](#52-get-active-branches)
   - [5.3 Get HR Users](#53-get-hr-users)
   - [5.4 Search Applicants](#54-search-applicants)
6. [Status Codes & Stage Reference](#6-status-codes--stage-reference)
7. [Global Error Responses](#7-global-error-responses)
8. [Integration Checklist](#8-integration-checklist)

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
| `GET` | `/api/meta/designations` | Bearer | All positions / designations |
| `GET` | `/api/meta/branches` | Bearer | All active branches |
| `GET` | `/api/meta/hr-users` | Bearer (HR only) | HR staff list |
| `GET` | `/api/meta/applicants` | Bearer (HR only) | Search applicant profiles |

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
s
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
      "employee_status": "ACTIVE"
    }
  }
}
```

| Field | Notes |
|-------|-------|
| `lag_days` | Days elapsed since L1 started. `null` if pre-screening not yet passed |
| `deleted` | `true` means soft-deleted — visible only to superadmin |
| `approved_branch_ids` | Branch IDs approved for this candidate across all stages |
| `stages` | Ordered array of all stage records from creation to current |
| `stages[].action_taken` | `created` / `pre_screen_proceed` / `pre_screen_not_responding` / `pre_screen_rejected` / `proceed` / `hold` / `reject` |
| `stages[].file_size` | In bytes |
| `offer_consent` | `null` if no offer has been released yet |
| `offer_consent.total_releases` | Max allowed is 3 |
| `joining_form` | `null` if joining form not yet generated |

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

## 5. Meta / Lookup Endpoints

These endpoints supply dropdown and autocomplete data for the Create Application form.
`meta/designations` and `meta/branches` require a Bearer token.
`meta/hr-users` and `meta/applicants` require a Bearer token **and an HR role** (`superadmin`, `hr_manager`, `hr_executive`) — they contain PII (contact numbers, email, Aadhar search) and internal org structure.

---

### 5.1 Get Designations (Positions)

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

### 5.2 Get Active Branches

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

### 5.3 Get HR Users

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

### 5.4 Search Applicants

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

## 6. Status Codes & Stage Reference

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
| `07` | Candidate yet to Join |
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
| `pre_screen_proceed` | Pre-screening passed |
| `pre_screen_not_responding` | Marked not responding during pre-screen |
| `pre_screen_rejected` | Rejected during pre-screen |
| `pre_screen_no_vacancy` | No vacancy at pre-screen |
| `proceed` | Stage passed — moved to next level |
| `hold` | Candidate placed on hold |
| `reject` | Candidate rejected at this stage |

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
| `ACTIVE` | Currently active employee |
| `NOTICE_PERIOD` | Serving notice period |

---

### `recent_logins.status` Values

| Value | Meaning |
|-------|---------|
| `success` | Successful login |
| `failed` | Wrong credentials |
| `deactivated` | Login attempted but account is deactivated |

---

## 7. Global Error Responses

| HTTP Code | Meaning | Example Body |
|-----------|---------|--------------|
| `401` | Missing or expired token | `{"message": "Unauthenticated."}` |
| `403` | Authenticated but no permission | `{"success": false, "message": "Access denied."}` |
| `404` | Resource not found | `{"message": "No query results for model..."}` |
| `422` | Validation failed | `{"message": "...", "errors": { "field": ["reason"] }}` |
| `500` | Server error | `{"message": "Server Error"}` |

---

## 8. Integration Checklist

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

──────────────────────────────────────────────────

Create Application Screen  (show only if is_hr = true)
  On screen load (parallel fetch):
  ✓ GET  /api/meta/designations   → Position dropdown
  ✓ GET  /api/meta/branches       → Branch dropdown
  ✓ GET  /api/meta/hr-users       → HR Manager + Assigned To dropdowns

  Applicant search field:
  ✓ GET  /api/meta/applicants?search=  → Autocomplete as user types (debounce 300ms)

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

*Generated for PAFT HRMS Recruitment Portal — April 2026*
