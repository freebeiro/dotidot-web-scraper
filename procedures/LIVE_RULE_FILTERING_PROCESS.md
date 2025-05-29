# Live Rule Filtering Process - Dotidot Web Scraper

## 🎯 Purpose

This document defines the **Live Rule Filtering Process** that must be followed for every implementation step. This ensures that any AI assistant can pick up the work and continue seamlessly without losing context.

## 🔄 Mandatory 4-Step Process for Every Task

### **📋 Step A: Live Rule Filtering (MANDATORY)**

**When starting ANY implementation step, the AI MUST:**

1. **Announce the current step** clearly (e.g., "Starting Step 3: Basic Error Classes")
2. **Scan all 8 rule files** in real-time:
   - `rules/git_workflow_rules.md`
   - `rules/api_design_rules.md` 
   - `rules/security_patterns_rules.md`
   - `rules/performance_optimization_rules.md`
   - `rules/testing_strategy_rules.md`
   - `rules/code_quality_rules.md`
   - `rules/web_scraping_rules.md`
   - `rules/ai_workflow_rules.md`

3. **Cherry-pick ONLY relevant rule lines** for this specific task:
   - ✅ **Include**: Rules that directly apply to current implementation
   - ❌ **Exclude**: Rules that don't make sense for this step
   - 📝 **Document**: Which rules were selected and why
   - 📝 **Document**: Which rules were ignored and why

4. **Create focused mini-checklist** of 3-8 relevant rule items maximum

**IMPORTANT: Filtered Rules Handling**
- **DO NOT create separate files** for filtered rules
- **Perform filtering inline** in your response
- **Document filtered rules** in progress.md after task completion
- This keeps the project clean while maintaining traceability

**Example Live Filtering:**
```markdown
## Live Rule Filtering for Step 3: Basic Error Classes

### ✅ RELEVANT RULES (Cherry-picked):
- **Code Quality**: Use descriptive class names, single responsibility
- **Code Quality**: Create custom exception hierarchy with proper inheritance
- **Testing Strategy**: Test exception classes can be instantiated with messages
- **Git Workflow**: Commit message format `feat: add custom exception hierarchy`

### ❌ IGNORED RULES (Not applicable now):
- **API Design**: No API endpoints yet
- **Security Patterns**: No input validation yet  
- **Web Scraping**: No scraping logic yet
- **Performance**: Basic classes, no optimization needed yet
```

### **🛠️ Step B: Implementation**
- Implement following **ONLY** the filtered rules from Step A
- Keep focused on the specific deliverable
- No rule checking beyond the filtered list

### **🧪 Step C: Testing & Validation**
**BOTH automated and manual testing required:**

**Automated Tests:**
- [ ] RSpec tests pass (when applicable)
- [ ] Specific test commands documented

**Manual Testing:**
- [ ] Rails console verification
- [ ] Curl commands (for API endpoints)
- [ ] Server startup tests
- [ ] Specific manual verification steps documented

**Testing Documentation Format:**
```bash
# Automated Testing
bundle exec rspec spec/path/to/new_spec.rb

# Manual Testing  
rails console
# Then test in console:
# SomeClass.new.method_call
# exit

# Additional verification
curl -X GET "http://localhost:3000/endpoint"
```

### **📝 Step D: Documentation & Commit**
- [ ] **Document what was accomplished** (2-3 sentences)
- [ ] **Commit with proper message** following rules/git_workflow_rules.md
- [ ] **Tag as ready** for next step
- [ ] **Update progress** in memory bank if needed

**Commit Message Format:**
- Use type from git rules: `feat:`, `fix:`, `test:`, `refactor:`, `docs:`, `chore:`, `security:`
- 50 characters or less
- Imperative mood
- No period at end

## 🔄 Continuity for Other AI Assistants

### **Context Files to Reference:**
1. **Current Progress**: Check `memory-bank/progress.md` for last completed step
2. **Active Context**: Check `memory-bank/activeContext.md` for current focus
3. **Technical Context**: Check `memory-bank/techContext.md` for stack decisions
4. **Project Brief**: Check `memory-bank/projectbrief.md` for overall goals

### **How to Resume Work:**
1. **Read the progress file** to understand last completed step
2. **Find the next step** in procedures/PROJECT_PLAN.md
3. **Follow this Live Rule Filtering Process** exactly
4. **Update progress file** after completion

### **Rule File Locations:**
All rule files are located in: `/Users/freebeiro/Documents/fcr/claudefiles/dotidot-scraper/rules/`
- `git_workflow_rules.md`
- `api_design_rules.md`
- `security_patterns_rules.md` 
- `performance_optimization_rules.md`
- `testing_strategy_rules.md`
- `code_quality_rules.md`
- `web_scraping_rules.md`
- `ai_workflow_rules.md`

## ✅ Success Criteria for Each Step

**Before moving to next step, verify:**
- [ ] Live rule filtering was performed and documented
- [ ] Only filtered rules were followed during implementation
- [ ] Both automated and manual testing completed successfully
- [ ] Proper commit made with correct message format
- [ ] Step marked as complete in progress tracking

## 🚨 Critical Notes

- **Never skip** the Live Rule Filtering step
- **Never apply all rules** - only cherry-picked ones
- **Always provide testing commands** for verification
- **Always commit** after successful step completion
- **Document context** for seamless AI handoff

## 🚨 Continuous Enforcement Throughout Project

### **Mid-Project Workflow Enforcement**
**The 4-step process applies to EVERY task, not just initial setup:**
- **Feature additions** → Must start with Live Rule Filtering
- **Bug fixes** → Must start with Live Rule Filtering
- **Refactoring** → Must start with Live Rule Filtering
- **Documentation updates** → Must start with Live Rule Filtering
- **Testing improvements** → Must start with Live Rule Filtering

### **Enforcement Checkpoints**
**Before ANY code change:**
- [ ] "Am I starting with Step A: Live Rule Filtering?"
- [ ] "Have I cherry-picked only relevant rules?"
- [ ] "Have I documented which rules I'm ignoring?"

**Before ANY commit:**
- [ ] "Have I run both automated and manual tests?"
- [ ] "Does my commit message follow the git workflow rules?"
- [ ] "Have I updated progress tracking?"

**At ANY AI handoff:**
- [ ] "Is the current step clearly documented?"
- [ ] "Can another AI continue from here?"
- [ ] "Are all context files up to date?"

### **Violation Recovery Process**
**If you realize you've skipped the process:**
1. **Stop immediately** - don't continue with implementation
2. **Acknowledge the skip**: "I need to return to Step A: Live Rule Filtering"
3. **Perform rule filtering** for the current task
4. **Document the filtering** as you should have initially
5. **Continue with proper process** from Step B

### **Progress Tracking Updates**
**After EVERY completed step:**
- Update `memory-bank/progress.md` with completed step
- Update `memory-bank/activeContext.md` with next focus
- Ensure any AI can pick up from this point

### **Quality Assurance Checks**
**Regular project health checks:**
- [ ] Are all recent commits following proper message format?
- [ ] Are all steps documented with rule filtering?
- [ ] Are progress files kept current?
- [ ] Is the codebase following filtered rules consistently?

This process ensures the workflow is maintained throughout the entire project lifecycle, not just at bootstrap.


---