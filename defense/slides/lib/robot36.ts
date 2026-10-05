/**
 * Robot 36 constants and canvas helpers shared by the slide components.
 *
 * Timings and frequencies follow the Dayton paper; the colour model is the
 * analogue BT.601 YUV used in the thesis.
 */

export const WIDTH = 320
export const HEIGHT = 240
/** Duration of one luminance pixel: 88 ms of Y scan over 320 pixels. */
export const PIXEL_MS = 0.275
export const SYNC_HZ = 1200
export const BLACK_HZ = 1500
export const WHITE_HZ = 2300

/** Maps an 8-bit level onto the 1500 Hz to 2300 Hz tone range. */
export function levelToHz(level: number) {
  return BLACK_HZ + (Math.min(255, Math.max(0, level)) / 255) * (WHITE_HZ - BLACK_HZ)
}

export function loadImage(src: string): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const img = new Image()
    img.onload = () => resolve(img)
    img.onerror = reject
    // Props skip Vite's asset URL rewriting, so prefix the deploy base for public paths.
    img.src = src.startsWith('/') ? import.meta.env.BASE_URL + src.slice(1) : src
  })
}

/** Downsamples an image to the Robot 36 resolution (or any other). */
export function samplePixels(img: HTMLImageElement, width = WIDTH, height = HEIGHT) {
  const canvas = document.createElement('canvas')
  canvas.width = width
  canvas.height = height
  const ctx = canvas.getContext('2d', { willReadFrequently: true })!
  ctx.drawImage(img, 0, 0, width, height)
  return ctx.getImageData(0, 0, width, height)
}

export function setupCanvas(canvas: HTMLCanvasElement, scale = 2) {
  // A canvas hidden by v-show has no layout box, so fall back to its CSS size.
  const style = getComputedStyle(canvas)
  const w = canvas.offsetWidth || Number.parseFloat(style.width)
  const h = canvas.offsetHeight || Number.parseFloat(style.height)
  canvas.width = w * scale
  canvas.height = h * scale
  const ctx = canvas.getContext('2d')!
  ctx.setTransform(scale, 0, 0, scale, 0, 0)
  return { ctx, w, h }
}

/** Draws image data scaled to the canvas without smoothing, so pixels stay visible. */
export function drawPixels(canvas: HTMLCanvasElement, pixels: ImageData) {
  const target = setupCanvas(canvas)
  const tiny = document.createElement('canvas')
  tiny.width = pixels.width
  tiny.height = pixels.height
  tiny.getContext('2d')!.putImageData(pixels, 0, 0)
  target.ctx.imageSmoothingEnabled = false
  target.ctx.drawImage(tiny, 0, 0, target.w, target.h)
  return target
}

export function luma(r: number, g: number, b: number) {
  return 0.299 * r + 0.587 * g + 0.114 * b
}

export function rgbToYuv(r: number, g: number, b: number): [number, number, number] {
  const y = luma(r, g, b)
  return [y, 0.492 * (b - y), 0.877 * (r - y)]
}

export function yuvToRgb(y: number, u: number, v: number): [number, number, number] {
  const r = y + v / 0.877
  const b = y + u / 0.492
  return [r, (y - 0.299 * r - 0.114 * b) / 0.587, b]
}
