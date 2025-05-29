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

### **Step 2: Follow Standard 4-Step Process**

Even unplanned tasks MUST follow the standard process:

#### **📋 Step A: Live Rule Filtering**
- Scan relevant rule files
- Cherry-pick applicable rules
- Document filtering inline

#### **🛠️ Step B: Implementation**
- Implement following filtered rules
- Keep changes focused and atomic

#### **🧪 Step C: Testing & Validation**
- Automated tests (if applicable)
- Manual verification
- Document test commands

#### **📝 Step D: Documentation & Commit**
- Commit with descriptive message
- Update progress.md with completion
- Note any impacts on planned work

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

## 🚨 Important Notes

- **Never skip documentation** for "quick fixes"
- **Always follow 4-step process** even for small changes
- **Update progress.md** for every unplanned task
- **Use descriptive commit messages** that reference the task
- **Consider impact** on current/future planned work

---

**Remember**: Unplanned tasks are part of real development. Handling them professionally with full documentation makes the project stronger and more maintainable.