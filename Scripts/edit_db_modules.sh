#!/bin/sh

swift package edit SQL --branch dev
swift package edit SQLite --branch dev
swift package edit MySQL --branch dev
swift package edit PostgreSQL --branch dev
swift package edit Fluent --branch dev
swift package edit FluentSQLite --branch dev
swift package edit FluentMySQL --branch dev
swift package edit FluentPostgreSQL --branch dev
swift package edit DatabaseKit --branch dev

swift package generate-xcodeproj