#import "@preview/acrostiche:0.7.0": acr

= Implementation

== Software Stack

The ESP32 as a widely adopted platform offers multiple programing languages to write the firmware. The main programing languages are:

- *C / C++*: C and C++ are the languages used by the official software development kit from Espressif Systems @espressif2026espidf. Therefore, they offer the largest amount of features and the most stable implementation.
- *Rust*: Rust offers modern ergonomics and prevents the majority of memory crashes via its compiler-enforced borrow-checker model @rust-vs-cpp.
- *Python*: Python can be used to program the ESP32 using the community developed MicroPython port @micropython.

After considering the advantages and disadvantages of different languages, Rust was chosen. MicroPython was disqualified due to large computational overhead @plauska2023evaluation. C / C++ was deemed too risky due to the manual memory management. Memory bugs in orbit would likely lead to an unrecoverable and undebuggable state. While low-level Rust is not entirely immune to memory bugs, the risk is significantly reduced. Therefore, Rust was chosen for the firmware.

== Software Architecture

- why split between beacon and sstv

== States

The system fundamentally acts as a state machine. The SSTV system stays in the idle state, listening for incoming commands and only switches once a valid command has been received. This shifts responsibility for triggering an overpass to the other satellite systems and the mission control team. It is expected that the SSTV system is only powered on when it is needed to conserve power.

#figure(
  image("../figures/imported/stm_sstv_system.svg", width: 100%),
  caption: [State machine diagram of the SSTV system],
)

Errors should get reported to the ground to aid in debugging the software. Rust's `Result` system supports this effort by making all failure states transparent and allowing for convenient reporting methods. In case of an error, the error identitfy is downlinked along with further information if present (e.g. chunk offset in case of an invalid update chunk).

=== Initialization

The initialization boots all peripheral devices and establishes a connection to the payload board.

#figure(
  image("../figures/imported/act_initialize.svg", width: 100%),
  caption: [Activity diagram of the initialization],
)

Two types of errors can occurr in the initialization state. A fatal error gets triggered the RS485 link to the payload board could not be established. Since this would prevent the SSTV system from communicating the failure, it forces a reboot immediately. Recoverable errors are ones that can be communicated. If one of the cameras fails for example, the intact one can still be used for the transmission.

After initialization is complete, a #acr("CSP") message is sent to the payload board announcing the availability of the SSTV system.

=== SSTV Transmission

The #acr("SSTV") transmission is the main functionality (?) of the firmware.

#figure(
  image("../figures/imported/act_transmit_sstv.svg", width: 100%),
  caption: [Activity diagram of the #acr("SSTV") transmission],
)

To maximize the scientific value of the system, the images are captured in direct succession. This should ensure that the transmitted images capture similar perspectives, even on a tumbling satellite. This could later be used to enhance the visible image with information in the infrared spectrum and vice-versa. If the second image was captured after the first image was transmitted, it would be pointed at an entirely different point on Earth.

A buffer of five seconds is used between the transmissions to allow ground station systems on Earth to process the image before the next one is transmitted.


=== Update Mechanism

Special attention was given to the update mechanism since a fatal bug could prevent any software changes in orbit or break the SSTV system entirely. The update needs to be split into multiple #acr("CSP") messages because of payload size limitations.

#figure(
  image("../figures/imported/stm_updating.svg", width: 100%),
  caption: [State machine diagram of the update mechanism],
)

If an update announcement is received while the update is in progress, the already received chunks get deleted and the update start from the beginning. This prevents the system from being stuck in a half-finished update. Alternatively, the update state can be exited by deliberately sending a package with a wrong offset.

If all chunks arrived as intended, the update only gets flashed in case the firmware can be validated by the official ESP32 update handler.
