//
//  GoogleCastClientStub.swift
//  
//
//  Created by Radek Čep on 15.01.2022.
//

import Foundation

#if DEBUG
extension GoogleCastClient {
    public static let stub: Self = .init(
        receivers: { .none }
    )
}
#endif
