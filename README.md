# SplitMate

https://github.com/haithanhle1510/SplitMate

## Project overview

SplitMate is an iOS shared expense app for small groups (students, trips, project teams). It records who paid, how the bill was split, and tracks **payments toward settlement** so balances stay accurate.

This repo is a **university assignment MVP**: **no accounts or networking**, local JSON only, **light mode** UI. The app is designed to be demoed **on one device** without a “current user”: on-screen copy uses **identity-agnostic** phrasing (for example, “Mia owes $20”), not “you owe.”

---

## Business concept

### Problem

Groups often split groceries, meals, transport, or shared purchases. Ad-hoc notes and calculators are easy to get wrong or forget.

### Approach

SplitMate focuses on **fast entry**, **readable balances**, and **simple group workflows** without the scope of larger commercial apps.

---

## Target audience (examples)

- University students and housemates  
- Friends travelling together  
- Small teams or assignment groups  

---

## Current features (MVP)

### Groups

- List groups, create a group with **+**, open a group (**no onboarding**).
- **Settings** tab: edit group name, add/remove members, delete the group.

### Group tabs (`TabView`)

1. **Home** — Member strip, total spent summary, **pairwise net balances** between members. Tap a pair to open **pair breakdown** (per-expense contributions, **Settle all** to record payments for that pair’s direction).
2. **Expenses** — Chronological list, **filter** (by involved members, unsettled-only), add expense, open **expense detail**.
3. **Settings** — Name, members, delete group.

### Add / edit expense

- **Title, amount, payer, participants, category, date**, optional **note** (progressive disclosure where used).
- **Three split modes** (picker): **equal**, **percentage** (must sum to 100%), **exact amounts** (must sum to the expense total). Only the rows for the active mode are shown.

### Balances and settlement

- Balances use each member’s **share** (from the split) minus **recorded payments** on that expense.
- **`Expense.payments`** stores a **payment ledger**: money from a participant **toward the payer**, and (when someone overpaid) **refunds from the payer back** to a participant.
- **Settlement**
  - From **pair breakdown**: confirm **Settle all** for the full net in that direction (matches the UI pattern on **expense detail** settle).
  - From **expense detail**: **Settle** for a participant when something is still owed to the payer, or when the payer should refund an overpayment (full amount offered in a confirmation dialog).

### Persistence

- All groups are saved with **Codable** JSON: **`splitmate_groups_v2.json`** in the app’s **Documents** directory (`GroupStorageService`).

---

## Technical design

### Stack

- **SwiftUI**, **Swift**, **MVVM**
- **Codable** + JSON file in Documents (no SwiftData in this MVP)
- No SPM pods; open **`SplitMate.xcodeproj`** in Xcode

### Build / run / test

```bash
xcodebuild -project SplitMate.xcodeproj -scheme SplitMate -destination 'platform=iOS Simulator,name=iPhone 15' build
xcodebuild -project SplitMate.xcodeproj -scheme SplitMate -destination 'platform=iOS Simulator,name=iPhone 15' test
```

```bash
open SplitMate.xcodeproj
```

`SplitMate/` uses synchronized folder references in Xcode so new files under that tree typically join the target automatically.

### Project layout (high level)

```text
SplitMateApp
├── Models
├── ViewModels
├── Services
├── Views
└── Utilities
```

### Folder structure (representative)

```text
SplitMate/
├── Models/
│   ├── SplitGroup.swift
│   ├── Member.swift
│   ├── Expense.swift
│   ├── ExpenseCategory.swift
│   ├── ExpensePayment.swift
│   ├── ExpenseParticipant.swift
│   ├── ExpenseSplitType.swift
│   ├── ExpenseSplitPayload.swift
│   └── ExpenseFilter.swift
├── ViewModels/
│   └── GroupViewModel.swift
├── Services/
│   ├── BalanceCalculatorService.swift
│   └── GroupStorageService.swift
├── Views/
│   ├── GroupsView.swift
│   ├── CreateGroupView.swift
│   ├── GroupDetailView.swift
│   ├── GroupTabs/
│   │   ├── GroupHomeTab.swift
│   │   ├── GroupExpensesTab.swift
│   │   └── GroupSettingsTab.swift
│   ├── AddExpenseView.swift
│   ├── ExpenseDetailView.swift
│   ├── ExpenseFilterSheet.swift
│   ├── PairBreakdownView.swift
│   ├── AddMemberView.swift
│   ├── EditGroupNameView.swift
│   └── Components/ …
└── Utilities/
    ├── CurrencyFormatter.swift
    ├── Theme.swift
    ├── Typography.swift
    ├── Haptics.swift
    └── DateExtensions.swift
```

### Architecture

- **Models** — `Codable` domain types.
- **Views** — SwiftUI; group flows receive `groupId` and the shared view model (avoid passing a stale copy of `SplitGroup`).
- **ViewModels** — `GroupViewModel` owns `[SplitGroup]`, mutates in place for `@Published` updates, **saves on change**.
- **Services** — `BalanceCalculatorService` (pairwise net debts, breakdown helpers), `GroupStorageService` (load/save JSON).

### Data models (summary)

**`SplitGroup`** — `id`, `name`, `members`, `expenses`, `createdAt`.

**`Member`** — `id`, `name`.

**`Expense`** — `title`, `totalAmount`, `paidByMemberId`, `splitType`, `participants` (with owed amounts), **`payments`**, `category`, `date`, optional `note`, `createdAt`. Settlement state is derived from **shares + payments**, not a single global “settled” flag.

**`ExpenseSplitType`** — `equal`, `percentage`, `exactAmount`.

**`ExpenseFilter`** — optional member subset and “unsettled only” for the expenses list.

### Main flows

1. **Launch** — Load JSON into `GroupViewModel`.
2. **Create group** — `CreateGroupView` → validate → append group → save.
3. **Add member** — From group Settings → persist member list.
4. **Add expense** — `AddExpenseView` → validate split → append expense → recompute derived balances → save.
5. **Settle** — Append to `Expense.payments` (via view model helpers) from pair breakdown or expense detail.

### Balance calculation (high level)

- Each expense computes each non-payer’s **signed balance toward the payer** from **owed amount**, **payments to the payer**, and **refunds from the payer**.
- **Pairwise net debts** collapse those signed flows across all expenses into **who nets owing whom** for each unordered pair, including cases driven by **overpayment** on specific expenses.
- Display copy avoids assuming a single “you”; amounts are labeled per member or as totals.

### Persistence

- Single JSON file: **`Documents/splitmate_groups_v2.json`** (see `GroupStorageService`).
- To reset local data during development: delete the app from the simulator/device, or remove that file / use `xcrun simctl uninstall booted UTS.SplitMate`.

### Validation and errors

The app blocks or warns on invalid input (empty names, non-positive amounts, invalid splits, missing payer/participants, save/load failures). Heavy-handed simulator erase is **not** required to clear app data—uninstalling the app or deleting the JSON is enough.

---

## Optional future ideas

- Sync / accounts  
- SwiftData or richer persistence  
- Charts, reminders  

These are **not** in the current MVP.
