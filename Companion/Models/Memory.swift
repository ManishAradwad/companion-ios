//
//  Memory.swift
//  Companion
//
//  Memory model for storing user information learned over time
//

import Foundation
import SwiftData

enum MemoryType: String, Codable, CaseIterable {
    case fact
    case preference
    case event
    case mood
    case goal
    case trait
    case relationship
}

enum MemorySource: String, Codable {
    case explicit      // User directly stated
    case inferred      // AI extracted from conversation
    case corrected     // User corrected AI's inference
}

@Model
final class Memory {
    var id: UUID
    var type: MemoryType
    var content: String
    var source: MemorySource
    var confidence: Double      // 0.0-1.0 for inferred memories
    var createdAt: Date
    var updatedAt: Date
    var lastAccessedAt: Date?   // For relevance scoring
    var accessCount: Int        // How often surfaced
    var isActive: Bool          // Soft delete / completed goals
    
    // Optional metadata
    var category: String?       // Sub-categorization
    var relatedMemoryIds: [UUID]?  // Linked memories
    
    // Source tracking
    var sourceSessionId: UUID?  // Which conversation
    var sourceMessageId: UUID?  // Which message
    
    init(
        type: MemoryType,
        content: String,
        source: MemorySource = .explicit,
        confidence: Double = 1.0,
        category: String? = nil
    ) {
        self.id = UUID()
        self.type = type
        self.content = content
        self.source = source
        self.confidence = confidence
        self.createdAt = Date()
        self.updatedAt = Date()
        self.accessCount = 0
        self.isActive = true
        self.category = category
    }
}
