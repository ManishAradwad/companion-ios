//
//  DeviceStat.swift
//  Companion
//
//  GPU memory tracking utility adapted from LLMEval
//

import Foundation
import MLX
import UIKit

@Observable
final class DeviceStat: @unchecked Sendable {

    @MainActor
    var gpuUsage = GPU.snapshot()

    private let initialGPUSnapshot = GPU.snapshot()
    private var timer: Timer?
    private var observers: [NSObjectProtocol] = []

    init() {
        startTimer()
        setupAppLifecycleObservers()
    }

    deinit {
        timer?.invalidate()
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }
    
    // MARK: - Timer Management
    
    private func startTimer() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateGPUUsages()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func setupAppLifecycleObservers() {
        // Pause timer when app goes to background to save resources
        let backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.stopTimer()
        }
        
        // Resume timer when app becomes active
        let foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.startTimer()
            self?.updateGPUUsages() // Immediate update
        }
        
        observers = [backgroundObserver, foregroundObserver]
    }

    private func updateGPUUsages() {
        let gpuSnapshotDelta = initialGPUSnapshot.delta(GPU.snapshot())
        DispatchQueue.main.async { [weak self] in
            self?.gpuUsage = gpuSnapshotDelta
        }
    }
}
