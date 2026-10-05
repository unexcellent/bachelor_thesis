<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { drawPixels, HEIGHT, loadImage, rgbToYuv, samplePixels, WIDTH, yuvToRgb } from '../lib/robot36'

/**
 * How Robot 36 transmits colour: the image split into Y, U and V, then on
 * click U kept on odd lines and V on even lines only.
 */
const props = withDefaults(defineProps<{
  src: string
  step?: number
  /** Chroma amplification for the U and V previews; the raw channels are too faint to read. */
  chromaGain?: number
}>(), {
  step: 0,
  chromaGain: 2.5,
})

const step = computed(() => Math.min(1, Math.max(0, props.step)))

const yCanvas = ref<HTMLCanvasElement>()
const uCanvas = ref<HTMLCanvasElement>()
const vCanvas = ref<HTMLCanvasElement>()

let yuv: Float32Array | undefined

const channels = computed(() => [
  { ref: yCanvas, name: 'Y', detail: step.value ? 'every line' : 'luminance' },
  { ref: uCanvas, name: 'U', detail: step.value ? 'odd lines' : 'blue difference' },
  { ref: vCanvas, name: 'V', detail: step.value ? 'even lines' : 'red difference' },
])

function image(fill: (row: number, col: number) => [number, number, number] | undefined) {
  const out = new ImageData(WIDTH, HEIGHT)
  for (let row = 0; row < HEIGHT; row++) {
    for (let col = 0; col < WIDTH; col++) {
      const rgb = fill(row, col)
      if (!rgb)
        continue
      out.data.set([...rgb, 255], (row * WIDTH + col) * 4)
    }
  }
  return out
}

function at(row: number, col: number) {
  const i = (row * WIDTH + col) * 3
  return [yuv![i], yuv![i + 1], yuv![i + 2]] as const
}

function drawChannels() {
  if (!yuv || !yCanvas.value || !uCanvas.value || !vCanvas.value)
    return
  const subsampled = step.value >= 1
  const gain = props.chromaGain
  drawPixels(yCanvas.value, image((r, c) => {
    const l = at(r, c)[0]
    return [l, l, l]
  }))
  drawPixels(uCanvas.value, image((r, c) => {
    if (subsampled && r % 2 === 0)
      return undefined
    return yuvToRgb(128, at(r, c)[1] * gain, 0)
  }))
  drawPixels(vCanvas.value, image((r, c) => {
    if (subsampled && r % 2 === 1)
      return undefined
    return yuvToRgb(128, 0, at(r, c)[2] * gain)
  }))
}

onMounted(async () => {
  const source = samplePixels(await loadImage(props.src))
  yuv = new Float32Array(WIDTH * HEIGHT * 3)
  for (let i = 0; i < WIDTH * HEIGHT; i++)
    yuv.set(rgbToYuv(source.data[i * 4], source.data[i * 4 + 1], source.data[i * 4 + 2]), i * 3)
  drawChannels()
})

watch(step, drawChannels)
</script>

<template>
  <div class="colour">
    <figure v-for="c in channels" :key="c.name">
      <canvas :ref="(el) => (c.ref.value = el as HTMLCanvasElement)" />
      <figcaption>
        <span class="name">{{ c.name }}</span>
        <span class="detail">{{ c.detail }}</span>
      </figcaption>
    </figure>
  </div>
</template>

<style scoped>
.colour {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 64px;
}

figure {
  margin: 0;
}

canvas {
  display: block;
  width: 320px;
  height: 240px;
}

figcaption {
  margin-top: 16px;
  display: flex;
  justify-content: center;
  align-items: baseline;
  gap: 12px;
}

.name {
  font-size: 32px;
  font-weight: 400;
}

.detail {
  font-size: 22px;
  color: var(--muted);
}
</style>
