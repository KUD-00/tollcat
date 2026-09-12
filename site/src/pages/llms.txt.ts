import type { APIRoute } from 'astro';
import { llmsTxt, plainResponse } from '../agent';

export const GET: APIRoute = () => plainResponse(llmsTxt());
