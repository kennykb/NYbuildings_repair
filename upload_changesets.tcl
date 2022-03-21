#!/usr/bin/env tclsh8.6

package require http

source push_changeset.tcl

source config.tcl

set useragent "[file tail [info script]] $build $project"
set wikilink https://wiki.openstreetmap.org/wiki/Mechanical_edits/ke9tv_NYbuildings_repair

if {[llength $argv] < 1} {
    set requested Infinity
} else {
    lassign $argv requested
}

set f [open changetable.txt r]

gets $f nsets
set done 0
for {set i 0} {$i < $nsets} {incr i} {
    set changes {}
    gets $f line;
    if {[llength $line] < 6} break
    lassign $line nchanges nways minx miny maxx maxy
    for {set j 0} {$j < $nchanges} {incr j} {
	set tags {}
	gets $f ntags
	for {set k 0} {$k < $ntags} {incr k} {
	    gets $f tag
	    lappend tags $tag
	}
	set ids {}
	gets $f nobjs
	for {set k 0} {$k < $nobjs} {incr k} {
	    gets $f id
	    lappend ids $id
	}
	lappend changes $tags $ids
    }
    set todo [expr {$requested - $done}]
    set left [expr {$nsets - $i}]
    if {rand() < double($todo) / double($left)} {
	puts "select changeset $i"
	incr done
	puts "changeset $i: $nchanges tag changes affecting $nways ways"
	puts "  in bounding box $minx,$miny .. $maxx,$maxy"
	start_changeset $i $minx $miny $maxx $maxy $nways $changes
	push_changeset $i $changes
    }
}
close $f
