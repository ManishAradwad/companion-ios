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
    
    var session: ChatSession?
    
    init(content: String, isUser: Bool, session: ChatSession? = nil) {
        self.id = UUID()
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
        self.session = session
    }
}
