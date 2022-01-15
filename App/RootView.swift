//
//  RootView.swift
//  ScreenCast
//
//  Created by Radek Čep on 12.01.2022.
//

import AppCore
import AppView
import ComposableArchitecture
import GoogleCastClient
import SwiftUI

struct RootView: View {
    let store = Store(
        initialState: AppState(),
        reducer: appReducer,
        environment: AppEnvironment(
            googleCastClient: .live
        )
    )

    var body: some View {
        AppView(store: store)
    }
}

#if DEBUG
struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
#endif
