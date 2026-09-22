#import "@preview/acrostiche:0.7.0": acr

= Theoretical Foundation

== Slow-Scan Television

=== Frequency Modulation

#acr("SSTV") as an analog technology fundamentally relies on tones modulated onto much higher frequency radio waves to transmit the image. This is done the same way that most analog radio station transfer sounds today, via #acr("FM") @sstv-handbook[p.~14]. The technique is illustrated in @img-fm.

#figure(
  image("../figures/frequency-modulation.svg", width: 80%),
  caption: [Frequenyc modulation of a carrier wvae by a single-period sine signal (frequency shift exaggerated for illustration).],
) <img-fm>

#acr("FM") is an angle modulation method, in which a source signal $f(t)$ controls the argument of a carrier wave rather than its amplitude. The modulated signal can be calculated by @eq-fm-signal with $f_0$ denoting the carrier frequency and $c$ denoting a modulator constant @signal-uebertragung[pp.~368-370].

$
  m(t) = cos(2 pi f_0 t + 2 pi c integral_(-oo)^t f(tau) dif tau)
$ <eq-fm-signal>

The information encoded in the signal is contained in its instantaneous frequency $f_i (t)$ which is the time derivative of the cosine argument. As described in @eq-instantaneous-frequency, $f_i$ deviates from the carrier frequency proportionally to the source signal.

$
  f_i (t) = 1 / (2 pi) dot dif / (dif t) (2 pi f_0 t + 2 pi c integral_(-oo)^t f(tau) dif tau) = f_0 + c dot f(t)
$ <eq-instantaneous-frequency>

Since the amplitude of the modulated signal carries no information, #acr("FM") is more robust to noise but requires a higher transmission bandwidth @signal-uebertragung[p.~368].

In the case of #acr("SSTV"), this means that all image information is entirely encoded in the instantaneous frequency of the received signal and can therefore be described as a series of frequencies and their durations.

=== Synchronization

In order to convert a one-dimensional audio signal to a two-dimensional image, special signals need to be defined to announce the start of an imgae (vertical synchronization) and the start of a new line (horizontal synchronization).

==== Vertical Synchronization

Vertical synchronization allows the decoder to automatically detect the start of a transmission. While not strictly mandatory, most #acr("SSTV") programs include the VOX tones displayed in @img-vox before the actual image is transmitted. These are meant to engage voice-activated transmitters and communicate the full bandwidth of the signal allowing operators to tune their radios @vox-codes.

#figure(
  image("../figures/vox-tones.svg", width: 100%),
  caption: [VOX tones used by the most #acr("SSTV") programs.],
) <img-vox>

Each image encoded via Robot 36C starts with a predefined set of tones called the #acr("VIS") code containing sequences for tuning, calibration and mode identification. Each mode has a unique identification number transmitted in binary form where a zero is represented by a 1100 Hz tone and a one by a 1300 Hz tone. The identification number for Robot 36C is 8 in decimal or 0001000 in binary. The parity bit is used as a simple error detection mechanism. If the number of ones in the identification is odd, a one is used. If it is even, a zero is. This results in the #acr("VIS") code in @img-vis @daytona-paper.

#figure(
  image("../figures/vis-code.svg", width: 100%),
  caption: [Robot 36C #acr("VIS") code.],
) <img-vis>

==== Horizontal Synchronization

Horizontal synchronization in Robot 36C is handled in two ways. Firstly, each line has the exact same duration. Therefore, if the first line is correctly synchronized and the durations stays consistent, the decoder can infer the row each pixel belongs to by timing along @sstv-handbook[p.~24]. In addition, a 9 ms sync pulse of 1200 Hz and a 3 ms sync porch of 1500 Hz preceed every line aiding synchronization @daytona-paper[p.~5].

=== Composite Color Model

Digital color is usually encoded via RGB, an additive color model, where every color is decomposed into its primary components red, green and blue. Alternatively, a color can be represented by YUV, a composite color model. In YUV, the color information of each pixel is separated from the brightness information @sstv-handbook[p.~3]. The Y component stores the brightness of each pixel derived from the red ($R$), green ($G$) and blue ($B$) components via @eq-luminance @video-demystified[p.~18].

$ Y = 0.257 dot R + 0.504 dot G + 0.098 dot B + 16 $ <eq-luminance>

The blue chromiance component ($U$) represents the where on the yellow (lower values) to blue (higher values) spectrum the pixel color is located @video-demystified[p.~18].

$ U = - 0.148 dot R - 0.291 dot G + 0.439 dot B + 128 $ <eq-chromiance-blue>

Likewise, the red chromiance component ($V$) transmits how cyan (lowe values) or red (higher values) the pixel is @video-demystified[p.~18].

$ V = 0.439 dot R + 0.368 dot G - 0.071 dot B + 128 $ <eq-chromiance-red>

@img-rgb-vs-yuv compares the two color encodings.

#figure(
  image("../figures/rgb-vs-yuv.svg", width: 100%),
  caption: [Basic color composition for RGB (left) and YUV (right) @sstv-handbook[pp.~20-22]],
) <img-rgb-vs-yuv>

=== Robot 36 Color Model

Robot 36 tries to maximize image quality while keeping transmission time to a minimum. Since the human eye can identify differences in luminosity much better than differences in chromiance, YUV is a natural choice for Robot 36. While the mode transmits luminance for every line, it only transmits blue chromiance for odd lines and red chromiance for even. While this fundamentally blends lines together vertically in a lossy process, the image appearance is mostly kept intact @daytona-paper[p.~5].

@img-robot36-lines shows two of the 240 scan-lines of a Robot 36C image.

#figure(
  image("../figures/horizontal-synchronization.svg", width: 100%),
  caption: [Two scan-lines of a Robot 36C transmission.],
) <img-robot36-lines>

== Modular Programming

Modular programming has been a corner stone in quality software since at least the 1970s. Applying those principles yields benefits in the following domains @parnas-criteria[p.~1054]:
- *Velocity*: Development will be accelerated due to less need for communication between developers.
- *Flexibility*: Modules can be substantially changed without the need to change the rest of the system.
- *Comprehensibility*: To understand parts of a system does not require in-depth knowledge of the system's other parts.
For this thesis, the main benefit of modularization is that the #acr("SSTV") firmware can be ported to new hardware by replacing only its hardware-specific modules @parnas-extension[p.~129].

The following sections detail how modularity can be achieved.

=== Modules and Information Hiding

A module in software engineering refers to part of a program that groups related functionality separated from the rest of the system @iso-24765[p.~279]. In that regard, it describes less a unit of code than a unit of responsibility. In a well modularized system, every modules is responsible for one design decision which it hides from all other parts of the system. Generally, the decision to hide are the ones most likely to change since a change to those hidden decisions does not propagate to the rest of the system @parnas-criteria[p.~1056]. The process of concealing the module's inner logic is called information hiding @iso-24765[p.~220].

=== Interfaces

A module exposes its functionality through public interfaces which should reveal as little as possible about the hidden decisions why still communicating how the module should be used @parnas-criteria[p.~1056]. Each interface is comprised of two parts. The formal part contains signatures and types and is usually enforced by the programming language. The informal part covers the behavior of the module or nuanced rules that need to be communicated through documentation @philosophy-of-software[ch.~4.2].

=== Program Families

If a set of programs is designed as variations of a common design, they are called a program family. In a well constructed system, family members can be derived by adding, removing or replacing modules instead of modifying them. Every family member can then benefit from changes made to those modules @parnas-extension[p.~129-131].

