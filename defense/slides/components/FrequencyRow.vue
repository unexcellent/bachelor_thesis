<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { renderTone, useSlideAudio } from '../lib/audio'
import { BLACK_HZ, HEIGHT, levelToHz, loadImage, luma, samplePixels, setupCanvas, WHITE_HZ, WIDTH } from '../lib/robot36'

/**
 * One Robot 36 scan line of an image above the tone frequency each of its pixels
 * produces. A cursor sweeps the line on the first click, draws the graph and
 * plays the tones at the cursor's pace.
 */
const props = withDefaults(defineProps<{
  src: string
  step?: number
  /** Image row (0 to 239) that is scanned. */
  row?: number
  /** Wall-clock milliseconds the cursor takes for the whole line. */
  sweepMs?: number
}>(), {
  step: 0,
  row: 40,
  sweepMs: 4000,
})

const BAND_ROWS = 60
const BAND_H = 180
const GAP = 48
const GRAPH_H = 260
const PAD = 12
const GRAPH_TOP = BAND_H + GAP
const WHITE_Y = GRAPH_TOP + PAD
const BLACK_Y = GRAPH_TOP + GRAPH_H - PAD

const canvas = ref<HTMLCanvasElement>()

let image: HTMLImageElement | undefined
let rowHz: Float32Array | undefined
let progress = props.step >= 1 ? 1 : 0
let frame = 0
let startedAt = 0
let sweepAudio: AudioBuffer | undefined
const audio = useSlideAudio()

function yOf(hz: number) {
  return WHITE_Y + (1 - (hz - BLACK_HZ) / (WHITE_HZ - BLACK_HZ)) * (BLACK_Y - WHITE_Y)
}

function draw() {
  if (!canvas.value || !image || !rowHz)
    return
  const { ctx, w } = setupCanvas(canvas.value)
  const bandStart = Math.max(0, Math.min(HEIGHT - BAND_ROWS, props.row - BAND_ROWS / 2))
  const srcRowH = image.naturalHeight / HEIGHT
  ctx.drawImage(image, 0, bandStart * srcRowH, image.naturalWidth, BAND_ROWS * srcRowH, 0, 0, w, BAND_H)

  const rowH = BAND_H / BAND_ROWS
  const rowY = (props.row - bandStart) * rowH
  ctx.fillStyle = 'rgba(12, 18, 22, 0.6)'
  ctx.fillRect(0, 0, w, rowY)
  ctx.fillRect(0, rowY + rowH, w, BAND_H - rowY - rowH)

  ctx.strokeStyle = 'rgba(253, 253, 253, 0.15)'
  ctx.lineWidth = 1
  for (const y of [WHITE_Y, BLACK_Y]) {
    ctx.beginPath()
    ctx.moveTo(0, y)
    ctx.lineTo(w, y)
    ctx.stroke()
  }

  const cut = progress * WIDTH
  const px = w / WIDTH
  ctx.strokeStyle = '#fdfdfd'
  ctx.lineWidth = 1.5
  ctx.lineJoin = 'round'
  ctx.beginPath()
  for (let i = 0; i < Math.ceil(cut); i++) {
    const y = yOf(rowHz[i])
    if (i === 0)
      ctx.moveTo(0, y)
    else
      ctx.lineTo(i * px, y)
    ctx.lineTo(Math.min(i + 1, cut) * px, y)
  }
  ctx.stroke()

  if (progress >= 1)
    return
  const x = cut * px
  ctx.strokeStyle = 'rgba(253, 253, 253, 0.4)'
  ctx.beginPath()
  ctx.moveTo(x, rowY + rowH)
  ctx.lineTo(x, GRAPH_TOP + GRAPH_H)
  ctx.stroke()
  ctx.shadowColor = 'rgba(255, 255, 255, 0.9)'
  ctx.shadowBlur = 10
  ctx.fillStyle = '#ffffff'
  ctx.fillRect(x - 4, rowY + rowH / 2 - 4, 8, 8)
  ctx.shadowBlur = 0
}

function tick(now: number) {
  if (!startedAt)
    startedAt = now
  progress = Math.min(1, (now - startedAt) / props.sweepMs)
  draw()
  if (progress < 1)
    frame = requestAnimationFrame(tick)
}

function stop() {
  cancelAnimationFrame(frame)
  frame = 0
}

function restart() {
  stop()
  startedAt = 0
  progress = 0
  draw()
  if (!rowHz)
    return
  frame = requestAnimationFrame(tick)
  audio.play(() => sweepAudio ??= renderTone(props.sweepMs, ms => rowHz![Math.min(WIDTH - 1, Math.floor((ms / props.sweepMs) * WIDTH))]))
}

onMounted(async () => {
  image = await loadImage(props.src)
  const { data } = samplePixels(image)
  rowHz = new Float32Array(WIDTH)
  for (let x = 0; x < WIDTH; x++) {
    const i = (props.row * WIDTH + x) * 4
    rowHz[x] = levelToHz(luma(data[i], data[i + 1], data[i + 2]))
  }
  draw()
})

watch(() => props.step >= 1, (sweep) => {
  if (sweep) {
    restart()
  }
  else {
    stop()
    audio.stop()
    progress = 0
    draw()
  }
})

onBeforeUnmount(stop)
</script>

<template>
  <div class="frequency-row">
    <canvas ref="canvas" class="plot" />
    <div class="hz" :style="{ top: `${WHITE_Y}px` }">
      2300 Hz <span class="swatch white" />
    </div>
    <div class="hz" :style="{ top: `${BLACK_Y}px` }">
      1500 Hz <span class="swatch black" />
    </div>
    <div class="ms" style="left: 0">
      0 ms
    </div>
    <div class="ms" style="right: 0">
      88 ms
    </div>
  </div>
</template>

<style scoped>
.frequency-row {
  position: absolute;
  left: 220px;
  top: 104px;
  width: 960px;
  height: 488px;
}

.plot {
  width: 960px;
  height: 488px;
}

.hz {
  position: absolute;
  right: calc(100% + 20px);
  transform: translateY(-50%);
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 20px;
  color: var(--muted);
  white-space: nowrap;
}

.swatch {
  width: 16px;
  height: 16px;
  border: 1px solid rgba(253, 253, 253, 0.4);
}

.swatch.white {
  background: #fff;
}

.swatch.black {
  background: #000;
}

.ms {
  position: absolute;
  top: calc(100% + 8px);
  font-size: 20px;
  color: var(--muted);
}
</style>
