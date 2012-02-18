#!/usr/bin/env bash
#
# monitor
# https://github.com/sathlan/monitor
#
# Start backgroung monitoring a subsystem on STDOUT and, if sar is
# present, everything in a log file.
#
####
#/ USAGE: monitor [--help|-h] [--version|-v]
#/             --action|-a      <start|stop>
#/             --log|-l         <file>
#/             [--command|-d    <dstat:-ddevice-1,-ddevice-2,..|...>]
#/             
#### REQUIREMENTS
# getopt: 
#    debian: apt-get install util-linux
#    freebsd: portmaster misc/getopt

# Exit if any following command exits with a non-zero status.
set -e

MONITOR_VERSION="0.0.1"
export MONITOR_VERSION

SAR=/usr/lib/sysstat/sadc
LOG=""
ACTION=""
CMD=""
ARGS=""

monitor_usage()
{
    grep '^#/' <"$0" | cut -c4- >&2
}

monitor_log()
{
    echo "monitor: $@" >&2
}

monitor_error()
{
    [ -n "$@" ] && monitor_log "$@" 
    monitor_usage
    exit 1
}

monitor_valid_actions()
{
    local action="${1:-impossible_name}"
    awk '/^#\/.*--action/{print $3}' $0 | tr '<>|' ' ' | \
        grep -q "${action}"
}

while test "$#" -gt 0
do
    case "$1" in
        --help|-h)
            monitor_usage
            exit 0
            ;;
        --version|-v)
            echo "monitor version $MONITOR_VERSION"
            exit 0
            ;;
        --action|-a)
            ACTION="$2"
            shift 2
            ;;
        --command|-c)
            CMD="${2%:*}"
            ARGS="${2#*:}"
            shift 2
            ;;
        --name|-n)
            NAME="$2"
            shift 2
            ;;
        --log|-l)
            LOG="$2"
            shift 2
            ;;
        -)
            monitor_error "unkonwn switch $1"
            ;;
        *)
            break
            ;;
    esac
done

[ -z "$ACTION" ] && monitor_error "missing action."
[ -z "$LOG"    ] && monitor_error "missing log file for sar."
if ! monitor_valid_actions $ACTION; then
    monitor_error "invalid action."
fi

SAR_PID=''
OLD_WDIR="$PWD"

monitor_start_sar()
{
    /usr/lib/sysstat/sadc -S XALL -L -F 1 ./sar.db &
    SAR_PID=$!
}

monitor_do_start()
{
    cd /
    test -x $SAR && monitor_start_sar
    $ACTION `monitor_parse_option`
    [ -d $OLD_DIR ] && cd $OLD_WDIR
}

monitor_do_stop()
{
    [ -n "$SAR_PID" ] && kill -INT $SAR_PID
    
}

monitor()
{
    case "$ACTION" in
        start)
            trap 'monitor_do_stop' EXIT INT
            monitor_do_start
            return 0
            ;;
        stop)
            monitor_do_stop
            return 0
            ;;
        *)
            monitor_error "invalid action"
            return 1
            ;;
    esac
}

monitor
