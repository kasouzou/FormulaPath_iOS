# AGENTS.md

This document provides guidelines for AI agents to understand the `FormulaPath` codebase and develop, refactor, and fix bugs according to a consistent design philosophy.

## 1. Project overview
FormulaPath is a formula derivation puzzle game app for iOS that explains the origins of formulas and the derivation process in a step-by-step puzzle format. The UI incorporates a beautiful and sophisticated design (slight pink and purple gradations, beautiful borders, etc.).

## 2. Absolute rules and design philosophy in development

### ① Decoupling & Encapsulation
- Each component, View, and ViewModel are designed so that they do not strongly depend on each other.
- Direct logic for data persistence (SQLite, etc.) and external resource loading (JSON, etc.) should be hidden (encapsulated) inside a dedicated manager class, so that dirty operations cannot be seen directly from Views and ViewModels.

### ② Single Source of Truth
- Management and synchronization of in-app problem list and user progress status (such as "unlocked" and "cleared") is centralized in `GameDataManager`.
- **[Important]** To avoid breaking the automatic screen display update (reactive) mechanism, it is prohibited to save or update data by directly hitting `SQLiteManager` from `GamePlayViewModel` or each View. Be sure to update the state via a centralized method such as `updateProgress(problemId:newStatus:)` in `GameDataManager` and have the UI auto-detect changes to `@Published` properties.

### ③ Respect for existing code and comments
- **[Most Important]** When proposing or rewriting a modified version of code, **Never delete comments written in the original code (including explanations marked with 💡). ** Preserving development intent in the code is a top priority.
- Always implement with proper error handling, security considerations, code readability, and efficient algorithm selection in mind.
## 3. Main components and division of roles

### 📂 Views & ViewModels
- **`ContentView.swift`**
  - App launch entry point. Its simple role is to initialize `FormulaPathHomeView` and place it on the screen.
- **`FormulaPathHomeView.swift`**
  - Main home screen of the app. It centrally manages the entire screen transition stack (`NavigationPath`) and is responsible for safe and loosely coupled screen transition logic using `FormulaPathDestination` (enum).
- **`StageSelectionView.swift`**
  - Official/question list screen for each category (junior high school, high school, university, etc.). It receives the file name from the parent and internally manages the lifecycle of `GameDataManager` safely as `@StateObject`.
- **`GamePlayView.swift` & `GamePlayViewModel`**
  - Puzzle game play screen and state management.
  - `GamePlayViewModel` is not a structure that accumulates a permanent stack, but is a disposable design (it is deinited when you leave the screen) only to solve the real-time state (current step, shake effect flag, etc.) of "one problem in front of you". The progress update when clearing is delegated to the received `GameDataManager`.

### 📂 Models & Managers
- **`MathProblem.swift`**
  - Data structure definition. Defines `DerivationStep` (step information), `MathProblem` (whole problem), and `ProblemWithProgress` (problem with progress). Conforms to `Hashable` for safe handling in `NavigationPath`.
- **`GameDataManager.swift`**
  - A management craftsman class that encapsulates data loading and coalescing logic. The static problem data obtained from `JSONManager` and the user's progress obtained from `SQLiteManager` are mapped (combined) based on ID, and the latest array (`@Published var menuProblems`) is maintained.

## 4. Implementation checklist for agents
When modifying or adding functionality, please make sure that all of the checklists below are met.
- [ ] Are you writing code that calls `SQLiteManager` directly from View or ViewModel? (Is it via `GameDataManager`?)
- [ ] When adding a new screen transition, can you consolidate the logic into the `FormulaPathHomeView` enum (`FormulaPathDestination`) and `navigationDestination`?
- [ ] Are all the explanatory comments and hint comments with the 💡 mark in the original code left without being deleted?
- [ ] Have you considered the placement of appropriate UI components so that the screen layout does not become unstable due to variations in choices (3 choices, 4 choices, etc.)?
- [ ] Write a commit message in Japanese for each conversation and commit.You can go as far as committing. Never push.
