# AI Workflow Rules - Dotidot Web Scraper

## 🎯 Purpose

These rules govern how AI assistants should approach code development, ensuring clean, maintainable, and efficient implementation practices.

## 🚫 Prohibited Practices

### **0. NO New/Updated/Enhanced File Naming (CRITICAL)**
- [ ] **NEVER create** files with NEW_, UPDATED_, ENHANCED_ prefixes
- [ ] **NEVER create** versioned files (file_v2.md, file_new.md)
- [ ] **ALWAYS edit** the original file directly
- [ ] **ALWAYS modify** existing files instead of creating variants
- [ ] **ALWAYS use** surgical changes to improve existing files

**Examples:**
```
❌ BAD: NEW_PROJECT_BOOTSTRAP.md, UPDATED_README.md, ENHANCED_API_DESIGN.md
✅ GOOD: Edit PROJECT_BOOTSTRAP.md, README.md, API_DESIGN.md directly
```

### **0.1. MANDATORY 4-Step Process Enforcement (CRITICAL)**
- [ ] **NEVER skip** Live Rule Filtering (Step A) for ANY task
- [ ] **NEVER implement** without first cherry-picking relevant rules
- [ ] **NEVER commit** without both automated and manual testing
- [ ] **ALWAYS follow** Filter → Implement → Test → Commit sequence
- [ ] **ALWAYS update** progress tracking after each completed step

**Enforcement Checkpoints:**
- Before ANY implementation: "Have I done Live Rule Filtering?"
- Before ANY commit: "Have I tested both automated and manual?"
- Before moving to next step: "Have I updated progress tracking?"
- At ANY handoff: "Is the process documented for continuation?"

**Violation Prevention:**
```
❌ BAD: Jump straight to implementation without rule filtering
❌ BAD: Commit without running tests
❌ BAD: Skip progress updates
✅ GOOD: Always follow Step A → B → C → D sequence
```

### **1. No One-Time Scripts or Files**
- [ ] **Never create** temporary scripts for one-time tasks
- [ ] **Never create** throwaway .md files or documentation
- [ ] **Never create** quick-and-dirty implementations
- [ ] **Always build** permanent, reusable solutions
- [ ] **Always consider** long-term maintainability

### **2. No One-Time Quick Tests**
- [ ] **Never create** temporary test files or specs
- [ ] **Never write** throwaway testing code
- [ ] **Always write** permanent, meaningful tests
- [ ] **Always integrate** tests into the main test suite
- [ ] **Always follow** established testing patterns

## 🔍 Code Reuse & Analysis

### **3. Always Analyze Existing Code First**
**Before implementing ANY new functionality:**
- [ ] **Scan all existing files** in the project
- [ ] **Identify reusable components** that already exist
- [ ] **Look for similar patterns** that can be extended
- [ ] **Check service objects** for existing functionality
- [ ] **Review helper methods** and utilities already built

**Analysis Questions to Ask:**
- "Do we already have a service that does something similar?"
- "Can we extend an existing class instead of creating a new one?"
- "Is there existing validation logic we can reuse?"
- "Do we have helper methods that solve part of this problem?"

### **4. Surgical Changes Over New Implementations**
- [ ] **Prefer extending** existing classes over creating new ones
- [ ] **Add methods** to existing services when appropriate
- [ ] **Enhance existing validators** instead of building new ones
- [ ] **Modify existing tests** to cover new scenarios
- [ ] **Build upon established patterns** in the codebase

**Example - Good Surgical Change:**
```ruby
# ✅ GOOD - Extend existing service
class UrlValidatorService
  # Existing validation methods...
  
  # Add new validation method
  def self.validate_css_selector_safety(selector)
    # New functionality added to existing service
  end
end

# ❌ BAD - Create new service
class CssSelectorValidatorService
  # Duplicates validation patterns already in UrlValidatorService
end
```

## 🆕 New Code Creation Guidelines

### **5. Only Create New Code When Necessary**
**Create new code ONLY when:**
- [ ] **No existing component** can be adapted or extended
- [ ] **Functionality is completely different** from existing code
- [ ] **Creating new code** results in cleaner architecture
- [ ] **Existing code would become bloated** with new functionality

**Before creating new code, document:**
- Why existing code cannot be used or adapted
- What makes this functionality fundamentally different
- How the new code integrates with existing patterns

### **6. Build Modular, Shareable Components**
**Every new class/module must be:**
- [ ] **Reusable** across multiple implementations
- [ ] **Modular** with clear single responsibility
- [ ] **Configurable** to handle different scenarios
- [ ] **Well-tested** with comprehensive specs
- [ ] **Documented** with clear usage examples

**Design Principles for New Code:**
```ruby
# ✅ GOOD - Modular, reusable service
class DataExtractionService
  def self.call(document, extraction_config)
    new(document, extraction_config).extract
  end
  
  # Can handle CSS selectors, meta tags, attributes, etc.
  # Configurable extraction strategies
  # Reusable across different scraping scenarios
end

# ❌ BAD - Hard-coded, single-purpose
class ProductTitleExtractor
  def self.extract_title_from_alza_page(html)
    # Hard-coded for one specific use case
  end
end
```

### **7. Modular Component Characteristics:**
- [ ] **Strategy pattern** for different behaviors
- [ ] **Dependency injection** for flexibility
- [ ] **Configuration objects** instead of hard-coded values
- [ ] **Chainable interfaces** where appropriate
- [ ] **Error handling** that can be customized

## 🧹 Code Cleanup & Maintenance

### **8. Delete Unused Code After Pivots**
**After any architectural change or pivot:**
- [ ] **Identify orphaned code** that's no longer used
- [ ] **Remove unused classes** and methods
- [ ] **Clean up unused tests** and specs
- [ ] **Remove unused dependencies** from Gemfile
- [ ] **Update documentation** to reflect changes

**Cleanup Checklist:**
- [ ] Search for references to old code before deleting
- [ ] Remove unused imports and requires
- [ ] Clean up unused constants and configuration
- [ ] Remove commented-out code blocks
- [ ] Update related documentation and comments

### **9. Regular Code Health Checks**
**During development, regularly:**
- [ ] **Review class sizes** (keep under 150 lines)
- [ ] **Check method complexity** (keep methods focused)
- [ ] **Look for duplication** and extract common patterns
- [ ] **Verify test coverage** for all new functionality
- [ ] **Ensure consistent naming** across similar components

## 🔄 Implementation Workflow

### **Before Starting Any Task:**
1. **Analyze existing codebase** for reusable components
2. **Document what exists** and what needs to be created
3. **Plan surgical changes** vs new implementations
4. **Design for reusability** if creating new code

### **During Implementation:**
1. **Start with existing code** modifications when possible
2. **Build modular components** when creating new code
3. **Test integration** with existing systems
4. **Document decisions** and rationale

### **After Implementation:**
1. **Review for unused code** and clean up
2. **Verify modularity** and reusability of new components
3. **Check integration** with existing patterns
4. **Update documentation** as needed

## ✅ Code Quality Gates

**Before considering ANY task complete:**
- [ ] **Existing code analyzed** and reused where possible
- [ ] **New code is modular** and reusable
- [ ] **No temporary or throwaway** implementations
- [ ] **Unused code cleaned up** if any pivots occurred
- [ ] **Tests are permanent** and integrated
- [ ] **Documentation updated** to reflect current state
- [ ] **🚨 MANDATORY: 4-Step Process Completed**
  - [ ] Step A: Live Rule Filtering documented
  - [ ] Step B: Implementation follows filtered rules only
  - [ ] Step C: Both automated tests, code quality (RuboCop), and manual testing passed
  - [ ] Step D: Proper commit made and progress updated

## 🚨 Continuous Workflow Enforcement

### **Every Task Validation (MANDATORY)**
**Before starting ANY implementation task:**
1. **Announce the step**: "Starting Step X: [Description]"
2. **Confirm rule filtering**: "Performing Live Rule Filtering for [specific task]"
3. **Document filtered rules**: Show which rules apply and which are ignored
4. **Proceed only after filtering**: Never implement without this step

### **Every Commit Validation (MANDATORY)**
**Before making ANY commit:**
1. **Verify automated tests**: All RSpec/tests must pass
2. **Verify code quality**: RuboCop must pass with no offenses
3. **Verify manual tests**: Console/curl verification completed
4. **Verify deliverable**: Step objective achieved
5. **Update progress**: memory-bank/progress.md and activeContext.md updated

### **Every Handoff Validation (MANDATORY)**
**When ANY AI takes over or hands off:**
1. **Read progress.md**: Understand current status
2. **Read activeContext.md**: Understand immediate focus
3. **Follow 4-step process**: Never skip rule filtering
4. **Update context files**: Keep continuity information current

### **Workflow Violation Detection**
**Warning Signs of Process Violations:**
- Implementation started without mentioning rule filtering
- Commits made without testing commands provided
- Commits made without RuboCop validation
- Progress files not updated after task completion
- Rules applied wholesale instead of cherry-picked
- Temporary or throwaway code created

### **Self-Correction Protocol**
**If workflow violation detected:**
1. **Stop immediately** and acknowledge the violation
2. **Return to proper step** (usually Step A: Rule Filtering)
3. **Document the correction** for future reference
4. **Continue with proper process** from corrected point

## 🎯 Success Metrics

**Healthy Codebase Indicators:**
- **High code reuse** - similar functionality uses same components
- **Modular architecture** - components can be easily recombined
- **Clean abstractions** - interfaces are clear and well-defined
- **No dead code** - every class and method serves a purpose
- **Consistent patterns** - similar problems solved in similar ways

**Warning Signs:**
- Multiple classes doing similar things differently
- Hard-coded solutions that can't be reused
- Accumulation of temporary or quick-fix code
- Tests that duplicate existing test patterns
- Documentation that doesn't match actual implementation

---

**Remember: Code is written once but read many times. Always optimize for maintainability, reusability, and clarity over quick implementation.**