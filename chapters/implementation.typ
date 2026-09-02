#import "@preview/acrostiche:0.7.0": acr

= Implementation

== Language Selection

The ESP32 as a widely adopted platform offers multiple programing languages to write the firmware. The main candidate languages are:

- *C / C++*: C and C++ are the languages used by the official software development kit from Espressif Systems @espressif2026espidf.
- *Rust*: Rust offers modern ergonomics and prevents the majority of memory crashes via its compiler-enforced borrow-checker model @rust-vs-cpp.
- *Python*: Python can be used to program the ESP32 using the community developed MicroPython port @micropython.

To keep the decision objective, the language was selected through a weighted-criteria analysis. A set of assessment criteria was derived from the requirements in @tab-requirements and weighted according to their impact on the mission before any language was assessed. The weights reflect that the firmware runs on a resource-constrained microcontroller that cannot be physically serviced once in orbit. Each candidate was then scored from one (poor) to five (excellent) against every criterion and the weighted sum determined the outcome. The criteria and their weights are listed in @tab-lang-criteria and the resulting scores in @tab-lang-scores.

#figure(
  table(
    columns: (auto, auto, 1fr),
    align: (left, center, left),
    [*Criterion*], [*Weight*], [*Explanation*],

    [Memory safety & fault tolerance],
    [0.30],
    [A memory bug in orbit would likely lead to an unrecoverable and undebuggable state.],

    [Runtime performance],
    [0.20],
    [Robot 36C encoding (req3) and the continuous I2S sample output (req4) are soft-real-time and must not fall behind.],

    [Memory & flash footprint],
    [0.20],
    [The binary must be small enough to be uplinked within a single overpass (req7) and RAM is scarce on the #acr("MCU").],

    [Toolchain & ecosystem maturity],
    [0.15],
    [The software must run on the ESP32-P4 (req0); this covers peripheral libraries, hardware abstraction and debugging support for that specific target.],

    [Error handling & concurrency],
    [0.15],
    [Command dispatch (req5) and the update flow (req6) require explicit, non-silent error paths so faults can be reported to the ground.],
  ),
  caption: [Assessment criteria for the firmware language and their weights],
) <tab-lang-criteria>

#figure(
  table(
    columns: 4,
    align: (left, center, center, center),
    [*Criterion*], [*C / C++*], [*Rust*], [*MicroPython*],

    [Memory safety & fault tolerance],
    [2 @miller2019proactive],
    [5 @xu2021rustcve],
    [4 @micropython],

    [Runtime performance],
    [5 @plauska2023evaluation],
    [5 @plauska2023evaluation],
    [1 @plauska2023evaluation],

    [Memory & flash footprint],
    [5 @plauska2023evaluation],
    [4 @plauska2023evaluation],
    [2 @plauska2023evaluation],

    [Toolchain & ecosystem maturity],
    [5 @espressif2026espidf],
    [3 @rust-on-esp],
    [3 @micropython],

    [Error handling & concurrency], [2], [5 @rust-book], [3],

    [*Weighted total*], [*3.65*], [*4.50*], [*2.70*],
  ),
  caption: [Weighted scores of the candidate languages (1 = poor, 5 = excellent)],
) <tab-lang-scores>

With a weighted total of 4.50, Rust was chosen for the firmware. MicroPython is ruled out by its computational overhead and footprint @plauska2023evaluation. C / C++ scores well on ecosystem and footprint but is held back by manual memory management, which causes the majority of security-relevant errors @miller2019proactive. While low-level Rust is not entirely immune to memory bugs, they are confined to explicitly marked `unsafe` code, significantly reducing the risk @xu2021rustcve.

== Software Architecture

The decision was made to split the functionality in this code into two libraries (also called crates in the Rust ecosystem):

- *sstv*: The `sstv` crate handles encoding the images into the audio samples while being compatible with microcontroller architectures. To provide further value to the community, it was decided to also implement most other modes from the Dayton paper @daytona-paper, decoding of those modes and support file based encoding and decoding. The crate has been made available via Rust's default package registry crates.io#footnote("https://crates.io/crates/sstv").
- *beacon*: `beacon` is both the compiled firmware running on the SSTV system and a crate providing interfaces for third-party systems to benefit from the work done in this thesis.

Extracting the #acr("SSTV") logic has the benefit of providing the community with a focused crate with a much broader target group than people interested to build their own SSTV payload. And since `beacon` also imports it as a dependency, it validates the public interface.

=== SSTV Architecture

The core responsibility of the `sstv` crate is encoding an image into audio samples which are then transmitted using `beacon`. Because this has to run on a microcontroller with low memory, the crate is `no_std` meaning it does not depend on Rust's standard library and can therefore be compiled for the ESP32 without an operating system underneath.

The `no_std` constraint also shapes how the algorithm is designed. Rather than buffering the audio samples, the encoding path is built from iterators that each consume the previous stage on demand.

The encoding pipeline consumes an iterator of `RgbPixel` into the `Encoder` struct which yields a stream of `Tone`s defined by a frequency and a duration. A `Synthesizer` then turns every `Tone` into a 16 bit audio sample.

Due to the iterator design, only a fraction of the transmission is ever held in memory before it is passed on. This allows `beacon` to transmit an image without ever materializing the full audio signal which keeps the memory footprint small enough for a microcontroller.

=== Beacon Architecture <sec-beacon-architecture>

`beacon` is fundamentally built around a recurring pattern separating the reusable logic from the mission-specific hardware. The logic was made reusable by Rust's trait system, which lets the developer define interfaces to be used in the TODO. The MOVE-IIIa specific firmware, which defines the concrete pins and peripherals unique to the hardware, then implement those interfaces in an isolated module making MOVE-IIIa a carrier variant of the crate rather than a fork of it.

As a consequence, `beacon` offers multiple abstraction layers targeting different third-party users. A user can call the firmware at the top level and only swap out individual devices, or replace whole subsystems while reusing the orchestration logic.

- *Public entry points*: The behaviour of the firmware is reachable through the three public functions `idle()`, `transmit_sstv()` and `updating()`. They encapsulate the entire runtime behaviour, so a third-party system can implement the crate without reimplementing the control flow.
  - *Freedoms provided to the third party*: The entry points are generic via the traits, which allows hardware substitution.
    - Custom cameras can be implemented behind the `Camera` trait
    - The system allows any number of cameras to be operated
    - A custom audio output device can be implemented behind the `AudioChannel` trait
    - A custom commanding link can be implemented behind the `CommandLink` trait
  - *Fixed Assumptions*: However, some assumptions about the third party system were made limiting flexibility.
    - The set of receivable commands stays the same
    - The set of transmitted messages is fixed
    - Images are encoded using the Robot 36C mode
    - The entry points are blocking and terminal by nature, as `idle()` never returns
    - The firmware runs on the ESP32
- *Device implementations*: In addition, the specific devices used in MOVE-IIIa were implemented separately from the hardware interface commucating with them allowing third parties to reuse the devices outside of the ESP32 ecosystem. For example, the implementations of the SC850SL and MI48Dx cameras can be used in any embedded project even outside of the #acr("SSTV") domain.

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
