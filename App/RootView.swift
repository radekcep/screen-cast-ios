//
//  RootView.swift
//  ScreenCast
//
//  Created by Radek Čep on 12.01.2022.
//

import AppCore
import ComposableArchitecture
import GoogleCastClient
import SwiftUI

let client = GoogleCastClient.live

struct RootView: View {
    var body: some View {
        Text("Hello, world!")
            .padding()
            .onAppear {
                _ = client.receivers()
            }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
