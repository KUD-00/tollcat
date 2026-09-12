### TollCat 1.1：看哪个月，就说哪个月

- **换了月份，页面上的字也跟着换** — 选了七月或者近 3 个月，仪表盘上原来写「本月」的地方都会改成那段时间。「之最」那一节也一样。固定订阅卡在跨月区间里列的是那几个月实际扣过的每一笔，中途退掉的也算在里面。
- **订阅金额搬到日期上面** — 算进固定订阅的时候，大数字底下多一行「（订阅 $X）」，告诉你总数里有多少是订阅。关掉订阅这一行就不出现，不再写「已计入」「未计入」。
- **155 家的接入说明重写了** — 每一步都指到真正创建密钥的那一页，顺手写清要哪些权限、密钥只显示一次这类容易踩的坑。连接失败时的提示也按每家的实际情况改准了。
- **DigitalOcean、Stripe、Botpress、Neo4j Aura 用真实账单核对过了** — 这四家从「待验证」升为「完全支持」。接上去，数字就是你账单上的数字。
- **反馈里附带的响应，打码更严了** — 发反馈时选择附带测试连接的响应，所有以 token 结尾的字段一律打掉，之前有几家的写法漏了。用量统计里的 tokens 数字不受影响。

### TollCat 1.1: says the month you’re looking at

- **Pick a month, and the page talks about that month** — Choose July or the last 3 months and every spot that used to say “this month” now names that period, the superlatives section included. Over a multi-month range the subscriptions card lists what was actually charged in those months, cancelled ones too.
- **The subscription amount now sits above the date** — With subscriptions included, a line like “(Subscriptions $20)” appears under the big number so you can see how much of the total is subscriptions. Turn them off and the line goes away. No more “included” or “not included”.
- **Setup guides for 155 services, rewritten** — Each step now points at the exact page where the key gets created, and calls out the traps along the way: which permission to tick, keys that are shown only once. The messages you see when a connection fails were made specific to each service too.
- **DigitalOcean, Stripe, Botpress and Neo4j Aura checked against real bills** — These four move from “pending verification” to fully supported. Connect one and the number you see is the number on your bill.
- **Stricter redaction in feedback attachments** — If you attach the test-connection response to a feedback report, every field ending in “token” is now blanked out. A few services spelled theirs in a way that slipped through before. Usage counts like total_tokens are untouched.

Shipping to: iPhone · iPad
