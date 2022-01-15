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
        WithViewStore(store) { viewStore in
            NavigationView {
                List {
                    Section(
                        header: Text("Discovered receivers"),
                        footer: Text("Receivers will pop up automatically as they become available."),
                        content: {
                            ForEach(viewStore.receivers) { receiver in
                                Text(receiver.name)
                            }
                        }
                    )
                }
                .navigationTitle("ScreenCast")
            }
            .navigationViewStyle(.stack)
            .onAppear { viewStore.send(.lifecycleAction(.onAppear)) }
            .onDisappear { viewStore.send(.lifecycleAction(.onDisappear)) }
        }
    }
}

#if DEBUG
struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView(
            store: .init(
                initialState: .init(
                    receivers: [
                        .init(id: "1", name: "Livingroom TV"),
                        .init(id: "2", name: "Bedroom TV"),
                        .init(id: "3", name: "Bathroom TV"),
                        .init(id: "4", name: "Toilet 4K Plasma TV")
                    ]
                ),
                reducer: .empty,
                environment: AppEnvironment(
                    googleCastClient: .stub
                )
            )
        )
    }
}
#endif
