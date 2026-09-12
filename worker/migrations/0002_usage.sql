-- 匿名页面计数。不存标识、不存 IP、不存事件流水。
--
-- visits：客户端声称的「这个 UTC 日第一次成功打开」。可被灌，但是对不上人。
-- views：各屏进入次数。客户端对「连续停在同一页」去重。

CREATE TABLE IF NOT EXISTS usage_visits (
  day TEXT NOT NULL,
  platform TEXT NOT NULL,
  visits INTEGER NOT NULL,
  PRIMARY KEY (day, platform)
);

CREATE TABLE IF NOT EXISTS usage_screens (
  day TEXT NOT NULL,
  platform TEXT NOT NULL,
  screen TEXT NOT NULL,
  views INTEGER NOT NULL,
  PRIMARY KEY (day, platform, screen)
);
