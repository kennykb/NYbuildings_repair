#!/usr/bin/env tclsh8.6

# This script locates the changeset numbers that may contain
# corrupted addresses created by an import from user 'NYbuildings'.

package require http
package require tdom
package require tls

source config.tcl

http::config -useragent "[file tail [info script]] $build $project"
http::register https 443 [list ::tls::socket -autoservername true]

set f [open changesets.csv r]
set data [split [read $f] \n]
close $f

file mkdir changesets

set changesets {}
foreach row $data {
    set cells [split $row ,]
    if {[llength $cells] != 2} continue
    set t [clock scan [lindex $cells 1] -format "%Y-%m-%dT%H:%M:%S%Z"]
    lappend changesets $t [lindex $cells 0]
}

set changeno -1
set safety 200

foreach {t changeid} [lsort -integer -index 1 -stride 2 $changesets] {

    puts stderr "Changeset $changeid at time [clock format $t]"
    if {[incr changeno] >= $safety} break

    set cachefile [file join changesets ${changeid}.xml]

    set then 0

    if {![file exists $cachefile]} {

	set url $osm_server
	append url /api/0.6/changeset/ $changeid /download
	puts stderr "$url -> $cachefile"
	set token [http::geturl $url]
	if {[http::status $token] ne {ok}} {
	    puts stderr "[http::status $token] [http::error $token]"
	    return 1
	} else {
	    set f [open $cachefile w]
	    puts $f [http::data $token]
	    close $f
	    after 2000;		# Throttle requests to <= 0.5 request/second
	}
	http::cleanup $token
    }
}
