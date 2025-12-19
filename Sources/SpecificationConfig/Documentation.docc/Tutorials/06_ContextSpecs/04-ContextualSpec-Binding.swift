contextualValueSpecs: [
    ContextualSpecEntry(description: "Pets sleep at night") { context, isSleeping in
        if context.flag(for: "nightTime") {
            return isSleeping
        }
        return !isSleeping
    },
],
