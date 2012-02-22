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


# Exit if any following command exits with a non-zero status.
set -e

MONITOR_VERSION="0.0.1"
export MONITOR_VERSION

SAR=/usr/lib/sysstat/sadc
LOG=""
ACTION=""
CMD=""
ARGS=""
SAR_PID=''
CMD_PID=''
OLD_WDIR="$PWD"
RC=0

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
    RC=64
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
[ -z "$LOG" -a "$ACTION" != 'stop' ] && monitor_error "missing log file for sar."
if ! monitor_valid_actions $ACTION; then
    monitor_error "invalid action."
fi

sanitize_log_path()
{
    local p_dir="$PWD"
    local dir="$OLD_WDIR"
    if echo "$LOG" | egrep -q '^(\.\.|/)'; then
        cd `dirname "$LOG"`
        dir="$PWD"
    fi
    LOG="${dir}/`basename $LOG`"
    cd $p_dir
    
}

monitor_start_sar()
{
    sanitize_log_path
    $SAR -S XALL -L -F 1 $LOG &
    SAR_PID=$!
}

monitor_parse_option()
{
    echo $ARGS | tr ',' ' ' | sed -e 's/_ _/,/g'
}

monitor_do_start()
{
    test -x $SAR && monitor_start_sar
    [ -z "$CMD" ] && return 0
    local args=`monitor_parse_option`
    set +e
    $CMD $args &
    CMD_PID=$!
    wait $CMD_PID
    local rc=$!
    set -e
    if [ $rc -ne 0 ]; then
        CMD_PID="";
        monitor_error "failed to start \"$CMD $args\"."
    fi
}

monitor_do_stop()
{
    [ -n "$SAR_PID" ] && kill -TERM $SAR_PID
    [ -n "$CMD_PID" ] && kill -TERM $CMD_PID
    exit $RC
}

monitor()
{
    case "$ACTION" in
        start)
            trap 'monitor_do_stop' EXIT INT TERM
            monitor_do_start
            wait
            return 0
            ;;
        stop)
            pkill -TERM -f 'monitor.*start'
            return 0
            ;;
        *)
            monitor_error "invalid action"
            return 1
            ;;
    esac
}

monitor
