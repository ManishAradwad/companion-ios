//
//  DeviceStat.swift
//  Companion
//
//  GPU memory tracking utility adapted from LLMEval
//

import Foundation
import UIKit

#if targetEnvironment(simulator)
// MARK: - Simulator Stub

/// Stub GPU usage for simulator
struct GPUUsageStub {
    let activeMemory: UInt64 = 0
    let cacheMemory: UInt64 = 0
    let peakMemory: UInt64 = 0
}

@Observable
final class DeviceStat: @unchecked Sendable {
    @MainActor
    var gpuUsage: GPUUsageStub? = GPUUsageStub()
    
    init() {}
}

#else
// MARK: - Real Device Implementation

import MLX

@Observable
final class DeviceStat: @unchecked Sendable {

    @MainActor
    var gpuUsage: GPU.Snapshot?

    private let initialGPUSnapshot: GPU.Snapshot?
    private var timer: Timer?
    private var observers: [NSObjectProtocol] = []

    init() {
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" || ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PLAYGROUNDS"] == "1"

        if isPreview {
            self.gpuUsage = nil
            self.initialGPUSnapshot = nil
        } else {
            let snapshot = GPU.snapshot()
            self.gpuUsage = snapshot
            self.initialGPUSnapshot = snapshot
            startTimer()
            setupAppLifecycleObservers()
        }
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
        guard let initial = initialGPUSnapshot else { return }
        let gpuSnapshotDelta = initial.delta(GPU.snapshot())
        DispatchQueue.main.async { [weak self] in
            self?.gpuUsage = gpuSnapshotDelta
        }
    }
}

#endif
