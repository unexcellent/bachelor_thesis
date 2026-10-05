<script setup lang="ts">
/**
 * The thesis IBD of the `sstv` encoding path, redrawn in the deck's style.
 * Each click highlights the part that matches the highlighted code line:
 * 1 pixel input, 2 Encoder with its inputs and tone output, 3 Synthesizer
 * with its sample output, 4 sample output.
 */
const props = withDefaults(defineProps<{ step?: number }>(), { step: 0 })

type Group = 'mode' | 'pixels' | 'encoder' | 'tone' | 'synth' | 'samples'

const FOCUS: Group[][] = [[], ['pixels'], ['encoder', 'mode', 'pixels', 'tone'], ['synth', 'samples'], ['samples']]

/** Outer ends of the flows entering and leaving the crate. */
const EDGE = { x0: 60, x1: 1220 }
const PORT = 18
const ENCODER = { x: 300, y: 80, w: 260, h: 170 }
const SYNTH = { x: 760, y: 80, w: 260, h: 170 }
const MODE_Y = 120
const PIXELS_Y = 210
const TONE_Y = 165

function dim(group: Group) {
  const focus = FOCUS[Math.min(props.step, FOCUS.length - 1)]
  return focus.length > 0 && !focus.includes(group)
}

function port(x: number, y: number) {
  return { x: x - PORT / 2, y: y - PORT / 2 }
}

/** SysML item flow: a solid connector with a filled triangle at its middle. */
function flowHead(x0: number, x1: number, y: number) {
  const m = (x0 + x1) / 2
  return `M${m - 9},${y - 9}L${m + 9},${y}L${m - 9},${y + 9}Z`
}

const flows = [
  { group: 'mode' as Group, x0: EDGE.x0, x1: ENCODER.x, y: MODE_Y, label: ['Mode'] },
  { group: 'pixels' as Group, x0: EDGE.x0, x1: ENCODER.x, y: PIXELS_Y, label: ['Iterator of RgbPixel'] },
  { group: 'tone' as Group, x0: ENCODER.x + ENCODER.w, x1: SYNTH.x, y: TONE_Y, label: ['Iterator of Tone'] },
  { group: 'samples' as Group, x0: SYNTH.x + SYNTH.w, x1: EDGE.x1, y: TONE_Y, label: ['Iterator of 16 bit', 'signed integer'] },
]

const blocks = [
  { group: 'encoder' as Group, name: ': Encoder', ...ENCODER },
  { group: 'synth' as Group, name: ': Synthesizer', ...SYNTH },
]
</script>

<template>
  <svg class="ibd" viewBox="0 0 1280 320">
    <g v-for="b in blocks" :key="b.name" class="part" :class="{ dim: dim(b.group) }">
      <rect :x="b.x" :y="b.y" :width="b.w" :height="b.h" />
      <text class="stereotype" :x="b.x + b.w / 2" :y="b.y + 40" text-anchor="middle">«block»</text>
      <text class="name" :x="b.x + b.w / 2" :y="b.y + 76" text-anchor="middle">{{ b.name }}</text>
    </g>

    <g v-for="f in flows" :key="f.group" class="part" :class="{ dim: dim(f.group) }">
      <line :x1="f.x0" :x2="f.x1" :y1="f.y" :y2="f.y" />
      <path class="head" :d="flowHead(f.x0, f.x1, f.y)" />
      <rect class="port" v-bind="port(f.x0, f.y)" :width="PORT" :height="PORT" />
      <rect class="port" v-bind="port(f.x1, f.y)" :width="PORT" :height="PORT" />
      <text class="label" :x="(f.x0 + f.x1) / 2" :y="f.y + 34" text-anchor="middle">
        <tspan v-for="(l, i) in f.label" :key="l" :x="(f.x0 + f.x1) / 2" :dy="i ? 24 : 0">{{ l }}</tspan>
      </text>
    </g>
  </svg>
</template>

<style scoped>
.ibd {
  position: absolute;
  left: 0;
  top: 40px;
  width: 1280px;
  height: 320px;
}

/*
 * Dimming swaps to solid colours (each a 30 % blend with the background)
 * instead of lowering opacity, so the opaque ports keep covering the block
 * edges they sit on.
 */
.part {
  --ink: #fdfdfd;
  --ink-muted: #8a949b;
}

.part.dim {
  --ink: #54585b;
  --ink-muted: #32393e;
}

.part * {
  transition: fill 0.4s ease, stroke 0.4s ease;
}

.part rect,
.part line {
  fill: none;
  stroke: var(--ink);
  stroke-width: 2;
}

.part rect.port {
  fill: var(--bg);
}

.head {
  fill: var(--ink);
}

.stereotype {
  fill: var(--ink-muted);
  font-size: 18px;
}

.name {
  fill: var(--ink);
  font-size: 26px;
  font-weight: 500;
}

.label {
  fill: var(--ink);
  font-size: 19px;
}
</style>
