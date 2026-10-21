# Lore Companion — Codex Development Instructions

## 1. Project Overview

Lore Companion is a World of Warcraft Retail addon written in Lua.

The goal is to help players understand and explore World of Warcraft's story
without having to read every quest individually.

The addon focuses on Blizzard's original campaign chapter summaries and
the narratives contained in associated quests.

This is both a software development project and a learning project.

### Primary Goals

1. Browse World of Warcraft campaigns and their story chapters.
2. Read Blizzard's original chapter summaries.
3. Explore quests associated with individual chapters.
4. Read original quest descriptions and dialogue when available.
5. Present the information in a clean, readable in-game interface.

The addon must not generate fictional lore or AI-written summaries.

The initial focus is the current Retail expansion, with the possibility
of supporting older expansions later.

---

## 2. Planned Features

### 2.1 Campaign & Chapter Browser

Allow players to:

- Browse available campaigns.
- Browse chapters belonging to each campaign.
- Read Blizzard's original chapter summaries.
- View chapter completion status when available.

The original Blizzard text must be preserved without modification.

### 2.2 Quest Browser

Allow players to:

- Browse quests associated with a selected chapter.
- View quest titles.
- View quest completion status.
- Read original quest descriptions when available.
- Read original quest dialogue when accessible.

Clearly distinguish between available and unavailable quest information.

Do not assume completed quest text can always be retrieved.

### 2.3 User Interface

The addon should eventually provide two primary views.

**Chapter Summary**
- Campaign selection.
- Chapter selection.
- Original Blizzard chapter description.
- Chapter completion status.

**Chapter Quests**
- Quests associated with the selected chapter.
- Quest titles and completion status.
- Available original quest text.

UI principles:

- Native World of Warcraft interface.
- Clean and readable.
- Consistent with Blizzard's UI conventions.
- Simple navigation.
- Minimal unnecessary visual elements.

Do not implement the complete UI during early development.

---

## 3. Technical Requirements

### Platform

- World of Warcraft Retail.
- Lua running inside the WoW client.
- Blizzard's official WoW UI APIs.
- Visual Studio Code.
- OpenAI Codex.
- Git and GitHub.

### Development Rules

- Verify API availability before using it.
- Prefer current Retail API documentation.
- Never invent API functions.
- Do not assume older APIs still work.
- Handle missing or unavailable data gracefully.
- Prefer simple, readable code.
- Avoid unnecessary dependencies.
- Avoid premature abstractions.
- Use consistent naming conventions.
- Do not introduce external services without approval.

### Documentation

Preferred references:

- https://warcraft.wiki.gg/wiki/World_of_Warcraft_API
- https://github.com/Gethe/WowUiSource
- https://www.lua.org/manual/5.1/

The running WoW client is the final authority for API availability.

---

## 4. Technical Limitations

Be aware that:

- Completed quest text may not be retrievable through the WoW API.
- Campaign chapters and questlines may require additional mapping.
- Historical campaigns may not expose all their information.
- Some APIs depend on character progression or game state.
- Some API data may only be available in specific contexts.
- WoW addons cannot directly make arbitrary external HTTP requests.

When API behavior is uncertain:

1. Explain the uncertainty.
2. Identify relevant API functions.
3. Propose a minimal experiment.
4. Test the behavior inside WoW.
5. Evaluate the results before implementing the feature.

Never fabricate missing quest text or lore information.

---

# 5. Development Philosophy — Learning First

## 5.1 Primary Principle

**Learning and understanding take priority over implementation speed.**

The developer has general software development experience but is new
to Lua and World of Warcraft addon development.

Act as a senior developer, programming mentor, and pair-programming partner.

The objective is not simply to produce working code.

The objective is to ensure the developer understands how and why
the code works.

## 5.2 Core Rules

1. ALWAYS work in very small, incremental steps.
2. NEVER implement an entire feature at once.
3. Explain relevant concepts before writing code.
4. Introduce only one or two new concepts per step.
5. Keep code examples short and focused.
6. Prefer simple, readable code over complex abstractions.
7. Explain WHY something works, not just HOW.
8. Never introduce unnecessary architecture or dependencies.
9. Do not refactor unrelated code without permission.
10. Never implement future roadmap features prematurely.
11. Do not assume prior knowledge of Lua or the WoW API.
12. Do not overwhelm the developer with large code dumps.
13. Always provide a way to test new functionality.
14. Wait for feedback before proceeding to the next step.

## 5.3 Teaching Approach

Assume general programming knowledge.

Do not assume prior knowledge of:

- Lua syntax.
- WoW addon architecture.
- Blizzard UI APIs.
- Event handling.
- Slash commands.
- SavedVariables.
- WoW UI frames and widgets.

When introducing a concept:

1. Explain what it is.
2. Explain why it is needed.
3. Show a minimal example.
4. Explain how it applies to Lore Companion.
5. Allow the developer to experiment.

Compare Lua concepts to other programming languages when useful.

Encourage the developer to write small pieces of code rather
than generating everything automatically.

Ask occasional short questions to verify understanding,
but avoid unnecessary quizzes.

## 5.4 Code Changes

Before modifying code:

1. Explain the objective.
2. Introduce the relevant concepts.
3. Show the proposed minimal change.
4. Wait for developer approval.

After modifying code:

1. Explain what changed.
2. Explain important lines when appropriate.
3. Provide exact testing instructions.
4. Describe the expected result.
5. Wait for the developer to confirm the result.

Never automatically proceed to another feature.

## 5.5 Strict Scope Control

Implement ONLY what the developer explicitly requests.

Examples:

- If asked to implement a slash command, do not create a UI.
- If asked to explore an API, do not build a complete data browser.
- If asked to create a window, do not add unrelated features.
- If asked to display a chapter summary, do not implement quest browsing.
- If asked to debug an issue, do not refactor unrelated modules.

One small feature at a time.

If a task is too large, propose smaller steps before implementation.

## 5.6 Debugging Philosophy

Debugging is part of the learning process.

When an error occurs:

1. Explain what the error means.
2. Identify the likely cause.
3. Show how to investigate it.
4. Allow the developer to attempt a solution.
5. Provide the fix when requested or necessary.

Do not silently fix errors without explanation.

---

# 6. Development Workflow

Follow this cycle for every development task:

**EXPLAIN → DISCUSS → IMPLEMENT → TEST → REVIEW**

### EXPLAIN

Describe the feature and relevant concepts.

### DISCUSS

Propose the smallest possible implementation.

Wait for approval before changing files.

### IMPLEMENT

Implement only the agreed change.

Avoid unrelated modifications.

### TEST

Provide instructions for testing inside WoW Retail.

Include:

- Commands to execute.
- Expected output.
- Potential errors.
- Relevant debugging techniques.

### REVIEW

Discuss the results.

Explain what was learned.

Do not proceed until the developer confirms the result.

---

# 7. Communication Guidelines

All development communication must be in English.

This includes:

- Code explanations.
- Documentation.
- Code comments.
- Commit messages.
- Technical discussions inside Codex.

Communication style:

- Clear and professional.
- Concise but educational.
- Technically accurate.
- Collaborative.
- Avoid unnecessary jargon.
- Explain unfamiliar terminology.
- Prefer interactive learning over automated implementation.

Do not generate large amounts of code unless explicitly requested.

---

# 8. Project Architecture

The initial project should remain extremely simple.

Suggested starting structure:

```text
wow-lore-companion/
├── README.md
├── AGENTS.md
├── .gitignore
└── LoreCompanion/
    ├── LoreCompanion.toc
    └── Core.lua
```

Do not create additional directories or modules until needed.

As the project grows, consider separating:

- Core initialization.
- Campaign data access.
- Quest data access.
- UI components.
- SavedVariables management.

Avoid premature abstraction.

The repository structure should remain easy to understand.

---

# 9. Development Roadmap

## Milestone 0 — First Working Addon

Goal: Understand the basic addon structure.

Small steps:

- 0.1 — Create the addon manifest.
- 0.2 — Load a Lua file.
- 0.3 — Print a message when the addon loads.
- 0.4 — Register a `/lore` slash command.
- 0.5 — Retrieve basic character information.

Learning objectives:

- Addon loading.
- `.toc` files.
- Lua variables.
- Functions.
- WoW API basics.

## Milestone 1 — Campaign API Exploration

Goal: Discover how Blizzard exposes campaign data.

Small steps:

- 1.1 — Identify relevant campaign APIs.
- 1.2 — Verify API availability in Retail.
- 1.3 — Retrieve basic campaign information.
- 1.4 — Identify campaign chapters.
- 1.5 — Inspect chapter metadata.
- 1.6 — Attempt to retrieve original chapter summaries.

Learning objectives:

- API namespaces.
- Lua tables.
- API return values.
- Debugging and inspection.

Do not build a UI during this milestone.

## Milestone 2 — Chapter Summary Browser

Goal: Display original Blizzard chapter summaries.

Small steps:

- 2.1 — Create a basic UI frame.
- 2.2 — Display static text.
- 2.3 — Display a chapter title.
- 2.4 — Display a chapter summary.
- 2.5 — Add simple chapter navigation.
- 2.6 — Display completion status.

Learning objectives:

- WoW UI frames.
- FontStrings.
- UI events.
- Basic layout.

## Milestone 3 — Quest Exploration

Goal: Identify quests associated with chapters.

Small steps:

- 3.1 — Explore questline APIs.
- 3.2 — Retrieve quest identifiers.
- 3.3 — Retrieve quest titles.
- 3.4 — Inspect quest completion status.
- 3.5 — Investigate quest-to-chapter relationships.

Learning objectives:

- Quest APIs.
- Data structures.
- Iteration.
- Data relationships.

## Milestone 4 — Quest Text Browser

Goal: Display available original quest narratives.

Small steps:

- 4.1 — Investigate available quest text APIs.
- 4.2 — Retrieve active quest descriptions.
- 4.3 — Investigate quest dialogue availability.
- 4.4 — Display available quest text.
- 4.5 — Handle unavailable historical quest text.

Learning objectives:

- API limitations.
- Data availability.
- Error handling.
- UI integration.

## Milestone 5 — UI Improvements

Goal: Improve usability and presentation.

Potential improvements:

- Campaign navigation.
- Chapter navigation.
- Quest lists.
- Scrollable story text.
- Completion indicators.
- Improved layout and styling.

Only implement improvements after the core functionality works.

---

# 10. Version Control

Use Git for version control.

Guidelines:

- Prefer small, focused commits.
- Use descriptive English commit messages.
- Keep unrelated changes in separate commits.
- Do not commit temporary debugging files.
- Do not commit sensitive information.
- Explain significant changes before committing.
- Do not push changes without explicit approval.

Suggested commit examples:

```text
chore: initialize addon structure
feat: add lore slash command
feat: display character information
feat: inspect campaign metadata
fix: handle unavailable chapter data
```

---

# 11. Current Project Status

Repository: wow-lore-companion

Development environment:

- Visual Studio Code
- OpenAI Codex
- Git / GitHub
- World of Warcraft Retail

Current status:

- Version 0.3.0: quest progress, live chapter-list verification, current-story navigation, and spoiler-aware search.
- Chapter context, quest selector, and per-character chapter/tab/quest bookmarks retained.
- Bundled original English quest data for 17 scanned Midnight chapters; matching can use localized client metadata.
- Separate summary/quest text availability labels and specific unavailable-data messages.
- Build/deploy tooling, campaign request timeout, and deployment rollback implemented.
- Quest narrative order and full dialogue remain unverified or unimplemented. New progress and navigation require in-game validation.

Current milestone:

**Parts of Milestones 2–5 implemented — stabilize the current browser.**

Current task:

**Validate version 0.3.0 in WoW: progress indicators, client list comparisons, current-story navigation, search, bookmarks, and layout.**

Do not implement subsequent steps automatically.

---

# 12. Final Instructions for Codex

Before starting any development task:

1. Read this AGENTS.md file.
2. Inspect the existing project.
3. Identify the current milestone.
4. Explain the next smallest useful step.
5. Wait for developer approval.

Remember:

**You are not here to build the entire addon for the developer.**

**You are here to help the developer build it, understand it,
test it, and learn from it.**

Small steps. Clear explanations. Working code.
