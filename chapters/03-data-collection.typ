= Data Collection <sec:data-collection>

== Considerations for Using COTS Parts in CubeSats

The space environment offers unique challenges compared to the usual use-cases of
COTS parts. Firstly, maintenance of components after launch is impossible for all
practical purposes, which leads to increased reliability requirements. Other
factors include radiation, vacuum exposure and vibration loads, which will be
discussed in the following paragraphs. These need to be tested for to ensure the
usability of every COTS-part @budroweit2021risk.

=== Vacuum and Outgassing

One of the most unique properties of space is the lack of an atmosphere to a
degree that is hard to replicate on earth. In consequence, atmospheric pressure
is not a common consideration for COTS parts manufacturers. Parts that rely on
internal gasses or liquids therefore are rarely suitable for space applications.
Even solid materials can degrade due to vacuum in a process called outgassing,
where condensable molecules escape from the material @cappelletti2020cubesat.

=== Vibration and Launch Loads

Any unpowered satellite will only experience significant linear acceleration
during launch. This produces stability requirements that are directly opposed to
the weight optimization efforts to minimize launch costs @sebestyen2019leo.

=== Radiation

Radiation sharply increases with altitude. This can degrade hardware in the
long-term and be a significant factor in the lifespan of spacecraft systems.
Furthermore, integrated circuits are vulnerable to bit flips @sebestyen2019leo.
