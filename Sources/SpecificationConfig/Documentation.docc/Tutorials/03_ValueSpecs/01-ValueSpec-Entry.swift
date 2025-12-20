import Foundation
import SpecificationConfig

let nonEmptyNameSpec = SpecEntry(description: "Non-empty pet name") { value in
    !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
}
