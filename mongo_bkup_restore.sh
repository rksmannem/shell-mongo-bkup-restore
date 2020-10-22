#!/usr/bin/env bash

set -eu -o pipefail

# set -x


ROOT_PATH=$(
    cd "$(dirname "${BASH_SOURCE[0]}")"
    pwd -P
)

MONGO_CREDS_FILE_NAME="mongo_creds.sh"

# db's backup DIR NAME
DBS_DIR_NAME="dbs"

# collection's backup DIR NAME
COLLS_DIR_NAME="collections"

# Database Name to backup
MONGO_DATABASE_NAME="admin"
# Backup directory
BACKUPS_DIR="${ROOT_PATH}/backups"

# get the required mongo db crenetials from a script by sourcing
source "${ROOT_PATH}/${MONGO_CREDS_FILE_NAME}"

usage() {
    cat <<EOF
        utility to perform backup and/or restore of mongo database or collection
        Usage:
             ${0} <command> <type>...

             Command:
                backup
                restore
             Type:
                database
                collection
EOF

}

function main() {
    if [[ $# -eq 0 ]]; then
        usage
        exit
    fi

    COMMAND="${1}"
    shift

    case "${COMMAND}" in
    backup | BACKUP) ;;

    restore | RESTORE) ;;

    help)
        usage
        ;;
    *)
        printf "invalid command: %s\n" "${COMMAND}"
        exit 1
        ;;
    esac

    if [[ ${#} -le 0 ]]; then
        printf "invalid operation: %s\n" "${COMMAND}"
        usage
        exit 1
    fi

    while [[ ${#} -gt 0 ]]; do
        case "${1}" in
        database)
            shift
            ${COMMAND}_database "${@}"
            ;;
        collection)
            shift
            ${COMMAND}_collection "${@}"
            shift
            ;;
        *)
            printf "invalid database item: %s" "${COMMAND}"
            exit 1
            ;;
        esac
        shift 2

    done
    # check if the mongod is installed in the machine

}

function backup_database() {
    # need exactly one argument which is db_name to backup
    if [[ $# -ne 1 ]]; then
        cat <<EOF
      Usage:
          backup_database <db_name>
EOF
        exit
    fi

    # extract the db name to backup from positional argument #1
    MONGO_DATABASE_NAME="${1}"

    echo "Performing backup of $MONGO_DATABASE_NAME"
    echo "--------------------------------------------"

    OUT_DIR="$BACKUPS_DIR/$DBS_DIR_NAME"
    # Create backup directory
    if ! mkdir -p $OUT_DIR; then
        echo "Can't create backup directory in $OUT_DIR. Go and fix it!" 1>&2
        exit 1
    fi

    # Create a backup of the given db
    mongodump --db $MONGO_DATABASE_NAME \
        --host $MONGO_HOST \
        --port $MONGO_PORT \
        --username $MONGO_USER \
        --authenticationDatabase $MONGO_AUTH_DB \
        --password $MONGO_PASSWORD \
        --out $OUT_DIR

    # Compress backup
    TIMESTAMP=$(date +%F-%H%M)
    BACKUP_NAME="$MONGO_DATABASE_NAME-$TIMESTAMP"

    [[ -d $OUT_DIR/$MONGO_DATABASE_NAME ]] && tar -zcvf $OUT_DIR/$BACKUP_NAME.tgz $OUT_DIR/$MONGO_DATABASE_NAME

    echo "--------------------------------------------"
    echo "Database:${MONGO_DATABASE_NAME} backup complete!"
    echo "--------------------------------------------"
}

function backup_collection() {
    # need exactly two arguments here: db_name collection_name
    if [[ $# -ne 2 ]]; then
        cat <<EOF
      Usage:
          backup_collection <db_name> <collection_name>
EOF
        exit
    fi

    # extract the db name to backup from positional argument #1
    MONGO_DATABASE_NAME="${1}"
    # extract the collection name to backup from positional argument #2
    MONGO_COLLECTION_NAME="${2}"

    echo "Performing backup of $MONGO_DATABASE_NAME"
    echo "--------------------------------------------"

    OUT_DIR=$BACKUPS_DIR/$COLLS_DIR_NAME
    # Create backup directory
    if ! mkdir -p $OUT_DIR; then
        echo "Can't create backup directory in $OUT_DIR. Go and fix it!" 1>&2
        exit 1
    fi

    # Create a backup of the given db and collection
    mongodump --collection $MONGO_COLLECTION_NAME \
        --db $MONGO_DATABASE_NAME \
        --host $MONGO_HOST \
        --port $MONGO_PORT \
        --username $MONGO_USER \
        --authenticationDatabase $MONGO_AUTH_DB \
        --password $MONGO_PASSWORD \
        --out $OUT_DIR

    # Compress backup
    TIMESTAMP=$(date +%F-%H%M)
    BACKUP_NAME="$MONGO_COLLECTION_NAME-$TIMESTAMP"
    [[ -d $OUT_DIR/$MONGO_DATABASE_NAME ]] && tar -zcvf $OUT_DIR/$BACKUP_NAME.tgz $OUT_DIR/$MONGO_DATABASE_NAME

    echo "--------------------------------------------"
    echo "collection:${MONGO_COLLECTION_NAME} from db:${MONGO_DATABASE_NAME} backup complete!"
    echo "--------------------------------------------"

}

#**************************RESTORES****************************************
function restore_database() {
    # need exactly one argument which is db_name to restore
    if [[ $# -ne 1 ]]; then
        cat <<EOF
      Usage:
          restore_database <db_name>
EOF
        exit
    fi

    # extract the db name to restore from positional argument #1
    MONGO_DATABASE_NAME="${1}"

    echo "Restoring the db: $MONGO_DATABASE_NAME"
    echo "--------------------------------------------"

    IN_DIR=$BACKUPS_DIR/$DBS_DIR_NAME/$MONGO_DATABASE_NAME

    # check if IN_DIR exists
    if [[ ! -d $IN_DIR ]]; then
        echo "Error: ${IN_DIR} not found. Can not continue."
        exit 1
    fi
    # restore a given db
    mongorestore --db $MONGO_DATABASE_NAME \
        --host $MONGO_HOST \
        --port $MONGO_PORT \
        --username $MONGO_USER \
        --authenticationDatabase $MONGO_AUTH_DB \
        --password $MONGO_PASSWORD \
        --drop \
        $IN_DIR

    echo "---------------------------------------------------"
    echo "Database:${MONGO_DATABASE_NAME} restore complete!"
    echo "---------------------------------------------------"
}

function restore_collection() {
    # need exactly two arguments here: db_name collection_name
    if [[ $# -ne 3 ]]; then
        cat <<EOF
      Usage:
          restore_collection <target_db_name> <target_collection_name> <path_to_bson_file_to_retore>
EOF
        exit
    fi

    # extract the target db name from positional argument #1
    TARGET_MONGO_DATABASE_NAME="${1}"
    # extract the target collection name from positional argument #2
    TARGET_MONGO_COLLECTION_NAME="${2}"
    # extract the input bson file name positional argument #3
    IN_BSON_FILE_NAME="${3}"

    IN_BSON_FILE=$BACKUPS_DIR/$COLLS_DIR_NAME/$IN_BSON_FILE_NAME

    echo "creating a collection:$TARGET_MONGO_DATABASE_NAME to: $TARGET_MONGO_COLLECTION_NAME, from "
    echo "--------------------------------------------------------------------"

    # check if IN_DIR exists
    if [[ ! -f $IN_BSON_FILE ]]; then
        echo "Error: ${IN_BSON_FILE} not found. Can not continue."
        exit 1
    fi

    # mongorestore --port <port> --db <destination database> --collection <collection-name>
    # <data-dump-path/dbname/collection.bson> --drop
    # restore a given collection to given db
    mongorestore --collection $TARGET_MONGO_COLLECTION_NAME \
        --db $TARGET_MONGO_DATABASE_NAME \
        --host $MONGO_HOST \
        --port $MONGO_PORT \
        --username $MONGO_USER \
        --authenticationDatabase $MONGO_AUTH_DB \
        --password $MONGO_PASSWORD \
        --drop \
        $IN_BSON_FILE

    echo "--------------------------------------------"
    echo "creating a new collection:${TARGET_MONGO_COLLECTION_NAME} in db:${TARGET_MONGO_DATABASE_NAME} complete!"
    echo "--------------------------------------------"
}

#**************************MAIN****************************************
# start executing from here
main "$@"
exit
