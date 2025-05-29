# AI Handoff Instructions - Dotidot Web Scraper

## 🎯 **For AI Assistants Picking Up This Work**

This document provides complete instructions for any AI assistant to seamlessly continue the Dotidot Web Scraper project without human intervention.

---

## 📋 **STEP 1: IMMEDIATE ACTIONS (Required)**

### **A. Read This First**
You are taking over a **Ruby on Rails REST API web scraper project** for a technical interview challenge. The project follows strict professional development practices with comprehensive rules and testing.

### **B. Understand Current Status**
1. **Read**: `memory-bank/progress.md` - Shows exactly where we left off
2. **Read**: `memory-bank/activeContext.md` - Current focus and immediate next steps  
3. **Read**: `PROJECT_PLAN.md` - Complete 28-step implementation plan
4. **Find**: Current step number and what needs to be done next

### **C. Locate All Context Files**
**Base Directory**: `/Users/freebeiro/Documents/fcr/claudefiles/dotidot-scraper/`

**Essential Files to Reference:**
- `procedures/PROJECT_PLAN.md` - Step-by-step implementation guide
- `procedures/LIVE_RULE_FILTERING_PROCESS.md` - Mandatory process for every step
- `procedures/UNPLANNED_TASK_PROCESS.md` - How to handle unplanned work
- `memory-bank/progress.md` - Current status and completed work
- `memory-bank/activeContext.md` - Immediate focus and context

---

## 🔄 **STEP 2: MANDATORY PROCESS (NEVER SKIP)**

### **Every Single Task Must Follow This 4-Step Process:**

#### **📋 Step A: Live Rule Filtering (MANDATORY)**
**Before ANY implementation:**
1. **Scan these 8 rule files** and cherry-pick only relevant rules for current task:
   - `rules/git_workflow_rules.md`
   - `rules/api_design_rules.md`
   - `rules/security_patterns_rules.md`
   - `rules/performance_optimization_rules.md`
   - `rules/testing_strategy_rules.md`
   - `rules/code_quality_rules.md`
   - `rules/web_scraping_rules.md`
   - `rules/ai_workflow_rules.md`

2. **Create focused mini-checklist** (3-8 items max) of ONLY relevant rules
3. **Document which rules ignored** and why
4. **Never apply all rules** - only cherry-picked ones
5. **IMPORTANT**: Do NOT create separate files for filtered rules - perform filtering inline and document in progress.md after completion

#### **🛠️ Step B: Implementation**
- Follow ONLY the filtered rules from Step A
- Focus on specific deliverable for this step
- Keep implementation simple and targeted

#### **🧪 Step C: Testing & Validation**
**BOTH required:**
- **Automated Tests**: RSpec, database tests, etc.
- **Manual Tests**: Rails console, curl commands, server startup
- **Provide exact commands** for human to verify

#### **📝 Step D: Documentation & Commit**
- Document what was accomplished
- Create proper Git commit with correct format
- Update progress tracking
- Mark step as complete

---

## 🚨 **STEP 3: CRITICAL REQUIREMENTS (NON-NEGOTIABLE)**

### **AI Workflow Rules (Must Follow):**
- **NO temporary scripts** or throwaway files
- **NO one-time quick fixes** or temporary code
- **ALWAYS check existing code first** before creating new
- **Prefer extending existing code** over creating new
- **Build modular, reusable components** only
- **Delete unused code** after any pivots
- **Every step must be testable** (automated + manual)

### **MANDATORY 4-Step Process (NEVER SKIP):**
**This applies to EVERY task throughout the entire project:**
- **Feature additions** → Start with Live Rule Filtering
- **Bug fixes** → Start with Live Rule Filtering  
- **Refactoring** → Start with Live Rule Filtering
- **Documentation** → Start with Live Rule Filtering
- **ANY code change** → Start with Live Rule Filtering

### **Continuous Enforcement Checkpoints:**
**Before ANY task:** "Have I done Live Rule Filtering?"
**Before ANY commit:** "Have I tested automated + manual?"
**Before next step:** "Have I updated progress tracking?"
**At ANY handoff:** "Can another AI continue from here?"

### **Quality Gates (Every Step):**
- [ ] Code follows filtered rules only
- [ ] Both automated and manual tests pass
- [ ] Proper Git commit message format
- [ ] Step deliverable achieved
- [ ] Progress tracking updated
- [ ] Context files maintained for AI continuity

---

## 📖 **STEP 4: HOW TO RESUME WORK**

### **A. Determine Current Step**
1. **Check**: `memory-bank/progress.md` for last completed step
2. **Find**: Next step number in `PROJECT_PLAN.md`
3. **Read**: Step details and requirements

### **B. Execute Current Step**
1. **Announce**: "Starting Step X: [Description]"
2. **Live Rule Filter**: Cherry-pick relevant rules from 8 rule files
3. **Implement**: Following only filtered rules
4. **Test**: Both automated and manual verification
5. **Commit**: Proper Git commit message
6. **Update**: Progress tracking files

### **C. Continue Sequential Steps**
- Follow PROJECT_PLAN.md step by step
- Never skip steps or jump ahead
- Each step builds on previous ones
- Maintain quality gates throughout

---

## 🎯 **STEP 5: PROJECT CONTEXT UNDERSTANDING**

### **What We're Building:**
- **Ruby on Rails 7.1 REST API** for web scraping
- **Technical interview challenge** for Dotidot company
- **Production-quality code** with enterprise standards
- **Security-first approach** with SSRF protection
- **Performance optimization** with Redis caching
- **Comprehensive testing** with RSpec

### **Challenge Requirements:**
1. **GET/POST /data endpoints** accepting URL and CSS selectors
2. **Meta tag extraction** capability
3. **Intelligent caching** for performance
4. **Security measures** (rate limiting, input validation)

### **Success Criteria:**
- Demonstrate Rails expertise
- Show security consciousness  
- Exhibit performance awareness
- Professional development practices
- >90% test coverage

---

## 🔧 **STEP 6: TECHNICAL STACK**

**Core Technologies:**
- Rails 7.1 (API mode)
- PostgreSQL database
- Redis (caching + Sidekiq)
- RSpec + FactoryBot (testing)
- Nokogiri (HTML parsing)
- HTTP.rb (HTTP client)

**Architecture Pattern:**
- Service objects for business logic
- Thin controllers
- Custom exception hierarchy
- Security-first validation
- Comprehensive error handling

---

## 📋 **STEP 7: READY CHECKLIST**

**Before starting any work, confirm:**
- [ ] Read `memory-bank/progress.md` for current status
- [ ] Found next step in `PROJECT_PLAN.md`
- [ ] Understand the 4-step process (Filter → Implement → Test → Commit)
- [ ] Located all 8 rule files for filtering
- [ ] Ready to follow AI workflow rules (no throwaway code)
- [ ] Can provide both automated and manual testing
- [ ] Will update progress tracking after completion

---

## 🚀 **STEP 8: EXAMPLE HANDOFF PROCESS**

### **Sample AI Response When Taking Over:**

```
I'm taking over the Dotidot Web Scraper project. Let me check the current status:

[Reading memory-bank/progress.md...]
[Reading memory-bank/activeContext.md...]

Current Status: Step 1 - Rails Application Setup is next
Project: 0% complete, bootstrap finished

Starting Step 1: Rails Application Setup

Step 1A: Live Rule Filtering (MANDATORY)
[Scanning 8 rule files for Rails setup relevance...]

Relevant Rules for Rails Setup:
- Git Workflow: Proper commit message format
- Code Quality: Rails file structure conventions  
- Testing Strategy: RSpec configuration
- AI Workflow: Check existing code first (none exists yet)

Ignored Rules: API design (no endpoints yet), Security (no input yet), Web scraping (no scraping yet)

Filtered Checklist:
- [ ] Use commit format: "chore: initialize Rails API application with RSpec"
- [ ] Follow Rails conventions for file structure
- [ ] Configure RSpec properly
- [ ] Ensure app starts successfully

Step 1B: Implementation
[Proceeding with Rails setup...]

Step 1C: Testing & Validation
Automated Tests:
- bundle exec rspec (should run without errors)
- rails db:create RAILS_ENV=test

Manual Tests:  
- rails server (should start on port 3000)
- rails console (should load without errors)

Testing Commands:
```bash
# Test server
rails server

# Test database  
rails db:create RAILS_ENV=test

# Test RSpec
bundle exec rspec
```

Step 1D: Documentation & Commit
[Creating commit and updating progress...]

Ready for Step 2: Essential Gems Setup
```

---

## 🎊 **READY TO WORK**

**The project is fully documented and ready for seamless AI handoff.**

**Any AI assistant can now:**
1. **Read these instructions**
2. **Check current progress** 
3. **Continue from exact stopping point**
4. **Follow established quality standards**
5. **Build production-ready Rails application**

**No human intervention needed - just follow the process!** 🚀

---

## 🔗 **Quick Reference**

**Base Directory**: `/Users/freebeiro/Documents/fcr/claudefiles/dotidot-scraper/`
**Process File**: `procedures/LIVE_RULE_FILTERING_PROCESS.md`
**Implementation Plan**: `procedures/PROJECT_PLAN.md`
**Current Status**: `memory-bank/progress.md`
**Active Context**: `memory-bank/activeContext.md`

**Remember**: Always follow the 4-step process, never skip rule filtering, always test both automated and manual, always commit properly.


---