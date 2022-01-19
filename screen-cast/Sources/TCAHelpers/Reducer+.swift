//
//  Reducer+.swift
//  
//
//  Created by Radek Čep on 19.01.2022.
//

import ComposableArchitecture
import Foundation

extension Reducer {
    public func onChange<LocalState>(
        of toLocalState: @escaping (State) -> LocalState,
        perform additionalEffects: @escaping (LocalState, inout State, Action, Environment) -> Effect<Action, Never>
    ) -> Self where LocalState: Equatable {

        .init { state, action, environment in
            let previousLocalState = toLocalState(state)
            let effects = self.run(&state, action, environment)
            let localState = toLocalState(state)

            return previousLocalState != localState
                ? .merge(effects, additionalEffects(localState, &state, action, environment))
                : effects
        }
    }
}
