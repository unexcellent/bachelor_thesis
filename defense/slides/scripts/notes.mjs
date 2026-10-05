// Writes build/notes.json with the speaker notes of every slide, in slide order,
// for scripts/handout.typ. Notes are read with Slidev's own parser so they match
// the presenter view, and are escaped so Typst renders them as plain text
// (markdown bullet lists map onto Typst lists unchanged).
import { mkdir, writeFile } from 'node:fs/promises'
import { createRequire } from 'node:module'

const require = createRequire(import.meta.resolve('@slidev/cli/package.json'))
const { load } = await import(require.resolve('@slidev/parser/fs'))

const data = await load(process.cwd(), 'slides.md')

/** Escape everything Typst markup would interpret, then restore list markers at line starts. */
function toTypst(note) {
  if (!note)
    return ''
  return note
    .split('\n')
    .map((line) => {
      const [, indent, marker, text] = line.match(/^(\s*)(- )?(.*)$/)
      const escaped = text.replace(/[\\#$*_`<>@[\]~=/+"']/g, c => `\\${c}`)
      return indent + (marker ?? '') + escaped
    })
    .join('\n')
}

await mkdir('build', { recursive: true })
await writeFile('build/notes.json', JSON.stringify(data.slides.map(s => toTypst(s.note)), null, 2))
console.log(`notes for ${data.slides.length} slides written`)
