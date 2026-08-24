#import "@preview/acrostiche:0.7.0": acr

= Theoretical Foundation

== Slow-Scan Television

=== Frequency Modulation

#acr("SSTV") as an analog technology fundamentally relies on tones modulated onto much higher frequency radio waves to transmit the image. This is done the same way that most analog radio station transfer sounds today, via #acr("FM") @sstv-handbook[p.~14].

- TODO

=== Synchronization

In order to convert a one-dimensional audio signal to a two-dimensional image, special signals need to be defined to announce the start of an imgae (vertical synchronization) and the start of a new line (horizontal synchronization).

==== Vertical Synchronization

Vertical synchronization allows the decoder to automatically detect the start of a transmission. While not strictly mandatory, most SSTV programs include VOX tones before the actual image is transmitted. These are meant to engage voice-activated transmitters and communicate the full bandwidth of the signal allowing operators to tune their radios.

#figure(
  table(
    columns: 2,
    align: left,
    [*Duration [ms]*], [*Frequency [Hz]*],
    [100], [1900],
    [100], [1500],
    [100], [1900],
    [100], [1500],
    [100], [2300],
    [100], [1500],
    [100], [2300],
    [100], [1500],
  ),
  caption: [VOX tones @vox-codes.],
)

Each image encoded via Robot 36C starts with a predefined set of tones called the #acr("VIS") code containing sequences for tuning, calibration and mode identification. Each mode has a unique identification number transmitted in binary form where a zero is represented by a 1100 Hz tone and a one by a 1300 Hz tone. The identification number for Robot 36C is 8 in decimal or 0001000 in binary. The parity bit is used as a simple error detection mechanism. If the number of ones in the identification is odd, a one is used. If it is even, a zero is. This results in the following #acr("VIS") code @daytona-paper.

#figure(
  table(
    columns: 3,
    align: left,
    [*Duration [ms]*], [*Frequency [Hz]*], [*Identity*],
    [300], [1900], [Leader tone],
    [10], [1200], [Break],
    [300], [1900], [Leader tone],
    [30], [1200], [#acr("VIS") start bit],
    [30], [1100], [Identification bit 0],
    [30], [1100], [Identification bit 1],
    [30], [1100], [Identification bit 2],
    [30], [1300], [Identification bit 3],
    [30], [1100], [Identification bit 4],
    [30], [1100], [Identification bit 5],
    [30], [1100], [Identification bit 6],
    [30], [1300], [Identification parity bit],
    [30], [1200], [#acr("VIS") stop bit],
  ),
  caption: [Robot 36C #acr("VIS") code @daytona-paper.],
)

==== Horizontal Synchronization

Horizontal synchronization in Robot 36C is handled in two ways. Firstly, each line has the exact same duration. Therefore, if the first line is correctly synchronized and the durations stays consistent, the decoder can infer the row each pixel belongs to by timing along @sstv-handbook[p.~24]. In addition, a 9 ms sync pulse of 1200 Hz and a 3 ms sync porch of 1500 Hz preceed every line aiding synchronization @daytona-paper[p.~5].

=== Composite Color Model

Digital color is usually encoded via RGB, an additive color model, where every color is decomposed into its primary components red, green and blue. Alternatively, a color can be represented by YUV, a composite color model. In YUV, the color information of each pixel is separated from the brightness information @sstv-handbook[p.~3]. The Y component stores the brightness of each pixel derived from the red ($R$), green ($G$) and blue ($B$) components via @eq-luminance @video-demystified[p.~18].

$ Y = 0.257 dot R + 0.504 dot G + 0.098 dot B + 16 $ <eq-luminance>

The blue chromiance component ($U$) represents the where on the yellow (lower values) to blue (higher values) spectrum the pixel color is located @video-demystified[p.~18].

$ U = - 0.148 dot R - 0.291 dot G + 0.439 dot B + 128 $ <eq-chromiance-blue>

Likewise, the red chromiance component ($V$) transmits how cyan (lowe values) or red (higher values) the pixel is @video-demystified[p.~18].

$ V = 0.439 dot R + 0.368 dot G - 0.071 dot B + 128 $ <eq-chromiance-red>

#figure(
  image("../figures/rgb-vs-yuv.svg", width: 100%),
  caption: [Basic color composition for RGB (left) and YUV (right) @sstv-handbook[pp.~20-22]],
) <img-rgb-vs-yuv>


=== Robot 36 Color Model



== Software Modularization
