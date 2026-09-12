#!/usr/bin/env bun

import { render } from "ink";
import { HELP, parseArgs } from "./args";
import { loadAck } from "./ack";
import { App } from "./app";
import { printJSON, printText } from "./report";
import { fetchSnapshot } from "./snapshot";

const args = parseArgs(process.argv.slice(2));

if (args.help) {
  process.stdout.write(HELP);
  process.exit(0);
}

const interactive = process.stdout.isTTY && !args.json && !args.once;

if (!interactive) {
  try {
    const snapshot = await fetchSnapshot();
    const acked = await loadAck();
    process.stdout.write(args.json ? printJSON(snapshot, acked) : printText(snapshot, acked));
  } catch (error) {
    process.stderr.write(`${error instanceof Error ? error.message : String(error)}\n`);
    process.exit(1);
  }
} else {
  const instance = render(<App section={args.section} />, {
    alternateScreen: true,
    exitOnCtrlC: true,
  });
  await instance.waitUntilExit();
}
