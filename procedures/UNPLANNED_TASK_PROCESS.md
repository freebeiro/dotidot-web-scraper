# Unplanned Task Process - Dotidot Web Scraper

## 🎯 Purpose

This document defines how to handle unplanned tasks, changes, or improvements that arise during development. Every change must be traceable and follow the same quality standards as planned work.

## 📋 Process for Unplanned Tasks

### **Step 1: Document the Task**

When a new unplanned task is identified:

1. **Create a task entry** in progress.md under a new section:
   ```markdown
   ## 🔧 Unplanned Tasks Log

   ### Task U1: [Task Description]
   **Requested**: [Date/Time]
   **Reason**: [Why this task is needed]
   **Status**: Pending
   **Impact**: [Does this affect current step? Yes/No]
   ```

2. **Add to TodoWrite** with prefix "UNPLANNED:"
   ```
   id: "unplanned-1"
   content: "UNPLANNED: [Task description]"
   status: "pending"
   priority: "medium"
   ```

### **Step 2: Follow EXACT Same Workflow as Planned Tasks**

Unplanned tasks MUST follow the **IDENTICAL workflow** as planned tasks:

#### **📋 Step A: Live Rule Filtering (MANDATORY)**
```markdown
## Live Rule Filtering for TASK_XXX

### Scanning rule files...
- Checking testing_strategy_rules.md...
  - ✅ CHERRY-PICKED: "Run full test suite before marking complete"
  - ✅ CHERRY-PICKED: "Fix failing tests incrementally"
- Checking code_quality_rules.md...
  - ✅ CHERRY-PICKED: "All code must pass RuboCop"
```

**Document the actual rules you're following!**

#### **🛠️ Step B: Implementation Plan**
- Create implementation checklist BEFORE starting
- Break down into subtasks
- Follow filtered rules strictly

#### **🧪 Step C: Testing & Validation**
- Run all tests as per testing rules
- Validate against acceptance criteria
- Document all test commands and results

#### **📝 Step D: Documentation & Commit**
- Create proper documentation file
- Update task log
- Commit with standard format
- Update progress tracking

### **Step 3: Update Progress Tracking**

After completing the unplanned task:

1. **Update task entry** in progress.md:
   ```markdown
   ### Task U1: [Task Description]
   **Requested**: [Date/Time]
   **Completed**: [Date/Time]
   **Reason**: [Why this task is needed]
   **Status**: ✅ Complete
   **Impact**: [Did this affect current step?]
   **Commit**: [commit hash or message]
   **Changes**: [Brief summary of what was done]
   ```

2. **Update TodoWrite** to mark complete

3. **Resume planned work** from where it was paused

## 📊 Examples of Unplanned Tasks

### **Infrastructure Changes**
- Reorganizing directory structure
- Updating documentation processes
- Fixing git issues
- Environment configuration

### **Process Improvements**
- Adding new procedures
- Clarifying existing processes
- Improving development workflow

### **Bug Fixes**
- Fixing broken tests
- Resolving dependency issues
- Correcting configuration errors

### **Rollbacks**
- Reverting problematic changes
- Undoing commits
- Restoring previous state

## 🔄 Rollback Process

If an unplanned task needs to be rolled back:

1. **Document the rollback**:
   ```markdown
   ### Rollback R1: [What is being rolled back]
   **Original Task**: U1
   **Reason for Rollback**: [Why rollback is needed]
   **Status**: In Progress
   ```

2. **Perform the rollback**:
   - Use `git revert` for clean history
   - Or `git reset` if not yet pushed
   - Document the approach used

3. **Update tracking**:
   - Mark original task as "Rolled Back"
   - Document lessons learned
   - Update any affected documentation

## 📝 Integration with Existing Process

### **During Step Implementation**
If unplanned task arises DURING a step:
1. Pause current step
2. Document current progress
3. Handle unplanned task
4. Resume step implementation

### **Between Steps**
If unplanned task arises BETWEEN steps:
1. Complete current step first (if possible)
2. Handle unplanned task
3. Continue to next planned step

## ✅ Benefits of This Process

1. **Full Traceability**: Every change is documented
2. **Consistent Quality**: All work follows same standards
3. **Clear Timeline**: Shows when/why changes happened
4. **Easy Handoff**: Other AIs can see full history
5. **Learning Record**: Documents decisions and rationale

## 📖 Example: How TASK_003 Should Have Been Handled

### Step 1: Document the Task
```markdown
### Task U3: Debug and Fix 156+ Failing Specs
**Requested**: 2025-05-29 14:00
**Reason**: Blocking Task #1 verification
**Status**: Pending
**Impact**: Yes - blocks Task #1 completion
```

### Step 2A: Live Rule Filtering
```markdown
## Live Rule Filtering for TASK_003

### Scanning testing_strategy_rules.md...
- ✅ CHERRY-PICKED: "Fix failing tests incrementally, one file at a time"
- ✅ CHERRY-PICKED: "Never modify test expectations without understanding why they're failing"
- ✅ CHERRY-PICKED: "Run focused specs first: bundle exec rspec spec/file_spec.rb"

### Scanning code_quality_rules.md...
- ✅ CHERRY-PICKED: "Extract complex methods when exceeding RuboCop limits"
- ✅ CHERRY-PICKED: "Use service objects for business logic"
```

### Step 2B: Implementation Plan
- [ ] Identify root cause of failures
- [ ] Fix service API inconsistencies
- [ ] Update specs to match implementation
- [ ] Run RuboCop and fix violations
- [ ] Verify all tests pass

### Step 2C: Testing & Validation
```bash
bundle exec rspec --fail-fast  # Find first failure
bundle exec rspec spec/services/  # Fix service specs first
bundle exec rubocop --autocorrect  # Fix style issues
bundle exec rspec  # Full suite
```

### Step 2D: Documentation
- Created procedures/unplanned_tasks/TASK_003_DEBUG_FIX_SPECS.md
- Updated task log
- Committed with proper message

## 🚨 Important Notes

- **Never skip documentation** for "quick fixes"
- **Always follow the EXACT workflow** as planned tasks
- **Live rule filtering is MANDATORY** - not optional
- **Create implementation plan BEFORE coding**
- **Update progress.md** for every unplanned task
- **Use descriptive commit messages** that reference the task
- **Consider impact** on current/future planned work

---

**Remember**: Unplanned tasks are part of real development. Handling them professionally with full documentation makes the project stronger and more maintainable.

## Task Log

| Task ID | Date | Description | Impact | Documented |
|---------|------|-------------|--------|------------|
| TASK_001 | 2025-01-30 | CI/CD Pipeline Setup | High - Adds automated quality gates | ✅ [Link](unplanned_tasks/TASK_001_CICD_SETUP.md) |
| TASK_002 | 2025-05-29 | Debugging Workflow Documentation | Low - Process documentation | ✅ [Link](unplanned_tasks/TASK_002_DEBUGGING_WORKFLOW.md) |
| TASK_003 | 2025-05-29 | Debug and Fix 156+ Failing Specs | Critical - Unblocked Task #1 | ✅ [Link](unplanned_tasks/TASK_003_DEBUG_FIX_SPECS.md) |