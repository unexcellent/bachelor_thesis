#import "@preview/acrostiche:0.7.0": acr

= Theoretical Foundation

== Slow-Scan Television

=== Frequency Modulation

#acr("SSTV"), as an analogue technology, relies on tones modulated onto much higher-frequency radio waves to transmit the image. This is done the same way that most analogue radio stations transmit sound today, via #acr("FM") @sstv-handbook[p.~14]. The technique is illustrated in @img-fm.

#figure(
  image("../figures/frequency-modulation.svg", width: 80%),
  caption: [Frequency modulation of a carrier wave by a single-period sine signal (frequency shift exaggerated for illustration).],
) <img-fm>

#acr("FM") is an angle modulation method, in which a source signal $f(t)$ controls the argument of a carrier wave rather than its amplitude. The modulated signal can be calculated by @eq-fm-signal with $f_0$ denoting the carrier frequency and $c$ denoting a modulation constant @signal-uebertragung[pp.~368–370].

$
  m(t) = cos(2 pi f_0 t + 2 pi c integral_(-oo)^t f(tau) dif tau)
$ <eq-fm-signal>

The information encoded in the signal is contained in its instantaneous frequency $f_i (t)$, which is the time derivative of the cosine argument divided by $2 pi$. As described in @eq-instantaneous-frequency, $f_i$ deviates from the carrier frequency proportionally to the source signal.

$
  f_i (t) = 1 / (2 pi) dot dif / (dif t) (2 pi f_0 t + 2 pi c integral_(-oo)^t f(tau) dif tau) = f_0 + c dot f(t)
$ <eq-instantaneous-frequency>

Since the amplitude of the modulated signal carries no information, #acr("FM") is more robust to noise but requires a higher transmission bandwidth @signal-uebertragung[p.~368].

In the case of #acr("SSTV"), this means that all image information is encoded in the instantaneous frequency of the received signal and can therefore be described as a series of frequencies and their durations.

=== Synchronization

To convert a one-dimensional audio signal to a two-dimensional image, special signals need to be defined to announce the start of an image (vertical synchronization) and the start of a new line (horizontal synchronization).

==== Vertical Synchronization

Vertical synchronization allows the decoder to automatically detect the start of a transmission. While not strictly mandatory, most #acr("SSTV") programs include the VOX tones displayed in @img-vox before the actual image is transmitted. These are meant to engage voice-activated transmitters and communicate the full bandwidth of the signal, allowing operators to tune their radios @vox-codes.

#figure(
  image("../figures/vox-tones.svg", width: 100%),
  caption: [VOX tones used by most #acr("SSTV") programs.],
) <img-vox>

Robot 36 is an #acr("SSTV") mode that transmits a colour image of 320 × 240 pixels in 36 seconds @daytona-paper. Each image encoded via Robot 36 starts with a predefined set of tones called the #acr("VIS") code, containing sequences for tuning, calibration and mode identification. Each mode has a unique identification number transmitted in binary form where a zero is represented by a 1300 Hz tone and a one by a 1100 Hz tone. The identification number for Robot 36 is 8 in decimal or 0001000 in binary. An additional parity bit serves as a simple error detection mechanism. If the number of ones in the identification is odd, a one is used. Otherwise, a zero is used. This results in the #acr("VIS") code in @img-vis @daytona-paper.

#figure(
  image("../figures/vis-code.svg", width: 100%),
  caption: [Robot 36 #acr("VIS") code.],
) <img-vis>

==== Horizontal Synchronization

Horizontal synchronization in Robot 36 is handled in two ways. Firstly, each line has the exact same duration. Therefore, if the first line is correctly synchronized and the duration stays consistent, the decoder can infer the row each pixel belongs to by timing alone @sstv-handbook[p.~24]. In addition, a 9 ms sync pulse of 1200 Hz and a 3 ms sync porch of 1500 Hz precede every line, aiding synchronization @daytona-paper[p.~5].

=== Composite Colour Model

Digital colour is usually encoded via RGB, an additive colour model, where every colour is decomposed into its primary components red, green and blue. Alternatively, a colour can be represented by YUV, a composite colour model. In YUV, the colour information of each pixel is separated from the brightness information @sstv-handbook[p.~3]. The Y component stores the brightness of each pixel derived from the red ($R$), green ($G$) and blue ($B$) components via @eq-luminance @video-demystified[p.~18].

$ Y = 0.257 dot R + 0.504 dot G + 0.098 dot B + 16 $ <eq-luminance>

The blue chrominance component ($U$) represents where on the yellow (lower values) to blue (higher values) spectrum the pixel colour is located @video-demystified[p.~18].

$ U = - 0.148 dot R - 0.291 dot G + 0.439 dot B + 128 $ <eq-chrominance-blue>

Likewise, the red chrominance component ($V$) represents how cyan (lower values) or red (higher values) the pixel is @video-demystified[p.~18].

$ V = 0.439 dot R + 0.368 dot G - 0.071 dot B + 128 $ <eq-chrominance-red>

@img-rgb-vs-yuv compares the two colour encodings.

#figure(
  image("../figures/rgb-vs-yuv.svg", width: 100%),
  caption: [Basic colour composition for RGB (left) and YUV (right) @sstv-handbook[pp.~20-22].],
) <img-rgb-vs-yuv>

=== Robot 36 Colour Model

Robot 36 aims to maximize image quality while keeping transmission time to a minimum. Since the human eye can identify differences in luminance much better than differences in chrominance, YUV is a natural choice for Robot 36. While the mode transmits luminance for every line, it only transmits blue chrominance for odd lines and red chrominance for even ones. Although this lossy process blends the colour of adjacent lines, the image appearance is mostly kept intact @daytona-paper[p.~5].

@img-robot36-lines shows two of the 240 scan-lines of a Robot 36 image.

#figure(
  image("../figures/horizontal-synchronization.svg", width: 100%),
  caption: [Two scan-lines of a Robot 36 transmission.],
) <img-robot36-lines>

== Modular Programming

Modular programming has been a cornerstone of quality software since at least the 1970s. Applying those principles yields benefits in the following domains @parnas-criteria[p.~1054]:
- *Velocity*: Development will be accelerated due to a reduced need for communication between developers.
- *Flexibility*: Modules can be substantially changed without the need to change the rest of the system.
- *Comprehensibility*: Understanding parts of a system does not require in-depth knowledge of the system's other parts.
For this thesis, the main benefit of modularization is that the #acr("SSTV") firmware can be ported to new hardware by replacing only its hardware-specific modules @parnas-extension[p.~129].

The following sections detail how modularity can be achieved.

=== Modules and Information Hiding

A module in software engineering refers to a part of a program that groups related functionality and separates it from the rest of the system @iso-24765[p.~279]. In that regard, it describes less a unit of code than a unit of responsibility. In a well-modularized system, every module is responsible for one design decision which it hides from all other parts of the system. Generally, the decisions to hide are the ones most likely to change since a change to those hidden decisions does not propagate to the rest of the system @parnas-criteria[p.~1056]. The process of concealing the module's inner logic is called information hiding @iso-24765[p.~220].

=== Interfaces

A module exposes its functionality through public interfaces which should reveal as little as possible about the hidden decisions while still communicating how the module should be used @parnas-criteria[p.~1056]. Each interface comprises two parts. The formal part contains signatures and types and is usually enforced by the programming language. The informal part covers the behaviour of the module or nuanced rules that need to be communicated through documentation @philosophy-of-software[ch.~4.2].

=== Program Families

If a set of programs is designed as variations of a common design, they are called a program family. In a well-constructed system, family members can be derived by adding, removing or replacing modules instead of modifying them. Every family member can then benefit from changes made to those modules @parnas-extension[pp.~129–131].

