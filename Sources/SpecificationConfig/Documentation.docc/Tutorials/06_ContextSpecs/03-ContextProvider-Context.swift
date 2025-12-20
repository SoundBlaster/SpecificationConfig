func currentContext() -> EvaluationContext {
    EvaluationContext(
        currentDate: Date(),
        launchDate: launchDate,
        userData: [:],
        counters: ["reloadCount": reloadCount],
        events: [:],
        flags: [
            "nightTime": isNighttime,
            "sleepOverride": nightOverride ?? false,
        ],
        segments: []
    )
}
