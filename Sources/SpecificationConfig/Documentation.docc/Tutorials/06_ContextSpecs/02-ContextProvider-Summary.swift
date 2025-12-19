func recordReload() {
    reloadCount += 1
}

func toggleNightOverride() {
    if let override = nightOverride {
        nightOverride = override ? false : nil
    } else {
        nightOverride = true
    }
}

private var isNighttime: Bool {
    if let override = nightOverride {
        return override
    }
    let hour = calendar.component(.hour, from: Date())
    return hour < 6 || hour >= 19
}

var contextSummary: String {
    let reloads = reloadCount
    return isNighttime
        ? "Nighttime - Reloads: \(reloads)"
        : "Daytime - Reloads: \(reloads)"
}

var isNightOverrideActive: Bool {
    nightOverride != nil
}
