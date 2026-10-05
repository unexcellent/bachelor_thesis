<script setup lang="ts">
import { computed, onMounted, shallowRef, watch } from 'vue'
import { renderTone, useSlideAudio } from '../lib/audio'
import { levelToHz, loadImage, luma, PIXEL_MS, samplePixels, SYNC_HZ, WIDTH } from '../lib/robot36'

/**
 * One part of a Robot 36 transmission as frequency over time: the VOX tones,
 * the VIS code or one scan line of the image. A click plays it in real time.
 *
 * Tones follow the Dayton paper; the VOX sequence is the one most SSTV
 * programs send.
 */
const props = withDefaults(defineProps<{
  part: 'vox' | 'vis' | 'line'
  /** Only needed for the scan line, which is taken from this image. */
  src?: string
  step?: number
  /** Image row (even, so it carries V) shown as the scan line. */
  row?: number
}>(), {
  step: 0,
  row: 40,
})

interface Segment { ms: number, hz: number | ArrayLike<number> }
interface Label { from: number, to: number, text: string }
interface Digit { at: number, hz: number, text: string }
interface Section { name: string, segments: Segment[], labels: Label[], digits: Digit[], ticks: number[] }

const W = 1040
const H = 370
const X0 = 110
const X1 = 1030
const PLOT_TOP = 80
const PLOT_BOTTOM = 330
const MIN_HZ = 1000
const MAX_HZ = 2400
const LINE_MS = 150

const ROBOT36_VIS = 8
const BIT_MS = 30
const ONE_HZ = 1100
const ZERO_HZ = 1300

const rowY = shallowRef<Float32Array>()
const rowV = shallowRef<Float32Array>()
let sectionAudio: AudioBuffer | undefined
const audio = useSlideAudio()

const PARTS = ['vox', 'vis', 'line'] as const
const partIndex = PARTS.indexOf(props.part)

function vis(): Section {
  const bits = Array.from({ length: 7 }, (_, i) => (ROBOT36_VIS >> i) & 1)
  const parity = bits.reduce((a, b) => a + b, 0) % 2
  const segments: Segment[] = [
    { ms: 300, hz: 1900 },
    { ms: 10, hz: SYNC_HZ },
    { ms: 300, hz: 1900 },
    { ms: BIT_MS, hz: SYNC_HZ },
    ...[...bits, parity].map(b => ({ ms: BIT_MS, hz: b ? ONE_HZ : ZERO_HZ })),
    { ms: BIT_MS, hz: SYNC_HZ },
  ]
  const firstBit = 640
  return {
    name: 'VIS',
    segments,
    labels: [
      { from: 0, to: 300, text: 'leader' },
      { from: 310, to: 610, text: 'leader' },
      { from: firstBit, to: firstBit + 8 * BIT_MS, text: 'mode' },
    ],
    digits: [...bits, parity].map((b, i) => ({
      at: firstBit + (i + 0.5) * BIT_MS,
      hz: b ? ONE_HZ : ZERO_HZ,
      text: String(b),
    })),
    ticks: [ONE_HZ, SYNC_HZ, ZERO_HZ, 1900],
  }
}

const sections = computed<Section[]>(() => [
  {
    name: 'VOX',
    segments: [1900, 1500, 1900, 1500, 2300, 1500, 2300, 1500].map(hz => ({ ms: 100, hz })),
    labels: [],
    digits: [],
    ticks: [1500, 1900, 2300],
  },
  vis(),
  {
    name: 'scan line',
    segments: rowY.value && rowV.value
      ? [
          { ms: 9, hz: SYNC_HZ },
          { ms: 3, hz: 1500 },
          { ms: WIDTH * PIXEL_MS, hz: rowY.value },
          { ms: 4.5, hz: 1500 },
          { ms: 1.5, hz: 1900 },
          { ms: (WIDTH * PIXEL_MS) / 2, hz: rowV.value },
        ]
      : [],
    labels: [
      { from: 0, to: 9, text: 'sync' },
      { from: 12, to: 100, text: 'Y' },
      { from: 106, to: LINE_MS, text: 'V' },
    ],
    digits: [],
    ticks: [SYNC_HZ, 1500, 1900, 2300],
  },
])

const section = computed(() => sections.value[partIndex])
const totalMs = computed(() => section.value.segments.reduce((t, s) => t + s.ms, 0) || LINE_MS)

function x(ms: number) {
  return X0 + (ms / totalMs.value) * (X1 - X0)
}

function y(hz: number) {
  return PLOT_BOTTOM - ((hz - MIN_HZ) / (MAX_HZ - MIN_HZ)) * (PLOT_BOTTOM - PLOT_TOP)
}

const path = computed(() => {
  let d = ''
  let t = 0
  for (const seg of section.value.segments) {
    const values = typeof seg.hz === 'number' ? [seg.hz] : seg.hz
    const dt = seg.ms / values.length
    for (let i = 0; i < values.length; i++) {
      const yy = y(values[i]).toFixed(1)
      d += `${d ? 'L' : 'M'}${x(t).toFixed(1)},${yy}L${x(t + dt).toFixed(1)},${yy}`
      t += dt
    }
  }
  return d
})

function hzAt(s: Section, ms: number) {
  let t = 0
  for (const seg of s.segments) {
    if (ms < t + seg.ms || seg === s.segments.at(-1)) {
      if (typeof seg.hz === 'number')
        return seg.hz
      return seg.hz[Math.min(seg.hz.length - 1, Math.floor(((ms - t) / seg.ms) * seg.hz.length))]
    }
    t += seg.ms
  }
  return SYNC_HZ
}

function playSection() {
  const s = section.value
  if (props.step !== 1 || !s.segments.length) {
    audio.stop()
    return
  }
  audio.play(() => sectionAudio ??= renderTone(totalMs.value, ms => hzAt(s, ms)))
}

onMounted(async () => {
  if (props.part !== 'line' || !props.src)
    return
  const { data } = samplePixels(await loadImage(props.src))
  const lum = new Float32Array(WIDTH)
  const cr = new Float32Array(WIDTH / 2)
  for (let col = 0; col < WIDTH; col++) {
    const i = (props.row * WIDTH + col) * 4
    lum[col] = levelToHz(luma(data[i], data[i + 1], data[i + 2]))
  }
  for (let col = 0; col < WIDTH / 2; col++) {
    let sum = 0
    for (const c of [col * 2, col * 2 + 1]) {
      const i = (props.row * WIDTH + c) * 4
      sum += 128 + 0.5 * data[i] - 0.418688 * data[i + 1] - 0.081312 * data[i + 2]
    }
    cr[col] = levelToHz(sum / 2)
  }
  rowY.value = lum
  rowV.value = cr
})

watch(() => props.step, playSection)
</script>

<template>
  <div class="timeline">
    <div class="crumbs">
      <template v-for="(s, i) in sections" :key="s.name">
        <span v-if="i" class="arrow">→</span>
        <span :class="{ active: i === partIndex }">{{ i === 2 ? `240 × ${s.name}` : s.name }}</span>
      </template>
    </div>

    <svg class="plot" :viewBox="`0 0 ${W} ${H}`">
      <g class="ticks">
        <template v-for="hz in section.ticks" :key="hz">
          <line :x1="X0" :x2="X1" :y1="y(hz)" :y2="y(hz)" />
          <text :x="X0 - 14" :y="y(hz)" text-anchor="end" dominant-baseline="middle">{{ hz }} Hz</text>
        </template>
      </g>
      <g class="labels">
        <template v-for="l in section.labels" :key="l.text + l.from">
          <path :d="`M${x(l.from) + 2},64V58H${x(l.to) - 2}V64`" />
          <text :x="(x(l.from) + x(l.to)) / 2" y="46" text-anchor="middle">{{ l.text }}</text>
        </template>
      </g>
      <g class="digits">
        <text v-for="d in section.digits" :key="d.at" :x="x(d.at)" :y="y(d.hz) - 14" text-anchor="middle">{{ d.text }}</text>
      </g>
      <path class="signal" :d="path" />
      <g class="time">
        <text :x="X0" :y="H - 8">0 ms</text>
        <text :x="X1" :y="H - 8" text-anchor="end">{{ Math.round(totalMs) }} ms</text>
      </g>
    </svg>
  </div>
</template>

<style scoped>
.timeline {
  position: absolute;
  inset: 0;
}

.crumbs {
  position: absolute;
  top: 72px;
  left: 0;
  right: 0;
  display: flex;
  justify-content: center;
  gap: 20px;
  font-size: 28px;
  color: var(--muted);
}

.crumbs .active {
  color: var(--fg);
  font-weight: 400;
}

.plot {
  position: absolute;
  left: 120px;
  top: 170px;
  width: 1040px;
  height: 370px;
}

.ticks line {
  stroke: rgba(253, 253, 253, 0.12);
  stroke-width: 1;
}

.plot text {
  font-size: 18px;
  fill: var(--muted);
}

.labels path {
  fill: none;
  stroke: rgba(253, 253, 253, 0.5);
  stroke-width: 1;
}

.labels text {
  fill: var(--fg);
  font-size: 20px;
}

.digits text {
  fill: var(--fg);
  font-size: 20px;
}

.signal {
  fill: none;
  stroke: #fdfdfd;
  stroke-width: 1.5;
  stroke-linejoin: round;
}
</style>
