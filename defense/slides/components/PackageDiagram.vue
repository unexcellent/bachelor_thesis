<script setup lang="ts">
/**
 * The crate structure from the thesis package diagram, redrawn in the deck's
 * style. Dependencies use the SysML notation for «import»: a dashed line with
 * an open arrowhead pointing at the imported package. Each click from 1 on
 * highlights one package, in the order the talk explains them.
 */

const props = withDefaults(defineProps<{ step?: number }>(), { step: 0 })

interface Package { name: string, x: number, y: number, w: number }

const BODY_H = 110
const TAB_W = 90
const TAB_H = 30
const JUNCTION_X = 820

const packages: Package[] = [
  { name: 'sstv', x: 80, y: 325, w: 240 },
  { name: 'beacon', x: 460, y: 325, w: 240 },
  { name: 'beacon-on-moveiiia', x: 880, y: 190, w: 320 },
  { name: 'beacon-on-tab5', x: 880, y: 460, w: 320 },
]

const [sstv, beacon, moveiiia, tab5] = packages
const mid = (p: Package) => p.y + BODY_H / 2
const focused = (i: number) => props.step === 0 || props.step - 1 === i

function arrowhead(x: number, y: number) {
  return `M${x + 16},${y - 10}L${x},${y}L${x + 16},${y + 10}`
}
</script>

<template>
  <svg class="pkg" viewBox="0 0 1280 720">
    <g v-for="(p, i) in packages" :key="p.name" class="package" :class="{ dim: !focused(i) }">
      <rect :x="p.x" :y="p.y - TAB_H" :width="TAB_W" :height="TAB_H" />
      <rect :x="p.x" :y="p.y" :width="p.w" :height="BODY_H" />
      <text :x="p.x + p.w / 2" :y="mid(p)" text-anchor="middle" dominant-baseline="middle">{{ p.name }}</text>
    </g>

    <g class="dependency" :class="{ dim: step > 0 }">
      <path :d="`M${beacon.x},${mid(beacon)}H${sstv.x + sstv.w}`" />
      <path :d="`M${moveiiia.x},${mid(moveiiia)}H${JUNCTION_X}V${mid(beacon)}H${beacon.x + beacon.w}`" />
      <path :d="`M${tab5.x},${mid(tab5)}H${JUNCTION_X}V${mid(beacon)}`" />
    </g>
    <g class="head" :class="{ dim: step > 0 }">
      <path :d="arrowhead(sstv.x + sstv.w, mid(sstv))" />
      <path :d="arrowhead(beacon.x + beacon.w, mid(beacon))" />
    </g>

    <g class="keyword" :class="{ dim: step > 0 }">
      <text :x="(sstv.x + sstv.w + beacon.x) / 2" :y="mid(beacon) - 18" text-anchor="middle">«import»</text>
      <text :x="JUNCTION_X - 14" :y="(mid(moveiiia) + mid(beacon)) / 2" text-anchor="end" dominant-baseline="middle">«import»</text>
      <text :x="JUNCTION_X - 14" :y="(mid(tab5) + mid(beacon)) / 2" text-anchor="end" dominant-baseline="middle">«import»</text>
    </g>
  </svg>
</template>

<style scoped>
.pkg {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
}

.package,
.dependency,
.head,
.keyword {
  transition: opacity 0.4s ease;
}

.dim {
  opacity: 0.3;
}

.package rect {
  fill: none;
  stroke: #fdfdfd;
  stroke-width: 2;
}

.package text {
  fill: var(--fg);
  font-size: 28px;
  font-weight: 300;
}

.dependency path {
  fill: none;
  stroke: #fdfdfd;
  stroke-width: 2;
  stroke-dasharray: 10 8;
}

.head path {
  fill: none;
  stroke: #fdfdfd;
  stroke-width: 2;
  stroke-linejoin: round;
}

.keyword text {
  fill: var(--muted);
  font-size: 22px;
}
</style>
