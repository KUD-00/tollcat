import { Box, Text } from "ink";
import { useEffect, useState } from "react";
import { relativeTime } from "./format";
import { accent, HELP_LINES, tabLabel } from "./theme";
import { SECTIONS, type Section } from "./types";

export type ListRow = {
  id: string;
  kicker: string;
  title: string;
  meta: string;
  dim?: boolean;
  warn?: boolean;
};

export function Header(props: {
  account: string;
  fetchedAt: string | null;
  now: Date;
}) {
  return (
    <Box justifyContent="space-between">
      <Text>
        <Text color={accent} bold>
          TollCat ops
        </Text>
        <Text dimColor>  api.tollcat.app</Text>
      </Text>
      <Text dimColor>
        {props.account}
        {props.fetchedAt ? `  ·  ${relativeTime(props.fetchedAt, props.now)}` : ""}
      </Text>
    </Box>
  );
}

export function TabBar(props: {
  section: Section;
  counts: Partial<Record<Section, number>>;
  alerts: Partial<Record<Section, boolean>>;
}) {
  return (
    <Box gap={2}>
      {SECTIONS.map((section, index) => {
        const active = section === props.section;
        const count = props.counts[section];
        const alert = props.alerts[section] === true;
        return (
          <Text
            key={section}
            color={active ? accent : alert ? "yellow" : undefined}
            bold={active}
            dimColor={!active && !alert}
            underline={active}
          >
            {index + 1} {tabLabel[section]}
            {typeof count === "number" ? ` ${count}` : ""}
          </Text>
        );
      })}
    </Box>
  );
}

export function Rule({ width }: { width: number }) {
  return <Text dimColor>{"─".repeat(Math.max(8, width))}</Text>;
}

export function ScrollList(props: {
  rows: ListRow[];
  selected: number;
  height: number;
  empty: string;
}) {
  if (props.rows.length === 0) {
    return (
      <Box height={props.height} flexDirection="column">
        <Text dimColor>{props.empty}</Text>
      </Box>
    );
  }

  const height = Math.max(1, props.height);
  const { visible, start } = windowed(props.rows, props.selected, height);

  return (
    <Box height={height} flexDirection="column" overflow="hidden">
      {visible.map((row, index) => {
        const selected = start + index === props.selected;
        const color = selected ? undefined : row.warn ? "yellow" : undefined;
        return (
          <Box key={row.id} gap={1}>
            <Text inverse={selected} color={color} dimColor={!selected && row.dim}>
              {selected ? "›" : " "}
            </Text>
            <Box width={6}>
              <Text
                inverse={selected}
                color={color}
                dimColor={!selected && (row.dim || !row.warn)}
              >
                {row.kicker}
              </Text>
            </Box>
            <Box flexGrow={1}>
              <Text
                inverse={selected}
                color={color}
                dimColor={!selected && row.dim}
                wrap="truncate"
              >
                {row.title}
              </Text>
            </Box>
            <Text inverse={selected} dimColor={!selected} wrap="truncate">
              {row.meta}
            </Text>
          </Box>
        );
      })}
    </Box>
  );
}

export function Detail(props: { title: string; lines: string[]; height: number }) {
  const bodyHeight = Math.max(0, props.height - 1);
  return (
    <Box flexDirection="column" height={props.height} overflow="hidden" paddingLeft={1}>
      <Text bold wrap="truncate">
        {props.title}
      </Text>
      {props.lines.slice(0, bodyHeight).map((line, index) => (
        <Text key={`${index}:${line.slice(0, 24)}`} wrap="truncate">
          {line.length === 0 ? " " : line}
        </Text>
      ))}
    </Box>
  );
}

export function HintBar(props: { flash: string | null }) {
  if (props.flash) {
    return <Text color={accent}>{props.flash}</Text>;
  }
  return (
    <Text dimColor>
      j/k 移动  1-6 切页  space 已读  y 复制  r 刷新  ? 帮助  q 退出
    </Text>
  );
}

export function Spinner({ label }: { label: string }) {
  const frames = "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏";
  const [i, setI] = useState(0);
  useEffect(() => {
    const timer = setInterval(() => setI((n) => (n + 1) % frames.length), 80);
    return () => clearInterval(timer);
  }, []);
  return (
    <Text>
      <Text color={accent}>{frames[i]}</Text> {label}
    </Text>
  );
}

export function HelpOverlay() {
  return (
    <Box
      flexDirection="column"
      borderStyle="round"
      borderColor={accent}
      paddingX={2}
      paddingY={1}
      width={42}
    >
      <Text bold color={accent}>
        键盘
      </Text>
      {HELP_LINES.map((line) => (
        <Text key={line} dimColor>
          {line}
        </Text>
      ))}
    </Box>
  );
}

export function windowed<T>(
  rows: T[],
  selected: number,
  height: number,
): { start: number; visible: T[] } {
  if (rows.length <= height) return { start: 0, visible: rows };
  const mid = Math.floor(height / 2);
  let start = Math.max(0, selected - mid);
  start = Math.min(start, rows.length - height);
  return { start, visible: rows.slice(start, start + height) };
}
