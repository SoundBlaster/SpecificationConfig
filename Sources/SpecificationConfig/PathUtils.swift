import Foundation

/// Lightweight path helpers shared by the demo app and tests.
public enum PathUtils {
    /// Joins a base path and component using URL normalization.
    public static func joinedPath(_ base: String, _ component: String) -> String {
        URL(fileURLWithPath: base)
            .appendingPathComponent(component)
            .standardizedFileURL
            .path
    }
}
