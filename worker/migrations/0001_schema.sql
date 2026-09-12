-- 首发基线 schema。发布前压平过一次：这里就是全部真相，没有历史迁移考古。

-- 打赏留言。JWS 存而不验（伪造者拿不到钱，最坏是垃圾留言）。
CREATE TABLE IF NOT EXISTS tips (
  transaction_id TEXT PRIMARY KEY,
  product_id TEXT NOT NULL,
  display_price TEXT NOT NULL,
  name TEXT,
  message TEXT,
  app_version TEXT,
  jws TEXT NOT NULL,
  created_at TEXT NOT NULL
);

-- 读数信箱。官方没有账单接口的那几家（Render / Expo / Clerk …），
-- 用户自己在自己机器上取数，再把数字投递到这里，App 打开时取回。
--
-- 这张表里没有任何 provider 凭据，也没有任何能花钱的东西。
-- 最坏情况被拖库，泄露的是一堆和人对不上的匿名金额。

CREATE TABLE IF NOT EXISTS inboxes (
  -- 公开标识，128 位随机。不是账号，没有邮箱没有密码。
  id TEXT PRIMARY KEY,
  -- read key 只存 SHA-256。D1 被 dump 也拿不到读取权限。
  read_key_hash TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS inboxes_read_key ON inboxes (read_key_hash);

-- 投递 key，一个信箱可以有多把。
--
-- 为什么是一张表而不是 inboxes 上的一列：key 会散落在 N 个脚本和 CI 里。
-- 只有一把的时候，任何一处泄露都要轮换全部，而轮换是一刀切——所有脚本
-- 同时失效，改到一半就是断的。拆开之后一个脚本一把（label 记它是谁），
-- 泄露和吊销都只影响那一个，新旧还能共存一段时间，平滑过渡。
--
-- 信箱和 read key 仍然是一个用户一份，多把的只有投递侧。

CREATE TABLE IF NOT EXISTS ingest_keys (
  id TEXT PRIMARY KEY,
  inbox_id TEXT NOT NULL,
  -- 同样只存 SHA-256。鉴权直接按哈希查行。
  key_hash TEXT NOT NULL UNIQUE,
  -- 给人看的名字，例如「Render 抓取」。不参与鉴权。
  label TEXT,
  created_at TEXT NOT NULL,
  last_used_at TEXT,
  FOREIGN KEY (inbox_id) REFERENCES inboxes (id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS ingest_keys_inbox ON ingest_keys (inbox_id);

-- 每把投递 key 只留最新一条：投递是覆盖写，重复投递幂等。
-- 历史留在设备上（SnapshotRecord 永不删除），这里不做金额历史库。
CREATE TABLE IF NOT EXISTS readings (
  ingest_key_id TEXT PRIMARY KEY,
  inbox_id TEXT NOT NULL,
  provider TEXT NOT NULL,
  period_start TEXT NOT NULL,
  -- 十进制字符串，不用 REAL。分位不许被二进制浮点改掉。
  current_spend_usd TEXT,
  reported_at TEXT NOT NULL,
  FOREIGN KEY (inbox_id) REFERENCES inboxes (id) ON DELETE CASCADE,
  FOREIGN KEY (ingest_key_id) REFERENCES ingest_keys (id) ON DELETE CASCADE
);

-- 取回和删除都按信箱扫。
CREATE INDEX IF NOT EXISTS readings_inbox ON readings (inbox_id);

-- 通用限流桶（`tip:<ip>`、`ingest:<inbox>` …），各功能互不挤占额度。
CREATE TABLE IF NOT EXISTS rate_limits (
  bucket TEXT PRIMARY KEY,
  window_start INTEGER NOT NULL,
  count INTEGER NOT NULL
);

-- 用户反馈。设置 →「其他」→「反馈」发过来的。
--
-- 这张表刻意没有任何能把一条反馈连回某个人的东西：没有信箱 id，没有设备
-- 标识，没有 IP。留 IP 能反查滥用，但也就等于给这张表配了一列身份——
-- 限流已经在 rate_limits 里按 IP 做过了，那张表不留内容，这张表不留身份。
--
-- contact 是用户自己主动填的一行字（邮箱 / 任意 handle），空着就是空着。
-- 想匿名提就匿名提，我们没有回信的义务也没有回信的手段。

CREATE TABLE IF NOT EXISTS feedback (
  -- 客户端生成的 UUID。POST 超时后重发走 INSERT OR IGNORE，不会变成两条。
  id TEXT PRIMARY KEY,
  -- bug / idea / provider / other。存字符串而不是整数：以后加一类不用迁移。
  category TEXT NOT NULL,
  message TEXT NOT NULL,
  contact TEXT,
  app_version TEXT NOT NULL,
  os_version TEXT NOT NULL,
  locale TEXT NOT NULL,
  device_model TEXT,
  -- 用户显式勾选才带：已接入的服务名单，逗号分隔。
  -- 只有服务名，没有金额，没有凭据，没有用量。
  providers TEXT,
  created_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS feedback_created ON feedback (created_at DESC);
