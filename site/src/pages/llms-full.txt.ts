import type { APIRoute } from 'astro';
import { llmsFullTxt, plainResponse } from '../agent';

export const GET: APIRoute = () => plainResponse(llmsFullTxt());
