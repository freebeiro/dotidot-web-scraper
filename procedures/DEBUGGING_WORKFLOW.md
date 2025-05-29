# Debugging Workflow - Cross-AI Procedure

## 🎯 Purpose

This procedure provides a systematic approach for debugging recurring errors, failed tests, and code quality issues while preserving the integrity of the main development branch.

## 🚨 **MANDATORY TRIGGERS** - When to Enter Debugging Mode

Enter debugging mode immediately when ANY of these conditions occur:

1. **`bundle exec rubocop -A && bundle exec rspec` fails**
2. **Recurring test failures** (same test fails multiple times)
3. **RuboCop violations that auto-fix can't resolve**
4. **Integration failures** between services/components
5. **Performance issues** affecting core functionality
6. **Deployment/CI failures** that block progress
7. **Complex refactoring** that might break existing functionality

## 🔄 **DEBUGGING_TASK Classification**

- **Task Type**: `DEBUGGING_TASK` (separate from unplanned tasks)
- **Priority**: Always `HIGH` (blocks development progress)
- **Documentation**: Must be logged for future reference
- **Outcome**: Clean solution applied to feature branch

## 📋 **Step-by-Step Debugging Procedure**

### **Phase 1: Preparation & Branch Setup**

#### Step 1: Document the Problem
```bash
# 1A. Capture the exact error/failure
echo "DEBUGGING_TASK initiated: $(date)" >> debug_log.md
echo "Problem: [describe the issue]" >> debug_log.md
echo "Trigger: [rubocop/rspec/integration/etc]" >> debug_log.md
```

#### Step 1B: Verify Current State
```bash
# Ensure we're on the correct feature branch
git status
git branch
# Note: Should be on a feature branch, NOT main
```

#### Step 1C: Create Debug Branch
```bash
# Create debug branch from current feature branch
git checkout -b debug/[issue-description]
# Example: debug/fix-rubocop-rspec-failures
# Example: debug/fix-integration-test-failures
```

### **Phase 2: Safe Experimentation**

#### Step 2A: Reproduce the Issue
```bash
# Document exact reproduction steps
bundle exec rubocop -A && bundle exec rspec
# Or whatever command is failing
# Copy full output to debug_log.md
```

#### Step 2B: Analyze & Hypothesize
- **Identify root cause** (not just symptoms)
- **List possible solutions** (at least 3 approaches)
- **Estimate complexity** of each approach
- **Choose starting approach** (simplest first)

#### Step 2C: Experiment Freely
- **Try solutions without fear** - debug branch is disposable
- **Break things** - learn what doesn't work
- **Commit frequently** - `git commit -m "debug: trying approach X"`
- **Document learnings** - what worked, what didn't, why

### **Phase 3: Solution Validation**

#### Step 3A: Verify Complete Fix
```bash
# Run ALL quality checks
bundle exec rubocop -A
bundle exec rspec
# Plus any project-specific checks
```

#### Step 3B: Test Edge Cases
- **Run tests multiple times** (check for flaky tests)
- **Test different scenarios** that might be affected
- **Verify no regressions** in existing functionality

#### Step 3C: Document Solution
```markdown
## Solution Found
- **Root Cause**: [explain the actual problem]
- **Solution**: [describe the fix]
- **Why This Works**: [explain the mechanism]
- **Tested By**: [list verification steps]
```

### **Phase 4: Clean Implementation**

#### Step 4A: Return to Feature Branch
```bash
# Switch back to clean feature branch
git checkout [feature-branch-name]
# Verify clean state
git status
```

#### Step 4B: Apply Clean Solution
- **Implement ONLY the final solution** (no debug code)
- **Use proper commit messages** following git_workflow_rules.md
- **Apply best practices** from code_quality_rules.md

#### Step 4C: Final Verification
```bash
# Verify clean implementation works
bundle exec rubocop -A && bundle exec rspec
# All checks must pass
```

### **Phase 5: Cleanup & Documentation**

#### Step 5A: Document for Future Reference
```bash
# Create debugging task documentation
echo "procedures/unplanned_tasks/TASK_XXX_DEBUG_[ISSUE].md"
```

#### Step 5B: Clean Up Debug Branch
```bash
# Option 1: Delete debug branch (if solution is simple)
git branch -D debug/[issue-description]

# Option 2: Keep for reference (if complex solution)
git push origin debug/[issue-description]
# Document branch location in task log
```

## 🎯 **AI-Specific Instructions**

### For Any AI/LLM Following This Procedure:

1. **ALWAYS check if debugging mode is needed** before making changes
2. **Create the debug branch first** - never experiment on feature branches
3. **Document every attempt** - future AIs need context
4. **Verify the full solution** - not just the immediate fix
5. **Apply clean final solution** - no debug artifacts in feature branch

### Cross-Session Handoff:

When continuing debugging in a new chat session:

```markdown
## Debugging Context Handoff
- **Issue**: [original problem description]
- **Debug Branch**: debug/[branch-name]
- **Attempts Made**: [list what was tried]
- **Current Status**: [where we left off]
- **Next Steps**: [what to try next]
```

## ⚠️ **Critical Rules**

1. **NEVER commit debug code to feature branches**
2. **ALWAYS verify complete solution before applying to feature branch**
3. **MUST document the debugging process for future reference**
4. **Keep debug branches separate from feature work**
5. **Test edge cases - not just the happy path**

## 🔄 **Integration with Existing Workflows**

- **Before any development task**: Check if debugging mode is needed
- **During git commits**: Ensure no debug artifacts are committed
- **In task planning**: Account for potential debugging tasks
- **Cross-AI sessions**: Always check for existing debug branches

## 📊 **Success Metrics**

- ✅ `bundle exec rubocop -A && bundle exec rspec` passes
- ✅ No regressions in existing functionality  
- ✅ Solution is documented and reproducible
- ✅ Debug branch cleaned up appropriately
- ✅ Knowledge captured for future debugging

---

**Remember**: Debugging mode is a powerful tool. Use it proactively to maintain code quality and prevent technical debt accumulation.