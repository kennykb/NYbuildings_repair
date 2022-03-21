# geocluster.tcl --
#
#	Code to divide a point cloud into clusters that are close together
#	geographically
#
# Copyright © 2022 by Kevin B. Kenny
# See the file LICENSE for the terms and conditions of reuse of this
# software, and for a DISCLAIMER OF ALL WARRANTIES.

package provide geocluster 0.1

namespace eval geocluster {
    namespace export clusters
}

# bbox --
#
#	Calculates the bounding box of a point set
#
# Parameters:
#	points - List of alternating values
#		 {x y clientdata x y clientdata...}
#		 where x and y give point coordinates in some projection
#		 and clientdata is ignored
#
# Results:
#	Returns a four-element list, {minx miny maxx maxy} giving the
#	extrema of the point coordinates
#
# SIde effects:
#	None.

proc geocluster::bbox {points} {

    set minx Infinity
    set maxx -Infinity
    set miny Infinity
    set maxy -Infinity

    foreach {x y clientdata} $points {

	if {$x < $minx} { set minx $x }
	if {$x > $maxx} { set maxx $x }
	if {$y < $miny} { set miny $y }
	if {$y > $maxy} { set maxy $y }
    }

    return [list $minx $miny $maxx $maxy]

}

# geocluster::clusters --
#
#	Divides a set of points into clusters.
#
# Parameters:
#	points - List of alternating values
#		 {x y clientdata x y clientdata...}
#		 where x and y give point coordinates in some projection
#		 and clientdata is ignored
#	maxdelta - Maximum extent of a cluster in both X and Y.
#		   All of the points of a returned cluster must fall within
#		   X and Y ranges whose maximum and minimum differ by most
#		   maxdelta
#	maxsize - Maximum number of points in a cluster.
#
# Results:
#	Returns a list of lists, where each sublist contains a subset of the
#	original points, no sublist is longer than 3*maxsize elements
#	(equivalently, maxsize points), and no sublist spans a greater
#	distance than maxdelta in either X or Y
#
# Side effects:
#	None.
#
# This procedure attempts to identify natural breakpoints along the axes
# for dividing the points.
#
# If the point set presented to it already spans a small enough range
# in both X and Y, and contains a small enough number of points, there
# is nothing to do, and it returns the input point set as the sole cluster.
#
# Otherwise, it divides the point set into two classes and calls itself
# recursively on each class.
#
# The method used to split the classes is analogous to Otsu's method
# for image segmentation.  The axis with the greater extent is identified,
# and the points are sorted according to their positions along that axis.
# A threshold value for that coordinate is then identified so that the
# sum of the variance of the point coordinates less than the threshold and
# the variance of the point coordinates greater than the threshold is minimized.
# This minimization is equivalent to maximizing the between-classes variance.
# The points are then divided into two subsets based on this threshold.
# As mentioned above, each subset is then presented recursively to 'clusters'
# for further subdivision if needed.  The two return values from 'clusters'
# are then concatenated to give the final result.

proc geocluster::clusters {points maxdelta maxsize} {

    # Count the points and find their bounding box

    set N [expr {[llength $points] / 3}]
    lassign [bbox $points] minx miny maxx maxy

    # Decide which axis to split on
    set deltax [expr {$maxx-$minx}]
    set deltay [expr {$maxy-$miny}]
    if {$N <= $maxsize
	&& $maxy-$miny <= $maxdelta
	&& $maxx-$minx <= $maxdelta} {
	return [list $points]
    }
    if {$deltax > $deltay} {
	set axis 0
    } else {
	set axis 1
    }

    puts "$minx <= x <= $maxx; $miny <= y <= $maxy; split on axis $axis"

    # Sort points along the given axis

    set sorted [lsort -real -index $axis -stride 3 $points]

    # Calculate cumulative sums, cumulative sums-of-squares

    set sums {}
    set sumsqs {}
    set sum 0.0
    set sumsq 0.0

    foreach {x y clientdata} $sorted {
	if {$axis == 0} {
	    set z $x
	} else {
	    set z $y
	}
	lappend sums [set sum [expr {$sum + $z}]]
	lappend sumsqs [set sumsq [expr {$sumsq + $z*$z}]]
    }

    # Find total variance of the point set. Tne within-classes
    # variance cannot exceed this value

    set best [expr {($sumsq - $sum**2 / $N) / $N}]

    # Find within-classes variances for each possible split point
    
    set n 0
    set breakpoint 0
    foreach s $sums ss $sumsqs {
	incr n

	# Variance of the set of points from 0 to n-1
	set varbelow [expr {($ss - $s**2 / $n) / $n}]

	# Class from points n to N-1
	set sa [expr {$sum - $s}]
	set ssa [expr {$sumsq - $ss}]
	set na [expr {$N - $n}]
	if {$na > 0} {
	    set varabove [expr {($ssa - $sa**2 / $na) / $na}]
	} else {
	    set varabove 0.0
	}

	# Total within-classes variance with threshold fixed at point 3*n
	set within [expr {$varbelow + $varabove}]
	if {$within < $best} {
	    set best $within
	    set breakpoint [expr {3 * $n}]
	}
    }

    # Partition the point set into two clusters, and recurse to partition
    # them further if necessary
    
    return [concat \
		[clusters [lrange $sorted 0 [expr {$breakpoint-1}]] \
		     $maxdelta $maxsize] \
		[clusters [lrange $sorted $breakpoint end] \
		    $maxdelta $maxsize]]
}
