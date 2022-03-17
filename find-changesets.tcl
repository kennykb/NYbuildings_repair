#!/usr/bin/env tclsh8.6

# This script locates the changeset numbers that may contain
# corrupted addresses created by an import from user 'NYbuildings'.

package require http
package require tls
http::config -useragent "[file tail [info script]] $build $project"
http::register https 443 [list ::tls::socket -autoservername true]
source config.tcl

# Retrieves a page of changesets from local storage if available, otherwise
# from the OSM API
#
#	pageNum - Sequential number of the page being retrieved
#	t1	- Start of the time window for retrieval
#	t2	- End of the time window for retrieval

proc retrieve_changesets {pagenum t1 t2} {

    variable osm_server

    set cachefile changeset-list-${pagenum.xml}
    
    if {[file exists $cachefile]} {
	
	set f [open $cachefile r]
	set data [read $f]
	close $f
	return $data

    } else {

	set url $osm_server
	append url /api/0.6/changesets? \
	    [http::formatQuery \
		 display_name	NYbuildings \
		 time		$t1,$t2]
	puts $url

	set token [http::geturl $url]
	if {[http::status $token] ne {ok}} {
	    set message [http::error $token]
	    http::cleanup $token
	    return -code error -errorcode [list HTTP $url] $message
	}

	set result [http::data $token]
	http::cleanup $token
	set f [open $cachefile w]
	puts -nonewline $f $result
	close $f
	return $result
    }
}

set t1 [clock format 0 -format "%Y-%m-%dT%H:%M:%S%z" -gmt true]
set t2 [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S%z" -gmt true]

set pagenum 0
while {1} {

    set data [retrieve_changesets $pagenum $t1 $t2]

    break

    incr pagenum
	

}




