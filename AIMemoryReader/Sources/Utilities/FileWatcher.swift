import Foundation

extension Notification.Name {
    static let fileWatcherDidDetectChange = Notification.Name("fileWatcherDidDetectChange")
}

#if os(macOS)
/// Watches a directory tree for .md file changes using FSEvents
final class FileWatcher: Sendable {
    private let path: String
    nonisolated init(path: String) {
        self.path = path
    }

    /// Starts watching. Returns a stream reference that the caller must keep alive.
    /// Call `stopStream(_:)` to stop watching.
    func startStream() -> FSEventStreamRef? {
        // Ensure path has trailing slash for FSEvents directory monitoring
        let watchPath = path.hasSuffix("/") ? path : path + "/"
        let pathsToWatch = [watchPath] as CFArray
        print("[FileWatcher] Starting watch on: \(watchPath)")

        let queue = DispatchQueue(label: "com.aitools.filewatcher", qos: .utility)

        var context = FSEventStreamContext()

        guard let stream = FSEventStreamCreate(
            nil,
            { _, _, numEvents, eventPaths, eventFlags, _ in
                print("[FileWatcher] FSEvent fired: \(numEvents) events")
                if numEvents > 0 {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .fileWatcherDidDetectChange, object: nil)
                    }
                }
            },
            &context,
            pathsToWatch,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.5,
            UInt32(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagNoDefer)
        ) else { return nil }

        FSEventStreamSetDispatchQueue(stream, queue)
        FSEventStreamStart(stream)
        return stream
    }

    static func stopStream(_ stream: FSEventStreamRef) {
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
    }
}
#endif
