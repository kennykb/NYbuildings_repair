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
numerous OSM accounts, all of which appear to be pseudonyms of `miluethi`. 

As of 2022-03-31, the OSM accounts known to be involved in the import
include:
```
    AlexCleary    JoelManagua   Nia-gara     RI-Improve
    BrianDillman  JOetlikers    NYbuildings  RickMaldonado
    BobKelly      JoseDeSilva   Northfork    RobertReynolds
    JimTracy      miluethi      PeterKing
```

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
Further confusion ensued because the
[NYS GIS SAM import](https://wiki.openstreetmap.org/wiki/New_York_(state)/NYS_GIS_SAM_Address_Points_Import)
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
I did finally get a reply, and there has been further conversation
indicating that the importer is at least aware that there is a
genuine problem here.

## So, where do we go from here?

The problem affects a large number of ways - roughly 130,000 at last count.
2,631 are repaired in OSM by the sample changesets described below.
While the MS building footprints are pretty sketchy, I think that
rolling forward with address corrections is still the best way to
go, rather than the collateral damage that will inevitably result
from attempting to revert an import that's been in place for two years.

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
     
There's committed code in the repositoryy that carries out the first
two steps and forms the changesets (the last step). This code should
be enough to 'stop the bleeding', and the process will likely take
several weeks. Following that, we can go back and assess how much
we can harvest from the rest of the botched import. Manual review
of the remaining imported addresses may be easy (there may, in fact,
be none!), onerous, or not worth doing.

Obviously, I'll follow the mechanical edit guidelines when doing this:
announce the edit in advance on `imports-us` and `talk-us`; prepare
OSM XML showing the results on a small subset of the points and make
it available for community review; and document the process (this
message would be a good start toward that documentation) on the
Wiki. Following that, I'll pull the trigger only if it appears that I
have community buy-in.

## Current status: 2022-04-16

The last of about 130,000 buildings have had their addresses altered
by this mechanical process. All of the 700 or so changesets (including one
tranche that was mistakenly uploaded as user `ke9tv` rather than
`ke9tv_NYbuildings_repair`) were subjected to at least a cursory
'sanity check' inspection.

Until and unless additional alias users are identified, this project may be
considered closed.

## Current status: 2022-03-31

Beyond the 2,631 building addresses that have been repaired by the
sample changesets, 127,559 remain. They are not distributed
geographically in anything like a homogeneous fashion. New York City has
only one affected address, for instance.  The hardest-hit areas are the
suburban counties of Nassau and Suffolk, while the equally suburban
Westchester County has only a handful, In general, the lower Hudson
Valley was spared, with Washington, Columbia, Albany, Rensselaer,
Greene, Ulster, Dutchess, Rockland, Sullivan and Delaware Counties
needing only a few sporadic corrections. (Orange County, by contrast,
needs thousands.)  The Adirondacks, Southern Tier and Niagara Frontier
are all in need of considerable work.

The changes fall into two main categories, plus about 1,110 sporadic
changes. The counts of changes (the 2.601 changes already applied are
not counted here) are:

   * 78,270 cases where `addr:city` is incorrect.  These all appear
     to be cases where a building is served by a post office whose
     name differs from the surrounding municipality. These might be
     villages without a post office of their own, unincorporated
     Hamlets that do have their own post offices, or simply buildings
     that are served by a post office in a neighbouring community. They
     also include a few thousand changes that are respellings of the
     city name, in all cases to a version that OSM would prefer, for
     example, expanding 'St. James' to 'Saint James'.
     
   * 56,159 cases where `addr:street` is changed. Virtually all of these
     result from inappropriate discarding of name qualifiers.
     The source data had separate columns for the proper noun in a
     street name and the prefix and suffix qualifiers, which in turn
     were grouped into categories: directions, common nouns such as
     'Street' and adjectival words such as 'Old' or 'Extension'
     are all broken out separtely.  Thus, an address such as
     '37 Old State Route 29 West'  would show up incorrectly as
     `addr:housenumber=37 addr:street=29`. 
     
The 611 changes to `addr:housenumber` and 510 changes to `addr:postcode`
all appear to be changes related to the fact that I'm using a newer
version of the NYS address point data to do the repair. Updating
imported data to the current version should be mostly harmless. There
appear to be perhaps 200 addresses that also lost a qualifier in the
original import: '122A Main Street' and '122B Main Street' could
both show up as just `122`.

These numbers add up to more than the total of 127,559 remaining
affected buildings, because many buildings have more than one problem.

## Early study on changed city names - Suffolk County

(This commentary is out of date, because a much larger tranche
of questionable edits was discovered since this study. It should give
a good view, though, of the process used to analyze the data.)

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

## History

### Completion of the first-round code

On 2022-03-21, I pushed commits that appear to make the entire pipeline work,
and announced on `imports-us`, `talk-us`, and `talk-us-newyork` that
the import was ready for peer review. I uploaded a directory,
`sample_changesets`, that contains a bunch of randomly-selected
changesets from the process in support of the review. It also has a file,
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

### Application of sample changesets

Having heard no complaints about the proposed edit, on 2022-03-28 I
carefully vetted and uploaded ten changesets, and put the project
on pause for another week to await any changeset comments that might
appear, with a plan to commence the full repair two weeks later
on 2022-04-09.

A detailed summary of what has been uploaded so far:

#### [Changeset 119033831](https://www.openstreetmap.org/changeset/119033831):

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


#### [Changeset 119035063](https://www.openstreetmap.org/changeset/119035063)

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

#### [Changeset 119035973](https://www.openstreetmap.org/changeset/119035973)

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

#### [Changeset 119036136](https://www.openstreetmap.org/changeset/119036136)

   - `addr:city=Greenlawn` (206 buildings)
   
      Clusters of buildings in adacent communities of Huntington, Elwood
      and East Northport served from the Greenlawn post office.
      Postal city and ZIP code appear correct.
      
#### [Changeset 119037200](https://www.openstreetmap.org/changeset/119037200)

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

#### [Changeset 119037705](https://www.openstreetmap.org/changeset/119037705)

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
     
#### [Changeset 119038042](https://www.openstreetmap.org/changeset/119038042)

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

#### [Changeset 119038244](https://www.openstreetmap.org/changeset/119038244)

Just a handful of street name corrections:

| From                    | To                      | Count | Notes |
| ----------------------- | ----------------------- | ----- | ----- |
| Snyder                  | Snyder Road             | 5     | |
| Black Creek             | Black Creek Road        | 16    | |
| Dairy Hill              | Dairy Hill Road         | 18    | |
| Guideboard              | Guideboard Road         | 5     | |

#### [Changeset 119038500](https://www.openstreetmap.org/changeset/119038500)

Housenumbers 4265 and 4277 are transposed from the way they appear in
OSM data. This change appears to make them run out of sequence. I
suspect that may have something to do with the fact that both
buildings are off the highway on a service way named 'Rixs Lane' but
have addresses on 'Town Line Road', so they may be numbered in order
of construction or something.

#### [Changeset 119038596](https://www.openstreetmap.org/changeset/119038596)

Three housenumber changes. All appear to have been typos in an earlier
version of the NYSGIS data.
