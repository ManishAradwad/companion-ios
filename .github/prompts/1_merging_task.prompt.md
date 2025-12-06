---
name: integrateLLMJournalApp
description: Plan integration of MLX LLM reference code into a SwiftUI journal app with persistence.
argument-hint: Specify the target app structure (e.g., tab-based, navigation-based) and persistence requirements.
---
# Integrate On-Device LLM into iOS Journal App

You are helping integrate an MLX-based LLM reference implementation into a SwiftUI app with SwiftData persistence. The goal is to create a journaling app where users can chat with an on-device AI and view their chat history.

## Architecture Requirements

### Two-Tab Interface
- **Chat Tab** (default): Shows last active session with "New Chat" button, message input, and streaming AI responses
- **History Tab**: Lists all chat sessions grouped by date with swipe-to-delete support

### Data Model
- **ChatSession**: id, createdAt, lastMessageAt, title, messages relationship, computed `isFrozen` property
- **ChatMessage**: id, content, isUser (boolean for role), timestamp, session relationship
- Today's chats are continuable; older chats are frozen/read-only

### LLM Integration
- Preserve lazy model loading pattern (`LoadState` enum with `.idle`/`.loaded`)
- Set GPU cache limit: `MLX.GPU.set(cacheLimit: 20 * 1024 * 1024)`
- Use streaming with throttle: `stream._throttle(for: .seconds(0.25), reducing: Generation.collect)`
- MainActor UI updates: `Task { @MainActor in ... }`
- Support generation cancellation

## Implementation Steps

1. **Add package dependencies**: `MLXLLM`, `MLXLMCommon` from mlx-swift, plus `MarkdownUI` for message rendering

2. **Create entitlements file** with:
   - `com.apple.developer.kernel.increased-memory-limit` (required for LLM weights)
   - `com.apple.security.network.client` (required for HuggingFace downloads)

3. **Create SwiftData models**: `ChatSession` and `ChatMessage` with cascade delete relationship

4. **Integrate DeviceStat**: Copy GPU monitoring utility and inject via `.environment()` in App struct

5. **Create LLMService**: Adapt LLMEvaluator with session-aware message appending and auto-save to SwiftData

6. **Build tab-based UI**: `MainTabView` with `TabView` containing `ChatView` and `HistoryView`

7. **Implement ChatView**: Last active session display, "New Chat" button, message bubbles, input field, streaming generation

8. **Implement HistoryView**: Query all sessions, group by date sections, swipe-to-delete, navigation to continue (today) or view-only (past)

9. **Clean up**: Remove placeholder template files (`Item.swift`, template `ContentView.swift`)

## Key Patterns to Preserve

```swift
// Lazy loading
enum LoadState {
    case idle
    case loaded(ModelContainer)
}

// Streaming with throttle
for await batch in stream._throttle(for: updateInterval, reducing: Generation.collect) {
    let output = batch.compactMap { $0.chunk }.joined()
    Task { @MainActor in self.output += output }
}

// Cancellation support
var generationTask: Task<Void, Error>?
func cancelGeneration() { generationTask?.cancel() }
```

## Considerations
- Handle first-launch model download (~2GB) with progress UI
- Consider offline/error states gracefully
- Strip tool calling features for V1, or keep for future expansion
