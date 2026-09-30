### TollCat 1.3：上了 Android，也上了手表

- **新图标：装在口袋里的猫** — 图标换成一只装在口袋里的猫，身后插着云、AI 和数据库三枚圆牌。打开 App 时，这三枚圆牌会从口袋里飞出来，落到仪表盘上对应的服务旁边。
- **手表上也能看** — iPhone 版带上了 Apple Watch App 和表盘上的小组件，抬手就能看到这个月到现在花了多少。锁屏上也能放一个。
- **Android 版来了** — 和 iPhone 上是同一套算法、同一份接入说明，仪表盘按 Material 3 重新做了一遍。凭据只存在这台手机的 Android Keystore 里。
- **读数更可靠了** — 用欧元、日元等币种结账的服务，明细行现在和总数用同一个汇率换算，不再把原币的数字标成美元。凭据失效或接口出错时，也不会再把这个月报成 $0，而是告诉你这次没读到，数字停在上一次。
- **做了一轮安全检查** — 删除一个服务时，会先吊销它在信箱里的投递 key，再清掉本地记录。断网删不掉会告诉你，不会悄悄留下一把还能用的 key。

### TollCat 1.3: on Android, and on your wrist

- **A new icon: a cat in your pocket** — The icon is now a cat sitting in a pocket, with three round badges tucked behind it for cloud, AI and database services. When you open the app, the badges fly out of the pocket and land next to the matching services on your dashboard.
- **On your wrist, too** — The iPhone app now comes with an Apple Watch app and watch face complications, so one look at your wrist tells you what this month has cost so far. You can put one on the Lock Screen as well.
- **TollCat on Android** — The same calculations and the same setup guides as on iPhone, with the dashboard rebuilt in Material 3. Your credentials stay in this phone’s Android Keystore.
- **More reliable readings** — For services billed in euros, yen or other currencies, itemized lines now use the same exchange rate as the total instead of showing the original amount as dollars. And when a credential has expired or an API returns an error, the month no longer shows $0: you’re told the update failed and the last number stays.
- **A security review** — This release went through a security review. Removing a service now revokes its inbox ingest key before clearing local records, and if you’re offline you’ll be told, instead of a working key being left behind.

Shipping to: iPhone · iPad · Mac · Android
