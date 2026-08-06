= Planning

This chapter describes the process that preceded the software implementation in which the fundamental goal of the project and the needs of the different stakeholders were analysed.

== Community Input

The secondary payload of MOVE-IIIa is fundamentally a service offered to the amateur satellite community. As such, its design should reflect the wishes of this stakeholder group. Therefore, it was decided that a post#footnote[link to the post: #link("https://www.reddit.com/r/amateursatellites/comments/1s6255m/i_am_building_the_sstv_payload_for_a_satellite/")] should be created in the r/amateursatellites subreddit describing the project and asking for feedback and inputs. The individual points concerning the software are listed in the following table.

#figure(
  table(
    columns: 3,
    align: left,
    [*Input*], [*Authors*], [*Verdict*],
    [Encode the Images via Robot 36C],
    [ISpentAllMyMoneyOnPi, TacitMoose, tsgmob, Own_Event_4363],
    [Accepted into the requirements],

    [Send via SSDV],
    [TRGFelix],
    [Rejected because decoding SSDV requires a more complex setup than SSTV, which just needs an FM radio and a smartphone running SSTV decoding software],

    [Enable Image Relay via VHF],
    [tsgmob],
    [Rejected because the hardware does not allow VHF uplink],

    [Send pre-saved Images for Special Events],
    [Own_Event_4363],
    [Rejected for the initial software due to increased complexity and memory requirements. However, this might be added in a future version],
  ),
  caption: [Input from amateur satellite community with verdict],
)

== Hardware Description

The fundamental output of this thesis is a firmware which deeply interacts with the underlying hardware. Although the hardware design is out of scope for this thesis, the resulting architecture still needs to be described to explain the design decisions.


== Use-Case Analysis

#figure(
  image("../generated/use-case.svg", width: 80%),
)

== Requirements

- updatetable within a single overpass
- keep idle power below 0.1 W
- allow commanding via CSP messages
- take images from both an RGB and Thermal camera
- encode to Robot 36 SSTV
- send down via VHF
- stay within channel
- send full-resolution images via SBand

