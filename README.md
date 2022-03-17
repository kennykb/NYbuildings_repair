# NYbuildings_repair
One-time scripts for repairing a building import with corrupted addresses in OpenStreetMap


## One-sentence problem statement:

A majority of buildings mapped in Herkimer County, New York (and some
buildings elsewhere in New York) have corrupted street addresses.


## Examples:

https://www.openstreetmap.org/way/816006773 has its `addr:street` value
set to 'Washington'.  It should be 'North Washington Street'.

https://www.openstreetmap.org/way/816007524 has its `addr:street` value
set to '5'.  It should be 'State Route 5 West' or some variant thereof.

https://www.openstreetmap.org/way/815788501 has an `addr:city` value of
'Road'.  It should be 'Stony Creek'. (This one is in Warren County rather
than Herkimer.)


## What appears to have happened:

A great number of building footprints appear to have been imported by
OSM user `NYbuildings` - an import pseudonym for `mileuthi`. The import
source is not given in the tags or changeset comments, but I suspect that
the footprints are from either the 
[Microsoft building footprints](https://cugir.library.cornell.edu/catalog/cugir-009053)
or the
[NYSERDA Building Footprints with Flood Analysis](http://fidss.ciesin.columbia.edu/building_data_adaptation).

As far as I can tell from searching the 'imports', 'imports-us',
'talk-us' and 'talk-us-newyork' mailing lists for a few months prior
to the import, the import was not discussed on the mailing lists.
I know that talk of the MS Building Footprints was in the air, though,
so I may well have missed something in my search.

Neither of these data sets has address point information, so the
street addresses of the imported buildings must have come from
another source, likely [NYS Address Points](https://gis.ny.gov/streets/).
There appears
to have been a systemic error in the conversion of street names
from whatever source gave the importer the street addresses.
Further confusion ensued because the [NYS GIS SAM import](https://wiki.openstreetmap.org/wiki/New_York_(state)/NYS_GIS_SAM_Address_Points_Import)
added tagging to the buildings in the area.  It was (responsibly!)
coded in such a way that it would not overwrite any address tagging
that an earlier mapper had added, so buildings likely bear corrupted
address fields together with perhaps a few correct ones and corresponding
address point ID's from the later import.

It would appear that the issue of the corrupted addresses was first
raised with the importer on 2021-07-13 in a comment on 
[changeset 86613422](https://www.openstreetmap.org/changeset/86613422).
There was no reply,
possibly because the commenter also fixed the specific ways that he
mentioned.  Apparently, the importer did not attempt to determine whether
there might have been a systemic issue with the import.

All changesets from the import user must be suspect.  I've seen
corrupted addresses as early as changeset 86590260 and as late as
changeset 88885072.

I personally raised the issue (without having done the full research
needed to make this report) on 2022-03-13, in comments on 
(changeset 86639030)[https://www.openstreetmap.org/changeset/86639030].
I did get a reply,
asking for specific examples, and I responded with Overpass Turbo links
demonstrating the extent of the problem - there appear to be thousands
of affected polygons.  I've not heard back further.


* So, where do we go from here?

(First, give `NYBuildings` a few days more to respond...)

The problem affects a large number of ways - I'm guessing at least
ten thousand. 
[Changeset 86639030](https://www.openstreetmap.org/changeset/86639030)
alone contains about 7200 corrupted street addresses. I don't
think a total revert is appropriate; some amount of the bad data
has already been fixed by other mappers, and the MS building footprints,
while of pretty sketchy data quality, are most likely better than
nothing.  For this reason, I think that some clever programming and
a mechanical edit are probably the best approach to recovering
the situation.

A sketch of the process might be.

   * Examine the 180 changesets committed by `NYbuildings`. Identify
     the building ways with `addr:*` values.  Discard at this point
     any buildings that have had their addresses modified since the
     import by any user other than the NYS GIS SAM import.

   * For any building that has been conflated with an address point
     from NYS GIS SAM, replace all `addr:*` fields with the ones from
     the state.

   * For any remaining building that _contains_ one or more address
     points from NYS GIS SAM, if all of the contained points agree
     on `addr:state`, `addr:city`, `addr:postcode`, 'addr:housenumber`
     or `addr:street`, replace any `addr:*` key for which all the
     contained points agreed with the agreed-on value.

   * Flag any remaining building in a local database for manual analysis.
     It is possble that the manual analysis will reveal more
     opportunities for streamlining the remaining recovery with
     further mechanical edits.

   * Group modified buildings into batches of 100 buildings or so,
     clustered geographically. Push the key changes into JOSM using
     the remote control API one batch at a time and upload.
     (I have code to do the clustering, which I used on earlier import
     work.)

Obviously, I'll follow the mechanical edit guidelines when doing this:
announce the edit in advance on `imports-us` and `talk-us`; prepare
OSM XML showing the results on a small subset of the points and make
it available for community review; and document the process (this
message would be a good start toward that documentation) on the
Wiki. Following that, I'll pull the trigger only if it appears that I
have community buy-in.
