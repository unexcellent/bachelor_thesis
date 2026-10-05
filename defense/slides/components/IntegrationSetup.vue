<script setup lang="ts">
/**
 * The integration test setup from the thesis photo as line drawings, wired
 * directly instead of through a breadboard (thesis table "Pin wiring for the
 * test setup"):
 * - Raspberry Pi 4B GPIO header → ESP32-P4 on the payload: 5V (pin 2),
 *   GND (pin 6), GPIO18 (pin 12), GPIO19 (pin 35), GPIO20 (pin 38).
 * - DSD TECH SH-U11 terminals TX+, TX−, RX+, RX− → THVD1424 on the payload.
 *
 * All drawings share one scale. Wires enter the payload from below: the
 * adapter's on the left half, the Pi's on the right half, nested so none cross.
 *
 * Clicks 1 to 4 replay the RGB-only transmission test: the SSTV command goes
 * out over RS422, the payload answers BUSY, the audio streams back over I2S
 * (the GPIO18 to 20 wires) and the payload reports AVAILABLE.
 */
import { computed } from 'vue'

const props = withDefaults(defineProps<{ step?: number }>(), { step: 0 })

const MM = 3.4

/** Raspberry Pi SVG: viewBox origin (-1, -1), landscape board drawn rotated by translate(59,0) rotate(90). */
const PI = { left: 350, top: 101, w: 61 * MM, h: 91 * MM }
/** SH-U11 SVG: viewBox origin (-1, -1); its plug sits 9 mm deep in the Pi's left USB port. */
const SH = { left: PI.left - 2 * MM, top: PI.top + 78.2 * MM, w: 30 * MM, h: 74 * MM }
const PAYLOAD = { left: 750, top: 320, w: 119.5, h: 228 }
/** Flat part of the payload's bottom outline, measured from the image: x range and y within the drawing. */
const PAYLOAD_BASE = { x0: 10, x1: 95, y: 225 }

const R = 12
const WIRE_GAP = 10

/** Header pin centre on the slide, from its physical pin number. */
function piPin(n: number) {
  const x = 7.1 + Math.floor((n - 1) / 2) * 2.54
  const y = n % 2 === 0 ? 2.23 : 4.77
  return { x: PI.left + (59 - y + 1) * MM, y: PI.top + (x + 1) * MM }
}

/** Terminal screw centre on the slide (terminals 1 to 4: TX+, TX−, RX+, RX−). */
function shTerminal(i: number) {
  return { x: SH.left + (5 + i * 4.5 + 1) * MM, y: SH.top + (65.2 + 1) * MM }
}

const bottom = PAYLOAD.top + PAYLOAD_BASE.y
const half = PAYLOAD.left + (PAYLOAD_BASE.x0 + PAYLOAD_BASE.x1) / 2

/** Pi wires run right above the payload, down its right side and wrap under it; the topmost pin takes the outermost lane. */
const piWires = [2, 6, 12, 35, 38].map((n, i, all) => {
  const p = piPin(n)
  const lane = PAYLOAD.left + PAYLOAD.w + 20 + (all.length - 1 - i) * WIRE_GAP
  const under = bottom + 20 + (all.length - 1 - i) * WIRE_GAP
  const entry = half + 4 + i * 8.5
  return {
    start: p,
    d: `M${p.x},${p.y}H${lane - R}Q${lane},${p.y} ${lane},${p.y + R}V${under - R}Q${lane},${under} ${lane - R},${under}H${entry + R}Q${entry},${under} ${entry},${under - R}V${bottom}`,
  }
})

/** Adapter wires leave the terminal block downwards; the leftmost terminal takes the lowest lane and the rightmost entry. */
const shWires = [0, 1, 2, 3].map((i, _, all) => {
  const p = shTerminal(i)
  const below = SH.top + 70.5 * MM + 14 + (all.length - 1 - i) * WIRE_GAP
  const entry = half - 4 - i * 9
  return {
    start: p,
    d: `M${p.x},${p.y}V${below - R}Q${p.x},${below} ${p.x + R},${below}H${entry - R}Q${entry},${below} ${entry},${below - R}V${bottom}`,
  }
})

interface Stage { caption: string, wires: { d: string }[], towardsPayload: boolean, stream: boolean }

/** Adapter terminal 0 is TX+ (command out), terminal 2 RX+ (replies in). */
const stages: (Stage | undefined)[] = [
  undefined,
  { caption: 'SSTV command over RS422', wires: [shWires[0]], towardsPayload: true, stream: false },
  { caption: 'BUSY', wires: [shWires[2]], towardsPayload: false, stream: false },
  { caption: 'Audio over I2S, decoded on the Pi', wires: piWires.slice(2), towardsPayload: false, stream: true },
  { caption: 'AVAILABLE', wires: [shWires[2]], towardsPayload: false, stream: false },
]
const stage = computed(() => stages[Math.min(props.step, stages.length - 1)])
const DOTS_PER_STREAM = 4
const STREAM_S = 3

const asset = (path: string) => import.meta.env.BASE_URL + path
const box = (b: { left: number, top: number, w: number, h: number }) => ({ left: `${b.left}px`, top: `${b.top}px`, width: `${b.w}px`, height: `${b.h}px` })
</script>

<template>
  <div class="setup">
    <!-- The Pi comes after the adapter so its filled port housing covers the inserted part of the plug. -->
    <img :src="asset('img/sh_u11_top.svg')" :style="box(SH)">
    <img :src="asset('img/rpi4_top.svg')" :style="box(PI)">
    <img :src="asset('img/sstv_system_top.png')" :style="box(PAYLOAD)">

    <svg class="wires" viewBox="0 0 1280 720">
      <path v-for="w in [...piWires, ...shWires]" :key="w.d" :d="w.d" :class="{ active: stage?.wires.includes(w) }" />
      <circle v-for="w in [...piWires, ...shWires]" :key="`c${w.d}`" :cx="w.start.x" :cy="w.start.y" r="3" />
    </svg>

    <template v-if="stage">
      <template v-for="(w, wi) in stage.wires" :key="`${step}-${wi}`">
        <div
          v-for="k in (stage.stream ? DOTS_PER_STREAM : 1)"
          :key="k"
          class="dot"
          :class="{ stream: stage.stream }"
          :style="{
            offsetPath: `path('${w.d}')`,
            animationDirection: stage.towardsPayload ? 'normal' : 'reverse',
            animationDelay: stage.stream ? `${-((k - 1) / DOTS_PER_STREAM) * STREAM_S}s` : '0s',
            animationDuration: stage.stream ? `${STREAM_S}s` : '1.8s',
          }"
        />
      </template>
    </template>

    <Transition name="fade" mode="out-in">
      <div v-if="stage" :key="step" class="caption">
        {{ stage.caption }}
      </div>
    </Transition>
  </div>
</template>

<style scoped>
.setup {
  position: absolute;
  inset: 0;
}

img {
  position: absolute;
}

.wires {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  pointer-events: none;
}

.wires path {
  fill: none;
  stroke: #5f686e;
  stroke-width: 2;
  stroke-linejoin: round;
}

.wires path.active {
  stroke: #fdfdfd;
  transition: stroke 0.3s ease;
}

.wires circle {
  fill: #5f686e;
}

.dot {
  position: absolute;
  left: 0;
  top: 0;
  width: 12px;
  height: 12px;
  border-radius: 50%;
  background: #fdfdfd;
  box-shadow: 0 0 10px rgba(255, 255, 255, 0.9);
  offset-rotate: 0deg;
  animation-name: travel;
  animation-timing-function: ease-in-out;
  animation-fill-mode: both;
}

.dot.stream {
  width: 8px;
  height: 8px;
  animation-timing-function: linear;
  animation-iteration-count: infinite;
}

@keyframes travel {
  from { offset-distance: 0%; }
  to { offset-distance: 100%; }
}

.caption {
  position: absolute;
  left: 0;
  right: 0;
  top: 40px;
  text-align: center;
  font-size: 28px;
}
</style>
