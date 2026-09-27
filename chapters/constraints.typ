#import "@preview/acrostiche:0.7.0": acr
#import "../lib/template.typ": constraint, req

= Constraints

== Mission Context

=== Community Input

An #acr("SSTV") payload is fundamentally a service offered to the amateur satellite community. As such, its design should reflect the wishes of this stakeholder group. Therefore, a post @reddit-sstv-post was created in the r/amateursatellites subreddit describing the project and asking for feedback and input. The individual comments concerning the software are listed in @tab-community-input.

#figure(
  table(
    columns: 3,
    align: left,
    [*Input*], [*Authors*], [*Verdict*],
    [Encode the images via Robot 36],
    [ISpentAllMyMoneyOnPi, TacitMoose, tsgmob, Own_Event_4363],
    [Accepted into the requirements.],

    [Send via SSDV],
    [TRGFelix],
    [Rejected because decoding SSDV requires a more complex setup than SSTV @ukhas-ssdv, which just needs an FM radio and a smartphone running SSTV decoding software. However, this is a potential future feature.],

    [Use the payload to relay images between radio operators],
    [tsgmob],
    [Rejected due to the increased coordination and supervision effort needed to allow operators to upload their own images.],

    [Send pre-saved Images for Special Events],
    [Own_Event_4363],
    [Rejected due to increased complexity and memory requirements. However, this is a potential future feature.],
  ),
  caption: [Input from the amateur satellite community on the r/amateursatellites post, with author attributions and the verdict on whether the input is included in the software.],
) <tab-community-input>

=== Environmental Constraints

Besides the community input, the software should reflect the constraints of a satellite mission as listed in @tab-constraints.

#figure(
  table(
    columns: 2,
    align: left,
    [*Name*], [*Description*],

    [#constraint("MCU")],
    [The software runs on an unserviceable, memory-constrained microcontroller.],

    [#constraint("Commanding")],
    [The device is connected to a commanding link and commands are transmitted using the #acr("CSP").],

    [#constraint("Ground Link")],
    [The radio link from the ground station to the satellite is bandwidth-constrained.],

    [#constraint("Power")],
    [The system is powered by the host satellite and has to operate within a limited power budget.],
  ),
  caption: [Constraints for the software from the space environment.],
) <tab-constraints>

=== General Hardware

The constraints from @tab-constraints result in the minimal hardware structure shown in @img-ibd-general with the #acr("MCU") and an arbitrary number of cameras. Leaving the system are two connections, one carrying the #acr("CSP") messages for commands and the other carrying the audio samples using I2S.

#figure(
  image("../figures/imported/ibd_general.svg", width: 100%),
  caption: [Internal block diagram of the general system this software is designed for with the MCU, a commanding and an I2S connection out of the system and an arbitrary number of connected cameras.],
) <img-ibd-general>

== Requirements

Based on the mission context, the requirements on the system were collected in @tab-requirements.

#figure(
  table(
    columns: (3.5cm, auto, auto),
    align: left,
    [*Name*], [*Description*], [*Reasoning*],

    [#req("MCU")],
    [The software shall run on the ESP32-P4.],
    [Unlike the peripherals, the #acr("MCU") cannot reasonably be abstracted. The boot process, flash layout and update mechanism are device-specific. The ESP32-P4 fits the #acr("SSTV") payload as it includes interfaces for camera and audio control, has a low power draw and sufficient computing power for real-time #acr("SSTV") encoding @esp32p4-datasheet[p.~5].],

    [#req("Cameras")],
    [The software shall read the images from all connected cameras.],
    [The number and type of connected cameras can change between carriers. The software has to support every connected camera instead of a fixed amount.],

    [#req("Encoding")],
    [The software shall encode the images via Robot 36.],
    [Based on the community input in @tab-community-input.],

    [#req("Audio")],
    [The software shall output the audio samples via I2S.],
    [The #acr("SSTV") system does not access the radio hardware itself but transmits the audio signal to the connected system. I2S is a widely supported interface for transmitting audio samples @nxp-i2s[p.~2].],

    [#req("Commanding")],
    [The software shall trigger an #acr("SSTV") transmission when the corresponding command is received.],
    [Since radio downlinks draw a large amount of power, the #acr("SSTV") payload should only trigger a transmission if the operators deem the conditions favourable.],

    [#req("Camera Failure")],
    [If a camera encounters an error, the transmission of its corresponding image shall be skipped while the images of the working cameras shall be transmitted.],
    [Since the payload is unserviceable after deployment, hardware errors cannot be fixed. A fault in a single camera should still allow the rest of the system to function as intended.],

    [#req("Updates")],
    [The software shall be able to receive firmware updates via the commanding link.],
    [Bugs discovered in orbit can only be fixed by replacing the firmware remotely. Updates also allow adding features after launch.],

    [#req("Update Failure")],
    [A failed update shall not lead to an unrecoverable state.],
    [Ground-to-space radio links are unreliable. A fault in the update transmitted from the ground must not result in the loss of the #acr("SSTV") payload.],

    [#req("Error Communication")],
    [The software shall communicate any recoverable errors to the ground station.],
    [Debugging requires information about the nature of any error 'no #acr("SSTV") signal was received'.],

    [#req("Transmission Communication")],
    [The software shall communicate when an SSTV transmission starts and ends.],
    [The host system routes the audio signal to the radio hardware. Communicating the start and end of a transmission allows it to power the energy-hungry radio devices only while they are actually needed.],

    [#req("Size")],
    [All bytes transmitted for an update shall be less than 790.21 kB.],
    [If the firmware cannot be transmitted within a single overpass, the update state has to persist across multiple ground station contacts. This introduces additional error paths like the ground station losing track of the last received chunk. This limit of 790.21 kB is 50% of the data volume available for uplink on MOVE-IIIa via #acr("UHF") on an average overpass @move-iiia-cdr[p.~10] giving it a sizeable margin for error. Since this calculation is based on a #acr("UHF") link and satellite missions increasingly move to bands with higher data rates (such as S-band, X-band and Ka-band) @nasa-soa[p.~245], this is considered a reasonable assumption for other missions implementing this software.],
  ),
  caption: [Requirements for the software.],
) <tab-requirements>

== MOVE-IIIa Carrier

The MOVE-IIIa #acr("SSTV") payload runs a member of the software family described in this thesis, with two cameras connected – one for the visible and one for the infrared spectrum. Commanding is handled via RS422 which requires the use of a specialized transceiver component. The hardware setup is illustrated in @img-ibd-move-iiia and the pin mapping is shown in @tab-gpio.

#figure(
  image("../figures/imported/ibd_move_iiia.svg", width: 100%),
  caption: [Internal block diagram of the MOVE-IIIa SSTV system with the MCU (ESP32-P4), the RGB Camera (SC850SL), the thermal camera (MI1602) and the RS422 transceiver (THVD1424).],
) <img-ibd-move-iiia>

#figure(
  table(
    columns: 4,
    align: left,
    [*GPIO*], [*Connected to*], [*Label*], [*Purpose*],
    [9], [SC850SL], [SCL], [I2C bus clock],
    [11], [SC850SL], [SDA], [Camera register configuration],
    [12], [MI1602], [SDA], [Register control],
    [15], [MI1602], [SCL], [MIPI-CSI bus clock],
    [20], [I2S], [MCLK], [Master clock],
    [21], [I2S], [BCLK], [Bit clock],
    [22], [I2S], [DOUT], [Serial audio sample data],
    [23], [I2S], [WS], [Word select],
    [28], [MI1602], [SCLK], [SPI2 clock for frame readout],
    [29], [MI1602], [MISO], [SPI2 data input],
    [30], [MI1602], [MOSI], [SPI2 data output],
    [31], [MI1602], [SSN], [SPI2 slave select],
    [37],
    [THVD1424],
    [RX],
    [Receives #acr("CSP") messages from the payload board],

    [38],
    [THVD1424],
    [TX],
    [Transmits #acr("CSP") messages to the payload board],

    [39], [THVD1424], [DE], [Enables sending via RS422 (permanently held high)],
    [54], [SC850SL], [XSHUTDN], [Shutdown / reset],
  ),
  caption: [ESP32-P4 pin mapping for the MOVE-IIIa SSTV payload.],
) <tab-gpio>
