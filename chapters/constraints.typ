#import "@preview/acrostiche:0.7.0": acr

= Constraints

This chapter describes the process that preceded the software implementation in which the fundamental goal of the project and the needs of the different stakeholders were analysed.

== Hardware

The fundamental output of this thesis is a firmware which deeply interacts with the underlying hardware. Although the hardware design is out of scope for this thesis, the resulting architecture still needs to be described to explain the design decisions.

In the global satellite architecture, the SSTV system is only connected to the payload board which in turn handles transmission via the #acr("VHF") spectrum and communication with the ground station.

#figure(
  image("../figures/imported/ibd_satellite.svg", width: 100%),
  caption: [Internal block diagram of the satellite hardware (only the relevant parts)],
)

Within the SSTV system, the #acr("MCU") is the component running the software subject in this thesis and responsible for communicating with the payload board, fetching images from the cameras, processing them into #acr("SSTV") audio samples and sending those samples back to the payload board.

#figure(
  image("../figures/imported/ibd_sstv_system.svg", width: 100%),
  caption: [Internal block diagram of the SSTV system hardware (only the relevant parts)],
)

A table mapping the GPIO pins of the #acr("MCU") can be found in table @tab-gpio.


== Commands

#figure(
  table(
    columns: 4,
    align: left,
    [*Name*], [*Port*], [*Payload*], [*Description*],
    [Ping],
    [1],
    [Any],
    [Standard #acr("CSP") ping which should trigger a response echoing the received payload],

    [SSTV Trigger],
    [11],
    [Any payload starting with the string "SSTV"],
    [Triggers the SSTV transmission],

    [Update Announcement],
    [10],
    [Starting with a 0x00 byte followed by the data chunk size as an unsigned 16 bit integer],
    [Announce a firmware update],

    [Update Begin],
    [10],
    [Starting with a 0x01 byte followed by the total update size as an unsigned 32 bit integer],
    [Begin the firmware update],

    [Update Chunk],
    [10],
    [Starting with a 0x02 byte followed by the chunk offset as an unsigned 32 bit integer and the firmware bytes of that chunk],
    [Part of the new firmware],

    [Update End], [10], [Just a 0x03 byte], [Announce that the update is done],
  ),
  caption: [#acr("CSP") commands receivable by the SSTV system],
)


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

    [Enable Image Relay via #acr("VHF")],
    [tsgmob],
    [Rejected because the hardware does not allow #acr("VHF") uplink],

    [Send pre-saved Images for Special Events],
    [Own_Event_4363],
    [Rejected for the initial software due to increased complexity and memory requirements. However, this might be added in a future version],
  ),
  caption: [Input from amateur satellite community with verdict],
)


== Requirements

The above constraints and inputs translate into the following list of requirements.

#figure(
  table(
    columns: 2,
    align: left,
    [*ID*], [*Description*],
    [req0],
    [The software should be able to take an image in the visible light spectrum],

    [req1],
    [The software should be able to take an image in the infrared light spectrum],

    [req2], [The software should encode the images to tones via Robot 36C],
    [req3],
    [The software should transmit tones as samples to the payload board],

    [req4],
    [The software should trigger the SSTV transmission if a command is received via RS485],

    [req5], [The software should be updateable via RS485],
    [req6],
    [The firmware size should be small enough to allow transmitting the entire binary within a single overpass],

    [req7], [The software should keep idle power below 0.1 W],
  ),
  caption: [Requirements for the software],
)
