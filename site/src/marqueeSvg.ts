import { providerRows, type ProviderMark } from './providers';

const CELL = 50;
const GAP = 11;
const RADIUS = 11;

export const marqueeRowCount = 3;
export const marqueeThemes = ['light', 'dark'] as const;
export type MarqueeTheme = (typeof marqueeThemes)[number];

export function marqueeRowSize(count: number): { width: number; height: number } {
  if (count === 0) return { width: CELL, height: CELL };
  return { width: count * CELL + (count - 1) * GAP, height: CELL };
}

function xmlEscape(value: string): string {
  return value.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

function glyphSvg(mark: ProviderMark, x: number, theme: MarqueeTheme): string {
  const bg = theme === 'dark' ? mark.dark : mark.light;
  const ink = theme === 'dark' ? '#0e1116' : '#ffffff';
  const fill = mark.fill ?? 0.68;
  const pad = ((1 - fill) / 2) * CELL;
  const inner = CELL - pad * 2;
  const letter = mark.key.charAt(0).toUpperCase();
  const icon = mark.path
    ? `<svg x="${pad}" y="${pad}" width="${inner}" height="${inner}" viewBox="0 0 24 24"><path d="${xmlEscape(mark.path)}" fill="${ink}" fill-rule="${mark.evenOdd ? 'evenodd' : 'nonzero'}"/></svg>`
    : `<text x="${CELL / 2}" y="${CELL / 2}" text-anchor="middle" dominant-baseline="central" fill="${ink}" font-size="20" font-weight="650" font-family="ui-sans-serif, system-ui, sans-serif">${xmlEscape(letter)}</text>`;
  return `<g transform="translate(${x} 0)"><rect width="${CELL}" height="${CELL}" rx="${RADIUS}" fill="${bg}"/>${icon}</g>`;
}

export function marqueeRowSvg(theme: MarqueeTheme, row: number): string {
  const marks = providerRows(marqueeRowCount)[row] ?? [];
  const { width, height } = marqueeRowSize(marks.length);
  const body = marks.map((mark, index) => glyphSvg(mark, index * (CELL + GAP), theme)).join('');
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" fill="none">${body}</svg>`;
}

export function marqueeRowMarks(row: number): ProviderMark[] {
  return providerRows(marqueeRowCount)[row] ?? [];
}
