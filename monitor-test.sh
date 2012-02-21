#!/usr/bin/env roundup
# http://bmizerany.github.com/roundup

describe "Monitor specific information on stdout and everything on background."

monitor="$PWD/monitor.sh"

before() {
    __DIR__="$PWD"
    rm -rf .sandbox
    mkdir -p .sandbox
    cd .sandbox
}

after() {
    rm -rf "$__DIR__/.sandbox"
}

it_shows_usage_with_no_argv()
{
    $monitor 2>&1 | grep 'USAGE'
}

it_shows_help_when_asked()
{
    $monitor -h 2>&1 | grep -q 'USAGE' && $monitor --help 2>&1 | grep -q 'USAGE'

}

it_shows_message_when_no_action()
{
    $monitor -c blah 2>&1 | grep 'missing.*action'
}

it_shows_message_when_invalid_action()
{
    $monitor -a blah -l log -c blah 2>&1 | grep 'invalid.*action'
}

it_shows_message_when_no_logfile()
{
    $monitor -a start -c sar 2>&1 | grep 'missing.*log'
}

it_can_start_arbitrary_command()
{
    local cmd="$monitor -a start -l ${PWD}/db.log -c iostat:1,dm-1"
    $cmd &
    local m_pid=$!
    sleep 2
    pgrep -f "$cmd" && \
        pgrep -f 'iostat *1 dm-1 *$' && \
        pgrep -f 'sadc.*db.log' && \
        test -f "${PWD}/db.log"
    local rc=$?
    # clean up!
    kill -TERM $m_pid
    wait
    exit $rc
}

it_let_no_processes_behind()
{
    pgrep -vf '.*monitor.*' && \
        pgrep -vf '.*iostat.*' && \
        pgrep -vf 'sar.*db.log$'
}

it_can_stop_itself()
{
    local cmd="$monitor -a start -l ${PWD}/db.log -c iostat:1,dm-1"
    $cmd &
    local m_pid=$!
    sleep 2
    $monitor -a stop
    pgrep -fv "$cmd" && \
        pgrep -fv 'iostat *1 dm-1 *$' && \
        pgrep -fv 'sadc.*db.log' && \
        test -f "${PWD}/db.log"
}

it_shows_the_command()
{
    local cmd="$monitor -a start -l ${PWD}/db.log -c iostat:1,dm-1"
    $cmd >'test-output' 2>&1 &
    local m_pid=$!
    sleep 2
    grep 'avg-cpu' test-output
    local rc=$?
    kill -TERM $m_pid
    exit $rc
}

it_fills_the_db()
{
    local cmd="$monitor -a start -l ${PWD}/db.log -c iostat:1,dm-1"
    $cmd >'test-output' 2>&1 &
    local m_pid=$!
    sleep 2
    sar -A -f "${PWD}/db.log" 1 2 | grep '^Average.*all'
    local rc=$?
    kill -TERM $m_pid
    exit $rc
}

it_can_be_run_without_command()
{
    local cmd="$monitor -a start -l ${PWD}/db.log"
    $cmd >'test-output' 2>&1 &
    local m_pid=$!
    sleep 2
    # if it has disappeared, it had a problem.
    ps -p $m_pid 2>/dev/null || exit 42
    kill -TERM $m_pid
    wait $m_pid
    exit 0
}

it_fails_if_command_is_a_nonsense()
{
    local cmd="$monitor -a start -l ${PWD}/db.log -c myblahfoobar:-df"
    $cmd &
    local m_pid=$!
    sleep 2
    ps -p $m_pid 2>/dev/null || exit 0
    # cleanup (shouldn't happen)
    kill -TERM $m_pid
    wait $m_pid
    exit 42
}

it_can_have_command_with_dash_in_args()
{
    local cmd="$monitor -a start -l ${PWD}/db.log -c dstat:-df,-Dsda1_,_dm-0"
    $cmd &
    local m_pid=$!
    sleep 2
    ps -p $m_pid 2>/dev/null || exit 42
    # cleanup (should happen)
    kill -TERM $m_pid
    wait $m_pid
    exit 0
}
