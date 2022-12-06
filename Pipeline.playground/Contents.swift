import Foundation

//
//  Pipeline.swift
//  CreateSwiftly
//
//  Created by Larissa Perara on 12/6/22.
//

// MARK: - GCD

class GCDConsumer {
    let pipeline = GCDPipeline.shared
    
    func executeTask(task: @escaping () -> Void) {
        pipeline.execute(task: task)
    }
    
    func checkTaskStatus() {
        return pipeline.printTasksCompleted()
    }
}

// MARK: Pipeline Definition

/// A class that takes multiple tasks and completes them in parallel in the background.
final class GCDPipeline {
    
    static let shared = GCDPipeline()
    
    // We know that all the work being called for this example should execute on the background thread.
    // Note: qos is quality of service i.e. .userInteractive, .userInitiated, .utility, .background, .default, .unspecified
    let concurrentQueue = DispatchQueue.global(qos: .background)
    
    // TODO: maybe this should be encapsulated into its own object. Is there a structure for a mutex counter?
    /// We only want one person at a time to access the count
    let completedCountSemaphore = DispatchSemaphore(value: 1)
    
    // We cannot use didSet because the threading issue stems from accessing a variable from multiple threads, not changing it, we want to make sure the instance is the correct one when it is change.
    var completedCount: Int  = 0
    
    public func execute(task: @escaping () -> Void) {
        // This is distributing the work across multiple threads
        // executing the information in order within the completion handler block.
        concurrentQueue.async { [weak self] in
            guard let strongSelf = self else {
                // TODO: When would this happen? What logging would need to be done.
                return
            }
            
            task()
            strongSelf.taskCompleted()
        }
    }
    
    private func taskCompleted() {
        completedCountSemaphore.wait()
        completedCount = completedCount + 1
        completedCountSemaphore.signal()
    }
    
    private func getCompletedTaskCount() -> Int {
        let count: Int
        completedCountSemaphore.wait()
        count = completedCount
        completedCountSemaphore.signal()
        return count
    }
    
    public func printTasksCompleted() {
        print("Completed \(getCompletedTaskCount())")
    }
}

// MARK: - Async Await
// TODO: Implement this
