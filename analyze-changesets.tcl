#!/usr/bin/env tclsh8.6

package require tdbc::postgres
package require tdom

set f [open "changesets.csv" r]
set data [split [read $f] \n]
close $f

tdbc::postgres::connection create db -db gis

set qAddressPointId [db prepare {
    select tags->'nysgissam:nysaddresspointid' as pointid
    from na_osm_polygon poly
    where poly.osm_id = :osmid}]

set changesets {}
foreach row $data {
    set cells [split $row ,]
    if {[llength $cells] != 2} continue
    set t [clock scan [lindex $cells 1] -format "%Y-%m-%dT%H:%M:%S%Z"]
    lappend changesets $t [lindex $cells 0]
}

set addrkeys {}
set objects {}
set oneword 0
set salvage 0
set counties {}
set oneword_chsets {}

foreach {t changeid} [lsort -integer -index 1 -stride 2 $changesets] {

    puts stderr "Changeset $changeid at time [clock format $t]"

    set f [open changesets/${changeid}.xml r]
    set data [read $f]
    close $f
    set doc [dom parse $data]
    set root [$doc documentElement]

    if {[$root nodeName] ne "osmChange"} {
	puts stderr "changesets/${changeid}.xml isn't an OSM change file."
	break
    }

    foreach block [$root childNodes] {

	if {[$block nodeName] in {"create" "modify"}} {

	    foreach feature [$block childNodes] {
		if {[$feature nodeName] in {"way" "relation"}} {
		    set osmid [$feature getAttribute id]
		    set isBuilding 0
		    foreach tag [$feature childNodes] {
			if {[$tag nodeName] ne "tag"} continue
			if {[$tag getAttribute k] eq "building"} {
			    set isBuilding 1
			    break
			}
		    }
		    if {$isBuilding} {
			foreach tag [$feature childNodes] {
			    if {[$tag nodeName] ne "tag"} continue
			    set key [$tag getAttribute k]
			    if {[regexp {^addr:} $key]} {
				set value [$tag getAttribute v]
				dict incr addrkeys $key
				dict set objects $osmid $key $value
				if {$key eq "addr:street"
				    && ![regexp " " $value]
				    && $value ni {"Broadway"}} {
				    incr oneword
				    dict set oneword_chsets $changeid {}
				    $qAddressPointId foreach row \
					[list osmid $osmid] {
					    if {[dict exists $row pointid]} {
						incr salvage
						set cty [string range [dict get $row pointid] 0 3]
						dict set counties $cty {}
					    }
					}
				}
			    }
			}
		    }
		}
	    }
	}
    }
}

puts "$oneword objects with one-word street names"
puts "appearing in changesets [dict keys $oneword_chsets]"
puts "$salvage have associated NYSGIS SAM address points"
puts "They are in counties: [lsort [dict keys $counties]]"
dict for {k count} $addrkeys {
    puts "$k: $count instances"
}
