= Analysis <sec:analysis>

== Drag on Low Earth Orbit Satellites

Aerodynamic properties are usually a consideration for objects on the surface of
the earth or aircraft. However, as earth's atmosphere decreases exponentially
with increasing altitude, there is in theory no limit to its expanse
@palmroth2021lti. In practice, this has implications to spacecraft in low earth
orbit (LEO) @zheng_satdrag.

In general, atmospheric drag is a factor for objects with an altitude below
1,000 km, which incidentally matches the boundary of LEO. This height is also
classified as the thermosphere. Just like in any other atmospheric layer, the
drag force is characterized by the following equation.

$ F = 1/2 rho A C v^2 $ <eq:drag>

However, in the thermosphere the density $rho$ is primarily characterized by the
temperature. This layer of the atmosphere can reach up to 1400 K due to the
absorption of ultra-violet radiation and particles from the sun. This makes the
atmospheric drag in LEO highly correlated to the solar activity @zheng_satdrag.

From a satellite operations standpoint, the force generated from the thermosphere
drag can induce an unpredictable moment, that needs to be compensated
@markley2014attitude. Drag also effectively limits the lifetime of objects in LEO
as they lose potential energy to the thermosphere decreasing their altitude.
Depending on the initial orbit, the area and shape of an object, they can have a
lifespan from a few days to over 1,000 years. A typical satellite in LEO has a
lifespan between 7 and 10 years, however @stewart2024leo. The International Space
Station (ISS) for instance orbits at 400 km above the ground and experiences an
average drag force of approximately 0.25 N resulting in a loss of around 100 m of
altitude per day @esa_atv.

Drag in LEO not only poses challenges, however. As described by @eq:drag, it can
also be used to intentionally change a satellite's orbit. This is especially
useful for small spacecraft (like CubeSats), since they usually have no onboard
thrust system. Instead, the attitude control system can be used to change the
spacecraft's cross-sectional area and drag coefficient to precisely change the
drag force. Large solar panels can act as drag sails with a cross-sectional area
highly dependent on the attitude @cappelletti2020cubesat. Differential drag can
also be used to control satellite constellations. In cases where groups of
satellites are launched into the same orbit, they are usually deployed in
relative proximity to each other by a single launch vehicle. Usually this
proximity does not represent the target distribution of the constellation.
Instead of using thrust systems to separate the satellites, the drag force can be
used by precisely controlling the attitude of each spacecraft @foster2018differential.

== Radiation Exposure on Astronauts and How to Mitigate It

Humans evolved to survive and thrive on Earth. The space environment presents
itself as dangerous and deadly in almost every regard, requiring elaborate life
support systems onboard human spacecraft to enable survivability. The most
damaging factor is the constant radiation exposure, that needs to be addressed to
make humans survive space @seedhouse2020life.

=== Sources of Radiation

Radiation experienced near to Earth can be categorized into two categories
depending on its origin: solar particle radiation and galactic cosmic rays. The
sun emits alpha particles, electrons and protons at near light-speed velocities
in regular mass ejections. The intensity roughly follows the sun's 11-year cycle
with 4 years of solar minimum and 7 years of solar maximum, although individual
ejection events are not reliably predictable. Radiation from outside the solar
system is mostly comprised of protons and alpha particles with a small percentage
of larger atomic nuclei. These originate from distant super novae and therefore
possess incredibly high energy compared to solar particles @seedhouse2020life.

=== Biological Effects

Unlike other environmental factors, the human body can not adapt to high
radiation doses. High energy particles can pass through the skin and damage the
DNA at any point of the body. Cells with damaged DNA may die or begin to mutate.
Short-term effects include impairment of the central nervous system with symptoms
usually associated with Alzheimer's and inflammations. Long-term exposure
increases the risk of developing cancers, which are more aggressive than ordinary
tumors @seedhouse2020life.

=== Mitigation Strategies

As has become apparent, the mitigation of radiation effects requires blocking the
particles before they can damage the human body. One method of shielding
astronauts is including materials into the walls of spacecrafts and habitats,
that have a high chance of blocking particles. Aluminum is already widely used in
aerospace and has a comparatively high density. However, when aluminum is hit by
high energy particles secondary radiation can occur from neutrons and ions
expelled from the material. Hydrogen can also be used in molecules like
polyethylene or lithium hydride @gohel2022shielding. For long-term habitats on
the moon shipping radiation shielding from Earth is impractical. Therefore, NASA
plans to use the lunar regolith with a significant thickness to increase the
chance of blocking rays @simonsen1991radiation.

Another approach on mitigating radiation is active shielding. This in a sense
mimics the protective properties of Earth's magnetic field. Active shielding
could potentially redirect those high energy particles, that multiple meters of
passive shielding can not reliably stop. The issue with this approach however is
scaling, as the total energy required to maintain a sufficient field strength is
far beyond the capabilities of spacecraft or human habitats @battiston2012arssem.
