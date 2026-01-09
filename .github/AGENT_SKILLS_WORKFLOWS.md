# Agent Skills Workflow Examples

This document shows practical workflows using Agent Skills for common development scenarios in Companion iOS.

## 🎯 Workflow Overview

```
User Request → AI Agent → Skill Selection → Implementation → Testing → Integration
```

Agent Skills can work independently or be chained together for complex features.

## Example Workflows

### 1. Complete Feature Development

**Scenario**: Add a mood tracking feature

**Workflow**:
```
Step 1: Feature Scaffolding
@feature Create a mood tracking feature:
- Model to store mood entries (emoji, note, timestamp)
- Service to save and retrieve mood history
- View to log mood with emoji picker
- View to display mood history as calendar
- Tests for all components

Step 2: Memory Integration (if personalization needed)
@memory Extract mood patterns:
- Analyze mood trends over time
- Identify triggers (time of day, activities)
- Create insights for user

Step 3: Prompt Enhancement
@prompts Update system prompt:
- Reference mood history in conversations
- Ask about mood changes
- Provide supportive responses based on mood

Step 4: Comprehensive Testing
@test Generate integration tests:
- Test mood logging flow
- Test mood history retrieval
- Test memory pattern extraction
- Test prompt context injection
```

**Result**: Complete mood tracking feature with personalization and AI integration

---

### 2. Memory Feature Development

**Scenario**: Build a user preference learning system

**Workflow**:
```
Step 1: Define Memory Model
@memory Create user preference storage:
- Model for preferences (category, value, confidence, source)
- Service for preference extraction from conversations
- Logic for preference confidence scoring
- Retrieval based on conversation context

Step 2: Feature Integration
@feature Build preference viewer:
- View to display all learned preferences
- Edit/delete preferences
- Category filtering
- Integration with settings

Step 3: Prompt Integration
@prompts Inject preferences into LLM context:
- Update system prompt template
- Add preference context section
- Format preferences for optimal LLM understanding

Step 4: Test Coverage
@test Comprehensive preference tests:
- Test extraction accuracy
- Test confidence scoring
- Test retrieval relevance
- Test UI functionality
```

**Result**: Intelligent preference learning that personalizes AI responses

---

### 3. Conversation Mode Development

**Scenario**: Add a "gratitude journal" mode

**Workflow**:
```
Step 1: Design Prompts
@prompts Create gratitude journal mode:
- Design system prompt for gratitude focus
- Guiding questions for daily gratitude
- Positive reframing techniques
- Gratitude pattern recognition

Step 2: UI Implementation
@feature Build mode selector:
- Mode picker in settings
- Mode indicator in chat
- Mode-specific placeholder text
- Smooth mode transitions

Step 3: Memory Enhancement
@memory Track gratitude patterns:
- Extract gratitude entries
- Identify common themes
- Build gratitude insights over time

Step 4: Testing
@test Test gratitude mode:
- Test prompt behavior
- Test mode switching
- Test memory extraction
- Test insights generation
```

**Result**: Dedicated gratitude journaling mode with pattern insights

---

### 4. Bug Fix with Tests

**Scenario**: Fix a crash in chat history and prevent regression

**Workflow**:
```
Step 1: Reproduce and Diagnose
- Identify the crash (e.g., nil session when displaying history)
- Locate the problematic code

Step 2: Create Failing Test
@test Write test that reproduces the crash:
- Test history view with empty sessions
- Test with deleted sessions
- Test edge cases that trigger crash

Step 3: Fix Implementation
- Fix the bug (e.g., add nil checking, proper guards)
- Follow project patterns

Step 4: Verify Fix
@test Add regression tests:
- Test the fixed behavior
- Test edge cases
- Ensure no other functionality broken
```

**Result**: Bug fixed with tests preventing future regression

---

### 5. Prompt Optimization

**Scenario**: Improve AI response quality based on user feedback

**Workflow**:
```
Step 1: Analyze Current Behavior
- Review example conversations
- Identify issues (too verbose, not empathetic enough, etc.)

Step 2: Redesign Prompt
@prompts Optimize system prompt:
- Reduce verbosity instructions
- Add empathy guidelines
- Improve question quality
- Better response structure

Step 3: Test Changes
- Test with various conversation scenarios
- Compare old vs new responses
- Iterate on prompt design

Step 4: Memory Context
@memory Ensure memory injection works:
- Test that memories enhance responses
- Verify relevant context is used
- Check token usage efficiency

Step 5: Document Changes
- Update prompt documentation
- Add examples of improved responses
- Note any trade-offs
```

**Result**: Improved conversation quality with documented changes

---

## Skill Orchestration Patterns

### Independent Skills
Use single skills for focused tasks:
```
@test Create tests for LLMService
@prompts Fix grammar in system prompt
```

### Sequential Skills
Chain skills for complex workflows:
```
1. @feature Build photo attachment feature
2. @test Generate comprehensive tests
3. @prompts Update prompt to reference photos
```

### Parallel Skills
Multiple related changes:
```
@memory + @prompts: Build memory feature and update prompts simultaneously
@feature + @test: Scaffold feature with tests in same task
```

### Iterative Skills
Refine through multiple passes:
```
1. @prompts Create initial coach mode
2. Test and gather feedback
3. @prompts Refine coach mode based on feedback
4. @test Add tests for edge cases
5. Repeat until satisfied
```

## Tips for Effective Skill Usage

### 1. Be Specific
❌ Bad: `@feature Add tags`
✅ Good: `@feature Add a tagging system with tag creation, tag picker in input, and filter history by tags`

### 2. Provide Context
❌ Bad: `@test Test the service`
✅ Good: `@test Test LLMService streaming generation, cancellation, and error handling with mock dependencies`

### 3. Define Success Criteria
❌ Bad: `@prompts Make it better`
✅ Good: `@prompts Update prompt to ask more open-ended questions and reduce yes/no questions`

### 4. Consider Dependencies
✅ Good: `@feature with tests + @memory integration + @prompts update` (mentions all parts)
✅ Good: Let AI orchestrate: "Build mood tracking with full integration"

### 5. Iterate and Refine
- Start with MVP using skills
- Test and gather feedback
- Refine using same skills iteratively

## Common Patterns

### Pattern 1: Feature → Test → Integrate
```
@feature → @test → @memory/@prompts
```
Standard feature development flow

### Pattern 2: Memory → Prompts
```
@memory → @prompts
```
Memory features need prompt updates to use the stored data

### Pattern 3: Prompts → Test → Iterate
```
@prompts → test manually → @prompts (refine)
```
Prompt engineering is iterative

### Pattern 4: Feature → All Skills
```
@feature → @memory → @prompts → @test
```
Comprehensive feature with full integration

## Real-World Examples

### Example 1: Weekly Reflection Summary
```
@feature Create weekly reflection summary:
- Analyze past 7 days of entries
- Extract key themes and emotions
- Generate summary with insights
- Display in a dedicated view
- Schedule notifications

Then integrate:
@memory Extract long-term patterns from summaries
@prompts Reference patterns in conversations
@test Comprehensive test coverage
```

### Example 2: Smart Question Suggestions
```
@prompts Design question suggestion system:
- Analyze conversation context
- Generate relevant follow-up questions
- Vary question types (reflection, gratitude, planning)

@feature Build question suggestion UI:
- Show 3 suggested questions
- Tap to insert
- Refresh for new suggestions

@test Test suggestion quality and variety
```

### Example 3: Location-Based Memories
```
@memory Implement location memories:
- Store conversation locations
- Retrieve memories by location
- Location-based insights

@feature Add location tagging:
- Request location permission
- Tag conversations with location
- Show memories on map view

@test Test location privacy and accuracy
```

---

## Troubleshooting

**Skill not doing what you expected?**
- Be more specific in your prompt
- Break complex tasks into steps
- Review skill documentation in `.github/skills/`

**Need custom behavior?**
- Skills are guidelines, not restrictions
- Provide detailed custom instructions
- Mix skill patterns with custom requirements

**Multiple skills needed?**
- List all skills needed upfront
- Or describe the full feature and let AI orchestrate

---

For more details on each skill, see [`.github/skills/README.md`](.github/skills/README.md).
