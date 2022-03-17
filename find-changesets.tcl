#!/usr/bin/env tclsh8.6

# This script locates the changeset numbers that may contain
# corrupted addresses created by an import from user 'NYbuildings'.

package require http
package requre tls
http::register https 443 [list ::tls::socket -autoservername true]

source config.tcl

http::config -useragent "[file tail [info script]] $build $project"

set t1 [clock format 0 -format "%Y-%m-%dT%H:%M:%S%z" -gmt true]
set t2 [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S%z" -gmt true]

set pagenum 0
while {1} {

    set url $osm_server
    append url /api/0.6/changesets?\
	[http::formatQuery \
	     display_name	NYbuildings \
	     time		$t1,$t2]
    puts $url

    set token [http::geturl $url]
    if {[http::status $token] ne {ok}} {
	puts "--> $state(error)"
	return 1
    }

    set f changeset-list-${pagenum}.xml w
    puts -nonewline $f [http::data $token]
    close $f

    http::cleanup $token

    break

    incr pagenum
	

}




