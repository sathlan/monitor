#!/usr/bin/env roundup

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
