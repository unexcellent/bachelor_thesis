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

=== Transmission with Both Cameras

The transmission test verifies the main functionality of the firmware by triggering an #acr("SSTV") transmission and validating the returned audio samples for the presence and correctness of both images. @img-test-sstv shows the testing sequence.

#figure(
  image("../figures/imported/sd_test_sstv.svg", width: 100%),
  caption: [Sequence diagram of the SSTV transmission test.],
) <img-test-sstv>

=== RGB Only Transmission

This test is supposed to verify the firmware behaves correctly in the case that only the RGB camera is working. Therefore, a firmware version is flashed where a failed thermal camera initialization is simulated. @img-test-rgb shows the testing sequence.

#figure(
  image("../figures/imported/sd_test_rgb.svg", width: 100%),
  caption: [Sequence diagram of the RGB only transmission test.],
) <img-test-rgb>

=== Thermal Only Transmission

The test covering the scenario that only the thermal camera is working is identical to the RGB only transmission test other than the fact that flashed software has the RGB camera disabled instead of the thermal camera.

== Modularity

- show an example on how another camera could be added
- show an example of the code for a raspberry pi with a camera and a speaker

