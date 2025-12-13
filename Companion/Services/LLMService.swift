//
//  LLMService.swift
//  Companion
//
//  LLM service adapted from LLMEval with session-aware message handling
//

import AsyncAlgorithms
import Foundation
import MLX
import MLXLLM
import MLXLMCommon
import SwiftData
import SwiftUI

// Type alias to avoid conflict between SwiftData and MLXLMCommon types
typealias LLMModelContext = MLXLMCommon.ModelContext
typealias LLMModelContainer = MLXLMCommon.ModelContainer
typealias DataModelContext = SwiftData.ModelContext

@Observable
@MainActor
class LLMService {
    
    // MARK: - State
    
    var running = false
    var output = ""  // Raw full output
    var thinkingOutput = ""  // Extracted thinking tokens during streaming
    var responseOutput = ""  // Extracted response tokens during streaming
    var isThinking = false  // Whether currently generating thinking tokens
    var modelInfo = ""
    var stat = ""
    var downloadProgress: Double = 0
    
    /// The model configuration to use
    let modelConfiguration = LLMRegistry.qwen3_0_6b_4bit
    
    /// Generation parameters
    let generateParameters = GenerateParameters(maxTokens: 1024, temperature: 0.7)
    let updateInterval = Duration.seconds(0.25)
    
    /// Task responsible for handling the generation process
    var generationTask: Task<Void, Error>?
    
    // MARK: - Load State
    
    enum LoadState {
        case idle
        case loading
        case loaded(LLMModelContainer)
        case failed(Error)
    }
    
    var loadState = LoadState.idle
    
    var isLoaded: Bool {
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" || ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PLAYGROUNDS"] == "1"
        if isPreview { return true }
        if case .loaded = loadState { return true }
        return false
    }

    var isLoading: Bool {
        if case .loading = loadState { return true }
        return false
    }
    
    // MARK: - Model Loading
    
    /// Load and return the model -- can be called multiple times, subsequent calls will
    /// just return the loaded model
    func load() async throws -> LLMModelContainer {
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" || ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PLAYGROUNDS"] == "1"

        if isPreview {
            throw NSError(domain: "Companion", code: -1, userInfo: [NSLocalizedDescriptionKey: "Preview Mode"])
        }

        switch loadState {
        case .idle, .failed:
            loadState = .loading
            
            // Limit the buffer cache
            MLX.GPU.set(cacheLimit: 20 * 1024 * 1024)
            
            do {
                let modelContainer = try await LLMModelFactory.shared.loadContainer(
                    configuration: modelConfiguration
                ) { [modelConfiguration] progress in
                    Task { @MainActor in
                        self.downloadProgress = progress.fractionCompleted
                        self.modelInfo = "Downloading \(modelConfiguration.name): \(Int(progress.fractionCompleted * 100))%"
                    }
                }
                
                let numParams = await modelContainer.perform { context in
                    context.model.numParameters()
                }
                
                self.modelInfo = "Loaded \(modelConfiguration.id). Weights: \(numParams / (1024 * 1024))M"
                loadState = .loaded(modelContainer)
                return modelContainer
            } catch {
                loadState = .failed(error)
                throw error
            }
            
        case .loading:
            // Wait for loading to complete
            throw LLMServiceError.alreadyLoading
            
        case .loaded(let modelContainer):
            return modelContainer
        }
    }
    
    // MARK: - Generation
    
    private func loadSystemPrompt() -> String {
        if let url = Bundle.main.url(forResource: "system_prompt", withExtension: "txt"),
           let prompt = try? String(contentsOf: url, encoding: .utf8) {
            return prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return "You are a helpful AI assistant for journaling. Be supportive, insightful, and help the user reflect on their thoughts and feelings."
    }
    
    /// Generate a response for the given session
    func generate(
        prompt: String,
        session: ChatSession,
        modelContext: DataModelContext
    ) {
        guard !running else { return }

        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" || ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PLAYGROUNDS"] == "1"
        if isPreview {
            generatePreview(prompt: prompt, session: session, modelContext: modelContext)
            return
        }

        generationTask = Task {
            running = true
            output = ""
            thinkingOutput = ""
            responseOutput = ""
            isThinking = false
            
            do {
                // Add user message to session
                let userMessage = ChatMessage(content: prompt, isUser: true, session: session)
                modelContext.insert(userMessage)
                session.lastMessageAt = Date()
                
                // Update session title from first message
                if session.messages.count <= 1 {
                    session.title = String(prompt.prefix(50))
                    if prompt.count > 50 {
                        session.title += "..."
                    }
                }
                
                try modelContext.save()
                
                // Build chat history from session messages
                var chat: [Chat.Message] = [
                    .system(self.loadSystemPrompt())
                ]
                
                for message in session.sortedMessages {
                    if message.isUser {
                        chat.append(.user(message.content))
                    } else {
                        chat.append(.assistant(message.content))
                    }
                }
                
                let userInput = UserInput(chat: chat)
                
                let modelContainer = try await load()
                
                // Each time you generate you will get something new
                MLXRandom.seed(UInt64(Date.timeIntervalSinceReferenceDate * 1000))
                
                try await modelContainer.perform { [weak self] (context: LLMModelContext) -> Void in
                    guard let self = self else { return }
                    
                    let lmInput = try await context.processor.prepare(input: userInput)
                    let stream = try MLXLMCommon.generate(
                        input: lmInput,
                        parameters: self.generateParameters,
                        context: context
                    )
                    
                    // Generate and output in batches
                    for await batch in stream._throttle(
                        for: self.updateInterval,
                        reducing: Generation.collect
                    ) {
                        // Check for cancellation
                        try Task.checkCancellation()
                        
                        let outputChunk = batch.compactMap { $0.chunk }.joined(separator: "")
                        if !outputChunk.isEmpty {
                            Task { @MainActor [outputChunk] in
                                self.output += outputChunk
                                self.updateStreamingState()
                            }
                        }
                        
                        if let completion = batch.compactMap({ $0.info }).first {
                            Task { @MainActor in
                                self.stat = "\(completion.tokensPerSecond) tokens/s"
                            }
                        }
                    }
                }
                
                // Save assistant response to session
                if !output.isEmpty {
                    let (thinking, response) = parseThinkingTokens(output)
                    let assistantMessage = ChatMessage(
                        content: response,
                        isUser: false,
                        thinkingContent: thinking,
                        session: session
                    )
                    modelContext.insert(assistantMessage)
                    session.lastMessageAt = Date()
                    try modelContext.save()
                }
                
            } catch is CancellationError {
                // Handle cancellation gracefully
                if !output.isEmpty {
                    // Save partial response
                    let (thinking, response) = parseThinkingTokens(output)
                    let assistantMessage = ChatMessage(
                        content: response + " [cancelled]",
                        isUser: false,
                        thinkingContent: thinking,
                        session: session
                    )
                    modelContext.insert(assistantMessage)
                    session.lastMessageAt = Date()
                    try? modelContext.save()
                }
            } catch {
                output = "Failed: \(error.localizedDescription)"
            }
            
            running = false
        }
    }
    
    private func generatePreview(prompt: String, session: ChatSession, modelContext: DataModelContext) {
        generationTask = Task {
            running = true
            output = ""
            
            // Add user message
            let userMessage = ChatMessage(content: prompt, isUser: true, session: session)
            modelContext.insert(userMessage)
            session.lastMessageAt = Date()
            if session.messages.count <= 1 {
                session.title = String(prompt.prefix(50))
            }
            try? modelContext.save()
            
            // Simulate streaming
            let response = "This is a simulated response in Xcode Preview mode. The actual MLX model is not loaded to prevent crashes."
            for char in response {
                try? await Task.sleep(nanoseconds: 50_000_000) // 0.05s
                output.append(char)
            }
            
            // Save response
            let assistantMessage = ChatMessage(content: output, isUser: false, session: session)
            modelContext.insert(assistantMessage)
            session.lastMessageAt = Date()
            try? modelContext.save()
            
            running = false
        }
    }
    
    /// Cancel the current generation
    func cancelGeneration() {
        generationTask?.cancel()
        running = false
    }
    
    // MARK: - Streaming State Management
    
    /// Update the streaming state by parsing thinking tokens in real-time
    private func updateStreamingState() {
        let text = output
        
        // Check if we have a <think> tag
        if let thinkStart = text.range(of: "<think>") {
            // Check if thinking is complete (has closing tag)
            if let thinkEnd = text.range(of: "</think>") {
                // Thinking is complete
                isThinking = false
                
                // Extract thinking content
                let thinkingStartIndex = thinkStart.upperBound
                let thinkingEndIndex = thinkEnd.lowerBound
                thinkingOutput = String(text[thinkingStartIndex..<thinkingEndIndex])
                
                // Extract response (everything after </think>)
                let responseStartIndex = thinkEnd.upperBound
                responseOutput = String(text[responseStartIndex...]).trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                // Still thinking (no closing tag yet)
                isThinking = true
                
                // Extract partial thinking content
                let thinkingStartIndex = thinkStart.upperBound
                thinkingOutput = String(text[thinkingStartIndex...])
                responseOutput = ""
            }
        } else {
            // No thinking tags, treat entire output as response
            isThinking = false
            thinkingOutput = ""
            responseOutput = text
        }
    }
    
    // MARK: - Thinking Token Parsing
    
    /// Parse thinking tokens from output, returns (thinkingContent, responseContent)
    private func parseThinkingTokens(_ text: String) -> (thinking: String?, response: String) {
        // Look for <think>...</think> or similar patterns
        let pattern = "<think>(.*?)</think>"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return (nil, text)
        }
        
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        guard let match = matches.first, match.numberOfRanges > 1 else {
            return (nil, text)
        }
        
        let thinkingRange = match.range(at: 1)
        let thinking = nsString.substring(with: thinkingRange)
        
        // Remove the entire <think>...</think> block from response
        let responseText = regex.stringByReplacingMatches(
            in: text,
            options: [],
            range: NSRange(location: 0, length: nsString.length),
            withTemplate: ""
        ).trimmingCharacters(in: .whitespacesAndNewlines)
        
        return (thinking, responseText)
    }
}

// MARK: - Errors

enum LLMServiceError: LocalizedError {
    case alreadyLoading
    case notLoaded
    
    var errorDescription: String? {
        switch self {
        case .alreadyLoading:
            return "Model is already loading"
        case .notLoaded:
            return "Model is not loaded"
        }
    }
}
