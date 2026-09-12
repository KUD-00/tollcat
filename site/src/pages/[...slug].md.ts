import type { APIRoute } from 'astro';
import { agentRoutes, markdownResponse, pageMarkdown, type AgentPage } from '../agent';
import type { Locale } from '../config';

type Props = { locale: Locale; page: AgentPage };

export function getStaticPaths() {
  return agentRoutes().map((route) => ({
    params: { slug: route.slug },
    props: { locale: route.locale, page: route.page } satisfies Props,
  }));
}

export const GET: APIRoute<Props> = ({ props }) => markdownResponse(pageMarkdown(props.locale, props.page));
