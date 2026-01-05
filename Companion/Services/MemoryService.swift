//
//  MemoryService.swift
//  Companion
//
//  Service for managing memories and building memory context for conversations
//

import Foundation
import SwiftData

typealias DataModelContext = SwiftData.ModelContext

@Observable
@MainActor
class MemoryService {
    
    // MARK: - State
    
    var isProcessing = false
    var lastError: Error?
    
    // MARK: - Memory CRUD
    
    /// Add explicit memory from user statement
    func addExplicitMemory(
        type: MemoryType,
        content: String,
        category: String? = nil,
        context: DataModelContext
    ) {
        let memory = Memory(type: type, content: content, source: .explicit, category: category)
        context.insert(memory)
        try? context.save()
    }
    
    /// Add inferred memory from conversation analysis
    func addInferredMemory(
        type: MemoryType,
        content: String,
        confidence: Double,
        category: String? = nil,
        sourceSession: ChatSession?,
        sourceMessage: ChatMessage?,
        context: DataModelContext
    ) {
        let memory = Memory(type: type, content: content, source: .inferred, confidence: confidence, category: category)
        memory.sourceSessionId = sourceSession?.id
        memory.sourceMessageId = sourceMessage?.id
        context.insert(memory)
        try? context.save()
    }
    
    /// Update an existing memory
    func updateMemory(
        _ memory: Memory,
        content: String? = nil,
        isActive: Bool? = nil,
        context: DataModelContext
    ) {
        if let content = content {
            memory.content = content
        }
        if let isActive = isActive {
            memory.isActive = isActive
        }
        memory.updatedAt = Date()
        try? context.save()
    }
    
    /// Delete a memory
    func deleteMemory(_ memory: Memory, context: DataModelContext) {
        context.delete(memory)
        try? context.save()
    }
    
    /// Retrieve relevant memories for a conversation context
    func retrieveRelevantMemories(
        query: String,
        types: [MemoryType]? = nil,
        limit: Int = 10,
        context: DataModelContext
    ) -> [Memory] {
        // For now, return recent high-confidence active memories
        // TODO: Implement semantic relevance scoring
        var predicate: Predicate<Memory>
        
        if let types = types {
            predicate = #Predicate { memory in
                memory.isActive && memory.confidence > 0.7 && types.contains(memory.type)
            }
        } else {
            predicate = #Predicate { memory in
                memory.isActive && memory.confidence > 0.7
            }
        }
        
        var descriptor = FetchDescriptor<Memory>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        
        return (try? context.fetch(descriptor)) ?? []
    }
    
    /// Get all memories, optionally filtered by type
    func getAllMemories(
        types: [MemoryType]? = nil,
        includeInactive: Bool = false,
        context: DataModelContext
    ) -> [Memory] {
        var predicate: Predicate<Memory>
        
        if let types = types {
            if includeInactive {
                predicate = #Predicate { memory in
                    types.contains(memory.type)
                }
            } else {
                predicate = #Predicate { memory in
                    memory.isActive && types.contains(memory.type)
                }
            }
        } else {
            if includeInactive {
                predicate = #Predicate { _ in true }
            } else {
                predicate = #Predicate { memory in
                    memory.isActive
                }
            }
        }
        
        let descriptor = FetchDescriptor<Memory>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        return (try? context.fetch(descriptor)) ?? []
    }
    
    /// Mark memory as accessed (for relevance tracking)
    func touchMemory(_ memory: Memory, context: DataModelContext) {
        memory.lastAccessedAt = Date()
        memory.accessCount += 1
        try? context.save()
    }
    
    // MARK: - Memory Context Building
    
    /// Build memory context string for system prompt injection
    func buildMemoryContext(
        for query: String,
        context: DataModelContext
    ) -> String {
        let memories = retrieveRelevantMemories(query: query, limit: 15, context: context)
        
        guard !memories.isEmpty else { return "" }
        
        var sections: [String: [String]] = [:]
        
        for memory in memories {
            let typeKey = memory.type.rawValue.capitalized
            if sections[typeKey] == nil {
                sections[typeKey] = []
            }
            sections[typeKey]?.append("- \(memory.content)")
        }
        
        var result = "\n\n## What you know about the user:\n"
        for (type, items) in sections.sorted(by: { $0.key < $1.key }) {
            result += "\n### \(type):\n"
            result += items.joined(separator: "\n")
        }
        
        return result
    }
    
    // MARK: - Memory Extraction (Placeholder)
    
    /// Extract memories from a completed conversation
    /// TODO: Implement LLM-based extraction in Phase 4
    func extractMemoriesFromSession(
        _ session: ChatSession,
        llmService: LLMService,
        context: DataModelContext
    ) async throws {
        isProcessing = true
        defer { isProcessing = false }
        
        // Build extraction prompt
        let conversationText = session.sortedMessages
            .map { "\($0.isUser ? "User" : "AI"): \($0.content)" }
            .joined(separator: "\n")
        
        let extractionPrompt = """
        Analyze this conversation and extract any new information about the user.
        Return JSON array of memories:
        [{"type": "fact|preference|event|mood|goal|trait|relationship", "content": "...", "confidence": 0.0-1.0}]
        
        Only extract information the user directly stated or strongly implied.
        Be conservative with confidence scores.
        
        Conversation:
        \(conversationText)
        """
        
        // TODO: Call LLM for extraction
        // Parse JSON response
        // Insert inferred memories
        
        print("Memory extraction not yet implemented: \(extractionPrompt)")
    }
}
