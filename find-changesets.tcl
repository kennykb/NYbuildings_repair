#!/usr/bin/env tclsh8.6

# This script locates the changeset numbers that may contain
# corrupted addresses created by an import from user 'NYbuildings'.

package require http
package require tdom
package require tls

source config.tcl

http::config -useragent "[file tail [info script]] $build $project"
http::register https 443 [list ::tls::socket -autoservername true]


# Retrieves a page of changesets from local storage if available, otherwise
# from the OSM API
#
#	username - Name of the user making the change
#	pageNum - Sequential number of the page being retrieved
#	time1	- Start of the time window for retrieval
#	time2	- End of the time window for retrieval

proc retrieve_changesets {username pagenum time1 time2} {

    variable osm_server

    set t1 [clock format $time1 -format "%Y-%m-%dT%H:%M:%S%z" -gmt true]
    set t2 [clock format $time2 -format "%Y-%m-%dT%H:%M:%S%z" -gmt true]
    set cachefile changeset-list-${pagenum}.xml
    
    if {[file exists $cachefile]} {
	
	set f [open $cachefile r]
	set data [read $f]
	close $f
	return $data

    } else {

	set url $osm_server
	append url /api/0.6/changesets? \
	    [http::formatQuery \
		 display_name	$username \
		 time		$t1,$t2]
	puts stderr $url

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

set safety 200;			# Safety counter; never retrieve more than
;				# this many pages of changesets

set pagenum 0

foreach user {
    miluethi
    NYbuildings AlexCleary
    BobKelly RobertReynolds Nia-gara RickMaldonado
    Northfork JoelManagua JoseDeSilva PeterKing RI-Improve JimTracy
    BrianDillman JOetlikers
} {

    puts stderr "Retrieve changesets for $user"

    set t1 0
    set t2 [clock seconds]

    set ok 1
    while {$ok && $pagenum < $safety} {

	puts stderr "--- page $pagenum ---"

	set data [retrieve_changesets $user $pagenum $t1 $t2]
	
	set doc [dom parse $data]
	set root [$doc documentElement]
	
	if {[$root nodeName] ne "osm"} {
	    puts stderr "Retrieved page is not an OSM XML file!"
	    return 1
	}
	
	if {![$root hasChildNodes]} {
	    set ok 0
	} else {

	    set kids [$root childNodes]
	    
	    foreach kid $kids {
		if {[$kid nodeName] eq "changeset"} {
		    set changeid [$kid getAttribute id]
		    set changetime [$kid getAttribute created_at]
		    set t2a [clock scan $changetime -format "%Y-%m-%dT%H:%M:%S%Z"]
		    puts "$changeid,$changetime"
		    if {$t2a < $t2} {
			set t2 $t2a
		    }
		}
	    }
	}
	
	$doc delete
	incr pagenum
	flush stdout
    }
}

