//
//  AppView.swift
//  
//
//  Created by Radek Čep on 15.01.2022.
//

import AppCore
import ComposableArchitecture
import Foundation
import GoogleCastClient
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
                                ReceiverCell(store: store, receiver: receiver)
                            }
                        }
                    )
                }
                .navigationTitle("ScreenCast")
            }
            .alert(self.store.scope(state: \.error), dismiss: .dismissError)
            .navigationViewStyle(.stack)
            .onAppear { viewStore.send(.onAppear) }
            .onDisappear { viewStore.send(.onDisappear) }
        }
    }
}

struct ReceiverCell: View {
    let viewStore: ViewStore<AppState, AppAction>
    let receiver: GoogleCastReceiver

    var isSelected: Bool {
        viewStore.userSettings?.selectedReceiverID == receiver.id
    }

    init(store: Store<AppState, AppAction>, receiver: GoogleCastReceiver) {
        self.viewStore = ViewStore(store)
        self.receiver = receiver
    }

    var body: some View {
        Button {
            viewStore.send(
                isSelected ? .deselectGoogleCastReceiver : .select(receiver.id)
            )
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(receiver.name)

                    if isSelected {
                        Text("Your screen will be cast to this device")
                            .font(.system(.footnote))
                    }
                }

                if isSelected {
                    Spacer()
                    Image(systemName: "tv")
                }
            }
        }
        .tint(.black)
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
                    ],
                    userSettings: .init(
                        selectedReceiverID: "2"
                    )
                ),
                reducer: .empty,
                environment: AppEnvironment(
                    googleCastClient: .stub,
                    settingsClient: .stub
                )
            )
        )
    }
}
#endif
