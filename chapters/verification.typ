#import "@preview/acrostiche:0.7.0": acr

= Verification

== Quality Assurance

Software engineering offers some common practices for increasing high quality code throughout a project. One of these practices is the usage of formatters and linters. As the name implies, the formatter automatically aligns the formatting for all files with the style guide @rustfmt. Linters perform static code analysis to catch common code mistakes, increase performance or enforce rules @clippy. Rust's default formatter `rustfmt` and linter `clippy` are both used in all repositories. `sstv` even uses `clippy` to guarentee the program has no run time paths that could lead to a program crash.

These practices only generate an impact on the code base if they are consistently enforced. For that reason, all crates use `pre-commit`. This tool installs a hook into the respecive `git` repositories triggering before every single commit. `pre-commit` then runs `rustfmt`, `clippy`, the unit tests (see @sec-unit-testing) and other checks. If a single one of those checks fail, the commit is aborted, forcing the developer to address the issues before adding their changes to the `git` history. If the developer does not have `pre-commit` installed locally, a GitHub Action catches the issues and sensd out an automatic email communicating the failure. While these measures raise the bar for contributing to the repositories, they prevent low quality and faulty code from entering the `git` history in the first place, ensuring that reverting to any commit yields safe state.

== Unit Testing <sec-unit-testing>

Unit testing is the verification of behavior of modules in isolation @swebok[p. 5-6]. It is used to validate the informal interface outside of the scope of the compiler checks. By isolating the modules, hardware can be abstracted to allow the tests to run deterministically on the developer's machine. However, this restricts unit testing to `sstv` and `beacon` since carriers require direct hardware access.

=== `sstv`

Testing in the `sstv` crate fundamentally verifies that the tones from the Dayton paper @daytona-paper are correctly emitted. Each mode in `sstv` is defined as a sequence os steps which are either fixed control tones or scans of a color channel. A single mistake in any of these steps would shift the timing of the entire transmission and prevent a receiver from decoding the image. The test in @list-test-robot36-mode therefore checks the duration of the transmission against the values in the paper.

#figure(
  ```rust
  #[test]
  fn transmission_time_matches_the_paper() {
      let encoder = Encoder::new(ROBOT_36, black_image(ROBOT_36)).unwrap();
      let samples: Vec<i16> = Synthesizer::new(encoder, SAMPLE_RATE).collect();

      let transmission_duration = samples.len() as f64 / SAMPLE_RATE as f64;
      assert_eq!(transmission_duration, 36.0 + HEADER_DURATION)
  }
  ```,
  caption: [The `transmission_time_matches_the_paper()` test in `sstv` which verifies that the total transmission time matches the value defined in the Dayton paper.],
) <list-test-robot36-mode>

@list-test-shared-pair verifies that the `Encoder` averages the color differences of the two buffered rows correctly.

#figure(
  ```rust
  #[test]
  fn shared_pair_colour_differences_average_both_rows() {
      let mut pixels = two_rows();
      let lines = lines_over(&mut pixels, ColorMode::YuvSharedPair);
      let top = YuvPixel::from(TOP_ROW[0]);
      let bottom = YuvPixel::from(BOTTOM_ROW[0]);

      let red_average = average(top.chroma_red(), bottom.chroma_red());
      let blue_average = average(top.chroma_blue(), bottom.chroma_blue());
      assert_eq!(lines.value(0, Channel::RY), red_average);
      assert_eq!(lines.value(0, Channel::BY), blue_average);
  }
  ```,
  caption: [The `shared_pair_colour_differences_average_both_rows()` unit test in `sstv` verifying the averaging of the color differences over a line pair.],
) <list-test-shared-pair>

The remaining stages of the encoding path are tested similarly. The conversion from RGB to YUV is compared against precomputed values, every pixel value has to map linearly onto the frequency range between black (1500 Hz) and white (2300 Hz) and the header has to consist of the VOX tones, the leader tones and the #acr("VIS") code of Robot 36. The `Encoder` itself is tested for ending the transmission early if the image is truncated. Finally, the `Synthesizer` is compared against a floating point sine wave reference to ensure that the generated audio samples do not deviate from the ideal signal as can be seen in @list-test-synthesizer.

#figure(
  ```rust
  #[test]
  fn synthesizer_matches_pure_sine_wave() {
      let sample_rate: u32 = 48_000;
      let tones = [
          tone!(1200 Hz, 10 ms),
          tone!(1500 Hz, 10 ms),
          tone!(2300 Hz, 10 ms),
      ];

      let samples: Vec<i16> = Synthesizer::new(tones.into_iter(), sample_rate)
          .collect();
      let reference_samples = float_reference(&tones, sample_rate);

      let difference: Vec<u16> = samples
          .iter()
          .zip(&reference_samples)
          .map(|(sample, reference_sample)| sample.abs_diff(*reference_sample))
          .collect();
      let max_difference = *difference.iter().max().unwrap();
      let max_reference_sample = reference_samples
          .iter()
          .max()
          .unwrap()
          .abs() as u16;

      // should not deviate by more than 2%
      assert!(max_difference <= max_reference_sample / 50);
  }
  ```,
  caption: [The `synthesizer_matches_pure_sine_wave()` unit test in `sstv` verifying the generated audio samples against a floating point reference.],
) <list-test-synthesizer>

In total, 29 tests cover the Robot 36 encoding path which all pass.

=== `beacon`

Unit testing in `beacon` reveals another benefit of modular programming. The traits, that have been defined in @sec-hardware-abstraction can be used to implement mock hardware. The unit tests in `beacon` define `FakeCamera`, `FakeAudio` and `FakeLink`. Each implement the same public methods that any real device would, but only log what methods are called and emit dummy data if requested as can be seen in @list-fake-camera.

#figure(
  ```rust
  struct FakeCamera { log: CallLog }

  impl Camera for FakeCamera {
      fn power_on(&mut self) {
          self.log.append_call("power_on");
      }
      fn power_off(&mut self) {
          self.log.append_call("power_off");
      }
      fn calibrate(&mut self) {
          self.log.append_call("calibrate");
      }
      fn receive_frame(&mut self) -> Image {
          self.log.append_call("receive_frame");
          return fake_robot36_frame();
      }
  }
  ```,
  caption: [The `FakeCamera` struct and its implementation of `Camera` in `beacon`. The code was slightly restructured for readability while remaining functionally identical to the actual implementation.],
) <list-fake-camera>

The mock devices can then be used in the tests to check the behavior as seen in @list-test-transmit-sstv.

#figure(
  ```rust
  #[test]
  fn single_camera_captures_then_encodes_and_flushes_once() {
      let (camera, log) = FakeCamera::boxed();
      let mut audio = FakeAudio::new();

      transmit_sstv(&mut vec![Some(camera)], &mut audio).expect("transmission");

      assert_eq!(
          log.calls(),
          ["power_on", "calibrate", "receive_frame", "power_off"]
      );
      assert_eq!(audio.completed_transmissions(), 1);
      assert!(audio.samples > 0);
  }
  ```,
  caption: [The `single_camera_captures_then_encodes_and_flushes_once()` unit test in `beacon` verifying a successful transmission with a single working `FakeCamera`.],
) <list-test-transmit-sstv>

Other tests can then verify if combinations of working and non-working cameras behave as expected as the test in @list-test-transmit-sstv-non-working illustrates.

#figure(
  ```rust
  #[test]
  fn empty_slots_are_skipped() {
      let mut cameras = vec![
          missing_camera(),
          working_camera(),
          missing_camera(),
      ];
      let mut audio = FakeAudio::new();

      transmit_sstv(&mut cameras, &mut audio).expect("transmission");

      assert_eq!(
          audio.completed_transmissions(),
          1,
          "only the working camera transmits"
      );
  }
  ```,
  caption: [The `empty_slots_are_skipped()` unit test in `beacon` verifying that only working cameras transmit an image.],
) <list-test-transmit-sstv-non-working>

In total, `beacon` has three unit tests for `idle()` and five unit tests for `transmit_sstv()` which all pass. Testing the update mechanism is inherently more hardware-bound which is why it is verified in @sec-integration-testing.

== Integration Testing <sec-integration-testing>

The integration tests verify the behavior of the carrier firmware as a black-box system @swebok[p. 5-7]. They can therefore only be applied in `beacon-on-moveiiia` and `beacon-on-tab5`. This section only discusses the tests for `beacon-on-moveiiia` since they mostly match the ones in `beacon-on-tab5` and @sec-verify-modularity goes further into details on the `beacon-on-tab5` implementation.

The hardware for verifying the `beacon-on-moveiiia` carrier was deliberately set up isolated from the rest of the satellite to reduce the variables and make the setup replicable. A Raspberry Pi was chosen to mock all external interfaces. It provides the CSP message link through a USB to RS485 adapter and receives the audio samples via I2S. @img-test-setup shows the exact setup, while @tbl-test-wiring shows how the test setup is wired.

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

Rather than testing the firmware behavior manually, automatic software tests were written in the `tests` directory of the `beacon-on-moveiiia` repository. The tests send the commands required to trigger the behavior and then check the system response against the expected output. Since some tests simulate camera failure cases, a compile flag was introduced that disables either of the cameras in the software.

Python was chosen for the integration tests because it requires no compilation step on the Raspberry Pi and already provides libraries for the serial link and image analysis. The decoding is done via the Python bindings of `sstv`#footnote("https://pypi.org/project/sstv").

=== Transmission with Both Cameras <sec-test-both-cameras>

The transmission test verifies the main functionality of the firmware by triggering an #acr("SSTV") transmission and validating the returned audio samples for the presence and correctness of both images. @list-test-both-cameras shows the testing sequence.

#figure(
  ```python
  def test_both_cameras_transmitting(board: MockPayloadBoard) -> None:
      send_sstv_command(board)

      samples, rate = record_transmission(board, seconds=90)
      rgb, thermal = decode_images(samples, rate, count=2)

      assert_valid_image(rgb, min_std=6.0, min_smoothness=0.35)
      assert_valid_image(thermal, min_std=5.0, min_smoothness=0.35)
      assert_gap_between_images(samples, rate, seconds=5.0)
  ```,
  caption: [The `test_both_cameras_transmitting()` test in `beacon-on-moveiiia` verifying transmission if both cameras work as expected.],
) <list-test-both-cameras>

=== RGB Only Transmission <sec-test-rgb-only>

This test is supposed to verify the firmware behaves correctly in the case that only the RGB camera is working. Therefore, a firmware version is flashed where a failed thermal camera initialization is simulated. @list-test-rgb-only shows the testing sequence.

#figure(
  ```python
  def test_rgb_only_transmission(board: MockPayloadBoard) -> None:
    send_sstv_command(board)
    image = capture_and_decode(board)
    assert_valid_image(image, min_std=6.0, min_smoothness=0.35)
  ```,
  caption: [The `test_rgb_only_transmission()` test in `beacon-on-moveiiia` verifying transmission behavior if only the RGB camera is working.],
) <list-test-rgb-only>

=== Thermal Only Transmission <sec-test-thermal-only>

The test covering the scenario that only the thermal camera is working is identical to the RGB only transmission test other than the fact that flashed software has the RGB camera disabled instead of the thermal camera.

=== Busy and Available Messages <sec-test-busy-available>

This test verifies that the SSTV system communicates the start and end of a transmission to the payload board. After the #acr("SSTV") command is sent, the test waits for a Busy message followed by an Available message once the transmission has finished. The test is passed if both messages are received in the correct order as can be seen in @list-test-busy-available.

#figure(
  ```python
  def test_sstv_busy_available(board: MockPayloadBoard) -> None:
      send_sstv_command(board)
      wait_for_busy(board)
      wait_for_available(board)
  ```,
  caption: [The `test_sstv_busy_available()` test in `beacon-on-moveiiia` verifying that the carrier notifies the devices on the commanding link that an SSTV transmission is ongoing.],
) <list-test-busy-available>

=== Update Successfully <sec-test-update-successful>

This test verifies that the device can receive updates via the command link and runs the new firmware after the update sequence was successfully performed. The sequence is shown in @list-test-update-successful.

#figure(
  ```python
  def test_update_successful(board: MockPayloadBoard) -> None:
      image = build_firmware()

      send_update_announcement(board)
      send_update_begin(board, len(image))
      send_update_chunks(board, image)
      send_update_end(board)
      success = receive_boot_info(board)

      assert success
  ```,
  caption: [The `test_update_successful()` test in `beacon-on-moveiiia` verifying a successful firmware update over the command link.],
) <list-test-update-successful>

The test is considered successful if a boot info message is received by the Raspberry Pi, because the device only reboots if the update succeeded.

=== Update Incomplete <sec-test-update-incomplete>

To test if the device recovers if an incomplete update is transmitted, a full update is announced but only a single firmware chunk is transmitted before the update end command is sent. The test is passed if the SSTV system transmitts an UpdateIncomplete error (see @list-test-update-incomplete).

#figure(
  ```python
  def test_incomplete(board: MockPayloadBoard) -> None:
      header = staged_firmware_image()[:CHUNK]

      send_update_announcement(board)
      send_update_begin(board, 100 * len(header))
      send_update_data(board, 0, header)
      send_update_end(board)

      expect_update_error(board, b"UpdateIncomplete")
      assert_recovered(board)
  ```,
  caption: [The `test_incomplete()` test in `beacon-on-moveiiia` verifying that an incomplete update is rejected with an UpdateIncomplete error.],
) <list-test-update-incomplete>

=== Update Corrupt <sec-test-update-corrupt>

To test how the SSTV system reacts when an unbootable update is received, the compiled firmware is truncated at the end. The new shortened length of the firmware is then announced and after sending the update chunks and end command, the test succeeds if the SSTV system returns an UpdateCorrupt message as shown in @list-test-update-corrupt.

#figure(
  ```python
  def test_corrupt(board: MockPayloadBoard) -> None:
      truncated_image = staged_firmware_image()[:CHUNK]

      send_update_announcement(board)
      send_update_begin(board, len(truncated_image))
      send_update_data(board, 0, truncated_image)
      send_update_end(board)

      expect_update_error(board, b"UpdateCorrupt", timeout=15.0)
      assert_recovered(board)
  ```,
  caption: [The `test_corrupt()` test in `beacon-on-moveiiia` verifying that an unbootable update is rejected with an UpdateCorrupt error.],
) <list-test-update-corrupt>

=== Update Chunk Incomplete <sec-test-update-chunk-incomplete>

In the case that part of a chunk is missing, the firmware is supposed to transmit an UpdateChunkIncomplete message. To test this, only part of the first update chunk is transmitted as can be seen in @list-test-update-chunk-incomplete.

#figure(
  ```python
  def test_short_chunk(board: MockPayloadBoard) -> None:
      send_update_announcement(board)
      send_update_begin(board, 100_000)
      send_update_data(board, 0, bytes(CHUNK // 2))

      expect_update_error(board, b"UpdateChunkIncomplete")
      assert_recovered(board)
  ```,
  caption: [The `test_short_chunk()` test in `beacon-on-moveiiia` verifying that a partial update chunk is rejected with an UpdateChunkIncomplete error.],
) <list-test-update-chunk-incomplete>

=== Update Data Before Begin <sec-test-update-data-before-begin>

To test that the device rejects update chunks arriving before an update was started, a chunk is transmitted directly after the update announcement without the begin command. The test is passed if the SSTV system transmits an UpdateNotInProgress error (see @list-test-update-data-before-begin).

#figure(
  ```python
  def test_data_before_begin(board: MockPayloadBoard) -> None:
      send_update_announcement(board)
      send_update_data(board, 0, bytes(CHUNK))

      expect_update_error(board, b"UpdateNotInProgress")
      assert_recovered(board)
  ```,
  caption: [The `test_data_before_begin()` test in `beacon-on-moveiiia` verifying that update chunks sent before the begin command are rejected.],
) <list-test-update-data-before-begin>

=== Update End Before Begin <sec-test-update-end-before-begin>

This test is identical to the previous one other than the fact that the end command is sent instead of an update chunk. The expected response is again an UpdateNotInProgress error as shown in @list-test-update-end-before-begin.

#figure(
  ```python
  def test_end_before_begin(board: MockPayloadBoard) -> None:
      send_update_announcement(board)
      send_update_end(board)

      expect_update_error(board, b"UpdateNotInProgress")
      assert_recovered(board)
  ```,
  caption: [The `test_end_before_begin()` test in `beacon-on-moveiiia` verifying that an end command sent before the begin command is rejected.],
) <list-test-update-end-before-begin>

=== Update Wrong Offset <sec-test-update-wrong-offset>

If a chunk is lost during an update, the following chunks arrive at an unexpected offset. To test this, the first update chunk is transmitted with a wrong offset. The test is passed if the SSTV system transmits an UpdatePackageOffset error (see @list-test-update-wrong-offset).

#figure(
  ```python
  def test_wrong_offset(board: MockPayloadBoard) -> None:
      send_update_announcement(board)
      send_update_begin(board, 100_000)
      send_update_data(board, CHUNK, bytes(CHUNK))

      expect_update_error(board, b"UpdatePackageOffset")
      assert_recovered(board)
  ```,
  caption: [The `test_wrong_offset()` test in `beacon-on-moveiiia` verifying that an update chunk with an unexpected offset is rejected with an UpdatePackageOffset error.],
) <list-test-update-wrong-offset>

== Firmware Size <sec-size>

The size of the compiled `beacon-on-moveiiia` binary can be obtained by running the commands in @list-size-commands on a unix system in the repository directory.

#figure(
  ```shell-unix-generic
  mkdir -p local/firmware

  cargo build --release

  espflash save-image --chip esp32p4 -s 16mb target/riscv32imafc-esp-espidf/release/beacon-on-moveiiia local/firmware

  ls -lh local/firmware
  ```,
  caption: [Commands used to determine the `beacon-on-moveiiia` firmware size via a UNIX shell.],
) <list-size-commands>

Running these commands outputs a size of 385.92 kB. The full update is then split into 3015 chunks, each of which with a size of 128 bytes. A number of non-firmware bytes are then added to each chunk from the various communication channels the update is transmitted through which are detailed in @tab-update-chunks.

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

With the total size of each chunk we can obtain the total size of the transmitted update as $3015 times 228 "B" = 687.648 "kB"$.

== Requirement Verification

With the above sections, a verdict can be reached in @tab-requirement-verification whether each requirement has been fulfilled by the system.

#figure(
  table(
    columns: (3.5cm, 1.7cm, auto),
    align: left,
    [*Name*], [*Verdict*], [*Reasoning*],

    [MCU],
    [Passed],
    [The fact that any of the integration tests pass, validates this requirement.],

    [Cameras],
    [Passed],
    [All transmission tests pass (@sec-test-both-cameras, @sec-test-rgb-only, @sec-test-thermal-only).],

    [Encoding],
    [Passed],
    [The images in the transmission tests (@sec-test-both-cameras, @sec-test-rgb-only, @sec-test-thermal-only) are strictly decoded using Robot 36.],

    [Audio],
    [Passed],
    [All transmission tests pass (@sec-test-both-cameras, @sec-test-rgb-only, @sec-test-thermal-only).],

    [Commanding],
    [Passed],
    [The transmission tests (@sec-test-both-cameras, @sec-test-rgb-only, @sec-test-thermal-only) trigger via the SSTV command.],

    [Cameras Failure],
    [Passed],
    [Both camera failure tests (@sec-test-rgb-only, @sec-test-thermal-only) pass.],

    [Updates],
    [Passed],
    [The successful update test (@sec-test-update-successful) passes.],

    [Update Failure],
    [Passed],
    [All of the update failure tests (@sec-test-update-incomplete, @sec-test-update-corrupt, @sec-test-update-chunk-incomplete, @sec-test-update-data-before-begin, @sec-test-update-wrong-offset) pass.],

    [Error Communication],
    [Passed],
    [All of the update failure tests (@sec-test-update-incomplete, @sec-test-update-corrupt, @sec-test-update-chunk-incomplete, @sec-test-update-data-before-begin, @sec-test-update-wrong-offset) receive the corresponding error.],

    [Transmission Communication],
    [Passed],
    [The busy and available test (@sec-test-busy-available) passes.],

    [Size],
    [Passed],
    [The 687.648 kB calculated in @sec-size are smaller than the 790.21 kB listed in the requirement.],
  ),
  caption: [Verdict about each requirement if it was passed and reasoning given.],
) <tab-requirement-verification>

== Modularity <sec-verify-modularity>

Since `beacon-on-moveiiia` already imports `beacon`, it could be argued that the SSTV system itself validates the modularity of `beacon`. However, both crates were developed alongside each other for the same hardware. Any decision about the hardware that accidentally leaked into `beacon` would therefore go unnoticed because `beacon-on-moveiiia` implements it anyway. Only a second carrier with different hardware can therefore verify the software's modularity.

For this purpose, the M5Stack Tab5 IoT Development Kit (from here on referred to as the Tab5) was chosen. The Tab5 is powered by an ESP32-P4 and has a builtin RGB camera (the SC2356) and speaker (driven by the NS4150B audio amplifier). These are notably distinct from the devices used in `beacon-on-moveiiia` and therefore require a custom carrier.

The carrier itself is implemented in `beacon-on-tab5` which copies all of the integration tests, except for those requiring a thermal camera. Instead of a Raspberry Pi, the tests are executed on a laptop with the microphone used for image decoding and the USB-C port on the Tab5 for commanding.

After implementing the hardware abstraction for the new devices, the integration into the firmware was remarkably similar compared to `beacon-on-moveiiia`. @list-main-comparison shows the `main` functions of both firmwares side by side.

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
  caption: [The `main` functions of `beacon-on-moveiiia` (left) and `beacon-on-tab5` (right).],
) <list-main-comparison>

Since all of the copied tests pass, `beacon` can be considered modular. @img-tab5-decoding shows how the #acr("SSTV") transmission from the Tab5 can be decoded on a phone.

#figure(
  image("../figures/tab5-decoding.jpg", width: 60%),
  caption: [Showcase of how the SSTV transmission from the Tab5 can be decoded.],
) <img-tab5-decoding>

