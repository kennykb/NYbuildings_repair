#!/usr/bin/env tclsh8.6

set maxextent 0.067;		# Max extent in X and Y in degrees
set maxcluster 500;		# Max number of changes in a cluster

namespace path {::tcl::mathfunc ::tcl::mathop}

package require tdbc::postgres
package require tdom

source geocluster.tcl

tdbc::postgres::connection create db -db gis

db allrows {
    DROP TABLE nys_city_rewrites
}

db allrows {
    CREATE TABLE nys_city_rewrites(
        id SERIAL PRIMARY KEY,
        zip CHAR(5),
        fromcity TEXT,
        tocity TEXT,
        loc GEOMETRY(POINT, 4326)
    )
}

db allrows {
    CREATE INDEX nys_city_rewrites_gist ON nys_city_rewrites USING GIST(loc)
}

set qAddressPointId [db prepare {
    select tags->'nysgissam:nysaddresspointid' as pointid,
           tags->'addr:city' as city,
           "addr:housenumber" as housenumber,
           tags->'addr:postcode' as postcode,
           tags->'addr:street' as street,
           tags->'addr:state' as state
    from na_osm_polygon poly
    where poly.osm_id = :osmid
}]

set qNYSAddr [db prepare {
    select ST_X(ST_Transform(wkb_geometry, 4326)) as longitude,
           ST_Y(ST_Transform(wkb_geometry, 4326)) as latitude,
           prefixaddr, addressnum, suffixaddr,
           completest as street,
           zipname as city,
           state,
           zipcode as postcode
    from nys_address_points
    where nysaddress = :pid
}]

set iCityRewrite [db prepare {
    insert into nys_city_rewrites(zip, fromcity, tocity, loc)
    values(:zip, :fromcity, :tocity,
	   ST_SetSRID(ST_MakePoint(:longitude, :latitude), 4326))
}]
       

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

set objects {}
set deleted 0
set edited 0
set salvage 0

set counties {}
set cities {}
set changekeys {}
set repairs {}

foreach {t changeid} [lsort -integer -index 1 -stride 2 $changesets] {

    puts stderr "Changeset $changeid at time [clock format $t]"

    if {[catch {open changesets/${changeid}.xml r} f]} {
	puts "$f: cannot open"
	continue
    }
    set data [read $f]
    close $f
    set doc [dom parse $data]
    set root [$doc documentElement]

    if {[$root nodeName] ne "osmChange"} {
	puts stderr "changesets/${changeid}.xml isn't an OSM change file."
	break
    }

    foreach block [$root childNodes] {

	# Look at all ways/relations modified in the changeset

	if {[$block nodeName] in {"create" "modify"}} {
	    foreach feature [$block childNodes] {

		# Isolate only the buildings

		set isBuilding 0
		if {[$feature nodeName] in {"way" "relation"}} {
		    set osmid [$feature getAttribute id]
		    foreach tag [$feature childNodes] {
			if {[$tag nodeName] ne "tag"} continue
			if {[$tag getAttribute k] eq "building"} {
			    set isBuilding 1
			    break
			}
		    }
		}
		if {!$isBuilding} continue

		# Isolate only the buildings with addresses

		set address {}
		foreach tag [$feature childNodes] {
		    if {[$tag nodeName] ne "tag"} continue
		    set key [$tag getAttribute k]
		    if {[regexp {^addr:(?:city|housenumber|postcode|street|state)$} $key]} {
			dict set address $key [$tag getAttribute v]
		    }
		}

		if {[dict size $address] == 0} continue


		# Get current state of a building - address and NYSGIS
		# address point ID

		set pointids {}
		set curaddress {}
		set exists 0
		$qAddressPointId foreach row \
		    [list osmid $osmid] {
			set exists 1
			if {[dict exists $row pointid]} {
			    set pointids [split [dict get $row pointid] \;]
			}
			foreach key {city housenumber postcode street state} {
			    if {[dict exists $row $key]} {
				dict set curaddress addr:$key \
				    [dict get $row $key]
			    }
			}
		    }

		# Has the building been deleted since the import?

		if {!$exists} {
		    incr deleted
		    continue
		}

		if {[llength $pointids] == 0} continue

		# Count address points to examine by county, to make sure
		# that all needed counties have been loaded in NYSGIS

		set pid [lindex $pointids 0]
		dict incr counties [string range $pid 0 3]

		# Find the NYSGIS addresses for the points

		set newaddress {}
		foreach pid $pointids {
		    $qNYSAddr foreach row [list pid $pid] {
			set comps {}
			foreach k {prefixaddr addressnum suffixaddr} {
			    if {[dict exists $row $k]} {
				lappend comps [dict get $row $k]
				dict unset row $k
			    }
			}
			dict set row housenumber [join $comps {}]
			
			set coords [list [dict get $row longitude] \
					[dict get $row latitude]]
			dict unset row longitude
			dict unset row latitude
			dict for {k v} $row {
			    dict set newaddress addr:$k $v {}
			}
		    }
		}
		lassign $coords longitude latitude

		# Set the ZIP code according to NYSGIS
		
		if {[dict exists $newaddress addr:postcode]} {
		    set zip [lindex [dict get $newaddress addr:postcode] 0]
		} else {
		    set zip {}
		}

		# Develop the fixes
		
		set fix {}
		dict for {key oldvalue} $address {

		    # Don't fix any tag that isn't still current
		    
		    if {![dict exists $curaddress $key]
			|| [dict get $curaddress $key] ne $oldvalue} continue

		    # Does NYSGIS offer a different value?

		    if {[dict exists $newaddress $key]} {
			set newvalue \
			    [join [dict keys [dict get $newaddress $key]] \;]

			if {$newvalue eq $oldvalue} continue
			if {[regexp \; $newvalue]} {
			    puts "$osmid: ambiguous: $key: $oldvalue -> $newvalue"
			    continue
			}

			# Override Ballston Spa 12020
			# TODO - More overrides here?
			
			if {$oldvalue ne $newvalue} {
			    if {$key eq "addr:city"
				&& $zip eq "12020"
				&& $oldvalue eq "Ballston Spa"} {
				continue
			    }
			}
			
			# Count that this key is changed

			dict incr changekeys $key
			
			# Record what cities have changed

			if {$key eq "addr:city"} {
			    if {![dict exists $cities $zip $oldvalue $newvalue]} {
				set x 0
			    } else {
				set x [dict get $cities $zip $oldvalue $newvalue]
			    }
			    incr x
			    dict set cities $zip $oldvalue $newvalue $x
			    $iCityRewrite allrows \
				[list zip $zip \
				     fromcity $oldvalue tocity $newvalue \
				     longitude $longitude latitude $latitude]
			}
			    
			# Record that this key needs repair on this object

			dict set fix $key $newvalue
		    }
		}

		if {[dict size $fix] == 0} continue

		# Count objects to be fixed; objects to be fixed by county;
		# record the repair for this specific object; record lists
		# of objects by repairs required

		incr salvage
		dict set repairs $osmid $fix
		dict lappend fixups $fix $longitude $latitude $osmid
		    
	    }
	}
    }
}

puts "$deleted buildings have been deleted since import"
puts "$edited buildings have had their addresses change since import"
puts "$salvage buildings have NYS address points disagreeing with imported data."
puts "Summary by county code:"
dict for {k count} $counties {
    puts "  $k: $count buildings"
}
puts "Summary by keyword:"
dict for {k count} $changekeys {
    puts "  $k: $count instances may be corrected"
}
puts "Cities adjusted:"
set tbl {}
foreach {zip d1} [lsort -stride 2 -index 0 $cities] {
    foreach {from d2} [lsort -stride 2 -index 0 $d1] {
	foreach {to count} [lsort -stride 2 -index 0 $d2] {
	    puts "   $zip: $from -> $to ($count instances)"
	    lappend tbl $zip $from $to $count
	}
    }
}
set i 0
puts "Most common city adjustments:"
foreach {zip from to count} [lsort -stride 4 -index 3 -integer -decreasing $tbl] {
    if {$count < 50} break
    puts "   $zip: $from -> $to ($count instances)"
}

# Changetable will have groups of seven objects:
# {minx miny maxx maxy npoints {actionlist}}
# Each action list will have alternating {set of changes to make}
# {set of points to make them on}.

set changetable {}
dict for {changes objects} $fixups {
    foreach cluster [geocluster::clusters $objects $maxextent $maxcluster] {
	set n2 [expr {[llength $cluster] / 3}]
	lassign [geocluster::bbox $cluster] minx2 miny2 maxx2 maxy2

	set found 0
	set i -1
	foreach tuple $changetable {
	    incr i
	    lassign $tuple minx1 miny1 maxx1 maxy1 n1 actions1
	    set n [expr {$n1 + $n2}]
	    set minx [min $minx1 $minx2]
	    set miny [min $miny1 $miny2]
	    set maxx [max $maxx1 $maxx2]
	    set maxy [max $maxy1 $maxy2]
	    if {$n <= $maxcluster
		&& $maxx-$minx <= $maxextent
		&& $maxy-$miny <= $maxextent} {
		set found 1
		break
	    }
	}
	if {$found} {
	    lset changetable $i {}
	    set tuple {}
	    lappend actions1 $changes $cluster
	    lset changetable $i [list $minx $miny $maxx $maxy $n $actions1]
	} else {
	    lappend changetable [list $minx2 $miny2 $maxx2 $maxy2 $n2 [list $changes $cluster]]
	}
    }
}

puts "[llength $changetable] changesets could go into JOSM"

set f [open changetable.txt w]
puts $f [llength $changetable]
foreach tuple $changetable {
    lassign $tuple minx miny maxx maxy n actions
    puts $f "[dict size $actions] $n $minx $miny $maxx $maxy"
    dict for {changes points} $actions {
	puts $f [dict size $changes]
	dict for {key value} $changes {
	    puts $f "$key=$value"
	}
	puts $f [expr [llength $points] / 3]
	foreach {x y osmid} $points {
	    puts $f $osmid
	}
    }
}
close $f


# Create a PostGIS table to report on the postal city-municipality mismatch.

db allrows {
    DROP TABLE nys_city_rewrite_counts
}

db allrows {

    CREATE TABLE nys_city_rewrite_counts(
           zip CHAR(5),
           fromcity TEXT,
           tocity TEXT,
           npoints INTEGER,
           boundary GEOMETRY(MULTIPOLYGON, 32618),
           PRIMARY KEY(zip, fromcity, tocity)
    )
}      

db allrows {
    INSERT INTO nys_city_rewrite_counts(zip, fromcity, tocity,
					npoints, boundary)
    SELECT zip, fromcity, tocity,
           COUNT(1) as npoints,
           ST_Simplify(
               ST_Multi(
                   ST_Buffer(
                       ST_Transform(
                           ST_Collect(loc),
                           32618),
                       75.)
                   ),
               10.) as boundary
    FROM nys_city_rewrites
    GROUP BY zip, fromcity, tocity
}

db allrows {
    CREATE INDEX idx_nys_city_rewrite_counts_geo
    ON nys_city_rewrite_counts USING GIST(boundary)
}
