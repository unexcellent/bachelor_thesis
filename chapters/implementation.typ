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
    [*Criterion*], [*Weight*], [*Reasoning*],

    [Memory safety & fault tolerance],
    [0.30],
    [A memory bug in orbit would likely lead to an unrecoverable and undebuggable state, violating the @req-update-failure.],

    [Runtime performance],
    [0.20],
    [Robot 36C encoding (@req-encoding) and the continuous I2S sample output (@req-audio) are soft-real-time and must not fall behind.],

    [Memory & flash footprint],
    [0.20],
    [The binary must be small enough to be uplinked within a single overpass (@req-size) and RAM is scarce on the #acr("MCU").],

    [Toolchain & ecosystem maturity],
    [0.15],
    [The software must run on the ESP32-P4 (@req-mcu) and interface with its peripherals such as the cameras (@req-cameras). This covers peripheral libraries, hardware abstraction and debugging support for that specific target.],

    [Error handling & concurrency],
    [0.15],
    [Degraded camera operation (@req-camera-failure) and the update flow (@req-updates) require explicit, non-silent error paths so faults can be reported to the ground (@req-error-communication).],
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

== Commands

The commanding is used to control the SSTV system via the RS485 link to the payload board. Commands are encoded as #acr("CSP") messages and can originate from any board on the satellite bus or the ground station. The commands were originally specified for the MOVE-IIIa mission. However, `beacon` defines them for all carriers since its functions can only implement the entire control flow if the commands are known in advance. Because no command contains any MOVE-IIIa specific behavior, the set could be adopted for the whole software family. Only the transport of the commands is left to the carrier.

#figure(
  table(
    columns: 4,
    align: left,
    [*Name*], [*#acr("CSP") Port*], [*Payload*], [*Description*],
    [Ping],
    [1],
    [Any],
    [Standard #acr("CSP") ping which should trigger a response echoing the received payload],

    [SSTV Trigger],
    [11],
    [Any payload starting with the string "SSTV"],
    [Commands the SSTV system to capture the images and transmit them via the audio channel],

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
) <tab-commands>

== Software Architecture

To maximise the value this thesis provides to the #acr("SSTV") community, it was decided to split the resulting software into multiple packages (also called crates in the Rust ecosystem) where each crate targets a different user group. The crates are depicted in @img-pkg-software.

#figure(
  image("../figures/imported/pkg_software.svg", width: 100%),
  caption: [Package diagram for the SSTV system depicting the relationship between `sstv`, `beacon`, `beacon-on-moveiiia` and `beacon-on-tab5`.],
) <img-pkg-software>

The `sstv` crate isolates pure encoding and decoding functionality without any dependence on the specific hardware running the algorithms. In fact, the goal of the crate is to be maximally hardware agnostic to ensure compatibility with a wide array of systems. Beyond the Robot 36C mode required by this thesis, it implements most other modes from the Dayton paper @daytona-paper, supports decoding as well as encoding and has been published to Rust's default package registry crates.io#footnote("https://crates.io/crates/sstv"). No other crate in the Rust ecosystem with such a premise has existed before, requiring the creation of `sstv` in the first place. Since only the Robot 36 encoding logic is used by the downstream packages in this thesis, no other functionality of `sstv` will be discussed.

`beacon` contains the modular functions, traits and structs for running the #acr("SSTV") logic on a satellite payload. It forms the shared core of the software family. Every variant imports it and provides only the implementations for its specific hardware.

`beacon-on-moveiiia` represents the carrier running on the MOVE-IIIa #acr("SSTV") payload and imports `beacon` for its own implementation.

`beacon-on-tab5` is another member of the software family importing `beacon` used for validation on an additional ESP32-P4 device. This crate will be discussed in the verification section.

== `sstv` Crate Implemenation

The core responsibility of the `sstv` crate in the context of this thesis is encoding an image into audio samples. Because this has to run on a microcontroller with low memory, the crate is `no_std` meaning it does not depend on Rust's standard library and can therefore be compiled for the ESP32 without an operating system underneath.

The `no_std` constraint also influences how the algorithm is designed. Rather than buffering the audio samples, the encoding path is built from iterators that each consume the previous stage on demand as depicted in @img-ibd-sstv-crate.

#figure(
  image("../figures/imported/ibd_sstv_crate.svg", width: 100%),
  caption: [Internal block diagram of the `sstv` crate's encoding path with the `Encoder`, the `Synthesizer` and the flowitems passed between them.],
) <img-ibd-sstv-crate>

The encoding pipeline consumes an iterator of `RgbPixel` into the `Encoder` struct which yields a stream of `Tone`s defined by a frequency and a duration. A `Synthesizer` then turns every `Tone` into a 16 bit audio sample. Due to the iterator design, only a fraction of the transmission is ever held in memory before it is passed on. This allows `beacon` to transmit an image without ever buffering the full audio signal which keeps the memory footprint small enough for a microcontroller. @list-sstv-encoding shows how a user would implement the `sstv` encoding pipeline.

#figure(
  ```rust
  let pixels = ...; // source of the image as an iterator over each pixel
  let encoder = Encoder::new(Mode::Robot36, pixels)?;
  for sample in Synthesizer::new(encoder, SAMPLE_RATE) {
      ... // output of each sample
  }
  ```,
  caption: [Example of how a user would implement the `sstv` encoding pipeline with `...` representing placeholders for device-specific code.],
) <list-sstv-encoding>

The `Encoder` itself only ever buffers two rows of 320 `RgbPixel` each which converted to YUV, averaged over the two lines, converted into a frequency and then emitted as depicted in @img-act-encoder.

#figure(
  image("../figures/imported/act_encoder.svg", width: 100%),
  caption: [Activity diagram of the `Encoder` in the `sstv` crate.],
) <img-act-encoder>

== `beacon` Crate Implemenation <sec-beacon-architecture>

`beacon` implements the runtime behavior of the #acr("SSTV") payload while leaving the hardware access to the carrier. At runtime, the firmware moves through a fixed set of states as depicted in @img-stm-sstv-system.

#figure(
  image("../figures/imported/stm_sstv_system.svg", width: 100%),
  caption: [State machine diagram of the SSTV system with the Initalization, Idle, Error, SSTV Transmission and Updating states and their transition conditions.],
) <img-stm-sstv-system>

Since the initialization state boots up the hardware specific to the device running the firmware, it needs to be fully implemented by the carrier and can not be provided by `beacon`.

As per the @req-error-communication, errors should be downlinked. Rust's `Result` system supports this effort by making all failure states transparent and allowing for convenient reporting methods. A custom method called `report_if_err()` is used to automatically downlink any error via the commanding link and continue on with the program.

The states are entered through the three public functions `idle()`, `transmit_sstv()` and `update()`. Exposing `idle()` alone would be sufficient since it contains the control flow dispatching into the other two states. However, the underlying functions are deliberately public as well. This lets carriers choose to reuse a single behavior such as the #acr("SSTV") transmission while implementing their own control flow around it.

=== Hardware Abstraction

The Rust compiler requires carriers to use traits in order to use custom hardware abstractions in the functions provided by `beacon`. These traits represent the formal interface expected by those functions in order to use the hardware. Traits need to be implemented by a struct and define all methods along with their arguments and return types. They can also define a default implementation of a method which can optionally be overwritten by the implementer. One trait is defined in `beacon` for every type of hardware.

The `Camera` trait is used as a universal camera interface, requiring the carrier to implement all of the life cycle methods needed to capture an image as shown in @list-camera-trait.

#figure(
  ```rust
  pub trait Camera {
      /// Bring the sensor out of standby and prepare it to capture.
      fn power_on(&mut self);

      /// Return the sensor to a low-power idle state.
      fn power_off(&mut self);

      /// Capture and discard warm-up frames so the sensor / on-chip filters
      /// settle.
      fn calibrate(&mut self);

      /// Receive a single frame as a ready-to-encode image.
      fn receive_frame(&mut self) -> Image;

      /// Capture a frame from turned off state and turn the camera back off.
      fn capture(&mut self) -> Image {
          self.power_on();
          self.calibrate();
          let image = self.receive_frame();
          self.power_off();
          image
      }
  }
  ```,
  caption: [The `Camera` trait in the `beacon` crate.],
) <list-camera-trait>

The `AudioChannel` trait is used as a universal audio output interface, requiring the carrier to implement the sample output methods as shown in @list-audio-channel-trait. Besides outputting and flushing single samples, the carrier communicates the sample rate of its hardware, which `beacon` passes on to the `Synthesizer`.

#figure(
  ```rust
  pub trait AudioChannel {
      /// The rate at which the hardware plays samples, in Hz.
      fn sample_rate(&self) -> u32;

      /// Output a single sample. May be buffered internally.
      fn transmit(&mut self, sample: i16) -> Result<(), AudioError>;

      /// Write all buffered samples out to the hardware.
      fn flush(&mut self) -> Result<(), AudioError>;
  }
  ```,
  caption: [The `AudioChannel` trait in the `beacon` crate.],
) <list-audio-channel-trait>

The `CommandLink` trait is used as the interface to the commanding link, requiring the carrier to transmit `Message`s and poll for received `Command`s as shown in @list-command-link-trait. Since the trait already deals in parsed `Command`s and `Message`s, the encoding of the underlying protocol stays hidden from the logic consuming the trait.

#figure(
  ```rust
  pub trait CommandLink {
      /// Transmit a message via the link.
      fn send(&self, message: Message);

      /// Return the next pending command
      fn receive(&mut self) -> Result<Option<Command>>;
  }
  ```,
  caption: [The `CommandLink` trait in the `beacon` crate.],
) <list-command-link-trait>

=== SSTV Transmission

The SSTV transmission state is responsible for the main function of the software, emitting audio samples based on input from the camera(s). Ideally, all cameras would capture images at the same time in order to get images of the same location in orbit from different angles or different light spectra. However, since the cameras can only be accessed sequentially, all images are captured before any transmission.

A buffer of five seconds is used between the transmissions to allow ground station systems on Earth to process the image before the next one is transmitted. @img-act-transmit-sstv shows how the `transmit_sstv()` function is implemented.

#figure(
  image("../figures/imported/act_transmit_sstv.svg", width: 100%),
  caption: [Activity diagram of the #acr("SSTV") transmission],
) <img-act-transmit-sstv>

=== Updating

The @req-update-failure is the guiding principle behind the `update()` function, resulting in a design without any paths leading to fatal errors as depicted in @img-stm-updating.

#figure(
  image("../figures/imported/stm_updating.svg", width: 100%),
  caption: [State machine diagram of the update mechanism],
) <img-stm-updating>

If an update announcement is received while the update is in progress, the already received chunks get deleted and the update start from the beginning. This prevents the system from being stuck in a half-finished update. Alternatively, the update state can be exited by deliberately sending a package with a wrong offset.

If all chunks arrived as intended, the update only gets flashed in case the firmware can be validated by the official ESP32 update handler.

