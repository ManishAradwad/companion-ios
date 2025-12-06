//
//  ChatSession.swift
//  Companion
//
//  Created for Companion journal app
//

import Foundation
import SwiftData

@Model
final class ChatSession {
    var id: UUID
    var createdAt: Date
    var lastMessageAt: Date
    var title: String
    
    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.session)
    var messages: [ChatMessage] = []
    
    /// A session is frozen (read-only) if it wasn't created today
    var isFrozen: Bool {
        !Calendar.current.isDateInToday(createdAt)
    }
    
    init(title: String = "New Chat") {
        self.id = UUID()
        self.createdAt = Date()
        self.lastMessageAt = Date()
        self.title = title
    }
    
    /// Get messages sorted by timestamp
    var sortedMessages: [ChatMessage] {
        messages.sorted { $0.timestamp < $1.timestamp }
    }
    
    /// Update the title based on the first user message
    func updateTitleFromFirstMessage() {
        if let firstUserMessage = messages.first(where: { $0.isUser }) {
            let content = firstUserMessage.content
            // Take first 50 characters or first sentence
            let truncated = String(content.prefix(50))
            if truncated.count < content.count {
                title = truncated + "..."
            } else {
                title = truncated
            }
        }
    }
}
