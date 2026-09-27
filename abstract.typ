Slow-Scan Television (SSTV) is an analogue method of transmitting images via radio that is still widely used by radio amateurs. This thesis presents a modular firmware for SSTV payloads on satellites running on an ESP32-P4 microcontroller. It is written in Rust and split into multiple crates.

`beacon` contains the shared runtime logic for capturing, encoding and transmitting images, handling camera failures, reporting errors and receiving firmware updates. The hardware is abstracted through traits, so a new system only needs to implement hardware-specific modules. The encoding is provided by `sstv`, a hardware-agnostic library published on #link("https://crates.io/crates/sstv")[crates.io].

`beacon-on-moveiiia` implements these traits for the SSTV payload of the MOVE-IIIa satellite. Unit and integration tests verify that it fulfils all requirements. A second carrier for the M5Stack Tab5 passes the same tests, demonstrating the modularity of the software.
