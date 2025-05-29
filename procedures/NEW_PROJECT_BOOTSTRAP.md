# New Project Bootstrapping Workflow Guide (v4.1 - Enhanced Classification & Purpose)

This guide outlines the structured process for initiating a new project using a capable AI assistant with access to core operational rules (e.g., `global_rules.md` via user settings) and file system tools. The user acts as the orchestrator, guiding the AI through these steps and managing the local file system.

## Phase 1: Initiation & Intelligent Context Gathering

1.  **User Trigger Prompt:** Start the interaction with the AI using a prompt describing the project. Place a copy of this guide in the project root and reference it, e.g.,
    `AI, initiate the project setup for 'ai_rule_generator' following @[NEW_PROJECT_BOOTSTRAP.md]. Goal: Build a tool with a modern UI to assist in generating project-specific rule files.`
    *(Note: Ensure the @[] reference points correctly to the file within the *current* project workspace).*

2.  **AI Mandatory First Action: Project Classification, Parse, Confirm & Query:** Following the instructions from the referenced guide, the AI *must*:

    a. **Context Analysis:** If project-related files are already shared, analyze them for additional context before proceeding.
       
    b. **Project Classification & Purpose:** Identify both the project's scope category and its purpose:
    
       **Scope Categories:**
       - **Full Project:** Complete application with multiple features and components (e.g., a complete e-commerce platform)
       - **Feature Implementation:** Single feature within an existing project (e.g., adding a recommendation system to an e-commerce site)
       - **Step Implementation:** Sub-component of a feature (e.g., implementing the algorithm for a recommendation system)
       - **Script/Utility:** Small, focused tool or script (e.g., a data migration script)
       - **Research/Proof of Concept:** Time-boxed exploration (e.g., a 2-hour interview project, a weekend hackathon)
       
       **Development Intent:**
       - **MVP (Minimum Viable Product):** Initial version with core functionality only, expecting future iterations
       - **Full-Featured Solution:** Comprehensive implementation covering all requirements
       - **Technical Demonstration:** Focused on showcasing specific technologies or approaches
       - **Time-Boxed Deliverable:** Must be completed within strict time constraints (e.g., 2-hour interview)
       - **Learning Exercise:** Primary goal is knowledge acquisition rather than production use
       
    c. **Structured Understanding Summary:** Present understanding in a clear, point-by-point format:
       ```
       Please confirm each point (Yes/No):
       - Project Name: [Name]? (Yes/No)
       - Project Scope: [Type from scope categories]? (Yes/No)
       - Development Intent: [Type from development intent]? (Yes/No)
       - Primary Goal: [Goal]? (Yes/No)
       - Problem Solved: [Problem]? (Yes/No)
       - Target Users: [Users]? (Yes/No)
       - Core Features: [List key features]? (Yes/No)
       - Initial Tech Stack: [Technologies]? (Yes/No)
       - Key Constraints: [Constraints]? (Yes/No)
       ```
       
    d. **Tech Stack Checklist:** Address all relevant technology categories:
       - Backend Framework (with version)
       - Frontend/UI Framework (with version)
       - Database and Extensions
       - API Integration Methods
       - Real-time Features (if applicable)
       - AI/ML Components (if applicable)
       
    e. **Source of Inferred Features:** When listing features, cite the source of inference (e.g., "Based on the project description document, I understand the core features include...")
    
    f. **Missing Context Questions:** Ask ONLY essential missing questions, clearly labeled
    
    g. **Minimum Viable Features:** Request confirmation of the minimum viable features (MVF)
    
    h. **Timeline Assessment:** For all projects, explicitly ask about timeline constraints and how they affect scope prioritization. For time-boxed projects (e.g., interviews, hackathons), emphasize the need to prioritize features that can be completed within the time constraint.
    
    i. **Optional Components:** Query about Testing, Git, Deployment strategies
    
    j. **Research Signaling:** Explicitly state intention to research all mentioned technologies to verify versions and best practices after user confirmation

3.  **User Provides Context & Confirmations:** Answer the AI's specific questions and confirm its understanding.

4.  **AI Researches & Finalizes Tech Stack:** BEFORE proceeding, the AI *must* use its research tools (web search, Context7, etc.) to:
    *   Verify latest stable versions of proposed technologies.
    *   Check for known compatibility issues or significant drawbacks.
    *   Confirm alignment with current best practices for the project type.
    *   Identify any emerging alternatives that might better suit the project requirements.
    *   For time-constrained projects, prioritize technologies with rapid setup and minimal configuration.
    
    The AI presents findings and confirms the final tech stack choices with the user.
    *(No file generation in this phase yet)*

## Phase 2: Task-Specific Guideline Generation

5.  **AI Identifies & Proposes Rule Categories:** Based on the confirmed context and finalized tech stack, the AI identifies *relevant* rule categories and proposes them (e.g., "For the `ai_rule_generator` with React/FastAPI, I suggest rules for `API_DESIGN`, `REACT_STYLE`, `TESTING_STRATEGY`, `SECURITY`. OK?").

    **Rule Category Adaptation:** The AI should adapt the depth and breadth of rule categories based on the project's scope and development intent:
    - For time-boxed projects, focus on minimal, essential rules
    - For MVPs, focus on rules that enable rapid iteration
    - For full-featured solutions, provide comprehensive rule categories
    - For learning exercises, include educational comments within rules

6.  **User Confirms/Adjusts Rule Categories.**

7.  **AI Researches & Generates Draft Rule Files:** For each confirmed category, the AI *must* first **research** current best practices, official documentation, popular tooling (linters, formatters), and conventions specific to the chosen tech stack and project type. Based on this research, it generates draft content (e.g., `rules/REACT_STYLE.md`) reflecting up-to-date standards.
    
    **Rule Generation Process (Mandatory Steps):**
    a. **Research Phase**: Use web search tools to verify current best practices for the specific technology stack
    b. **Structure Validation**: Ensure each rule file follows consistent format with checklists and examples
    c. **Quality Assessment**: Each rule must be actionable, specific, and measurable
    d. **Integration Check**: Rules must work together without conflicts across different categories
    e. **Completeness Verification**: Cover all essential aspects of the technology/practice area
    f. **MANDATORY: Generate AI Workflow Rules** - Always create `rules/ai_workflow_rules.md` with continuous enforcement
    
    **Rule File Requirements:**
    - Use checkbox format for actionable items
    - Include both positive (✅ GOOD) and negative (❌ BAD) examples
    - Provide code examples where applicable
    - Keep each rule focused and specific (no vague guidelines)
    - Include testing requirements where relevant
    - Reference official documentation and current versions
    
    **MANDATORY Rule Files (Always Generated):**
    - `rules/ai_workflow_rules.md` - Code reuse, modular development, NO NEW/UPDATED files, 4-step process enforcement
    - At least 3-5 technology-specific rule files based on project requirements in `rules/` directory
    
    **MANDATORY Procedure Files (Always Generated):**
    - `procedures/LIVE_RULE_FILTERING_PROCESS.md` - Live rule filtering with continuous enforcement throughout project
    - `procedures/AI_HANDOFF_INSTRUCTIONS.md` - Complete instructions for AI continuity
    - `procedures/UNPLANNED_TASK_PROCESS.md` - How to handle unplanned work
    
    **Testing Guidelines:** When generating testing guidelines (if testing was requested), the AI must ensure the draft covers standard levels (Unit, Integration, System/E2E) and include recommendations for testing infrastructure appropriate to the project type and classification.

8.  **AI Presents Draft Rules & Prompts User to Save:** "Based on research into current best practices, here is the draft content for each rule file. Please review, adjust if needed, and save these to a `rules/` directory. Let me know when done."

9.  **User Saves Files & Confirms:** Manually create `rules/` directory and save the files locally. Confirm to the AI.

## Phase 3: Initial Planning

10. **AI Researches & Generates Project Plan:** Based on the confirmed context and MVP features, the AI generates the initial high-level `PROJECT_PLAN.md` content. For tasks involving specific technical implementations, the AI should perform a quick **research check** to ensure the proposed approach aligns with current best practices before outlining the task.

    **Project Plan Generation Process (Mandatory Steps):**
    a. **Step Decomposition**: Break complex features into 15-30 minute implementation steps
    b. **Dependency Mapping**: Ensure each step builds logically on previous steps
    c. **Testing Integration**: Every step must include both automated and manual testing requirements
    d. **Quality Gates**: Define specific deliverables and success criteria for each step
    e. **Time Estimation**: Realistic time estimates based on complexity and project constraints
    f. **Rule Integration**: Each step must reference which rule categories will be relevant
    
    **Step Structure Requirements:**
    - **Step Title**: Clear, descriptive name indicating what will be built
    - **Time Estimate**: Realistic estimate (15-30 minutes for small steps)
    - **File Count**: Approximate number of files to be created/modified
    - **Implementation Details**: Specific tasks to be completed
    - **Testing Requirements**: Both automated tests and manual verification steps
    - **Deliverable**: Clear success criteria and what should work after completion
    - **Commit Message**: Proper Git commit message format for the step

    **Plan Adaptation:** The plan structure should reflect both the project scope classification and development intent:
    - **Full Project:** Comprehensive phased approach with milestones
    - **Feature Implementation:** Focused tasks with integration points
    - **Step Implementation:** Detailed implementation steps with dependencies
    - **Script/Utility:** Straightforward development and testing steps
    - **Research/POC:** Time-boxed exploration phases with evaluation points
    
    **Timeline-Driven Planning:** For time-constrained projects, the plan must:
    - Explicitly state the time constraint at the beginning
    - Prioritize tasks that deliver core functionality first
    - Identify "nice-to-have" features that can be omitted if time runs short
    - Include specific checkpoints to assess progress against the timeline
    - Propose a simplified "fallback approach" if the primary approach proves too time-consuming
    
    **Live Rule Filtering Integration (MANDATORY):** The plan must incorporate the Live Rule Filtering Process as a core requirement:
    - **Every step MUST begin** with mandatory Live Rule Filtering phase (Step A)
    - **Cherry-pick only relevant rules** from all rule files for each specific task
    - **Document filtered rules** and explain why others were ignored
    - **Implementation follows ONLY filtered rules** to maintain laser focus
    - **Include rule filtering time** in step estimates (typically 2-3 minutes per step)
    - **4-Step Process**: Filter → Implement → Test → Commit (mandatory for every step)
    
    **Rule Filtering Requirements:**
    - Scan ALL rule files before each implementation step
    - Create focused mini-checklist (3-8 items maximum) of relevant rules only
    - Explicitly state which rules are ignored and why
    - Never apply all rules simultaneously - only cherry-picked ones
    - Document filtering decisions for AI continuity

11. **AI Presents Plan & Prompts User to Save:** "Here is the initial `PROJECT_PLAN.md`, incorporating current best practices for key technical steps. Please review and save this to your project root. Let me know when done."

12. **User Saves Plan & Confirms:** Save the file locally. Confirm to the AI.

## Phase 4: Memory Bank Initialization

13. **AI Generates Memory Bank Content:** Now that context, rules, and plan (informed by research) are defined, the AI generates the content for all initial Memory Bank files:
    *   `memory-bank/projectbrief.md`
    *   `memory-bank/productContext.md`
    *   `memory-bank/techContext.md` (Reflecting finalized, researched tech stack)
    *   `memory-bank/systemPatterns.md`
    *   `memory-bank/progress.md`
    *   `memory-bank/activeContext.md`

    **Memory Bank Content Requirements:**
    - **Project Brief**: High-level project overview, goals, and success criteria
    - **Product Context**: User needs, business requirements, and product vision
    - **Tech Context**: Finalized technology stack with versions and rationale
    - **System Patterns**: Code patterns, architectural decisions, and integration approaches
    - **Progress Tracking**: Current status, completed steps, next actions
    - **Active Context**: Immediate focus, current step details, and decision context
    
    **AI Continuity Requirements:**
    - Each file must be self-contained and readable by any AI assistant
    - Progress file must clearly indicate the next step to be implemented
    - Active context must provide enough detail for immediate action
    - All files must be updated throughout the project lifecycle

    **Memory Content Adaptation:** The content and detail level should be adapted based on project scope and intent:
    - For time-boxed projects, focus on essential information needed for rapid implementation
    - For learning exercises, include educational notes and explanations

14. **AI Presents Memory Content & Prompts User to Save:** "I have generated the initial content for all memory bank files... Please save these into a `memory-bank/` directory... Let me know when done."

15. **User Saves Files & Confirms:** Manually create `memory-bank/` directory and save all files locally. Confirm to the AI.

## Phase 5: Final Handoff

16. **AI Acknowledges & Starts:** The AI confirms completion of the bootstrap process and transitions to implementation mode.

    **Bootstrap Completion Checklist:**
    - [ ] All rule files generated with proper research and structure
    - [ ] **MANDATORY: rules/ai_workflow_rules.md created** with continuous enforcement
    - [ ] **MANDATORY: procedures/LIVE_RULE_FILTERING_PROCESS.md created** with 4-step process
    - [ ] **MANDATORY: procedures/AI_HANDOFF_INSTRUCTIONS.md created** for AI continuity
    - [ ] **MANDATORY: procedures/UNPLANNED_TASK_PROCESS.md created** for handling unplanned work
    - [ ] procedures/PROJECT_PLAN.md created with detailed, testable steps
    - [ ] Memory bank files created and populated
    - [ ] Live rule filtering process established
    - [ ] Quality gates and success criteria defined
    - [ ] **procedures/AI_HANDOFF_INSTRUCTIONS.md generated** (see step 17)
    - [ ] **procedures/LIVE_RULE_FILTERING_PROCESS.md generated** (see step 18)
    - [ ] **procedures/UNPLANNED_TASK_PROCESS.md generated** (see step 19)
    - [ ] **All enforcement mechanisms automatically created**
    
17. **AI Generates Handoff Instructions:** The AI automatically creates `procedures/AI_HANDOFF_INSTRUCTIONS.md` file containing complete instructions for any future AI assistant to seamlessly continue the project.

18. **AI Generates Live Rule Filtering Process:** The AI automatically creates `procedures/LIVE_RULE_FILTERING_PROCESS.md` file with detailed instructions for the mandatory 4-step process and continuous enforcement throughout the project.

19. **AI Generates Unplanned Task Process:** The AI automatically creates `procedures/UNPLANNED_TASK_PROCESS.md` file with instructions for handling unplanned work that arises during development.

    **Enforcement File Requirements:**
    - **procedures/AI_HANDOFF_INSTRUCTIONS.md**: Complete takeover instructions for any AI
    - **procedures/LIVE_RULE_FILTERING_PROCESS.md**: Mandatory 4-step process with continuous enforcement
    - **procedures/UNPLANNED_TASK_PROCESS.md**: Process for handling unplanned work
    - **Bootstrap completion checklist** in each file
    - **Violation detection and recovery** protocols
    - **Self-monitoring checkpoints** for AI assistants
    
    **Content Requirements for Enforcement Files:**
    - Step-by-step process for AI assistants taking over the project
    - File location references for all context and rule files
    - Current status detection instructions (how to read progress.md)
    - Mandatory 4-step process explanation with examples
    - Quality requirements and testing standards
    - Project context and technical stack overview
    - Example handoff scenario showing how AI should respond when taking over
    - **Continuous enforcement throughout entire project lifecycle**
    - **Violation detection and recovery protocols**
    - **Self-correction mechanisms for AI assistants**
    
    **Handoff File Content Structure:**
    ```markdown
    # AI Handoff Instructions - [Project Name]
    ## Step 1: Immediate Actions (Required)
    ## Step 2: Mandatory Process (Never Skip)
    ## Step 3: Critical Requirements (Non-Negotiable)
    ## Step 4: How to Resume Work
    ## Step 5: Project Context Understanding
    ## Step 6: Technical Stack
    ## Step 7: Ready Checklist
    ## Step 8: Example Handoff Process
    ```
    
    **Handoff Statement Format:**
    "🎉 BOOTSTRAP SETUP COMPLETE! 🎉
    
    All phases of the NEW_PROJECT_BOOTSTRAP.md workflow have been successfully completed:
    - ✅ Phase 1: Context Analysis & Project Classification
    - ✅ Phase 2: Task-specific rule files generated and saved (including MANDATORY rules/ai_workflow_rules.md)
    - ✅ Phase 3: PROJECT_PLAN.md created with [X] detailed steps
    - ✅ Phase 4: Memory Bank files initialized
    - ✅ Phase 5: Final Handoff completed with ALL enforcement mechanisms
    
    🔧 ENFORCEMENT MECHANISMS CREATED:
    - ✅ rules/ai_workflow_rules.md - Continuous 4-step process enforcement
    - ✅ procedures/LIVE_RULE_FILTERING_PROCESS.md - Mandatory rule filtering for every task
    - ✅ procedures/AI_HANDOFF_INSTRUCTIONS.md - Complete AI continuity instructions
    - ✅ procedures/UNPLANNED_TASK_PROCESS.md - Process for handling unplanned work
    
    📂 All files saved to: [directory path]
    
    🤖 AI HANDOFF READY: Any AI assistant can now continue this project using the prompt:
    'Please take over this project by reading and following the procedures/AI_HANDOFF_INSTRUCTIONS.md file at [file path]'
    
    ⚠️ CRITICAL: Every task from this point forward MUST follow the 4-step process:
    Step A: Live Rule Filtering → Step B: Implementation → Step C: Testing → Step D: Commit
    
    🚀 STARTING IMPLEMENTATION
    Starting Step 1 from PROJECT_PLAN.md: [Step Title]
    [Step Description and immediate requirements]
    
    Ready to proceed with Step 1A: Live Rule Filtering for [step focus]?"
    
    **Post-Bootstrap Requirements:**
    - User must confirm readiness before proceeding to implementation
    - **CRITICAL**: First step must begin with Live Rule Filtering process (Step A)
    - **Every subsequent step** must follow the 4-step process: Filter → Implement → Test → Commit
    - **Never skip rule filtering** - it's mandatory for every single task
    - Progress tracking must be updated after each completed step
    - Rule filtering decisions must be documented for AI continuity
    
    **Implementation Process Reminder:**
    ```
    Step X: [Task Name]
    └─▶ Step XA: Live Rule Filtering (MANDATORY)
        - Scan all 8 rule files
        - Cherry-pick 3-8 relevant rules only
        - Document ignored rules and reasons
    └─▶ Step XB: Implementation
        - Follow ONLY filtered rules
        - Focus on specific deliverable
    └─▶ Step XC: Testing & Validation
        - Automated tests + Manual verification
        - Both must pass before proceeding
    └─▶ Step XD: Documentation & Commit
        - Proper commit message
        - Update progress tracking
    ```

**Setup is now complete. Development proceeds following the Act/Plan modes, guided by the generated `PROJECT_PLAN.md`, project-specific `rules/`, contextual `memory-bank/`, and the assumed active global rules.**