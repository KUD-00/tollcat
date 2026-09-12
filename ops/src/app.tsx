import { Box, Text, useApp, useInput, useWindowSize } from "ink";
import { type ReactNode, useCallback, useEffect, useMemo, useState } from "react";
import { loadAck, saveAck, toggleAck } from "./ack";
import { truncate } from "./format";
import { ackKey, buildQueue, feedbackItem, tipItem } from "./queue";
import {
  HealthScreen,
  InboxScreen,
  MasterDetail,
  UsageScreen,
  feedbackRows,
  queueRows,
  tipRows,
} from "./screens";
import { fetchSnapshot } from "./snapshot";
import { SECTIONS, type QueueItem, type Section, type Snapshot } from "./types";
import { Header, HelpOverlay, HintBar, Rule, Spinner, TabBar } from "./ui";

export function App(props: { section: Section }) {
  const { exit } = useApp();
  const { columns, rows } = useWindowSize();
  const [section, setSection] = useState<Section>(props.section);
  const [snapshot, setSnapshot] = useState<Snapshot | null>(null);
  const [acked, setAcked] = useState<Set<string>>(new Set());
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [help, setHelp] = useState(false);
  const [flash, setFlash] = useState<string | null>(null);
  const [cursor, setCursor] = useState<Record<Section, number>>({
    queue: 0,
    feedback: 0,
    tips: 0,
    inbox: 0,
    usage: 0,
    health: 0,
  });
  const [now, setNow] = useState(() => new Date());

  const refresh = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [nextSnapshot, nextAck] = await Promise.all([fetchSnapshot(), loadAck()]);
      setSnapshot(nextSnapshot);
      setAcked(nextAck);
      setNow(new Date());
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : String(caught));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  useEffect(() => {
    if (!flash) return;
    const timer = setTimeout(() => setFlash(null), 1600);
    return () => clearTimeout(timer);
  }, [flash]);

  const queue = useMemo(
    () => (snapshot ? buildQueue(snapshot, acked) : []),
    [snapshot, acked],
  );

  useEffect(() => {
    if (!snapshot) return;
    setCursor((prev) => ({
      queue: clamp(prev.queue, 0, Math.max(0, queue.length - 1)),
      feedback: clamp(prev.feedback, 0, Math.max(0, snapshot.feedback.length - 1)),
      tips: clamp(prev.tips, 0, Math.max(0, snapshot.tips.length - 1)),
      inbox: 0,
      usage: 0,
      health: 0,
    }));
  }, [queue.length, snapshot]);

  const selectedQueue: QueueItem | undefined = queue[cursor.queue];
  const selectedFeedback = snapshot?.feedback[cursor.feedback];
  const selectedTip = snapshot?.tips[cursor.tips];

  const counts: Partial<Record<Section, number>> = {
    queue: queue.length,
    feedback: snapshot?.feedback.length ?? 0,
    tips: snapshot?.tips.length ?? 0,
    inbox: snapshot?.mailbox.inboxes ?? 0,
    usage: snapshot?.usage
      ? snapshot.usage.visits.reduce((sum, row) => sum + row.visits, 0)
      : undefined,
    health: (snapshot?.health.pendingMigrations.length ?? 0) +
      (snapshot?.health.warnings.length ?? 0),
  };

  const alerts = {
    queue: queue.length > 0,
    health: (snapshot?.health.pendingMigrations.length ?? 0) > 0,
    usage: snapshot !== null && snapshot.usage === null,
  };

  const listLength = (current: Section): number => {
    if (!snapshot) return 0;
    if (current === "queue") return queue.length;
    if (current === "feedback") return snapshot.feedback.length;
    if (current === "tips") return snapshot.tips.length;
    return 0;
  };

  const move = (delta: number) => {
    const length = listLength(section);
    if (length === 0) return;
    setCursor((prev) => ({
      ...prev,
      [section]: clamp(prev[section] + delta, 0, length - 1),
    }));
  };

  const jump = (index: number) => {
    const length = listLength(section);
    if (length === 0) return;
    setCursor((prev) => ({ ...prev, [section]: clamp(index, 0, length - 1) }));
  };

  const changeSection = (next: Section) => {
    setSection(next);
    setHelp(false);
  };

  const ackCurrent = () => {
    if (!snapshot) return;
    let key: string | null = null;
    if (section === "queue" && selectedQueue && selectedQueue.kind !== "health") {
      key = selectedQueue.id;
    } else if (section === "feedback" && selectedFeedback) {
      key = ackKey("feedback", selectedFeedback.id);
    } else if (section === "tips" && selectedTip) {
      key = ackKey("tip", selectedTip.transactionId);
    }
    if (!key) {
      setFlash("这一条不能标已读");
      return;
    }
    const next = toggleAck(acked, key);
    setAcked(next);
    void saveAck(next);
    setFlash(next.has(key) ? "已标已读" : "已恢复未读");
  };

  const copyCurrent = () => {
    let text: string | null = null;
    if (section === "queue") text = selectedQueue?.copyText ?? null;
    else if (section === "feedback" && selectedFeedback) {
      text = feedbackItem(selectedFeedback).copyText;
    } else if (section === "tips" && selectedTip) {
      text = tipItem(selectedTip).copyText;
    }
    if (!text) {
      setFlash("没有可复制的内容");
      return;
    }
    const copied = text;
    void copyText(copied).then(
      () => setFlash(`已复制 ${truncate(copied, 24)}`),
      () => setFlash("复制失败"),
    );
  };

  useInput((input, key) => {
    if (key.escape && help) {
      setHelp(false);
      return;
    }
    if (input === "q") {
      exit();
      return;
    }
    if (input === "?") {
      setHelp((value) => !value);
      return;
    }
    if (help) return;
    if (input === "r") {
      void refresh();
      return;
    }
    if (input >= "1" && input <= "6") {
      const next = SECTIONS[Number(input) - 1];
      if (next) changeSection(next);
      return;
    }
    if (key.tab || key.rightArrow || key.leftArrow) {
      const index = SECTIONS.indexOf(section);
      const delta = key.leftArrow || key.shift ? -1 : 1;
      changeSection(SECTIONS[(index + delta + SECTIONS.length) % SECTIONS.length]!);
      return;
    }
    if (input === "j" || key.downArrow) {
      move(1);
      return;
    }
    if (input === "k" || key.upArrow) {
      move(-1);
      return;
    }
    if (input === "g") {
      jump(0);
      return;
    }
    if (input === "G") {
      jump(9999);
      return;
    }
    if (input === " ") {
      ackCurrent();
      return;
    }
    if (input === "y") copyCurrent();
  });

  const width = Math.max(40, columns - 2);
  const bodyHeight = Math.max(6, rows - 5);
  const wide = columns >= 100;
  const account = snapshot?.account
    ? `${snapshot.account.name} · ${snapshot.account.email}`
    : "";

  let body: ReactNode;
  if (loading && !snapshot) {
    body = (
      <Box height={bodyHeight} alignItems="center" justifyContent="center">
        <Spinner label="正在用本机 wrangler 拉远端 D1…" />
      </Box>
    );
  } else if (error && !snapshot) {
    body = (
      <Box height={bodyHeight} flexDirection="column" paddingTop={1}>
        <Text color="red">{error}</Text>
        <Text dimColor>r 重试    q 退出</Text>
      </Box>
    );
  } else if (snapshot && section === "inbox") {
    body = <InboxScreen snapshot={snapshot} now={now} height={bodyHeight} />;
  } else if (snapshot && section === "usage") {
    body = <UsageScreen snapshot={snapshot} height={bodyHeight} />;
  } else if (snapshot && section === "health") {
    body = <HealthScreen snapshot={snapshot} now={now} height={bodyHeight} />;
  } else if (snapshot && section === "queue") {
    const item = selectedQueue;
    body = (
      <MasterDetail
        rows={queueRows(queue, now)}
        selected={cursor.queue}
        title={item ? item.title : "待办"}
        lines={item ? item.lines : ["没有待办。"]}
        empty="没有待办。"
        wide={wide}
        width={width}
        height={bodyHeight}
      />
    );
  } else if (snapshot && section === "feedback") {
    const item = selectedFeedback ? feedbackItem(selectedFeedback) : null;
    body = (
      <MasterDetail
        rows={feedbackRows(snapshot, acked, now)}
        selected={cursor.feedback}
        title={item ? item.title : "反馈"}
        lines={item ? item.lines : ["还没有反馈。"]}
        empty="还没有反馈。"
        wide={wide}
        width={width}
        height={bodyHeight}
      />
    );
  } else if (snapshot) {
    const item = selectedTip ? tipItem(selectedTip) : null;
    body = (
      <MasterDetail
        rows={tipRows(snapshot, acked, now)}
        selected={cursor.tips}
        title={item ? item.title : "打赏"}
        lines={item ? item.lines : ["还没有打赏。"]}
        empty="还没有打赏。"
        wide={wide}
        width={width}
        height={bodyHeight}
      />
    );
  }

  return (
    <Box flexDirection="column" width={columns} height={rows} paddingX={1}>
      <Header account={account} fetchedAt={snapshot?.fetchedAt ?? null} now={now} />
      <TabBar section={section} counts={counts} alerts={alerts} />
      <Rule width={width} />
      <Box flexGrow={1} height={bodyHeight} flexDirection="column">
        {help ? (
          <Box height={bodyHeight} alignItems="center" justifyContent="center">
            <HelpOverlay />
          </Box>
        ) : (
          body
        )}
      </Box>
      <HintBar
        flash={loading && snapshot ? "刷新中…" : error && snapshot ? error : flash}
      />
    </Box>
  );
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value));
}

async function copyText(text: string): Promise<void> {
  const proc = Bun.spawn(["pbcopy"], { stdin: "pipe" });
  proc.stdin.write(text);
  proc.stdin.end();
  const code = await proc.exited;
  if (code !== 0) throw new Error("pbcopy failed");
}
