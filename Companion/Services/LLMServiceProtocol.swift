//
//  LLMServiceProtocol.swift
//  Companion
//
//  Protocol for LLM service implementations (on-device and cloud)
//

import Foundation
import SwiftData

/// Protocol defining the interface for LLM services
@MainActor
protocol LLMServiceProtocol: AnyObject, Observable {
    var running: Bool { get set }
    var output: String { get set }
    var modelInfo: String { get set }
    var stat: String { get set }
    var isLoaded: Bool { get }
    var isLoading: Bool { get }
    
    func load() async throws
    func generate(prompt: String, session: ChatSession, modelContext: DataModelContext)
    func cancelGeneration()
}
