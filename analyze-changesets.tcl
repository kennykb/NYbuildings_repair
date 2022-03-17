#!/usr/bin/env tclsh8.6

package require tdom

set f [open "changesets.csv" r]
set data [split [read $f] \n]
close $f

set changesets {}
foreach row $data {
    set cells [split $row ,]
    if {[llength $cells] != 2} continue
    set t [clock scan [lindex $cells 1] -format "%Y-%m-%dT%H:%M:%S%Z"]
    lappend changesets $t [lindex $cells 0]
}

foreach {t changeid} [lsort -integer -index 1 -stride 2 $changesets] {

    puts stderr "Changeset $changeid at time [clock format $t]"

    set f [open changesets/${changeid}.xml r]
    set data [read $f]
    close $f
    set doc [dom parse $data]
    set root [$doc rootElement]
    puts [$root nodeName]
    break;

}
