//
//  RequestDelegate.swift
//  
//
//  Created by Radek Čep on 23.03.2022.
//

import Foundation
import GoogleCast

class RequestDelegate: NSObject, GCKRequestDelegate {
    private let _requestDidComplete: (GCKRequest) -> Void
    private let _requestDidFailWithError: (GCKRequest, GCKError) -> Void
    private let _requestDidAbortWithAbortReason: (GCKRequest, GCKRequestAbortReason) -> Void

    init(
        requestDidComplete: @escaping (GCKRequest) -> Void,
        requestDidFailWithError: @escaping (GCKRequest, GCKError) -> Void,
        requestDidAbortWithAbortReason: @escaping (GCKRequest, GCKRequestAbortReason) -> Void
    ) {
        _requestDidComplete = requestDidComplete
        _requestDidFailWithError = requestDidFailWithError
        _requestDidAbortWithAbortReason = requestDidAbortWithAbortReason

        super.init()
    }

    func requestDidComplete(_ request: GCKRequest) {
        _requestDidComplete(request)
    }

    func request(_ request: GCKRequest, didFailWithError error: GCKError) {
        _requestDidFailWithError(request, error)
    }

    func request(_ request: GCKRequest, didAbortWith abortReason: GCKRequestAbortReason) {
        _requestDidAbortWithAbortReason(request, abortReason)
    }
}
