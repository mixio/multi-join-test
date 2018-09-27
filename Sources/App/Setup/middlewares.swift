//
//  middlewares.swift
//  App
//
//  Created by jj on 26/09/2018.
//

import Vapor

public func setupMiddlewares(config: inout MiddlewareConfig) throws {
    // config.use(FileMiddleware.self)  // Serves files from `Public/` directory
    config.use(ErrorMiddleware.self)    // Catches errors and converts to HTTP response
    // Other Middlewares...
}
