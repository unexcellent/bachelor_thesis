= Constraints

This chapter describes the process that preceded the software implementation in which the fundamental goal of the project and the needs of the different stakeholders were analysed.

== Hardware Constraints

The fundamental output of this thesis is a firmware which deeply interacts with the underlying hardware. Although the hardware design is out of scope for this thesis, the resulting architecture still needs to be described to explain the design decisions.

#figure(
  image("../generated/hardware-global.svg", width: 100%),
  caption: [Internal block diagram of the relevant satellite parts],
)

#figure(
  image("../generated/hardware-sstv.svg", width: 100%),
  caption: [Internal block diagram of the SstvSystem],
)

#figure(
  table(
    columns: 4,
    align: left,
    [*GPIO*], [*Connected to*], [*Label*], [*Purpose*],
    [9], [SC850SL], [SCL], [I2C bus clock],
    [11], [SC850SL], [SDA], [camera register configuration],
    [12], [MI1602], [SDA], [Register control],
    [15], [MI1602], [SCL], [MIPI-CSI bus clock],
    [20], [PCM5102A], [MCLK], [Master clock],
    [21], [PCM5102A], [BCLK], [Bit clock],
    [22], [PCM5102A], [DOUT], [Serial audio sample data],
    [23], [PCM5102A], [WS], [Word select],
    [28], [MI1602], [SCLK], [SPI2 clock for frame readout],
    [29], [MI1602], [MISO], [SPI2 data input],
    [30], [MI1602], [MOSI], [SPI2 data output],
    [31], [MI1602], [SSN], [SPI2 slave select],
    [37], [THVD1424], [RX], [Receives CSP messages from the payload board],
    [38], [THVD1424], [TX], [Transmits CSP messages to the payload board],
    [39], [THVD1424], [DE], [Enables sending via RS485. Permanently held high],
    [54], [SC850SL], [XSHUTDN], [Shutdown / reset],
  ),
  caption: [ESP32-P4 pin mapping],
)

== Mission Constraints

#figure(
  image("../generated/use-case.svg", width: 80%),
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

    [Enable Image Relay via VHF],
    [tsgmob],
    [Rejected because the hardware does not allow VHF uplink],

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
