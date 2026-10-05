<script setup lang="ts">
import { onSlideEnter, onSlideLeave } from '@slidev/client'
import { onBeforeUnmount, onMounted, ref } from 'vue'
import { renderTone, useSlideAudio } from '../lib/audio'
import { BLACK_HZ, drawPixels as drawImageData, levelToHz, loadImage, luma, PIXEL_MS, samplePixels, setupCanvas, WHITE_HZ } from '../lib/robot36'

/**
 * Encodes an image pixel by pixel into SSTV tones and decodes it again on the fly.
 *
 * Left: the source image at Robot 36 resolution with the pixel currently being
 * sent. Middle: the audio samples of the last few pixels. Right: the received
 * image.
 *
 * Reception noise is simulated where it happens on air, on the tone frequency:
 * it is correlated along the scan line (streaks), clips at black and white,
 * shares chroma errors across line pairs like Robot 36 and occasionally hits a
 * line segment with a fade.
 *
 * Each pixel is one tone of Robot 36 pixel length (0.275 ms), mapped linearly
 * from 1500 Hz (black) to 2300 Hz (white) by its luminance (Dayton paper).
 * Sync pulses are left out to keep the slide focused. The tones play at the
 * same pace as the animation.
 */
const props = withDefaults(defineProps<{
  src: string
  /** Grid width in cells; the height follows from the 4:3 aspect ratio. */
  cols?: number
  /** Wall-clock milliseconds the scan spends on each cell; 0.275 is real time. */
  cellMs?: number
  /** Signal milliseconds shown in the audio line. */
  windowMs?: number
  /** Standard deviation of the frequency error at the receiver, in Hz. */
  noise?: number
}>(), {
  cols: 320,
  cellMs: 0.6875,
  windowMs: 9,
  noise: 55,
})

const cols = props.cols
const rows = Math.round((props.cols * 3) / 4)
const cells = cols * rows

const sourceCanvas = ref<HTMLCanvasElement>()
const audioCanvas = ref<HTMLCanvasElement>()
const decodedCanvas = ref<HTMLCanvasElement>()

let cellRgb: Uint8ClampedArray | undefined
let cellHz: Float32Array | undefined
// Cycles elapsed at the start of each cell, so the waveform phase stays continuous across frames.
let cellCycles: Float64Array | undefined
let source: ImageData | undefined
let decoded: Uint8ClampedArray | undefined
let received: ImageData | undefined
let decodedCells = 0
let frame = 0
let startedAt = 0
let signalMs = 0
let active = false
let scanAudio: AudioBuffer | undefined
const audio = useSlideAudio()

function gaussian(rand: () => number) {
  return Math.sqrt(-2 * Math.log(1 - rand())) * Math.cos(2 * Math.PI * rand())
}

/** mulberry32 */
function seeded(seed: number) {
  return () => {
    seed = (seed + 0x6D2B79F5) | 0
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed)
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}

function analyse(img: HTMLImageElement) {
  source = samplePixels(img, cols, rows)
  cellRgb = source.data

  cellHz = new Float32Array(cells)
  cellCycles = new Float64Array(cells + 1)
  for (let i = 0; i < cells; i++) {
    cellHz[i] = levelToHz(luma(cellRgb[i * 4], cellRgb[i * 4 + 1], cellRgb[i * 4 + 2]))
    cellCycles[i + 1] = cellCycles[i] + (cellHz[i] * PIXEL_MS) / 1000
  }
  decoded = simulateReception(cellRgb)
  received = new ImageData(cols, rows)
}

function simulateReception(rgb: Uint8ClampedArray) {
  const out = new Uint8ClampedArray(rgb.length)
  const rand = seeded(1)
  const hzToLevel = 255 / (WHITE_HZ - BLACK_HZ)
  // One-pole low-pass over successive pixels turns white noise into horizontal streaks.
  const smooth = 0.65
  const uNoise = new Float32Array(cols)
  const vNoise = new Float32Array(cols)

  for (let y = 0; y < rows; y++) {
    const fade = rand() < 0.05
    const fadeStart = rand() * cols
    const fadeEnd = fadeStart + 20 + rand() * 120
    if (y % 2 === 0) {
      let u = 0
      let v = 0
      for (let x = 0; x < cols; x++) {
        u = smooth * u + (1 - smooth) * gaussian(rand) * props.noise * 1.4
        v = smooth * v + (1 - smooth) * gaussian(rand) * props.noise * 1.4
        uNoise[x] = u * hzToLevel
        vNoise[x] = v * hzToLevel
      }
    }

    let n = 0
    for (let x = 0; x < cols; x++) {
      const i = (y * cols + x) * 4
      const r = rgb[i]
      const g = rgb[i + 1]
      const b = rgb[i + 2]
      const l = luma(r, g, b)
      const amp = fade && x >= fadeStart && x < fadeEnd ? 5 : 1
      n = smooth * n + (1 - smooth) * gaussian(rand) * props.noise * amp
      const yy = Math.min(255, Math.max(0, l + n * hzToLevel))
      const u = 0.492 * (b - l) + uNoise[x] * amp
      const v = 0.877 * (r - l) + vNoise[x] * amp
      const rr = yy + v / 0.877
      const bb = yy + u / 0.492
      out[i] = rr
      out[i + 1] = (yy - 0.299 * rr - 0.114 * bb) / 0.587
      out[i + 2] = bb
      out[i + 3] = 255
    }
  }
  return out
}

function drawMarker(ctx: CanvasRenderingContext2D, w: number, h: number, band: boolean) {
  if (!startedAt || decodedCells >= cells)
    return
  const cell = Math.min(cells - 1, Math.floor(signalMs / PIXEL_MS))
  const cw = w / cols
  const ch = h / rows
  const cx = ((cell % cols) + 0.5) * cw
  const cy = (Math.floor(cell / cols) + 0.5) * ch

  if (band) {
    ctx.fillStyle = 'rgba(255, 255, 255, 0.15)'
    ctx.fillRect(0, cy - ch / 2, w, ch)
  }
  const size = Math.max(cw, 6)
  ctx.shadowColor = 'rgba(255, 255, 255, 0.9)'
  ctx.shadowBlur = 10
  ctx.fillStyle = '#ffffff'
  ctx.fillRect(cx - size / 2, cy - size / 2, size, size)
  ctx.shadowBlur = 0
}

function drawPixels(canvas: HTMLCanvasElement | undefined, pixels: ImageData | undefined, band: boolean) {
  if (!canvas || !pixels)
    return
  const { ctx, w, h } = drawImageData(canvas, pixels)
  drawMarker(ctx, w, h, band)
}

function cyclesAt(ms: number) {
  const cell = Math.min(cells - 1, Math.floor(ms / PIXEL_MS))
  return cellCycles![cell] + (cellHz![cell] * (ms - cell * PIXEL_MS)) / 1000
}

function drawAudio() {
  const canvas = audioCanvas.value
  if (!canvas || !cellHz)
    return
  const { ctx, w, h } = setupCanvas(canvas)
  const mid = h / 2
  const amp = h * 0.38

  ctx.strokeStyle = '#fdfdfd'
  ctx.lineWidth = 1.25
  ctx.lineJoin = 'round'
  ctx.beginPath()
  const steps = Math.ceil(w * 2)
  const sampleMs = props.windowMs / steps
  for (let i = 0; i <= steps; i++) {
    const ms = signalMs - props.windowMs + i * sampleMs
    const x = (1 - i / steps) * w
    let y = mid
    if (ms >= 0 && startedAt) {
      // Seeded by absolute sample index so the noise scrolls with the signal instead of flickering.
      const n = gaussian(seeded(Math.floor(ms / sampleMs))) * 0.06
      y = mid - (Math.sin(2 * Math.PI * cyclesAt(ms)) + n) * amp
    }
    if (i === 0)
      ctx.moveTo(x, y)
    else
      ctx.lineTo(x, y)
  }
  ctx.stroke()
}

function decodeUpTo(target: number) {
  if (!received || !decoded || target <= decodedCells)
    return
  received.data.set(decoded.subarray(decodedCells * 4, target * 4), decodedCells * 4)
  decodedCells = target
}

function render() {
  drawPixels(sourceCanvas.value, source, true)
  drawAudio()
  drawPixels(decodedCanvas.value, received, false)
}

function tick(now: number) {
  if (!startedAt)
    startedAt = now
  signalMs = Math.min(cells * PIXEL_MS, ((now - startedAt) / props.cellMs) * PIXEL_MS)
  decodeUpTo(Math.floor(signalMs / PIXEL_MS))
  render()
  if (decodedCells < cells)
    frame = requestAnimationFrame(tick)
}

function stop() {
  cancelAnimationFrame(frame)
  frame = 0
}

function restart() {
  stop()
  startedAt = 0
  signalMs = 0
  decodedCells = 0
  if (cellRgb)
    received = new ImageData(cols, rows)
  render()
  if (!cellHz)
    return
  frame = requestAnimationFrame(tick)
  audio.play(() => scanAudio ??= renderTone(cells * props.cellMs, ms => cellHz![Math.min(cells - 1, Math.floor(ms / props.cellMs))]))
}

onMounted(async () => {
  analyse(await loadImage(props.src))
  if (active)
    restart()
  else
    render()
})

onSlideEnter(() => {
  active = true
  restart()
})

onSlideLeave(() => {
  active = false
  stop()
})

onBeforeUnmount(stop)
</script>

<template>
  <div class="sstv-scan">
    <canvas ref="sourceCanvas" class="frame" />
    <canvas ref="audioCanvas" class="audio" />
    <canvas ref="decodedCanvas" class="frame" />
  </div>
</template>

<style scoped>
.sstv-scan {
  position: absolute;
  inset: 0;
  display: grid;
  grid-template-columns: 320px 1fr 320px;
  gap: 48px;
  align-items: center;
  padding: 0 64px;
}

.frame {
  width: 320px;
  height: 240px;
}

.audio {
  width: 100%;
  height: 140px;
}
</style>
