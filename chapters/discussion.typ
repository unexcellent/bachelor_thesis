#import "@preview/acrostiche:0.7.0": acr

= Discussion and Future Work

In this thesis, software was developed which takes images, encodes them via #acr("SSTV") and transmits them as audio. Two crates have been provided to the community. `sstv` is a hardware-agnostic #acr("SSTV") encoding and decoding library supporting the most common modes and has already found real-world use by the #link("slowscan.space") website. `beacon` provides functions and abstractions which can be integrated by satellite teams into their own #acr("SSTV") system with a diverse set of input and output devices.

Real-world applicabilityy of the software has been proven by an integration into the MOVE-IIIa #acr("SSTV") payload where the firmware passes all of the integration tests and almost all of the requirements. The only caveat is the large size of the firmware, restricting on which orbits an update can be transmitted to the satellite. Future work should focus on reducing the firmware size by - for example - removing the dependence on the `esp-idf` development framework and implementing bare-metal code.

Additionally, future work could expand on the features implemented in this thesis and suggested by the community in @tab-community-input. A potential feature with a likely low implementation complexity is the transmission of buffered images where community members would provide pictures for special occasions which are uploaded to the satellite and then transmitted instead of the camera captures. Another requested feature is the support for digital modes where the image quality is less suseptible to noise and higher quality images can be transmitted. Furthermore, the current implementation is entirely dependent on the pointing of the satellite to capture an interesting image. Without explicit support from the pointing system, a significant amount of captures would not feature parts of the Earth, but only the black of space or captures saturated by the Sun. A future feature could implement a metric for determining how interesting an image is and then store it for future transmission.


