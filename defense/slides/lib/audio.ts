import { onSlideLeave, useIsSlideActive, useNav, useSlideContext } from '@slidev/client'
import { onBeforeUnmount } from 'vue'

/** SSTV tones are harsh, so stay well below full scale. */
const VOLUME = 0.12
const FADE_S = 0.01

let ctx: AudioContext | undefined
let master: GainNode | undefined

function context() {
  if (!ctx) {
    ctx = new AudioContext()
    master = ctx.createGain()
    master.gain.value = VOLUME
    master.connect(ctx.destination)
  }
  if (ctx.state === 'suspended')
    void ctx.resume()
  return ctx
}

/**
 * Renders a phase-continuous tone whose frequency follows `hzAt`, the way an
 * SSTV transmitter frequency-modulates a single oscillator.
 */
export function renderTone(durationMs: number, hzAt: (ms: number) => number) {
  const c = context()
  const rate = c.sampleRate
  const length = Math.ceil((durationMs / 1000) * rate)
  const buffer = c.createBuffer(1, length, rate)
  const data = buffer.getChannelData(0)
  const fade = Math.min(Math.floor(FADE_S * rate), length / 2)
  let phase = 0
  for (let i = 0; i < length; i++) {
    phase += (2 * Math.PI * hzAt((i / rate) * 1000)) / rate
    const edge = Math.min(1, i / fade, (length - 1 - i) / fade)
    data[i] = Math.sin(phase) * edge
  }
  return buffer
}

/**
 * Plays tones for the slide this is called from. Only the audience view of the
 * active slide makes sound, so the presenter window, overview thumbnails and
 * PDF export stay silent instead of doubling the audio.
 */
export function useSlideAudio() {
  const { $renderContext } = useSlideContext()
  const { isPrintMode } = useNav()
  const isActive = useIsSlideActive()
  let source: AudioBufferSourceNode | undefined

  function stop() {
    source?.stop()
    source?.disconnect()
    source = undefined
  }

  /** Takes a factory so no audio is rendered for views that stay silent. */
  function play(buffer: () => AudioBuffer | undefined) {
    stop()
    if ($renderContext.value !== 'slide' || isPrintMode.value || !isActive.value)
      return
    const b = buffer()
    if (!b)
      return
    const c = context()
    source = c.createBufferSource()
    source.buffer = b
    source.connect(master!)
    source.start()
  }

  onSlideLeave(stop)
  onBeforeUnmount(stop)
  return { play, stop }
}
