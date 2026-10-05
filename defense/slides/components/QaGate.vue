<script setup lang="ts">
/**
 * The pre-commit gate as a SysML activity diagram: every commit runs through
 * rustfmt and clippy, and a failure after either check ends the activity.
 * Control flows use the dashed SysML notation.
 */

const MAIN_Y = 300
const FAIL_Y = 430
const ACTION = { w: 150, h: 70 }
const DIAMOND = 22
const ARROW = 40
/** Flows leaving a decision carry a guard, so they need room for its label. */
const GUARDED_ARROW = 100
const NODE_R = 14

const INITIAL_X = 70
const commitX = INITIAL_X + NODE_R + ARROW
const rustfmtX = commitX + ACTION.w + ARROW
const decision1X = rustfmtX + ACTION.w + ARROW + DIAMOND
const clippyX = decision1X + DIAMOND + GUARDED_ARROW
const decision2X = clippyX + ACTION.w + ARROW + DIAMOND
const historyX = decision2X + DIAMOND + GUARDED_ARROW
const finalX = historyX + ACTION.w + ARROW + NODE_R

/** Shift that centres the whole diagram horizontally on the slide. */
const OFFSET = 640 - (INITIAL_X - NODE_R + finalX + NODE_R) / 2

const actions = [
  { label: 'git commit', x: commitX, mono: false },
  { label: 'rustfmt', x: rustfmtX, mono: true },
  { label: 'clippy', x: clippyX, mono: true },
  { label: 'git history', x: historyX, mono: false },
]

/** Control flows as [path, arrow tip x, tip y, direction]. */
const flows: [string, number, number, 'right' | 'down'][] = [
  [`M${INITIAL_X + NODE_R},${MAIN_Y}H${commitX}`, commitX, MAIN_Y, 'right'],
  [`M${commitX + ACTION.w},${MAIN_Y}H${rustfmtX}`, rustfmtX, MAIN_Y, 'right'],
  [`M${rustfmtX + ACTION.w},${MAIN_Y}H${decision1X - DIAMOND}`, decision1X - DIAMOND, MAIN_Y, 'right'],
  [`M${decision1X + DIAMOND},${MAIN_Y}H${clippyX}`, clippyX, MAIN_Y, 'right'],
  [`M${clippyX + ACTION.w},${MAIN_Y}H${decision2X - DIAMOND}`, decision2X - DIAMOND, MAIN_Y, 'right'],
  [`M${decision2X + DIAMOND},${MAIN_Y}H${historyX}`, historyX, MAIN_Y, 'right'],
  [`M${historyX + ACTION.w},${MAIN_Y}H${finalX - NODE_R}`, finalX - NODE_R, MAIN_Y, 'right'],
  [`M${decision1X},${MAIN_Y + DIAMOND}V${FAIL_Y - NODE_R}`, decision1X, FAIL_Y - NODE_R, 'down'],
  [`M${decision2X},${MAIN_Y + DIAMOND}V${FAIL_Y - NODE_R}`, decision2X, FAIL_Y - NODE_R, 'down'],
]

const finals = [[finalX, MAIN_Y], [decision1X, FAIL_Y], [decision2X, FAIL_Y]]

function head(x: number, y: number, dir: 'right' | 'down') {
  const [dx, dy] = { right: [-1, 0], down: [0, -1] }[dir]
  const back = 14
  const side = 8
  return `M${x + dx * back - dy * side},${y + dy * back - dx * side}L${x},${y}L${x + dx * back + dy * side},${y + dy * back + dx * side}`
}

const diamond = (cx: number) => `M${cx},${MAIN_Y - DIAMOND}L${cx + DIAMOND},${MAIN_Y}L${cx},${MAIN_Y + DIAMOND}L${cx - DIAMOND},${MAIN_Y}Z`

const guards = [
  { text: '[passed]', x: (decision1X + DIAMOND + clippyX) / 2, y: MAIN_Y - 18, anchor: 'middle' },
  { text: '[passed]', x: (decision2X + DIAMOND + historyX) / 2, y: MAIN_Y - 18, anchor: 'middle' },
  { text: '[failed]', x: decision1X + 12, y: (MAIN_Y + FAIL_Y) / 2 + 8, anchor: 'start' },
  { text: '[failed]', x: decision2X + 12, y: (MAIN_Y + FAIL_Y) / 2 + 8, anchor: 'start' },
]
</script>

<template>
  <svg class="act" viewBox="0 0 1280 720">
    <g :transform="`translate(${OFFSET}, 0)`">
      <g class="flow">
        <template v-for="[d, x, y, dir] in flows" :key="d">
          <path class="line" :d="d" />
          <path :d="head(x, y, dir)" />
        </template>
      </g>

      <g class="node">
        <circle :cx="INITIAL_X" :cy="MAIN_Y" :r="NODE_R" class="filled" />
        <template v-for="[x, y] in finals" :key="`${x},${y}`">
          <circle :cx="x" :cy="y" :r="NODE_R" />
          <circle :cx="x" :cy="y" :r="NODE_R - 6" class="filled" />
        </template>
        <path :d="diamond(decision1X)" />
        <path :d="diamond(decision2X)" />
      </g>

      <g v-for="a in actions" :key="a.label" class="action">
        <rect :x="a.x" :y="MAIN_Y - ACTION.h / 2" :width="ACTION.w" :height="ACTION.h" rx="16" />
        <text :x="a.x + ACTION.w / 2" :y="MAIN_Y" text-anchor="middle" dominant-baseline="middle" :class="{ mono: a.mono }">{{ a.label }}</text>
      </g>

      <text v-for="g in guards" :key="g.text + g.x" class="guard" :x="g.x" :y="g.y" :text-anchor="g.anchor">{{ g.text }}</text>
    </g>
  </svg>
</template>

<style scoped>
.act {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
}

.flow path,
.node path,
.node circle,
.action rect {
  fill: none;
  stroke: #fdfdfd;
  stroke-width: 2;
  stroke-linejoin: round;
}

.node path,
.node circle,
.action rect {
  fill: var(--bg);
}

.flow .line {
  stroke-dasharray: 8 6;
}

.node .filled {
  fill: #fdfdfd;
}

text {
  fill: var(--fg);
  font-size: 24px;
}

.mono {
  font-family: Menlo, ui-monospace, monospace;
  font-size: 22px;
}

.guard {
  font-size: 19px;
}
</style>
