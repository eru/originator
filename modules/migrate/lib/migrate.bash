#!/bin/bash

#################################################
# Creates a new migration
#
# @param $1: The name of the migration
#################################################
migrate_make() {
    if [[ -z "$1" ]]; then
        log_error "migrate:make requires a second parameter for the name of the migration."
    else
        epoch_time=$(date +%s)
        migration_name="$epoch_time"_"$1"
        
        migrate=./migrations/migrate/"$migration_name"_migrate.sql
        revert=./migrations/revert/"$migration_name"_revert.sql

        # Creating migration files
        touch "$migrate"
        log_success "Migrate file located at $migrate"
        touch "$revert" 
        log_success "Revert file located at $revert"

        # Creating migration in the database
        create_migration $migration_name
    fi
}

#################################################
# Rollback the last migration operation
#################################################
migrate_rollback() {
    # Fetching Migrations
    migrations=$(get_last_ran)
    error="The last set of migrations were already rolled back"

    # Rolling back the migrations
    handle_multiple_revert "$migrations" "$error"
}

#################################################
# Performs a revert on multiple migrations
#
# @param $1: The migrations list
# @param $2: The error message to display if
#            there is nothing to migrate
#################################################
handle_multiple_revert() {
    # Verifying that we have a migration to run
    words=( $1 )
    if [ ${#words[@]} -ne 0 ]; then

        # Going through all outstanding migrations
        for column in $1
        do
            # id column
            if [ "$id" == "" ]; then
                id=$column
                continue
            fi

            # name column
            if [ "$name" == "" ]; then
               name=$column
            fi

            # Handling
            handle_single_revert $id $name

            # Clearing
            id=""
            name=""
        done
    else
        log_alert "$2"
    fi
}

#################################################
# Performs a revert on a single migration
#
# @param $1: The id of the migration
# @param $2: The name of the migration
#################################################
handle_single_revert() {
    # Reverting the file
    revert_file=./migrations/revert/"$2"_revert.sql
    database_file_execute $revert_file

    # Updating the database that we haven't ran this
    set_ran_last $1 0
    set_active $1 0

    # Logging our success
    log_success "Migration $2 has successfully been reveted"
}

#################################################
# Rollback all migrations
#################################################
migrate_reset() {
    # Fetching Migrations
    migrations=$(get_active_migrations)
    error="There were no migrations to revert"

    # Rolling back the migrations
    handle_multiple_revert "$migrations" "$error"
}

#################################################
# Runs all outstanding migrations
#################################################
migrate() {
    migrations=$(get_outstanding_migrations)

    # Verifying that we have a migration to run
    words=( $migrations )
    if [ ${#words[@]} -ne 0 ]; then

        # Setting all migrations ran_last to false
        reset_ran_last

        # Going through all outstanding migrations
        for column in $migrations
        do
            # id column
            if [ "$id" == "" ]; then
                id=$column
                continue
            fi

            # name column
            if [ "$name" == "" ]; then
               name=$column
            fi

            # Handling
            handle_single_migration $id $name

            # Clearing
            id=""
            name=""
        done
    else
        log_alert "There were no migrations to run"
    fi
}

#################################################
# Runs a single migration
#
# @param $1: The id of the migration
# @param $2: The name of the migration
#################################################
handle_single_migration() {
    # Migrating the file
    migration_file=./migrations/migrate/"$2"_migrate.sql
    database_file_execute $migration_file

    # Updating the database that we've ran this
    set_ran_last $1 1
    set_active $1 1

    # Logging our success
    log_success "Migration located at $migration_file has successfully executed"
}

#################################################
# Rollback all migrations and run them all again
#################################################
migrate_refresh() {
    log_alert "Refreshing all migrations"
    migrate_reset
    log_alert "========="
    migrate
    log_alert "All migrations have been refreshed"
}

#################################################
# Runs through all of the migration files and
# puts the ones that aren't being tracked in the
# database.
#################################################
migrate_update() {
    migrations_files="migrations/migrate/*.sql"
    for file in $migrations_files
    do
        # Getting the migration name
        file_basename=$(basename $file)
        migration_name=$(echo $file_basename | sed 's/\_migrate.sql//')

        # Getting the result from the database
        migration=$(get_migration_from_name $migration_name)

        # Checking if it already exists
        words=( $migration )
        if [ ${#words[@]} -eq 0 ]
        then
            create_migration $migration_name
            log_success "Migration $migration_name is now being watched"
        fi
    done
}

#################################################
# Determines which action to take
#
# @param $1: The action to take
# @param $2: Parameters to pass to the action
#################################################
determine_action() {
    if   [ "$1" = "migrate" ]; then
        migrate
    elif [ "$1" = "migrate:update" ]; then
        migrate_update
    elif [ "$1" = "migrate:make" ]; then
        migrate_make $2
    elif [ "$1" = "migrate:rollback" ]; then
        migrate_rollback
    elif [ "$1" = "migrate:reset" ]; then
        migrate_reset
    elif [ "$1" = "migrate:refresh" ]; then
        migrate_refresh
    else
        log_error "Action invalid"
    fi
}

#################################################
# Ensures that the database is set up
#################################################
ensure_setup() {
    exists=$(database_table_exists)

    # Table doesn't exist, create it
    if [ $exists -eq 0 ]; then
        # Creating Table
        create_migrations_table

        # Logging
        log_alert "Created table $MYSQL_MIGRATION_TABLE"
    fi
}
