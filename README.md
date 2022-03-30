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
OSM users `AlexCleary` and `NYbuildings` - both of which are
pseudonyms of `miluethi`. 

(_Update 2022-03-29:_ The users `miluethi`, `BobKelly`, `RobertReynolds`,
`Nia-gara`, and `RickMaldonado` were also aliases of the same importer.
These users have been added to the list to examine. The changesets
will take some time to retrieve and analyze, but it is anticipated that
the same data processing pipeline will apply to all of them.)

The import source is not given in the tags
or changeset comments, but Michael Luethi reports that the footprints
were derived from 
[Lewis County building footprints](https://gis.ny.gov/gisdata/inventories/details.cfm?DSID=1343)
That is one possible data source, but the problem extends far beyond
Lewis County.
I suspect that some of the remaining footprints are from either the
[Microsoft building footprints](https://cugir.library.cornell.edu/catalog/cugir-009053) 
or the
[NYSERDA Building Footprints with Flood Analysis](http://fidss.ciesin.columbia.edu/building_data_adaptation).
The address points are reported to have derived from 
[NYS Address Points](https://gis.ny.gov/streets/).
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
(_Update 2022-03-29_: In excess of sixty thousand. How far in excess
remains to be determined, since the discovery of additional aliases
that the importer used.)

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
	 (_Update 2022-03-29:_The various users have nearly four thousand
	 changesets among them. Many relate to other projects than the
	 NY building import, but all must be examined at least mechanically.
	 The process of retrieving them alone will likely take several days.)

   * For any building that has been conflated with an address point
     from NYS GIS SAM, replace all `addr:*` fields with the ones from
     the state.

   * For any remaining building that _contains_ one or more address
     points from NYS GIS SAM, if all of the contained points agree
     on `addr:state`, `addr:city`, `addr:postcode`, `addr:housenumber`
     or `addr:street`, replace any `addr:*` key for which all the
     contained points agreed with the agreed-on value.

   * Flag any remaining building in a local database for manual analysis.
     It is possble that the manual analysis will reveal more
     opportunities for streamlining the remaining recovery with
     further mechanical edits. (_Update 2022-03-29:_ This step is on
	 indefinite hold - the project has simply grown bigger than I can
	 handle with manual review of this material.)

   * Group modified buildings into batches, clustered
     geographically. Push the key changes into JOSM using the remote
     control API one batch at a time and upload.  (I have code to do
     the clustering, which I used on earlier import work.)

Obviously, I'll follow the mechanical edit guidelines when doing this:
announce the edit in advance on `imports-us` and `talk-us`; prepare
OSM XML showing the results on a small subset of the points and make
it available for community review; and document the process (this
message would be a good start toward that documentation) on the
Wiki. Following that, I'll pull the trigger only if it appears that I
have community buy-in.

## Update 2022-03-19 02:00Z

The code as now committed carries out the first two steps of this
process, without yet creating and organizing changesets.

The discovery of the `AlexCleary` user id came as something of a surprise,
and reveals a huge additional volume of data that disagree with
NYSGIS - a total of 59,980 ways. (_Update 2022-03-29:_ and there are
four more aliases in play.)

The analysis reveals:

   * 30,825 addresses with street names that differ
   * 32,465 addresses with city names that differ
   * 152 addresses with housenumbers that differ
   * 120 addresses with postcodes that differ

_Update 2022-03-29:_ There will be considerably more even than this!
One round of corrections has already been run, so further counts will
not include the buildings that are already fixed.
   
The list of affected counties has also expanded greatly.  Counties
that are known to have imported addresses that disagree with NYSGIS
are Allegany, Cattaraugus, Cayuga, Chautauqua, Clinton, Cortland,
Essex, Fulton, Hamilton, Herkimer, Jefferson, Livingston, Montgomery,
Nassau, Ontario, Oswego, Saint Lawrence, Saratoga, Schuyler, Steuben,
Suffolk, Tioga, Tompkins, Warren, and Wyoming.

_Update 2022-03-29:_ Since Lewis County is known to have been
imported, and was absent from the list above, I suspect that the
whole state is involved. In any case, the analysis scripts are capable
of working with whole-state data. 

Most of the street names in disagreement can be accounted for by the
previously noted systemic issue of discarding prefix and suffix from
street names, so that 'West Main Street' would become just 'Main' and
so on.

There are numerous systemic issues with cities, which appear to be
that the city name was derived from intersecting the address with a
political boundary, rather than looking up the postal address. All of
these appear to be in Suffolk County. The remainder of changed city
names - no more than a handful - are accounted for by the possible
memory corruption mentioned above, or else by changes to geocoding
between the imports.

The changed city names in Suffolk County fall into specific, dense
geographic clusters.  The largest single cluster, of 2281 points,
is a simple respelling of the postal city name, from 'St. James'
(abbreviated - deprecated) to 'Saint James' (spelt out in full - as
OSM prefers). The following two maps show the other clusters.
Select the links in the captions to view them at a readable scale.

![City name changes - western Suffolk County](https://live.staticflickr.com/65535/51947090309_3100eac4a1_c_d.jpg)

[Map 1](https://live.staticflickr.com/65535/51947090309_3100eac4a1_c_d.jpg)
City name changes in western Suffolk County

![City name changes - eastern Suffolk County](https://live.staticflickr.com/65535/51945796197_8e076074f9_c_d.jpg)

[Map 2](https://live.staticflickr.com/65535/51945796197_8e076074f9_o_d.png). 
City name changes in eastern Suffolk County

In both maps, the clusters of address points are shown as shaded
regions. The color of a region is a rough indication of how many
addresses that would change in it, gradated from few=blue to
many=yellow. The labels give the count of points in the cluster,
the proposed change to the city name, and the ZIP code that applies.

All of the larger clusters (I've examined a few dozen) look reasonable
to me.  An example can be seen on the northwest corner of Map 1.  The
villages of Eatons Neck (1076 addresses) and Asharoken (531 addresses)
do not have their own post offices, and the post office explicitly
deprecates using those city names with ZIP code 11768, requiring
Northport instead - exactly what the data from the NYSGIS import give
us.

Farther east, the post office with ZIP code 11733 spans multple
villages. It serves Setauket and East Setauket, and allows both names
for city names.  It also serves the village of Old Field, and a small
corner of the village of Stony Brook, but those names are deprecated;
once again, NYSGIS is showing correct postal cities.

On the southwest corner of that map, there are patches all along the
south shore where the postal service boundaries don't coincide
with the village lines, so that some residents of Copiague have
their mailing address show Amityville while others show Lindenhurst.
The Lindenhurst post office also claims some residents of West
Babylon, and a strip where the postal service boundary between West
Babylon and Babylon follows a canal rather than the village line has
residents on both sides of the canal with postal addresses in the
other village.

The same sort of situations crop up all over the county.  On Map 2,
on the South Fork, the villages of Shinnecock Hills, Tuckahoe and
North Sea all lack their own post offices and are served by
Southampton, as is the westernmost corner of Water Mill.
Bridgehampton has residents served by the Water Mill, Sag Harbor and
Sagaponack post offices; Noyack and North Haven are served out of
Sag Harbor, and so on.

The Census-Determined Place (CDP) of Greenport West, on the North
Fork, is not a municipality, nor does it have a strong local
identity. All its addresses need to be assigned to nearby Southold or
Greenport, which the NYSGIS data does.

If `addr:city` is to represent the postal city, then I don't see any
changes on Long Island that I disagree with, particularly in light of
the fact that the building addresses arrived on an import to begin
with.

## Update 2022-03-22 00:01Z

I just pushed commits that appear to make the entire pipeline work.

The directory, `sample_changesets`, now contains a bunch of randomly-selected
changesets from the process, for peer review. It also has a file,
`changedesc.txt`, which is a machine-generated description of the
sample changesets, together with a few notes of mine about what's
going on.

My personal assessment of the sample changes is that they're surely no
worse than what's there, and generally much better. Only a handful of
changes appear questionable, and they generally relate to address
normalisation. 'Mt. Washington' should be spelt out, as possibly should
names like '2nd Street' or '4th Avenue' (the latter is questioned:
surely spelliing out One Hundred Ninety-Sixth street in New York City
would be silly, but where do whe draw the line?). I noticed one
house with an address on the wrong street - but it was wrong in both
datasets, and all that the repair program did was to change to the
correct spelling of the wrong street.

Obviously, more eyeballs are needed before going forward.

## Update 2022-03-28 20:21Z

Having heard no complaints about the proposed edit, I carefully vetted
and uploaded ten changesets, and will put the project on pause for another
week to await any changeset comments that may appear.

A detailed summary of what has been uploaded:

### [Changeset 119033831](https://www.openstreetmap.org/changeset/119033831):

 - `addr:street=West Water Street` (11 buildings)

     Buildings appear to front on a street with a matching name and
     have housenumbers running in sequence with ones that are
	 unaffected by the changeset. The changeset adds the 'West'
	 direction prefix.
   
 - `addr:city=Sag Harbor` (291 buildings)

      All buildings have `addr:postcode=11963` and are located in the
	  municipality of North Haven. USPS shows 'North Haven' as an
	  _unacceptable_ city for ZIP code 11963.

 - `addr:street=South Memantic Road` (16 buildings)

     Buildings appear to front on a street with a matching name and
     have housenumbers running in sequence with ones that are
	 unaffected by the changeset. Changeset adds the 'South'
	 direction prefix.

 - `addr:street=Simpson Road` (1 building)

     Building at 1 Simpson Road is adjacent to an unchanged
     building at 3 Simpson Road. Changeset alters the street name
	 from 'Gibbs Road', a nearby street that the house is not
	 adjacent to.
	 
 - `addr:street=Gibbs Avenue` (1 building)

     Changeset changes house number 4 from 'Gibbs Road' to 'Gibbs
     Avenue'.  The adjacent street in OSM is 'Gibbs Road' and
	 there is one other address point on it. NYSGIS shows the
	 street name for that address point also altered to Gibbs Avenue.
	 The associated building, if there is one, is not mapped.
	 
 - `addr:street=Bay Avenue` (8 buildings)

     OSM shows the adjacent street as 'Bay Avenue', matching the former
     value of `addr:street`, but NYSGIS shows it as 'Bay Road' in
	 both street segments and E911 addresses. The street name should
	 probably be changed in OSM, but that's out of scope for the
	 mechanical edit.
	 
 - `addr:street=South Ferry Road` (1 building)
 - `addr:street=Sunshine Road` (1 building)
 - `addr:street=Cove Drive` (1 building)
 - `addr:street=Whalers Walk`(1 building)
 - `addr:street=Ridge Drive` (2 buildings)
 - `addr:street=Cliff Drive` (1 building)
 - `addr:street=Windermere Drive` (1 building)
 - `addr:street=Sunset Drive` (1 building)
 - `addr:street=Harbor Drive` (3 buildings)
 
     Changeset alters the street name of corner lots. All changes make
     the housenumber run in correct sequence on the cross street, so
	 appear correct.

 - `addr:street=Bay View Drive East` (21 buildings)
 
   : Changeset adds a correct direction suffix.


### [Changeset 119035063](https://www.openstreetmap.org/changeset/119035063)

  - `addr:city=Shelter Island` (59 buildings)
  
    OSM had had 'Greenport' for the city name. These address points
	are easily identified as being on Shelter Island, which 
    matches the `addr:postcode`.
	
  - `addr:city=Shelter Island Heights` (196 buildings)
  
    These address points are in Shelter Island Heights, with the
	correct ZIP code. Previous OSM data had had the adjacent
	community, `Shelter Island`.
	
  - `addr:street=Wiggins Street` (14 buildings)
  
    Assigns the correct cross street to a corner lot.
	
_Note_: The OSM data for the buildings at the north end of Shelter
Island also bears the tag `addr:place=Dering Harbor`.  This tag is not
present in the later NYSGIS import. It is the name of a nearby
village, but the buildings in question are not in that village. The
tag probably ought to be removed, but I consider that out of scope for
the mechanical edit.

### [Changeset 119035973](https://www.openstreetmap.org/changeset/119035973)

  - `addr:city=Lake Grove` (329 buildings)
  
     Clusters of addresses in the neighbouring communities of Centereach,
	 Lake Ronkonkoma, and Saint James that are served from the Lake Grove
	 post office. Here, I have local knowledge that 'Lake Grove'
	 is the correct postal city.
	
  - `addr:street=Coates Avenue North` (84 buildings)
 
     Change spells out the 'North' suffix, which previously
	 appeared as just 'N' in the OSM data.
	 
   - `addr:city=Holbrook` + `addr:street=All Points Terrace` (19 buildings)
   
     Change unabbreviates 'All Points Ter' to 'All Points Terrace'
	 and assignes the correct city of 'Holtsville' in place of
	 'Holbrook'.
	 
   - `addr:city-Holbrook + addr:street=Expressway Drive North` (1 building)
	 
     Change unabbrviates 'Expressway Drive N' and assigns the postal
	 city of Holbrook in place of Holtsville. The postal city and
	 ZIP code match the adjacent buildings.

### [Changeset 119036136](https://www.openstreetmap.org/changeset/119036136)

   - `addr:city=Greenlawn` (206 buildings)
   
      Clusters of buildings in adacent communities of Huntington, Elwood
	  and East Northport served from the Greenlawn post office.
	  Postal city and ZIP code appear correct.
	  
### [Changeset 119037200](https://www.openstreetmap.org/changeset/119037200)

  - `addr:street=Main Street` (64 buildings)
   
     63 buildings had previously been just 'Main' and one had been '28'.
	 'Main Street' appears correct.
	 
  - `addr:street=Park Avenue` (13 buildings)
  
    Previously had been just 'Park'. Change appears correct
	
  - `addr:street=State Route 28` (23 buildings)

	Previously, 22 buildings had been just '28' and one, peculiarly,
	was 'West Canada Valley Central School'. Change appears correct.
	
I begin to abberviate here, since all the changes in the changeset 
follow the same pattern. All the names match facing streets in
OSM, except for the one exception noted
.

| From                    | To                      | Count | Notes |
| ----------------------- | ----------------------- | ----- | ----- |
| School                  | School Street           | 8     | |
| Cole                    | Cole Road               | 5     | |
| Main                    | South Main Street       | 32    | |
| Twin Ponds              | Twin Ponds Drive        | 1     | |
| East                    | East Street             | 31    | |
| West                    | West Street             | 37    | |
| Main                    | North Main Street       | 37    | |
| Newport                 | Newport Road            | 9     | |
| Gould                   | Gould Road              | 8     | |
| White Creek             | White Creek Road        | 41    | |
| Mechanic                | Mechanic Street         | 21    | |
| Hillside Terrace        | Hillside Terrace Drive  | 1     | |
| Norway                  | Norway Street           | 9     | |
| Bridge                  | Bridge Street           | 4     | |
| Harris                  | Harris Avenue           | 8     | |
| First                   | First Street            | 3     | (a)   |
| North                   | North Street            | 23    | |
| Woodchuck Hill          | Woodchuck Hill Road     | 11    | |
| Summit                  | Summit Road             | 29    | |
| Fishing Rock            | Fishing Rock Road       | 22    | |
| Farrington              | Farrington Road         | 4     | |
| City                    | Old City Road           | 4     | |
| Huyck                   | Huyck Avenue            | 18    | |
| Herkimer                | Herkimer Street         | 18    | |
| Kanata                  | Kanata Street           | 11    | |
| Farrington              | Farrington Road North   | 1     | |

(a) OSM has '1st Street' as the name of the facing street. I
am unaware of a uniform consensus about when a numbered street
should have its name spelt out.  Abbreviating 'Fifth Avenue'
is possibly wrong, but spelling out '261st Street' also appears
to be undesirable. I suspect that data consumers already implement
some sort of normalization process for these.

### [Changeset 119037705](https://www.openstreetmap.org/changeset/119037705)

  - `addr:city=Southampton` (500 buildings) 
  
     Buildings in the communities of Hampton Bays, Shinnecock Hills, 
	 and Tuckahoe that are served from the Southampton post office.

Among these 500 buildings are the following street name corrections, all
of which match the facing street:

| From                    | To                      | Count | Notes |
| ----------------------- | ----------------------- | ----- | ----- |
| Neck Lane               | West Neck Lane          | 2     | |
| Neck Cir                | West Neck Circle        | 13    | |
| Neck Point Road         | West Neck Point Road    | 10    | |
| Parrish Pond Court W    | Parrish Pond Court West | 2     | |
| Parrish Pond Court E    | Parrish Pond Court East | 6     | |
| Inlet Road W            | Inlet Road West         | 2     | |
| North Highway           | Old North Highway       | 1     | |
	 
### [Changeset 119038042](https://www.openstreetmap.org/changeset/119038042)

  - `addr:city=Sagaponack` (253 buildings)
  
    Cluster of buildings in Bridgehampton served from the Sagaponack
	post office. Postal city matches the ZIP code.
	 
plus the following street name corrections, all of which match
facing streets in OSM:

| From                    | To                      | Count | Notes |
| ----------------------- | ----------------------- | ----- | ----- |
| Narrow Lane E           | Narrow Lane East        | 14    | |
| Gibson Lane             | Row Off Gibson Lane     | 3     | |
| Highland Ter            | Highland Terrace        | 18    | |

### [Changeset 119038244](https://www.openstreetmap.org/changeset/119038244)

Just a handful of street name corrections:

| From                    | To                      | Count | Notes |
| ----------------------- | ----------------------- | ----- | ----- |
| Snyder                  | Snyder Road             | 5     | |
| Black Creek             | Black Creek Road        | 16    | |
| Dairy Hill              | Dairy Hill Road         | 18    | |
| Guideboard              | Guideboard Road         | 5     | |

### [Changeset 119038500](https://www.openstreetmap.org/changeset/119038500)

Housenumbers 4265 and 4277 are transposed from the way they appear in
OSM data. This change appears to make them run out of sequence. I
suspect that may have something to do with the fact that both
buildings are off the highway on a service way named 'Rixs Lane' but
have addresses on 'Town Line Road', so they may be numbered in order
of construction or something.

### [Changeset 119038596](https://www.openstreetmap.org/changeset/119038596)

Three housenumber changes. All appear to have been typos in an earlier
version of the NYSGIS data.
