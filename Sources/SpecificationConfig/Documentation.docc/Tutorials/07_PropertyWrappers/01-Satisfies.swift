import SpecificationConfig
import SpecificationCore

final class ContextGate {
    @Satisfies(
        provider: DemoContextProvider.shared,
        using: PredicateSpec<EvaluationContext>.flag("nightTime")
    )
    var canSleepAtNight: Bool
}
