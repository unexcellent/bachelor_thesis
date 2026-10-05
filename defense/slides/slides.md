---
theme: default
title: SSTV Thesis Defense
info: A Modular Software Architecture for SSTV Image Transmission on an ESP32 Microcontroller
author: Tobias Klockau
colorSchema: dark
aspectRatio: 16/9
canvasWidth: 1280
fonts:
  sans: Helvetica Neue
  provider: none
defaults:
  layout: canvas
transition: none
# Hash routes keep deep links like the presenter view working on GitHub Pages, which has no SPA fallback.
routerMode: hash
exportFilename: defense
download: false
---

<img src="/img/sstv_system_above.svg" class="absolute" style="left: 18.4%; top: 2.2%; width: 63.3%; height: 95.6%" />
<img src="/img/tum_logo.svg" class="absolute" style="left: 87.7%; top: 3%; width: 10.8%" />

<div class="absolute" style="left: 3.7%; top: 50%; width: 64.4%">
  <div class="text-[43px] font-bold leading-tight">A Modular Software Architecture for SSTV Image Transmission on an ESP32 Microcontroller</div>
  <div class="mt-2 text-[32px] font-normal">Bachelor Thesis Defense | Tobias Klockau</div>
</div>

---

<SstvScan src="/img/earthset.jpg" />

<!--
- Analog image transfer technology from the 1950s
- Still actively used today: every few months a transmission from the ISS received by thousands
- Scans an image line by line - thats why its called slow-scan television
- Converts the pixel information into tones that can then be decoded
- Demonstration here shows satellite image on the left, encoded into tones and decoded on the right
- [start playing the audio for a few seconds]
-->

---
clicks: 2
---

<!-- Spacing and centring use each drawing's ink centroid, not its box centre, so the antennas don't skew the layout. -->
<div
  class="absolute swoop"
  style="left: 64px; top: 182px; width: 410px; height: 355px"
  :style="{ transform: `translateX(${[372, 186.5, 0][$clicks]}px)`, filter: $clicks >= 1 ? 'brightness(0.4)' : 'none' }"
>
  <!-- The satellite is shown in two crops so its antenna points at the payload, mirroring the pptx. -->
  <div class="absolute overflow-hidden" style="left: 0; top: 24px; width: 398px; height: 331px">
    <img src="/img/satellite.svg" class="absolute max-w-none" style="left: 0; top: 0; width: 125.75%; height: 100%" />
  </div>
  <div class="absolute overflow-hidden" style="left: 398px; top: 0; width: 12px; height: 331px">
    <img src="/img/satellite.svg" class="absolute max-w-none" style="left: -4124%; top: 0; width: 4214%; height: 100%" />
  </div>
</div>
<img
  src="/img/sstv_system.svg"
  class="absolute swoop"
  style="left: 494.5px; top: 232px; width: 301px; height: 256px"
  :style="{ transform: `translateX(${[586.5, 186.5, 0][$clicks]}px)`, opacity: $clicks >= 1 ? 1 : 0, filter: $clicks >= 2 ? 'brightness(0.4)' : 'none' }"
/>
<img
  src="/img/camera_top.svg"
  class="absolute swoop"
  style="left: 888px; top: 143px; width: 234px; height: 256px"
  :style="{ transform: `translateX(${$clicks >= 2 ? 0 : 400}px)`, opacity: $clicks >= 2 ? 1 : 0 }"
/>
<img
  src="/img/camera_bottom.svg"
  class="absolute swoop"
  style="left: 886px; top: 397px; width: 237px; height: 199px"
  :style="{ transform: `translateX(${$clicks >= 2 ? 0 : 400}px)`, opacity: $clicks >= 2 ? 1 : 0 }"
/>

<!--
- MOVE-IIIa is the third satellite iteration of the WARR student group with targeted launch end of this year or beginning of next
- Two main payloads
  - DEDRA for detecting microdebris
  - SSTV payload
    - Two cameras, one for visible light spectrum and one for infrared
- Only software written in this thesis
  - Not only for MOVE-IIIa but for any sstv payload
-->

---
clicks: 1
---

<FrequencyRow src="/img/earthset.jpg" :step="$clicks" />

<!--
- SSTV works by encoding color information in frequencies
- the graph below shows the frequency by time graph
- [click]
- higher frequency is higher brighness (or luminance)
-->

---
clicks: 1
---

<ColourSplit src="/img/earthset.jpg" :step="$clicks" />

<!--
- why is it brightness and not any of the RGB channels?
  - because Robot36 uses a composite color model
- means that we have one channel for brightness (called luminance)
- one channel for the blue difference
  - color shift from blue to yellow
- one channel for red difference
  - color shift from red to green
- [click]
- why use this color model?
  - because the human eye can perceive changes in luminance much better than changes in chromiance
- therefore we can alternate blue and red chromiance every other line
- barely a noticable change
- shorter transmissions
-->

---
clicks: 1
---

<RobotTimeline part="vox" :step="$clicks" />

<!--
- every transmission has a header besides the actual image tones
- usually starts with the voice activation sequence
- used to announce the transmission and show the entire frequency range
- [click]
-->

---
clicks: 1
---

<RobotTimeline part="vis" :step="$clicks" />

<!--
- vis header is used to identify the mode of the transmission
- starts with two leader tones
- then a tone sequence representing a binary number
- in this case, it identifies the Robot36 mode
- [click]
-->

---
clicks: 1
---

<RobotTimeline part="line" src="/img/earthset.jpg" :step="$clicks" />

<!--
- finally, the tones for each scanline
- starts with a synchronization tone so every receiver knows a new line has started
- then luminance
- then a small porch
- then chromiance
  - alternates between blue and red
- [click]
-->

---
clicks: 1
---

<div class="absolute inset-0 grid content-center justify-center items-start" style="grid-template-columns: auto auto auto; column-gap: 80px">
  <div>
    <div class="list-heading">Constraints</div>
    <ul class="plain-list">
      <li>Unserviceable</li>
      <li>Power-constrained</li>
      <li>Unreliable uplink</li>
    </ul>
  </div>
  <div v-click class="text-[64px] font-thin self-center">→</div>
  <div v-click="1">
    <div class="list-heading">Requirements</div>
    <ul class="plain-list">
      <li>Supports any number of cameras</li>
      <li>Keeps transmitting when a camera fails</li>
      <li>Firmware updates over the uplink</li>
      <li>Survives a failed update</li>
    </ul>
  </div>
</div>

<!--
- the system must work in real space conditions
- brings some constraints
  - cant access the hardware once it is in space
  - are compute and power constraint
  - only have a constraint and unreliable communication link up
- [click]
- translated into the system requirements
  - any number and type of camera should be supported
  - if any of those cameras fails, the rest should still transmit the signal down
  - remotely update the firmware
  - a failed update can't break the system
  - firmware needs to be small enough to be transmitted via single overpass
    – numbers from MOVE-IIIa were used
-->

---
clicks: 4
---

<PackageDiagram :step="$clicks" />

<!--
- This is global package architecture – all written in Rust
- All of these are libraries that are somewhat independent to each other
- Sstv is only used for encoding and decoding of tones and images
  - Separating it makes sense since it has a much wider potential user group
  - Optimized for minimal memory footprint and compute cycles
  - Already has all common modes included for encoding and decoding with support for common audio and image formats – out of scope
- Beacon is the modular framework for all satellite operators building their own sstv payload
  - Exposes the algorithms and device interfaces via Rust functions and traits
  - Heart of the thesis
- Beacon-on-moveiiia is the firmware running on the MOVE-IIIa sstv payload
  - Imports the functions and traits from beacon
- Beacon-on-tab5 is another implementation used in the verification
-->

---
clicks: 4
---

<SstvIbd :step="$clicks" />

<div class="absolute code-panel" style="left: 120px; top: 400px; width: 1040px">

```rust {all|1|2|3|4-6}
let pixels = ...; // source of the image as an iterator over each pixel
let tones = Encoder::new(ROBOT_36, pixels)?;
let samples = Synthesizer::new(tones, SAMPLE_RATE);
for sample in samples {
    ... // output of each sample
}
```

</div>

<!--
- here is the public interface of the SSTV crate encoder path
- ibd above and how a user would implement it in the code below [click]
- need to supply an image as an iterator over pixels
  - could be pulling directly from camera buffer
  - or an image stored on the device [click]
- encoder then takes pixels and a mode and outputs an iterator of tones
  - each tone is defined by a frequency and a duration [click]
- synthesizer then converts the tones into samples
  - represented by a 16 bit signed integer [click]
- user can then emit or store those samples
- encoder only ever buffers two rows
  - for Robot36, takes as little as 1.9 kB memory
-->

---

<StateDiagram />

<!--
QUESTION: how do I best explain the states
-->

---
clicks: 3
---

<TraitMap :step="$clicks" />

<div class="absolute code-panel step-only" style="left: 340px; top: 150px" :class="{ shown: $clicks === 1 }">

```rust
pub trait Camera {
    fn power_on(&mut self);
    fn power_off(&mut self);
    fn calibrate(&mut self);
    fn receive_frame(&mut self) -> Image;

    fn capture(&mut self) -> Image {
        self.power_on();
        self.calibrate();
        let image = self.receive_frame();
        self.power_off();
        image
    }
}
```

</div>

<!--
- any type of camera, audio device and command link should be supported
- achieved via Rust traits
- [click] defines the methods each trait implementation has to implement
- for example for the camera, it defines one method for each part of the capturing pipeline
- [click] here are the implementations
- for the camera
  - one implementation for each physical camera
  - RGB and thermal cam for MOVE-IIIa and only one RGB cam for the tab5
- similarly for the other devices
- [click] this is what the methods then take as arguments for the camera
- vector with any number of cameras
- option means cameras that have failed initialization are covered
- dyn camera means any implementation of the camera trait
-->

---

<div class="absolute inset-0 flex items-center justify-center">
  <div class="placeholder">Listing of transmit_sstv()</div>
</div>

<!--
- Function for transmitting the sstv signal once the command has been received
- The caller can hand in any number of cameras
- Only images from the working cameras are captured
- 5s waiting time between each transmission
-->

---

<table class="coverage">
  <thead>
    <tr>
      <th></th>
      <th>Static checks</th>
      <th>Unit tests</th>
      <th>Integration tests</th>
    </tr>
  </thead>
  <tbody>
    <tr><td>sstv</td><td>✓</td><td>✓</td><td class="none">–</td></tr>
    <tr><td>beacon</td><td>✓</td><td>✓</td><td class="none">–</td></tr>
    <tr><td>beacon-on-moveiiia</td><td>✓</td><td class="none">–</td><td>✓</td></tr>
    <tr><td>beacon-on-tab5</td><td>✓</td><td class="none">–</td><td>✓</td></tr>
  </tbody>
</table>

<!--
- multi layered verification approach
- different strategy for each crate
- static checks performed on all of the crates
  - checks for basic code quality without running the code
- unit tests performed only on the libraries
  - tests basic functionality without a hardware connection
- integration tests for wholistic validation on the actual hardware
-->

---

<QaGate />

<!--
- here are the static checks
- in reality there are more but these are the most important
- triggered whenever the user tries to commit
- rustfmt applies standard formating rules
  - fixes spacing, applies line-breaks, breaks up lines that are too long ...
- clippy is a linter
  - checks for bad patterns, bad algorithms, deprecated calls, ...
  - all rules that are not strictly enforced by the compiler
- changes only enter git history if all checks pass
  - no bad code can be committed -> rolling back to any commit is safe
- if the developer does not enforce on their machine, it is checked in a pipeline in the cloud
-->

---
clicks: 1
---

<FakeMap :step="$clicks" />

<div class="absolute code-panel step-only" style="left: 50%; top: 480px; transform: translateX(-50%)" :class="{ shown: $clicks >= 1 }">

```rust
let mut cameras = vec![missing_camera(), working_camera(), missing_camera()];
let mut audio = FakeAudio::new();
transmit_sstv(&mut cameras, &mut audio)?;
assert_eq!(audio.completed_transmissions(), 1);
```

</div>

<!--
- unit tests for beacon crate
- another benefit of modularizing the library
  - we can implement fake devices to simulate the hardware
  - for each trait, there is one fake device
- [click] tests then cover one specific scenario
- in this case, 3 cameras, 1 working, 2 did not initialize
- we test the sstv transmission
- only a single transmission should have reached the audio device
- the failure of a single unit test also prevents the developer from committing
-->

---
clicks: 4
---

<IntegrationSetup :step="$clicks" />

<!--
- finally here is the integration setup for move-iiia
- have the SSTV system (on the right)
- connected to a RaspBerry Pi which acts like the other satellite systems and the ground station
- a RS422 transceiver for the commanding link since the Raspberry Pi does not support RS422 natively
- this is how one of those tests would be conducted
-->

---

<table class="verify">
  <thead>
    <tr><th>Requirement</th><th>Integration tests</th><th></th></tr>
  </thead>
  <tbody>
    <tr><td>Supports any number of cameras</td><td>both cameras</td><td>✓</td></tr>
    <tr><td>Keeps transmitting when a camera fails</td><td>RGB only · thermal only</td><td>✓</td></tr>
    <tr><td>Firmware updates over the uplink</td><td>successful update</td><td>✓</td></tr>
    <tr><td>Survives a failed update</td><td>incomplete · corrupt · chunk incomplete<br>data before begin · end before begin · wrong offset</td><td>✓</td></tr>
  </tbody>
</table>

<!--
- a number of different tests were conducted
- each for a different scenario
- one test with both cameras, one for each camera failing
- updates were tested once for the successful case and then every failure path
- at the end, all requirements could be verified

- then for modularity verification I wrote beacon-for-tab5
- device won't go to space but has all parts necessary to act as an SSTV payload
- single camera
- same chip as MOVE-IIIa
- speakers to emit SSTV audio
- ran all of the integration tests on this device as well
  - also passed
- since we can easily use beacon on other devices, it is modular
-->

---

<div class="absolute text-[64px] font-thin" style="left: 22.8%; top: 43.9%; width: 54.4%">
  Ready to see it in action?
</div>

<!--
- tab5 also allows us to do a live demo here
- everybody ok with taking a photo?
-->
