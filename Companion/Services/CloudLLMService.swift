//
//  CloudLLMService.swift
//  Companion
//
//  Cloud-based LLM service using external API
//

import Foundation
import SwiftData
import SwiftUI

@Observable
@MainActor
class CloudLLMService: LLMServiceProtocol {
    
    // MARK: - State
    
    var running = false
    var output = ""
    var modelInfo = ""
    var stat = ""
    
    /// The API endpoint for cloud LLM
    private let apiEndpoint: String
    private let apiKey: String?
    
    /// Task responsible for handling the generation process
    var generationTask: Task<Void, Error>?
    
    // MARK: - Load State
    
    enum LoadState {
        case idle
        case loaded
        case failed(Error)
    }
    
    var loadState = LoadState.idle
    
    var isLoaded: Bool {
        if case .loaded = loadState { return true }
        return false
    }
    
    var isLoading: Bool {
        false // Cloud service doesn't need loading
    }
    
    // MARK: - Initialization
    
    init(apiEndpoint: String = "https://api.openai.com/v1/chat/completions", apiKey: String? = nil) {
        self.apiEndpoint = apiEndpoint
        self.apiKey = apiKey
        self.modelInfo = "Cloud Model (GPT-4)"
    }
    
    // MARK: - Service Methods
    
    func load() async throws {
        // For cloud service, just mark as loaded if API key is available
        if apiKey != nil && !apiKey!.isEmpty {
            loadState = .loaded
            modelInfo = "Cloud Model Ready"
        } else {
            let error = CloudLLMError.noAPIKey
            loadState = .failed(error)
            throw error
        }
    }
    
    // MARK: - Generation
    
    func generate(
        prompt: String,
        session: ChatSession,
        modelContext: DataModelContext
    ) {
        guard !running else { return }
        
        generationTask = Task {
            running = true
            output = ""
            
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
                var messages: [[String: String]] = [
                    ["role": "system", "content": "You are a helpful AI assistant for journaling. Be supportive, insightful, and help the user reflect on their thoughts and feelings."]
                ]
                
                for message in session.sortedMessages {
                    let role = message.isUser ? "user" : "assistant"
                    messages.append(["role": role, "content": message.content])
                }
                
                // Make API request
                let response = try await makeAPIRequest(messages: messages)
                output = response
                
                // Save assistant response to session
                if !output.isEmpty {
                    let assistantMessage = ChatMessage(content: output, isUser: false, session: session)
                    modelContext.insert(assistantMessage)
                    session.lastMessageAt = Date()
                    try modelContext.save()
                }
                
            } catch is CancellationError {
                // Handle cancellation gracefully
                if !output.isEmpty {
                    let assistantMessage = ChatMessage(content: output + " [cancelled]", isUser: false, session: session)
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
    
    /// Cancel the current generation
    func cancelGeneration() {
        generationTask?.cancel()
        running = false
    }
    
    // MARK: - API Request
    
    private func makeAPIRequest(messages: [[String: String]]) async throws -> String {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw CloudLLMError.noAPIKey
        }
        
        guard let url = URL(string: apiEndpoint) else {
            throw CloudLLMError.invalidEndpoint
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "gpt-4",
            "messages": messages,
            "stream": true
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CloudLLMError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw CloudLLMError.httpError(statusCode: httpResponse.statusCode)
        }
        
        var fullResponse = ""
        let startTime = Date()
        var tokenCount = 0
        
        // Process streaming response
        for try await line in asyncBytes.lines {
            // Check for cancellation
            try Task.checkCancellation()
            
            // SSE format: "data: {json}"
            guard line.hasPrefix("data: ") else { continue }
            let data = line.dropFirst(6)
            
            // Check for end of stream
            if data == "[DONE]" { break }
            
            // Parse JSON chunk
            guard let jsonData = data.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let delta = choices.first?["delta"] as? [String: Any],
                  let content = delta["content"] as? String else {
                continue
            }
            
            fullResponse += content
            tokenCount += 1
            
            // Update output in real-time
            Task { @MainActor in
                self.output = fullResponse
                
                // Update stats
                let elapsed = Date().timeIntervalSince(startTime)
                if elapsed > 0 {
                    let tokensPerSecond = Double(tokenCount) / elapsed
                    self.stat = String(format: "%.1f tokens/s", tokensPerSecond)
                }
            }
            
            // Small delay for UI updates
            try await Task.sleep(for: .milliseconds(50))
        }
        
        return fullResponse
    }
}

// MARK: - Errors

enum CloudLLMError: LocalizedError {
    case noAPIKey
    case invalidEndpoint
    case invalidResponse
    case httpError(statusCode: Int)
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No API key provided"
        case .invalidEndpoint:
            return "Invalid API endpoint"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        }
    }
}
