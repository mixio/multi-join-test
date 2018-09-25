#!/bin/sh

# This script should be inside the <project_directory>/Scripts directory.

SCRIPT_NAME="$( basename "$0" )"
#echo "$SCRIPT_NAME"

SCRIPT_DIR="$( dirname "$0" )"
#echo "$SCRIPT_DIR"

PROJECT_PATH="$( dirname "$SCRIPT_DIR" )"
#echo "$PROJECT_PATH"

FORKS_PATH="$( dirname "$PROJECT_PATH" )"
#echo "$FORKS_PATH"

cd "$PROJECT_PATH"

declare -a modules=(
    "SQL vapor-sql-mixio-git"
    "SQLite vapor-sqlite-mixio-git"
    "MySQL vapor-mysql-mixio-git"
    "PostgreSQL vapor-postgresql-mixio-git"
    "Fluent vapor-fluent-mixio-git"
    "FluentSQLite vapor-fluent-sqlite-mixio-git"
    "FluentMySQL vapor-fluent-mysql-mixio-git"
    "FluentPostgreSQL vapor-fluent-postgresql-mixio-git"
    )

read -p "Make DB modules editable? (y/n): " choice
case "$choice" in
  y|Y )
    for i in "${modules[@]}"
    do
        declare -a module=($i)
        module_name="${module[0]}"
        module_path="$FORKS_PATH/${module[1]}"
        echo "Make $module_name editable at $module_path"
        swift package edit "$module" --path "$module_path"
    done
    swift package generate-xcodeproj
    ;;
  n|N )
    for i in "${modules[@]}"
    do
        declare -a module=($i)
        module_name="${module[0]}"
        echo "Make $module_name uneditable"
        swift package unedit "$module_name"
    done
    swift package generate-xcodeproj
    ;;
  * )
    echo "invalid"
    ;;
esac
