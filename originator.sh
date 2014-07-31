#!/bin/bash
cd "$(dirname "$0")"

# Imports
. ./lib/logger.bash
. ./config/database.bash


migrate_make() {
    if [[ -z "$1" ]]; then
        log_error "migrate:make requires a second parameter for the name of the migration."
    else
        log_alert "Creating the migrate and revert files"
        epochTime=$(date +%s)
        
        migrate=./migrations/migrate/"$epochTime"_migrate_$1.sql
        revert=./migrations/revert/"$epochTime"_revert_$1.sql

        touch "$migrate"
        log_success "Migrate file located at $migrate"
        touch "$revert" 
        log_success "Revert file located at $revert"
    fi
}

migrate_rollback() {
    echo "TODO Rollback The Last Migration Operation"
}

migrate_reset() {
    echo "TODO Rollback all migrations"
}

migrate_refresh() {
    echo "TODO Rollback all migrations and run them all again"
}

migrate() {
    echo "TODO Running All Outstanding Migrations"
}

determine_action() {
    if   [ "$1" = "migrate:make" ]; then
        migrate_make $2
    elif [ "$1" = "migrate:rollback" ]; then
        migrate_rollback
    elif [ "$1" = "migrate:reset" ]; then
        migrate_reset
    elif [ "$1" = "migrate:refresh" ]; then
        migrate_refresh
    elif [ "$1" = "migrate" ]; then
        migrate
    else
        log_error "Action invalid"
    fi
}

determine_action $1 $2
