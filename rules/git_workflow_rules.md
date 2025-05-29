# Git Workflow Rules - Dotidot Web Scraper Challenge

## 🎯 Commit Message Format Checklist

### Before Every Commit
- [ ] **Subject line starts with type**: `feat:`, `fix:`, `test:`, `refactor:`, `docs:`, `chore:`, `security:`
- [ ] **Subject line is 50 characters or less**
- [ ] **Subject line uses imperative mood** ("Add feature" not "Added feature")
- [ ] **Subject line has no period at the end**
- [ ] **Subject line describes WHAT was changed**

### Commit Types to Use
- [ ] `feat:` for new features
- [ ] `fix:` for bug fixes
- [ ] `test:` for adding/updating tests
- [ ] `refactor:` for code cleanup without functionality changes
- [ ] `docs:` for documentation updates
- [ ] `chore:` for setup, dependencies, configuration
- [ ] `security:` for security improvements

### Good Commit Message Examples
- [ ] `feat: add CSS selector extraction service`
- [ ] `fix: handle malformed URLs in validation`
- [ ] `test: add integration tests for /data endpoint`
- [ ] `security: implement rate limiting per IP`
- [ ] `refactor: extract validation into service class`

## 🚨 Feature Branch Enforcement (CRITICAL)

### NEVER Work on Main Branch
- [ ] **NEVER commit directly to main** - Always use feature branches
- [ ] **NEVER push directly to main** - Always create PR for review
- [ ] **ALWAYS create feature branch first** - Before any development work
- [ ] **ALWAYS update from main before branching** - Ensure latest code

### Starting New Feature (MANDATORY)
```bash
# ✅ CORRECT - Always do this
git checkout main
git pull origin main  # Get latest changes
git checkout -b feature/your-feature

# ❌ WRONG - Never do this
# Making changes directly on main
# Committing directly to main
```

### Feature Branch Rules
- [ ] **Create from updated main** - Always pull latest main first
- [ ] **One feature per branch** - Don't mix unrelated changes
- [ ] **Delete after merging** - Keep repository clean
- [ ] **Never rebase public branches** - Only rebase local branches

## 🌿 Branch Naming Checklist

### Before Creating Branch
- [ ] **Branch name format**: `type/short-description`
- [ ] **Use kebab-case** (hyphens, not underscores)
- [ ] **Keep description short** (2-4 words max)
- [ ] **Make purpose clear** from the name

### Branch Name Examples
- [ ] `feature/css-extraction`
- [ ] `fix/url-validation`
- [ ] `test/api-integration`
- [ ] `security/input-sanitization`
- [ ] `refactor/service-objects`
- [ ] `debug/fix-rubocop-rspec-issues` (DEBUGGING_TASK branches)

## 🔧 DEBUGGING_TASK Workflow (MANDATORY)

### When to Create Debug Branch
- [ ] **`bundle exec rubocop -A && bundle exec rspec` fails**
- [ ] **Recurring test failures** (same test fails multiple times)  
- [ ] **RuboCop violations** that auto-fix can't resolve
- [ ] **Integration failures** between services/components
- [ ] **Complex refactoring** that might break existing functionality

### Debug Branch Creation (CRITICAL)
```bash
# ✅ CORRECT - Always create debug branch from feature branch
git checkout feature/your-current-feature
git checkout -b debug/fix-specific-issue

# ❌ WRONG - Never debug directly on feature branch
# Making experimental changes on feature branch
# Committing debug code to feature branch
```

### Debug Branch Rules
- [ ] **ALWAYS branch from feature branch** (not main)
- [ ] **Experiment freely** - debug branch is disposable
- [ ] **Commit frequently** with `debug:` prefix
- [ ] **Document findings** in debug_log.md
- [ ] **NEVER merge debug branch** directly to feature branch

### Debug Branch Cleanup
```bash
# Option 1: Delete after successful debugging
git checkout feature/your-feature
git branch -D debug/fix-specific-issue

# Option 2: Keep for reference (complex issues)
git push origin debug/fix-specific-issue
# Document branch location in DEBUGGING_TASK log
```

### Applying Debug Solutions
- [ ] **Return to clean feature branch** before applying solution
- [ ] **Implement ONLY the final solution** (no debug artifacts)  
- [ ] **Verify complete fix** with all quality checks
- [ ] **Use proper commit messages** (not debug prefixes)

## 🔄 Daily Workflow Checklist

### Starting Work Session
- [ ] `git checkout main` (NEVER work directly on main)
- [ ] `git pull origin main` (Get latest changes)
- [ ] `git checkout -b feature/your-feature` (ALWAYS create feature branch)
- [ ] Verify you're NOT on main: `git branch --show-current`

### During Development
- [ ] **Commit frequently** (every logical change)
- [ ] **Each commit builds successfully**
- [ ] **Each commit passes all tests**
- [ ] **Only commit related changes together**

### Ending Work Session
- [ ] `git push origin your-branch-name` (Push to feature branch)
- [ ] Create Pull Request for review (NEVER push directly to main)
- [ ] Clean up merged branches after PR approval

## 🔀 Pull Request Workflow

### Before Creating PR
- [ ] All tests pass on feature branch
- [ ] Branch is up to date with main
- [ ] Commits follow proper format
- [ ] Code follows project rules

### PR Process
```bash
# Update feature branch with latest main
git checkout main
git pull origin main
git checkout feature/your-feature
git merge main  # or rebase if preferred
git push origin feature/your-feature

# Create PR via GitHub/GitLab UI
# NEVER merge directly without review
```

## ⚡ Quick Commit Process

### Every Single Commit Must
- [ ] **Build without errors**
- [ ] **Pass all existing tests**
- [ ] **Follow commit message format**
- [ ] **Contain only related changes**
- [ ] **Be easily understandable**

### Atomic Commit Examples
```bash
# ✅ GOOD - Each commit is focused
git commit -m "feat: add HTTP client configuration"
git commit -m "feat: implement HTML fetching logic"  
git commit -m "test: add HTTP client tests"

# ❌ BAD - Too much in one commit
git commit -m "feat: add HTTP client, implement fetching, add tests, fix bugs"
```

## 🛡️ Security Checklist

### Never Commit These
- [ ] **No passwords or API keys**
- [ ] **No database credentials**
- [ ] **No secret tokens**
- [ ] **No sensitive configuration**

### Always Check Before Commit
- [ ] `git diff` to review changes
- [ ] No sensitive data in files
- [ ] All files should be committed
- [ ] Commit message makes sense

## 📋 Interview Project Specific

### Professional Standards Checklist
- [ ] **Every commit message follows format**
- [ ] **Commit history tells development story**
- [ ] **No broken commits** (all build and pass tests)
- [ ] **Logical progression** from setup to features
- [ ] **Clean branch management**

### Example Commit Sequence for Interview
```bash
# Setup phase
git commit -m "chore: initialize Rails app with basic gems"
git commit -m "chore: configure database and Redis"

# Security foundation  
git commit -m "feat: add URL validation service"
git commit -m "test: add URL validation tests"

# Core feature
git commit -m "feat: implement CSS selector extraction"
git commit -m "test: add CSS extraction tests"

# API layer
git commit -m "feat: add GET /data endpoint"
git commit -m "test: add API integration tests"
```

## ✅ Pre-Push Final Check

### Before Every Push
- [ ] All tests pass: `rails test` or `rspec`
- [ ] Code builds: `rails server` starts successfully
- [ ] Commit messages follow format
- [ ] Branch name follows format
- [ ] No sensitive data committed
- [ ] Ready for technical review

---

**Simple Rule: If any checkbox is unchecked, fix it before proceeding!**