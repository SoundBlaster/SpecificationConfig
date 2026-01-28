import SpecificationConfig
import SpecificationCore

/// Derived demo state powered by SpecificationCore property wrappers.
final class DemoDerivedState {
    @Satisfies(
        provider: DemoContextProvider.shared,
        using: PredicateSpec<EvaluationContext>.flag("nightTime")
    )
    private var isNightTime: Bool

    @Decides(
        provider: DemoContextProvider.shared,
        firstMatch: [
            (
                DemoDerivedState.sleepOverrideActive
                    .and(DemoDerivedState.sleepOverrideSleeping),
                "Forced Sleep"
            ),
            (
                DemoDerivedState.sleepOverrideActive
                    .and(DemoDerivedState.sleepOverrideSleeping.not()),
                "Forced Awake"
            ),
            (PredicateSpec<EvaluationContext>.flag("nightTime"), "Sleepy"),
        ],
        fallback: "Awake"
    )
    private var sleepLabel: String

    var isNightTimeDerived: Bool {
        isNightTime
    }

    var sleepLabelDerived: String {
        sleepLabel
    }

    var sleepLabelMatch: String? {
        $sleepLabel
    }

    private static let sleepOverrideActive =
        PredicateSpec<EvaluationContext>.flag("sleepOverrideActive")
    private static let sleepOverrideSleeping =
        PredicateSpec<EvaluationContext>.flag("sleepOverrideSleeping")
}
