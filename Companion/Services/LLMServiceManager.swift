//
//  LLMServiceManager.swift
//  Companion
//
//  Manages switching between on-device and cloud LLM services
//

import Foundation
import SwiftUI

@Observable
@MainActor
class LLMServiceManager {
    
    enum ServiceType: String, CaseIterable, Identifiable {
        case onDevice = "On-Device"
        case cloud = "Cloud"
        
        var id: String { rawValue }
    }
    
    var currentServiceType: ServiceType = .onDevice {
        didSet {
            switchService()
        }
    }
    
    private(set) var onDeviceService: LLMService
    private(set) var cloudService: CloudLLMService
    
    var currentService: any LLMServiceProtocol {
        switch currentServiceType {
        case .onDevice:
            return onDeviceService
        case .cloud:
            return cloudService
        }
    }
    
    init() {
        self.onDeviceService = LLMService()
        
        // Get API key from environment or UserDefaults
        let apiKey = UserDefaults.standard.string(forKey: "cloudAPIKey") ?? ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
        self.cloudService = CloudLLMService(apiKey: apiKey)
    }
    
    private func switchService() {
        // Cancel any ongoing generation when switching
        onDeviceService.cancelGeneration()
        cloudService.cancelGeneration()
    }
    
    func setCloudAPIKey(_ apiKey: String) {
        UserDefaults.standard.set(apiKey, forKey: "cloudAPIKey")
        cloudService = CloudLLMService(apiKey: apiKey)
    }
}
