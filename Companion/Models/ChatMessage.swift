//
//  ChatMessage.swift
//  Companion
//
//  Created for Companion journal app
//

import Foundation
import SwiftData

@Model
final class ChatMessage {
    var id: UUID
    var content: String
    var isUser: Bool
    var timestamp: Date
    var thinkingContent: String?
    
    var session: ChatSession?
    
    init(content: String, isUser: Bool, thinkingContent: String? = nil, session: ChatSession? = nil) {
        self.id = UUID()
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
        self.thinkingContent = thinkingContent
        self.session = session
    }
}
