<script setup lang="ts">
/**
 * The thesis state machine of the SSTV system, redrawn in the deck's style
 * without the diagram frame. Coordinates follow the thesis figure so the
 * layout stays recognisable; the SVG scales them onto the slide.
 */

interface State { name: string, x: number, y: number, w: number, h: number }
interface Transition { d: string, head: [number, number, 'up' | 'down' | 'left' | 'right'], label?: string[], at?: [number, number] }

const states: State[] = [
  { name: 'Error', x: 742, y: 25, w: 340, h: 173 },
  { name: 'Initialization', x: 196, y: 342, w: 339, h: 173 },
  { name: 'Idle', x: 742, y: 342, w: 340, h: 173 },
  { name: 'SSTV Transmission', x: 1288, y: 342, w: 340, h: 173 },
  { name: 'Updating', x: 742, y: 658, w: 340, h: 174 },
]

const POINT_R = 17

const transitions: Transition[] = [
  { d: 'M73,428H196', head: [196, 428, 'right'], label: ['Turned on'], at: [130, 404] },
  { d: 'M535,428H742', head: [742, 428, 'right'], label: ['Initialization', 'Successful'], at: [638, 368] },
  { d: 'M365,342V113H742', head: [742, 113, 'right'], label: ['Recoverable Error Occurred'], at: [365, 242] },
  { d: 'M365,515V575H265V515', head: [265, 515, 'up'], label: ['Fatal Error', 'Occurred'], at: [317, 605] },
  { d: 'M830,198V342', head: [830, 342, 'down'] },
  { d: 'M993,342V198', head: [993, 198, 'up'], label: ['Error', 'Occurred'], at: [993, 256] },
  { d: 'M1082,383H1288', head: [1288, 383, 'right'], label: ['SSTV Command', 'Received'], at: [1185, 323] },
  { d: 'M1288,468H1082', head: [1082, 468, 'left'], label: ['Transmission', 'Successful'], at: [1185, 498] },
  { d: 'M1458,342V153H1082', head: [1082, 153, 'left'], label: ['Error Occurred'], at: [1458, 248] },
  { d: `M912,515V${658 - POINT_R}`, head: [912, 658 - POINT_R, 'down'], label: ['Update Announcement', 'Received'], at: [912, 553] },
  { d: `M${742 - POINT_R},745H455V515`, head: [455, 515, 'up'], label: ['Update', 'Successful'], at: [660, 685] },
  { d: `M${1082 + POINT_R},745H1660V66H1082`, head: [1082, 66, 'left'], label: ['Update', 'Failed'], at: [1140, 685] },
]

/** Open arrowhead whose tip sits at (x, y), pointing in `dir`. */
function arrowhead([x, y, dir]: Transition['head']) {
  const [dx, dy] = { up: [0, 1], down: [0, -1], left: [1, 0], right: [-1, 0] }[dir]
  const back = 18
  const side = 11
  return `M${x + dx * back - dy * side},${y + dy * back - dx * side}L${x},${y}L${x + dx * back + dy * side},${y + dy * back + dx * side}`
}

const crossed = (cx: number, cy: number) => {
  const k = POINT_R * Math.SQRT1_2
  return `M${cx - k},${cy - k}L${cx + k},${cy + k}M${cx - k},${cy + k}L${cx + k},${cy - k}`
}
</script>

<template>
  <svg class="stm" viewBox="10 15 1665 830">
    <g class="lines">
      <path v-for="t in transitions" :key="t.d" :d="t.d" />
      <path v-for="t in transitions" :key="`h${t.d}`" :d="arrowhead(t.head)" />
    </g>

    <g v-for="s in states" :key="s.name" class="state">
      <rect :x="s.x" :y="s.y" :width="s.w" :height="s.h" rx="10" />
      <text :x="s.x + s.w / 2" :y="s.y + s.h / 2" text-anchor="middle" dominant-baseline="middle">{{ s.name }}</text>
    </g>

    <g class="points">
      <circle cx="45" cy="428" r="28" class="filled" />
      <circle cx="912" cy="658" :r="POINT_R" />
      <circle cx="742" cy="745" :r="POINT_R" />
      <path :d="crossed(742, 745)" />
      <circle cx="1082" cy="745" :r="POINT_R" />
      <path :d="crossed(1082, 745)" />
      <!-- Composite state icon: two linked states. -->
      <rect x="1000" y="792" width="26" height="22" rx="11" />
      <rect x="1040" y="792" width="26" height="22" rx="11" />
      <path d="M1014,792C1020,780 1046,780 1052,792" />
      <path d="M103,715H277L322,745L277,775H103Z" />
      <circle cx="350" cy="745" r="27" />
      <circle cx="350" cy="745" r="14" class="filled" />
    </g>
    <text class="signal" x="128" y="746" dominant-baseline="middle">Turned off</text>

    <g class="labels">
      <text v-for="t in transitions.filter(t => t.label)" :key="`l${t.d}`" :x="t.at![0]" :y="t.at![1]" text-anchor="middle">
        <tspan v-for="(l, i) in t.label" :key="l" :x="t.at![0]" :dy="i ? 32 : 0">{{ l }}</tspan>
      </text>
    </g>
  </svg>
</template>

<style scoped>
.stm {
  position: absolute;
  left: 20px;
  top: 50px;
  width: 1240px;
  height: 620px;
}

.lines path,
.points path,
.points rect,
.points circle,
.state rect {
  fill: none;
  stroke: #fdfdfd;
  stroke-width: 2.5;
  stroke-linejoin: round;
}

.state rect,
.points circle,
.points rect {
  fill: var(--bg);
}

.points .filled {
  fill: #fdfdfd;
}

.state text {
  fill: var(--fg);
  font-size: 30px;
  font-weight: 600;
}

.signal {
  fill: var(--fg);
  font-size: 26px;
  font-weight: 300;
}

/* The halo hides the line behind labels that sit on a transition. */
.labels text {
  fill: var(--fg);
  font-size: 23px;
  paint-order: stroke;
  stroke: var(--bg);
  stroke-width: 20px;
  stroke-linejoin: round;
}
</style>
