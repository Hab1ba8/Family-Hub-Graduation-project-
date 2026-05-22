# Task Management — Backend Flow

> **File references**
> - Routes: `backend/routes/taskRoutes.js`
> - Controller: `backend/controllers/TaskController.js`
> - Models: `backend/models/taskModel.js` · `backend/models/task_historyModel.js`
> - Auth middleware: `backend/controllers/AuthController.js`

---

## Data Models

### Task (template)
Stored in the `tasks` collection. Defines *what* the task is — it is reusable and not tied to any specific person.

| Field | Type | Notes |
|---|---|---|
| `title` | String | Required |
| `description` | String | Optional |
| `is_mandatory` | Boolean | Default `false` |
| `created_by` | String (mail) | Who created the template |
| `reward_type` | `'points'` \| `'money'` \| `'both'` | Default `'points'` |
| `money_reward` | Number | Only relevant when type is `money` or `both` |
| `paid_to_wallet` | Boolean | Set to `true` after money reward is deposited |
| `category_id` | ObjectId → TaskCategory | Required |
| `family_id` | ObjectId → FamilyAccount | Required — every query is scoped to this |

### TaskDetails (assignment)
Stored in the `taskdetails` collection. Represents one *instance* of a task assigned to one member.

| Field | Type | Notes |
|---|---|---|
| `task_id` | ObjectId → Task | The template |
| `member_mail` | String | Who it was assigned to |
| `assigned_points` | Number | Points granted on approval |
| `penalty_points` | Number | Points deducted on penalty |
| `deadline` | Date | Required |
| `assigned_by` | String (mail) | Assigner |
| `assignment_approved` | Boolean | `false` if assigned by a non-Parent |
| `assignment_approved_by` | String (mail) | Parent who approved |
| `priority` | Number | 0=Normal, 1=Medium, 2=High, 3=Urgent |
| `status` | Enum | See lifecycle below |
| `completed_at` | Date | Set when member marks complete |
| `approved_by` | String (mail) | Parent who approved completion |
| `approved_at` | Date | Set when completion is approved |
| `notes` | String | Appended throughout the lifecycle |

#### Status lifecycle

```
assigned ──► in_progress ──► completed ──► approved
    │                                         │
    └──────────── late ◄────── (penalty) ─────┘
                                rejected ◄───────── (parent rejects completion)
```

---

## Full Flow — Step by Step

### Phase 1 · Create a Task Template

**Endpoint:** `POST /api/tasks`  
**Auth:** Any authenticated member

1. Request arrives with `{ title, category_id, reward_type, money_reward, is_mandatory }`.
2. `protect` middleware sets `req.familyAccount` and `req.member`.
3. Controller validates `title` and `category_id` are present.
4. Confirms the `TaskCategory` document exists and its `family_id` matches.
5. Validates `reward_type` is one of `'points'`, `'money'`, `'both'`.
6. If `reward_type` includes money, checks the active `Budget` for the `"Tasks/Rewards"` category.
   - If budget is insufficient and `force_create` is not `true`, returns **HTTP 409** with a warning so the client can ask the user to confirm.
7. Creates the `Task` document with `family_id = req.familyAccount._id` and `created_by = req.member.mail`.
8. Populates `category_id` and returns **201**.

> **Notes on points vs money**: Points per assignment are set at *assignment* time, not here. `money_reward` on the template is the fixed money amount paid to the member's wallet on completion.

---

### Phase 2 · Assign a Task to a Member

**Endpoint:** `POST /api/tasks/assign`  
**Auth:** Any authenticated member

1. Request carries `{ task_id, member_mail, assigned_points, penalty_points, deadline, priority }`.
2. Controller checks that:
   - The `Task` exists and its `family_id` matches.
   - A `Member` with `member_mail` exists in the same family.
3. Looks up the assigner's `MemberType` to decide whether approval is needed.
   - **Parent assigning** → `assignment_approved: true`, assignment is immediately active.
   - **Non-parent assigning** → `assignment_approved: false`, must wait for parent to approve.
4. Creates a `TaskDetails` document with `status: 'assigned'`.
5. Returns **201** with a message that tells the client whether approval is pending.

---

### Phase 3 · Parent Approves (or Rejects) the Assignment

> Only required when a non-Parent created the assignment.

**Endpoint:** `PATCH /api/tasks/assignments/:taskDetailId/approve-assignment`  
**Auth:** Parent only (`restrictTo('Parent')`)

1. Loads the `TaskDetails` by ID and confirms the linked `Task` belongs to the same family.
2. Checks `assignment_approved` is still `false` (prevents double-approval).
3. **If `approved: true`:**
   - Sets `assignment_approved = true` and `assignment_approved_by = req.member.mail`.
   - Saves and returns **200**.
4. **If `approved: false`:**
   - Deletes the `TaskDetails` document entirely.
   - Returns **200** with message "rejected and removed".

**Parent view of pending assignments:** `GET /api/tasks/pending-assignments`  
Finds all `TaskDetails` where `assignment_approved: false` and the linked `Task` belongs to this family.

---

### Phase 4 · Member Marks the Task as Complete

**Endpoint:** `PATCH /api/tasks/:taskDetailId/complete`  
(also reachable via `PATCH /api/tasks/assignments/:taskDetailId/complete`)  
**Auth:** Any authenticated member (must be the assigned member)

1. Loads `TaskDetails` and checks:
   - `taskDetail.member_mail === req.member.mail` — only the assignee can complete it.
   - `assignment_approved === true` — assignment must be approved first.
   - `status` is not already `'approved'`.
   - `status` is one of `'assigned'`, `'in_progress'`, or `'completed'`.
2. Sets `status = 'approved'`, `completed_at`, `approved_at`, `approved_by` (self-approval in this flow), and saves.
3. **Immediately calls `applyTaskRewards()`** — rewards are auto-applied without a second parent step.
4. Returns **200** with the `taskDetail` and a `rewardSummary`.

> **Current design note**: In this codebase, `completeTask` both marks complete *and* applies rewards in one step (the `status` goes straight to `'approved'`). There is also a separate `approveTaskCompletion` endpoint for a two-step flow (described below in Phase 4b), but `completeTask` bypasses it.

---

### Phase 4b · Two-Step Completion Approval (Parent reviews)

This alternative flow uses `status: 'completed'` as a staging state:

**Member submits** → `status = 'completed'`  
**Parent reviews** via `GET /api/tasks/waiting-approval`  
**Parent acts** via `PATCH /api/tasks/assignments/:taskDetailId/approve-completion`

**Endpoint:** `PATCH /api/tasks/assignments/:taskDetailId/approve-completion`  
**Auth:** Parent only

1. Loads the `TaskDetails`, verifies `status === 'completed'` and family ownership.
2. **If `approved: true`:**
   - Sets `status = 'approved'`, stamps `approved_by` and `approved_at`.
   - Calls `applyTaskRewards()` to credit the member.
   - Returns **200** with `rewardSummary`.
3. **If `approved: false`:**
   - Sets `status = 'rejected'` and appends rejection reason to `notes`.
   - Returns **200** with updated `taskDetail`.

---

### Phase 5 · Reward Application (`applyTaskRewards`)

This internal helper runs after either Phase 4 or Phase 4b approval. It handles all wallet updates atomically.

```
applyTaskRewards({ task, taskDetail, familyId, actorMail })
```

#### Points reward (`reward_type: 'points'` or `'both'`)

1. Calls `ensurePointWallet(memberMail, familyId)` — creates a `PointWallet` if one doesn't exist.
2. Increments `PointWallet.total_points += assigned_points` and saves.
3. Creates a `PointHistory` record:
   - `reason_type: 'task_completion'`
   - `granted_by: actorMail`
   - `description: 'Task completed: <title>'`

#### Money reward (`reward_type: 'money'` or `'both'`)

1. Calls `ensureMoneyWallet(memberMail, familyId)` — creates a `MemberWallet` if needed.
2. Increments `MemberWallet.balance += money_reward` and saves.
3. Creates a `WalletTransaction` (type: `'deposit'`), optionally linked to the `PointHistory` ID.
4. Calls `recordBalanceWalletDetail()` for the full audit trail:
   - `wallet_scope: 'money_wallet'`, `change_type: 'credit'`, `source_type: 'task_reward'`
5. Looks for an active `Budget` with `category_name: 'Tasks/Rewards'` and increments `spent_amount`.
6. Sets `task.paid_to_wallet = true`.

#### Return value

```js
{
  reward_type,        // 'points' | 'money' | 'both'
  points_awarded,
  money_awarded,
  point_wallet,       // updated PointWallet doc
  money_wallet,       // updated MemberWallet doc (or null)
  point_history,      // created PointHistory doc (or null)
  wallet_transaction, // created WalletTransaction doc (or null)
  budget,             // updated Budget doc (or null)
}
```

---

### Phase 6 · Manual Penalty (Parent)

**Endpoint:** `POST /api/tasks/assignments/:taskDetailId/penalty`  
**Auth:** Parent only

1. Validates `penalty_points > 0`.
2. Loads `TaskDetails` and confirms family ownership.
3. Gets or creates the member's `PointWallet`.
4. Deducts points: `total_points = Math.max(0, total_points - penalty_points)` (floor at 0).
5. Creates a `PointHistory` record with `points_amount: -penalty_points` and `reason_type: 'penalty'`.
6. If the task `status` is still `'assigned'`, changes it to `'late'`.
7. Appends penalty details to `taskDetail.notes`.
8. Returns **200**.

---

## Read Endpoints Summary

| Endpoint | Auth | What it returns |
|---|---|---|
| `GET /api/tasks` | Any | All task templates for the family |
| `GET /api/tasks/my-tasks` | Any | All `TaskDetails` assigned to `req.member.mail`, sorted by deadline |
| `GET /api/tasks/all-assigned` | Any | All approved assignments for the family, newest first |
| `GET /api/tasks/pending-assignments` | Parent | `TaskDetails` with `assignment_approved: false` |
| `GET /api/tasks/waiting-approval` | Parent | `TaskDetails` with `status: 'completed'` |
| `GET /api/tasks/rewards-summary` | Any | Points/money earned from tasks this month (or year) |

---

## Auth & Family Scoping

Every route is behind `protect`, which sets:

```
req.familyAccount  →  full FamilyAccount doc
req.memberId       →  ObjectId of logged-in member
req.member         →  full Member doc (with member_type_id populated)
```

All queries filter by `family_id: req.familyAccount._id`. Because `TaskDetails` has no `family_id` field, it is always joined through `Task` and the result filtered in application code:

```js
const filtered = taskDetails.filter(td => td.task_id !== null);
// task_id is null when Mongoose populate's match({ family_id }) finds no match
```

Parent-only routes additionally use `restrictTo('Parent')`, which checks `req.member.member_type_id.type === 'Parent'`.

---

## Complete Sequence Diagram

```
Member/Parent         Backend              DB
     │                  │                  │
     │─── POST /tasks ──►│                  │
     │                  │── create Task ───►│
     │◄── 201 ──────────│                  │
     │                  │                  │
     │─── POST /assign ─►│                  │
     │                  │── create TaskDetails (approved=false if non-parent) ─►│
     │◄── 201 ──────────│                  │
     │                  │                  │
     │ (Parent)         │                  │
     │─ PATCH approve-assignment ──────────►│
     │                  │── set approved=true ──────────────────────────────────►│
     │◄── 200 ──────────│                  │
     │                  │                  │
     │─── PATCH /complete ──────────────────►│
     │                  │── status='approved' ──────────────────────────────────►│
     │                  │── applyTaskRewards() ─────────────────────────────────►│
     │                  │     ├─ PointWallet += points ──────────────────────────►│
     │                  │     ├─ PointHistory created ──────────────────────────►│
     │                  │     ├─ MemberWallet += money (if applicable) ──────────►│
     │                  │     ├─ WalletTransaction created ──────────────────────►│
     │                  │     ├─ BalanceWalletDetail created ────────────────────►│
     │                  │     └─ Budget.spent_amount += money ──────────────────►│
     │◄── 200 + rewardSummary ──────────────│
     │                  │                  │
     │ (Parent, optional penalty)          │
     │─ POST /penalty ──►│                  │
     │                  │── PointWallet -= penalty ──────────────────────────────►│
     │                  │── PointHistory (negative) created ─────────────────────►│
     │                  │── status='late' ───────────────────────────────────────►│
     │◄── 200 ──────────│                  │
```
