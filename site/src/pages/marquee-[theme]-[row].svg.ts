import type { APIRoute } from 'astro';
import { marqueeRowCount, marqueeRowSvg, marqueeThemes, type MarqueeTheme } from '../marqueeSvg';

export function getStaticPaths() {
  return marqueeThemes.flatMap((theme) =>
    Array.from({ length: marqueeRowCount }, (_, row) => ({
      params: { theme, row: String(row) },
    })),
  );
}

export const GET: APIRoute = ({ params }) => {
  const theme = params.theme as MarqueeTheme;
  const row = Number(params.row);
  return new Response(marqueeRowSvg(theme, row), {
    headers: {
      'Content-Type': 'image/svg+xml; charset=utf-8',
      'Cache-Control': 'public, max-age=86400',
    },
  });
};
