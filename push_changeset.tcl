set josm_url http://127.0.0.1:8111

proc start_changeset {label minx miny maxx maxy nways changes} {
    variable josm_url
    set tagcounts {}
    foreach {tags ids} $changes {
	foreach tag $tags {
	    dict incr tagcounts $tag [llength $ids]
	}
    }
    puts "start changeset $label with $nways ways"
    set comment "ke9tv NYbuildings repair: $nways ways"
    set left [dict size $tagcounts]
    foreach {tag count} [lsort -stride 2 -index 1 -integer -decreasing $tagcounts] {
	puts "$count ways with tag $tag"
	set message " $tag: $count"
	if {[string length $comment] + [string length $message] < 240} {
	    append comment $message
	    incr left -1
	}
    }
    if {$left > 0} {
	append comment "+$left more tags"
    }
    puts "Changeset comment: $comment"
    set ctags "bot=yes|description=$::wikilink"
    set midx [expr {0.5 * ($minx + $maxx)}]
    set midy [expr {0.5 * ($miny + $maxy)}]

    set params {}
    dict set params bottom $midy
    dict set params top $midy
    dict set params left $midx
    dict set params right $midx
    dict set params new_layer true
    dict set params layer_name "Repaired Buildings $label"
    dict set params changeset_comment $comment
    dict set params changeset_source $::useragent
    dict set params changeset_tags $ctags

    set url $josm_url
    append url /load_and_zoom? [http::formatQuery {*}$params]
    puts stderr $url
    set token [http::geturl $url]
    if {[http::status $token] ne {ok}} {
	puts stderr "OOPS: [http::error $token]"
    }
    http::cleanup $token

}

proc push_changeset {label changes} {
    variable josm_url
    foreach {tags ids} $changes {
	puts "Apply tags $tags to objects $ids"
	set params {}
	dict set params new_layer false
	dict set params addtags [join $tags |]
	# dict set params referrers true
	dict set params layer_name "Repaired Buildings $label"
	dict set params objects \
	    [join [lmap x $ids {return -level 0 w$x}] ,]
	set url $josm_url
	append url /load_object? [http::formatQuery {*}$params]
	puts stderr $url
	set token [http::geturl $url]
	if {[http::status $token] ne {ok}} {
	    puts stderr "OOPS: [http::error $token]"
	}
	http::cleanup $token
    }
    puts -nonewline stderr "Enter to continue: "
    gets stdin -
}

