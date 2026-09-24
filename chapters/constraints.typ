#import "@preview/acrostiche:0.7.0": acr
#import "../lib/template.typ": constraint, req

= Constraints

== Mission Context

=== Community Input

An #acr("SSTV") payload is fundamentally a service offered to the amateur satellite community. As such, its design should reflect the wishes of this stakeholder group. Therefore, it was decided that a post @reddit-sstv-post should be created in the r/amateursatellites subreddit describing the project and asking for feedback and inputs. The individual points concerning the software are listed in @tab-community-input.

#figure(
  table(
    columns: 3,
    align: left,
    [*Input*], [*Authors*], [*Verdict*],
    [Encode the images via Robot 36C],
    [ISpentAllMyMoneyOnPi, TacitMoose, tsgmob, Own_Event_4363],
    [Accepted into the requirements.],

    [Send via SSDV],
    [TRGFelix],
    [Rejected because decoding SSDV requires a more complex setup than SSTV @ukhas-ssdv, which just needs an FM radio and a smartphone running SSTV decoding software.],

    [Use the payload to relay images between radio operators],
    [tsgmob],
    [Rejected due to the increased coordination and supervision effort needed to allow operators to upload their own images.],

    [Send pre-saved Images for Special Events],
    [Own_Event_4363],
    [Rejected due to increased complexity and memory requirements.],
  ),
  caption: [Input from amateur satellite community from the post to the r/amateursatellites subreddit with author attributions and verdict reached if the input will be included in the software.],
) <tab-community-input>

=== Environmental Constraints

Besides the community input, the software should reflect the constraints of a satellite mission as listed in @tab-constraints.

#figure(
  table(
    columns: 2,
    align: left,
    [*Name*], [*Description*],

    [#constraint("MCU")],
    [The software runs on an unservicable, memory-constrained microcontroller without and operating system.],

    [#constraint("Cameras")], [At least one camera is connected to the microcontroller.],

    [#constraint("Audio")], [The audio should be output as a continuous stream of samples.],

    [#constraint("Commanding")],
    [The device is connected to a commanding link and commands are transmitted using the #acr("CSP").],

    [#constraint("Ground Link")],
    [The radio link from the ground station to the satellite is bandwidth constrained.],
  ),
  caption: [Constraints for the software from the space environment.],
) <tab-constraints>

=== General Hardware

The constraints from @tab-constraints result into the minimal hardware structure shown in @img-ibd-general with the #acr("MCU") and an arbitrary amount of cameras. Leaving the system are two connections, one carrying the #acr("CSP") messages for commands and the other transmits the audio samples using I2S.

#figure(
  image("../figures/imported/ibd_general.svg", width: 100%),
  caption: [Internal block diagram of the general system this software is designed for with the #acr("MCU"), a commading and an I2S connection out of the system and an arbitrary number of connected cameras.],
) <img-ibd-general>

== Requirements

Based on the mission context, the requirements on the system were collected in @tab-requirements

#figure(
  table(
    columns: 3,
    align: left,
    [*Name*], [*Description*], [*Reasoning*],

    [#req("MCU")],
    [The software shall run on the ESP32-P4.],
    [Unlike the peripherals, the #acr("MCU") can not reasonably be abstracted. The boot process, flash layout and update mechanism are device specific. The ESP32-P4 fits the #acr("SSTV") payload as it includes interfaces for camera and audio control, has a low power draw and enough compute for real-time #acr("SSTV") encoding.],

    [#req("Cameras")],
    [The software shall read the images from all connected cameras.],
    [Capturing images is the purpose of the payload. Since the number and type of connected cameras changes between missions, the software has to support every connected camera instead of a fixed set.],

    [#req("Encoding")],
    [The software shall encode the images via Robot 36C.],
    [Based on the community input in @tab-community-input.],

    [#req("Audio")],
    [The software shall output the audio samples via I2S.],
    [The #acr("SSTV") system does not access the radio hardware itself but transmits the audio signal to the connected system. I2S is a widely supported interface for transmitting audio samples.],

    [#req("Commanding")],
    [The software shall trigger an #acr("SSTV") transmission if the corresponding command has been received.],
    [Since radio downlinks draw a large amount of power, the #acr("SSTV") payload should only trigger a transmission if the operators deem the conditions favorable.],

    [#req("Camera Failure")],
    [If a camera encounters an error, the transmission of its corresponding image shall be skipped while the image of the working cameras shall be transmitted.],
    [Since the payload is unservicable after deployment, any hardware error can not be fixed. A fault in a single camera should still allow the rest of the system to function as intended.],

    [#req("Updates")],
    [The software shall be able to receive firmware updates via the commanding link.],
    [Since the payload is unservicable after deployment, bugs discovered in orbit can only be fixed by replacing the firmware remotely. Updates also allow adding features after launch.],

    [#req("Update Failure")],
    [A failed update shall not lead to an unrecoverable state.],
    [Ground to space radio links are unreliable. Since the payload is unservicable after deployment, a fault in the update transmitted from the ground can not result in the loss of the #acr("SSTV") payload.],

    [#req("Error Communication")],
    [The software shall communicate any recoverable errors to the ground station.],
    [Debugging requires information about the nature of any error beyond "no #acr("SSTV") signal was received".],

    [#req("Transmission Communication")],
    [The software shall communicate when an SSTV transmission starts and ends.],
    [The host system routes the audio signal to the radio hardware. Communicating the start and end of a transmission allows it to power the energy-hungry radio devices only while they are actually needed.],

    [#req("Size")],
    [The firmware shall be transmittable over the mission's command link within a single overpass.],
    [If the firmware can not be transmitted within a single overpass, the update state has to remain across multiple ground station contacts. This introduces additional error paths like the ground station losing track of the last received chunk.],
  ),
  caption: [Requirements for the software],
) <tab-requirements>

== MOVE-IIIa Variant

The MOVE-IIIa #acr("SSTV") payload runs a family member of the software described in this thesis where two cameras are connected - one for the visual and one for the infrared color spectrum. Commanding is handled via RS485 which requires the use of a specialized transceiver component. The hardware setup is illustrated in @img-ibd-move-iiia and the pin mapping is shown in <tab-move-iiia-pins>

#figure(
  image("../figures/imported/ibd_move_iiia.svg", width: 100%),
  caption: [Internal block diagram of the MOVE-IIIa #acr("SSTV") system with the MCU (ESP32-P4), the RGB Camera (SC850SL), the thermal camera (MI1602) and the RS485 transceiver (THVD1424).],
) <img-ibd-move-iiia>

#figure(
  table(
    columns: 4,
    align: left,
    [*GPIO*], [*Connected to*], [*Label*], [*Purpose*],
    [9], [SC850SL], [SCL], [I2C bus clock],
    [11], [SC850SL], [SDA], [camera register configuration],
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
    [37], [THVD1424], [RX], [Receives CSP messages from the payload board],
    [38], [THVD1424], [TX], [Transmits CSP messages to the payload board],
    [39], [THVD1424], [DE], [Enables sending via RS485. Permanently held high],
    [54], [SC850SL], [XSHUTDN], [Shutdown / reset],
  ),
  caption: [ESP32-P4 pin mapping for the MOVE-IIIa SSTV payload.],
) <tab-gpio>
