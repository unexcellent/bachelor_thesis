= Literature Review <sec:literature-review>

== Different Earth-Orbits and their Use-Cases

Just like the gravitation on the ground, the Newtonian laws can be used to
describe the orbits of objects around the earth. Since man-made objects have
entered space in the 1950s, multiple orbits have emerged for different use cases
@hintz2015orbital.

=== Low Earth Orbit (LEO)

The orbit category closest to earth is the low earth orbit (LEO), which contains
objects orbiting between 160 km to 1,000 km from earth's surface. Its close
proximity to the ground is ideal for high resolution imaging, which is what it is
commonly used for. In recent years, low-latency satellite internet has emerged as
another use-case for LEO. However, large satellite constellations are needed to
provide large coverage over the earth, since a single satellite in LEO only
"sees" a very limited area of the earth's surface. Additionally, a large portion
of human spaceflight has been performed in LEO due to its short travel distance
from the ground (e.g. the International Space Station) @esa2020orbits.

One disadvantage of satellite operations in LEO is the presence of a residual
atmosphere. The earth's atmosphere is thin when compared to the surface, yet
dense enough to cause drag on objects. This drag effectively sets a limited
lifetime for satellites deployed to LEO, which depends on the orbit altitude.
Additionally, atmospheric density is influenced by solar sunspot activity which
leads to lower predictability of orbit lifetimes @sebestyen2019leo.

=== Medium Earth Orbit (MEO)

Orbits between 1,000 km and 35,000 km are categorized as medium earth orbits
(MEO). Just like LEO, MEO is used for a variety of different applications. The
most prominent might be navigation satellites like the European Galileo system
@esa2020orbits. One disadvantage of MEO is the significantly higher radiation
environment. This leads to MEO being significantly less attractive for human
space flight applications. Furthermore, space hardware is more likely to fail and
single event effects (e.g. bit flips) are more frequent requiring more redundancy
in the hardware @loffler2022romeo.

=== Geostationary Orbit (GEO)

In contrast to the other orbit types listed so far, geostationary orbit (GEO) is
very clearly defined. It is the set of orbits with an orbital period equal to
earth's sidereal day (approximately 23 h 56 min). This property constrains
GEO-orbits to an altitude of 35,786 km at a velocity of 3 km/s above the equator.
This leads to the orbiting objects being "fixed" above a single spot on earth.
That is especially advantageous for telecommunication and television applications
as a single satellite can reliably cover approximately one third of earth
@esa2020orbits. One drawback of satellites in GEO however is the high latency
caused by their large distance from earth of approximately 700 ms. This
significantly impacts internet applications in GEO @telesat2022latency.
