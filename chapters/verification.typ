#import "@preview/acrostiche:0.7.0": acr

= Verification

== Quality Assurance

Software engineering offers some common practices for increasing high quality code throughout a project. One of these practices is the usage of formatters and linters. As the name implies, the formatter automatically aligns the formatting for all files with the style guide @rustfmt. Linters perform static code analysis to catch common code mistakes, increase performance or enforce rules @clippy. Rust's default formatter `rustfmt` and linter `clippy` were both used in `beacon` and `sstv`. `clippy` was even used in `sstv` to guarentee the program could not crash at run time via a strict rule set.

Another software engineering practice is unit testing where the run time environment is simulated to verify certain behaviors in a deterministic manner. Extensive unit testing was used in `sstv` to ensure compatibility with the Dayton paper and other #acr("SSTV") programs. Testing `beacon` proved comparatively more difficult because unit tests by design have to be run on the device developing the code and not the target device. However, the traits described in section @sec-beacon-architecture make this possible. Since the entry points only depend on the `Camera`, `AudioChannel` and `CommandLink` traits, the real devices can be replaced with lightweight fakes running on the development machine. This lets the behaviour of `idle()` and `transmit_sstv()` be verified deterministically without the target hardware present.

However, these practices only generate an impact on the code base if they are consistently enforced. For that reason, both repositories use `pre-commit`. This tool installs a hook into the respective `git` repositories running among others the formatter, the linter and the unit tests before each commit. If any of those checks fail, the commit is aborted. If the developer does not have `pre-commit` installed locally, a GitHub Action catches the issues and sends out an automatic email communicating the failure. While these measures raise the bar for contributing to the repository, they prevent low quality and faulty code from entering the `git` history in the first place, ensuring that reverting to any commit yields safe state.

== Integration Testing

The hardware for verifying the SSTV system was deliberately set up isolated from the rest of the satellite to reduce the variables and make the setup replicable. A Raspberry Pi was chosen to mock all external interfaces. It provides the CSP message link through a USB to RS485 adapter and receives the audio samples via I2S. @img-test-setup shows the exact setup, while @tbl-test-wiring shows how the test setup is wired.

#figure(
  image("../figures/test-setup.jpg", width: 60%),
  caption: [Hardware setup for the verification with a Raspberry Pi 4B (1), a DSD TECH SH-U11 (2) and the SSTV system (3)],
) <img-test-setup>

#figure(
  table(
    columns: 4,
    align: left,
    [*From Device*], [*From Pin*], [*To Device*], [*To Pin*],

    [ESP32-P4], [GPIO21], [Raspberry Pi 4B], [GPIO18],
    [ESP32-P4], [GPIO23], [Raspberry Pi 4B], [GPIO19],
    [ESP32-P4], [GPIO22], [Raspberry Pi 4B], [GPIO20],
    [ESP32-P4], [5V], [Raspberry Pi 4B], [5V],
    [ESP32-P4], [GND], [Raspberry Pi 4B], [GND],

    [THVD1424], [TX+], [DSD TECH SH-U11], [RX-],
    [THVD1424], [TX-], [DSD TECH SH-U11], [RX+],
    [THVD1424], [RX+], [DSD TECH SH-U11], [TX+],
    [THVD1424], [RX-], [DSD TECH SH-U11], [TX-],
  ),
  caption: [Pin wiring for the test setup],
) <tbl-test-wiring>

Rather than testing the firmware behavior manually, automatic software tests were written in the `tests` directory of the `beacon` repository. The tests send the commands required to trigger the behavior and then check the system response against the expected output. Since some tests simulate camera failure cases, a compile flag was introduced that disables either of the cameras in the software. The following sections detail each of the integration tests. All tests have were successfully passed by the firmware.

=== Transmission with Both Cameras <sec-test-both-cameras>

The transmission test verifies the main functionality of the firmware by triggering an #acr("SSTV") transmission and validating the returned audio samples for the presence and correctness of both images. @img-test-sstv shows the testing sequence.

#figure(
  image("../figures/imported/sd_test_sstv.svg", width: 100%),
  caption: [Sequence diagram of the SSTV transmission test.],
) <img-test-sstv>

=== RGB Only Transmission <sec-test-rgb-only>

This test is supposed to verify the firmware behaves correctly in the case that only the RGB camera is working. Therefore, a firmware version is flashed where a failed thermal camera initialization is simulated. @img-test-rgb shows the testing sequence.

#figure(
  image("../figures/imported/sd_test_rgb.svg", width: 100%),
  caption: [Sequence diagram of the RGB only transmission test.],
) <img-test-rgb>

=== Thermal Only Transmission <sec-test-thermal-only>

The test covering the scenario that only the thermal camera is working is identical to the RGB only transmission test other than the fact that flashed software has the RGB camera disabled instead of the thermal camera.

=== Busy and Available Messages <sec-test-busy-available>

This test verifies that the SSTV system communicates the start and end of a transmission to the payload board. After the #acr("SSTV") command is sent, the test waits for a Busy message followed by an Available message once the transmission has finished. The test is passed if both messages are received in the correct order.

=== Update Successfully <sec-test-update-successful>

This test verifies that the device can receive updates via RS485 and runs the new firmware after the update sequence was successfully performed. The sequence is shown in @img-test-update-successful.

#figure(
  image("../figures/imported/sd_test_update_successful.svg", width: 100%),
  caption: [Sequence diagram of the successful update test.],
) <img-test-update-successful>

The test is considered successful if a boot info message is received by the Raspberry Pi, because the device only reboots if the update succeeded.

The above steps are used as the basis for the failed update tests described in the following sections. In addition to checking for the expected error message, each failed update test verifies that the device still responds to commands afterwards and has not entered an unrecoverable state.


=== Update Incomplete <sec-test-update-incomplete>

To test if the device recovers if an incomplete update is transmitted, a full update is announced but only a single firmware chunk is transmitted before the update end command is sent. The test is passed if the SSTV system transmitts an UpdateIncomplete error.

=== Update Corrupt <sec-test-update-corrupt>

To test how the SSTV system reacts when an unbootable update is received, the compiled firmware is truncated at the end. The new shortened length of the firmware is then announced and after sending the update chunks and end command, the test succeeds if the SSTV system returns an UpdateCorrupt message.

=== Update Chunk Incomplete <sec-test-update-chunk-incomplete>

In the case that part of a chunk is missing, the firmware is supposed to transmit an UpdateChunkIncomplete message. To test this, only part of the first update chunk is transmitted.

=== Update Data Before Begin <sec-test-update-data-before-begin>

To test that the device rejects update chunks arriving before an update was started, a chunk is transmitted directly after the update announcement without the begin command. The test is passed if the SSTV system transmits an UpdateNotInProgress error.

=== Update End Before Begin <sec-test-update-end-before-begin>

This test is identical to the previous one other than the fact that the end command is sent instead of an update chunk. The expected response is again an UpdateNotInProgress error.

=== Update Wrong Offset <sec-test-update-wrong-offset>

If a chunk is lost during an update, the following chunks arrive at an unexpected offset. To test this, the first update chunk is transmitted with a wrong offset. The test is passed if the SSTV system transmits an UpdatePackageOffset error.

== Requirement Verification

The tests do not map cleanly to the requirements because the requirements partially constrain internal details such as the specific sensors and interfaces and the tests verify the bahavior of the SSTV system as a black box. However, a combination of the tests can still be used for requirement verification.

=== req00

*Description*: The software shall run on the ESP32-P4.

*Verdict*: Passed

The first requirement is not verified by a specific test but rather from the fact that the tests run on the device at all. If the software could not run on the ESP32-P4, none of the tests would pass.

=== req01

*Description*: The software shall read an image from the SC850SL RGB camera.

*Verdict*: Passed

The two tests that include the transmission of an RGB image (@sec-test-both-cameras and @sec-test-rgb-only) prove that the SSTV system can read an image from the RGB camera.

=== req02

*Description*: The software shall read an image from the MI1602 thermal camera.

*Verdict*: Passed

The tests in @sec-test-both-cameras and @sec-test-thermal-only both prove the correct implementation of the thermal camera.

=== req03

*Description*: The software shall encode the images via Robot 36C.

*Verdict*: Passed

Since the decoding happens in Robot 36, all SSTV transmission tests (@sec-test-both-cameras, @sec-test-rgb-only, @sec-test-thermal-only), verify this requirement.

=== req04

*Description*: The software shall output the audio samples via I2S.

*Verdict*: Passed

Similarly, since the audio samples are received via I2S on the Raspberry pi, all transmission tests verify req04.

=== req05

*Description*: The software shall trigger an #acr("SSTV") transmission if the corresponding command is received.

*Verdict*: Passed

The transmissions in the tests are triggered by an SSTV command. They therefore also validate this requirement.

=== req06

*Description*: If a camera encounters an error, the transmission of its corresponding image shall be skipped while the image of the working camera shall be transmitted.

*Verdict*: Passed

This behavior is explicitly tested and verified by @sec-test-rgb-only and @sec-test-thermal-only.

=== req07

*Description*: The software shall be able to receive firmware updates via UART.

*Verdict*: Passed

The successful update test (@sec-test-update-successful) proves that the SSTV system can receive a firmware update over RS485 and run the new firmware afterwards.

=== req08

*Description*: A failed update shall not lead to an unrecoverable state.

*Verdict*: Passed

All failed update tests (@sec-test-update-incomplete, @sec-test-update-corrupt, @sec-test-update-chunk-incomplete, @sec-test-update-data-before-begin, @sec-test-update-end-before-begin and @sec-test-update-wrong-offset) verify that the device still responds to commands after the failed update, which proves that no failure case leads to an unrecoverable state.

=== req09

*Description*: The software shall communicate any recoverable errors to the ground station.

*Verdict*: Passed

Each of the failed update tests checks for a specific error message returned by the SSTV system. Since these messages are received by the Raspberry Pi, they prove that the recoverable errors are communicated to the ground station.

=== req10

*Description*: The software shall communicate when an SSTV transmission starts and ends to the payload board.

*Verdict*: Passed

The Busy and Available messages test (@sec-test-busy-available) verifies that the SSTV system sends a Busy message when a transmission starts and an Available message once it has finished.

=== req11

*Description*: The firmware size shall be small enough to allow transmitting the entire binary within a single overpass.

*Verdict*: Partially Passed

The size of the compiled binary is 333.8 kB#footnote[obtainable in the `beacon` repository via `cargo build --release; espflash save-image --chip esp32p4 -s 16mb target/riscv32imafc-esp-espidf/release/beacon <temporary-location> && ls -lh <temporary-location>`]. The full update is then split into 2600 chunks, each of which with a size of 128 bytes. A number of non-firmware bytes are then added to each chunk from the various communication channels the update is transmitted through which are detailed in @tab-update-chunks.

#figure(
  table(
    columns: 3,
    align: left,
    [*Layer*], [*Bytes*], [*Note*],

    [Firmware bytes], [128], [],

    [Command overhead],
    [5],
    [1 byte identifying the command as an Update Chunk + 4 bytes of chunk offset (see @tab-commands)],

    [CSP header], [6], [From @libcsp],

    [Authentication], [4], [From @libcsp-hmac],

    [Reed-Solomon], [32], [From @gomspace-ax100-manual[p.~28]],

    [Golay-Length], [3], [From @gomspace-ax100-manual[p.~27]],

    [Interframe Fill],
    [50],
    [`intfrmln`@gomspace-ax100-manual[p.~12] value chosen by MOVE-IIIa],

    [*Total bytes per chunk*], [*228*], [],
  ),
  caption: [Byte overhead breakdown of each update chunk.],
) <tab-update-chunks>

With the total size of each chunk we can obtain the total size of the transmitted update as $2600 times 228 "B" = 592.8 "kB" = 4742.4 "kb"$.

The primary link for transmitting firmware to the satellite is #acr("UHF") which uses #acr("GMSK"). #acr("GMSK") carries one bit per symbol meaning the bits per firmware update are analogous to the symbols per firmware update @gmsk-mathworks. The #acr("UHF") link supports symbol rates up to 38.4 kbps @gomspace-ax100-datasheet[p.~4] with 4.8 kbps used as the fallback baudrate in the case of a non-ideal link by MOVE-IIIa.

TODO: quantify which percent of overpasses allow for full firmware transmission.

== Modularity

One of the explicit goals of this thesis is to make the functionality of `beacon` usable by other system with potentially different hardware. The only way to properly test this is to implement it on a different device. For this purpose, the M5Stack Tab5 IoT Development Kit (from here on referred to as the Tab5) was chosen. The Tab5 is powered by an ESP32-P4 and has a builtin RGB camera (the SC2356) and speaker (driven by the NS4150B audio amplifier). These are notably distinct from the devices used in the SSTV system and therefore require custom implementations. Commanding was handled via the USB-C port of the Tab5.

The custom implementation was done in the `beacon-on-tab5` repository which copied all of the above mentioned tests, except for the ones requiring a thermal camera. The tests were then changed to use the Laptop's microphone for image decoding instead of the I2S samples from the Raspberry Pi.

After implementing the hardware abstraction for the new devices, the integration into the firmware was remarkably similar compared to `beacon`. @list-main-comparison shows the `main` functions of both firmwares side by side.

#figure(
  grid(
    columns: (1fr, 1fr),
    column-gutter: 1em,
    align: left,
    [
      ```rust
      fn main() {
          initialize_esp32();
          let mut link =
              initialize_payload_link()
                  .unwrap();
          let mut audio =
              initialize_audio_channel()
                  .report_if_err(&link)
                  .unwrap();

          let rgb_camera =
              initialize_rgb_camera()
                  .report_if_err(&link)
                  .ok()
                  .map(boxed);
          let thermal_camera =
              initialize_thermal_camera()
                  .report_if_err(&link)
                  .ok()
                  .map(boxed);

          link.send(Message::Available);
          idle(
              &mut link,
              vec![
                  rgb_camera,
                  thermal_camera,
              ],
              &mut audio,
          );
      }
      ```
    ],
    [
      ```rust
      fn main() {
          initialize_esp32();
          let mut link =
              initialize_payload_link()
                  .unwrap();

          let mut i2c =
              initialize_board()
                  .report_if_err(&link)
                  .unwrap();
          let mut audio =
              initialize_audio_channel(
                  &mut i2c,
              )
              .report_if_err(&link)
              .unwrap();

          let rgb_camera =
              initialize_rgb_camera(i2c)
                  .report_if_err(&link)
                  .ok()
                  .map(boxed);

          link.send(Message::Available);
          idle(
              &mut link,
              vec![rgb_camera],
              &mut audio,
          );
      }
      ```
    ],
  ),
  caption: [The `main` functions of `beacon` (left) and `beacon-on-tab5` (right).],
) <list-main-comparison>

Since all of the copied tests pass, `beacon` can be considered modular. @img-tab5-decoding shows how the SSTV transmission from the Tab5 can be decoded on a phone.

#figure(
  image("../figures/tab5-decoding.jpg", width: 60%),
  caption: [Showcase of how the SSTV transmission from the Tab5 can be decoded (not the actual testing setup though).],
) <img-tab5-decoding>

