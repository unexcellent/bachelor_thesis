<script setup lang="ts">
import { computed } from 'vue'

/**
 * The hardware traits of `beacon` with the carriers implementing them:
 * 0. the traits alone, 1. hidden while the Camera trait code is shown,
 * 2. MOVE-IIIa and Tab5 hardware, 3. the camera list type that turns the
 * requirements into code.
 *
 * Arrows use the UML/SysML realization notation (dashed line, hollow
 * triangle at the trait). Hardware names follow the thesis.
 */
const props = withDefaults(defineProps<{ step?: number }>(), { step: 0 })

interface Item { name: string, part: string, y: number, trait: number }

const TRAIT = { x: 490, w: 300, h: 72 }
const ITEM = { w: 250, h: 60 }
const LEFT_X = 110
const RIGHT_X = 1280 - 110 - ITEM.w

const traits = [
  { name: 'Camera', y: 231 },
  { name: 'AudioChannel', y: 351 },
  { name: 'CommandLink', y: 471 },
]

const moveiiia: Item[] = [
  { name: 'RGB camera', part: 'SC850SL', y: 196, trait: 0 },
  { name: 'Thermal camera', part: 'MI1602', y: 266, trait: 0 },
  { name: 'Audio output', part: 'PCM5102A', y: 351, trait: 1 },
  { name: 'Payload link', part: 'RS422', y: 471, trait: 2 },
]

const tab5: Item[] = [
  { name: 'RGB camera', part: 'SC2356', y: 231, trait: 0 },
  { name: 'Speaker', part: 'ES8388', y: 351, trait: 1 },
  { name: 'Payload link', part: 'USB serial', y: 471, trait: 2 },
]

const showMap = computed(() => props.step !== 1)

/** Dashed realization line ending in a hollow triangle at the trait edge. */
function realization(item: Item, fromLeft: boolean) {
  const x0 = fromLeft ? LEFT_X + ITEM.w : RIGHT_X
  const x1 = fromLeft ? TRAIT.x : TRAIT.x + TRAIT.w
  const y1 = traits[item.trait].y
  const angle = Math.atan2(y1 - item.y, x1 - x0)
  const len = 20
  const half = 11
  const bx = x1 - Math.cos(angle) * len
  const by = y1 - Math.sin(angle) * len
  const px = -Math.sin(angle) * half
  const py = Math.cos(angle) * half
  return {
    line: `M${x0},${item.y}L${bx},${by}`,
    head: `M${x1},${y1}L${bx + px},${by + py}L${bx - px},${by - py}Z`,
  }
}

const TYPE = 'cameras: Vec<Option<Box<dyn Camera>>>'
const TYPE_WIDTH = 668
const charX = (i: number) => 640 - TYPE_WIDTH / 2 + i * (TYPE_WIDTH / TYPE.length)
/** Character ranges [from, to) of the type each note explains. */
const notes = [
  { text: 'any number', from: 9, to: 12 },
  { text: 'may fail', from: 13, to: 19 },
  { text: 'any model', from: 24, to: 34 },
].map(n => ({ ...n, x0: charX(n.from) + 3, x1: charX(n.to) - 3 }))
</script>

<template>
  <svg class="map" viewBox="0 0 1280 720" :class="{ hidden: !showMap }">
    <g class="side" :class="{ out: step < 2, left: true }">
      <text class="heading" :x="LEFT_X + ITEM.w / 2" y="140" text-anchor="middle">MOVE-IIIa</text>
      <g v-for="m in moveiiia" :key="m.name">
        <path class="realize" :d="realization(m, true).line" />
        <path class="head" :d="realization(m, true).head" />
        <rect :x="LEFT_X" :y="m.y - ITEM.h / 2" :width="ITEM.w" :height="ITEM.h" rx="6" />
        <text :x="LEFT_X + 18" :y="m.y" dominant-baseline="middle">{{ m.name }} <tspan class="part">{{ m.part }}</tspan></text>
      </g>
    </g>

    <g class="side" :class="{ out: step < 2, right: true }">
      <text class="heading" :x="RIGHT_X + ITEM.w / 2" y="140" text-anchor="middle">Tab5</text>
      <g v-for="t in tab5" :key="t.name">
        <path class="realize" :d="realization(t, false).line" />
        <path class="head" :d="realization(t, false).head" />
        <rect :x="RIGHT_X" :y="t.y - ITEM.h / 2" :width="ITEM.w" :height="ITEM.h" rx="6" />
        <text :x="RIGHT_X + 18" :y="t.y" dominant-baseline="middle">{{ t.name }} <tspan class="part">{{ t.part }}</tspan></text>
      </g>
    </g>

    <g class="traits">
      <text class="heading" x="640" y="140" text-anchor="middle">beacon</text>
      <g v-for="t in traits" :key="t.name">
        <rect :x="TRAIT.x" :y="t.y - TRAIT.h / 2" :width="TRAIT.w" :height="TRAIT.h" rx="6" />
        <text :x="TRAIT.x + TRAIT.w / 2" :y="t.y" text-anchor="middle" dominant-baseline="middle">
          <tspan class="keyword">trait </tspan>{{ t.name }}
        </text>
      </g>
    </g>

    <g class="type" :class="{ out: step < 3 }">
      <text x="640" y="600" text-anchor="middle" :textLength="TYPE_WIDTH" lengthAdjust="spacingAndGlyphs">{{ TYPE }}</text>
      <g v-for="n in notes" :key="n.text">
        <path class="bracket" :d="`M${n.x0},614V622H${n.x1}V614`" />
        <text class="note" :x="(n.x0 + n.x1) / 2" y="650" text-anchor="middle">{{ n.text }}</text>
      </g>
    </g>
  </svg>
</template>

<style scoped>
.map {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  transition: opacity 0.4s ease;
}

.map.hidden {
  opacity: 0;
}

.side,
.type {
  transition: opacity 0.6s ease-out, transform 0.9s cubic-bezier(0.22, 1, 0.36, 1);
}

.side.out {
  opacity: 0;
}

.side.left.out {
  transform: translateX(-120px);
}

.side.right.out {
  transform: translateX(120px);
}

.type.out {
  opacity: 0;
}

rect {
  fill: var(--bg);
  stroke: #fdfdfd;
  stroke-width: 2;
}

text {
  fill: var(--fg);
  font-size: 22px;
}

.part {
  fill: var(--muted);
  font-size: 18px;
}

.heading {
  fill: var(--muted);
  font-size: 20px;
  text-transform: uppercase;
  letter-spacing: 0.08em;
}

.traits text {
  font-family: Menlo, ui-monospace, monospace;
  font-size: 24px;
}

.traits .heading {
  font-family: inherit;
  font-size: 20px;
}

.keyword {
  fill: var(--muted);
}

.realize {
  fill: none;
  stroke: #fdfdfd;
  stroke-width: 2;
  stroke-dasharray: 8 7;
}

.head {
  fill: var(--bg);
  stroke: #fdfdfd;
  stroke-width: 2;
  stroke-linejoin: round;
}

.type text {
  font-family: Menlo, ui-monospace, monospace;
  font-size: 30px;
}

.bracket {
  fill: none;
  stroke: rgba(253, 253, 253, 0.5);
  stroke-width: 1.5;
}

.type .note {
  font-family: inherit;
  fill: var(--muted);
  font-size: 20px;
}
</style>
