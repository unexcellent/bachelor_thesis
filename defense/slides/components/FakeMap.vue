<script setup lang="ts">
import { computed } from 'vue'

/**
 * The `beacon` traits implemented by the mock devices of its unit tests,
 * drawn like the carrier trait map. From click 1 on the map moves up to make
 * room for the test code in the slide markdown.
 */
const props = withDefaults(defineProps<{ step?: number }>(), { step: 0 })

const TRAIT = { w: 300, h: 64 }
const FAKE = { w: 250, h: 56 }
const GAP = 140
const LEFT_X = (1280 - (FAKE.w + GAP + TRAIT.w)) / 2
const TRAIT_X = LEFT_X + FAKE.w + GAP
const HEADING_Y = 130

const rows = [
  { fake: 'FakeCamera', trait: 'Camera', y: 190 },
  { fake: 'FakeAudio', trait: 'AudioChannel', y: 290 },
  { fake: 'FakeLink', trait: 'CommandLink', y: 390 },
]

/** With no code below, the map is moved down to sit at the slide centre. */
const CENTER_SHIFT = 360 - (HEADING_Y + rows.at(-1)!.y + TRAIT.h / 2) / 2
const shift = computed(() => (props.step >= 1 ? 0 : CENTER_SHIFT))

const x0 = LEFT_X + FAKE.w
const x1 = TRAIT_X
</script>

<template>
  <svg class="map" viewBox="0 0 1280 720">
    <g class="group" :style="{ transform: `translateY(${shift}px)` }">
      <text class="heading" :x="LEFT_X + FAKE.w / 2" :y="HEADING_Y" text-anchor="middle">unit tests</text>
      <text class="heading" :x="TRAIT_X + TRAIT.w / 2" :y="HEADING_Y" text-anchor="middle">beacon</text>

      <g v-for="r in rows" :key="r.fake">
        <path class="realize" :d="`M${x0},${r.y}H${x1 - 20}`" />
        <path class="head" :d="`M${x1},${r.y}L${x1 - 20},${r.y - 11}L${x1 - 20},${r.y + 11}Z`" />
        <rect :x="LEFT_X" :y="r.y - FAKE.h / 2" :width="FAKE.w" :height="FAKE.h" rx="6" />
        <text class="mono" :x="LEFT_X + FAKE.w / 2" :y="r.y" text-anchor="middle" dominant-baseline="middle">{{ r.fake }}</text>
        <rect :x="TRAIT_X" :y="r.y - TRAIT.h / 2" :width="TRAIT.w" :height="TRAIT.h" rx="6" />
        <text class="mono" :x="TRAIT_X + TRAIT.w / 2" :y="r.y" text-anchor="middle" dominant-baseline="middle">
          <tspan class="keyword">trait </tspan>{{ r.trait }}
        </text>
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
}

.group {
  transition: transform 0.6s cubic-bezier(0.22, 1, 0.36, 1);
}

rect {
  fill: var(--bg);
  stroke: #fdfdfd;
  stroke-width: 2;
}

text {
  fill: var(--fg);
}

.mono {
  font-family: Menlo, ui-monospace, monospace;
  font-size: 23px;
}

.keyword {
  fill: var(--muted);
}

.heading {
  fill: var(--muted);
  font-size: 20px;
  text-transform: uppercase;
  letter-spacing: 0.08em;
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
</style>
