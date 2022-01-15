//
//  AppView.swift
//  
//
//  Created by Radek Čep on 15.01.2022.
//

import AppCore
import ComposableArchitecture
import Foundation
import SwiftUI

public struct AppView: View {
    let store: Store<AppState, AppAction>

    public init(store: Store<AppState, AppAction>) {
        self.store = store
    }

    public var body: some View {
        Text("Hello, world!")
            .padding()
    }
}

#if DEBUG
struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView(
            store: .init(
                initialState: .init(),
                reducer: .empty,
                environment: AppEnvironment(
                    googleCastClient: .stub
                )
            )
        )
    }
}
#endif
