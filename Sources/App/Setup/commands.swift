//
//  Commands.swift
//  App
//
//  Created by jj on 26/09/2018.
//

import Vapor

public func setupCommands(config: inout CommandConfig) throws {
    config.useFluentCommands()
}
