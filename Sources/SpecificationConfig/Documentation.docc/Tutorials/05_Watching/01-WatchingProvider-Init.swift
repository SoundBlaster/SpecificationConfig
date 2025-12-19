import Configuration
import Foundation

final class WatchingProvider {
    private let provider: ReloadingFileProvider<JSONSnapshot>

    init(configFileURL: URL) {
        provider = ReloadingFileProvider<JSONSnapshot>(fileURL: configFileURL) { url in
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(JSONSnapshot.self, from: data)
        }
    }
}
