#!/usr/bin/env bash
# Generate HomeCloud service volumes(mount to docker)
#
SETUP_ENV_FULLPATH=""
usage() {
    echo "Usage: $0 -c some_path/homeproxy.<env>"
    echo "  Please provide the homeproxy service environment file, e.g. some_path/homeproxy.dev"
    echo "  You COULD create such file based on homeproxy.env.template"
    echo "  The filename should be homeproxy.<env>, <env> indicates the deployment, can be dev | prod"
}

error_exit() {
    usage
    exit 1
}

while getopts "c:h" arg
do
    case ${arg} in
        c)
            SETUP_ENV_FULLPATH=${OPTARG}
            ;;
        h | *)
            usage
            exit 0
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${SETUP_ENV_FULLPATH}" ] || [ ! -f "${SETUP_ENV_FULLPATH}" ]; then
    error_exit
fi

SETUP_ENV_FILENAME=$(basename "${SETUP_ENV_FULLPATH}")
TARGET_ENV=${SETUP_ENV_FILENAME##*.}
filename=${SETUP_ENV_FILENAME%.*}

if [ "${filename}" != "homeproxy" ]; then
    error_exit
fi

source "${SETUP_ENV_FULLPATH}"

# myself path
mypath=$(realpath "${BASH_SOURCE:-$0}")
MYSELF_PATH=$(dirname "${mypath}")
SYNCUP_PROGRAM_PATH="${MYSELF_PATH}"
if [ ! -d "${SERVICE_DESTINATION}" ]; then
    echo "Folder ${SERVICE_DESTINATION} does not exist or can not access!!!"
    error_exit
fi

mkdir -p "${SERVICE_DESTINATION}/etc"
if [ ! -f "${SERVICE_DESTINATION}/${SETUP_ENV_FILENAME}" ]; then
    cp "${SETUP_ENV_FULLPATH}" "${SERVICE_DESTINATION}"/"${SETUP_ENV_FILENAME}"
fi

for f in docker-compose.yml Dockerfile.tor Dockerfile.privoxy Dockerfile.squid
do
    cp "${SYNCUP_PROGRAM_PATH}/${f}" "${SERVICE_DESTINATION}/${f}"
done

rsync -r "${SYNCUP_PROGRAM_PATH}/etc/" "${SERVICE_DESTINATION}/etc"

HOMEPROXY_ENV_FILE="${SERVICE_DESTINATION}/docker-compose.${TARGET_ENV}.yml"

printf "services:\n" > "${HOMEPROXY_ENV_FILE}"
{
    printf "\n";
    printf "  tor:\n";
    printf "    volumes:\n";
    printf "      - %s:/etc/tor\n" "${SERVICE_DESTINATION}/etc/tor";
} >> "${HOMEPROXY_ENV_FILE}"
{
    printf "\n";
    printf "  privoxy:\n";
    printf "    volumes:\n";
    printf "      - %s:/etc/privoxy\n" "${SERVICE_DESTINATION}/etc/privoxy";
} >> "${HOMEPROXY_ENV_FILE}"
{
    printf "\n";
    printf "  squid:\n";
    printf "    volumes:\n";
    printf "      - %s:/etc/squid/squid.conf\n" "${SERVICE_DESTINATION}/etc/squid/squid.conf";
    printf "      - %s:/etc/squid/passwords\n" "${SERVICE_DESTINATION}/etc/squid/passwords";
} >> "${HOMEPROXY_ENV_FILE}"


mkdir -p "${SERVICE_DESTINATION}/bin"

START_SH="${SERVICE_DESTINATION}/bin/start.sh"
START_DAEMON_SH="${SERVICE_DESTINATION}/bin/start.daemon.sh"
STOP_SH="${SERVICE_DESTINATION}/bin/stop.sh"
RESTART_SH="${SERVICE_DESTINATION}/bin/restart.sh"

{
    printf "#!/bin/bash\n";
    printf "docker rmi homeproxy-tor homeproxy-privoxy homeproxy-squid\n";
    printf "docker compose -f ${SERVICE_DESTINATION}/docker-compose.yml -f ${SERVICE_DESTINATION}/docker-compose.${TARGET_ENV}.yml up\n";
} > "${START_SH}"

{
    printf "#!/bin/bash\n";
    printf "docker rmi homeproxy-tor homeproxy-privoxy homeproxy-squid\n";
    printf "docker compose -f ${SERVICE_DESTINATION}/docker-compose.yml -f ${SERVICE_DESTINATION}/docker-compose.${TARGET_ENV}.yml up -d\n";
} > "${START_DAEMON_SH}"

{
    printf "#!/bin/bash\n";
    printf "docker compose -f ${SERVICE_DESTINATION}/docker-compose.yml -f ${SERVICE_DESTINATION}/docker-compose.${TARGET_ENV}.yml down\n";
} > "${STOP_SH}"

{
    printf "#!/bin/bash\n";
    printf "docker compose -f ${SERVICE_DESTINATION}/docker-compose.yml -f ${SERVICE_DESTINATION}/docker-compose.${TARGET_ENV}.yml restart\n";
} > "${RESTART_SH}"

chmod +x "${START_SH}" "${STOP_SH}" "${START_DAEMON_SH}" "${RESTART_SH}"
