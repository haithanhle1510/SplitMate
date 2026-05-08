# SplitMate

## Project Overview

SplitMate is an iOS shared expense management application designed for students, housemates, couples, travel groups, and small teams. The app helps users record shared payments and automatically calculate who owes whom.

The goal of SplitMate is to provide a simple and clean alternative to existing expense-sharing solutions by focusing on speed, usability, and common group scenarios.

---

# Business Concept

## Problem Statement

People frequently share costs such as:

* Rent
* Groceries
* Dining out
* Utilities
* Transport
* Group purchases

Existing methods are often inefficient or confusing, including:

* Notes apps
* Calculators
* Spreadsheets
* Complex commercial apps

These methods may lead to forgotten debts, unclear balances, and incorrect calculations.

SplitMate solves this by providing a fast and structured mobile experience.

---

## Target Audience

SplitMate is designed for:

* University students living together
* Housemates sharing rent and bills
* Friends travelling together
* Couples sharing expenses
* Small teams or assignment groups

### Example User Persona

Alex is a university student living with two roommates who needs a better way to manage groceries, rent, and utility payments fairly.

---

## Core Features (Minimum Viable Product)

### 1. Create Groups

Examples:

* UTS Housemates
* Sydney Trip
* Group Assignment Team

### 2. Add Members

Users can add members into a group.

### 3. Add Shared Expenses

Users can record:

* Title
* Amount
* Paid by
* Participants
* Category
* Date
* Optional note

### 4. Automatic Debt Calculation

The app instantly calculates who owes whom.

Example:

* Mia owes Alex $20
* John owes Alex $20

### 5. Expense History

Users can view all previous expenses.

### 6. Mark as Settled

Users can mark payments as completed.

---

## Competitive Comparison

### Manual Alternatives

* Notes app
* Calculator
* Spreadsheet

Weaknesses:

* Manual calculations
* No balance automation
* Easy to forget records

### Existing Apps

* Splitwise
* Tricount
* Settle Up

Weaknesses:

* Too many features for casual users
* Some premium locked features
* Not focused on student use cases

### SplitMate Positioning

SplitMate focuses on:

* Fast expense entry
* Clean UI
* Student-friendly workflows
* Small-group simplicity
* Easy-to-read balance summaries

---

## Unique Selling Proposition (USP)

A lightweight shared expense app designed specifically for students and small groups who need speed, simplicity, and clarity.

---

# Technical Design

## System Overview

SplitMate is built as an iOS application using SwiftUI and MVVM architecture. The system manages groups, members, expenses, and balance calculations using local persistence.

---

## Recommended Tech Stack

* SwiftUI
* Swift
* MVVM Pattern
* Codable + JSON local storage
* Foundation utilities

Optional future upgrades:

* SwiftData
* Charts
* UserNotifications

---

## Project Structure

```text id="u13t7n"
SplitMateApp
├── Models
├── ViewModels
├── Services
├── Views
└── Utilities
```

---

## Folder Structure

```text id="s0u4kc"
SplitMate/
├── Models/
│   ├── SplitGroup.swift
│   ├── Member.swift
│   ├── Expense.swift
│   └── ExpenseCategory.swift
├── ViewModels/
│   └── GroupViewModel.swift
├── Services/
│   ├── BalanceCalculatorService.swift
│   └── GroupStorageService.swift
├── Views/
│   ├── DashboardView.swift
│   ├── CreateGroupView.swift
│   ├── GroupDetailView.swift
│   ├── AddMemberView.swift
│   ├── AddExpenseView.swift
│   ├── ExpenseHistoryView.swift
│   └── BalanceSummaryView.swift
└── Utilities/
    └── CurrencyFormatter.swift
```

---

## Architecture Pattern

### MVVM

* Models store domain data
* Views render UI
* ViewModels manage state and business logic
* Services manage calculations and storage

---

## Data Models

### SplitGroup

```swift id="e0p7m0"
struct SplitGroup: Identifiable, Codable {
    let id: UUID
    var name: String
    var members: [Member]
    var expenses: [Expense]
    var createdAt: Date
}
```

### Member

```swift id="g1nq2f"
struct Member: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
}
```

### Expense

```swift id="6k6h2v"
struct Expense: Identifiable, Codable {
    let id: UUID
    var title: String
    var amount: Double
    var paidBy: UUID
    var participantIds: [UUID]
    var category: ExpenseCategory
    var date: Date
    var note: String?
    var isSettled: Bool
}
```

### ExpenseCategory

```swift id="k9r5fd"
enum ExpenseCategory: String, Codable, CaseIterable {
    case food
    case rent
    case transport
    case utilities
    case entertainment
    case other
}
```

---

## Main Data Flow

### App Launch

Load saved groups from local JSON into the main ViewModel.

### Create Group

Dashboard → CreateGroupView → Validate → Save → Refresh Dashboard

### Add Member

GroupDetailView → AddMemberView → Save Member → Refresh Group Screen

### Add Expense

AddExpenseView → Validate → Save Expense → Recalculate Balances → Refresh UI

---

## Balance Calculation Logic

For each unsettled expense:

1. Divide amount equally by participant count
2. Credit payer with full amount
3. Debit each participant share
4. Display final balances

---

## Example Calculation

Expense:

* Groceries $60
* Paid by Alex
* Shared by Alex, Mia, John

Each share = $20

Result:

* Alex should receive $40
* Mia owes $20
* John owes $20

---

## Persistence Design

Use Codable to encode and decode group data into a local JSON file stored in the app Documents directory.

---

## Error Handling

The app should prevent:

* Empty group name
* Empty member name
* Amount less than or equal to zero
* No payer selected
* No participants selected
* Save or load failures

The app should guide users with alerts and validation messages.
