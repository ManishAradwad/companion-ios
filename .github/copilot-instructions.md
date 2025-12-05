# Companion iOS - AI Coding Agent Guidelines

## Project Overview
**Companion** is an early-stage iOS app for on-device AI-powered journaling/assistant features, built with SwiftUI and MLX for local LLM inference. The codebase is in a **transitional state**:

- `Companion/Companion/` — Main app scaffold (Xcode template, SwiftData-based `Item.swift`)
- `Companion/Companion/LLMEval/` — **Unmerged reference code** from Apple's [mlx-swift-examples](https://github.com/ml-explore/mlx-swift-examples). This will be integrated into Companion's architecture.

## Current File Roles
| File | Status | Purpose |
|------|--------|---------|
| `CompanionApp.swift` | Active | App entry point with SwiftData `ModelContainer` |
| `ContentView.swift` (root) | Placeholder | Xcode template list view—will become chat UI |
| `Item.swift` | Placeholder | SwiftData model for timestamps—will be replaced |
| `LLMEval/ContentView.swift` | Reference | Full MLX streaming UI implementation |
| `LLMEval/LLMEvalApp.swift` | Reference | Shows `DeviceStat` environment injection |
| `LLMEval/ViewModels/DeviceStat.swift` | Reusable | GPU memory tracking—integrate directly |

## MLX LLM Patterns (from LLMEval)
### Model Loading
```swift
let modelConfiguration = LLMRegistry.qwen3_1_7b_4bit  // or other models from MLXLLM
MLX.GPU.set(cacheLimit: 20 * 1024 * 1024)  // Limit buffer cache
let container = try await LLMModelFactory.shared.loadContainer(configuration: modelConfiguration)
```

### Streaming Generation
```swift
let stream = try MLXLMCommon.generate(input: lmInput, parameters: generateParameters, context: context)
for await batch in stream._throttle(for: .seconds(0.25), reducing: Generation.collect) {
    let output = batch.compactMap { $0.chunk }.joined()  // Token chunks
    // Update UI on MainActor
}
```

### SwiftUI State Management
- Use `@Observable` class (`LLMEvaluator`) for model state
- Bind prompt input with `Bindable(llm).prompt`
- Use `@Environment(DeviceStat.self)` for GPU stats

## Required Entitlements
Copy from `LLMEval/LLMEval.entitlements` to Companion target:
- `com.apple.developer.kernel.increased-memory-limit` — Required for LLM weights
- `com.apple.security.network.client` — For HuggingFace model downloads

## Build & Debug Notes
- **Release builds** recommended for large models (avoids stack overflow in Debug)
- Disable debugger for performance: `cmd+opt+r` → uncheck "Debug Executable"
- Set Team in Signing & Capabilities before device builds

## Swift Package Dependencies
- `mlx-swift` (0.29.x) — MLX framework, MLXLLM, MLXLMCommon
- `swift-async-algorithms` — For `_throttle` on async streams

## Integration Roadmap
1. Add MLXLLM/MLXLMCommon packages to Companion target
2. Copy `DeviceStat.swift` → `Companion/ViewModels/`
3. Create `LLMService.swift` wrapping `LLMEvaluator` logic
4. Replace placeholder `ContentView` with chat interface using streaming patterns
5. Add entitlements from LLMEval to Companion target

## Code Style
- SwiftUI with `@Observable` (not ObservableObject)
- Async/await for all LLM operations
- MainActor for UI state updates during streaming
- Prefer `Task { @MainActor in }` for cross-actor updates
