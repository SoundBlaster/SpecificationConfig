import SpecificationConfig
import SpecificationCore

final class SleepLabeler {
    @Decides(
        provider: DemoContextProvider.shared,
        firstMatch: [
            (PredicateSpec<EvaluationContext>.flag("sleepOverride"), "Forced Sleep"),
            (PredicateSpec<EvaluationContext>.flag("nightTime"), "Sleepy"),
        ],
        fallback: "Awake"
    )
    var sleepLabel: String

    func resolvedLabel() -> (String, String?) {
        (sleepLabel, $sleepLabel)
    }
}
