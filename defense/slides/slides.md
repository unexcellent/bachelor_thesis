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

<div class="absolute placeholder" style="left: 8.9%; top: 29%; width: 26%">List of important constraints</div>
<div class="absolute text-[64px] font-thin" style="left: 45%; top: 44%">→</div>
<div class="absolute placeholder" style="left: 63.4%; top: 29%; width: 28%">List of important requirements</div>

<!--
- The system must work in real space conditions
  - Brings some constraints
  - Can't access the hardware once it is in space
  - Are compute and power constraint
  - Only have a constraint and unreliable communication link up
- Translated into the system requirements that means
  - We need to be able to remotely update the firmware
  - A failed update can't permanently break the system
  - Any number and type of camera should be supported
  - If any of those cameras fails, the rest should still transmit the signal down
  - Firmware needs to be small enough to be transmitted via single overpass – numbers from MOVE-IIIa were used
-->

---

<div class="absolute inset-0 flex items-center justify-center">
  <div class="placeholder">Package diagram</div>
</div>

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

<div class="absolute inset-0 flex items-center justify-center">
  <div class="placeholder">Sstv crate</div>
</div>

---

<div class="absolute inset-0 flex items-center justify-center">
  <div class="placeholder">beacon state diagram</div>
</div>

<!--
QUESTION: how do I best explain the states
-->

---

<div class="absolute inset-0 flex items-center justify-center gap-16">
  <div class="placeholder">Listing of the camera trait</div>
  <div class="placeholder">Listing of move-iiia implementations</div>
</div>

<!--
- The goal is to allow any number of cameras and a wide array of camera models
- Achieved via Rust traits
  - Any struct that implements the trait needs to implement these specific methods
- Here we see the implementations for MOVE-IIIa
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

<img src="/img/pre_commit.png" class="absolute" style="left: 2.5%; top: 10.9%; width: 95%; height: 78.1%" />

---

<div class="absolute inset-0 flex items-center justify-center">
  <div class="placeholder">Drawing of the integration test setup</div>
</div>

---

<div class="absolute text-[64px] font-thin" style="left: 22.8%; top: 43.9%; width: 54.4%">
  Ready to see it in action?
</div>

---

