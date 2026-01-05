# Memory Layer Documentation

The Memory Layer enables Companion to remember and learn about its users over time, creating a more personalized and context-aware journaling experience.

## Overview

The memory layer consists of:
- **Memory Models**: SwiftData models for storing user information
- **Memory Service**: Business logic for CRUD operations and memory retrieval
- **Memory UI**: Views for browsing and manually adding memories
- **Memory Integration**: Automatic injection of relevant memories into AI conversations

## Architecture

### Core Models

#### Memory (`Memory.swift`)

Stores individual pieces of information about the user:

```swift
@Model
final class Memory {
    var type: MemoryType           // fact, preference, event, mood, goal, trait, relationship
    var content: String            // The actual memory content
    var source: MemorySource       // explicit, inferred, corrected
    var confidence: Double         // 0.0-1.0 for inferred memories
    var isActive: Bool             // Soft delete / completed goals
    var category: String?          // Optional categorization
    // ... timestamps and tracking fields
}
```

**Memory Types:**
- **fact**: Concrete biographical information (e.g., "Lives in Seattle", "Has a dog named Max")
- **preference**: Likes, dislikes, habits (e.g., "Prefers morning workouts", "Loves Italian food")
- **event**: Life happenings and milestones (e.g., "Started new job Dec 2024", "Sister's wedding in March")
- **mood**: Emotional states with context (e.g., "Felt anxious about presentation", "Happy after hiking")
- **goal**: Aspirations and plans (e.g., "Wants to learn piano", "Training for marathon")
- **trait**: Personality characteristics (e.g., "Tends to overthink", "Values honesty")
- **relationship**: People in user's life (e.g., "Mom - close, calls weekly", "Best friend Alex")

**Memory Sources:**
- **explicit**: User directly stated (confidence = 1.0)
- **inferred**: AI extracted from conversation (confidence = 0.0-1.0)
- **corrected**: User corrected AI's inference (confidence = 1.0)

#### PersonalityProfile (`PersonalityProfile.swift`)

Aggregated view of user's personality traits:

```swift
@Model
final class PersonalityProfile {
    // Big Five personality traits (0.0-1.0)
    var openness: Double?
    var conscientiousness: Double?
    var extraversion: Double?
    var agreeableness: Double?
    var neuroticism: Double?
    
    // Custom traits specific to user
    var customTraits: [String: Double]
    
    // LLM-generated summary
    var summary: String?
}
```

### Memory Service

`MemoryService.swift` provides:

**CRUD Operations:**
- `addExplicitMemory()` - Add user-stated memory
- `addInferredMemory()` - Add AI-extracted memory with confidence score
- `updateMemory()` - Update existing memory content or status
- `deleteMemory()` - Remove a memory
- `getAllMemories()` - Fetch all memories with optional filtering

**Memory Retrieval:**
- `retrieveRelevantMemories()` - Get memories for conversation context (filters by confidence > 0.7)
- `buildMemoryContext()` - Format memories for system prompt injection
- `touchMemory()` - Track memory access for relevance scoring

**Memory Extraction (Planned):**
- `extractMemoriesFromSession()` - Analyze conversation to extract new memories (Phase 4)

### Memory UI

#### MemoryListView

- Browse all memories grouped by type
- Filter by memory type with chip buttons
- Search memories by content
- Swipe to delete individual memories
- Displays memory metadata (source, category, date)

#### AddMemoryView

- Manual memory entry form
- Type selector with descriptions
- Optional category field
- Save validation and haptic feedback

### Memory Integration

The LLMService automatically injects relevant memories into conversations:

1. User sends a message
2. `MemoryService.buildMemoryContext()` retrieves relevant memories
3. Memory context is appended to system prompt
4. AI receives both base instructions and user memories
5. AI uses memories naturally in conversation

**Memory Context Format:**
```
## What you know about the user:

### Fact:
- Lives in Seattle
- Has a dog named Max

### Preference:
- Loves hiking in the mountains
- Prefers morning workouts

### Goal:
- Wants to learn piano this year
```

## Usage

### Adding Memories Manually

Users can add memories through the Memories tab:

1. Tap "Memories" tab
2. Tap "+" button
3. Select memory type
4. Enter content
5. Optionally add category
6. Tap "Save"

### Browsing Memories

- View all memories sorted by date
- Filter by type (All, Fact, Preference, Event, etc.)
- Search by content
- Swipe left to delete

### Automatic Memory Context

Memories are automatically injected into conversations:
- High-confidence memories (>0.7) are included
- Most recent/frequently accessed memories prioritized
- AI references memories naturally without listing them

## Privacy & Security

All memories are stored **on-device only**:
- No cloud sync
- SQLite database via SwiftData
- User can view and delete all memories
- No external API calls for memory storage

## Testing

Comprehensive test coverage in `CompanionTests.swift`:

- Memory model tests (creation, types, sources)
- PersonalityProfile tests
- MemoryService CRUD tests
- Memory retrieval and filtering tests
- Memory context building tests
- Integration tests with LLMService

Run tests:
```bash
xcodebuild test -project Companion.xcodeproj -scheme Companion -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Future Enhancements (Phase 4)

### Automatic Memory Extraction

Post-conversation analysis to extract memories:
- Use LLM to analyze conversation transcripts
- Extract facts, preferences, events, moods, etc.
- Assign confidence scores
- Present to user for confirmation

### Personality Profile Aggregation

Build personality insights from memories:
- Compute Big Five traits from conversation patterns
- Generate natural language personality summary
- Update as more memories are collected
- "About You" view for self-reflection

### Advanced Memory Retrieval

Semantic search for relevant memories:
- Vector embeddings for memory content
- Similarity-based retrieval
- Temporal relevance (recent vs. historical)
- Access frequency tracking

### Memory Management

- Bulk edit/delete operations
- Memory export (JSON, Markdown)
- Memory statistics dashboard
- Duplicate detection and merging

## Implementation Checklist

### Phase 1: Foundation ✅
- [x] Memory model with all types
- [x] PersonalityProfile model
- [x] MemoryService with CRUD operations
- [x] Add to ModelContainer schema
- [x] Comprehensive tests

### Phase 2: Memory UI ✅
- [x] MemoryListView for browsing
- [x] AddMemoryView for manual entry
- [x] Memories tab in MainTabView
- [x] UI tests

### Phase 3: Integration ✅
- [x] Memory context injection in LLMService
- [x] Retrieval based on conversation context
- [x] Update system prompt
- [x] Integration tests

### Phase 4: Extraction (Future)
- [ ] Post-conversation memory extraction
- [ ] Extraction prompt engineering
- [ ] Duplicate detection
- [ ] Personality profile aggregation

## Code Examples

### Adding a Memory Programmatically

```swift
let memoryService = MemoryService()
memoryService.addExplicitMemory(
    type: .preference,
    content: "Loves hiking in the mountains",
    category: "Hobbies",
    context: modelContext
)
```

### Retrieving Memories

```swift
let memories = memoryService.retrieveRelevantMemories(
    query: "outdoor activities",
    types: [.preference, .event],
    limit: 10,
    context: modelContext
)
```

### Building Memory Context

```swift
let memoryContext = memoryService.buildMemoryContext(
    for: userMessage,
    context: modelContext
)
// Returns formatted string for system prompt
```

## Contributing

When adding new features to the memory layer:

1. Update relevant models in `Models/`
2. Add business logic to `MemoryService`
3. Create/update UI in `Views/Memory/`
4. Add comprehensive tests to `CompanionTests`
5. Update this documentation

## Questions?

For questions about the memory layer implementation, please open an issue or refer to:
- Agent instructions in `.github/agents/`
- Inline code documentation
- Test cases in `CompanionTests/`
