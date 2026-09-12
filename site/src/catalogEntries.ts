// GENERATED — 由 scripts/generate-shared.py 从 Packages/MeterKit/Sources/MeterProviders/ProviderCatalog.swift + Catalog/catalog.json 生成。
// 不要手改：改 Packages/MeterKit/Sources/MeterProviders/ProviderCatalog.swift + Catalog/catalog.json 后重跑生成器。

export type CatalogKind = "usage" | "prepaid" | "subscription" | "freeTier" | "planAndUsage";
export type CatalogStatus = "available" | "pendingVerification" | "declined";
export type CatalogMarketTier = 1 | 2 | 3 | 4;
export type LocalizedText = { zh: string; en: string; ja: string };

export type CatalogEntry = {
  key: string;
  name: string;
  kind: CatalogKind;
  status: CatalogStatus;
  inbox: boolean;
  costsMoneyToRefresh: boolean;
  supportsDailyGranularity: boolean;
  historyLookbackMonths: number;
  minimumRefreshInterval: number;
  marketTier: CatalogMarketTier;
  marketTierReason: string;
  searchKeywords: readonly string[];
  declineReason?: string;
  billingURL?: string;
  credentialSetupURL?: string;
  summary?: LocalizedText;
  verifyHint?: LocalizedText;
  fields: readonly {
    key: string;
    label: LocalizedText;
    isSecret: boolean;
    hint?: LocalizedText;
    validation?: LocalizedText;
  }[];
  steps: readonly LocalizedText[];
  troubleshooting: readonly {
    explanation: LocalizedText;
    nextStep: LocalizedText;
    httpStatus?: number;
  }[];
  plans: readonly { name: LocalizedText; amountUSD: string; period: string }[];
  notices: readonly LocalizedText[];
  guideURLs: readonly { id: string; url: string }[];
};

export const catalogEntries: readonly CatalogEntry[] = [
  {
    "key": "cloudflare",
    "name": "Cloudflare",
    "kind": "usage",
    "status": "available",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "网站反向代理近乎垄断，安全加边缘收入高速增长。",
    "searchKeywords": [
      "cf",
      "workers",
      "r2",
      "d1",
      "pages",
      "云"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Account ID",
          "en": "Account ID",
          "ja": "Account ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "在控制台右侧栏",
          "en": "In the dashboard sidebar",
          "ja": "ダッシュボードのサイドバーにあります"
        },
        "validation": {
          "zh": "Account ID 应该是 32 位十六进制",
          "en": "Account ID should be 32 hexadecimal characters",
          "ja": "Account ID は 32 桁の十六進数です"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Cloudflare 控制台的 API Tokens 页面，点 Create Token。",
        "en": "Open the API Tokens page in the Cloudflare dashboard, then tap Create Token.",
        "ja": "Cloudflare ダッシュボードの API Tokens ページを開き、Create Token をタップします。"
      },
      {
        "zh": "选 Custom token，只勾 Account · Billing · Read。Account Resources 选你的账户，其余留默认，然后复制 token。",
        "en": "Choose Custom token, and check only Account · Billing · Read. Under Account Resources pick your account, leave the rest as default, then copy the token.",
        "ja": "Custom token を選び、Account · Billing · Read だけにチェックを入れます。Account Resources で自分のアカウントを選び、ほかは初期値のまま、token をコピーします。"
      },
      {
        "zh": "请查阅 查找 Account ID",
        "en": "See Find account and zone IDs.",
        "ja": "アカウントとゾーンの ID の確認 を参照してください。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这个 token 无效，或者已经被撤销了。",
          "en": "This token is invalid, or it has already been revoked.",
          "ja": "この token は無効か、すでに取り消されています。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这个 token 缺 Billing:Read 权限，所以读不到账单。",
          "en": "This token is missing Billing:Read, so it can’t read billing.",
          "ja": "この token に Billing:Read がないため、請求を読めません。"
        },
        "nextStep": {
          "zh": "回上一步按 Custom token 重建，只勾 Account · Billing · Read。",
          "en": "Go back a step and recreate it as a Custom token with only Account · Billing · Read.",
          "ja": "前の手順に戻し、Custom token で作り直し、Account · Billing · Read だけをオンにしてください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [
      {
        "name": {
          "zh": "Workers Paid",
          "en": "Workers Paid",
          "ja": "Workers Paid"
        },
        "amountUSD": "5",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Workers for Platforms Paid",
          "en": "Workers for Platforms Paid",
          "ja": "Workers for Platforms Paid"
        },
        "amountUSD": "25",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "R2 Paid",
          "en": "R2 Paid",
          "ja": "R2 Paid"
        },
        "amountUSD": "0",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Pro（每个站点）",
          "en": "Pro (per site)",
          "ja": "Pro（サイトあたり）"
        },
        "amountUSD": "25",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Pro（年付·每个站点）",
          "en": "Pro (annual, per site)",
          "ja": "Pro（年払い・サイトあたり）"
        },
        "amountUSD": "240",
        "period": "annual"
      },
      {
        "name": {
          "zh": "Business（每个站点）",
          "en": "Business (per site)",
          "ja": "Business（サイトあたり）"
        },
        "amountUSD": "250",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Business（年付·每个站点）",
          "en": "Business (annual, per site)",
          "ja": "Business（年払い・サイトあたり）"
        },
        "amountUSD": "2400",
        "period": "annual"
      },
      {
        "name": {
          "zh": "Zero Trust（每席位）",
          "en": "Zero Trust (per seat)",
          "ja": "Zero Trust（席あたり）"
        },
        "amountUSD": "7",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Advanced Certificate Manager",
          "en": "Advanced Certificate Manager",
          "ja": "Advanced Certificate Manager"
        },
        "amountUSD": "10",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Load Balancing",
          "en": "Load Balancing",
          "ja": "Load Balancing"
        },
        "amountUSD": "5",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Argo Smart Routing",
          "en": "Argo Smart Routing",
          "ja": "Argo Smart Routing"
        },
        "amountUSD": "5",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Automatic Platform Optimization",
          "en": "Automatic Platform Optimization",
          "ja": "Automatic Platform Optimization"
        },
        "amountUSD": "5",
        "period": "monthly"
      }
    ],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://dash.cloudflare.com/?to=/:account/billing",
    "credentialSetupURL": "https://dash.cloudflare.com/profile/api-tokens",
    "summary": {
      "zh": "全球 CDN、DNS 和边缘计算。Workers、R2、D1 按用量月底结算。",
      "en": "Global CDN, DNS, and edge compute. Workers, R2, and D1 bill by usage at month-end.",
      "ja": "グローバルな CDN、DNS、エッジコンピューティング。Workers、R2、D1 は月末に従量課金です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和你 Cloudflare 后台看到的一致。不一致就先别保存，回上一步检查权限。",
      "en": "This number should match what you see in the Cloudflare dashboard. If it doesn’t, don’t save yet. Go back and check the permissions.",
      "ja": "この数字は Cloudflare の管理画面で見る金額と一致するはずです。違うなら、まだ保存せず、前の手順に戻って権限を確認してください。"
    }
  },
  {
    "key": "neon",
    "name": "Neon",
    "kind": "usage",
    "status": "available",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "无服务器 Postgres 的领先独立选手，被 Databricks 收购后并入 Lakebase，产品仍在加注。",
    "searchKeywords": [
      "postgres",
      "postgresql",
      "database",
      "数据库"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true,
        "validation": {
          "zh": "API Key 太短，确认复制完整",
          "en": "API Key is too short. Make sure you copied the whole thing.",
          "ja": "API Key が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Neon 控制台，进付账那个组织的 Settings，找到 API keys，点 Create new API key。需要组织管理员。",
        "en": "Open the Neon dashboard, go to Settings for the account you pay from, find API keys, and tap Create new API key. You need to be an organization admin.",
        "ja": "Neon ダッシュボードを開き、支払い中の組織の Settings に入り、API keys を見つけて Create new API key をタップします。組織の管理者が必要です。"
      },
      {
        "zh": "Key scope 选 Org-wide。填 Key name，创建后立刻复制。没有只读选项，这把是组织级管理员权限，能管项目、成员和账单。",
        "en": "Set Key scope to Org-wide. Fill in Key name, then copy it right away. There’s no read-only option — this is org-admin access. It can manage projects, members, and billing.",
        "ja": "Key scope は Org-wide。Key name を入れて、作成したらすぐにコピーします。読み取り専用はありません。これは組織の管理者権限で、プロジェクト・メンバー・請求を扱えます。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把 API key 无效，或者已经被撤销。",
          "en": "This API key is invalid, or it has already been revoked.",
          "ja": "この API key は無効か、すでに取り消されています。"
        },
        "nextStep": {
          "zh": "回组织 Settings 的 API keys 重新创建一把 Org-wide，创建后立刻复制。",
          "en": "Go back to API keys in the org Settings, create a new Org-wide key, and copy it right away.",
          "ja": "組織 Settings の API keys に戻って Org-wide を作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把钥匙读不到消费数据。多半是选了 Project-scoped，或者组织还在免费档。",
          "en": "These keys can’t read consumption. Usually you picked Project-scoped, or the org is still on the free tier.",
          "ja": "このキーでは消費データを読めません。たいてい Project-scoped を選んだか、組織がまだ無料枠です。"
        },
        "nextStep": {
          "zh": "用 Org-wide 重开一把。免费档没有 Consumption API，Launch 及以上才有。",
          "en": "Create a new Org-wide key. The free tier has no Consumption API. Launch and above do.",
          "ja": "Org-wide でもう一度作ってください。無料枠に Consumption API はなく、Launch 以上です。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [
      {
        "name": {
          "zh": "Neon Launch",
          "en": "Neon Launch",
          "ja": "Neon Launch"
        },
        "amountUSD": "19",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Neon Scale",
          "en": "Neon Scale",
          "ja": "Neon Scale"
        },
        "amountUSD": "69",
        "period": "monthly"
      }
    ],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://console.neon.tech/app/billing",
    "credentialSetupURL": "https://console.neon.tech/app/settings/api-keys",
    "summary": {
      "zh": "无服务器 Postgres。按计算和存储用量计。",
      "en": "Serverless Postgres. Billed on compute and storage usage.",
      "ja": "サーバーレス Postgres。計算とストレージの用量で課金します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和你 Neon Billing / Consumption 看到的一致。不一致先别保存。",
      "en": "This number should match what you see in Neon Billing / Consumption. If it doesn’t, don’t save yet.",
      "ja": "この数字は Neon Billing / Consumption の表示と一致するはずです。違うなら、まだ保存しないでください。"
    }
  },
  {
    "key": "aws",
    "name": "AWS",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": true,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "全球 IaaS 仍由 AWS、Azure、GCP 三分，AWS 份额虽缓降但仍是第一名。",
    "searchKeywords": [
      "amazon",
      "amazon web services",
      "s3",
      "ec2",
      "lambda",
      "bedrock",
      "亚马逊"
    ],
    "fields": [
      {
        "key": "accessKeyID",
        "label": {
          "zh": "Access Key ID",
          "en": "Access Key ID",
          "ja": "Access Key ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "长期密钥以 AKIA 开头",
          "en": "Long-term keys start with AKIA",
          "ja": "長期キーは AKIA で始まります"
        },
        "validation": {
          "zh": "Access Key ID 应该以 AKIA 开头",
          "en": "Access Key ID should start with AKIA",
          "ja": "Access Key ID は AKIA で始まる必要があります"
        }
      },
      {
        "key": "secretAccessKey",
        "label": {
          "zh": "Secret Access Key",
          "en": "Secret Access Key",
          "ja": "Secret Access Key"
        },
        "isSecret": true,
        "validation": {
          "zh": "Secret Access Key 太短，确认复制完整",
          "en": "Secret Access Key is too short. Make sure you copied the whole thing.",
          "ja": "Secret Access Key が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 IAM，单独建一个只给这个 App 用的用户。账户要先打开 Cost Explorer；每次刷新大约 $0.01，不会加入全局刷新。",
        "en": "Open IAM and create a user just for this app. Turn on Cost Explorer on the account first. Each fetch costs about $0.01, and it won’t join the global refresh.",
        "ja": "IAM を開き、この App 専用のユーザーを作ります。アカウントで先に Cost Explorer をオンにしてください。1 回の取得は約 $0.01 で、全体更新には入りません。"
      },
      {
        "zh": "给这个用户贴一段内联策略，只允许 ce:GetCostAndUsage。JSON 在下面，点复制。",
        "en": "Attach an inline policy to this user that only allows ce:GetCostAndUsage. The JSON is below — tap copy.",
        "ja": "このユーザーにインラインポリシーを貼り、ce:GetCostAndUsage だけ許可します。JSON は下にあります。コピーをタップしてください。"
      },
      {
        "zh": "给这个用户创建访问密钥，选「命令行」那种。Access Key ID 和 Secret 一起复制。",
        "en": "Create access keys for this user, pick the Command Line type, and copy the Access Key ID and Secret together.",
        "ja": "このユーザーにアクセスキーを作り、「コマンドライン」を選びます。Access Key ID と Secret を一緒にコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把访问密钥无效，或者已经被停用。",
          "en": "These access keys are invalid, or they’ve already been deactivated.",
          "ja": "このアクセスキーは無効か、すでに停止されています。"
        },
        "nextStep": {
          "zh": "回 IAM 停掉旧钥匙，给这个只读用户重新创建一对。创建后立刻复制 Secret。",
          "en": "Go back to IAM, disable the old keys, and create a new pair for this read-only user. Copy the Secret right away.",
          "ja": "IAM に戻り、古いキーを止めて、この読み取り専用ユーザーに新しいペアを作ってください。作成したらすぐに Secret をコピーします。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把钥匙没有 ce:GetCostAndUsage，或者账户还没打开 Cost Explorer。",
          "en": "These keys don’t have ce:GetCostAndUsage, or Cost Explorer isn’t turned on for the account.",
          "ja": "このキーに ce:GetCostAndUsage がないか、アカウントで Cost Explorer がまだオンではありません。"
        },
        "nextStep": {
          "zh": "把下面那段 JSON 贴成内联策略，并到 Billing → Cost Management 打开 Cost Explorer。",
          "en": "Paste the JSON below as an inline policy, and turn on Cost Explorer under Billing → Cost Management.",
          "ja": "下の JSON をインラインポリシーとして貼り、Billing → Cost Management で Cost Explorer をオンにしてください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [
      {
        "zh": "AWS Cost Explorer 每刷新一次大约 $0.01，不会加入全局刷新。",
        "en": "Each AWS Cost Explorer refresh costs about $0.01, and it won’t join the global refresh.",
        "ja": "AWS Cost Explorer の更新は 1 回およそ $0.01 で、全体更新には入りません。"
      }
    ],
    "guideURLs": [],
    "billingURL": "https://console.aws.amazon.com/costmanagement/home",
    "credentialSetupURL": "https://console.aws.amazon.com/iamv2/home#/users/create",
    "summary": {
      "zh": "云计算。账单从 Cost Explorer 拉，每次刷新大约 $0.01。",
      "en": "Cloud compute. Bills come from Cost Explorer. Each refresh costs about $0.01.",
      "ja": "クラウドコンピューティング。請求は Cost Explorer から取り、1 回の更新はおよそ $0.01 です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和你 AWS Cost Explorer 本月至今看到的一致。不一致先别保存，检查策略是不是只有 ce:GetCostAndUsage。",
      "en": "This number should match what you see in AWS Cost Explorer month-to-date. If it doesn’t, don’t save yet. Check that the policy only allows ce:GetCostAndUsage.",
      "ja": "この数字は AWS Cost Explorer の今月これまでの表示と一致するはずです。違うなら、まだ保存せず、ポリシーが ce:GetCostAndUsage だけか確認してください。"
    }
  },
  {
    "key": "openai",
    "name": "OpenAI",
    "kind": "prepaid",
    "status": "available",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "与 Anthropic、Google 三分企业 LLM 支出，消费端聊天仍过半，是前沿 API 寡头之一。",
    "searchKeywords": [
      "chatgpt",
      "gpt",
      "dall-e",
      "sora",
      "开放 AI"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "Admin Key",
          "en": "Admin Key",
          "ja": "Admin Key"
        },
        "isSecret": true,
        "hint": {
          "zh": "必须是 Admin Key，Read only 即可",
          "en": "It must be an Admin Key. Read only is enough.",
          "ja": "Admin Key である必要があります。Read only で足ります"
        },
        "validation": {
          "zh": "Admin Key 应该以 sk-admin- 开头",
          "en": "Admin Key should start with sk-admin-",
          "ja": "Admin Key は sk-admin- で始まる必要があります"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 OpenAI 的 Organization 设置，签发一把 Admin Key。权限选 Read only，不要 All。需要组织管理员，然后复制。",
        "en": "Open OpenAI’s Organization settings and issue an Admin Key. Set permission to Read only, not All. You need to be an organization admin, then copy it.",
        "ja": "OpenAI の Organization 設定を開き、Admin Key を発行します。権限は Read only で、All にはしないでください。組織の管理者が必要です。発行したらコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这个 Admin Key 无效。",
          "en": "This Admin Key is invalid.",
          "ja": "この Admin Key は無効です。"
        },
        "nextStep": {
          "zh": "回上一步，在 Organization 设置里重新签发 Admin Key。",
          "en": "Go back a step and issue a new Admin Key in Organization settings.",
          "ja": "前の手順に戻り、Organization 設定で Admin Key を発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 key 没有组织账单权限。",
          "en": "This key doesn’t have organization billing permission.",
          "ja": "この key に組織の請求権限がありません。"
        },
        "nextStep": {
          "zh": "回上一步重建一把 Admin Key，权限选 Read only。",
          "en": "Go back a step and recreate an Admin Key with Read only.",
          "ja": "前の手順に戻って Admin Key を作り直し、権限は Read only にしてください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [
      {
        "name": {
          "zh": "ChatGPT Plus",
          "en": "ChatGPT Plus",
          "ja": "ChatGPT Plus"
        },
        "amountUSD": "20",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "ChatGPT Pro 5×",
          "en": "ChatGPT Pro 5×",
          "ja": "ChatGPT Pro 5×"
        },
        "amountUSD": "100",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "ChatGPT Pro 20×",
          "en": "ChatGPT Pro 20×",
          "ja": "ChatGPT Pro 20×"
        },
        "amountUSD": "200",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "ChatGPT Business（每席位）",
          "en": "ChatGPT Business (per seat)",
          "ja": "ChatGPT Business（席あたり）"
        },
        "amountUSD": "25",
        "period": "monthly"
      }
    ],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://platform.openai.com/settings/organization/billing/overview",
    "credentialSetupURL": "https://platform.openai.com/settings/organization/admin-keys",
    "summary": {
      "zh": "GPT 等模型的 API 平台。预充值，按 token 扣余额。",
      "en": "An API platform for GPT and other models. Prepaid. Tokens debit the balance.",
      "ja": "GPT などのモデル API。プリペイドで、token で残高を引きます。"
    },
    "verifyHint": {
      "zh": "这个数字应该和你 OpenAI 组织后台 Usage / Costs 看到的一致。不一致先别保存，确认用的是 Admin Key。",
      "en": "This number should match Usage / Costs in the OpenAI organization dashboard. If it doesn’t, don’t save yet. Confirm you’re using an Admin Key.",
      "ja": "この数字は OpenAI 組織管理画面の Usage / Costs と一致するはずです。違うなら、まだ保存せず、Admin Key か確認してください。"
    }
  },
  {
    "key": "anthropic",
    "name": "Anthropic",
    "kind": "prepaid",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "企业 API 支出与编程场景的领先者，和 OpenAI、Google 构成支出寡头。",
    "searchKeywords": [
      "claude",
      "claude code",
      "sonnet",
      "opus",
      "克劳德"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "Admin API Key",
          "en": "Admin API Key",
          "ja": "Admin API Key"
        },
        "isSecret": true,
        "hint": {
          "zh": "必须是 Admin API Key，以 sk-ant- 开头",
          "en": "It must be an Admin API Key starting with sk-ant-",
          "ja": "Admin API Key で、sk-ant- で始まる必要があります"
        },
        "validation": {
          "zh": "Admin API Key 应该以 sk-ant- 开头",
          "en": "Admin API Key should start with sk-ant-",
          "ja": "Admin API Key は sk-ant- で始まる必要があります"
        }
      }
    ],
    "steps": [
      {
        "zh": "先确认 Console 里有 Organization。没有组织就改成手工录入。",
        "en": "Confirm there’s an Organization in Console. If there isn’t, switch to entering it by hand.",
        "ja": "先に Console に Organization があるか確認してください。なければ手入力に切り替えてください。"
      },
      {
        "zh": "打开 Admin API keys 页面，签发一把 Admin API Key 并复制。",
        "en": "Open the Admin API keys page, issue an Admin API Key, and copy it.",
        "ja": "Admin API keys ページを開き、Admin API Key を発行してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这个 Admin API Key 无效。",
          "en": "This Admin API Key is invalid.",
          "ja": "この Admin API Key は無効です。"
        },
        "nextStep": {
          "zh": "回 Admin API keys 重新签发。个人账号没有组织就改成手工录入 Claude 订阅。",
          "en": "Go back to Admin API keys and issue a new one. If a personal account has no organization, switch to entering the Claude subscription by hand.",
          "ja": "Admin API keys に戻って発行し直してください。個人アカウントに組織がなければ、Claude のサブスクリプションを手入力に切り替えてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 key 没有组织账单权限，或者你还没有 Organization。",
          "en": "This key doesn’t have organization billing permission, or you don’t have an Organization yet.",
          "ja": "この key に組織の請求権限がないか、まだ Organization がありません。"
        },
        "nextStep": {
          "zh": "先在 Console → Settings 建组织。建不了就改成手工录入订阅。",
          "en": "Create an organization in Console → Settings first. If you can’t, switch to entering the subscription by hand.",
          "ja": "先に Console → Settings で組織を作ってください。作れないなら、サブスクリプションを手入力に切り替えてください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [
      {
        "name": {
          "zh": "Claude Pro",
          "en": "Claude Pro",
          "ja": "Claude Pro"
        },
        "amountUSD": "20",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Claude Max 5×",
          "en": "Claude Max 5×",
          "ja": "Claude Max 5×"
        },
        "amountUSD": "100",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Claude Max 20×",
          "en": "Claude Max 20×",
          "ja": "Claude Max 20×"
        },
        "amountUSD": "200",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Claude Team（每席位）",
          "en": "Claude Team (per seat)",
          "ja": "Claude Team（席あたり）"
        },
        "amountUSD": "25",
        "period": "monthly"
      }
    ],
    "notices": [
      {
        "zh": "要先在 Console 建组织，再签发 Admin API Key。没有组织就改成手工录入订阅。",
        "en": "Create an organization in Console first, then issue an Admin API Key. If there’s no org, switch to entering the subscription by hand.",
        "ja": "先に Console で組織を作り、Admin API Key を発行してください。組織がなければサブスクリプションを手入力に切り替えてください。"
      }
    ],
    "guideURLs": [],
    "billingURL": "https://console.anthropic.com/settings/billing",
    "credentialSetupURL": "https://console.anthropic.com/settings/admin-keys",
    "summary": {
      "zh": "Claude。用组织账号的 Admin API Key。",
      "en": "Claude. Use an Admin API Key from an organization account.",
      "ja": "Claude。組織アカウントの Admin API Key を使います。"
    },
    "verifyHint": {
      "zh": "没有组织的个人账号会在这一步失败。失败就改成手工录入 Claude 订阅。",
      "en": "A personal account with no organization fails at this step. If it fails, switch to entering the Claude subscription by hand.",
      "ja": "組織のない個人アカウントはこの手順で失敗します。失敗したら Claude のサブスクリプションを手入力に切り替えてください。"
    }
  },
  {
    "key": "vercel",
    "name": "Vercel",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 11,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "前端/应用托管（尤其 Next.js）已由 Vercel 以数量级优势领跑，Netlify 等被拉开。",
    "searchKeywords": [
      "next",
      "nextjs",
      "next.js"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true,
        "validation": {
          "zh": "API Token 太短，确认复制完整",
          "en": "API Token is too short. Make sure you copied the whole thing.",
          "ja": "API Token が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Vercel 的 Account Tokens 页面，点 Create。Expiration 选不会过期的那一档。",
        "en": "Open Vercel’s Account Tokens page and tap Create. Set Expiration so the token does not expire.",
        "ja": "Vercel の Account Tokens ページを開き、Create をタップします。Expiration は期限なしにします。"
      },
      {
        "zh": "SCOPE 选你付账的那个团队，不要再点进某个项目。没有只读选项，这把能管部署和项目。创建后立刻复制。",
        "en": "Set SCOPE to the team you pay from. Don’t drill into a project. There’s no read-only option — this token can deploy and manage projects. Copy it right away.",
        "ja": "SCOPE は支払い中のチームにし、プロジェクトまで掘らないでください。読み取り専用はありません。この token はデプロイとプロジェクトを扱えます。作成したらすぐにコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这个 token 无效，或者已经被撤销。",
          "en": "This token is invalid, or it has already been revoked.",
          "ja": "この token は無効か、すでに取り消されています。"
        },
        "nextStep": {
          "zh": "回 Account Tokens 重新创建，创建后立刻复制。",
          "en": "Go back to Account Tokens, create a new one, and copy it right away.",
          "ja": "Account Tokens に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这个 token 看不到账单。多半是 SCOPE 点进了某个项目，或选错了团队。",
          "en": "This token can’t see billing. Usually SCOPE drilled into a project, or the wrong team was selected.",
          "ja": "この token では請求が見えません。たいてい SCOPE でプロジェクトまで掘ったか、チームを間違えています。"
        },
        "nextStep": {
          "zh": "确认 SCOPE 停在付账的那个团队，没有点进项目。",
          "en": "Confirm SCOPE stays on the team you pay from, and didn’t drill into a project.",
          "ja": "SCOPE が支払い中のチームで止まっていて、プロジェクトまで入っていないか確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [
      {
        "name": {
          "zh": "Vercel Pro（每席位）",
          "en": "Vercel Pro (per seat)",
          "ja": "Vercel Pro（席あたり）"
        },
        "amountUSD": "20",
        "period": "monthly"
      }
    ],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://vercel.com/account/billing",
    "credentialSetupURL": "https://vercel.com/account/tokens",
    "summary": {
      "zh": "前端部署。按本月已开账单计。Hobby 没有发票，读数是 $0。",
      "en": "Frontend hosting. Billed from this month’s charges. Hobby has no invoice, so the reading is $0.",
      "ja": "フロントエンドのデプロイ。今月の請求で数えます。Hobby に請求書はなく、読み取りは $0 です。"
    },
    "verifyHint": {
      "zh": "付费团队这个数字应该和 Vercel Billing 一致。Hobby 没有发票，会显示 $0。",
      "en": "On a paid team this number should match Vercel Billing. Hobby has no invoice, so it shows $0.",
      "ja": "有料チームではこの数字は Vercel Billing と一致するはずです。Hobby に請求書はなく、$0 と出ます。"
    }
  },
  {
    "key": "github",
    "name": "GitHub",
    "kind": "planAndUsage",
    "status": "available",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "代码托管已成事实标准，Actions 与 Copilot 把 CI 和 AI 一并锁进同一平台。",
    "searchKeywords": [
      "copilot",
      "actions",
      "gh",
      "微软"
    ],
    "fields": [
      {
        "key": "personalAccessToken",
        "label": {
          "zh": "Personal Access Token",
          "en": "Personal Access Token",
          "ja": "Personal Access Token"
        },
        "isSecret": true,
        "hint": {
          "zh": "Fine-grained token，以 github_pat_ 开头",
          "en": "Fine-grained token, starting with github_pat_",
          "ja": "Fine-grained token。github_pat_ で始まります"
        },
        "validation": {
          "zh": "请用 Fine-grained token（github_pat_ 开头）",
          "en": "Use a Fine-grained token (starts with github_pat_)",
          "ja": "Fine-grained token（github_pat_ で始まる）を使ってください"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 GitHub 的 Fine-grained personal access tokens 创建页。Resource owner 选你自己，Expiration 选 No expiration，Repository access 选 Public repositories，Account permissions 把 Plan 开成 Read-only。创建后复制，token 以 github_pat_ 开头。",
        "en": "Open GitHub’s Fine-grained personal access tokens page. Set Resource owner to yourself, Expiration to No expiration, Repository access to Public repositories, and Plan under Account permissions to Read-only. Copy it after creating. The token starts with github_pat_.",
        "ja": "GitHub の Fine-grained personal access tokens の作成ページを開きます。Resource owner は自分、Expiration は No expiration、Repository access は Public repositories、Account permissions の Plan は Read-only。作成したらコピーします。token は github_pat_ で始まります。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这个 token 无效，过期，或者已经被撤销。",
          "en": "This token is invalid, expired, or has already been revoked.",
          "ja": "この token は無効か、期限切れか、すでに取り消されています。"
        },
        "nextStep": {
          "zh": "回 Fine-grained tokens 重新创建一把，创建后立刻复制。",
          "en": "Go back to Fine-grained tokens, create a new one, and copy it right away.",
          "ja": "Fine-grained tokens に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这个 token 没有 Plan 权限，所以读不到账单。",
          "en": "This token doesn’t have Plan permission, so it can’t read billing.",
          "ja": "この token に Plan 権限がないため、請求を読めません。"
        },
        "nextStep": {
          "zh": "编辑 token，Account permissions 把 Plan 开成 Read-only。",
          "en": "Edit the token and set Plan under Account permissions to Read-only.",
          "ja": "token を編集し、Account permissions の Plan を Read-only にしてください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [
      {
        "name": {
          "zh": "GitHub Copilot Pro",
          "en": "GitHub Copilot Pro",
          "ja": "GitHub Copilot Pro"
        },
        "amountUSD": "10",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "GitHub Copilot Pro+",
          "en": "GitHub Copilot Pro+",
          "ja": "GitHub Copilot Pro+"
        },
        "amountUSD": "39",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "GitHub Copilot Business（每席位）",
          "en": "GitHub Copilot Business (per seat)",
          "ja": "GitHub Copilot Business（席あたり）"
        },
        "amountUSD": "19",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "GitHub Team（每席位）",
          "en": "GitHub Team (per seat)",
          "ja": "GitHub Team（席あたり）"
        },
        "amountUSD": "4",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "GitHub Enterprise（每席位）",
          "en": "GitHub Enterprise (per seat)",
          "ja": "GitHub Enterprise（席あたり）"
        },
        "amountUSD": "21",
        "period": "monthly"
      }
    ],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://github.com/settings/billing",
    "credentialSetupURL": "https://github.com/settings/personal-access-tokens/new?expires_in=none&plan=read",
    "summary": {
      "zh": "代码托管。这里只统计你自己付的 Actions 分钟和 Copilot。",
      "en": "Code hosting. This only counts Actions minutes and Copilot that you pay for yourself.",
      "ja": "コードホスティング。自分で払っている Actions 分と Copilot だけを数えます。"
    },
    "verifyHint": {
      "zh": "用户级账单只覆盖 Actions 分钟和你自己买的 Copilot。组织代付的 Copilot 不会出现在这里。",
      "en": "User-level billing only covers Actions minutes and Copilot you bought yourself. Copilot paid by the org won’t show up here.",
      "ja": "ユーザー請求は Actions 分と自分で買った Copilot だけです。組織が払う Copilot はここに出ません。"
    }
  },
  {
    "key": "fly",
    "name": "Fly.io",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": true,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "全球边缘/Machines 仍是 Render/Railway 并列短名单，虽停 GPU 但宿主平台还在加注。",
    "searchKeywords": [
      "fly.io",
      "flyio",
      "machines"
    ],
    "fields": [],
    "steps": [
      {
        "zh": "Fly.io 没有公开的账单接口。下一步会给你一段任务书，粘给 Claude Code、Cursor 或任何能上网的 AI 写抓取脚本。本月花费以控制台 Billing 页为准。",
        "en": "Fly.io has no public billing API. Next you’ll get a brief. Paste it into Claude Code, Cursor, or any AI that can reach the web, and have it write a scrape script. Treat the dashboard Billing page as the source for this month.",
        "ja": "Fly.io に公開の請求 API はありません。次の画面で依頼文を出します。Claude Code、Cursor、またはネットに出られる AI に貼って、取得スクリプトを書いてもらってください。今月の金額はダッシュボードの Billing ページを正とします。"
      },
      {
        "zh": "投递 key 单独给你，放进脚本的环境变量。脚本每天跑一次，同一个月重复上报是覆盖。",
        "en": "The ingest key is yours alone. Put it in the script’s environment variables. Run the script once a day. Sending the same month again overwrites.",
        "ja": "投函キーはあなた専用です。スクリプトの環境変数に入れてください。スクリプトは 1 日 1 回。同じ月を再送すると上書きです。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "投递 key 已经被吊销了。",
          "en": "The ingest key has been revoked.",
          "ja": "投函キーはすでに取り消されています。"
        },
        "nextStep": {
          "zh": "去设置 → 读数信箱里再签一把，然后更新你的脚本。",
          "en": "Go to Settings → Inbox and issue a new one, then update your script.",
          "ja": "設定 → 検針ポストで発行し直し、スクリプトを更新してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "投递太频繁了。",
          "en": "You’re delivering too often.",
          "ja": "投函が頻繁すぎます。"
        },
        "nextStep": {
          "zh": "每天跑一次就够。",
          "en": "Once a day is enough.",
          "ja": "1 日 1 回で足ります。"
        },
        "httpStatus": 429
      }
    ],
    "plans": [
      {
        "name": {
          "zh": "Fly.io Launch",
          "en": "Fly.io Launch",
          "ja": "Fly.io Launch"
        },
        "amountUSD": "29",
        "period": "monthly"
      }
    ],
    "notices": [
      {
        "zh": "Fly.io 的 GraphQL 没有本月花费字段。这家走读数信箱：你自己从 Billing 页把数字投递进来，App 只负责取回。",
        "en": "Fly.io GraphQL has no field for this month’s spend. This one uses the inbox: you fetch from the Billing page and deliver it; the app only reads it back.",
        "ja": "Fly.io の GraphQL に今月の支出フィールドはありません。このサービスは検針ポストです。Billing ページから自分で取って投函し、App は受け取るだけです。"
      }
    ],
    "guideURLs": [],
    "billingURL": "https://fly.io/dashboard/personal/billing",
    "credentialSetupURL": "https://fly.io/dashboard/personal/tokens",
    "summary": {
      "zh": "容器托管。没有公开账单接口，走读数信箱。",
      "en": "Container hosting. There’s no public billing API, so it uses the inbox.",
      "ja": "コンテナホスティング。公開の請求 API はないので、検針ポストを使います。"
    },
    "verifyHint": {
      "zh": "接入之后先显示「等待投递」。脚本第一次上报之后数字才会出来。",
      "en": "After connecting, it first shows Waiting for delivery. The number appears after the script reports once.",
      "ja": "接続した直後は「投函待ち」です。スクリプトが一度報告してから数字が出ます。"
    }
  },
  {
    "key": "openrouter",
    "name": "OpenRouter",
    "kind": "prepaid",
    "status": "available",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "独立多模型路由的事实标准，流量与收购估值都远超其他聚合器。",
    "searchKeywords": [
      "open router",
      "or",
      "聚合"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "Management Key",
          "en": "Management Key",
          "ja": "Management Key"
        },
        "isSecret": true,
        "hint": {
          "zh": "必须是 Management key，普通推理 key 读不到余额",
          "en": "It must be a Management key. A regular inference key can’t read the balance.",
          "ja": "Management key である必要があります。通常の推論 key では残高を読めません"
        },
        "validation": {
          "zh": "Key 太短，确认复制完整",
          "en": "Key is too short. Make sure you copied the whole thing.",
          "ja": "Key が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 OpenRouter 的 API Keys 页面，创建一把 Management key 并复制。",
        "en": "Open OpenRouter’s API Keys page, create a Management key, and copy it.",
        "ja": "OpenRouter の API Keys ページを開き、Management key を作ってコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把 key 无效。",
          "en": "This key is invalid.",
          "ja": "この key は無効です。"
        },
        "nextStep": {
          "zh": "回 API Keys 重新签发 Management key。",
          "en": "Go back to API Keys and issue a new Management key.",
          "ja": "API Keys に戻って Management key を発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "普通推理 key 读不到余额。",
          "en": "A regular inference key can’t read the balance.",
          "ja": "通常の推論 key では残高を読めません。"
        },
        "nextStep": {
          "zh": "换成 Management key 再测。",
          "en": "Switch to a Management key and test again.",
          "ja": "Management key に替えて再テストしてください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://openrouter.ai/settings/credits",
    "credentialSetupURL": "https://openrouter.ai/settings/keys",
    "summary": {
      "zh": "多家模型的聚合网关。预充值积分。",
      "en": "A gateway that aggregates many models. Prepaid credits.",
      "ja": "複数モデルの集約ゲートウェイ。プリペイドのポイントです。"
    },
    "verifyHint": {
      "zh": "这个余额应该和 OpenRouter Credits 页看到的一致。不一致先别保存，确认用的是 Management key。",
      "en": "This balance should match the OpenRouter Credits page. If it doesn’t, don’t save yet. Confirm you’re using a Management key.",
      "ja": "この残高は OpenRouter Credits ページと一致するはずです。違うなら、まだ保存せず、Management key か確認してください。"
    }
  },
  {
    "key": "deepseek",
    "name": "DeepSeek",
    "kind": "prepaid",
    "status": "available",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "公共网关 token 量与 OpenAI 并列第一梯队，是全球廉价前沿 API 的默认选项。",
    "searchKeywords": [
      "深度求索",
      "ds"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true,
        "validation": {
          "zh": "Key 太短，确认复制完整",
          "en": "Key is too short. Make sure you copied the whole thing.",
          "ja": "Key が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 DeepSeek Platform 的 API keys 页面，创建一把 key 并复制。",
        "en": "Open the API keys page on DeepSeek Platform, create a key, and copy it.",
        "ja": "DeepSeek Platform の API keys ページを開き、key を作ってコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把 key 无效。",
          "en": "This key is invalid.",
          "ja": "この key は無効です。"
        },
        "nextStep": {
          "zh": "回 API keys 重新签发。",
          "en": "Go back to API keys and issue a new one.",
          "ja": "API keys に戻って発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账户余额的币种不在汇率表里，没法折成美元。",
          "en": "The account balance’s currency isn’t in the rate table, so it can’t convert to USD.",
          "ja": "口座残高の通貨が為替表にないため、ドルに換算できません。"
        },
        "nextStep": {
          "zh": "换 USD 账户，或把花费记成手工订阅。",
          "en": "Switch to a USD account, or record the spend as a manual subscription.",
          "ja": "USD アカウントに替えるか、支出を手動サブスクリプションにしてください。"
        },
        "httpStatus": 200
      }
    ],
    "plans": [],
    "notices": [
      {
        "zh": "DeepSeek 国内户余额是人民币。按目录汇率折成美元计入总额；同时有美元余额时用美元。",
        "en": "A DeepSeek China account balance is in CNY. The catalog rate converts it to USD for the total. If a USD balance exists too, that USD is used.",
        "ja": "DeepSeek 国内口座の残高は人民元です。ディレクトリの為替でドルにして合計します。ドル残高もあるときはドルを使います。"
      }
    ],
    "guideURLs": [],
    "billingURL": "https://platform.deepseek.com/top_up",
    "credentialSetupURL": "https://platform.deepseek.com/api_keys",
    "summary": {
      "zh": "深度求索的 API。预充值，人民币户会折成美元。",
      "en": "DeepSeek’s API. Prepaid. A CNY account converts to USD.",
      "ja": "DeepSeek の API。プリペイドで、人民元口座はドルに換算します。"
    },
    "verifyHint": {
      "zh": "两个钱包都会列出。合计按目录汇率折成美元，应和充值页两边加起来一致。",
      "en": "Both wallets are listed. The total converts to USD at the catalog rate, and should match the two sides added up on the top-up page.",
      "ja": "両方のウォレットを出します。合計はディレクトリの為替でドルにし、チャージページの両側を足した額と一致するはずです。"
    }
  },
  {
    "key": "moonshot",
    "name": "Moonshot (China)",
    "kind": "prepaid",
    "status": "available",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "Kimi 在质量与溢价支出上是中国头部挑战者，商业化与港股冲刺并行。",
    "searchKeywords": [
      "kimi",
      "moonshot",
      "kimi.ai",
      "国内",
      "月之暗面",
      "china"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true,
        "validation": {
          "zh": "Key 太短，确认复制完整",
          "en": "Key is too short. Make sure you copied the whole thing.",
          "ja": "Key が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Moonshot (China) 的 API 密钥页面，签发一把 key 并复制。国际站请加 Moonshot (Overseas)。",
        "en": "Open the API keys page for Moonshot (China), issue a key, and copy it. For the overseas site, add Moonshot (Overseas).",
        "ja": "Moonshot (China) の API キーのページを開き、key を発行してコピーします。国際サイトは Moonshot (Overseas) を追加してください。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把 key 无效，或用了另一站的 key。",
          "en": "This key is invalid, or it’s from the other site.",
          "ja": "この key は無効か、別サイトの key です。"
        },
        "nextStep": {
          "zh": "确认 key 来自 platform.kimi.com。国际站的 key 去加 Moonshot (Overseas)。",
          "en": "Confirm the key is from platform.kimi.com. An overseas key belongs on Moonshot (Overseas).",
          "ja": "key が platform.kimi.com のものか確認してください。国際サイトの key は Moonshot (Overseas) に追加します。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "官方余额的币种不在汇率表里，没法折成美元。",
          "en": "The official balance’s currency isn’t in the rate table, so it can’t convert to USD.",
          "ja": "公式残高の通貨が為替表にないため、ドルに換算できません。"
        },
        "nextStep": {
          "zh": "改成手工录入本月花费。",
          "en": "Switch to entering this month’s spend by hand.",
          "ja": "今月の支出を手入力に切り替えてください。"
        },
        "httpStatus": 200
      }
    ],
    "plans": [],
    "notices": [
      {
        "zh": "Moonshot (China) 国内站余额是人民币。按目录汇率折成美元计入总额，详情页能看到原值。",
        "en": "Moonshot (China) balances are in CNY. The catalog rate converts them to USD for the total. The detail page still shows the original amount.",
        "ja": "Moonshot (China) 国内サイトの残高は人民元です。ディレクトリの為替でドルにして合計し、詳細では原通貨も見えます。"
      }
    ],
    "guideURLs": [],
    "billingURL": "https://platform.kimi.com/console/pay",
    "credentialSetupURL": "https://platform.kimi.com/console/api-keys",
    "summary": {
      "zh": "Moonshot 国内站（Kimi API）。预充值，人民币余额会折成美元。",
      "en": "Moonshot China (Kimi API). Prepaid. A CNY balance is converted to USD.",
      "ja": "Moonshot 国内サイト（Kimi API）。プリペイドで、人民元残高はドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个余额应该和 Moonshot (China) 充值页看到的人民币余额对得上。App 里按汇率折成美元显示。",
      "en": "This balance should match the CNY balance on the Moonshot (China) top-up page. The app converts it to USD at the catalog rate.",
      "ja": "この残高は Moonshot (China) のチャージページの人民元残高と一致するはずです。App では為替でドル表示します。"
    }
  },
  {
    "key": "moonshotai",
    "name": "Moonshot (Overseas)",
    "kind": "prepaid",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "与国内月之暗面同一公司的海外 API，质量与溢价定位同属中国头部挑战者。",
    "searchKeywords": [
      "kimi",
      "moonshot ai",
      "moonshot.ai",
      "海外",
      "国际",
      "oversea",
      "overseas"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true,
        "validation": {
          "zh": "Key 太短，确认复制完整",
          "en": "Key is too short. Make sure you copied the whole thing.",
          "ja": "Key が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Moonshot (Overseas) 的 API keys 页面，签发一把 key 并复制。国内站请加 Moonshot (China)。",
        "en": "Open the API keys page for Moonshot (Overseas), issue a key, and copy it. For the China site, add Moonshot (China).",
        "ja": "Moonshot (Overseas) の API keys ページを開き、key を発行してコピーします。国内サイトは Moonshot (China) を追加してください。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把 key 无效，或用了国内站的 key。",
          "en": "This key is invalid, or it’s a China-site key.",
          "ja": "この key は無効か、国内サイトの key です。"
        },
        "nextStep": {
          "zh": "确认 key 来自 platform.moonshot.ai。国内站的 key 去加 Moonshot (China)。",
          "en": "Confirm the key is from platform.moonshot.ai. A China-site key belongs on Moonshot (China).",
          "ja": "key が platform.moonshot.ai のものか確認してください。国内サイトの key は Moonshot (China) に追加します。"
        },
        "httpStatus": 401
      }
    ],
    "plans": [],
    "notices": [
      {
        "zh": "Moonshot (Overseas) 是国际站，余额是美元。国内站请加 Moonshot (China)。",
        "en": "Moonshot (Overseas) is the international site, with a USD balance. For the China site, add Moonshot (China).",
        "ja": "Moonshot (Overseas) は国際サイトで、残高はドルです。国内サイトは Moonshot (China) を追加してください。"
      }
    ],
    "guideURLs": [],
    "billingURL": "https://platform.moonshot.ai/console/pay",
    "credentialSetupURL": "https://platform.moonshot.ai/console/api-keys",
    "summary": {
      "zh": "Moonshot 国际站。预充值，美元余额。",
      "en": "Moonshot overseas. Prepaid, with a USD balance.",
      "ja": "Moonshot 国際サイト。プリペイドで、残高はドルです。"
    },
    "verifyHint": {
      "zh": "这个余额应该和 Moonshot (Overseas) 充值页看到的美元余额对得上。",
      "en": "This balance should match the USD balance on the Moonshot (Overseas) top-up page.",
      "ja": "この残高は Moonshot (Overseas) のチャージページのドル残高と一致するはずです。"
    }
  },
  {
    "key": "xai",
    "name": "xAI",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "Grok 消费端与算力规模已是强挑战者，但公共 API 份额仍远低于三巨头与 DeepSeek。",
    "searchKeywords": [
      "grok",
      "x.ai",
      "spacexai",
      "supergrok",
      "grok.com"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "Management API Key",
          "en": "Management API Key",
          "ja": "Management API Key"
        },
        "isSecret": true,
        "hint": {
          "zh": "Management API Key",
          "en": "Management API Key",
          "ja": "Management API Key"
        },
        "validation": {
          "zh": "Key 太短，确认复制完整",
          "en": "Key is too short. Make sure you copied the whole thing.",
          "ja": "Key が短すぎます。全部コピーできているか確認してください。"
        }
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Team ID",
          "en": "Team ID",
          "ja": "Team ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台 URL 里 /team/ 后面那串",
          "en": "The segment after /team/ in the dashboard URL",
          "ja": "ダッシュボード URL の /team/ の後ろ"
        },
        "validation": {
          "zh": "Team ID 太短，从控制台地址栏复制完整 UUID",
          "en": "Team ID is too short. Copy the full UUID from the dashboard address bar.",
          "ja": "Team ID が短すぎます。ダッシュボードのアドレスバーから UUID を全部コピーしてください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 xAI Console 的 API Keys，创建一把 Management API Key 并复制。",
        "en": "Open API Keys in the xAI Console, create a Management API Key, and copy it.",
        "ja": "xAI Console の API Keys を開き、Management API Key を作ってコピーします。"
      },
      {
        "zh": "还需要 Team ID。在控制台地址栏 /team/ 后面那一串，default 团队也有一个 UUID。",
        "en": "You also need a Team ID. It’s the segment after /team/ in the dashboard address bar. The default team has a UUID too.",
        "ja": "Team ID も必要です。ダッシュボードのアドレスバー /team/ の後ろです。default チームにも UUID があります。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这个 Management API Key 无效。",
          "en": "This Management API Key is invalid.",
          "ja": "この Management API Key は無効です。"
        },
        "nextStep": {
          "zh": "回 Console 重新签发 Management key。",
          "en": "Go back to Console and issue a new Management key.",
          "ja": "Console に戻って Management key を発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 key 读不到这个 Team 的账单。",
          "en": "This key can’t read billing for this Team.",
          "ja": "この key ではこの Team の請求を読めません。"
        },
        "nextStep": {
          "zh": "确认 Team ID 和 key 属于同一个团队。",
          "en": "Confirm the Team ID and key belong to the same team.",
          "ja": "Team ID と key が同じチームか確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [
      {
        "name": {
          "zh": "SuperGrok Lite",
          "en": "SuperGrok Lite",
          "ja": "SuperGrok Lite"
        },
        "amountUSD": "10",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "SuperGrok",
          "en": "SuperGrok",
          "ja": "SuperGrok"
        },
        "amountUSD": "30",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "SuperGrok（年付）",
          "en": "SuperGrok (annual)",
          "ja": "SuperGrok（年払い）"
        },
        "amountUSD": "300",
        "period": "annual"
      },
      {
        "name": {
          "zh": "SuperGrok Plus",
          "en": "SuperGrok Plus",
          "ja": "SuperGrok Plus"
        },
        "amountUSD": "100",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "SuperGrok Heavy",
          "en": "SuperGrok Heavy",
          "ja": "SuperGrok Heavy"
        },
        "amountUSD": "300",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Grok Business（每席位）",
          "en": "Grok Business (per seat)",
          "ja": "Grok Business（席あたり）"
        },
        "amountUSD": "30",
        "period": "monthly"
      }
    ],
    "notices": [
      {
        "zh": "xAI 要 Management API Key 和 Team ID。SuperGrok 月费是另一笔账单，记成这家的固定订阅。",
        "en": "xAI needs a Management API Key and a Team ID. The SuperGrok monthly fee is a separate bill — record it as a fixed subscription on this provider.",
        "ja": "xAI は Management API Key と Team ID が必要です。SuperGrok の月額は別請求なので、このサービスの固定サブスクリプションにします。"
      }
    ],
    "guideURLs": [],
    "billingURL": "https://console.x.ai/team/default/billing",
    "credentialSetupURL": "https://console.x.ai/team/default/api-keys",
    "summary": {
      "zh": "Grok 的 API。预充值 credits。",
      "en": "Grok’s API. Prepaid credits.",
      "ja": "Grok の API。プリペイド credits です。"
    },
    "verifyHint": {
      "zh": "这个余额应该和 xAI Billing 页的 prepaid credits 一致。",
      "en": "This balance should match prepaid credits on the xAI Billing page.",
      "ja": "この残高は xAI Billing ページの prepaid credits と一致するはずです。"
    }
  },
  {
    "key": "cursor",
    "name": "Cursor",
    "kind": "subscription",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "独立 AI IDE 的绝对龙头，收入与企业采购占有率碾压 Windsurf 等同类。",
    "searchKeywords": [
      "cursor ai",
      "cursor.sh",
      "anysphere",
      "ide",
      "编辑器"
    ],
    "fields": [],
    "steps": [
      {
        "zh": "Cursor 没有公开的账单接口。套餐月费在详情里加固定订阅。本月超额用量可以手填。",
        "en": "Cursor has no public billing API. Add the plan fee as a fixed subscription on the detail page. You can type this month’s overage by hand.",
        "ja": "Cursor に公開の請求 API はありません。プラン月額は詳細で固定サブスクリプションにします。今月の超過分は手入力できます。"
      }
    ],
    "troubleshooting": [],
    "plans": [
      {
        "name": {
          "zh": "Pro",
          "en": "Pro",
          "ja": "Pro"
        },
        "amountUSD": "20",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Pro+",
          "en": "Pro+",
          "ja": "Pro+"
        },
        "amountUSD": "60",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Ultra",
          "en": "Ultra",
          "ja": "Ultra"
        },
        "amountUSD": "200",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Teams Standard（每席位）",
          "en": "Teams Standard (per seat)",
          "ja": "Teams Standard（席あたり）"
        },
        "amountUSD": "40",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Teams Premium（每席位）",
          "en": "Teams Premium (per seat)",
          "ja": "Teams Premium（席あたり）"
        },
        "amountUSD": "120",
        "period": "monthly"
      }
    ],
    "notices": [
      {
        "zh": "Cursor 没有公开账单接口。套餐记成固定订阅，超额用量可以手填。",
        "en": "Cursor has no public billing API. Record the plan as a fixed subscription. You can type overage by hand.",
        "ja": "Cursor に公開の請求 API はありません。プランは固定サブスクリプション、超過分は手入力できます。"
      }
    ],
    "guideURLs": [],
    "billingURL": "https://cursor.com/dashboard/billing",
    "credentialSetupURL": "https://cursor.com/docs/models-and-pricing",
    "summary": {
      "zh": "AI 编程编辑器。没有公开账单接口，月费记成固定订阅。",
      "en": "An AI code editor. There’s no public billing API, so the monthly plan is a fixed subscription.",
      "ja": "AI コードエディタ。公開の請求 API はないので、月額は固定サブスクリプションとして記録します。"
    },
    "verifyHint": {
      "zh": "不能自动取账单。数字以你录的套餐和手填超额为准。",
      "en": "There’s no auto-fetch. The number is the plan you recorded plus overage you typed.",
      "ja": "自動取得はありません。数字は入力したプランと手入力の超過が正です。"
    }
  },
  {
    "key": "digitalocean",
    "name": "DigitalOcean",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "独立开发者云/VPS 的首选替代，收入已破十亿美元量级且 AI 客户在加速。",
    "searchKeywords": [
      "do",
      "droplet",
      "数字海洋"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true,
        "hint": {
          "zh": "通常以 dop_v1_ 开头",
          "en": "Usually starts with dop_v1_",
          "ja": "たいてい dop_v1_ で始まります"
        },
        "validation": {
          "zh": "个人 token 应该以 dop_v1_ 开头",
          "en": "A personal token should start with dop_v1_",
          "ja": "個人 token は dop_v1_ で始まる必要があります"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 DigitalOcean 的 API Tokens 页面，点 Generate New Token。Custom scope 只勾 billing:read，然后复制 token。",
        "en": "Open DigitalOcean’s API Tokens page and tap Generate New Token. Under Custom scope, check only billing:read, then copy the token.",
        "ja": "DigitalOcean の API Tokens ページを開き、Generate New Token をタップします。Custom scope は billing:read だけにチェックを入れ、token をコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这个 token 无效或已撤销。",
          "en": "This token is invalid or has been revoked.",
          "ja": "この token は無効か、すでに取り消されています。"
        },
        "nextStep": {
          "zh": "回 API Tokens 重新签发，创建后立刻复制。",
          "en": "Go back to API Tokens, issue a new one, and copy it right away.",
          "ja": "API Tokens に戻って発行し直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这个 token 没有 billing:read。",
          "en": "This token doesn’t have billing:read.",
          "ja": "この token に billing:read がありません。"
        },
        "nextStep": {
          "zh": "重建一把，只勾 billing:read。",
          "en": "Recreate one with only billing:read checked.",
          "ja": "billing:read だけにチェックしたものを作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://cloud.digitalocean.com/account/billing",
    "credentialSetupURL": "https://cloud.digitalocean.com/account/api/tokens",
    "summary": {
      "zh": "云主机、托管数据库和 App Platform。按本月至今已花。",
      "en": "Droplets, managed databases, and App Platform. This is month-to-date usage.",
      "ja": "クラウドホスト、マネージドデータベース、App Platform。今月これまでの使用額です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 Billing 页的 Month-to-date usage 一致。",
      "en": "This number should match Month-to-date usage on the Billing page.",
      "ja": "この数字は Billing ページの Month-to-date usage と一致するはずです。"
    }
  },
  {
    "key": "twilio",
    "name": "Twilio",
    "kind": "usage",
    "status": "available",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "全球 CPaaS 收入份额第一，与 Infobip、Sinch 构成寡头。",
    "searchKeywords": [
      "sms",
      "whatsapp",
      "语音"
    ],
    "fields": [
      {
        "key": "accountID",
        "label": {
          "zh": "Account SID",
          "en": "Account SID",
          "ja": "Account SID"
        },
        "isSecret": false,
        "validation": {
          "zh": "Account SID 应该是 AC 开头的 34 位十六进制",
          "en": "Account SID should be 34 hexadecimal characters starting with AC",
          "ja": "Account SID は AC で始まる 34 桁の十六進数です"
        }
      },
      {
        "key": "accessKeyID",
        "label": {
          "zh": "API Key SID",
          "en": "API Key SID",
          "ja": "API Key SID"
        },
        "isSecret": false,
        "hint": {
          "zh": "SK 开头",
          "en": "starts with SK",
          "ja": "SK で始まる"
        },
        "validation": {
          "zh": "API Key SID 应该是 SK 开头的 34 位",
          "en": "API Key SID should be 34 characters starting with SK",
          "ja": "API Key SID は SK で始まる 34 文字です"
        }
      },
      {
        "key": "apiToken",
        "label": {
          "zh": "API Key Secret",
          "en": "API Key Secret",
          "ja": "API Key Secret"
        },
        "isSecret": true,
        "hint": {
          "zh": "只显示一次",
          "en": "shown only once",
          "ja": "一度しか表示されない"
        },
        "validation": {
          "zh": "Secret 太短，确认复制完整",
          "en": "Secret is too short. Make sure you copied the whole thing.",
          "ja": "Secret が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Twilio Console 的 Account settings，复制 Account SID。",
        "en": "Open Account settings in the Twilio Console and copy the Account SID.",
        "ja": "Twilio Console の Account settings を開き、Account SID をコピーします。"
      },
      {
        "zh": "打开 API keys & auth tokens，区域留在 United States (US1)，点 Create API key。类型选 Restricted。",
        "en": "Open API keys & auth tokens, keep the region on United States (US1), and tap Create API key. Set the type to Restricted.",
        "ja": "API keys & auth tokens を開き、リージョンは United States (US1) のまま、Create API key をタップします。種類は Restricted にします。"
      },
      {
        "zh": "权限里搜 Billing，只勾 usage 的 Read。别的产品、Create / Update / Delete 都不要开。创建后立刻复制 SID 和 Secret，Secret 只显示一次。",
        "en": "In permissions, search Billing and check only usage Read. Leave other products and Create / Update / Delete off. Copy the SID and Secret right away — the Secret is shown once.",
        "ja": "権限で Billing を検索し、usage の Read だけにチェック。ほかのプロダクトと Create / Update / Delete はオフ。作成したらすぐに SID と Secret をコピーします。Secret は一度しか表示されません。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "API Key SID 和 Secret 对不上，或 Secret 没在创建时复制下来。",
          "en": "API Key SID and Secret don’t match, or the Secret wasn’t copied at creation.",
          "ja": "API Key SID と Secret が一致しないか、作成時に Secret をコピーしていません。"
        },
        "nextStep": {
          "zh": "回 API keys 重新签发 Restricted key，创建后立刻复制 SID 和 Secret。",
          "en": "Go back to API keys, issue a new Restricted key, and copy the SID and Secret right away.",
          "ja": "API keys に戻って Restricted key を発行し直し、作成したらすぐに SID と Secret をコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 key 没有 Billing 的 usage Read。",
          "en": "This key doesn’t have Billing usage Read.",
          "ja": "この key に Billing の usage Read がありません。"
        },
        "nextStep": {
          "zh": "重建一把 Restricted key，只勾 Billing → usage 的 Read。",
          "en": "Recreate a Restricted key with only Billing → usage Read.",
          "ja": "Restricted key を作り直し、Billing → usage の Read だけをオンにしてください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [
      {
        "name": {
          "zh": "Twilio SendGrid Essentials",
          "en": "Twilio SendGrid Essentials",
          "ja": "Twilio SendGrid Essentials"
        },
        "amountUSD": "20",
        "period": "monthly"
      }
    ],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://1console.twilio.com/go?to=/billing",
    "credentialSetupURL": "https://1console.twilio.com/go?to=/account/__account__/settings/us1/api-keys/list",
    "summary": {
      "zh": "短信、语音和 WhatsApp。按用量计，合计只认 totalprice。",
      "en": "SMS, voice, and WhatsApp. Billed by usage; the total uses totalprice only.",
      "ja": "SMS、音声、WhatsApp。従量課金で、合計は totalprice だけを使います。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 Twilio Usage 页本月 totalprice 一致。",
      "en": "This number should match this month’s totalprice on the Twilio Usage page.",
      "ja": "この数字は Twilio Usage ページの今月 totalprice と一致するはずです。"
    }
  },
  {
    "key": "planetscale",
    "name": "PlanetScale",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "Vitess 系 MySQL 水平扩展的企业级挑战者，推出 Postgres 后收入明显回升。",
    "searchKeywords": [
      "mysql",
      "vitess",
      "pscale"
    ],
    "fields": [
      {
        "key": "accessKeyID",
        "label": {
          "zh": "Token ID",
          "en": "Token ID",
          "ja": "Token ID"
        },
        "isSecret": false,
        "validation": {
          "zh": "Token ID 太短，确认复制完整",
          "en": "Token ID is too short. Make sure you copied the whole thing.",
          "ja": "Token ID が短すぎます。全部コピーできているか確認してください。"
        }
      },
      {
        "key": "apiToken",
        "label": {
          "zh": "Token",
          "en": "Token",
          "ja": "Token"
        },
        "isSecret": true,
        "validation": {
          "zh": "Token 太短，确认复制完整",
          "en": "Token is too short. Make sure you copied the whole thing.",
          "ja": "Token が短すぎます。全部コピーできているか確認してください。"
        }
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Organization slug",
          "en": "Organization slug",
          "ja": "Organization slug"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台 URL 里的组织名",
          "en": "The organization name in the dashboard URL",
          "ja": "ダッシュボード URL の組織名"
        },
        "validation": {
          "zh": "组织 slug 太短",
          "en": "The organization slug is too short",
          "ja": "組織 slug が短すぎます"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开组织设置里的 Service tokens，点 New service token。只勾 read_invoices。创建后复制 Token ID 和 Token。",
        "en": "Open Service tokens in organization settings and tap New service token. Check only read_invoices. Copy the Token ID and Token after creating.",
        "ja": "組織設定の Service tokens を開き、New service token をタップします。read_invoices だけにチェック。作成したら Token ID と Token をコピーします。"
      },
      {
        "zh": "组织 slug 是控制台 URL 里组织那一段。",
        "en": "The organization slug is the org segment in the dashboard URL.",
        "ja": "組織 slug はダッシュボード URL の組織の部分です。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "Token ID 和 Token 对不上。",
          "en": "Token ID and Token don’t match.",
          "ja": "Token ID と Token が一致しません。"
        },
        "nextStep": {
          "zh": "回 Service tokens 重新签发，两段都要复制。",
          "en": "Go back to Service tokens and issue a new one. Copy both pieces.",
          "ja": "Service tokens に戻って発行し直し、両方コピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这个 token 没有 read_invoices，或组织 slug 不对。",
          "en": "This token doesn’t have read_invoices, or the organization slug is wrong.",
          "ja": "この token に read_invoices がないか、組織 slug が違います。"
        },
        "nextStep": {
          "zh": "重建一把只勾 read_invoices，并核对组织 slug。",
          "en": "Recreate one with only read_invoices checked, and verify the organization slug.",
          "ja": "read_invoices だけにチェックしたものを作り直し、組織 slug も確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [
      {
        "name": {
          "zh": "PlanetScale Scaler",
          "en": "PlanetScale Scaler",
          "ja": "PlanetScale Scaler"
        },
        "amountUSD": "39",
        "period": "monthly"
      }
    ],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://app.planetscale.com",
    "credentialSetupURL": "https://app.planetscale.com/settings/service-tokens",
    "summary": {
      "zh": "MySQL 兼容的云数据库。按组织当期发票合计。",
      "en": "A MySQL-compatible cloud database. The organization’s current-period invoices, summed.",
      "ja": "MySQL 互換のクラウドデータベース。組織の当期インボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 Organization → Billing 当前账期发票合计一致。",
      "en": "This number should match the current-period invoice total under Organization → Billing.",
      "ja": "この数字は Organization → Billing の現在の会計期間のインボイス合計と一致するはずです。"
    }
  },
  {
    "key": "upstash",
    "name": "Upstash",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "面向 Serverless/Edge 的 Redis/KV 小而活跃，资金与体量远小于 Redis 本体与云厂商。",
    "searchKeywords": [
      "redis",
      "qstash",
      "vector"
    ],
    "fields": [
      {
        "key": "email",
        "label": {
          "zh": "Account email",
          "en": "Account email",
          "ja": "Account email"
        },
        "isSecret": false,
        "validation": {
          "zh": "请填写注册 Upstash 的邮箱",
          "en": "Enter the email you registered Upstash with",
          "ja": "Upstash 登録のメールアドレスを入力してください"
        }
      },
      {
        "key": "apiKey",
        "label": {
          "zh": "Developer API Key",
          "en": "Developer API Key",
          "ja": "Developer API Key"
        },
        "isSecret": true,
        "validation": {
          "zh": "Key 太短，确认复制完整",
          "en": "Key is too short. Make sure you copied the whole thing.",
          "ja": "Key が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "用户名是你注册 Upstash 的邮箱。从 Vercel 或 Fly 一键创建的账号用不了这条 API。",
        "en": "The username is the email you registered Upstash with. An account created with one-click from Vercel or Fly can’t use this API.",
        "ja": "ユーザー名は Upstash 登録のメールアドレスです。Vercel や Fly からワンクリックで作ったアカウントではこの API を使えません。"
      },
      {
        "zh": "打开 Upstash Console 的 Account → API，创建一把 Developer API key 并复制。",
        "en": "Open Account → API in the Upstash Console, create a Developer API key, and copy it.",
        "ja": "Upstash Console の Account → API を開き、Developer API key を作ってコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "邮箱和 Developer API key 对不上。",
          "en": "The email and Developer API key don’t match.",
          "ja": "メールアドレスと Developer API key が一致しません。"
        },
        "nextStep": {
          "zh": "确认邮箱和 Developer API key 来自 Upstash 控制台。",
          "en": "Confirm the email and Developer API key are from the Upstash dashboard.",
          "ja": "メールアドレスと Developer API key が Upstash ダッシュボードのものか確認してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 key 读不到库统计。",
          "en": "This key can’t read database stats.",
          "ja": "この key では DB 統計を読めません。"
        },
        "nextStep": {
          "zh": "回 Account → API 重新签发 Developer API key。",
          "en": "Go back to Account → API and issue a new Developer API key.",
          "ja": "Account → API に戻って Developer API key を発行し直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [
      {
        "name": {
          "zh": "Upstash Pay-as-you-go 固定费",
          "en": "Upstash Pay-as-you-go flat fee",
          "ja": "Upstash Pay-as-you-go 固定費"
        },
        "amountUSD": "0",
        "period": "monthly"
      }
    ],
    "notices": [
      {
        "zh": "从 Vercel 或 Fly 一键创建的 Upstash 账号没有 Developer API。",
        "en": "An Upstash account created with one-click from Vercel or Fly has no Developer API.",
        "ja": "Vercel や Fly からワンクリックで作った Upstash アカウントに Developer API はありません。"
      }
    ],
    "guideURLs": [],
    "billingURL": "https://console.upstash.com/account/billing",
    "credentialSetupURL": "https://console.upstash.com/account/api",
    "summary": {
      "zh": "无服务器 Redis 和队列。按各库本月费用合计。",
      "en": "Serverless Redis and queues. Sum of this month’s charges across databases.",
      "ja": "サーバーレス Redis とキュー。各 DB の今月費用の合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和各 Redis 库 Usage 页的本月费用合计一致。",
      "en": "This number should match this month’s charges summed across Redis Usage pages.",
      "ja": "この数字は各 Redis の Usage ページの今月費用合計と一致するはずです。"
    }
  },
  {
    "key": "elevenlabs",
    "name": "ElevenLabs",
    "kind": "freeTier",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "独立 TTS/语音平台的绝对龙头，收入与开发者规模碾压 Cartesia 等。",
    "searchKeywords": [
      "eleven",
      "tts",
      "语音",
      "voice"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true,
        "validation": {
          "zh": "Key 太短，确认复制完整",
          "en": "Key is too short. Make sure you copied the whole thing.",
          "ja": "Key が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 ElevenLabs 的 API Keys 页面，创建一把 key 并复制。套餐月费请另外记成手工订阅。",
        "en": "Open the ElevenLabs API Keys page, create a key, and copy it. Record the plan fee as a manual subscription.",
        "ja": "ElevenLabs の API Keys ページを開き、key を作ってコピーします。プラン月額は手動サブスクリプションとして別に記録してください。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把 key 无效。",
          "en": "This key is invalid.",
          "ja": "この key は無効です。"
        },
        "nextStep": {
          "zh": "回 API Keys 重新签发。",
          "en": "Go back to API Keys and issue a new one.",
          "ja": "API Keys に戻って発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 key 读不到订阅。",
          "en": "This key can’t read the subscription.",
          "ja": "この key ではサブスクリプションを読めません。"
        },
        "nextStep": {
          "zh": "用账户主 key。",
          "en": "Use the account’s primary key.",
          "ja": "アカウントの主 key を使ってください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [
      {
        "name": {
          "zh": "ElevenLabs Creator",
          "en": "ElevenLabs Creator",
          "ja": "ElevenLabs Creator"
        },
        "amountUSD": "22",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "ElevenLabs Pro",
          "en": "ElevenLabs Pro",
          "ja": "ElevenLabs Pro"
        },
        "amountUSD": "99",
        "period": "monthly"
      }
    ],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://elevenlabs.io/app/subscription",
    "credentialSetupURL": "https://elevenlabs.io/app/settings/api-keys",
    "summary": {
      "zh": "语音合成。额度内显示已用比例，超量才出现金额。",
      "en": "Speech synthesis. Inside the quota it shows usage percent. Dollars appear only after overage.",
      "ja": "音声合成。枠内は使用割合、超過してから金額が出ます。"
    },
    "verifyHint": {
      "zh": "额度内会显示已用比例；有超量时显示超额美元。套餐月费不在这个数字里。",
      "en": "Inside the quota it shows usage percent. After overage it shows extra dollars. The plan fee is not in this number.",
      "ja": "枠内は使用割合、超過があると超過ドルです。プラン月額はこの数字に入りません。"
    }
  },
  {
    "key": "railway",
    "name": "Railway",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "开发者口中的现代 Heroku，自建机房后增长很快，已被当成可落地的替代。",
    "searchKeywords": [
      "railway.app",
      "deploy",
      "部署"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true,
        "validation": {
          "zh": "Token 太短，确认复制完整",
          "en": "Token is too short. Make sure you copied the whole thing.",
          "ja": "Token が短すぎます。全部コピーできているか確認してください。"
        }
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Workspace ID",
          "en": "Workspace ID",
          "ja": "Workspace ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台 Cmd+K → Copy Workspace ID",
          "en": "In the dashboard, press Cmd+K → Copy Workspace ID",
          "ja": "ダッシュボードで Cmd+K → Copy Workspace ID"
        },
        "validation": {
          "zh": "Workspace ID 太短，从控制台复制完整",
          "en": "Workspace ID is too short. Copy the full value from the dashboard.",
          "ja": "Workspace ID が短すぎます。ダッシュボードから全部コピーしてください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Railway 的 Tokens 页面，创建一把 Account token 或 Workspace token 并复制。",
        "en": "Open Railway’s Tokens page, create an Account token or Workspace token, and copy it.",
        "ja": "Railway の Tokens ページを開き、Account token または Workspace token を作ってコピーします。"
      },
      {
        "zh": "还需要 Workspace ID。在控制台按 Cmd/Ctrl+K，搜 Copy Workspace ID。",
        "en": "You also need a Workspace ID. In the dashboard press Cmd/Ctrl+K and search Copy Workspace ID.",
        "ja": "Workspace ID も必要です。ダッシュボードで Cmd/Ctrl+K を押し、Copy Workspace ID を検索してください。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这个 token 无效或已撤销。",
          "en": "This token is invalid or has been revoked.",
          "ja": "この token は無効か、すでに取り消されています。"
        },
        "nextStep": {
          "zh": "回 Tokens 重新签发 Account 或 Workspace token。",
          "en": "Go back to Tokens and issue a new Account or Workspace token.",
          "ja": "Tokens に戻って Account または Workspace token を発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这个 token 读不到这个 Workspace。",
          "en": "This token can’t read this Workspace.",
          "ja": "この token ではこの Workspace を読めません。"
        },
        "nextStep": {
          "zh": "确认 Workspace ID 和 token 属于同一个 workspace。",
          "en": "Confirm the Workspace ID and token belong to the same workspace.",
          "ja": "Workspace ID と token が同じ workspace か確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [
      {
        "name": {
          "zh": "Railway Hobby",
          "en": "Railway Hobby",
          "ja": "Railway Hobby"
        },
        "amountUSD": "5",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Railway Pro",
          "en": "Railway Pro",
          "ja": "Railway Pro"
        },
        "amountUSD": "20",
        "period": "monthly"
      }
    ],
    "notices": [
      {
        "zh": "Railway 用 Account token 取账单。",
        "en": "Railway reads billing with an Account token.",
        "ja": "Railway は Account token で請求を取ります。"
      }
    ],
    "guideURLs": [],
    "billingURL": "https://railway.com/workspace/usage",
    "credentialSetupURL": "https://railway.com/account/tokens",
    "summary": {
      "zh": "应用托管。按工作区当期账单。",
      "en": "App hosting. The workspace’s current-period bill.",
      "ja": "アプリホスティング。ワークスペースの当期請求です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 Workspace → Usage 的 Current bill 一致。Hobby 的 5 美元保底已经含在里面。",
      "en": "This number should match Current bill under Workspace → Usage. The Hobby $5 floor is already included.",
      "ja": "この数字は Workspace → Usage の Current bill と一致するはずです。Hobby の 5 ドル下限はもう含まれています。"
    }
  },
  {
    "key": "stripe",
    "name": "Stripe",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "开发者收单与订阅计费的基础设施寡头，处理量已进入全球支付第一梯队。",
    "searchKeywords": [
      "支付",
      "手续费",
      "payments",
      "收费"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "Restricted API Key",
          "en": "Restricted API Key",
          "ja": "Restricted API Key"
        },
        "isSecret": true,
        "hint": {
          "zh": "rk_live_ 开头",
          "en": "starts with rk_live_",
          "ja": "rk_live_ で始まる"
        },
        "validation": {
          "zh": "Key 太短，确认复制完整",
          "en": "Key is too short. Make sure you copied the whole thing.",
          "ja": "Key が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Stripe Dashboard 的 API keys。若出现 Manage API keys，点它。",
        "en": "Open API keys in the Stripe Dashboard. If you see Manage API keys, tap it.",
        "ja": "Stripe Dashboard の API keys を開きます。Manage API keys が出たらタップします。"
      },
      {
        "zh": "切到 Live 模式，点 Create restricted key。",
        "en": "Switch to Live mode, then tap Create restricted key.",
        "ja": "Live モードにして、Create restricted key をタップします。"
      },
      {
        "zh": "用途选 Providing this key to a third-party application。",
        "en": "For how you’ll use this key, choose Providing this key to a third-party application.",
        "ja": "用途は Providing this key to a third-party application を選びます。"
      },
      {
        "zh": "第三方名称填 TollCat。",
        "en": "Enter TollCat as the third-party name.",
        "ja": "第三者の名前は TollCat です。"
      },
      {
        "zh": "网站填 tollcat.app，用 https 协议。",
        "en": "For the website, enter tollcat.app with the https scheme.",
        "ja": "サイトは https で tollcat.app を入力します。"
      },
      {
        "zh": "打开 Customize permissions for this key，只把 Balance 开成 Read。",
        "en": "Open Customize permissions for this key, and set only Balance to Read.",
        "ja": "Customize permissions for this key を開き、Balance だけ Read にします。"
      },
      {
        "zh": "点 Create key，复制。Key 以 rk_live_ 开头。",
        "en": "Tap Create key and copy it. The key starts with rk_live_.",
        "ja": "Create key をタップしてコピーします。Key は rk_live_ で始まります。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把 key 无效，或用了 Publishable key。",
          "en": "This key is invalid, or you used a Publishable key.",
          "ja": "この key は無効か、Publishable key を使っています。"
        },
        "nextStep": {
          "zh": "回 API keys 重新签发 Restricted key。",
          "en": "Go back to API keys and issue a new Restricted key.",
          "ja": "API keys に戻って Restricted key を発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 key 没有 Balance: Read。",
          "en": "This key doesn’t have Balance: Read.",
          "ja": "この key に Balance: Read がありません。"
        },
        "nextStep": {
          "zh": "重建一把 Restricted key，用途选 Providing this key to a third-party application，只开 Balance → Read。",
          "en": "Recreate a Restricted key, choose Providing this key to a third-party application, and turn on only Balance → Read.",
          "ja": "Restricted key を作り直し、Providing this key to a third-party application を選び、Balance → Read だけをオンにしてください。"
        },
        "httpStatus": 403
      },
      {
        "explanation": {
          "zh": "账户里有非美元手续费。",
          "en": "The account has non-USD fees.",
          "ja": "口座にドル以外の手数料があります。"
        },
        "nextStep": {
          "zh": "只用美元结算的 Stripe 账户，或把外币手续费记成手工订阅。",
          "en": "Use a Stripe account that settles only in USD, or record foreign-currency fees as a manual subscription.",
          "ja": "ドルだけを決済する Stripe アカウントにするか、外貨手数料を手動サブスクリプションにしてください。"
        },
        "httpStatus": 200
      }
    ],
    "plans": [],
    "notices": [
      {
        "zh": "这里记的是付给 Stripe 的手续费。",
        "en": "This records fees paid to Stripe.",
        "ja": "ここは Stripe に払う手数料です。"
      }
    ],
    "guideURLs": [],
    "billingURL": "https://dashboard.stripe.com/balance",
    "credentialSetupURL": "https://dashboard.stripe.com/apikeys",
    "summary": {
      "zh": "收款。这里记的是 Stripe 抽走的手续费，不是你的营收。",
      "en": "Payments. This records Stripe’s fees, not your revenue.",
      "ja": "決済。ここは Stripe が取る手数料で、あなたの売上ではありません。"
    },
    "verifyHint": {
      "zh": "这个数字是本月 Stripe 抽走的手续费合计，应该和 Balance 页的 Fees 对得上。多币种账户如果有非美元手续费会拒绝。",
      "en": "This number is this month’s Stripe fees, and should match Fees on the Balance page. A multi-currency account with non-USD fees is rejected.",
      "ja": "この数字は今月 Stripe が取る手数料合計で、Balance ページの Fees と一致するはずです。多通貨口座でドル以外の手数料があると拒否します。"
    }
  },
  {
    "key": "resend",
    "name": "Resend",
    "kind": "freeTier",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "开发者事务邮件的默认新选择，正在快速抢 SendGrid 的心智。",
    "searchKeywords": [
      "email",
      "邮件",
      "transactional"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true,
        "hint": {
          "zh": "re_ 开头",
          "en": "starts with re_",
          "ja": "re_ で始まる"
        },
        "validation": {
          "zh": "API Key 应该以 re_ 开头",
          "en": "API Key should start with re_",
          "ja": "API Key は re_ で始まる必要があります"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Resend 的 API Keys，创建一把 key 并复制。免费档按本月已用 / 3000 封显示额度。",
        "en": "Open Resend API Keys, create a key, and copy it. On the free tier this shows used / 3000 emails this month.",
        "ja": "Resend の API Keys を開き、key を作ってコピーします。無料枠では今月の使用 / 3000 通で枠を出します。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把 key 无效或已撤销。",
          "en": "This key is invalid or has been revoked.",
          "ja": "この key は無効か、すでに取り消されています。"
        },
        "nextStep": {
          "zh": "回 API Keys 重新签发。",
          "en": "Go back to API Keys and issue a new one.",
          "ja": "API Keys に戻って発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "请求被拒。直接打 HTTP 时必须带 User-Agent。",
          "en": "The request was rejected. Direct HTTP calls must send a User-Agent.",
          "ja": "リクエストが拒否されました。HTTP を直接叩くときは User-Agent が必要です。"
        },
        "nextStep": {
          "zh": "确认复制的是完整 re_ key。",
          "en": "Confirm you copied the full re_ key.",
          "ja": "re_ key を全部コピーしたか確認してください。"
        },
        "httpStatus": 403
      },
      {
        "explanation": {
          "zh": "付费套餐没有公开的美元账单字段。",
          "en": "Paid plans have no public USD billing field.",
          "ja": "有料プランに公開のドル請求フィールドはありません。"
        },
        "nextStep": {
          "zh": "免费档才能自动拉账单。付费户等 Resend 提供账单接口。",
          "en": "Auto-fetch only works on the free tier. Paid accounts have to wait for a Resend billing API.",
          "ja": "自動取得は無料枠だけです。有料アカウントは Resend が請求 API を出すまで待ちます。"
        },
        "httpStatus": 200
      }
    ],
    "plans": [
      {
        "name": {
          "zh": "Resend Pro",
          "en": "Resend Pro",
          "ja": "Resend Pro"
        },
        "amountUSD": "20",
        "period": "monthly"
      }
    ],
    "notices": [
      {
        "zh": "Resend 付费套餐没有公开账单金额。自动拉账单只覆盖免费档的 3,000 封/月额度。",
        "en": "Resend paid plans have no public billed amount. Auto-fetch only covers the free tier’s 3,000 emails / month.",
        "ja": "Resend の有料プランに公開の請求金額はありません。自動取得は無料枠の 3,000 通/月だけです。"
      }
    ],
    "guideURLs": [],
    "billingURL": "https://resend.com/settings/usage",
    "credentialSetupURL": "https://resend.com/api-keys",
    "summary": {
      "zh": "交易邮件。免费档看已用比例，付费套餐目前拉不到。",
      "en": "Transactional email. The free tier shows usage percent. Paid plans can’t be fetched yet.",
      "ja": "トランザクションメール。無料枠は使用割合、有料プランは今は取れません。"
    },
    "verifyHint": {
      "zh": "免费档这个比例应该和 Settings → Usage 的本月已用对得上。付费套餐会直接失败。",
      "en": "On the free tier this percent should match this month’s usage in Settings → Usage. Paid plans fail outright.",
      "ja": "無料枠では、この割合は Settings → Usage の今月使用と一致するはずです。有料プランはそのまま失敗します。"
    }
  },
  {
    "key": "posthog",
    "name": "PostHog",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "开发者一体分析正在吞噬 Mixpanel/Amplitude 的中小客户，增速远高于在位者。",
    "searchKeywords": [
      "analytics",
      "分析",
      "replay",
      "feature flags"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "Personal API Key",
          "en": "Personal API Key",
          "ja": "Personal API Key"
        },
        "isSecret": true,
        "hint": {
          "zh": "phx_ 开头",
          "en": "starts with phx_",
          "ja": "phx_ で始まる"
        },
        "validation": {
          "zh": "Personal API Key 应该以 phx_ 开头",
          "en": "Personal API Key should start with phx_",
          "ja": "Personal API Key は phx_ で始まる必要があります"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 PostHog Settings → Personal API keys，点 Create a personal API key。权限给 Organization 读取，然后复制 phx_ 开头的 key。EU Cloud 的 key 会先打 US，401 再试 EU。",
        "en": "Open PostHog Settings → Personal API keys and tap Create a personal API key. Grant Organization read, then copy the key that starts with phx_. An EU Cloud key hits US first, then EU after a 401.",
        "ja": "PostHog Settings → Personal API keys を開き、Create a personal API key をタップします。Organization の読み取りを付け、phx_ で始まる key をコピーします。EU Cloud の key は先に US へ行き、401 のあと EU を試します。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "key 无效，或 US / EU 区域都不认这把 key。",
          "en": "The key is invalid, or neither the US nor EU region accepts it.",
          "ja": "key が無効か、US / EU のどちらでもこの key を認めていません。"
        },
        "nextStep": {
          "zh": "回 Personal API keys 重新签发，确认复制完整。",
          "en": "Go back to Personal API keys, issue a new one, and make sure you copied all of it.",
          "ja": "Personal API keys に戻って発行し直し、全部コピーできているか確認してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 key 读不到组织账单。",
          "en": "This key can’t read organization billing.",
          "ja": "この key では組織の請求を読めません。"
        },
        "nextStep": {
          "zh": "重建一把，给 Organization 权限。",
          "en": "Recreate one and grant Organization permission.",
          "ja": "作り直し、Organization 権限を付けてください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [
      {
        "name": {
          "zh": "PostHog Ridiculously Cheap",
          "en": "PostHog Ridiculously Cheap",
          "ja": "PostHog Ridiculously Cheap"
        },
        "amountUSD": "0",
        "period": "monthly"
      }
    ],
    "notices": [
      {
        "zh": "PostHog 要 Personal API key（phx_）。EU Cloud 会先打 US，401 再试 EU。",
        "en": "PostHog needs a Personal API key (phx_). EU Cloud hits US first, then EU after a 401.",
        "ja": "PostHog は Personal API key（phx_）が必要です。EU Cloud は先に US へ行き、401 のあと EU を試します。"
      }
    ],
    "guideURLs": [],
    "billingURL": "https://app.posthog.com/organization/billing",
    "credentialSetupURL": "https://app.posthog.com/settings/user-api-keys",
    "summary": {
      "zh": "产品分析。按组织当期账单，优先折后金额。",
      "en": "Product analytics. The organization’s current-period bill, preferring the discounted amount.",
      "ja": "プロダクト分析。組織の当期請求で、割引後を優先します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 Organization → Billing 的 Current bill 一致，优先用折后金额。",
      "en": "This number should match Current bill under Organization → Billing, preferring the discounted amount.",
      "ja": "この数字は Organization → Billing の Current bill と一致するはずです。割引後を優先します。"
    }
  },
  {
    "key": "clerk",
    "name": "Clerk",
    "kind": "planAndUsage",
    "status": "pendingVerification",
    "inbox": true,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "Next.js / React 开发者认证的默认替代，正在切 Auth0 的中小客户。",
    "searchKeywords": [
      "auth",
      "登录",
      "authentication",
      "mau",
      "mru"
    ],
    "fields": [],
    "steps": [
      {
        "zh": "Clerk 没有公开的账单接口。下一步会给你一段任务书，粘给 Claude Code、Cursor 或任何能上网的 AI 写抓取脚本。",
        "en": "Clerk has no public billing API. Next you’ll get a brief. Paste it into Claude Code, Cursor, or any AI that can reach the web, and have it write a scrape script.",
        "ja": "Clerk に公開の請求 API はありません。次の画面で依頼文を出します。Claude Code、Cursor、またはネットに出られる AI に貼って、取得スクリプトを書いてもらってください。"
      },
      {
        "zh": "投递 key 单独给你，放进脚本的环境变量。脚本每天跑一次，同一个月重复上报是覆盖。",
        "en": "The ingest key is yours alone. Put it in the script’s environment variables. Run the script once a day. Sending the same month again overwrites.",
        "ja": "投函キーはあなた専用です。スクリプトの環境変数に入れてください。スクリプトは 1 日 1 回。同じ月を再送すると上書きです。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "投递 key 已经被吊销了。",
          "en": "The ingest key has been revoked.",
          "ja": "投函キーはすでに取り消されています。"
        },
        "nextStep": {
          "zh": "去设置 → 读数信箱里再签一把，然后更新你的脚本。",
          "en": "Go to Settings → Inbox and issue a new one, then update your script.",
          "ja": "設定 → 検針ポストで発行し直し、スクリプトを更新してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "投递太频繁了。",
          "en": "You’re delivering too often.",
          "ja": "投函が頻繁すぎます。"
        },
        "nextStep": {
          "zh": "每天跑一次就够。",
          "en": "Once a day is enough.",
          "ja": "1 日 1 回で足ります。"
        },
        "httpStatus": 429
      }
    ],
    "plans": [
      {
        "name": {
          "zh": "Clerk Pro",
          "en": "Clerk Pro",
          "ja": "Clerk Pro"
        },
        "amountUSD": "25",
        "period": "monthly"
      }
    ],
    "notices": [
      {
        "zh": "Clerk 这家走读数信箱。",
        "en": "Clerk. This one uses the inbox.",
        "ja": "Clerkこのサービスは検針ポストです。"
      },
      {
        "zh": "Clerk 的 API 只覆盖你向用户收钱那部分，读不到你欠 Clerk 多少。这家走读数信箱。",
        "en": "Clerk’s API only covers what you charge your users, not what you owe Clerk. This one uses the inbox.",
        "ja": "Clerk の API はユーザーから受け取る分だけで、Clerk に払う分は読めません。このサービスは検針ポストです。"
      }
    ],
    "guideURLs": [],
    "billingURL": "https://dashboard.clerk.com/last-active?path=billing",
    "credentialSetupURL": "https://dashboard.clerk.com/last-active?path=api-keys",
    "summary": {
      "zh": "登录和用户管理。没有公开账单接口，走读数信箱。",
      "en": "Auth and user management. There’s no public billing API, so it uses the inbox.",
      "ja": "ログインとユーザー管理。公開の請求 API はないので、検針ポストを使います。"
    },
    "verifyHint": {
      "zh": "接入之后先显示「等待投递」。脚本第一次上报之后数字才会出来。",
      "en": "After connecting, it first shows Waiting for delivery. The number appears after the script reports once.",
      "ja": "接続した直後は「投函待ち」です。スクリプトが一度報告してから数字が出ます。"
    }
  },
  {
    "key": "sentry",
    "name": "Sentry",
    "kind": "freeTier",
    "status": "available",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "错误追踪几乎是事实标准，份额远超 Bugsnag/Rollbar 等竞品。",
    "searchKeywords": [
      "error",
      "错误",
      "crash",
      "监控"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "Personal Token",
          "en": "Personal Token",
          "ja": "Personal Token"
        },
        "isSecret": true,
        "hint": {
          "zh": "Create New Personal Token，Organization 选 Read",
          "en": "Create New Personal Token, with Organization set to Read",
          "ja": "Create New Personal Token。Organization は Read"
        },
        "validation": {
          "zh": "Token 太短，确认复制完整",
          "en": "Token is too short. Make sure you copied the whole thing.",
          "ja": "Token が短すぎます。全部コピーできているか確認してください。"
        }
      },
      {
        "key": "accountID",
        "label": {
          "zh": "组织 Slug",
          "en": "organization slug",
          "ja": "組織 slug"
        },
        "isSecret": false,
        "hint": {
          "zh": "Settings → Organization Settings → General",
          "en": "Settings → Organization Settings → General",
          "ja": "Settings → Organization Settings → General"
        },
        "validation": {
          "zh": "填组织 slug",
          "en": "Fill in the organization slug",
          "ja": "組織 slug を入れてください"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Sentry 的 Create New Personal Token。",
        "en": "Open Sentry’s Create New Personal Token.",
        "ja": "Sentry の Create New Personal Token を開きます。"
      },
      {
        "zh": "Permissions 里把 Organization 从 No Access 改成 Read。Project、Team、Release、Issue & Event、Member、Alerts 都留 No Access，点 Create Token，复制。",
        "en": "Under Permissions, change Organization from No Access to Read. Leave Project, Team, Release, Issue & Event, Member, and Alerts as No Access, tap Create Token, and copy it.",
        "ja": "Permissions で Organization を No Access から Read にします。Project、Team、Release、Issue & Event、Member、Alerts は No Access のまま、Create Token をタップしてコピーします。"
      },
      {
        "zh": "再填组织的 slug。它在 Settings → Organization Settings → General 的 Organization Slug。这里显示 Developer 档 5,000 条错误的额度占比。",
        "en": "Then fill in the organization slug. It’s Organization Slug under Settings → Organization Settings → General. This shows the Developer tier’s 5,000-error quota.",
        "ja": "続けて組織の slug を入れます。Settings → Organization Settings → General の Organization Slug です。Developer 枠 5,000 件の割合を出します。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "Token 无效或已撤销。",
          "en": "Token is invalid or has been revoked.",
          "ja": "Token は無効か、すでに取り消されています。"
        },
        "nextStep": {
          "zh": "回 Create New Personal Token 重建一把。",
          "en": "Go back to Create New Personal Token and create a new one.",
          "ja": "Create New Personal Token に戻って作り直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 token 没有 Organization: Read。",
          "en": "This token doesn’t have Organization: Read.",
          "ja": "この token に Organization: Read がありません。"
        },
        "nextStep": {
          "zh": "回 Create New Personal Token 重建，Permissions 里把 Organization 改成 Read。",
          "en": "Go back to Create New Personal Token, recreate it, and set Organization to Read under Permissions.",
          "ja": "Create New Personal Token に戻って作り直し、Permissions の Organization を Read にしてください。"
        },
        "httpStatus": 403
      },
      {
        "explanation": {
          "zh": "组织 slug 不对。",
          "en": "The organization slug is wrong.",
          "ja": "組織 slug が違います。"
        },
        "nextStep": {
          "zh": "打开 Settings → Organization Settings → General，看 Organization Slug，区分大小写。",
          "en": "Open Settings → Organization Settings → General and check Organization Slug. It’s case-sensitive.",
          "ja": "Settings → Organization Settings → General を開き、Organization Slug を見てください。大文字小文字を区別します。"
        },
        "httpStatus": 404
      }
    ],
    "plans": [
      {
        "name": {
          "zh": "Sentry Team",
          "en": "Sentry Team",
          "ja": "Sentry Team"
        },
        "amountUSD": "26",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Sentry Business",
          "en": "Sentry Business",
          "ja": "Sentry Business"
        },
        "amountUSD": "80",
        "period": "monthly"
      }
    ],
    "notices": [
      {
        "zh": "Sentry 公开 API 只有事件计数，没有账单金额。",
        "en": "Sentry’s public API has event counts, not billed amounts.",
        "ja": "Sentry の公開 API はイベント数だけで、請求金額はありません。"
      },
      {
        "zh": "Sentry 公开 API 不给金额。这里只报 Developer 档 5,000 条错误的额度占比，付费档会一直顶在 100%。",
        "en": "Sentry’s public API doesn’t give amounts. This only reports the Developer tier’s 5,000-error quota. Paid tiers stay pinned at 100%.",
        "ja": "Sentry の公開 API は金額を出しません。Developer 枠 5,000 件の割合だけです。有料枠は 100% のままです。"
      }
    ],
    "guideURLs": [],
    "billingURL": "https://sentry.io/settings/billing/overview/",
    "credentialSetupURL": "https://sentry.io/settings/account/api/auth-tokens/new-token/",
    "summary": {
      "zh": "错误监控。这里按 Developer 档 5,000 条错误事件的额度来算。",
      "en": "Error monitoring. This uses the Developer tier’s 5,000-error quota.",
      "ja": "エラー監視。Developer 枠 5,000 件で計算します。"
    },
    "verifyHint": {
      "zh": "这个百分比对应 Sentry Stats 页当月已接收的错误事件数除以 5,000。付费档有预留额度，这里会一直顶在 100%。",
      "en": "This percent is this month’s accepted error events on Sentry Stats divided by 5,000. Paid tiers have reserved quota, so this stays pinned at 100%.",
      "ja": "この割合は Sentry Stats の当月受信エラー件数 ÷ 5,000 です。有料枠には予約クォータがあるので、ここは 100% のままです。"
    }
  },
  {
    "key": "vultr",
    "name": "Vultr",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "北美开发者常把它与 DO/Linode 并列短名单，并已进入主流公有云评测。",
    "searchKeywords": [
      "vps",
      "cloud compute",
      "主机",
      "云服务器"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true,
        "hint": {
          "zh": "Account → API 页面",
          "en": "Account → API page",
          "ja": "Account → API ページ"
        },
        "validation": {
          "zh": "Vultr 的 API Key 是 36 位大写字母数字串，看着太短就是没复制全",
          "en": "A Vultr API Key is 36 uppercase letters and digits. If it looks short, you didn’t copy all of it.",
          "ja": "Vultr の API Key は 36 桁の大文字と数字です。短く見えるなら、全部コピーできていません。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Vultr 控制台 Account → API，先把这台设备的出口 IP 加进访问控制。",
        "en": "Open Account → API in the Vultr dashboard and add this device’s egress IP to access control first.",
        "ja": "Vultr ダッシュボードの Account → API を開き、先にこの端末の出口 IP をアクセス制御に入れます。"
      },
      {
        "zh": "启用 API 并复制 Personal Access Token。",
        "en": "Enable the API and copy the Personal Access Token.",
        "ja": "API を有効にして Personal Access Token をコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "Token 无效，或者已经在控制台里重置过。",
          "en": "The token is invalid, or it was already reset in the dashboard.",
          "ja": "token は無効か、ダッシュボードでリセット済みです。"
        },
        "nextStep": {
          "zh": "回上一步重新复制一次 Personal Access Token。",
          "en": "Go back a step and copy the Personal Access Token again.",
          "ja": "前の手順に戻って Personal Access Token をもう一度コピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "多半是 IP 访问控制没放行这台设备。",
          "en": "Usually the IP allowlist hasn’t permitted this device.",
          "ja": "たいてい IP アクセス制御がこの端末を許可していません。"
        },
        "nextStep": {
          "zh": "回 Account → API 页，把当前网络的出口 IP 加进 Access Control，或临时放开 0.0.0.0/0 再收窄。",
          "en": "Go back to Account → API, add this network’s egress IP to Access Control, or briefly allow 0.0.0.0/0 and tighten it after.",
          "ja": "Account → API ページに戻り、今のネットワークの出口 IP を Access Control に入れるか、いったん 0.0.0.0/0 を開けてから絞ってください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [
      {
        "zh": "Vultr 的 API 默认拦掉所有 IP。要先在 Account → API 里把这台设备的出口 IP 放行，否则一直 403。",
        "en": "Vultr’s API blocks every IP by default. Allow this device’s egress IP under Account → API, or you’ll keep getting 403.",
        "ja": "Vultr の API は既定ですべての IP を止めます。Account → API でこの端末の出口 IP を許可しないと、ずっと 403 です。"
      }
    ],
    "guideURLs": [],
    "billingURL": "https://my.vultr.com/billing",
    "credentialSetupURL": "https://my.vultr.com/settings/#settingsapi",
    "summary": {
      "zh": "云主机。对账看 Pending Charges，余额是 Account Balance。",
      "en": "Cloud hosts. Reconcile against Pending Charges. The balance is Account Balance.",
      "ja": "クラウドホスト。照合は Pending Charges、残高は Account Balance です。"
    },
    "verifyHint": {
      "zh": "这个数字应该等于 Vultr 后台 Billing 页的「Pending Charges」。余额那栏对应「Account Balance」。",
      "en": "This number should equal Pending Charges on the Vultr Billing page. The balance column is Account Balance.",
      "ja": "この数字は Vultr 管理画面 Billing の「Pending Charges」と一致するはずです。残高の欄は「Account Balance」です。"
    }
  },
  {
    "key": "fastly",
    "name": "Fastly",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "可编程 CDN 的强挑战者，收入回升但站点份额被 Cloudflare 侵蚀。",
    "searchKeywords": [
      "cdn",
      "edge",
      "compute@edge",
      "加速"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true,
        "hint": {
          "zh": "Automation token 即可",
          "en": "An Automation token is enough",
          "ja": "Automation token で足ります"
        },
        "validation": {
          "zh": "Token 太短，确认复制完整",
          "en": "Token is too short. Make sure you copied the whole thing.",
          "ja": "Token が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Fastly 的 Personal API tokens 页面，新建一把 token。Scope 只勾 global:read，Type 选 Automation token。",
        "en": "Open Fastly’s Personal API tokens page and create a token. Check only global:read for Scope, and set Type to Automation token.",
        "ja": "Fastly の Personal API tokens ページを開き、token を新規作成します。Scope は global:read だけ、Type は Automation token です。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "Token 无效或已过期。",
          "en": "Token is invalid or has expired.",
          "ja": "Token は無効か、期限切れです。"
        },
        "nextStep": {
          "zh": "回上一步重建一把，注意 Automation token 有有效期。",
          "en": "Go back a step and recreate it. An Automation token expires.",
          "ja": "前の手順に戻って作り直してください。Automation token には有効期限があります。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 token 没有 global:read。",
          "en": "This token doesn’t have global:read.",
          "ja": "この token に global:read がありません。"
        },
        "nextStep": {
          "zh": "回上一步重建，Scope 勾 global:read。",
          "en": "Go back a step and recreate it with Scope set to global:read.",
          "ja": "前の手順に戻して作り直し、Scope に global:read を入れてください。"
        },
        "httpStatus": 403
      },
      {
        "explanation": {
          "zh": "账户下没有当月发票，一般是刚开户还没产生用量。",
          "en": "There’s no current-month invoice. Usually the account is new and hasn’t used anything yet.",
          "ja": "当月インボイスがありません。開設直後で用量がまだないことが多いです。"
        },
        "nextStep": {
          "zh": "先跑出一点流量，或者过一天再刷新。",
          "en": "Generate a bit of traffic first, or refresh tomorrow.",
          "ja": "先に少しトラフィックを出すか、1 日おいて再読み込みしてください。"
        },
        "httpStatus": 404
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://manage.fastly.com/account/billing",
    "credentialSetupURL": "https://manage.fastly.com/account/personal/tokens",
    "summary": {
      "zh": "CDN 和边缘计算。按当月 Month to date 账单。",
      "en": "CDN and edge compute. This is the Month to date bill.",
      "ja": "CDN とエッジコンピューティング。当月の Month to date 請求です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 Fastly 后台 Billing 页当月那张「Month to date」对得上。",
      "en": "This number should match this month’s Month to date bill on the Fastly Billing page.",
      "ja": "この数字は Fastly 管理画面 Billing の当月「Month to date」と一致するはずです。"
    }
  },
  {
    "key": "exa",
    "name": "Exa",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "AI 搜索 API 里融资与客户质量最高的挑战者，但收入仍远小于 Perplexity。",
    "searchKeywords": [
      "search",
      "搜索",
      "agent",
      "metaphor"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "Service Key",
          "en": "Service Key",
          "ja": "Service Key"
        },
        "isSecret": true,
        "hint": {
          "zh": "团队管理用的那把",
          "en": "The team-admin one",
          "ja": "チーム管理用のもの"
        },
        "validation": {
          "zh": "Service key 太短，确认复制完整",
          "en": "Service key is too short. Make sure you copied the whole thing.",
          "ja": "Service key が短すぎます。全部コピーできているか確認してください。"
        }
      },
      {
        "key": "keyID",
        "label": {
          "zh": "API Key ID",
          "en": "API Key ID",
          "ja": "API Key ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "要统计的那把 key 的 UUID",
          "en": "The UUID of the key you want to track",
          "ja": "集計したい key の UUID"
        },
        "validation": {
          "zh": "填 key 的 ID",
          "en": "Fill in the key’s ID",
          "ja": "key の ID を入れてください"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Exa Dashboard 的 API Keys 页面，取一把 service key。",
        "en": "Open the API Keys page in the Exa Dashboard and take a service key.",
        "ja": "Exa Dashboard の API Keys ページを開き、service key を取ります。"
      },
      {
        "zh": "再复制你要统计的那把 key 的 ID。用量是按单把 key 算的。",
        "en": "Then copy the ID of the key you want to track. Usage is counted per key.",
        "ja": "続けて集計したい key の ID をコピーします。用量はキー単位です。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把不是 service key。",
          "en": "This isn’t a service key.",
          "ja": "これは service key ではありません。"
        },
        "nextStep": {
          "zh": "回 Dashboard 换团队管理那把。",
          "en": "Go back to the Dashboard and switch to the team-admin key.",
          "ja": "Dashboard に戻り、チーム管理用の key に替えてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "Key ID 不存在，或者不属于这把 service key 的团队。",
          "en": "The Key ID doesn’t exist, or it doesn’t belong to this service key’s team.",
          "ja": "Key ID が存在しないか、この service key のチームのものではありません。"
        },
        "nextStep": {
          "zh": "回上一步核对 API Key ID。",
          "en": "Go back a step and check the API Key ID.",
          "ja": "前の手順に戻って API Key ID を確認してください。"
        },
        "httpStatus": 404
      }
    ],
    "plans": [],
    "notices": [
      {
        "zh": "Exa 的用量是按单把 key 统计的。团队里还有别的 key 在跑，这里的数会比后台账单小。",
        "en": "Exa usage is counted per key. If the team has other keys running, this number will be smaller than the dashboard bill.",
        "ja": "Exa の用量は key 1 本ごとです。チームに他の key があると、ここの数字は管理画面の請求より小さくなります。"
      }
    ],
    "guideURLs": [],
    "billingURL": "https://dashboard.exa.ai/billing",
    "credentialSetupURL": "https://dashboard.exa.ai/api-keys",
    "summary": {
      "zh": "搜索 API。这只是这一把 key 的花费，不是全团队账单。",
      "en": "A search API. This is spend for this one key, not the whole team bill.",
      "ja": "検索 API。この key 1 本の支出で、チーム全体の請求ではありません。"
    },
    "verifyHint": {
      "zh": "这只是这一把 key 的花费。团队里还有别的 key 在跑，总数会比 Exa 后台的账单小。",
      "en": "This is spend for this one key. If the team has other keys running, the total will be smaller than the Exa dashboard bill.",
      "ja": "これはこの key 1 本の支出です。チームに他の key があると、合計は Exa 管理画面の請求より小さくなります。"
    }
  },
  {
    "key": "atlas",
    "name": "MongoDB Atlas",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "文档库云市场的寡头核心，Atlas 已占 MongoDB 七成以上收入并持续双位数增长。",
    "searchKeywords": [
      "mongodb",
      "mongo",
      "atlas",
      "数据库",
      "database"
    ],
    "fields": [
      {
        "key": "clientID",
        "label": {
          "zh": "Client ID",
          "en": "Client ID",
          "ja": "Client ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "形如 mdb_sa_id_…",
          "en": "Looks like mdb_sa_id_…",
          "ja": "mdb_sa_id_… の形"
        },
        "validation": {
          "zh": "Client ID 太短，确认复制完整",
          "en": "Client ID is too short. Make sure you copied the whole thing.",
          "ja": "Client ID が短すぎます。全部コピーできているか確認してください。"
        }
      },
      {
        "key": "clientSecret",
        "label": {
          "zh": "Client Secret",
          "en": "Client Secret",
          "ja": "Client Secret"
        },
        "isSecret": true,
        "validation": {
          "zh": "Client Secret 太短，确认复制完整",
          "en": "Client Secret is too short. Make sure you copied the whole thing.",
          "ja": "Client Secret が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Atlas 组织设置的 Service Accounts，新建一个服务账号。角色只给 Organization Billing Viewer。创建后复制 Client Secret。",
        "en": "Open Service Accounts in the Atlas organization settings and create a service account. Give it only Organization Billing Viewer. Copy the Client Secret after creating it.",
        "ja": "Atlas の組織設定の Service Accounts を開き、サービスアカウントを新規作成します。ロールは Organization Billing Viewer だけ。作成したら Client Secret をコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "Client ID / Secret 不匹配，或者服务账号被删了。",
          "en": "Client ID / Secret don’t match, or the service account was deleted.",
          "ja": "Client ID / Secret が一致しないか、サービスアカウントが削除されています。"
        },
        "nextStep": {
          "zh": "回上一步重建服务账号，Secret 只在创建时显示一次。",
          "en": "Go back a step and recreate the service account. The Secret is shown only once, at creation.",
          "ja": "前の手順に戻ってサービスアカウントを作り直してください。Secret は作成時に一度だけ表示されます。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "服务账号缺 Organization Billing Viewer。",
          "en": "The service account is missing Organization Billing Viewer.",
          "ja": "サービスアカウントに Organization Billing Viewer がありません。"
        },
        "nextStep": {
          "zh": "回组织设置给这个服务账号加上 Billing Viewer 角色。",
          "en": "Go back to organization settings and add the Billing Viewer role to this service account.",
          "ja": "組織設定に戻り、このサービスアカウントに Billing Viewer ロールを付けてください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [
      {
        "zh": "MongoDB Atlas 只支持服务账号（OAuth2）。",
        "en": "MongoDB Atlas only supports service accounts (OAuth2).",
        "ja": "MongoDB Atlas はサービスアカウント（OAuth2）だけです。"
      }
    ],
    "guideURLs": [],
    "billingURL": "https://cloud.mongodb.com/v2#/billing/overview",
    "credentialSetupURL": "https://cloud.mongodb.com/v2#/access/serviceAccounts",
    "summary": {
      "zh": "MongoDB 托管。按 Pending Invoice 的本月净额。",
      "en": "Managed MongoDB. The net Month-to-date on the Pending Invoice.",
      "ja": "MongoDB マネージド。Pending Invoice の今月純額です。"
    },
    "verifyHint": {
      "zh": "这个数字应该等于 Atlas 后台 Billing 页「Pending Invoice」的 Net Month-to-Date Amount。",
      "en": "This number should equal Net Month-to-Date Amount on the Pending Invoice in Atlas Billing.",
      "ja": "この数字は Atlas 管理画面 Billing の「Pending Invoice」の Net Month-to-Date Amount と一致するはずです。"
    }
  },
  {
    "key": "azure",
    "name": "Azure",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "与 AWS、GCP 构成公有云 IaaS 寡头，份额持续追赶第一名。",
    "searchKeywords": [
      "microsoft",
      "微软",
      "azure openai",
      "entra"
    ],
    "fields": [
      {
        "key": "tenantID",
        "label": {
          "zh": "Directory (tenant) ID",
          "en": "Directory (tenant) ID",
          "ja": "Directory (tenant) ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "Entra ID 概览页",
          "en": "Entra ID overview page",
          "ja": "Entra ID の概要ページ"
        },
        "validation": {
          "zh": "Tenant ID 是 36 位 GUID",
          "en": "Tenant ID is a 36-character GUID",
          "ja": "Tenant ID は 36 桁の GUID です"
        }
      },
      {
        "key": "clientID",
        "label": {
          "zh": "Application (client) ID",
          "en": "Application (client) ID",
          "ja": "Application (client) ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "应用注册概览页",
          "en": "App registrations overview",
          "ja": "アプリの登録の概要ページ"
        },
        "validation": {
          "zh": "Client ID 是 36 位 GUID",
          "en": "Client ID is a 36-character GUID",
          "ja": "Client ID は 36 桁の GUID です"
        }
      },
      {
        "key": "clientSecret",
        "label": {
          "zh": "客户端密码",
          "en": "client secret",
          "ja": "クライアント シークレット"
        },
        "isSecret": true,
        "hint": {
          "zh": "复制「值」",
          "en": "Copy Value",
          "ja": "「値」をコピー"
        },
        "validation": {
          "zh": "客户端密码太短，确认复制的是「值」",
          "en": "The client secret is too short. Make sure you copied Value.",
          "ja": "クライアント シークレットが短すぎます。「値」をコピーしたか確認してください。"
        }
      },
      {
        "key": "accountID",
        "label": {
          "zh": "订阅 ID",
          "en": "Subscription ID",
          "ja": "サブスクリプション ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "Subscription ID",
          "en": "Subscription ID",
          "ja": "Subscription ID"
        },
        "validation": {
          "zh": "订阅 ID 是 36 位 GUID",
          "en": "The Subscription ID is a 36-character GUID",
          "ja": "サブスクリプション ID は 36 桁の GUID です"
        }
      }
    ],
    "steps": [
      {
        "zh": "在 Microsoft Entra ID → 应用注册里新建一个应用，记下 Application (client) ID 和 Directory (tenant) ID。",
        "en": "In Microsoft Entra ID → App registrations, create an app and write down the Application (client) ID and Directory (tenant) ID.",
        "ja": "Microsoft Entra ID → アプリの登録でアプリを新規作成し、Application (client) ID と Directory (tenant) ID を控えます。"
      },
      {
        "zh": "在这个应用的「证书和密码」里新建客户端密码，立刻复制「值」。",
        "en": "Under Certificates and secrets for this app, create a client secret and copy Value right away.",
        "ja": "このアプリの「証明書とシークレット」でクライアント シークレットを作り、「値」をすぐにコピーします。"
      },
      {
        "zh": "打开要监控的订阅 → 访问控制 (IAM)，把这个应用加成 Cost Management Reader。记下订阅 ID。账单数据有 8–24 小时延迟。",
        "en": "Open the subscription you want to watch → Access control (IAM) and add this app as Cost Management Reader. Write down the Subscription ID. Billing data lags 8–24 hours.",
        "ja": "監視するサブスクリプション → アクセス制御 (IAM) を開き、このアプリを Cost Management Reader にします。サブスクリプション ID を控えます。請求データは 8–24 時間遅れます。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "客户端密码错了，或者复制成了密钥 ID。",
          "en": "The client secret is wrong, or you copied the secret ID.",
          "ja": "クライアント シークレットが違うか、シークレット ID をコピーしています。"
        },
        "nextStep": {
          "zh": "回应用注册的「证书和密码」重建一条，复制那一列「值」。",
          "en": "Go back to Certificates and secrets in App registrations, create a new one, and copy the Value column.",
          "ja": "アプリの登録の「証明書とシークレット」に戻り、作り直して「値」の列をコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "应用没有这个订阅的 Cost Management Reader。",
          "en": "The app doesn’t have Cost Management Reader on this subscription.",
          "ja": "アプリにこのサブスクリプションの Cost Management Reader がありません。"
        },
        "nextStep": {
          "zh": "回订阅的访问控制 (IAM) 加角色，加完等几分钟再试。",
          "en": "Go back to Access control (IAM) on the subscription, add the role, then wait a few minutes and try again.",
          "ja": "サブスクリプションのアクセス制御 (IAM) に戻ってロールを足し、数分待ってから再試行してください。"
        },
        "httpStatus": 403
      },
      {
        "explanation": {
          "zh": "订阅 ID 不对，或者这个租户下没有这个订阅。",
          "en": "The Subscription ID is wrong, or this tenant doesn’t have that subscription.",
          "ja": "サブスクリプション ID が違うか、このテナントにそのサブスクリプションがありません。"
        },
        "nextStep": {
          "zh": "回门户核对订阅 ID。",
          "en": "Go back to the portal and check the Subscription ID.",
          "ja": "ポータルに戻ってサブスクリプション ID を確認してください。"
        },
        "httpStatus": 404
      }
    ],
    "plans": [],
    "notices": [
      {
        "zh": "Azure 要先建 Entra 应用注册并在订阅上授 Cost Management Reader，四个字段缺一不可。账单数据有 8–24 小时延迟。",
        "en": "Azure needs an Entra app registration with Cost Management Reader on the subscription. All four fields are required. Billing data lags 8–24 hours.",
        "ja": "Azure は先に Entra アプリ登録を作り、サブスクリプションに Cost Management Reader を付けます。4 つの欄はどれも欠かせません。請求データは 8–24 時間遅れます。"
      }
    ],
    "guideURLs": [],
    "billingURL": "https://portal.azure.com/#view/Microsoft_Azure_GTM/ModernBillingMenuBlade",
    "summary": {
      "zh": "微软云。对账看成本分析里 Month-to-date 的实际成本。",
      "en": "Microsoft cloud. Reconcile against actual cost, Month-to-date, in Cost analysis.",
      "ja": "マイクロソフトのクラウド。コスト分析の Month-to-date 実コストと照合します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 Azure 门户「成本分析」选 Month-to-date、指标选 Actual cost 时的合计一致。",
      "en": "This number should match the Azure portal Cost analysis total with Month-to-date and Actual cost.",
      "ja": "この数字は Azure ポータルの「コスト分析」で Month-to-date、指標 Actual cost の合計と一致するはずです。"
    }
  },
  {
    "key": "polar",
    "name": "Polar",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "面向开发者的开源 MoR 新秀，融资与团队仍处种子阶段。",
    "searchKeywords": [
      "payments",
      "支付",
      "手续费",
      "merchant of record",
      "polar.sh"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "Organization Access Token",
          "en": "Organization Access Token",
          "ja": "Organization Access Token"
        },
        "isSecret": true,
        "hint": {
          "zh": "形如 polar_oat_…",
          "en": "Looks like polar_oat_…",
          "ja": "polar_oat_… の形"
        },
        "validation": {
          "zh": "Token 太短，确认复制完整",
          "en": "Token is too short. Make sure you copied the whole thing.",
          "ja": "Token が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Polar 后台的设置页，新建一个 Organization Access Token。Scope 只勾 metrics:read。",
        "en": "Open settings in the Polar dashboard and create an Organization Access Token. Check only metrics:read for Scope.",
        "ja": "Polar 管理画面の設定ページを開き、Organization Access Token を新規作成します。Scope は metrics:read だけです。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "Token 无效或者已经撤销。",
          "en": "The token is invalid or has already been revoked.",
          "ja": "token は無効か、すでに取り消されています。"
        },
        "nextStep": {
          "zh": "回设置页重建一把 Organization Access Token。",
          "en": "Go back to settings and create a new Organization Access Token.",
          "ja": "設定ページに戻って Organization Access Token を作り直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 token 没有 metrics:read。",
          "en": "This token doesn’t have metrics:read.",
          "ja": "この token に metrics:read がありません。"
        },
        "nextStep": {
          "zh": "回上一步重建，勾上 metrics:read。",
          "en": "Go back a step and recreate it with metrics:read checked.",
          "ja": "前の手順に戻して作り直し、metrics:read にチェックを入れてください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [
      {
        "zh": "Polar 这家记的是手续费（营收 − 净营收）。",
        "en": "For Polar this records fees (revenue minus net revenue).",
        "ja": "Polar では手数料（売上 − 純売上）を記録します。"
      }
    ],
    "guideURLs": [],
    "billingURL": "https://polar.sh/dashboard",
    "credentialSetupURL": "https://polar.sh/settings",
    "summary": {
      "zh": "开源收款。这里是 Polar 抽走的部分，不是你的营收。",
      "en": "Open-source payments. This is Polar’s cut, not your revenue.",
      "ja": "オープンソースの決済。ここは Polar が取る分で、あなたの売上ではありません。"
    },
    "verifyHint": {
      "zh": "这个数字是 Polar 从你的收入里抽走的部分，不等于你的营收。对账看后台 Analytics 里 Revenue 和 Net Revenue 的差。",
      "en": "This number is Polar’s cut of your revenue, not your revenue. Reconcile against Revenue minus Net Revenue in Analytics.",
      "ja": "この数字は Polar が売上から取る分で、あなたの売上ではありません。照合は管理画面 Analytics の Revenue と Net Revenue の差です。"
    }
  },
  {
    "key": "heroku",
    "name": "Heroku",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "品类发明者已被 Salesforce 停掉企业新售、转入维持工程，正在被 Render/Railway 替换。",
    "searchKeywords": [
      "dyno",
      "salesforce",
      "paas",
      "部署"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true,
        "hint": {
          "zh": "Authorizations 里创建的那个",
          "en": "The one created under Authorizations",
          "ja": "Authorizations で作ったもの"
        },
        "validation": {
          "zh": "Token 太短，确认复制完整",
          "en": "Token is too short. Make sure you copied the whole thing.",
          "ja": "Token が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Heroku 账号设置的 Applications 页，在 Authorizations 里创建一个 authorization token。月末才出账，当月发票还没生成时会显示读不到数。",
        "en": "Open the Applications page in Heroku account settings and create an authorization token under Authorizations. Invoices land at month-end, so a missing current-month invoice shows as no reading yet.",
        "ja": "Heroku アカウント設定の Applications ページを開き、Authorizations で authorization token を作ります。月末に出帳するので、当月インボイスがまだないと「読めない」と出ます。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "Token 无效或已过期。",
          "en": "Token is invalid or has expired.",
          "ja": "Token は無効か、期限切れです。"
        },
        "nextStep": {
          "zh": "回 Applications 页重建一个 authorization。",
          "en": "Go back to the Applications page and create a new authorization.",
          "ja": "Applications ページに戻って authorization を作り直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账号下还没有任何发票。",
          "en": "This account has no invoices yet.",
          "ja": "このアカウントにはまだインボイスがありません。"
        },
        "nextStep": {
          "zh": "新账号第一个月末之后才会有。",
          "en": "A new account won’t have one until after the first month-end.",
          "ja": "新しいアカウントは最初の月末が過ぎてからです。"
        },
        "httpStatus": 404
      }
    ],
    "plans": [],
    "notices": [
      {
        "zh": "Heroku 月末才出账。当月发票还没生成时会显示读不到数。",
        "en": "Heroku invoices at month-end. If this month’s invoice isn’t out yet, it shows as no reading.",
        "ja": "Heroku は月末に出帳します。当月インボイスがまだないと「読めない」と出ます。"
      }
    ],
    "guideURLs": [],
    "billingURL": "https://dashboard.heroku.com/account/billing",
    "credentialSetupURL": "https://dashboard.heroku.com/account/applications",
    "summary": {
      "zh": "应用托管。月中常常还没有当月发票，这是出账节奏。",
      "en": "App hosting. Mid-month often has no current-month invoice yet. That’s the billing cadence.",
      "ja": "アプリホスティング。月の途中では当月インボイスがまだないことがよくあります。出帳のリズムです。"
    },
    "verifyHint": {
      "zh": "月中大概率读不到当月发票，这是 Heroku 的出账节奏。月初能看到上一期就说明通了。",
      "en": "Mid-month you usually can’t read this month’s invoice. That’s Heroku’s cadence. Seeing the previous period at month-start means it works.",
      "ja": "月の途中では当月インボイスはまず読めません。Heroku の出帳リズムです。月初に前期が見えれば通っています。"
    }
  },
  {
    "key": "revenuecat",
    "name": "RevenueCat",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "移动订阅内购的基础设施默认层，约三分之一新订阅应用在用。",
    "searchKeywords": [
      "iap",
      "内购",
      "订阅",
      "subscription",
      "rc",
      "抽成"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "V2 Secret Key",
          "en": "V2 Secret Key",
          "ja": "V2 Secret Key"
        },
        "isSecret": true,
        "hint": {
          "zh": "sk_ 开头",
          "en": "starts with sk_",
          "ja": "sk_ で始まる"
        },
        "validation": {
          "zh": "要 V2 secret key（sk_ 开头）",
          "en": "You need a V2 secret key (starts with sk_)",
          "ja": "V2 secret key（sk_ で始まる）が必要です"
        }
      },
      {
        "key": "projectID",
        "label": {
          "zh": "Project ID",
          "en": "Project ID",
          "ja": "Project ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "Project settings 页顶部",
          "en": "Top of the Project settings page",
          "ja": "Project settings ページの上部"
        },
        "validation": {
          "zh": "Project ID 太短，确认复制完整",
          "en": "Project ID is too short. Make sure you copied the whole thing.",
          "ja": "Project ID が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 RevenueCat 的 Project settings → API keys，取一把 V2 secret key。权限只勾 charts_metrics:overview:read。",
        "en": "Open RevenueCat Project settings → API keys and take a V2 secret key. Check only charts_metrics:overview:read.",
        "ja": "RevenueCat の Project settings → API keys を開き、V2 secret key を取ります。権限は charts_metrics:overview:read だけです。"
      },
      {
        "zh": "再复制这个项目的 Project ID。",
        "en": "Then copy this project’s Project ID.",
        "ja": "続けてこのプロジェクトの Project ID をコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "不是 V2 secret key。",
          "en": "That’s not a V2 secret key.",
          "ja": "V2 secret key ではありません。"
        },
        "nextStep": {
          "zh": "回 API keys 页取 sk_ 开头那把。",
          "en": "Go back to the API keys page and take the one that starts with sk_.",
          "ja": "API keys ページに戻り、sk_ で始まるものを取ってください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 key 没有 charts_metrics 权限。",
          "en": "This key doesn’t have charts_metrics permission.",
          "ja": "この key に charts_metrics 権限がありません。"
        },
        "nextStep": {
          "zh": "回上一步重建，勾上 charts_metrics:overview:read。",
          "en": "Go back a step and recreate it with charts_metrics:overview:read checked.",
          "ja": "前の手順に戻して作り直し、charts_metrics:overview:read にチェックを入れてください。"
        },
        "httpStatus": 403
      },
      {
        "explanation": {
          "zh": "指标接口限速 25 次/分钟。",
          "en": "The metrics API is limited to 25 calls per minute.",
          "ja": "指標 API は 1 分 25 回までです。"
        },
        "nextStep": {
          "zh": "等一分钟再刷新。",
          "en": "Wait a minute, then refresh.",
          "ja": "1 分待ってから再読み込みしてください。"
        },
        "httpStatus": 429
      }
    ],
    "plans": [
      {
        "name": {
          "zh": "RevenueCat Pro 起步",
          "en": "RevenueCat Pro starting at",
          "ja": "RevenueCat Pro スタート"
        },
        "amountUSD": "0",
        "period": "monthly"
      }
    ],
    "notices": [
      {
        "zh": "RevenueCat 没有账单接口。这里是按「月追踪收入超过 $2,500 的部分抽 1%」推算的，收入取的是 28 天滚动值，和自然月账单会差一点。",
        "en": "RevenueCat has no billing API. This estimates 1% of tracked monthly revenue above $2,500. Revenue is a 28-day rolling value, so it can differ from a calendar-month bill.",
        "ja": "RevenueCat に請求 API はありません。月次トラッキング売上が $2,500 を超えた分の 1% で推計します。売上は 28 日のローリングなので、暦月の請求とは少しずれます。"
      }
    ],
    "guideURLs": [],
    "billingURL": "https://app.revenuecat.com/settings/billing",
    "credentialSetupURL": "https://app.revenuecat.com/settings/api-keys",
    "summary": {
      "zh": "应用内购。按月追踪收入超过 $2,500 的部分抽 1% 估算。",
      "en": "In-app purchases. An estimate of 1% of tracked monthly revenue above $2,500.",
      "ja": "アプリ内課金。月次トラッキング売上が $2,500 を超えた分の 1% で見積もります。"
    },
    "verifyHint": {
      "zh": "这是按「月追踪收入超过 $2,500 的部分抽 1%」推算的。RevenueCat 只给 28 天滚动收入，和自然月账单会差一点。",
      "en": "This estimates 1% of tracked monthly revenue above $2,500. RevenueCat only gives 28-day rolling revenue, so it can differ from a calendar-month bill.",
      "ja": "月次トラッキング売上が $2,500 を超えた分の 1% で推計します。RevenueCat は 28 日ローリングの売上だけなので、暦月の請求とは少しずれます。"
    }
  },
  {
    "key": "gitlab",
    "name": "GitLab",
    "kind": "planAndUsage",
    "status": "pendingVerification",
    "inbox": true,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "企业与自托管 DevSecOps 的主要替代，体量够大但远未撼动 GitHub 默认地位。",
    "searchKeywords": [
      "ci",
      "pipeline",
      "runner",
      "计算分钟",
      "compute minutes",
      "席位",
      "premium",
      "ultimate",
      "duo"
    ],
    "fields": [],
    "steps": [
      {
        "zh": "GitLab 没有公开的账单金额接口。下一步会给你一段任务书，粘给 Claude Code、Cursor 或任何能上网的 AI 写抓取脚本。本月花费以 Customers Portal 或用量配额页为准。",
        "en": "GitLab has no public billing-amount API. Next you’ll get a brief. Paste it into Claude Code, Cursor, or any AI that can reach the web, and have it write a scrape script. Treat the Customers Portal or Usage Quotas page as the source for this month.",
        "ja": "GitLab に公開の請求金額 API はありません。次の画面で依頼文を出します。Claude Code、Cursor、またはネットに出られる AI に貼って、取得スクリプトを書いてもらってください。今月の金額は Customers Portal または用量クォータページを正とします。"
      },
      {
        "zh": "投递 key 单独给你，放进脚本的环境变量。脚本每天跑一次，同一个月重复上报是覆盖。",
        "en": "The ingest key is yours alone. Put it in the script’s environment variables. Run the script once a day. Sending the same month again overwrites.",
        "ja": "投函キーはあなた専用です。スクリプトの環境変数に入れてください。スクリプトは 1 日 1 回。同じ月を再送すると上書きです。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "投递 key 已经被吊销了。",
          "en": "The ingest key has been revoked.",
          "ja": "投函キーはすでに取り消されています。"
        },
        "nextStep": {
          "zh": "去设置 → 读数信箱里再签一把，然后更新你的脚本。",
          "en": "Go to Settings → Inbox and issue a new one, then update your script.",
          "ja": "設定 → 検針ポストで発行し直し、スクリプトを更新してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "投递太频繁了。",
          "en": "You’re delivering too often.",
          "ja": "投函が頻繁すぎます。"
        },
        "nextStep": {
          "zh": "每天跑一次就够。",
          "en": "Once a day is enough.",
          "ja": "1 日 1 回で足ります。"
        },
        "httpStatus": 429
      }
    ],
    "plans": [
      {
        "name": {
          "zh": "Premium（年付·每席位）",
          "en": "Premium (annual, per seat)",
          "ja": "Premium（年払い・席あたり）"
        },
        "amountUSD": "348",
        "period": "annual"
      }
    ],
    "notices": [
      {
        "zh": "GitLab 的公开接口只有计算分钟，没有账单金额。这家走读数信箱：你自己把数字投递进来，App 只负责取回。",
        "en": "GitLab’s public API exposes compute minutes, not billing amounts. This one uses the inbox: you fetch and deliver it; the app only reads it back.",
        "ja": "GitLab の公開 API は計算分だけで、請求金額はありません。このサービスは検針ポストです。自分で取って投函し、App は受け取るだけです。"
      }
    ],
    "guideURLs": [],
    "billingURL": "https://gitlab.com/-/profile/usage_quotas",
    "credentialSetupURL": "https://customers.gitlab.com",
    "summary": {
      "zh": "代码托管和 CI。没有公开账单金额接口，走读数信箱。",
      "en": "Code hosting and CI. There’s no public billing-amount API, so it uses the inbox.",
      "ja": "コードホスティングと CI。公開の請求金額 API はないので、検針ポストを使います。"
    },
    "verifyHint": {
      "zh": "接入之后先显示「等待投递」。脚本第一次上报之后数字才会出来。席位月费可以另加手动订阅。",
      "en": "After connecting, it first shows Waiting for delivery. The number appears after the script reports once. Seat fees can be added as a manual subscription.",
      "ja": "接続した直後は「投函待ち」です。スクリプトが一度報告してから数字が出ます。席料は手動サブスクリプションで足せます。"
    }
  },
  {
    "key": "render",
    "name": "Render",
    "kind": "planAndUsage",
    "status": "pendingVerification",
    "inbox": true,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "全栈 PaaS 里团队会真正选的 Heroku 替代，开发和融资都在加速。",
    "searchKeywords": [
      "paas",
      "部署",
      "deploy",
      "web service"
    ],
    "fields": [],
    "steps": [
      {
        "zh": "Render 没有公开的账单接口。下一步会给你一段任务书，粘给 Claude Code、Cursor 或任何能上网的 AI 写抓取脚本。",
        "en": "Render has no public billing API. Next you’ll get a brief. Paste it into Claude Code, Cursor, or any AI that can reach the web, and have it write a scrape script.",
        "ja": "Render に公開の請求 API はありません。次の画面で依頼文を出します。Claude Code、Cursor、またはネットに出られる AI に貼って、取得スクリプトを書いてもらってください。"
      },
      {
        "zh": "投递 key 单独给你，放进脚本的环境变量。脚本每天跑一次，同一个月重复上报是覆盖。",
        "en": "The ingest key is yours alone. Put it in the script’s environment variables. Run the script once a day. Sending the same month again overwrites.",
        "ja": "投函キーはあなた専用です。スクリプトの環境変数に入れてください。スクリプトは 1 日 1 回。同じ月を再送すると上書きです。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "投递 key 已经被吊销了。",
          "en": "The ingest key has been revoked.",
          "ja": "投函キーはすでに取り消されています。"
        },
        "nextStep": {
          "zh": "去设置 → 读数信箱里再签一把，然后更新你的脚本。",
          "en": "Go to Settings → Inbox and issue a new one, then update your script.",
          "ja": "設定 → 検針ポストで発行し直し、スクリプトを更新してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "投递太频繁了。",
          "en": "You’re delivering too often.",
          "ja": "投函が頻繁すぎます。"
        },
        "nextStep": {
          "zh": "每天跑一次就够。",
          "en": "Once a day is enough.",
          "ja": "1 日 1 回で足ります。"
        },
        "httpStatus": 429
      }
    ],
    "plans": [
      {
        "name": {
          "zh": "Render Professional（每席位）",
          "en": "Render Professional (per seat)",
          "ja": "Render Professional（席あたり）"
        },
        "amountUSD": "19",
        "period": "monthly"
      }
    ],
    "notices": [
      {
        "zh": "Render 的 API 没有任何账单端点。这家走读数信箱：你自己把数字投递进来，App 只负责取回。",
        "en": "Render’s API has no billing endpoint. This one uses the inbox: you fetch and deliver it; the app only reads it back.",
        "ja": "Render の API に請求エンドポイントはありません。このサービスは検針ポストです。自分で取って投函し、App は受け取るだけです。"
      }
    ],
    "guideURLs": [],
    "billingURL": "https://dashboard.render.com/billing",
    "credentialSetupURL": "https://dashboard.render.com/u/settings",
    "summary": {
      "zh": "应用托管。没有公开账单接口，走读数信箱。",
      "en": "App hosting. There’s no public billing API, so it uses the inbox.",
      "ja": "アプリホスティング。公開の請求 API はないので、検針ポストを使います。"
    },
    "verifyHint": {
      "zh": "接入之后先显示「等待投递」。等你的脚本第一次上报，数字才会出来。",
      "en": "After connecting, it first shows Waiting for delivery. The number appears after your script reports once.",
      "ja": "接続した直後は「投函待ち」です。スクリプトが一度報告してから数字が出ます。"
    }
  },
  {
    "key": "qdrant",
    "name": "Qdrant Cloud",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "开源向量库里增长最快的挑战者，下载与 GitHub 热度已超过 Weaviate。",
    "searchKeywords": [
      "vector",
      "向量",
      "embedding",
      "rag"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "Cloud Management Key",
          "en": "Cloud Management Key",
          "ja": "Cloud Management Key"
        },
        "isSecret": true,
        "hint": {
          "zh": "Access Management 页面",
          "en": "Access Management page",
          "ja": "Access Management ページ"
        },
        "validation": {
          "zh": "Management key 太短，确认复制完整",
          "en": "Management key is too short. Make sure you copied the whole thing.",
          "ja": "Management key が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Qdrant Cloud 的 Access Management → Cloud Management Keys，新建一把。权限勾 read:payment_information。周期刚开始还没生成草稿时会显示读不到数。",
        "en": "Open Qdrant Cloud Access Management → Cloud Management Keys and create one. Check read:payment_information. Right after a cycle starts, a missing draft invoice shows as no reading yet.",
        "ja": "Qdrant Cloud の Access Management → Cloud Management Keys を開き、新規作成します。権限は read:payment_information。周期の直後で下書きがまだないと「読めない」と出ます。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "Management key 无效。",
          "en": "Management key is invalid.",
          "ja": "Management key は無効です。"
        },
        "nextStep": {
          "zh": "回 Access Management 重建一把。",
          "en": "Go back to Access Management and create a new one.",
          "ja": "Access Management に戻って作り直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 key 缺 read:payment_information。",
          "en": "This key is missing read:payment_information.",
          "ja": "この key に read:payment_information がありません。"
        },
        "nextStep": {
          "zh": "回上一步重建，勾上这条权限。",
          "en": "Go back a step and recreate it with this permission checked.",
          "ja": "前の手順に戻して作り直し、この権限にチェックを入れてください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [
      {
        "name": {
          "zh": "Qdrant Cloud Standard 起步",
          "en": "Qdrant Cloud Standard starting at",
          "ja": "Qdrant Cloud Standard スタート"
        },
        "amountUSD": "25",
        "period": "monthly"
      }
    ],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://cloud.qdrant.io/billing",
    "credentialSetupURL": "https://cloud.qdrant.io/access-management",
    "summary": {
      "zh": "向量数据库云服务。按当期草稿发票。",
      "en": "A managed vector database. The current draft invoice.",
      "ja": "ベクトルデータベースのクラウド。当期の下書きインボイスです。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 Qdrant Cloud 后台 Billing 页当期那张草稿发票一致。",
      "en": "This number should match the current draft invoice on the Qdrant Cloud Billing page.",
      "ja": "この数字は Qdrant Cloud 管理画面 Billing の当期下書きインボイスと一致するはずです。"
    }
  },
  {
    "key": "expo",
    "name": "Expo EAS",
    "kind": "planAndUsage",
    "status": "pendingVerification",
    "inbox": true,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "在 React Native 云构建这一细分里已是默认流水线，EAS Build/Submit 覆盖大多数团队。",
    "searchKeywords": [
      "react native",
      "rn",
      "eas build",
      "eas update",
      "打包"
    ],
    "fields": [],
    "steps": [
      {
        "zh": "Expo EAS 没有公开的账单接口。下一步会给你一段任务书，粘给 Claude Code、Cursor 或任何能上网的 AI 写抓取脚本。命令行 eas account:usage --json 也能拿到同一份数。",
        "en": "Expo EAS has no public billing API. Next you’ll get a brief. Paste it into Claude Code, Cursor, or any AI that can reach the web, and have it write a scrape script. The CLI command eas account:usage --json returns the same numbers.",
        "ja": "Expo EAS に公開の請求 API はありません。次の画面で依頼文を出します。Claude Code、Cursor、またはネットに出られる AI に貼って、取得スクリプトを書いてもらってください。コマンドラインの eas account:usage --json でも同じ数字を取れます。"
      },
      {
        "zh": "投递 key 单独给你，放进脚本的环境变量。脚本每天跑一次，同一个月重复上报是覆盖。",
        "en": "The ingest key is yours alone. Put it in the script’s environment variables. Run the script once a day. Sending the same month again overwrites.",
        "ja": "投函キーはあなた専用です。スクリプトの環境変数に入れてください。スクリプトは 1 日 1 回。同じ月を再送すると上書きです。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "投递 key 已经被吊销了。",
          "en": "The ingest key has been revoked.",
          "ja": "投函キーはすでに取り消されています。"
        },
        "nextStep": {
          "zh": "去设置 → 读数信箱里再签一把，然后更新你的脚本。",
          "en": "Go to Settings → Inbox and issue a new one, then update your script.",
          "ja": "設定 → 検針ポストで発行し直し、スクリプトを更新してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "投递太频繁了。",
          "en": "You’re delivering too often.",
          "ja": "投函が頻繁すぎます。"
        },
        "nextStep": {
          "zh": "每天跑一次就够。",
          "en": "Once a day is enough.",
          "ja": "1 日 1 回で足ります。"
        },
        "httpStatus": 429
      }
    ],
    "plans": [
      {
        "name": {
          "zh": "Expo Production",
          "en": "Expo Production",
          "ja": "Expo Production"
        },
        "amountUSD": "99",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Expo Starter",
          "en": "Expo Starter",
          "ja": "Expo Starter"
        },
        "amountUSD": "19",
        "period": "monthly"
      }
    ],
    "notices": [
      {
        "zh": "Expo 的用量只在未公开的 GraphQL 上。这家走读数信箱：你自己把数字投递进来，命令行 eas account:usage --json 一条命令就能拿到。",
        "en": "Expo usage only exists on an unpublished GraphQL API. This one uses the inbox: you fetch and deliver it. eas account:usage --json is a ready-made way to get the numbers.",
        "ja": "Expo の用量は非公開の GraphQL にしかありません。このサービスは検針ポストです。自分で取って投函します。eas account:usage --json がそのまま使えます。"
      }
    ],
    "guideURLs": [],
    "billingURL": "https://expo.dev/settings/billing",
    "credentialSetupURL": "https://expo.dev/settings/access-tokens",
    "summary": {
      "zh": "React Native 的构建和更新。没有公开账单接口，走读数信箱。",
      "en": "React Native builds and updates. There’s no public billing API, so it uses the inbox.",
      "ja": "React Native のビルドと更新。公開の請求 API はないので、検針ポストを使います。"
    },
    "verifyHint": {
      "zh": "接入之后先显示「等待投递」。脚本第一次上报之后数字才会出来。",
      "en": "After connecting, it first shows Waiting for delivery. The number appears after the script reports once.",
      "ja": "接続した直後は「投函待ち」です。スクリプトが一度報告してから数字が出ます。"
    }
  },
  {
    "key": "groq",
    "name": "Groq",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "LPU 低延迟品牌仍在，但核心芯片与创始团队已被英伟达买走，现为重建中的推理云挑战者。",
    "searchKeywords": [
      "groq cloud",
      "llama",
      "inference"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "公开文档只有控制台 Usage，没有账单金额接口。"
  },
  {
    "key": "together",
    "name": "Together AI",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "开源模型 GPU 推理云寡头之一，年预订已过十亿美元。",
    "searchKeywords": [
      "together.ai",
      "togetherai",
      "billing usage",
      "USD",
      "metronome"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Together AI 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Together AI dashboard, create API Key, then copy it.",
        "ja": "Together AI ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://api.together.ai/settings/billing",
    "credentialSetupURL": "https://docs.together.ai/reference/billing-usage",
    "summary": {
      "zh": "开源模型推理。按本月组织用量花费。",
      "en": "Open-source model inference. This month’s organization usage spend.",
      "ja": "オープンソースモデルの推論。今月の組織用量支出です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "replicate",
    "name": "Replicate",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "社区模型托管被 Cloudflare 低价收购，已失去独立地位，输给 fal 等媒体推理云。",
    "searchKeywords": [
      "replicate.com",
      "predictions"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "公开 OpenAPI 只有预测和部署，没有账单金额。"
  },
  {
    "key": "perplexity",
    "name": "Perplexity",
    "kind": "prepaid",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "消费级 AI 搜索的最强挑战者，搜索总盘仍由 Google 垄断。",
    "searchKeywords": [
      "sonar",
      "pplx",
      "perplexity.ai"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "API 平台预充值只在控制台，公开接口不给余额或本月花费。"
  },
  {
    "key": "cohere",
    "name": "Cohere",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "企业 RAG 与私有化部署的稳定挑战者，规模小于三巨头和 Mistral。",
    "searchKeywords": [
      "command",
      "cohere.ai"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "公开 API 没有账单金额。"
  },
  {
    "key": "gemini",
    "name": "Google Gemini",
    "kind": "prepaid",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "企业份额约两成、消费端约三成，与 OpenAI、Anthropic 构成全球前沿 API 寡头。",
    "searchKeywords": [
      "gemini",
      "ai studio",
      "google ai",
      "bard",
      "aistudio"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "Gemini API / AI Studio 没有给 API key 的账单接口。金额在 Cloud Billing，那是另一家。"
  },
  {
    "key": "midjourney",
    "name": "Midjourney",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "付费 AI 绘图的品类象征，自举且盈利，仍是图像生成独立品牌的寡头。",
    "searchKeywords": [
      "mj",
      "mid journey"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [
      {
        "name": {
          "zh": "Basic",
          "en": "Basic",
          "ja": "Basic"
        },
        "amountUSD": "10",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Basic（年付）",
          "en": "Basic (annual)",
          "ja": "Basic（年払い）"
        },
        "amountUSD": "96",
        "period": "annual"
      },
      {
        "name": {
          "zh": "Standard",
          "en": "Standard",
          "ja": "Standard"
        },
        "amountUSD": "30",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Standard（年付）",
          "en": "Standard (annual)",
          "ja": "Standard（年払い）"
        },
        "amountUSD": "288",
        "period": "annual"
      },
      {
        "name": {
          "zh": "Pro",
          "en": "Pro",
          "ja": "Pro"
        },
        "amountUSD": "60",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Pro（年付）",
          "en": "Pro (annual)",
          "ja": "Pro（年払い）"
        },
        "amountUSD": "576",
        "period": "annual"
      },
      {
        "name": {
          "zh": "Mega",
          "en": "Mega",
          "ja": "Mega"
        },
        "amountUSD": "120",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Mega（年付）",
          "en": "Mega (annual)",
          "ja": "Mega（年払い）"
        },
        "amountUSD": "1152",
        "period": "annual"
      }
    ],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开 API，只能网页订阅。"
  },
  {
    "key": "runway",
    "name": "Runway",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "专业 AI 视频工具在中市场采购与支出上明显领先同类。",
    "searchKeywords": [
      "runwayml",
      "gen-3",
      "gen-4",
      "video"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "netlify",
    "name": "Netlify",
    "kind": "planAndUsage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "Jamstack 开创者持续丢份额与心智，融资停在 2021，正在被 Vercel 替换为默认选项。",
    "searchKeywords": [
      "jamstack",
      "netlify.com"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [
      {
        "name": {
          "zh": "Netlify Pro（每席位）",
          "en": "Netlify Pro (per seat)",
          "ja": "Netlify Pro（席あたり）"
        },
        "amountUSD": "19",
        "period": "monthly"
      }
    ],
    "notices": [],
    "guideURLs": [],
    "declineReason": "公开 API 只有付款方式，没有发票金额。"
  },
  {
    "key": "supabase",
    "name": "Supabase",
    "kind": "planAndUsage",
    "status": "pendingVerification",
    "inbox": true,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "开源 Postgres BaaS 已与 Firebase 对分开发者后端，并成为 vibe-coding 默认库。",
    "searchKeywords": [
      "postgres",
      "postgresql",
      "database",
      "数据库",
      "baas"
    ],
    "fields": [],
    "steps": [
      {
        "zh": "Supabase 的 Management API 没有账单金额。下一步会给你一段任务书，粘给 Claude Code、Cursor 或任何能上网的 AI 写抓取脚本。本月花费以控制台 Billing 页为准。",
        "en": "Supabase’s Management API has no billed amount. Next you’ll get a brief. Paste it into Claude Code, Cursor, or any AI that can reach the web, and have it write a scrape script. Treat the dashboard Billing page as the source for this month.",
        "ja": "Supabase の Management API に請求金額はありません。次の画面で依頼文を出します。Claude Code、Cursor、またはネットに出られる AI に貼って、取得スクリプトを書いてもらってください。今月の金額はダッシュボードの Billing ページを正とします。"
      },
      {
        "zh": "投递 key 单独给你，放进脚本的环境变量。脚本每天跑一次，同一个月重复上报是覆盖。",
        "en": "The ingest key is yours alone. Put it in the script’s environment variables. Run the script once a day. Sending the same month again overwrites.",
        "ja": "投函キーはあなた専用です。スクリプトの環境変数に入れてください。スクリプトは 1 日 1 回。同じ月を再送すると上書きです。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "投递 key 已经被吊销了。",
          "en": "The ingest key has been revoked.",
          "ja": "投函キーはすでに取り消されています。"
        },
        "nextStep": {
          "zh": "去设置 → 读数信箱里再签一把，然后更新你的脚本。",
          "en": "Go to Settings → Inbox and issue a new one, then update your script.",
          "ja": "設定 → 検針ポストで発行し直し、スクリプトを更新してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "投递太频繁了。",
          "en": "You’re delivering too often.",
          "ja": "投函が頻繁すぎます。"
        },
        "nextStep": {
          "zh": "每天跑一次就够。",
          "en": "Once a day is enough.",
          "ja": "1 日 1 回で足ります。"
        },
        "httpStatus": 429
      }
    ],
    "plans": [
      {
        "name": {
          "zh": "Supabase Pro",
          "en": "Supabase Pro",
          "ja": "Supabase Pro"
        },
        "amountUSD": "25",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Supabase Team",
          "en": "Supabase Team",
          "ja": "Supabase Team"
        },
        "amountUSD": "599",
        "period": "monthly"
      }
    ],
    "notices": [
      {
        "zh": "Supabase 的 Management API 没有账单金额。这家走读数信箱。Pro / Team 固定月费走手动订阅，计算实例超额仍以控制台为准。",
        "en": "Supabase’s Management API has no billed amount. This one uses the inbox. Pro / Team monthly fees go in as a manual subscription. Compute overage still follows the dashboard.",
        "ja": "Supabase の Management API に請求金額はありません。このサービスは検針ポストです。Pro / Team の月額は手動サブスクリプション、計算インスタンスの超過はダッシュボードを正とします。"
      }
    ],
    "guideURLs": [],
    "billingURL": "https://supabase.com/dashboard/org/_/billing",
    "credentialSetupURL": "https://supabase.com/dashboard/account/tokens",
    "summary": {
      "zh": "Postgres 后端。没有公开账单金额接口，走读数信箱。",
      "en": "A Postgres backend. There’s no public billed-amount API, so it uses the inbox.",
      "ja": "Postgres バックエンド。公開の請求金額 API はないので、検針ポストを使います。"
    },
    "verifyHint": {
      "zh": "接入之后先显示「等待投递」。脚本第一次上报之后数字才会出来。",
      "en": "After connecting, it first shows Waiting for delivery. The number appears after the script reports once.",
      "ja": "接続した直後は「投函待ち」です。スクリプトが一度報告してから数字が出ます。"
    }
  },
  {
    "key": "firebase",
    "name": "Firebase",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "移动 BaaS 仍由 Firebase 以数量级优势坐庄，Supabase 是挑战者而非对等寡头。",
    "searchKeywords": [
      "firestore",
      "fcm",
      "google"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "账单走 Google Cloud Billing，没有独立的 Firebase 账单接口。"
  },
  {
    "key": "linear",
    "name": "Linear",
    "kind": "subscription",
    "status": "pendingVerification",
    "inbox": true,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "工程师问题跟踪里增长最快的 Jira 挑战者，已过亿美元 ARR 且现金流为正。",
    "searchKeywords": [
      "linear.app",
      "issue",
      "项目管理"
    ],
    "fields": [],
    "steps": [
      {
        "zh": "Linear 没有公开的账单接口。下一步会给你一段任务书，粘给 Claude Code、Cursor 或任何能上网的 AI 写抓取脚本。本月花费以 Settings 里的 Plans 为准。",
        "en": "Linear has no public billing API. Next you’ll get a brief. Paste it into Claude Code, Cursor, or any AI that can reach the web, and have it write a scrape script. Treat Plans in Settings as the source for this month.",
        "ja": "Linear に公開の請求 API はありません。次の画面で依頼文を出します。Claude Code、Cursor、またはネットに出られる AI に貼って、取得スクリプトを書いてもらってください。今月の金額は Settings の Plans を正とします。"
      },
      {
        "zh": "投递 key 单独给你，放进脚本的环境变量。脚本每天跑一次，同一个月重复上报是覆盖。",
        "en": "The ingest key is yours alone. Put it in the script’s environment variables. Run the script once a day. Sending the same month again overwrites.",
        "ja": "投函キーはあなた専用です。スクリプトの環境変数に入れてください。スクリプトは 1 日 1 回。同じ月を再送すると上書きです。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "投递 key 已经被吊销了。",
          "en": "The ingest key has been revoked.",
          "ja": "投函キーはすでに取り消されています。"
        },
        "nextStep": {
          "zh": "去设置 → 读数信箱里再签一把，然后更新你的脚本。",
          "en": "Go to Settings → Inbox and issue a new one, then update your script.",
          "ja": "設定 → 検針ポストで発行し直し、スクリプトを更新してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "投递太频繁了。",
          "en": "You’re delivering too often.",
          "ja": "投函が頻繁すぎます。"
        },
        "nextStep": {
          "zh": "每天跑一次就够。",
          "en": "Once a day is enough.",
          "ja": "1 日 1 回で足ります。"
        },
        "httpStatus": 429
      }
    ],
    "plans": [
      {
        "name": {
          "zh": "Linear Basic（年付·每席位）",
          "en": "Linear Basic (annual, per seat)",
          "ja": "Linear Basic（年払い・席あたり）"
        },
        "amountUSD": "120",
        "period": "annual"
      },
      {
        "name": {
          "zh": "Linear Business（年付·每席位）",
          "en": "Linear Business (annual, per seat)",
          "ja": "Linear Business（年払い・席あたり）"
        },
        "amountUSD": "192",
        "period": "annual"
      }
    ],
    "notices": [
      {
        "zh": "Linear 没有公开账单接口。这家走读数信箱。Basic / Business 固定席位费走手动订阅。",
        "en": "Linear has no public billing API. This one uses the inbox. Basic / Business seat fees go in as a manual subscription.",
        "ja": "Linear に公開の請求 API はありません。このサービスは検針ポストです。Basic / Business の席料は手動サブスクリプションです。"
      }
    ],
    "guideURLs": [],
    "billingURL": "https://linear.app/settings/plans",
    "credentialSetupURL": "https://linear.app/settings/api",
    "summary": {
      "zh": "项目管理。没有公开账单接口，走读数信箱。",
      "en": "Project management. There’s no public billing API, so it uses the inbox.",
      "ja": "プロジェクト管理。公開の請求 API はないので、検針ポストを使います。"
    },
    "verifyHint": {
      "zh": "接入之后先显示「等待投递」。脚本第一次上报之后数字才会出来。",
      "en": "After connecting, it first shows Waiting for delivery. The number appears after the script reports once.",
      "ja": "接続した直後は「投函待ち」です。スクリプトが一度報告してから数字が出ます。"
    }
  },
  {
    "key": "notion",
    "name": "Notion",
    "kind": "subscription",
    "status": "pendingVerification",
    "inbox": true,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "知识库/工作区的强挑战者，收入已近十亿美元但仍面对 Google/Confluence。",
    "searchKeywords": [
      "notion.so",
      "wiki",
      "docs"
    ],
    "fields": [],
    "steps": [
      {
        "zh": "Notion 没有公开的账单接口。下一步会给你一段任务书，粘给 Claude Code、Cursor 或任何能上网的 AI 写抓取脚本。本月花费以 Settings 里的 Billing 为准。",
        "en": "Notion has no public billing API. Next you’ll get a brief. Paste it into Claude Code, Cursor, or any AI that can reach the web, and have it write a scrape script. Treat Billing in Settings as the source for this month.",
        "ja": "Notion に公開の請求 API はありません。次の画面で依頼文を出します。Claude Code、Cursor、またはネットに出られる AI に貼って、取得スクリプトを書いてもらってください。今月の金額は Settings の Billing を正とします。"
      },
      {
        "zh": "投递 key 单独给你，放进脚本的环境变量。脚本每天跑一次，同一个月重复上报是覆盖。",
        "en": "The ingest key is yours alone. Put it in the script’s environment variables. Run the script once a day. Sending the same month again overwrites.",
        "ja": "投函キーはあなた専用です。スクリプトの環境変数に入れてください。スクリプトは 1 日 1 回。同じ月を再送すると上書きです。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "投递 key 已经被吊销了。",
          "en": "The ingest key has been revoked.",
          "ja": "投函キーはすでに取り消されています。"
        },
        "nextStep": {
          "zh": "去设置 → 读数信箱里再签一把，然后更新你的脚本。",
          "en": "Go to Settings → Inbox and issue a new one, then update your script.",
          "ja": "設定 → 検針ポストで発行し直し、スクリプトを更新してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "投递太频繁了。",
          "en": "You’re delivering too often.",
          "ja": "投函が頻繁すぎます。"
        },
        "nextStep": {
          "zh": "每天跑一次就够。",
          "en": "Once a day is enough.",
          "ja": "1 日 1 回で足ります。"
        },
        "httpStatus": 429
      }
    ],
    "plans": [
      {
        "name": {
          "zh": "Notion Plus（每席位）",
          "en": "Notion Plus (per seat)",
          "ja": "Notion Plus（席あたり）"
        },
        "amountUSD": "12",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Notion Plus（年付·每席位）",
          "en": "Notion Plus (annual, per seat)",
          "ja": "Notion Plus（年払い・席あたり）"
        },
        "amountUSD": "120",
        "period": "annual"
      },
      {
        "name": {
          "zh": "Notion Business（每席位）",
          "en": "Notion Business (per seat)",
          "ja": "Notion Business（席あたり）"
        },
        "amountUSD": "24",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Notion Business（年付·每席位）",
          "en": "Notion Business (annual, per seat)",
          "ja": "Notion Business（年払い・席あたり）"
        },
        "amountUSD": "240",
        "period": "annual"
      }
    ],
    "notices": [
      {
        "zh": "Notion 没有公开账单接口。这家走读数信箱。Plus / Business 固定席位费走手动订阅。",
        "en": "Notion has no public billing API. This one uses the inbox. Plus / Business seat fees go in as a manual subscription.",
        "ja": "Notion に公開の請求 API はありません。このサービスは検針ポストです。Plus / Business の席料は手動サブスクリプションです。"
      }
    ],
    "guideURLs": [],
    "billingURL": "https://www.notion.so/profile",
    "credentialSetupURL": "https://www.notion.so/my-integrations",
    "summary": {
      "zh": "文档和知识库。没有公开账单接口，走读数信箱。",
      "en": "Docs and a knowledge base. There’s no public billing API, so it uses the inbox.",
      "ja": "ドキュメントとナレッジベース。公開の請求 API はないので、検針ポストを使います。"
    },
    "verifyHint": {
      "zh": "接入之后先显示「等待投递」。脚本第一次上报之后数字才会出来。",
      "en": "After connecting, it first shows Waiting for delivery. The number appears after the script reports once.",
      "ja": "接続した直後は「投函待ち」です。スクリプトが一度報告してから数字が出ます。"
    }
  },
  {
    "key": "figma",
    "name": "Figma",
    "kind": "subscription",
    "status": "pendingVerification",
    "inbox": true,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "协作 UI 设计的事实标准，收入已过十亿美元且独立上市。",
    "searchKeywords": [
      "figma.com",
      "design",
      "设计"
    ],
    "fields": [],
    "steps": [
      {
        "zh": "Figma 没有公开的账单接口。下一步会给你一段任务书，粘给 Claude Code、Cursor 或任何能上网的 AI 写抓取脚本。本月花费以控制台 Billing 为准。",
        "en": "Figma has no public billing API. Next you’ll get a brief. Paste it into Claude Code, Cursor, or any AI that can reach the web, and have it write a scrape script. Treat the dashboard Billing page as the source for this month.",
        "ja": "Figma に公開の請求 API はありません。次の画面で依頼文を出します。Claude Code、Cursor、またはネットに出られる AI に貼って、取得スクリプトを書いてもらってください。今月の金額はダッシュボードの Billing を正とします。"
      },
      {
        "zh": "投递 key 单独给你，放进脚本的环境变量。脚本每天跑一次，同一个月重复上报是覆盖。",
        "en": "The ingest key is yours alone. Put it in the script’s environment variables. Run the script once a day. Sending the same month again overwrites.",
        "ja": "投函キーはあなた専用です。スクリプトの環境変数に入れてください。スクリプトは 1 日 1 回。同じ月を再送すると上書きです。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "投递 key 已经被吊销了。",
          "en": "The ingest key has been revoked.",
          "ja": "投函キーはすでに取り消されています。"
        },
        "nextStep": {
          "zh": "去设置 → 读数信箱里再签一把，然后更新你的脚本。",
          "en": "Go to Settings → Inbox and issue a new one, then update your script.",
          "ja": "設定 → 検針ポストで発行し直し、スクリプトを更新してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "投递太频繁了。",
          "en": "You’re delivering too often.",
          "ja": "投函が頻繁すぎます。"
        },
        "nextStep": {
          "zh": "每天跑一次就够。",
          "en": "Once a day is enough.",
          "ja": "1 日 1 回で足ります。"
        },
        "httpStatus": 429
      }
    ],
    "plans": [
      {
        "name": {
          "zh": "Figma Professional Full（每席位）",
          "en": "Figma Professional Full (per seat)",
          "ja": "Figma Professional Full（席あたり）"
        },
        "amountUSD": "16",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Figma Professional Full（年付·每席位）",
          "en": "Figma Professional Full (annual, per seat)",
          "ja": "Figma Professional Full（年払い・席あたり）"
        },
        "amountUSD": "192",
        "period": "annual"
      },
      {
        "name": {
          "zh": "Figma Professional Dev（每席位）",
          "en": "Figma Professional Dev (per seat)",
          "ja": "Figma Professional Dev（席あたり）"
        },
        "amountUSD": "12",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Figma Professional Dev（年付·每席位）",
          "en": "Figma Professional Dev (annual, per seat)",
          "ja": "Figma Professional Dev（年払い・席あたり）"
        },
        "amountUSD": "144",
        "period": "annual"
      },
      {
        "name": {
          "zh": "Figma Professional Collab（每席位）",
          "en": "Figma Professional Collab (per seat)",
          "ja": "Figma Professional Collab（席あたり）"
        },
        "amountUSD": "3",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Figma Professional Collab（年付·每席位）",
          "en": "Figma Professional Collab (annual, per seat)",
          "ja": "Figma Professional Collab（年払い・席あたり）"
        },
        "amountUSD": "36",
        "period": "annual"
      },
      {
        "name": {
          "zh": "Figma Organization Full（年付·每席位）",
          "en": "Figma Organization Full (annual, per seat)",
          "ja": "Figma Organization Full（年払い・席あたり）"
        },
        "amountUSD": "660",
        "period": "annual"
      },
      {
        "name": {
          "zh": "Figma Organization Dev（年付·每席位）",
          "en": "Figma Organization Dev (annual, per seat)",
          "ja": "Figma Organization Dev（年払い・席あたり）"
        },
        "amountUSD": "300",
        "period": "annual"
      },
      {
        "name": {
          "zh": "Figma Organization Collab（年付·每席位）",
          "en": "Figma Organization Collab (annual, per seat)",
          "ja": "Figma Organization Collab（年払い・席あたり）"
        },
        "amountUSD": "60",
        "period": "annual"
      }
    ],
    "notices": [
      {
        "zh": "Figma 没有公开账单接口。这家走读数信箱。Professional / Organization 固定席位费走手动订阅。",
        "en": "Figma has no public billing API. This one uses the inbox. Professional / Organization seat fees go in as a manual subscription.",
        "ja": "Figma に公開の請求 API はありません。このサービスは検針ポストです。Professional / Organization の席料は手動サブスクリプションです。"
      }
    ],
    "guideURLs": [],
    "billingURL": "https://www.figma.com/settings",
    "credentialSetupURL": "https://help.figma.com/hc/en-us/articles/360039811114-Manage-your-plan",
    "summary": {
      "zh": "界面设计。没有公开账单接口，走读数信箱。",
      "en": "Interface design. There’s no public billing API, so it uses the inbox.",
      "ja": "UI デザイン。公開の請求 API はないので、検針ポストを使います。"
    },
    "verifyHint": {
      "zh": "接入之后先显示「等待投递」。脚本第一次上报之后数字才会出来。",
      "en": "After connecting, it first shows Waiting for delivery. The number appears after the script reports once.",
      "ja": "接続した直後は「投函待ち」です。スクリプトが一度報告してから数字が出ます。"
    }
  },
  {
    "key": "slack",
    "name": "Slack",
    "kind": "subscription",
    "status": "pendingVerification",
    "inbox": true,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "科技公司团队聊天的付费寡头，与捆绑销售的 Teams 二分市场。",
    "searchKeywords": [
      "slack.com",
      "聊天"
    ],
    "fields": [],
    "steps": [
      {
        "zh": "Slack 没有公开的工作区账单接口。下一步会给你一段任务书，粘给 Claude Code、Cursor 或任何能上网的 AI 写抓取脚本。本月花费以控制台 Billing 页为准。",
        "en": "Slack has no public workspace billing API. Next you’ll get a brief. Paste it into Claude Code, Cursor, or any AI that can reach the web, and have it write a scrape script. Treat the dashboard Billing page as the source for this month.",
        "ja": "Slack に公開のワークスペース請求 API はありません。次の画面で依頼文を出します。Claude Code、Cursor、またはネットに出られる AI に貼って、取得スクリプトを書いてもらってください。今月の金額はダッシュボードの Billing ページを正とします。"
      },
      {
        "zh": "投递 key 单独给你，放进脚本的环境变量。脚本每天跑一次，同一个月重复上报是覆盖。",
        "en": "The ingest key is yours alone. Put it in the script’s environment variables. Run the script once a day. Sending the same month again overwrites.",
        "ja": "投函キーはあなた専用です。スクリプトの環境変数に入れてください。スクリプトは 1 日 1 回。同じ月を再送すると上書きです。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "投递 key 已经被吊销了。",
          "en": "The ingest key has been revoked.",
          "ja": "投函キーはすでに取り消されています。"
        },
        "nextStep": {
          "zh": "去设置 → 读数信箱里再签一把，然后更新你的脚本。",
          "en": "Go to Settings → Inbox and issue a new one, then update your script.",
          "ja": "設定 → 検針ポストで発行し直し、スクリプトを更新してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "投递太频繁了。",
          "en": "You’re delivering too often.",
          "ja": "投函が頻繁すぎます。"
        },
        "nextStep": {
          "zh": "每天跑一次就够。",
          "en": "Once a day is enough.",
          "ja": "1 日 1 回で足ります。"
        },
        "httpStatus": 429
      }
    ],
    "plans": [
      {
        "name": {
          "zh": "Slack Pro（每席位）",
          "en": "Slack Pro (per seat)",
          "ja": "Slack Pro（席あたり）"
        },
        "amountUSD": "8.75",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Slack Pro（年付·每席位）",
          "en": "Slack Pro (annual, per seat)",
          "ja": "Slack Pro（年払い・席あたり）"
        },
        "amountUSD": "87",
        "period": "annual"
      },
      {
        "name": {
          "zh": "Slack Business+（每席位）",
          "en": "Slack Business+ (per seat)",
          "ja": "Slack Business+（席あたり）"
        },
        "amountUSD": "18",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Slack Business+（年付·每席位）",
          "en": "Slack Business+ (annual, per seat)",
          "ja": "Slack Business+（年払い・席あたり）"
        },
        "amountUSD": "180",
        "period": "annual"
      }
    ],
    "notices": [
      {
        "zh": "Slack 没有公开工作区账单接口。这家走读数信箱。Pro / Business+ 固定席位费走手动订阅。",
        "en": "Slack has no public workspace billing API. This one uses the inbox. Pro / Business+ seat fees go in as a manual subscription.",
        "ja": "Slack に公開のワークスペース請求 API はありません。このサービスは検針ポストです。Pro / Business+ の席料は手動サブスクリプションです。"
      }
    ],
    "guideURLs": [],
    "billingURL": "https://my.slack.com/admin/billing",
    "credentialSetupURL": "https://slack.com/help/articles/218915077-Manage-your-Slack-plan",
    "summary": {
      "zh": "团队聊天。没有公开工作区账单接口，走读数信箱。",
      "en": "Team chat. There’s no public workspace billing API, so it uses the inbox.",
      "ja": "チームチャット。公開のワークスペース請求 API はないので、検針ポストを使います。"
    },
    "verifyHint": {
      "zh": "接入之后先显示「等待投递」。脚本第一次上报之后数字才会出来。",
      "en": "After connecting, it first shows Waiting for delivery. The number appears after the script reports once.",
      "ja": "接続した直後は「投函待ち」です。スクリプトが一度報告してから数字が出ます。"
    }
  },
  {
    "key": "windsurf",
    "name": "Windsurf",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "创始团队被谷歌挖走、产品被 Cognition 低价收编，职场份额个位数且下滑。",
    "searchKeywords": [
      "codeium",
      "cascade",
      "ide",
      "编辑器"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [
      {
        "name": {
          "zh": "Windsurf Pro",
          "en": "Windsurf Pro",
          "ja": "Windsurf Pro"
        },
        "amountUSD": "15",
        "period": "monthly"
      }
    ],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单接口。"
  },
  {
    "key": "mistral",
    "name": "Mistral",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "欧洲主权与私有化部署的主要独立挑战者，收入已到数亿美元但未进入全球支出寡头。",
    "searchKeywords": [
      "mistral ai",
      "mixtral",
      "le chat",
      "codestral"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "Admin API Key",
          "en": "Admin API Key",
          "ja": "Admin API Key"
        },
        "isSecret": true,
        "hint": {
          "zh": "Backoffice 签发，不是推理用的那把",
          "en": "Issued in Backoffice, not the inference key",
          "ja": "Backoffice で発行したもので、推論用の key ではありません"
        },
        "validation": {
          "zh": "Admin API Key 太短，确认复制完整",
          "en": "Admin API Key is too short. Make sure you copied the whole thing.",
          "ja": "Admin API Key が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Mistral Backoffice 的 API keys，给这个组织签发一把 Admin API Key。普通推理 key 读不到账单。接口还在 Preview，数字以控制台为准。",
        "en": "Open API keys in Mistral Backoffice and issue an Admin API Key for this organization. A regular inference key can’t read billing. The API is still Preview, so trust the dashboard.",
        "ja": "Mistral Backoffice の API keys を開き、この組織に Admin API Key を発行します。通常の推論 key では請求を読めません。API はまだ Preview なので、数字はダッシュボードを正とします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "Admin API Key 无效。",
          "en": "Admin API Key is invalid.",
          "ja": "Admin API Key は無効です。"
        },
        "nextStep": {
          "zh": "回 Backoffice 重新签发一把。",
          "en": "Go back to Backoffice and issue a new one.",
          "ja": "Backoffice に戻って発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 key 不是 Admin API Key，或者组织没有 Enterprise Admin API。",
          "en": "This key isn’t an Admin API Key, or the org has no Enterprise Admin API.",
          "ja": "この key は Admin API Key ではないか、組織に Enterprise Admin API がありません。"
        },
        "nextStep": {
          "zh": "确认走的是 Backoffice 的 Admin API Key，不是 Studio 里的推理 key。",
          "en": "Confirm it’s a Backoffice Admin API Key, not a Studio inference key.",
          "ja": "Studio の推論 key ではなく Backoffice の Admin API Key か確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://admin.mistral.ai",
    "credentialSetupURL": "https://backoffice.mistral.ai",
    "summary": {
      "zh": "Mistral 模型 API。Admin API 读本月各品类花费，只对 Enterprise 组织开放。",
      "en": "Mistral model API. The Admin API reads this month’s spend by category, and only for Enterprise orgs.",
      "ja": "Mistral モデル API。Admin API が今月の品目別支出を読みます。Enterprise 組織だけです。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 Admin Panel 的 Usage 页本月合计一致。个人账号没有 Admin API，对不上就先别保存。",
      "en": "This number should match this month’s total on the Admin Panel Usage page. Personal accounts have no Admin API. If it doesn’t match, don’t save yet.",
      "ja": "この数字は Admin Panel の Usage ページの今月合計と一致するはずです。個人アカウントに Admin API はありません。合わなければ、まだ保存しないでください。"
    }
  },
  {
    "key": "fireworks",
    "name": "Fireworks",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "生产级开源推理收入已过十亿美元，与 Together 分食该市场。",
    "searchKeywords": [
      "fireworks.ai",
      "fireworks ai",
      "inference"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true,
        "validation": {
          "zh": "API Key 太短，确认复制完整",
          "en": "API Key is too short. Make sure you copied the whole thing.",
          "ja": "API Key が短すぎます。全部コピーできているか確認してください。"
        }
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Account ID",
          "en": "Account ID",
          "ja": "Account ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台 URL 或账号设置里",
          "en": "In the dashboard URL or account settings",
          "ja": "ダッシュボードの URL かアカウント設定"
        },
        "validation": {
          "zh": "Account ID 太短",
          "en": "Account ID is too short",
          "ja": "Account ID が短すぎます"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Fireworks 的 API keys 页面，签发一把。创建后立刻复制。",
        "en": "Open Fireworks' API keys page and issue a key. Copy it right away after creating it.",
        "ja": "Fireworks の API keys ページを開き、発行します。作成したらすぐにコピーしてください。"
      },
      {
        "zh": "在 Fireworks 控制台账号设置里复制 Account ID。账单接口的路径要用它。",
        "en": "Copy the Account ID from account settings in the Fireworks dashboard. The billing API path needs it.",
        "ja": "Fireworks ダッシュボードのアカウント設定で Account ID をコピーします。請求 API のパスに使います。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "API Key 无效。",
          "en": "API Key is invalid.",
          "ja": "API Key は無効です。"
        },
        "nextStep": {
          "zh": "回上一步重新签发一把。",
          "en": "Go back a step and issue a new one.",
          "ja": "前の手順に戻って発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 key 读不到这个 Account ID 的账单。",
          "en": "This key can’t read billing for this Account ID.",
          "ja": "この key ではこの Account ID の請求を読めません。"
        },
        "nextStep": {
          "zh": "确认 Account ID 和 key 属于同一账号。",
          "en": "Confirm the Account ID and key belong to the same account.",
          "ja": "Account ID と key が同じアカウントか確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://app.fireworks.ai",
    "credentialSetupURL": "https://app.fireworks.ai/settings/users/api-keys",
    "summary": {
      "zh": "Fireworks 推理平台。按本月已计价花费。",
      "en": "The Fireworks inference platform. This month’s already-priced spend.",
      "ja": "Fireworks の推論プラットフォーム。今月のすでに計上された支出です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 Fireworks 后台本月花费一致。",
      "en": "This number should match this month’s spend in the Fireworks dashboard.",
      "ja": "この数字は Fireworks 管理画面の今月支出と一致するはずです。"
    }
  },
  {
    "key": "fal",
    "name": "fal.ai",
    "kind": "prepaid",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "生成式媒体推理的领先平台，年化收入已到数亿美元量级。",
    "searchKeywords": [
      "fal",
      "fal.ai",
      "flux",
      "image"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "Admin API Key",
          "en": "Admin API Key",
          "ja": "Admin API Key"
        },
        "isSecret": true,
        "hint": {
          "zh": "要 Admin 权限才能读余额",
          "en": "Admin permission is required to read the balance",
          "ja": "残高を読むには Admin 権限が必要です"
        },
        "validation": {
          "zh": "API Key 太短，确认复制完整",
          "en": "API Key is too short. Make sure you copied the whole thing.",
          "ja": "API Key が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 fal.ai 的 API keys 页面，签发一把 Admin scope 的 key。普通推理 key 读不到余额。",
        "en": "Open the fal.ai API keys page and issue a key with Admin scope. A regular inference key can’t read the balance.",
        "ja": "fal.ai の API keys ページを開き、Admin スコープの key を発行します。通常の推論 key では残高を読めません。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "API Key 无效。",
          "en": "API Key is invalid.",
          "ja": "API Key は無効です。"
        },
        "nextStep": {
          "zh": "回上一步重新签发一把。",
          "en": "Go back a step and issue a new one.",
          "ja": "前の手順に戻って発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 key 没有 Admin 权限，读不到余额。",
          "en": "This key doesn’t have Admin permission, so it can’t read the balance.",
          "ja": "この key に Admin 権限がないため、残高を読めません。"
        },
        "nextStep": {
          "zh": "回上一步签发一把 Admin scope 的 key。",
          "en": "Go back a step and issue a key with Admin scope.",
          "ja": "前の手順に戻って Admin スコープの key を発行してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://fal.ai/dashboard",
    "credentialSetupURL": "https://fal.ai/dashboard/keys",
    "summary": {
      "zh": "fal.ai 图像和视频模型。预充值，报剩余额度。",
      "en": "fal.ai image and video models. Prepaid. It reports remaining quota.",
      "ja": "fal.ai の画像・動画モデル。プリペイドです。残りの枠を出します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 fal.ai 后台还剩的 credits 一致。",
      "en": "This number should match remaining credits in the fal.ai dashboard.",
      "ja": "この数字は fal.ai 管理画面の残り credits と一致するはずです。"
    }
  },
  {
    "key": "huggingface",
    "name": "Hugging Face",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "开源模型分发近乎垄断，推理 API 是附加能力。",
    "searchKeywords": [
      "hf",
      "huggingface",
      "inference",
      "spaces",
      "hub"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "Access Token",
          "en": "Access Token",
          "ja": "Access Token"
        },
        "isSecret": true,
        "hint": {
          "zh": "hf_ 开头",
          "en": "starts with hf_",
          "ja": "hf_ で始まる"
        },
        "validation": {
          "zh": "Access Token 应该以 hf_ 开头",
          "en": "Access Token should start with hf_",
          "ja": "Access Token は hf_ で始まる必要があります"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Hugging Face 的 Access Tokens，新建一把。读的是这把 token 对应的个人计算账单。",
        "en": "Open Hugging Face Access Tokens and create one. It reads the personal compute bill for this token.",
        "ja": "Hugging Face の Access Tokens を開き、新規作成します。この token に対応する個人の計算請求を読みます。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "Access Token 无效。",
          "en": "Access Token is invalid.",
          "ja": "Access Token は無効です。"
        },
        "nextStep": {
          "zh": "回上一步重新签发一把。",
          "en": "Go back a step and issue a new one.",
          "ja": "前の手順に戻って発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 token 读不到这个组织的账单。",
          "en": "This token can’t read this organization’s billing.",
          "ja": "この token ではこの組織の請求を読めません。"
        },
        "nextStep": {
          "zh": "确认组织名没写错，并且 token 对该组织有权限。",
          "en": "Confirm the organization name isn’t mistyped, and the token can access that org.",
          "ja": "組織名の誤記がなく、token にその組織の権限があるか確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://huggingface.co/settings/billing",
    "credentialSetupURL": "https://huggingface.co/settings/tokens",
    "summary": {
      "zh": "Hugging Face Hub 的计算花费。个人读自己的账单；填组织名则读组织。",
      "en": "Hugging Face Hub compute spend. A personal token reads your bill; an org name reads the org.",
      "ja": "Hugging Face Hub の計算費用。個人なら自分の請求、組織名を入れると組織を読みます。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 Hugging Face Billing 页本月计算花费一致。订阅费不在里面。",
      "en": "This number should match this month’s compute spend on the Hugging Face Billing page. Subscription fees are not included.",
      "ja": "この数字は Hugging Face Billing ページの今月の計算費用と一致するはずです。サブスクリプション料は含まれません。"
    }
  },
  {
    "key": "turso",
    "name": "Turso",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "libSQL/SQLite 边缘库仍处早期，资金很少但产品仍在向 Postgres 前端扩张。",
    "searchKeywords": [
      "libsql",
      "sqlite",
      "database",
      "数据库"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true,
        "validation": {
          "zh": "API Token 太短，确认复制完整",
          "en": "API Token is too short. Make sure you copied the whole thing.",
          "ja": "API Token が短すぎます。全部コピーできているか確認してください。"
        }
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Organization slug",
          "en": "Organization slug",
          "ja": "Organization slug"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台 URL 里的组织名",
          "en": "The organization name in the dashboard URL",
          "ja": "ダッシュボード URL の組織名"
        },
        "validation": {
          "zh": "Organization slug 太短",
          "en": "Organization slug is too short",
          "ja": "Organization slug が短すぎます"
        }
      }
    ],
    "steps": [
      {
        "zh": "用 Turso CLI 签发一把 API Token：turso auth api-tokens mint。网页控制台没有单独的创建页。",
        "en": "Issue an API Token with the Turso CLI: turso auth api-tokens mint. The web dashboard has no separate create page.",
        "ja": "Turso CLI で API Token を発行します：turso auth api-tokens mint。ウェブのダッシュボードに単独の作成ページはありません。"
      },
      {
        "zh": "在 Turso 控制台复制组织 slug。个人账号通常就是用户名。",
        "en": "Copy the organization slug in the Turso dashboard. For a personal account that’s usually the username.",
        "ja": "Turso のダッシュボードで組織 slug をコピーします。個人アカウントならだいたいユーザー名です。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "API Token 无效。",
          "en": "API Token is invalid.",
          "ja": "API Token は無効です。"
        },
        "nextStep": {
          "zh": "回上一步重新 mint 一把。",
          "en": "Go back a step and mint a new one.",
          "ja": "前の手順に戻って、もう一度 mint してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 token 读不到这个组织的发票。",
          "en": "This token can’t read this organization’s invoices.",
          "ja": "この token ではこの組織のインボイスを読めません。"
        },
        "nextStep": {
          "zh": "确认组织 slug 和 token 属于同一账号。",
          "en": "Confirm the organization slug and token belong to the same account.",
          "ja": "組織 slug と token が同じアカウントか確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://app.turso.tech",
    "credentialSetupURL": "https://docs.turso.tech/cli/auth/api-tokens",
    "summary": {
      "zh": "基于 libSQL 的数据库。按当期未出账发票。",
      "en": "A libSQL-based database. The current uninvoiced invoice.",
      "ja": "libSQL ベースのデータベース。当期の未請求インボイスです。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 Turso 后台当期未出账发票一致。周期刚开始还没生成发票时会显示读不到数。",
      "en": "This number should match the current uninvoiced invoice in the Turso dashboard. Right after a cycle starts, a missing invoice shows as no reading yet.",
      "ja": "この数字は Turso 管理画面の当期未請求インボイスと一致するはずです。周期の直後でインボイスがまだないと「読めない」と出ます。"
    }
  },
  {
    "key": "gcp",
    "name": "Google Cloud",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": true,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "三大超大规模云之一，份额上升且增速快于市场，仍是企业短名单第三席。",
    "searchKeywords": [
      "gcp",
      "google cloud",
      "gce",
      "gcs",
      "bigquery"
    ],
    "fields": [],
    "steps": [
      {
        "zh": "Google Cloud 没有公开的账单金额接口。本月花费只在控制台 Billing 页和 BigQuery 导出里。下一步会给你一段任务书，粘给 Claude Code、Cursor 或任何能上网的 AI 写抓取脚本。本月花费以控制台 Billing 页为准。",
        "en": "Google Cloud has no public billed-amount API. This month’s spend lives on the Billing page and in the BigQuery export. Next you’ll get a brief. Paste it into Claude Code, Cursor, or any AI that can reach the web, and have it write a scrape script. Treat the dashboard Billing page as the source for this month.",
        "ja": "Google Cloud に公開の請求金額 API はありません。今月の支出はダッシュボードの Billing ページと BigQuery エクスポートにあります。次の画面で依頼文を出します。Claude Code、Cursor、またはネットに出られる AI に貼って、取得スクリプトを書いてもらってください。今月の金額はダッシュボードの Billing ページを正とします。"
      },
      {
        "zh": "投递 key 单独给你，放进脚本的环境变量。脚本每天跑一次，同一个月重复上报是覆盖。",
        "en": "The ingest key is yours alone. Put it in the script’s environment variables. Run the script once a day. Sending the same month again overwrites.",
        "ja": "投函キーはあなた専用です。スクリプトの環境変数に入れてください。スクリプトは 1 日 1 回。同じ月を再送すると上書きです。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "投递 key 已经被吊销了。",
          "en": "The ingest key has been revoked.",
          "ja": "投函キーはすでに取り消されています。"
        },
        "nextStep": {
          "zh": "去设置 → 读数信箱里再签一把，然后更新你的脚本。",
          "en": "Go to Settings → Inbox and issue a new one, then update your script.",
          "ja": "設定 → 検針ポストで発行し直し、スクリプトを更新してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "投递太频繁了。",
          "en": "You’re delivering too often.",
          "ja": "投函が頻繁すぎます。"
        },
        "nextStep": {
          "zh": "每天跑一次就够。",
          "en": "Once a day is enough.",
          "ja": "1 日 1 回で足ります。"
        },
        "httpStatus": 429
      }
    ],
    "plans": [],
    "notices": [
      {
        "zh": "Cloud Billing API 只管账号和价目，本月花费只在 BigQuery 导出里。这家走读数信箱：你自己从 Billing 页把数字投递进来，App 只负责取回。",
        "en": "Cloud Billing API only covers accounts and prices. This month’s spend is in the BigQuery export. This one uses the inbox: you fetch from the Billing page and deliver it; the app only reads it back.",
        "ja": "Cloud Billing API はアカウントと料金表だけで、今月の支出は BigQuery エクスポートにあります。このサービスは検針ポストです。Billing ページから自分で取って投函し、App は受け取るだけです。"
      }
    ],
    "guideURLs": [],
    "billingURL": "https://console.cloud.google.com/billing",
    "credentialSetupURL": "https://console.cloud.google.com/iam-admin/serviceaccounts",
    "summary": {
      "zh": "云基础设施。没有公开账单金额接口，走读数信箱。",
      "en": "Cloud infrastructure. There’s no public billed-amount API, so it uses the inbox.",
      "ja": "クラウドインフラ。公開の請求金額 API はないので、検針ポストを使います。"
    },
    "verifyHint": {
      "zh": "接入之后先显示「等待投递」。脚本第一次上报之后数字才会出来。",
      "en": "After connecting, it first shows Waiting for delivery. The number appears after the script reports once.",
      "ja": "接続した直後は「投函待ち」です。スクリプトが一度報告してから数字が出ます。"
    }
  },
  {
    "key": "baseten",
    "name": "Baseten",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "推理平台被企业当成 SageMaker/Vertex 的替代，收入一年内冲到数亿美元量级。",
    "searchKeywords": [
      "baseten.co",
      "truss",
      "inference"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true,
        "validation": {
          "zh": "API Key 太短，确认复制完整",
          "en": "API Key is too short. Make sure you copied the whole thing.",
          "ja": "API Key が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Baseten 的 API keys 文档，在控制台签发一把 workspace API key。",
        "en": "Open Baseten’s API keys docs and issue a workspace API key in the dashboard.",
        "ja": "Baseten の API keys のドキュメントを開き、ダッシュボードで workspace API key を発行します。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "凭据无效。",
          "en": "The credentials are invalid.",
          "ja": "認証情報が無効です。"
        },
        "nextStep": {
          "zh": "回上一步重新签发一把。",
          "en": "Go back a step and issue a new one.",
          "ja": "前の手順に戻って発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把凭据读不到账单。",
          "en": "These credentials can’t read billing.",
          "ja": "この認証情報では請求を読めません。"
        },
        "nextStep": {
          "zh": "确认权限和账号属于同一组织。",
          "en": "Confirm the permission and account belong to the same organization.",
          "ja": "権限とアカウントが同じ組織か確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://app.baseten.co",
    "credentialSetupURL": "https://docs.baseten.co/organization/api-keys",
    "summary": {
      "zh": "模型推理平台。按 dedicated / training / Model APIs 的本月花费，已扣 credits。",
      "en": "A model inference platform. This month’s spend on dedicated / training / Model APIs, after credits.",
      "ja": "モデル推論プラットフォーム。dedicated / training / Model APIs の今月支出で、credits 差し引き後です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 Baseten Billing and usage 里扣完 credits 后的本月花费一致。",
      "en": "This number should match this month’s spend after credits on Baseten Billing and usage.",
      "ja": "この数字は Baseten Billing and usage の credits 差し引き後の今月支出と一致するはずです。"
    }
  },
  {
    "key": "clickhouse",
    "name": "ClickHouse Cloud",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "实时 OLAP 的最强独立挑战者，云收入一年内翻数倍并按 IPO 路径扩张。",
    "searchKeywords": [
      "clickhouse cloud",
      "chc",
      "analytics",
      "olap"
    ],
    "fields": [
      {
        "key": "clientID",
        "label": {
          "zh": "Key ID",
          "en": "Key ID",
          "ja": "Key ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台 API keys 页",
          "en": "API keys page in the dashboard",
          "ja": "ダッシュボードの API keys ページ"
        },
        "validation": {
          "zh": "Key ID 太短",
          "en": "Key ID is too short",
          "ja": "Key ID が短すぎます"
        }
      },
      {
        "key": "clientSecret",
        "label": {
          "zh": "Key Secret",
          "en": "Key Secret",
          "ja": "Key Secret"
        },
        "isSecret": true,
        "validation": {
          "zh": "Key Secret 太短，确认复制完整",
          "en": "Key Secret is too short. Make sure you copied the whole thing.",
          "ja": "Key Secret が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 ClickHouse Cloud 的 API 密钥文档，在控制台新建一把只读 Key。Key ID 和 Key Secret 成对复制。",
        "en": "Open the ClickHouse Cloud API keys docs and create a read-only Key in the dashboard. Copy the Key ID and Key Secret together.",
        "ja": "ClickHouse Cloud の API キーのドキュメントを開き、ダッシュボードで読み取り専用の Key を作ります。Key ID と Key Secret をペアでコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "凭据无效。",
          "en": "The credentials are invalid.",
          "ja": "認証情報が無効です。"
        },
        "nextStep": {
          "zh": "回上一步重新签发一把。",
          "en": "Go back a step and issue a new one.",
          "ja": "前の手順に戻って発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把凭据读不到账单。",
          "en": "These credentials can’t read billing.",
          "ja": "この認証情報では請求を読めません。"
        },
        "nextStep": {
          "zh": "确认权限和账号属于同一组织。",
          "en": "Confirm the permission and account belong to the same organization.",
          "ja": "権限とアカウントが同じ組織か確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://console.clickhouse.cloud",
    "credentialSetupURL": "https://clickhouse.com/docs/cloud/manage/openapi",
    "summary": {
      "zh": "托管分析库。按本月 ClickHouse Credit，1 CHC 等于 1 美元。",
      "en": "A managed analytics database. This month’s ClickHouse Credits, where 1 CHC equals $1.",
      "ja": "マネージド分析 DB。今月の ClickHouse Credit で、1 CHC は 1 ドルです。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 ClickHouse Cloud 后台本月 Usage 的合计一致。1 CHC = $1。",
      "en": "This number should match this month’s Usage total in the ClickHouse Cloud dashboard. 1 CHC = $1.",
      "ja": "この数字は ClickHouse Cloud 管理画面の今月 Usage 合計と一致するはずです。1 CHC = $1。"
    }
  },
  {
    "key": "linode",
    "name": "Linode",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "Akamai 收购后云基础设施仍在高增，品牌仍是 VPS 常见替代，但体量小于 DO。",
    "searchKeywords": [
      "akamai",
      "linode.com",
      "vps"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "Personal Access Token",
          "en": "Personal Access Token",
          "ja": "Personal Access Token"
        },
        "isSecret": true,
        "validation": {
          "zh": "Personal Access Token 太短，确认复制完整",
          "en": "Personal Access Token is too short. Make sure you copied the whole thing.",
          "ja": "Personal Access Token が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Linode 的 API Tokens 页面，新建一把。权限勾 account:read_only。",
        "en": "Open Linode’s API Tokens page and create one. Check account:read_only.",
        "ja": "Linode の API Tokens ページを開き、新規作成します。権限は account:read_only です。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "凭据无效。",
          "en": "The credentials are invalid.",
          "ja": "認証情報が無効です。"
        },
        "nextStep": {
          "zh": "回上一步重新签发一把。",
          "en": "Go back a step and issue a new one.",
          "ja": "前の手順に戻って発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把凭据读不到账单。",
          "en": "These credentials can’t read billing.",
          "ja": "この認証情報では請求を読めません。"
        },
        "nextStep": {
          "zh": "确认权限和账号属于同一组织。",
          "en": "Confirm the permission and account belong to the same organization.",
          "ja": "権限とアカウントが同じ組織か確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://cloud.linode.com/account/billing",
    "credentialSetupURL": "https://cloud.linode.com/profile/tokens",
    "summary": {
      "zh": "Akamai 旗下的云主机。按当期未出账余额，传输超额不在里面。",
      "en": "Akamai’s cloud hosts. This is the current uninvoiced balance; transfer overage is not included.",
      "ja": "Akamai のクラウドホスト。当期の未請求残高で、転送の超過分は含まれません。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 Linode 后台 Uninvoiced 余额一致。这是估算，传输超额不在里面。",
      "en": "This number should match the Uninvoiced balance in the Linode dashboard. It’s an estimate. Transfer overage is not included.",
      "ja": "この数字は Linode 管理画面の Uninvoiced 残高と一致するはずです。見積もりで、転送超過は含まれません。"
    }
  },
  {
    "key": "runpod",
    "name": "RunPod",
    "kind": "prepaid",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "自助 GPU 云里开发者真正会下单的替代，实例供给和 ARR 都已是新云第二梯队。",
    "searchKeywords": [
      "runpod.io",
      "gpu",
      "serverless",
      "pod"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true,
        "validation": {
          "zh": "API Key 太短，确认复制完整",
          "en": "API Key is too short. Make sure you copied the whole thing.",
          "ja": "API Key が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 RunPod 的 Settings，签发一把 API key。",
        "en": "Open RunPod Settings and issue an API key.",
        "ja": "RunPod の Settings を開き、API key を発行します。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "凭据无效。",
          "en": "The credentials are invalid.",
          "ja": "認証情報が無効です。"
        },
        "nextStep": {
          "zh": "回上一步重新签发一把。",
          "en": "Go back a step and issue a new one.",
          "ja": "前の手順に戻って発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把凭据读不到账单。",
          "en": "These credentials can’t read billing.",
          "ja": "この認証情報では請求を読めません。"
        },
        "nextStep": {
          "zh": "确认权限和账号属于同一组织。",
          "en": "Confirm the permission and account belong to the same organization.",
          "ja": "権限とアカウントが同じ組織か確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.runpod.io/console/user/billing",
    "credentialSetupURL": "https://www.runpod.io/console/user/settings",
    "summary": {
      "zh": "GPU 云。预充值，报剩余 credits。",
      "en": "GPU cloud. Prepaid. It reports remaining credits.",
      "ja": "GPU クラウド。プリペイドです。残りの credits を出します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 RunPod 后台还剩的 credits 一致。",
      "en": "This number should match remaining credits in the RunPod dashboard.",
      "ja": "この数字は RunPod 管理画面の残り credits と一致するはずです。"
    }
  },
  {
    "key": "deepgram",
    "name": "Deepgram",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "生产级流式语音识别的默认供应商，与 ElevenLabs 分食独立语音 API 寡头。",
    "searchKeywords": [
      "deepgram.com",
      "speech",
      "stt",
      "tts",
      "语音",
      "billing/breakdown"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true,
        "validation": {
          "zh": "API Key 太短，确认复制完整",
          "en": "API Key is too short. Make sure you copied the whole thing.",
          "ja": "API Key が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Deepgram 的 API keys 文档，在控制台签发一把。读的是这把 key 能看到的第一个项目的余额。",
        "en": "Open Deepgram’s API keys docs and issue a key in the dashboard. It reads the balance of the first project this key can see.",
        "ja": "Deepgram の API keys のドキュメントを開き、ダッシュボードで発行します。この key が見える最初のプロジェクトの残高を読みます。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "凭据无效。",
          "en": "The credentials are invalid.",
          "ja": "認証情報が無効です。"
        },
        "nextStep": {
          "zh": "回上一步重新签发一把。",
          "en": "Go back a step and issue a new one.",
          "ja": "前の手順に戻って発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把凭据读不到账单。",
          "en": "These credentials can’t read billing.",
          "ja": "この認証情報では請求を読めません。"
        },
        "nextStep": {
          "zh": "确认权限和账号属于同一组织。",
          "en": "Confirm the permission and account belong to the same organization.",
          "ja": "権限とアカウントが同じ組織か確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://console.deepgram.com",
    "credentialSetupURL": "https://developers.deepgram.com/docs/create-additional-api-keys",
    "summary": {
      "zh": "语音识别和合成。预充值，报项目剩余额度。",
      "en": "Speech recognition and synthesis. Prepaid. It reports remaining project quota.",
      "ja": "音声認識と合成。プリペイドです。プロジェクトの残り枠を出します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 Deepgram 后台该项目还剩的 credits 一致。",
      "en": "This number should match remaining credits for that project in the Deepgram dashboard.",
      "ja": "この数字は Deepgram 管理画面のそのプロジェクトの残り credits と一致するはずです。"
    }
  },
  {
    "key": "scaleway",
    "name": "Scaleway",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "Iliad 旗下欧洲主权云在扩区、加码 AI，但规模仍远小于超大规模云和 OVH。",
    "searchKeywords": [
      "scaleway.com",
      "online.net",
      "france",
      "vps"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "Secret Key",
          "en": "Secret Key",
          "ja": "Secret Key"
        },
        "isSecret": true,
        "hint": {
          "zh": "IAM API keys 的 secret",
          "en": "The secret from IAM API keys",
          "ja": "IAM API keys の secret"
        },
        "validation": {
          "zh": "Secret Key 太短，确认复制完整",
          "en": "Secret Key is too short. Make sure you copied the whole thing.",
          "ja": "Secret Key が短すぎます。全部コピーできているか確認してください。"
        }
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Organization ID",
          "en": "Organization ID",
          "ja": "Organization ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台 Organization 页的 UUID",
          "en": "The UUID on the Organization page in the dashboard",
          "ja": "ダッシュボードの Organization ページの UUID"
        },
        "validation": {
          "zh": "Organization ID 是 36 位 UUID",
          "en": "Organization ID is a 36-character UUID",
          "ja": "Organization ID は 36 桁の UUID です"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Scaleway 的 IAM API keys 页面，新建一把。权限给 BillingReadOnly。",
        "en": "Open Scaleway’s IAM API keys page and create one. Grant BillingReadOnly.",
        "ja": "Scaleway の IAM API keys ページを開き、新規作成します。権限は BillingReadOnly です。"
      },
      {
        "zh": "在 Scaleway 控制台复制 Organization ID。",
        "en": "Copy the Organization ID in the Scaleway dashboard.",
        "ja": "Scaleway のダッシュボードで Organization ID をコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "凭据无效。",
          "en": "The credentials are invalid.",
          "ja": "認証情報が無効です。"
        },
        "nextStep": {
          "zh": "回上一步重新签发一把。",
          "en": "Go back a step and issue a new one.",
          "ja": "前の手順に戻って発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把凭据读不到账单。",
          "en": "These credentials can’t read billing.",
          "ja": "この認証情報では請求を読めません。"
        },
        "nextStep": {
          "zh": "确认权限和账号属于同一组织。",
          "en": "Confirm the permission and account belong to the same organization.",
          "ja": "権限とアカウントが同じ組織か確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://console.scaleway.com/billing",
    "credentialSetupURL": "https://console.scaleway.com/iam/api-keys",
    "summary": {
      "zh": "欧洲云厂商。按本月 consumption，可能是欧元再折美元。",
      "en": "A European cloud vendor. This month’s consumption, possibly in euros then converted to USD.",
      "ja": "欧州のクラウド。今月の consumption で、ユーロならドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 Scaleway Billing 本月 consumption 一致。欧元账户会按目录汇率折美元。",
      "en": "This number should match this month’s consumption on Scaleway Billing. Euro accounts convert to USD at the catalog rate.",
      "ja": "この数字は Scaleway Billing の今月 consumption と一致するはずです。ユーロ口座はディレクトリの為替でドルにします。"
    }
  },
  {
    "key": "pinecone",
    "name": "Pinecone",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "托管向量库仍是品类默认选择，但 pgvector 与开源库正在分走份额、增长放缓。",
    "searchKeywords": [
      "pinecone.io",
      "vector",
      "向量",
      "rag"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "用量和发票只在控制台，公开 API 没有账单金额。"
  },
  {
    "key": "modal",
    "name": "Modal",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "无服务器 GPU/作业平台已被当成可规模化的替代，ARR 已到数亿美元。",
    "searchKeywords": [
      "modal.com",
      "gpu",
      "serverless"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "公开接口只有 Python SDK / CLI，没有 HTTP 账单金额。"
  },
  {
    "key": "hetzner",
    "name": "Hetzner",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "欧洲廉价 VPS/云的事实标准选项，实例规模与营收都已是独立云第一梯队。",
    "searchKeywords": [
      "hetzner cloud",
      "hcloud",
      "robot"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "Cloud API 只有价目，没有本月花费。"
  },
  {
    "key": "auth0",
    "name": "Auth0",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "中市值 SaaS 的 CIAM 默认选项，归入 Okta 后仍是开发者身份的强在位者。",
    "searchKeywords": [
      "auth0.com",
      "okta",
      "identity"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [
      {
        "name": {
          "zh": "Essentials",
          "en": "Essentials",
          "ja": "Essentials"
        },
        "amountUSD": "35",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Essentials（年付）",
          "en": "Essentials (annual)",
          "ja": "Essentials（年払い）"
        },
        "amountUSD": "385",
        "period": "annual"
      },
      {
        "name": {
          "zh": "Professional",
          "en": "Professional",
          "ja": "Professional"
        },
        "amountUSD": "240",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Professional（年付）",
          "en": "Professional (annual)",
          "ja": "Professional（年払い）"
        },
        "amountUSD": "2640",
        "period": "annual"
      }
    ],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单接口。"
  },
  {
    "key": "mixpanel",
    "name": "Mixpanel",
    "kind": "planAndUsage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "产品分析老牌玩家，收入仍大但中小客户份额被 PostHog 切走。",
    "searchKeywords": [
      "mixpanel.com",
      "analytics",
      "产品分析"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "amplitude",
    "name": "Amplitude",
    "kind": "planAndUsage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "上市的企业产品分析在位者，增速稳健但远低于 PostHog。",
    "searchKeywords": [
      "amplitude.com",
      "analytics",
      "产品分析"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "launchdarkly",
    "name": "LaunchDarkly",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "企业功能开关与运行时控制的品类龙头，规模与心智仍压过开源和套件捆绑者。",
    "searchKeywords": [
      "launchdarkly.com",
      "feature flag",
      "flags"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "algolia",
    "name": "Algolia",
    "kind": "planAndUsage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "站点搜索 API 的龙头之一，收入过亿美元但增速已降至约一成、估值被下调。",
    "searchKeywords": [
      "algolia.com",
      "search",
      "搜索"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "公开 API 没有账单金额。"
  },
  {
    "key": "zapier",
    "name": "Zapier",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "无代码应用自动化的默认寡头，中市场渗透仍远高于 n8n/Make。",
    "searchKeywords": [
      "zapier.com",
      "automation",
      "自动化"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [
      {
        "name": {
          "zh": "Professional",
          "en": "Professional",
          "ja": "Professional"
        },
        "amountUSD": "29.99",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Professional（年付）",
          "en": "Professional (annual)",
          "ja": "Professional（年払い）"
        },
        "amountUSD": "239.88",
        "period": "annual"
      },
      {
        "name": {
          "zh": "Team",
          "en": "Team",
          "ja": "Team"
        },
        "amountUSD": "103.50",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Team（年付）",
          "en": "Team (annual)",
          "ja": "Team（年払い）"
        },
        "amountUSD": "828",
        "period": "annual"
      }
    ],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单接口。"
  },
  {
    "key": "discord",
    "name": "Discord",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "开发者/游戏社区通讯的默认平台，用户巨大但估值较 2021 高点明显回落。",
    "searchKeywords": [
      "discord.com",
      "nitro"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [
      {
        "name": {
          "zh": "Nitro Basic",
          "en": "Nitro Basic",
          "ja": "Nitro Basic"
        },
        "amountUSD": "2.99",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Nitro Basic（年付）",
          "en": "Nitro Basic (annual)",
          "ja": "Nitro Basic（年払い）"
        },
        "amountUSD": "29.99",
        "period": "annual"
      },
      {
        "name": {
          "zh": "Nitro",
          "en": "Nitro",
          "ja": "Nitro"
        },
        "amountUSD": "9.99",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Nitro（年付）",
          "en": "Nitro (annual)",
          "ja": "Nitro（年払い）"
        },
        "amountUSD": "99.99",
        "period": "annual"
      }
    ],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开服务器账单接口。商标条款也不许改色改 path，字母回落。"
  },
  {
    "key": "replit",
    "name": "Replit",
    "kind": "planAndUsage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "AI 编程+一键托管爆发后成为大量应用的实际落地点，是该工作流里被点名的替代。",
    "searchKeywords": [
      "replit.com",
      "repl.it",
      "ide"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "webflow",
    "name": "Webflow",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "专业可视化建站的领先者，在 CMS 总盘里份额稳定但远小于 WordPress。",
    "searchKeywords": [
      "webflow.com",
      "cms"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [
      {
        "name": {
          "zh": "Basic",
          "en": "Basic",
          "ja": "Basic"
        },
        "amountUSD": "25",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Basic（年付）",
          "en": "Basic (annual)",
          "ja": "Basic（年払い）"
        },
        "amountUSD": "180",
        "period": "annual"
      },
      {
        "name": {
          "zh": "Premium",
          "en": "Premium",
          "ja": "Premium"
        },
        "amountUSD": "39",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Premium（年付）",
          "en": "Premium (annual)",
          "ja": "Premium（年払い）"
        },
        "amountUSD": "300",
        "period": "annual"
      }
    ],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单接口。"
  },
  {
    "key": "snowflake",
    "name": "Snowflake",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "云数仓寡头之一，产品收入已达数十亿美元并继续抬高全年指引。",
    "searchKeywords": [
      "snowflake.com",
      "warehouse",
      "data cloud"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有给客户的 HTTP 账单金额接口。"
  },
  {
    "key": "intercom",
    "name": "Intercom",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "SaaS 客户消息与 AI 客服的强挑战者，整体客服市场仍由 Zendesk 领跑。",
    "searchKeywords": [
      "intercom.com",
      "inbox",
      "客服"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单接口。"
  },
  {
    "key": "bunny",
    "name": "bunny.net",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "低价 CDN 与视频边缘正在爬升，份额仍约百分之一。",
    "searchKeywords": [
      "bunny.net",
      "bunnycdn",
      "cdn"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true,
        "validation": {
          "zh": "API Key 太短，确认复制完整",
          "en": "API Key is too short. Make sure you copied the whole thing.",
          "ja": "API Key が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 bunny.net 的 API Keys 文档，在 Account 里复制那把 account API key。",
        "en": "Open bunny.net’s API Keys docs and copy the account API key under Account.",
        "ja": "bunny.net の API Keys のドキュメントを開き、Account にある account API key をコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "凭据无效。",
          "en": "The credentials are invalid.",
          "ja": "認証情報が無効です。"
        },
        "nextStep": {
          "zh": "回上一步重新复制一把。",
          "en": "Go back a step and copy it again.",
          "ja": "前の手順に戻って、もう一度コピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把凭据读不到账单。",
          "en": "These credentials can’t read billing.",
          "ja": "この認証情報では請求を読めません。"
        },
        "nextStep": {
          "zh": "确认用的是 Account 那把 API key，不是 Storage 或 Stream 的。",
          "en": "Confirm you’re using the Account API key, not Storage or Stream.",
          "ja": "Storage や Stream ではなく Account の API key か確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://dash.bunny.net",
    "credentialSetupURL": "https://docs.bunny.net/account/api-keys",
    "summary": {
      "zh": "CDN。按各 Pull Zone 本月已用 credit 相加。",
      "en": "CDN. Sum of credits used this month across Pull Zones.",
      "ja": "CDN。各 Pull Zone の今月使用 credit を足します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 bunny.net Billing 里各 Pull Zone 本月已用 credit 的合计一致。Storage / Stream 不一定在里面。",
      "en": "This number should match this month’s used credits across Pull Zones in bunny.net Billing. Storage / Stream may not be included.",
      "ja": "この数字は bunny.net Billing の各 Pull Zone の今月使用 credit 合計と一致するはずです。Storage / Stream は入っていないことがあります。"
    }
  },
  {
    "key": "grafana",
    "name": "Grafana Cloud",
    "kind": "planAndUsage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "开源可观测栈的商业化寡头之一，连续三年进入 Gartner 领导者象限。",
    "searchKeywords": [
      "grafana cloud",
      "loki",
      "tempo",
      "mimir"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "Cloud Access Policy token",
          "en": "Cloud Access Policy token",
          "ja": "Cloud Access Policy token"
        },
        "isSecret": true,
        "validation": {
          "zh": "token 太短，确认复制完整",
          "en": "token is too short. Make sure you copied the whole thing.",
          "ja": "token が短すぎます。全部コピーできているか確認してください。"
        }
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Org slug",
          "en": "Org slug",
          "ja": "Org slug"
        },
        "isSecret": false,
        "hint": {
          "zh": "grafana.com/orgs 后面那段",
          "en": "The segment after grafana.com/orgs",
          "ja": "grafana.com/orgs の後ろの部分"
        },
        "validation": {
          "zh": "Org slug 太短",
          "en": "Org slug is too short",
          "ja": "Org slug が短すぎます"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Grafana Cloud 的 Access Policy 文档，在控制台签发一把只读 token。",
        "en": "Open Grafana Cloud’s Access Policy docs and issue a read-only token in the dashboard.",
        "ja": "Grafana Cloud の Access Policy のドキュメントを開き、ダッシュボードで読み取り専用 token を発行します。"
      },
      {
        "zh": "在 Grafana Cloud 控制台复制 Org slug。",
        "en": "Copy the Org slug in the Grafana Cloud dashboard.",
        "ja": "Grafana Cloud のダッシュボードで Org slug をコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "凭据无效。",
          "en": "The credentials are invalid.",
          "ja": "認証情報が無効です。"
        },
        "nextStep": {
          "zh": "回上一步重新签发一把。",
          "en": "Go back a step and issue a new one.",
          "ja": "前の手順に戻って発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把凭据读不到账单。",
          "en": "These credentials can’t read billing.",
          "ja": "この認証情報では請求を読めません。"
        },
        "nextStep": {
          "zh": "确认 token 的 realm 覆盖这个 org。",
          "en": "Confirm the token’s realm covers this org.",
          "ja": "token の realm がこの org をカバーしているか確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [
      {
        "name": {
          "zh": "Grafana Cloud Pro",
          "en": "Grafana Cloud Pro",
          "ja": "Grafana Cloud Pro"
        },
        "amountUSD": "19",
        "period": "monthly"
      }
    ],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://grafana.com/orgs",
    "summary": {
      "zh": "Grafana Cloud 托管观测。按指定月份已出账的 amountDue。当月可能还是空的。",
      "en": "Managed Grafana Cloud observability. amountDue for a billed month. The current month may still be empty.",
      "ja": "Grafana Cloud のマネージド観測。指定月の出帳済み amountDue です。当月はまだ空のことがあります。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 Grafana Cloud 该月已出账用量一致。当月还没出账时会是 $0。",
      "en": "This number should match billed usage for that month on Grafana Cloud. It will be $0 if the current month isn’t billed yet.",
      "ja": "この数字は Grafana Cloud のその月の出帳済み用量と一致するはずです。当月がまだ出帳前なら $0 です。"
    }
  },
  {
    "key": "elastic",
    "name": "Elastic Cloud",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "搜索引擎与托管搜索的寡头，年收入近 20 亿美元且 Elastic Cloud 接近一半。",
    "searchKeywords": [
      "elasticsearch",
      "kibana",
      "ecu",
      "elastic cloud"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true,
        "validation": {
          "zh": "API Key 太短，确认复制完整",
          "en": "API Key is too short. Make sure you copied the whole thing.",
          "ja": "API Key が短すぎます。全部コピーできているか確認してください。"
        }
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Organization ID",
          "en": "Organization ID",
          "ja": "Organization ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台 Organization 页",
          "en": "Organization page in the dashboard",
          "ja": "ダッシュボードの Organization ページ"
        },
        "validation": {
          "zh": "Organization ID 太短",
          "en": "Organization ID is too short",
          "ja": "Organization ID が短すぎます"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Elastic Cloud Billing API 的认证文档，在控制台签发一把 API key。",
        "en": "Open the Elastic Cloud Billing API auth docs and issue an API key in the dashboard.",
        "ja": "Elastic Cloud Billing API の認証ドキュメントを開き、ダッシュボードで API key を発行します。"
      },
      {
        "zh": "在 Elastic Cloud 控制台复制 Organization ID。",
        "en": "Copy the Organization ID in the Elastic Cloud dashboard.",
        "ja": "Elastic Cloud のダッシュボードで Organization ID をコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "凭据无效。",
          "en": "The credentials are invalid.",
          "ja": "認証情報が無効です。"
        },
        "nextStep": {
          "zh": "回上一步重新签发一把。",
          "en": "Go back a step and issue a new one.",
          "ja": "前の手順に戻って発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把凭据读不到账单。",
          "en": "These credentials can’t read billing.",
          "ja": "この認証情報では請求を読めません。"
        },
        "nextStep": {
          "zh": "确认 API key 能读这个组织。",
          "en": "Confirm the API key can read this organization.",
          "ja": "API key がこの組織を読めるか確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://cloud.elastic.co/account",
    "credentialSetupURL": "https://www.elastic.co/docs/api/doc/cloud-billing/authentication",
    "summary": {
      "zh": "Elastic Cloud。按本月 Elastic Consumption Unit，1 ECU 等于 1 美元。",
      "en": "Elastic Cloud. This month’s Elastic Consumption Units, where 1 ECU equals $1.",
      "ja": "Elastic Cloud。今月の Elastic Consumption Unit で、1 ECU は 1 ドルです。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 Elastic Cloud Usage 本月 ECU 合计一致。1 ECU = $1。",
      "en": "This number should match this month’s ECU total on Elastic Cloud Usage. 1 ECU = $1.",
      "ja": "この数字は Elastic Cloud Usage の今月 ECU 合計と一致するはずです。1 ECU = $1。"
    }
  },
  {
    "key": "datadog",
    "name": "Datadog",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "云原生可观测的执行力最强寡头，收入规模甩开同业一个数量级。",
    "searchKeywords": [
      "datadoghq",
      "apm",
      "logs",
      "monitor"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true,
        "validation": {
          "zh": "API Key 太短，确认复制完整",
          "en": "API Key is too short. Make sure you copied the whole thing.",
          "ja": "API Key が短すぎます。全部コピーできているか確認してください。"
        }
      },
      {
        "key": "apiToken",
        "label": {
          "zh": "Application Key",
          "en": "Application Key",
          "ja": "Application Key"
        },
        "isSecret": true,
        "validation": {
          "zh": "Application Key 太短，确认复制完整",
          "en": "Application Key is too short. Make sure you copied the whole thing.",
          "ja": "Application Key が短すぎます。全部コピーできているか確認してください。"
        }
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Site",
          "en": "Site",
          "ja": "Site"
        },
        "isSecret": false,
        "hint": {
          "zh": "us1、eu、us3、us5、ap1、ap2、uk1",
          "en": "us1、eu、us3、us5、ap1、ap2、uk1",
          "ja": "us1、eu、us3、us5、ap1、ap2、uk1"
        },
        "validation": {
          "zh": "站点短名太短",
          "en": "The site short name is too short",
          "ja": "サイト短名が短すぎます"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Datadog 的 API keys 页面，复制一把 Organization API key。",
        "en": "Open Datadog’s API keys page and copy an Organization API key.",
        "ja": "Datadog の API keys ページを開き、Organization API key をコピーします。"
      },
      {
        "zh": "打开 Datadog 的 Application Keys 页面，签发一把。用量接口两把都要。",
        "en": "Open Datadog’s Application Keys page and issue one. The usage API needs both keys.",
        "ja": "Datadog の Application Keys ページを開き、1 本発行します。用量 API は両方必要です。"
      },
      {
        "zh": "填站点短名。美国站写 us1，欧洲站写 eu。",
        "en": "Fill in the site short name. US is us1, Europe is eu.",
        "ja": "サイト短名を入れてください。米国は us1、欧州は eu です。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "凭据无效。",
          "en": "The credentials are invalid.",
          "ja": "認証情報が無効です。"
        },
        "nextStep": {
          "zh": "回上一步重新复制 API Key 和 Application Key。",
          "en": "Go back a step and copy the API Key and Application Key again.",
          "ja": "前の手順に戻って API Key と Application Key をもう一度コピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把凭据读不到账单。",
          "en": "These credentials can’t read billing.",
          "ja": "この認証情報では請求を読めません。"
        },
        "nextStep": {
          "zh": "确认是父组织、Pro 或 Enterprise，并且站点没填错。",
          "en": "Confirm it’s the parent org, Pro or Enterprise, and the site isn’t wrong.",
          "ja": "親組織の Pro または Enterprise か、サイトの記入も間違っていないか確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://app.datadoghq.com/billing",
    "credentialSetupURL": "https://app.datadoghq.com/organization-settings/api-keys",
    "summary": {
      "zh": "观测平台。按本月估算花费。只要 Pro / Enterprise 父组织，最多延迟 72 小时。",
      "en": "An observability platform. This month’s estimated spend. Parent Pro / Enterprise orgs only, up to 72 hours behind.",
      "ja": "観測プラットフォーム。今月の見積もり支出です。Pro / Enterprise の親組織だけで、最大 72 時間遅れます。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 Datadog Plan & Usage 的 Estimated MTD 一致。免费档和子组织读不到。",
      "en": "This number should match Estimated MTD on Datadog Plan & Usage. Free tiers and child orgs can’t be read.",
      "ja": "この数字は Datadog Plan & Usage の Estimated MTD と一致するはずです。無料枠と子組織は読めません。"
    }
  },
  {
    "key": "backblaze",
    "name": "Backblaze",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "独立对象存储里增长最快之一，相对 S3 仍是利基。",
    "searchKeywords": [
      "b2",
      "backblaze b2",
      "storage"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "账单只在控制台和合作伙伴 CSV，没有账单金额接口。"
  },
  {
    "key": "assemblyai",
    "name": "AssemblyAI",
    "kind": "prepaid",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "语音转写基础设施的强挑战者，调用量大但估值与定位仍低于 Deepgram。",
    "searchKeywords": [
      "assemblyai.com",
      "speech",
      "stt",
      "语音"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "预充值只在控制台，没有公开余额接口。"
  },
  {
    "key": "mux",
    "name": "Mux",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "开发者视频 API 收入自 2021 峰值后停滞。",
    "searchKeywords": [
      "mux.com",
      "video",
      "stream"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "Delivery Usage 只给秒数，没有账单金额。"
  },
  {
    "key": "civo",
    "name": "Civo",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "英国 Kubernetes 简云有增长苗头，但年收入仍是千万级，远未成为行业替代选项。",
    "searchKeywords": [
      "civo.com",
      "kubernetes",
      "k3s"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "Charges API 只给小时数，没有账单金额。"
  },
  {
    "key": "koyeb",
    "name": "Koyeb",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "独立容器 PaaS 已被 Mistral 收购并并入其 AI 基建，该品牌在托管市场的独立轨迹结束。",
    "searchKeywords": [
      "koyeb.com",
      "gpu",
      "serverless"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "pagerduty",
    "name": "PagerDuty",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "仍是企业值班/事件响应的默认品牌，但净留存跌破 100%、ARR 几乎停滞。",
    "searchKeywords": [
      "pagerduty.com",
      "oncall",
      "incident"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [
      {
        "name": {
          "zh": "Professional（每席位）",
          "en": "Professional (per seat)",
          "ja": "Professional（席あたり）"
        },
        "amountUSD": "25",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Professional（年付·每席位）",
          "en": "Professional (annual, per seat)",
          "ja": "Professional（年払い・席あたり）"
        },
        "amountUSD": "252",
        "period": "annual"
      },
      {
        "name": {
          "zh": "Business（每席位）",
          "en": "Business (per seat)",
          "ja": "Business（席あたり）"
        },
        "amountUSD": "49",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Business（年付·每席位）",
          "en": "Business (annual, per seat)",
          "ja": "Business（年払い・席あたり）"
        },
        "amountUSD": "492",
        "period": "annual"
      }
    ],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单接口。"
  },
  {
    "key": "workos",
    "name": "WorkOS",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "B2B SaaS 企业单点登录的开发者默认层。",
    "searchKeywords": [
      "workos.com",
      "sso",
      "directory"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单接口。"
  },
  {
    "key": "contentful",
    "name": "Contentful",
    "kind": "planAndUsage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "无头 CMS 份额第一，已被 Salesforce 收购并并入 Headless 360。",
    "searchKeywords": [
      "contentful.com",
      "cms",
      "headless"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "cloudinary",
    "name": "Cloudinary",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "图像视频变换与 DAM 的领先挑战者，已达亿元级收入。",
    "searchKeywords": [
      "cloudinary.com",
      "image",
      "cdn"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "公开 API 只有用量计数，没有账单金额。"
  },
  {
    "key": "sendgrid",
    "name": "SendGrid",
    "kind": "planAndUsage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "事务邮件检测份额与发送量均居前列，属 Twilio 系寡头。",
    "searchKeywords": [
      "sendgrid.com",
      "twilio sendgrid",
      "email"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "公开 API 只有发送统计，没有账单金额。"
  },
  {
    "key": "mailgun",
    "name": "Mailgun",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "高发送量开发者邮件 API，紧随 SendGrid 的强挑战者。",
    "searchKeywords": [
      "mailgun.com",
      "email"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "公开 API 只有发送统计，没有账单金额。"
  },
  {
    "key": "lambdalabs",
    "name": "Lambda",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "开发者向 GPU 云的核心替代，已被 Synergy 点名为快速扩张的新云之一。",
    "searchKeywords": [
      "lambda labs",
      "lambdalabs",
      "gpu"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "novita",
    "name": "Novita",
    "kind": "prepaid",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "廉价开源推理长尾云，公开融资与收入均远小于 Fireworks/Together。",
    "searchKeywords": [
      "novita.ai",
      "gpu",
      "inference"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true,
        "validation": {
          "zh": "API Key 太短，确认复制完整",
          "en": "API Key is too short. Make sure you copied the whole thing.",
          "ja": "API Key が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Novita 的 Key Management 页面，签发一把。余额接口用这把 key。",
        "en": "Open Novita’s Key Management page and issue a key. The balance API uses this key.",
        "ja": "Novita の Key Management ページを開き、発行します。残高 API はこの key を使います。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "凭据无效。",
          "en": "The credentials are invalid.",
          "ja": "認証情報が無効です。"
        },
        "nextStep": {
          "zh": "回上一步重新签发一把。",
          "en": "Go back a step and issue a new one.",
          "ja": "前の手順に戻って発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把凭据读不到账单。",
          "en": "These credentials can’t read billing.",
          "ja": "この認証情報では請求を読めません。"
        },
        "nextStep": {
          "zh": "确认权限和账号属于同一组织。",
          "en": "Confirm the permission and account belong to the same organization.",
          "ja": "権限とアカウントが同じ組織か確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://novita.ai/billing",
    "credentialSetupURL": "https://novita.ai/settings/key-management",
    "summary": {
      "zh": "GPU 推理平台。预充值，报还剩多少。",
      "en": "A GPU inference platform. Prepaid. It reports how much is left.",
      "ja": "GPU 推論プラットフォーム。プリペイドです。残量を出します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 Novita 后台还剩的余额一致。单位是万分之一美元，这里已经折成美元。",
      "en": "This number should match the remaining balance in the Novita dashboard. The API uses ten-thousandths of a dollar; it’s already converted here.",
      "ja": "この数字は Novita 管理画面の残額と一致するはずです。単位は万分の 1 ドルで、ここではドルに直してあります。"
    }
  },
  {
    "key": "apify",
    "name": "Apify",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "传统爬虫/自动化平台收入稳步千万级，但不是 AI 搜索新贵。",
    "searchKeywords": [
      "apify.com",
      "actor",
      "crawler",
      "scraper"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true,
        "validation": {
          "zh": "API Token 太短，确认复制完整",
          "en": "API Token is too short. Make sure you copied the whole thing.",
          "ja": "API Token が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Apify 的 Integrations 页面，复制 API token。不要把 token 放进 URL。",
        "en": "Open Apify’s Integrations page and copy the API token. Don’t put the token in the URL.",
        "ja": "Apify の Integrations ページを開き、API token をコピーします。token を URL に入れないでください。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "凭据无效。",
          "en": "The credentials are invalid.",
          "ja": "認証情報が無効です。"
        },
        "nextStep": {
          "zh": "回上一步重新复制 API token。",
          "en": "Go back a step and copy the API token again.",
          "ja": "前の手順に戻って API token をもう一度コピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把凭据读不到账单。",
          "en": "These credentials can’t read billing.",
          "ja": "この認証情報では請求を読めません。"
        },
        "nextStep": {
          "zh": "确认 token 能读账号用量。",
          "en": "Confirm the token can read account usage.",
          "ja": "token がアカウント用量を読めるか確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://console.apify.com/billing",
    "credentialSetupURL": "https://console.apify.com/settings/integrations",
    "summary": {
      "zh": "爬虫和 Actor 平台。按本月折完量的美元用量。",
      "en": "A crawler and Actor platform. This month’s usage in USD after discounts.",
      "ja": "クローラと Actor のプラットフォーム。今月の割引後ドル用量です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 Apify Usage 本月折完量的美元一致。",
      "en": "This number should match this month’s discounted USD usage on Apify Usage.",
      "ja": "この数字は Apify Usage の今月の割引後ドルと一致するはずです。"
    }
  },
  {
    "key": "tavily",
    "name": "Tavily",
    "kind": "freeTier",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "曾是 Agent 搜索 API 双雄之一，被 Nebius 收购后独立公司消失、产品仍在。",
    "searchKeywords": [
      "tavily.com",
      "search",
      "search api"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true,
        "hint": {
          "zh": "tvly- 开头",
          "en": "starts with tvly-",
          "ja": "tvly- で始まる"
        },
        "validation": {
          "zh": "API Key 太短，确认复制完整",
          "en": "API Key is too short. Make sure you copied the whole thing.",
          "ja": "API Key が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Tavily 的 Quickstart 文档，在控制台签发一把 API key。读的是本月 credits。",
        "en": "Open Tavily’s Quickstart docs and issue an API key in the dashboard. It reads this month’s credits.",
        "ja": "Tavily の Quickstart のドキュメントを開き、ダッシュボードで API key を発行します。今月の credits を読みます。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "凭据无效。",
          "en": "The credentials are invalid.",
          "ja": "認証情報が無効です。"
        },
        "nextStep": {
          "zh": "回上一步重新签发一把。",
          "en": "Go back a step and issue a new one.",
          "ja": "前の手順に戻って発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把凭据读不到用量。",
          "en": "These credentials can’t read usage.",
          "ja": "この認証情報では用量を読めません。"
        },
        "nextStep": {
          "zh": "确认 key 能读账号用量。",
          "en": "Confirm the key can read account usage.",
          "ja": "key がアカウント用量を読めるか確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://app.tavily.com",
    "credentialSetupURL": "https://docs.tavily.com/documentation/quickstart",
    "summary": {
      "zh": "搜索 API。按本月 credits 额度占比，不报钱。",
      "en": "A search API. This month’s credits quota percent. It doesn’t report dollars.",
      "ja": "検索 API。今月の credits 枠の割合で、金額は出しません。"
    },
    "verifyHint": {
      "zh": "这个百分比对应 Tavily 本月 plan credits。各档单价不一样，这里不报钱。",
      "en": "This percent is this month’s Tavily plan credits. Unit prices differ by plan, so it doesn’t report dollars.",
      "ja": "この割合は Tavily の今月 plan credits です。プランで単価が違うので、金額は出しません。"
    }
  },
  {
    "key": "deepinfra",
    "name": "DeepInfra",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "以低价开源推理抢量的强挑战者，已拿到过亿美元融资但仍非收入寡头。",
    "searchKeywords": [
      "deepinfra.com",
      "inference",
      "gpu"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true,
        "validation": {
          "zh": "API Key 太短，确认复制完整",
          "en": "API Key is too short. Make sure you copied the whole thing.",
          "ja": "API Key が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 DeepInfra 的 Authentication 文档，在控制台签发一把。读的是本月 usage。",
        "en": "Open DeepInfra’s Authentication docs and issue a key in the dashboard. It reads this month’s usage.",
        "ja": "DeepInfra の Authentication のドキュメントを開き、ダッシュボードで発行します。読むのは今月の usage です。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "凭据无效。",
          "en": "The credentials are invalid.",
          "ja": "認証情報が無効です。"
        },
        "nextStep": {
          "zh": "回上一步重新签发一把。",
          "en": "Go back a step and issue a new one.",
          "ja": "前の手順に戻って発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把凭据读不到账单。",
          "en": "These credentials can’t read billing.",
          "ja": "この認証情報では請求を読めません。"
        },
        "nextStep": {
          "zh": "确认权限和账号属于同一组织。",
          "en": "Confirm the permission and account belong to the same organization.",
          "ja": "権限とアカウントが同じ組織か確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://deepinfra.com/dash",
    "credentialSetupURL": "https://docs.deepinfra.com/account/authentication",
    "summary": {
      "zh": "推理平台。按本月已计价花费。",
      "en": "An inference platform. This month’s already-priced spend.",
      "ja": "推論プラットフォーム。今月のすでに計上された支出です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 DeepInfra Usage 本月合计一致。接口给的是美分。",
      "en": "This number should match this month’s DeepInfra Usage total. The API reports cents.",
      "ja": "この数字は DeepInfra Usage の今月合計と一致するはずです。API はセント単位です。"
    }
  },
  {
    "key": "vastai",
    "name": "Vast.ai",
    "kind": "prepaid",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "点对点 GPU 市场是预算盘常选项，供给可观但收入与可靠性都达不到行业替代量级。",
    "searchKeywords": [
      "vast.ai",
      "vastai",
      "gpu",
      "marketplace"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true,
        "validation": {
          "zh": "API Key 太短，确认复制完整",
          "en": "API Key is too short. Make sure you copied the whole thing.",
          "ja": "API Key が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Vast.ai 的 Keys 页面，签发一把。读的是账号 credit。",
        "en": "Open the Vast.ai Keys page and issue a key. It reads account credit.",
        "ja": "Vast.ai の Keys ページを開き、発行します。アカウントの credit を読みます。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "凭据无效。",
          "en": "The credentials are invalid.",
          "ja": "認証情報が無効です。"
        },
        "nextStep": {
          "zh": "回上一步重新签发一把。",
          "en": "Go back a step and issue a new one.",
          "ja": "前の手順に戻って発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把凭据读不到余额。",
          "en": "These credentials can’t read the balance.",
          "ja": "この認証情報では残高を読めません。"
        },
        "nextStep": {
          "zh": "确认 key 有读账号的权限。",
          "en": "Confirm the key can read the account.",
          "ja": "key にアカウント読み取り権限があるか確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://cloud.vast.ai",
    "credentialSetupURL": "https://cloud.vast.ai/manage-keys/",
    "summary": {
      "zh": "GPU 市场。预充值，报还剩多少。",
      "en": "A GPU marketplace. Prepaid. It reports how much is left.",
      "ja": "GPU マーケット。プリペイドです。残量を出します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 Vast.ai 后台还剩的 credit 一致。",
      "en": "This number should match remaining credit in the Vast.ai dashboard.",
      "ja": "この数字は Vast.ai 管理画面の残り credit と一致するはずです。"
    }
  },
  {
    "key": "firecrawl",
    "name": "Firecrawl",
    "kind": "freeTier",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "AI 爬取转 Markdown 的开发者新秀，规模仍小。",
    "searchKeywords": [
      "firecrawl.dev",
      "scrape",
      "crawl"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true,
        "validation": {
          "zh": "API Key 太短，确认复制完整",
          "en": "API Key is too short. Make sure you copied the whole thing.",
          "ja": "API Key が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Firecrawl 的 API keys 页面，签发一把。读的是团队还剩的 credits。",
        "en": "Open Firecrawl’s API keys page and issue a key. It reads the team’s remaining credits.",
        "ja": "Firecrawl の API keys ページを開き、発行します。チームに残っている credits を読みます。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "凭据无效。",
          "en": "The credentials are invalid.",
          "ja": "認証情報が無効です。"
        },
        "nextStep": {
          "zh": "回上一步重新签发一把。",
          "en": "Go back a step and issue a new one.",
          "ja": "前の手順に戻って発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把凭据读不到用量。",
          "en": "These credentials can’t read usage.",
          "ja": "この認証情報では用量を読めません。"
        },
        "nextStep": {
          "zh": "确认 key 能读这个团队。",
          "en": "Confirm the key can read this team.",
          "ja": "key がこのチームを読めるか確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.firecrawl.dev/app/billing",
    "credentialSetupURL": "https://www.firecrawl.dev/app/api-keys",
    "summary": {
      "zh": "网页抓取。按本月 credits 额度占比，不报钱。",
      "en": "Web crawling. This month’s credits quota percent. It doesn’t report dollars.",
      "ja": "ウェブクローリング。今月の credits 枠の割合で、金額は出しません。"
    },
    "verifyHint": {
      "zh": "这个百分比对应 Firecrawl 本月 plan credits。各档单价不一样，这里不报钱。",
      "en": "This percent is this month’s Firecrawl plan credits. Unit prices differ by plan, so it doesn’t report dollars.",
      "ja": "この割合は Firecrawl の今月 plan credits です。プランで単価が違うので、金額は出しません。"
    }
  },
  {
    "key": "cockroach",
    "name": "CockroachDB Cloud",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "独立分布式 SQL 的企业级代表，融资估值高但近年无新一轮、排名偏后。",
    "searchKeywords": [
      "cockroachdb",
      "cockroach labs",
      "crdb",
      "postgres"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "Secret Key",
          "en": "Secret Key",
          "ja": "Secret Key"
        },
        "isSecret": true,
        "validation": {
          "zh": "Secret Key 太短，确认复制完整",
          "en": "Secret Key is too short. Make sure you copied the whole thing.",
          "ja": "Secret Key が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 CockroachDB Cloud 的 managing-access 文档，给服务账号 Billing Coordinator，再签发一把 secret key。",
        "en": "Open CockroachDB Cloud’s managing-access docs, give the service account Billing Coordinator, then issue a secret key.",
        "ja": "CockroachDB Cloud の managing-access のドキュメントを開き、サービスアカウントに Billing Coordinator を付けてから secret key を発行します。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "凭据无效。",
          "en": "The credentials are invalid.",
          "ja": "認証情報が無効です。"
        },
        "nextStep": {
          "zh": "回上一步重新签发一把。",
          "en": "Go back a step and issue a new one.",
          "ja": "前の手順に戻って発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把凭据读不到账单。",
          "en": "These credentials can’t read billing.",
          "ja": "この認証情報では請求を読めません。"
        },
        "nextStep": {
          "zh": "确认服务账号有 Billing Coordinator 或 Cluster Admin。",
          "en": "Confirm the service account has Billing Coordinator or Cluster Admin.",
          "ja": "サービスアカウントに Billing Coordinator または Cluster Admin があるか確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://cockroachlabs.cloud",
    "credentialSetupURL": "https://www.cockroachlabs.com/docs/cockroachcloud/managing-access",
    "summary": {
      "zh": "托管数据库。按本周期草稿发票。",
      "en": "A managed database. The draft invoice for this cycle.",
      "ja": "マネージドデータベース。本周期の下書きインボイスです。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 CockroachDB Cloud 本周期草稿发票合计一致。",
      "en": "This number should match the draft invoice total for this cycle on CockroachDB Cloud.",
      "ja": "この数字は CockroachDB Cloud の本周期下書きインボイス合計と一致するはずです。"
    }
  },
  {
    "key": "typesense",
    "name": "Typesense Cloud",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "零融资仍能靠 Cloud 养活的开源搜索，体量比 Algolia/Elastic 小一个数量级。",
    "searchKeywords": [
      "typesense.org",
      "search",
      "search engine"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "Management API Key",
          "en": "Management API Key",
          "ja": "Management API Key"
        },
        "isSecret": true,
        "validation": {
          "zh": "Management API Key 太短，确认复制完整",
          "en": "Management API Key is too short. Make sure you copied the whole thing.",
          "ja": "Management API Key が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Typesense Cloud 的 Cloud Management API 文档，签发一把 Management API Key。",
        "en": "Open the Typesense Cloud Cloud Management API docs and issue a Management API Key.",
        "ja": "Typesense Cloud の Cloud Management API のドキュメントを開き、Management API Key を発行します。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "凭据无效。",
          "en": "The credentials are invalid.",
          "ja": "認証情報が無効です。"
        },
        "nextStep": {
          "zh": "回上一步重新签发一把。",
          "en": "Go back a step and issue a new one.",
          "ja": "前の手順に戻って発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把凭据读不到账单。",
          "en": "These credentials can’t read billing.",
          "ja": "この認証情報では請求を読めません。"
        },
        "nextStep": {
          "zh": "确认是 Management API Key，不是集群搜索 key。",
          "en": "Confirm it’s a Management API Key, not a cluster search key.",
          "ja": "クラスタ検索 key ではなく Management API Key か確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://cloud.typesense.org",
    "credentialSetupURL": "https://typesense.org/docs/cloud-management-api/v1/",
    "summary": {
      "zh": "托管搜索。按本月已出账发票合计。按周出账，当周可能还没出来。",
      "en": "Managed search. Sum of invoiced bills this month. Invoices are weekly, so this week may still be missing.",
      "ja": "マネージド検索。今月の出帳済みインボイス合計です。週次出帳なので、今週分はまだないことがあります。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 Typesense Cloud 本月已出账发票合计一致。按周出账，当周可能还没有。",
      "en": "This number should match this month’s invoiced total on Typesense Cloud. Invoices are weekly, so this week may still be missing.",
      "ja": "この数字は Typesense Cloud の今月の出帳済みインボイス合計と一致するはずです。週次出帳なので、今週分はまだないことがあります。"
    }
  },
  {
    "key": "cerebras",
    "name": "Cerebras",
    "kind": "prepaid",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "晶圆级推理的独特挑战者，拿得到大单但不是通用 LLM API 寡头。",
    "searchKeywords": [
      "cerebras.ai",
      "inference",
      "wafer"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "预充值只在控制台，没有公开余额接口。"
  },
  {
    "key": "cartesia",
    "name": "Cartesia",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "实时 TTS 延迟与音质标杆，融资近两亿美元，但收入体量远小于 ElevenLabs。",
    "searchKeywords": [
      "cartesia.ai",
      "tts",
      "sonic",
      "voice"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "TTS 是 credits，Agent 才是美元，没有一份能对账的总账单。"
  },
  {
    "key": "helicone",
    "name": "Helicone",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "开源网关型观测规模远小于 Langfuse，且有被收购后进入维护模式的报道。",
    "searchKeywords": [
      "helicone.ai",
      "llm ops",
      "gateway"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "公开 API 估的是下游 LLM 花费，不是付给 Helicone 的账单。"
  },
  {
    "key": "wasabi",
    "name": "Wasabi",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "独立廉价对象存储的领先挑战者，客户与收入均大于 B2。",
    "searchKeywords": [
      "wasabi.com",
      "object storage",
      "s3"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "账单金额只在合作伙伴 WACM，客户没有账单接口。"
  },
  {
    "key": "coreweave",
    "name": "CoreWeave",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "GPU 云新云里体量碾压同侪，与超大规模云一起切走企业级 GPU 训练/推理订单。",
    "searchKeywords": [
      "coreweave.com",
      "gpu",
      "kubernetes"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "账单只在控制台，公开接口没有账单金额。"
  },
  {
    "key": "honeycomb",
    "name": "Honeycomb",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "高基数查询的远见者，规模远小于 Datadog/Grafana，但仍连年留在分析师视野象限。",
    "searchKeywords": [
      "honeycomb.io",
      "observability",
      "tracing"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "newrelic",
    "name": "New Relic",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "仍是可观测平台的大型在位者，但企业支出意愿已掉到垫底。",
    "searchKeywords": [
      "new relic",
      "newrelic.com",
      "apm",
      "observability"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "NerdGraph / NRQL 只给 GB 和席位，金额要自己乘单价。"
  },
  {
    "key": "weaviate",
    "name": "Weaviate Cloud",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "混合检索向量库仍有机构加持，但开源热度与融资估值已落后于 Qdrant。",
    "searchKeywords": [
      "weaviate.io",
      "vector",
      "wcd"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "triggerdev",
    "name": "Trigger.dev",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "TypeScript 持久任务的小型开源挑战者，社区热度高于 Inngest 但仍是利基。",
    "searchKeywords": [
      "trigger.dev",
      "jobs",
      "background"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "aiven",
    "name": "Aiven",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "独立托管开源数据平台已过亿美元 ARR，是云厂商托管 Kafka/Postgres 的主要替代。",
    "searchKeywords": [
      "aiven.io",
      "kafka",
      "opensearch",
      "postgres",
      "mysql"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "Personal Token",
          "en": "Personal Token",
          "ja": "Personal Token"
        },
        "isSecret": true,
        "validation": {
          "zh": "Token 太短，确认复制完整",
          "en": "Token is too short. Make sure you copied the whole thing.",
          "ja": "Token が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Aiven 的 Create personal tokens 文档，在控制台 User information 的 Tokens 页签发一把。认证头是 aivenv1。",
        "en": "Open Aiven’s Create personal tokens docs, then issue one on the Tokens page under User information. The auth header is aivenv1.",
        "ja": "Aiven の Create personal tokens のドキュメントを開き、コンソールの User information の Tokens ページで発行します。認証ヘッダは aivenv1 です。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "凭据无效。",
          "en": "The credentials are invalid.",
          "ja": "認証情報が無効です。"
        },
        "nextStep": {
          "zh": "回上一步重新签发一把。",
          "en": "Go back a step and issue a new one.",
          "ja": "前の手順に戻って発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把凭据读不到账单。",
          "en": "These credentials can’t read billing.",
          "ja": "この認証情報では請求を読めません。"
        },
        "nextStep": {
          "zh": "确认 token 能读计费组。",
          "en": "Confirm the token can read billing groups.",
          "ja": "token が課金グループを読めるか確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://console.aiven.io",
    "credentialSetupURL": "https://aiven.io/docs/platform/howto/create_authentication_token",
    "summary": {
      "zh": "托管数据基础设施。按本周期税前预估花费。",
      "en": "Managed data infrastructure. Estimated pre-tax spend for this cycle.",
      "ja": "マネージドデータ基盤。本周期の税引前見積もりです。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 Aiven 各计费组本周期税前预估合计一致。",
      "en": "This number should match Aiven’s estimated pre-tax total across billing groups for this cycle.",
      "ja": "この数字は Aiven の各課金グループの本周期税引前見積もりの合計と一致するはずです。"
    }
  },
  {
    "key": "siliconflow",
    "name": "SiliconFlow",
    "kind": "prepaid",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "中国最大独立 token 工厂，但全国份额仅约 1.5%，收入仍很小。",
    "searchKeywords": [
      "硅基流动",
      "silicon flow",
      "siliconcloud",
      "国内"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true,
        "validation": {
          "zh": "API Key 太短，确认复制完整",
          "en": "API Key is too short. Make sure you copied the whole thing.",
          "ja": "API Key が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 SiliconFlow 的 API 密钥页面，签发一把。读的是 API key 账号余额。",
        "en": "Open the SiliconFlow API keys page and issue a key. It reads the API key account balance.",
        "ja": "SiliconFlow の API キーのページを開き、発行します。API key アカウントの残高を読みます。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "凭据无效。",
          "en": "The credentials are invalid.",
          "ja": "認証情報が無効です。"
        },
        "nextStep": {
          "zh": "回上一步重新签发一把。",
          "en": "Go back a step and issue a new one.",
          "ja": "前の手順に戻って発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "官方余额的币种不在汇率表里，没法折成美元。",
          "en": "The official balance’s currency isn’t in the rate table, so it can’t convert to USD.",
          "ja": "公式残高の通貨が為替表にないため、ドルに換算できません。"
        },
        "nextStep": {
          "zh": "改成手工录入本月花费。",
          "en": "Switch to entering this month’s spend by hand.",
          "ja": "今月の支出を手入力に切り替えてください。"
        },
        "httpStatus": 200
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://cloud.siliconflow.cn/account/billing",
    "credentialSetupURL": "https://cloud.siliconflow.cn/account/ak",
    "summary": {
      "zh": "硅基流动国内站。预充值，人民币余额会折成美元。",
      "en": "SiliconFlow China. Prepaid. A CNY balance is converted to USD.",
      "ja": "SiliconFlow 国内サイト。プリペイドで、人民元残高はドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个余额应该和 SiliconFlow 后台 API key 账号还剩的人民币对得上。新云平台网页钱包不走这条接口。",
      "en": "This balance should match the remaining CNY on the SiliconFlow API key account. The new-console web wallet doesn’t use this API.",
      "ja": "この残高は SiliconFlow 管理画面の API key アカウントに残る人民元と一致するはずです。新しいクラウドのウェブウォレットはこの API を使いません。"
    }
  },
  {
    "key": "aimlapi",
    "name": "AI/ML API",
    "kind": "prepaid",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "无融资的多模型聚合器，体量远小于 OpenRouter，属长尾网关。",
    "searchKeywords": [
      "aimlapi",
      "ai/ml api",
      "aiml"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true,
        "validation": {
          "zh": "API Key 太短，确认复制完整",
          "en": "API Key is too short. Make sure you copied the whole thing.",
          "ja": "API Key が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 AI/ML API 的 Keys 页面，签发一把普通 API key。不要用 management key。",
        "en": "Open the Keys page for AI/ML API and issue a regular API key. Don’t use a management key.",
        "ja": "AI/ML API の Keys ページを開き、通常の API key を発行します。management key は使わないでください。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "凭据无效。",
          "en": "The credentials are invalid.",
          "ja": "認証情報が無効です。"
        },
        "nextStep": {
          "zh": "回上一步重新签发一把。",
          "en": "Go back a step and issue a new one.",
          "ja": "前の手順に戻って発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把凭据读不到账单。",
          "en": "These credentials can’t read billing.",
          "ja": "この認証情報では請求を読めません。"
        },
        "nextStep": {
          "zh": "确认是普通 API key，不是 management key。",
          "en": "Confirm it’s a regular API key, not a management key.",
          "ja": "management key ではなく通常の API key か確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://aimlapi.com/app/billing",
    "credentialSetupURL": "https://aimlapi.com/app/keys",
    "summary": {
      "zh": "多模型聚合。预充值，报还剩多少美元。",
      "en": "A multi-model aggregator. Prepaid. It reports remaining USD.",
      "ja": "マルチモデル集約。プリペイドです。残りのドルを出します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 AI/ML API 后台还剩的美元余额一致。",
      "en": "This number should match the remaining USD balance in the AI/ML API dashboard.",
      "ja": "この数字は AI/ML API 管理画面の残りのドル残高と一致するはずです。"
    }
  },
  {
    "key": "stepfun",
    "name": "StepFun (China)",
    "kind": "prepaid",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "有上市路径和多模态产品，但网关份额与收入仍明显落后月之暗面、智谱、MiniMax。",
    "searchKeywords": [
      "阶跃星辰",
      "stepfun",
      "step-1",
      "国内",
      "china"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true,
        "validation": {
          "zh": "Key 太短，确认复制完整",
          "en": "Key is too short. Make sure you copied the whole thing.",
          "ja": "Key が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 StepFun (China) 的 API keys 页面，签发一把 key 并复制。国际站请加 StepFun (Overseas)。",
        "en": "Open the API keys page for StepFun (China), issue a key, and copy it. For the overseas site, add StepFun (Overseas).",
        "ja": "StepFun (China) の API keys ページを開き、key を発行してコピーします。国際サイトは StepFun (Overseas) を追加してください。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把 key 无效，或用了另一站的 key。",
          "en": "This key is invalid, or it’s from the other site.",
          "ja": "この key は無効か、別サイトの key です。"
        },
        "nextStep": {
          "zh": "确认 key 来自 platform.stepfun.com。国际站的 key 去加 StepFun (Overseas)。",
          "en": "Confirm the key is from platform.stepfun.com. An overseas key belongs on StepFun (Overseas).",
          "ja": "key が platform.stepfun.com のものか確認してください。国際サイトの key は StepFun (Overseas) に追加します。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "官方余额的币种不在汇率表里，没法折成美元。",
          "en": "The official balance’s currency isn’t in the rate table, so it can’t convert to USD.",
          "ja": "公式残高の通貨が為替表にないため、ドルに換算できません。"
        },
        "nextStep": {
          "zh": "改成手工录入本月花费。",
          "en": "Switch to entering this month’s spend by hand.",
          "ja": "今月の支出を手入力に切り替えてください。"
        },
        "httpStatus": 200
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://platform.stepfun.com/console/billing",
    "credentialSetupURL": "https://platform.stepfun.com/console/api-keys",
    "summary": {
      "zh": "StepFun 国内站（阶跃星辰）。预充值，人民币余额会折成美元。",
      "en": "StepFun China. Prepaid. A CNY balance is converted to USD.",
      "ja": "StepFun 国内サイト（階跃星辰）。プリペイドで、人民元残高はドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个余额应该和 StepFun (China) 充值页看到的人民币余额对得上。App 里按汇率折成美元显示。",
      "en": "This balance should match the CNY balance on the StepFun (China) top-up page. The app converts it to USD at the catalog rate.",
      "ja": "この残高は StepFun (China) のチャージページの人民元残高と一致するはずです。App では為替でドル表示します。"
    }
  },
  {
    "key": "stepfunai",
    "name": "StepFun (Overseas)",
    "kind": "prepaid",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "与国内阶跃星辰同一公司的海外 API，份额与收入仍属第二阵营之后的成长股。",
    "searchKeywords": [
      "阶跃星辰",
      "stepfun",
      "step-1",
      "海外",
      "国际",
      "oversea",
      "overseas"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true,
        "validation": {
          "zh": "Key 太短，确认复制完整",
          "en": "Key is too short. Make sure you copied the whole thing.",
          "ja": "Key が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 StepFun (Overseas) 的 API keys 页面，签发一把 key 并复制。国内站请加 StepFun (China)。",
        "en": "Open the API keys page for StepFun (Overseas), issue a key, and copy it. For the China site, add StepFun (China).",
        "ja": "StepFun (Overseas) の API keys ページを開き、key を発行してコピーします。国内サイトは StepFun (China) を追加してください。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把 key 无效，或用了国内站的 key。",
          "en": "This key is invalid, or it’s a China-site key.",
          "ja": "この key は無効か、国内サイトの key です。"
        },
        "nextStep": {
          "zh": "确认 key 来自 platform.stepfun.ai。国内站的 key 去加 StepFun (China)。",
          "en": "Confirm the key is from platform.stepfun.ai. A China-site key belongs on StepFun (China).",
          "ja": "key が platform.stepfun.ai のものか確認してください。国内サイトの key は StepFun (China) に追加します。"
        },
        "httpStatus": 401
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://platform.stepfun.ai/console/billing",
    "credentialSetupURL": "https://platform.stepfun.ai/console/api-keys",
    "summary": {
      "zh": "StepFun 国际站。预充值，美元余额。",
      "en": "StepFun overseas. Prepaid, with a USD balance.",
      "ja": "StepFun 国際サイト。プリペイドで、残高はドルです。"
    },
    "verifyHint": {
      "zh": "这个余额应该和 StepFun (Overseas) 充值页看到的美元余额对得上。",
      "en": "This balance should match the USD balance on the StepFun (Overseas) top-up page.",
      "ja": "この残高は StepFun (Overseas) のチャージページのドル残高と一致するはずです。"
    }
  },
  {
    "key": "telnyx",
    "name": "Telnyx",
    "kind": "prepaid",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "自建全球 IP 网的新晋利基玩家，刚进入分析师象限。",
    "searchKeywords": [
      "telnyx.com",
      "sip",
      "sms",
      "voice",
      "telecom"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true,
        "validation": {
          "zh": "API Key 太短，确认复制完整",
          "en": "API Key is too short. Make sure you copied the whole thing.",
          "ja": "API Key が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Telnyx 的 API Keys 页面，签发一把。读的是账号还剩的余额，不含授信。",
        "en": "Open the Telnyx API Keys page and issue a key. It reads remaining account balance, not credit lines.",
        "ja": "Telnyx の API Keys ページを開き、発行します。口座の残高を読み、与信は含みません。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "凭据无效。",
          "en": "The credentials are invalid.",
          "ja": "認証情報が無効です。"
        },
        "nextStep": {
          "zh": "回上一步重新签发一把。",
          "en": "Go back a step and issue a new one.",
          "ja": "前の手順に戻って発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把凭据读不到余额。",
          "en": "These credentials can’t read the balance.",
          "ja": "この認証情報では残高を読めません。"
        },
        "nextStep": {
          "zh": "确认 key 能读账号账单。",
          "en": "Confirm the key can read account billing.",
          "ja": "key がアカウント請求を読めるか確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://portal.telnyx.com/#/app/billing",
    "credentialSetupURL": "https://portal.telnyx.com/#/app/api-keys",
    "summary": {
      "zh": "通信平台。预充值，报还剩多少。",
      "en": "A communications platform. Prepaid. It reports how much is left.",
      "ja": "通信プラットフォーム。プリペイドです。残量を出します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 Telnyx 后台还剩的余额一致。授信额度不算进去。",
      "en": "This number should match the remaining balance in the Telnyx dashboard. Credit lines are not included.",
      "ja": "この数字は Telnyx 管理画面の残額と一致するはずです。与信は含みません。"
    }
  },
  {
    "key": "minimax",
    "name": "MiniMax",
    "kind": "prepaid",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "上市后 B2B/API 收入快速爬升、网关份额进入第一梯队，但仍未分食企业支出寡头。",
    "searchKeywords": [
      "minimax.io",
      "minimax.com",
      "abab",
      "海螺"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "Token Plan 接口只给配额窗口，不是按量美元余额。"
  },
  {
    "key": "hyperbolic",
    "name": "Hyperbolic",
    "kind": "prepaid",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "开放 GPU 市场仍是早期小盘，有融资但远未进入企业 GPU 短名单。",
    "searchKeywords": [
      "hyperbolic.xyz",
      "gpu",
      "inference"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开余额或账单金额接口。"
  },
  {
    "key": "jina",
    "name": "Jina",
    "kind": "prepaid",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "Reader 等 API 有开发者口碑，但已被 Elastic 收编，独立体量小于 Exa/Tavily。",
    "searchKeywords": [
      "jina.ai",
      "embeddings",
      "reader"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "dashscope",
    "name": "DashScope",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "中国企业级 token 市占领先，通义千问是国内 MaaS 寡头之一。",
    "searchKeywords": [
      "通义",
      "qwen",
      "aliyun",
      "alibaba",
      "dashscope"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "账单走阿里云 BSS 整云账号，没有单独的通义账单接口。"
  },
  {
    "key": "paperspace",
    "name": "Paperspace",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "品牌已被 DigitalOcean 收编并导向 GPU Droplets，独立 GPU 云轨迹结束。",
    "searchKeywords": [
      "paperspace.com",
      "gradient",
      "gpu"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "salad",
    "name": "Salad",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "闲置消费级 GPU 网络仍在运营，但规模停留在分布式算力长尾。",
    "searchKeywords": [
      "salad.com",
      "saladcloud",
      "gpu"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "browserbase",
    "name": "Browserbase",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "浏览器基础设施新秀，会话量在涨但收入仍小，属于有前景的第三梯队。",
    "searchKeywords": [
      "browserbase.com",
      "browser",
      "playwright"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "convex",
    "name": "Convex",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "响应式 TypeScript 后端在 AI 编程潮中融资加速，体量仍远小于 Supabase。",
    "searchKeywords": [
      "convex.dev",
      "backend",
      "database"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "langfuse",
    "name": "Langfuse",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "开源 LLM 观测的默认选项，品类仍小、尚未进入通用可观测寡头。",
    "searchKeywords": [
      "langfuse.com",
      "llm ops",
      "observability"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "gcore",
    "name": "Gcore",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "CDN+边缘/GPU 云收入过亿美元且两年近翻倍，仍是挑战者而非该品类寡头。",
    "searchKeywords": [
      "gcore.com",
      "cdn",
      "gpu",
      "reservation"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Gcore 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Gcore dashboard, create API Key, then copy it.",
        "ja": "Gcore ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://gcore.com/cloud",
    "credentialSetupURL": "https://gcore.com/docs/account-settings/api-tokens",
    "summary": {
      "zh": "CDN、边缘和 GPU 云。按月度成本报告，含包月和按量。",
      "en": "CDN, edge, and GPU cloud. The monthly cost report, including commit and pay-as-you-go.",
      "ja": "CDN、エッジ、GPU クラウド。月次コスト報告で、コミットと従量を含みます。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "contabo",
    "name": "Contabo",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "德国廉价 VPS 长尾品牌仍有爱好者盘，但未进入主流云份额统计。",
    "searchKeywords": [
      "contabo.com",
      "vps"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "northflank",
    "name": "Northflank",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "BYOC/微服务 PaaS 有产品完成度，但仍是小而美，尚未进入主流替代短名单。",
    "searchKeywords": [
      "northflank.com",
      "paas"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Northflank 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the Northflank dashboard, create API Token, then copy it.",
        "ja": "Northflank ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://app.northflank.com/",
    "credentialSetupURL": "https://northflank.com/docs/v1/api/auth",
    "summary": {
      "zh": "微服务和 BYOC 托管。按本月已出账发票合计。",
      "en": "Microservices and BYOC hosting. This month’s issued invoices, summed.",
      "ja": "マイクロサービスと BYOC ホスティング。今月の出帳済みインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "inngest",
    "name": "Inngest",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "事件驱动持久工作流的利基玩家，规模与知名度都小于 Trigger.dev 与 n8n。",
    "searchKeywords": [
      "inngest.com",
      "jobs",
      "background"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "tinybird",
    "name": "Tinybird",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "托管 ClickHouse 分析层在母公司云业务爆发后被挤压，2025 年裁员一半。",
    "searchKeywords": [
      "tinybird.co",
      "analytics",
      "clickhouse"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "livekit",
    "name": "LiveKit",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "实时音视频与语音 AI 基建的爆发挑战者，已承接 ChatGPT 语音。",
    "searchKeywords": [
      "livekit.io",
      "webrtc",
      "video"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "meilisearch",
    "name": "Meilisearch Cloud",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "MIT 开源即时搜索的有资金挑战者，社区大于 Typesense 但仍远小于 Algolia。",
    "searchKeywords": [
      "meilisearch.com",
      "search"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "账单只在控制台，没有公开账单金额接口。"
  },
  {
    "key": "motherduck",
    "name": "MotherDuck",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "DuckDB 云化代表，融资与引擎热度上升，但相对 Snowflake/BigQuery 仍是小玩家。",
    "searchKeywords": [
      "motherduck.com",
      "duckdb"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "公开接口只有 CU 小时，没有账单金额。"
  },
  {
    "key": "zhipu",
    "name": "Zhipu",
    "kind": "prepaid",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "港股上市后 API 收入与网关流量均进入全球前五，是最强的非寡头挑战者之一。",
    "searchKeywords": [
      "智谱",
      "glm",
      "z.ai",
      "bigmodel",
      "chatglm"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "公开接口没有一份能对账的总账单，只有套餐配额。"
  },
  {
    "key": "mariadb",
    "name": "MariaDB Cloud",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "引擎仍居前二十，但公司 SPAC 后被私有化、云业务几经分拆回购，份额远小于 RDS/Aurora。",
    "searchKeywords": [
      "skysql",
      "mariadb.com",
      "mysql",
      "数据库"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true,
        "validation": {
          "zh": "API Key 太短，确认复制完整",
          "en": "API Key is too short. Make sure you copied the whole thing.",
          "ja": "API Key が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 MariaDB Cloud 的 API keys 页面，签发一把。请求头是 X-API-Key。",
        "en": "Open the MariaDB Cloud API keys page and issue a key. The request header is X-API-Key.",
        "ja": "MariaDB Cloud の API keys ページを開き、発行します。リクエストヘッダは X-API-Key です。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "凭据无效。",
          "en": "The credentials are invalid.",
          "ja": "認証情報が無効です。"
        },
        "nextStep": {
          "zh": "回上一步重新签发一把。",
          "en": "Go back a step and issue a new one.",
          "ja": "前の手順に戻って発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把凭据读不到账单。",
          "en": "These credentials can’t read billing.",
          "ja": "この認証情報では請求を読めません。"
        },
        "nextStep": {
          "zh": "确认权限和账号属于同一组织。",
          "en": "Confirm the permission and account belong to the same organization.",
          "ja": "権限とアカウントが同じ組織か確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://app.skysql.com",
    "credentialSetupURL": "https://app.skysql.com/user-profile/api-keys",
    "summary": {
      "zh": "托管 MariaDB。按本月用量分摊合计。",
      "en": "Managed MariaDB. This month’s usage, prorated and summed.",
      "ja": "マネージド MariaDB。今月の用量按分の合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 MariaDB Cloud 本月用量分摊合计一致。",
      "en": "This number should match this month’s prorated usage total on MariaDB Cloud.",
      "ja": "この数字は MariaDB Cloud の今月用量按分合計と一致するはずです。"
    }
  },
  {
    "key": "ionos",
    "name": "IONOS Cloud",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "欧洲主机龙头的 Cloud 业务在增长，但只占集团约一成，IaaS 份额远落后市场增速。",
    "searchKeywords": [
      "ionos.com",
      "1and1",
      "1&1",
      "dcd"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "Authentication Token",
          "en": "Authentication Token",
          "ja": "Authentication Token"
        },
        "isSecret": true,
        "validation": {
          "zh": "Authentication Token 太短，确认复制完整",
          "en": "Authentication Token is too short. Make sure you copied the whole thing.",
          "ja": "Authentication Token が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 IONOS Cloud 的 Token Manager 文档，在 DCD 的 Management 里 Token Manager 签发一把。认证头是 Bearer。月末才出当月发票。",
        "en": "Open the IONOS Cloud Token Manager docs and issue a token in Token Manager under DCD Management. The auth header is Bearer. The current-month invoice only appears at month-end.",
        "ja": "IONOS Cloud の Token Manager のドキュメントを開き、DCD の Management の Token Manager で発行します。認証ヘッダは Bearer です。当月インボイスは月末に出ます。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "凭据无效。",
          "en": "The credentials are invalid.",
          "ja": "認証情報が無効です。"
        },
        "nextStep": {
          "zh": "回上一步重新签发一把。",
          "en": "Go back a step and issue a new one.",
          "ja": "前の手順に戻って発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把凭据读不到账单。",
          "en": "These credentials can’t read billing.",
          "ja": "この認証情報では請求を読めません。"
        },
        "nextStep": {
          "zh": "确认权限和账号属于同一组织。",
          "en": "Confirm the permission and account belong to the same organization.",
          "ja": "権限とアカウントが同じ組織か確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://dcd.ionos.com",
    "summary": {
      "zh": "欧洲云主机。按当月发票合计，欧元会折成美元。月末才出当月发票。",
      "en": "European cloud hosts. Sum of this month’s invoices. Euros convert to USD. The current-month invoice only appears at month-end.",
      "ja": "欧州のクラウドホスト。当月インボイス合計で、ユーロはドルに換算します。当月インボイスは月末に出ます。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 IONOS Cloud 当月发票合计一致。当月那张可能还没出。",
      "en": "This number should match this month’s invoice total on IONOS Cloud. The current-month invoice may not be out yet.",
      "ja": "この数字は IONOS Cloud の当月インボイス合計と一致するはずです。当月分はまだ出ていないことがあります。"
    }
  },
  {
    "key": "upcloud",
    "name": "UpCloud",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "北欧高性能 VPS 利基玩家，有区域口碑但融资与体量长期停在小型独立云。",
    "searchKeywords": [
      "upcloud.com",
      "maximap",
      "芬兰"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true,
        "validation": {
          "zh": "API Token 太短，确认复制完整",
          "en": "API Token is too short. Make sure you copied the whole thing.",
          "ja": "API Token が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 UpCloud 的 API Tokens 文档，在控制台 Account 的 API Tokens 页签发一把。认证头是 Bearer。账号要能读账单。",
        "en": "Open UpCloud’s API Tokens docs and issue one on the API Tokens page under Account. The auth header is Bearer. The account needs billing read.",
        "ja": "UpCloud の API Tokens のドキュメントを開き、ダッシュボード Account の API Tokens ページで発行します。認証ヘッダは Bearer です。アカウントに請求の読み取りが必要です。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "凭据无效。",
          "en": "The credentials are invalid.",
          "ja": "認証情報が無効です。"
        },
        "nextStep": {
          "zh": "回上一步重新签发一把。",
          "en": "Go back a step and issue a new one.",
          "ja": "前の手順に戻って発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把凭据读不到账单。",
          "en": "These credentials can’t read billing.",
          "ja": "この認証情報では請求を読めません。"
        },
        "nextStep": {
          "zh": "确认权限和账号属于同一组织。",
          "en": "Confirm the permission and account belong to the same organization.",
          "ja": "権限とアカウントが同じ組織か確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://hub.upcloud.com",
    "credentialSetupURL": "https://upcloud.com/docs/guides/managing-api-tokens/",
    "summary": {
      "zh": "北欧云主机。按本月从余额扣掉的合计，欧元会折成美元。",
      "en": "Nordic cloud hosts. This month’s total deducted from the balance. Euros convert to USD.",
      "ja": "北欧のクラウドホスト。今月残高から引いた合計で、ユーロはドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 UpCloud 本月账单合计一致。",
      "en": "This number should match this month’s bill total on UpCloud.",
      "ja": "この数字は UpCloud の今月請求合計と一致するはずです。"
    }
  },
  {
    "key": "confluent",
    "name": "Confluent Cloud",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "Kafka 商业化寡头，云收入过半，已被 IBM 收购。",
    "searchKeywords": [
      "kafka",
      "confluent.cloud",
      "ksql",
      "flink"
    ],
    "fields": [
      {
        "key": "clientID",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": false,
        "hint": {
          "zh": "Cloud API Key 那一页",
          "en": "The Cloud API Key page",
          "ja": "Cloud API Key のページ"
        },
        "validation": {
          "zh": "API Key 太短",
          "en": "API Key is too short",
          "ja": "API Key が短すぎます"
        }
      },
      {
        "key": "clientSecret",
        "label": {
          "zh": "API Secret",
          "en": "API Secret",
          "ja": "API Secret"
        },
        "isSecret": true,
        "validation": {
          "zh": "API Secret 太短，确认复制完整",
          "en": "API Secret is too short. Make sure you copied the whole thing.",
          "ja": "API Secret が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Confluent Cloud 的 API keys 页面，签发一把 Cloud API Key。需要 OrganizationAdmin 或 BillingAdmin。Key 和 Secret 成对复制。",
        "en": "Open the Confluent Cloud API keys page and issue a Cloud API Key. You need OrganizationAdmin or BillingAdmin. Copy the Key and Secret together.",
        "ja": "Confluent Cloud の API keys ページを開き、Cloud API Key を発行します。OrganizationAdmin または BillingAdmin が必要です。Key と Secret をペアでコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "凭据无效。",
          "en": "The credentials are invalid.",
          "ja": "認証情報が無効です。"
        },
        "nextStep": {
          "zh": "回上一步重新签发一把。",
          "en": "Go back a step and issue a new one.",
          "ja": "前の手順に戻って発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把凭据读不到账单。",
          "en": "These credentials can’t read billing.",
          "ja": "この認証情報では請求を読めません。"
        },
        "nextStep": {
          "zh": "确认角色是 OrganizationAdmin 或 BillingAdmin。",
          "en": "Confirm the role is OrganizationAdmin or BillingAdmin.",
          "ja": "ロールが OrganizationAdmin または BillingAdmin か確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://confluent.cloud/settings/billing",
    "credentialSetupURL": "https://confluent.cloud/settings/api-keys",
    "summary": {
      "zh": "托管 Kafka。按本月折后花费，最多晚 72 小时。",
      "en": "Managed Kafka. This month’s discounted spend, up to 72 hours behind.",
      "ja": "マネージド Kafka。今月の割引後支出で、最大 72 時間遅れます。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 Confluent Cloud 本月 Costs 合计一致。最近两三天可能还没进。",
      "en": "This number should match this month’s Costs total on Confluent Cloud. The last two or three days may still be missing.",
      "ja": "この数字は Confluent Cloud の今月 Costs 合計と一致するはずです。直近 2–3 日はまだ入っていないことがあります。"
    }
  },
  {
    "key": "postmark",
    "name": "Postmark",
    "kind": "planAndUsage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "投递率领先的精品事务邮件，规模远小于 SendGrid/Mailgun。",
    "searchKeywords": [
      "postmarkapp",
      "email",
      "transactional"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [
      {
        "name": {
          "zh": "Basic",
          "en": "Basic",
          "ja": "Basic"
        },
        "amountUSD": "15",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Pro",
          "en": "Pro",
          "ja": "Pro"
        },
        "amountUSD": "16.50",
        "period": "monthly"
      }
    ],
    "notices": [],
    "guideURLs": [],
    "declineReason": "公开 API 只有发送统计，没有账单金额。"
  },
  {
    "key": "sanity",
    "name": "Sanity",
    "kind": "planAndUsage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "无头 CMS 的高增长挑战者，客户含 Figma/Shopify，规模仍小于 Contentful。",
    "searchKeywords": [
      "sanity.io",
      "cms",
      "content"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [
      {
        "name": {
          "zh": "Growth（每席位）",
          "en": "Growth (per seat)",
          "ja": "Growth（席あたり）"
        },
        "amountUSD": "15",
        "period": "monthly"
      }
    ],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "ably",
    "name": "Ably",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "实时基础设施吞吐巨大，付费客户数仍明显小于 Pusher。",
    "searchKeywords": [
      "ably.com",
      "pubsub",
      "realtime"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "公开接口只有消息计数，没有账单金额。"
  },
  {
    "key": "crunchybridge",
    "name": "Crunchy Bridge",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "已被 Snowflake 收编为 Snowflake Postgres，独立品牌在消退。",
    "searchKeywords": [
      "crunchydata",
      "postgres",
      "postgresql",
      "数据库"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "发票只在控制台，没有公开账单金额接口。"
  },
  {
    "key": "influxdb",
    "name": "InfluxDB Cloud",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "时序品类鼻祖热度下滑，融资停在 2023，云渠道还在退市。",
    "searchKeywords": [
      "influxdata",
      "timeseries",
      "时序"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "公开接口只有用量指标，没有账单金额。"
  },
  {
    "key": "axiom",
    "name": "Axiom",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "廉价全量事件存储的小而快玩家，尚未进入 Gartner 象限。",
    "searchKeywords": [
      "axiom.co",
      "logs",
      "observability"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "公开接口只有 GB 摄入，没有账单金额。"
  },
  {
    "key": "checkly",
    "name": "Checkly",
    "kind": "planAndUsage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "Playwright 监控即代码的开发者向合成监控有口碑，但体量远小于 Datadog/Dynatrace。",
    "searchKeywords": [
      "checklyhq",
      "synthetic",
      "monitoring"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [
      {
        "name": {
          "zh": "Starter（年付）",
          "en": "Starter (annual)",
          "ja": "Starter（年払い）"
        },
        "amountUSD": "288",
        "period": "annual"
      },
      {
        "name": {
          "zh": "Team（年付）",
          "en": "Team (annual)",
          "ja": "Team（年払い）"
        },
        "amountUSD": "768",
        "period": "annual"
      }
    ],
    "notices": [],
    "guideURLs": [],
    "declineReason": "公开接口只有套餐额度，没有账单金额。"
  },
  {
    "key": "timescale",
    "name": "Timescale Cloud",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "已改名 Tiger Data，时序 Postgres 云用量翻倍增长，但仍远小于通用云数仓。",
    "searchKeywords": [
      "timescaledb",
      "postgres",
      "时序",
      "数据库"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "browserstack",
    "name": "BrowserStack",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "云真机/跨浏览器测试的明显第一名，收入与客户数把 Sauce/LambdaTest 甩开一截。",
    "searchKeywords": [
      "browserstack.com",
      "testing",
      "selenium"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "snyk",
    "name": "Snyk",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "仍是独立开发者安全头部厂商且入选 Gartner 领导者，但增长失速、平台捆绑正在分流。",
    "searchKeywords": [
      "snyk.io",
      "security",
      "cve"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [
      {
        "name": {
          "zh": "Team（每席位）",
          "en": "Team (per seat)",
          "ja": "Team（席あたり）"
        },
        "amountUSD": "25",
        "period": "monthly"
      }
    ],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "circleci",
    "name": "CircleCI",
    "kind": "planAndUsage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "独立 CI 被 GitHub Actions 默认化持续蚕食，份额已掉到个位数并持续下滑。",
    "searchKeywords": [
      "circleci.com",
      "ci",
      "cd"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [
      {
        "name": {
          "zh": "Performance",
          "en": "Performance",
          "ja": "Performance"
        },
        "amountUSD": "15",
        "period": "monthly"
      }
    ],
    "notices": [],
    "guideURLs": [],
    "declineReason": "公开接口只有 credits / 分钟，没有账单金额。"
  },
  {
    "key": "terraform",
    "name": "Terraform Cloud",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "多云 IaC 仍是 Terraform 的安装基数垄断，尽管许可与 IBM 收购让忠诚度出现裂缝。",
    "searchKeywords": [
      "hashicorp",
      "hcp",
      "iac",
      "terraform.io"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "tailscale",
    "name": "Tailscale",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "开发者 WireGuard 叠加组网的事实标准。",
    "searchKeywords": [
      "tailscale.com",
      "wireguard",
      "vpn",
      "mesh"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [
      {
        "name": {
          "zh": "Standard（每席位）",
          "en": "Standard (per seat)",
          "ja": "Standard（席あたり）"
        },
        "amountUSD": "8",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Premium（每席位）",
          "en": "Premium (per seat)",
          "ja": "Premium（席あたり）"
        },
        "amountUSD": "18",
        "period": "monthly"
      }
    ],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "deno",
    "name": "Deno Deploy",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "Deno Deploy 仍是边缘 JS 利基，体量远小于 Cloudflare Workers/Vercel。",
    "searchKeywords": [
      "deno.com",
      "deno.land",
      "deploy"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "plausible",
    "name": "Plausible",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "隐私优先网页分析的小而稳生意，份额远低于 GA 但高于 Fathom。",
    "searchKeywords": [
      "plausible.io",
      "analytics",
      "统计"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [
      {
        "name": {
          "zh": "Starter",
          "en": "Starter",
          "ja": "Starter"
        },
        "amountUSD": "9",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Growth",
          "en": "Growth",
          "ja": "Growth"
        },
        "amountUSD": "14",
        "period": "monthly"
      }
    ],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "prefect",
    "name": "Prefect",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "现代编排里最强的 Airflow 挑战者，已盈利并吞并 Dagster，正在收拢次世代品类。",
    "searchKeywords": [
      "prefect.io",
      "workflow",
      "orchestration"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "airbyte",
    "name": "Airbyte",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "开源 ELT 的第一挑战者，连接器与社区足以紧跟 Fivetran，但付费规模仍小一个数量级。",
    "searchKeywords": [
      "airbyte.com",
      "elt",
      "etl"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "exoscale",
    "name": "Exoscale",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "瑞士/欧洲合规向小云，产品还在，但全球 VPS 份额可忽略。",
    "searchKeywords": [
      "exoscale.com",
      "cloudstack"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "用量接口只给小时和 GiB.h，没有账单金额。"
  },
  {
    "key": "vonage",
    "name": "Vonage",
    "kind": "prepaid",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "重返 Gartner 领导者，体量仍次于 Twilio、Infobip 和 Sinch。",
    "searchKeywords": [
      "nexmo",
      "vonage.com",
      "sms",
      "voice"
    ],
    "fields": [
      {
        "key": "clientID",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台 Settings",
          "en": "Settings in the dashboard",
          "ja": "ダッシュボードの Settings"
        },
        "validation": {
          "zh": "API Key 太短",
          "en": "API Key is too short",
          "ja": "API Key が短すぎます"
        }
      },
      {
        "key": "clientSecret",
        "label": {
          "zh": "API Secret",
          "en": "API Secret",
          "ja": "API Secret"
        },
        "isSecret": true,
        "validation": {
          "zh": "API Secret 太短，确认复制完整",
          "en": "API Secret is too short. Make sure you copied the whole thing.",
          "ja": "API Secret が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Vonage 的 Settings 页面，复制 API Key 和 API Secret。认证走 HTTP Basic。",
        "en": "Open Vonage’s Settings page and copy the API Key and API Secret. Auth is HTTP Basic.",
        "ja": "Vonage の Settings ページを開き、API Key と API Secret をコピーします。認証は HTTP Basic です。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "凭据无效。",
          "en": "The credentials are invalid.",
          "ja": "認証情報が無効です。"
        },
        "nextStep": {
          "zh": "回上一步重新签发一把。",
          "en": "Go back a step and issue a new one.",
          "ja": "前の手順に戻って発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把凭据读不到账单。",
          "en": "These credentials can’t read billing.",
          "ja": "この認証情報では請求を読めません。"
        },
        "nextStep": {
          "zh": "确认权限和账号属于同一组织。",
          "en": "Confirm the permission and account belong to the same organization.",
          "ja": "権限とアカウントが同じ組織か確認してください。"
        },
        "httpStatus": 403
      },
      {
        "explanation": {
          "zh": "官方余额的币种不在汇率表里，没法折成美元。",
          "en": "The official balance’s currency isn’t in the rate table, so it can’t convert to USD.",
          "ja": "公式残高の通貨が為替表にないため、ドルに換算できません。"
        },
        "nextStep": {
          "zh": "改成手工录入本月花费。",
          "en": "Switch to entering this month’s spend by hand.",
          "ja": "今月の支出を手入力に切り替えてください。"
        },
        "httpStatus": 200
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://dashboard.nexmo.com",
    "credentialSetupURL": "https://dashboard.nexmo.com/settings",
    "summary": {
      "zh": "通信平台。预充值，欧元余额会折成美元。",
      "en": "A communications platform. Prepaid. A euro balance converts to USD.",
      "ja": "通信プラットフォーム。プリペイドで、ユーロ残高はドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 Vonage 后台还剩的欧元余额对得上。App 里按汇率折成美元显示。",
      "en": "This number should match the remaining euro balance in the Vonage dashboard. The app converts it to USD at the catalog rate.",
      "ja": "この数字は Vonage 管理画面の残りのユーロ残高と一致するはずです。App では為替でドル表示します。"
    }
  },
  {
    "key": "plivo",
    "name": "Plivo",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "低价 Twilio 替代且已盈利，尚未进入 CPaaS 前十。",
    "searchKeywords": [
      "plivo.com",
      "sms",
      "voice"
    ],
    "fields": [
      {
        "key": "accountID",
        "label": {
          "zh": "Auth ID",
          "en": "Auth ID",
          "ja": "Auth ID"
        },
        "isSecret": false,
        "validation": {
          "zh": "Auth ID 太短",
          "en": "Auth ID is too short",
          "ja": "Auth ID が短すぎます"
        }
      },
      {
        "key": "apiToken",
        "label": {
          "zh": "Auth Token",
          "en": "Auth Token",
          "ja": "Auth Token"
        },
        "isSecret": true,
        "validation": {
          "zh": "Auth Token 太短，确认复制完整",
          "en": "Auth Token is too short. Make sure you copied the whole thing.",
          "ja": "Auth Token が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Plivo 的 Dashboard 页面，复制 Auth ID。",
        "en": "Open Plivo’s Dashboard page and copy the Auth ID.",
        "ja": "Plivo の Dashboard ページを開き、Auth ID をコピーします。"
      },
      {
        "zh": "同一页复制 Auth Token。认证走 HTTP Basic。",
        "en": "On the same page, copy the Auth Token. Auth is HTTP Basic.",
        "ja": "同じページで Auth Token をコピーします。認証は HTTP Basic です。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "凭据无效。",
          "en": "The credentials are invalid.",
          "ja": "認証情報が無効です。"
        },
        "nextStep": {
          "zh": "回上一步重新签发一把。",
          "en": "Go back a step and issue a new one.",
          "ja": "前の手順に戻って発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把凭据读不到账单。",
          "en": "These credentials can’t read billing.",
          "ja": "この認証情報では請求を読めません。"
        },
        "nextStep": {
          "zh": "确认权限和账号属于同一组织。",
          "en": "Confirm the permission and account belong to the same organization.",
          "ja": "権限とアカウントが同じ組織か確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://console.plivo.com",
    "credentialSetupURL": "https://console.plivo.com/dashboard/",
    "summary": {
      "zh": "通信平台。按本月用量加号码等其它费用合计。",
      "en": "A communications platform. This month’s usage plus numbers and other charges.",
      "ja": "通信プラットフォーム。今月の用量と番号などのその他費用の合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 Plivo 本月用量加其它费用合计一致。",
      "en": "This number should match this month’s usage plus other charges on Plivo.",
      "ja": "この数字は Plivo の今月用量とその他費用の合計と一致するはずです。"
    }
  },
  {
    "key": "messagebird",
    "name": "MessageBird",
    "kind": "prepaid",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "已退出领导者阵营，员工大幅收缩，正在萎缩。",
    "searchKeywords": [
      "messagebird.com",
      "bird.com",
      "sms"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "Access Key",
          "en": "Access Key",
          "ja": "Access Key"
        },
        "isSecret": true,
        "validation": {
          "zh": "Access Key 太短，确认复制完整",
          "en": "Access Key is too short. Make sure you copied the whole thing.",
          "ja": "Access Key が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 MessageBird 的 Access 页面，签发一把 Access Key。后付费账户这条接口给不出账单。",
        "en": "Open the MessageBird Access page and issue an Access Key. Postpaid accounts get no billing from this API.",
        "ja": "MessageBird の Access ページを開き、Access Key を発行します。後払いアカウントではこの API から請求を取れません。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "凭据无效。",
          "en": "The credentials are invalid.",
          "ja": "認証情報が無効です。"
        },
        "nextStep": {
          "zh": "回上一步重新签发一把。",
          "en": "Go back a step and issue a new one.",
          "ja": "前の手順に戻って発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把凭据读不到账单。",
          "en": "These credentials can’t read billing.",
          "ja": "この認証情報では請求を読めません。"
        },
        "nextStep": {
          "zh": "确认权限和账号属于同一组织。",
          "en": "Confirm the permission and account belong to the same organization.",
          "ja": "権限とアカウントが同じ組織か確認してください。"
        },
        "httpStatus": 403
      },
      {
        "explanation": {
          "zh": "官方余额是 credits，或币种不在汇率表里，没法折成美元。",
          "en": "The official balance is in credits, or the currency isn’t in the rate table, so it can’t convert to USD.",
          "ja": "公式残高が credits か、通貨が為替表にないため、ドルに換算できません。"
        },
        "nextStep": {
          "zh": "改成手工录入本月花费。",
          "en": "Switch to entering this month’s spend by hand.",
          "ja": "今月の支出を手入力に切り替えてください。"
        },
        "httpStatus": 200
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://dashboard.messagebird.com",
    "credentialSetupURL": "https://dashboard.messagebird.com/en/developers/access",
    "summary": {
      "zh": "通信平台。预充值，欧元等余额会折成美元。",
      "en": "A communications platform. Prepaid. Euro and other balances convert to USD.",
      "ja": "通信プラットフォーム。プリペイドで、ユーロなどの残高はドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 MessageBird 后台还剩的余额对得上。credits 账户折不成美元。",
      "en": "This number should match the remaining balance in the MessageBird dashboard. A credits account can’t convert to USD.",
      "ja": "この数字は MessageBird 管理画面の残額と一致するはずです。credits 口座はドルに換算できません。"
    }
  },
  {
    "key": "ibm",
    "name": "IBM Cloud",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "IaaS 收入基本停滞、份额掉到约 1%，公司已转向红帽混合云而非公有云抢量。",
    "searchKeywords": [
      "ibmcloud",
      "bluemix",
      "softlayer"
    ],
    "fields": [
      {
        "key": "accountID",
        "label": {
          "zh": "Account ID",
          "en": "Account ID",
          "ja": "Account ID"
        },
        "isSecret": false,
        "validation": {
          "zh": "Account ID 太短",
          "en": "Account ID is too short",
          "ja": "Account ID が短すぎます"
        }
      },
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true,
        "validation": {
          "zh": "API Key 太短，确认复制完整",
          "en": "API Key is too short. Make sure you copied the whole thing.",
          "ja": "API Key が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 IBM Cloud 的 API keys 页面所在账号，记下 Account ID。",
        "en": "Open the IBM Cloud API keys page for this account and write down the Account ID.",
        "ja": "IBM Cloud の API keys ページがあるアカウントを開き、Account ID を控えます。"
      },
      {
        "zh": "同一页签发一把 API Key。账号要能读账单。",
        "en": "On the same page, issue an API Key. The account needs billing read.",
        "ja": "同じページで API Key を発行します。アカウントに請求の読み取りが必要です。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "凭据无效。",
          "en": "The credentials are invalid.",
          "ja": "認証情報が無効です。"
        },
        "nextStep": {
          "zh": "回上一步重新签发一把。",
          "en": "Go back a step and issue a new one.",
          "ja": "前の手順に戻って発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把凭据读不到账单。",
          "en": "These credentials can’t read billing.",
          "ja": "この認証情報では請求を読めません。"
        },
        "nextStep": {
          "zh": "确认权限和账号属于同一组织。",
          "en": "Confirm the permission and account belong to the same organization.",
          "ja": "権限とアカウントが同じ組織か確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://cloud.ibm.com/billing",
    "credentialSetupURL": "https://cloud.ibm.com/iam/apikeys",
    "summary": {
      "zh": "IBM Cloud。按本月应付合计。",
      "en": "IBM Cloud. This month’s amount due.",
      "ja": "IBM Cloud。今月の支払い合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 IBM Cloud 本月应付合计一致。",
      "en": "This number should match this month’s amount due on IBM Cloud.",
      "ja": "この数字は IBM Cloud の今月支払い合計と一致するはずです。"
    }
  },
  {
    "key": "brevo",
    "name": "Brevo",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "中小企业邮件营销第二梯队，正在快速抢份额。",
    "searchKeywords": [
      "sendinblue",
      "brevo.com",
      "email"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "公开接口只给发送 credits，不是账单金额。"
  },
  {
    "key": "redpanda",
    "name": "Redpanda Cloud",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "Kafka 协议性能派挑战者已成独角兽，对 Confluent/MSK 构成实质分流。",
    "searchKeywords": [
      "redpanda.com",
      "kafka"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "账单只在控制台和 CSV，没有公开账单金额接口。"
  },
  {
    "key": "fauna",
    "name": "Fauna",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "托管服务已于 2025 年关停，属于明确退出市场。",
    "searchKeywords": [
      "fauna.com",
      "fql",
      "数据库"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "kamatera",
    "name": "Kamatera",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "多区域灵活 VPS 的小型供应商，报告里有名但无公开量级，属于持续存在的长尾。",
    "searchKeywords": [
      "kamatera.com",
      "vps"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "onesignal",
    "name": "OneSignal",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "独立推送 SaaS 的领先挑战者，Shopify 渠道则在退。",
    "searchKeywords": [
      "onesignal.com",
      "push",
      "notification"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "courier",
    "name": "Courier",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "通知编排层仍小，融资停留在 2022 年 B 轮。",
    "searchKeywords": [
      "courier.com",
      "notification"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "doppler",
    "name": "Doppler",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "开发者密钥 SaaS 的早期品牌，融资停在 2022 年 Series A，规模远小于 Vault。",
    "searchKeywords": [
      "doppler.com",
      "secrets"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [
      {
        "name": {
          "zh": "Team（每席位）",
          "en": "Team (per seat)",
          "ja": "Team（席あたり）"
        },
        "amountUSD": "21",
        "period": "monthly"
      }
    ],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "infisical",
    "name": "Infisical",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "开源密钥管理的高增长挑战者，正在从 Doppler/Vault 抢开发者。",
    "searchKeywords": [
      "infisical.com",
      "secrets"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [
      {
        "name": {
          "zh": "Pro（每身份）",
          "en": "Pro (per identity)",
          "ja": "Pro（アイデンティティあたり）"
        },
        "amountUSD": "18",
        "period": "monthly"
      }
    ],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "kinsta",
    "name": "Kinsta",
    "kind": "planAndUsage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "高端托管 WordPress 里与 WP Engine 并列被点名的选项，客户数仍在快增。",
    "searchKeywords": [
      "kinsta.com",
      "wordpress",
      "hosting"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [
      {
        "name": {
          "zh": "Single 20GB",
          "en": "Single 20GB",
          "ja": "Single 20GB"
        },
        "amountUSD": "35",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Single 20GB（年付）",
          "en": "Single 20GB (annual)",
          "ja": "Single 20GB（年払い）"
        },
        "amountUSD": "350",
        "period": "annual"
      }
    ],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "imgix",
    "name": "imgix",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "实时图片 CDN 次于 Cloudinary，体量小且已转向积分计价。",
    "searchKeywords": [
      "imgix.com",
      "cdn",
      "image"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "fathom",
    "name": "Fathom",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "同样走无 Cookie 网页分析，站点规模约为 Plausible 的一半。",
    "searchKeywords": [
      "usefathom",
      "analytics",
      "统计"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [
      {
        "name": {
          "zh": "起步",
          "en": "Starting at",
          "ja": "スタート"
        },
        "amountUSD": "15",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "起步（年付）",
          "en": "Starting at (annual)",
          "ja": "スタート（年払い）"
        },
        "amountUSD": "150",
        "period": "annual"
      }
    ],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "mailchimp",
    "name": "Mailchimp",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "安装基数仍近半壁江山，虽增长停滞但仍是邮件营销寡头。",
    "searchKeywords": [
      "mailchimp.com",
      "email",
      "intuit"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "klaviyo",
    "name": "Klaviyo",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "电商 CRM 与 Shopify 邮件的强挑战者，收入仍在高速扩张。",
    "searchKeywords": [
      "klaviyo.com",
      "email"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Klaviyo 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Klaviyo dashboard, create API Key, then copy it.",
        "ja": "Klaviyo ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。",
    "summary": {
      "zh": "电商邮件和短信。按本账期美元计价用量。",
      "en": "Ecommerce email and SMS. This period’s usage priced in USD.",
      "ja": "EC のメールと SMS。今期のドル換算用量です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "bitbucket",
    "name": "Bitbucket",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "份额远落后于 GitHub/GitLab，基本靠 Atlassian 套件续命，独立代码托管心智在收缩。",
    "searchKeywords": [
      "bitbucket.org",
      "atlassian",
      "git"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [
      {
        "name": {
          "zh": "Standard（每席位）",
          "en": "Standard (per seat)",
          "ja": "Standard（席あたり）"
        },
        "amountUSD": "3.65",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Premium（每席位）",
          "en": "Premium (per seat)",
          "ja": "Premium（席あたり）"
        },
        "amountUSD": "7.25",
        "period": "monthly"
      }
    ],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "buildkite",
    "name": "Buildkite",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "份额很小，但混合自建 runner 在超大规模工程组织里有稳固高端阵地。",
    "searchKeywords": [
      "buildkite.com",
      "ci",
      "cd"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "codecov",
    "name": "Codecov",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "托管覆盖率报告的事实默认项，但已两次被收购，正变成交付平台里的功能模块。",
    "searchKeywords": [
      "codecov.io",
      "coverage"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [
      {
        "name": {
          "zh": "Team（每席位）",
          "en": "Team (per seat)",
          "ja": "Team（席あたり）"
        },
        "amountUSD": "5",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Pro（每席位）",
          "en": "Pro (per seat)",
          "ja": "Pro（席あたり）"
        },
        "amountUSD": "12",
        "period": "monthly"
      }
    ],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "sonarcloud",
    "name": "SonarCloud",
    "kind": "planAndUsage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "静态分析/代码质量几乎由 Sonar 一家定义，云端 SonarCloud 是同一垄断品牌的 SaaS 面。",
    "searchKeywords": [
      "sonarcloud.io",
      "sonarqube",
      "quality"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [
      {
        "name": {
          "zh": "Team",
          "en": "Team",
          "ja": "Team"
        },
        "amountUSD": "32",
        "period": "monthly"
      }
    ],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "fivetran",
    "name": "Fivetran",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "托管数据接入的企业默认层，与 dbt 合并后把 EL+T 收成同一寡头。",
    "searchKeywords": [
      "fivetran.com",
      "elt",
      "etl"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "clicksend",
    "name": "ClickSend",
    "kind": "prepaid",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "按量计费的中小企业多通道短信，未进入分析师前十。",
    "searchKeywords": [
      "clicksend.com",
      "sms",
      "fax"
    ],
    "fields": [
      {
        "key": "clientID",
        "label": {
          "zh": "Username",
          "en": "Username",
          "ja": "Username"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台 API Credentials",
          "en": "API Credentials in the dashboard",
          "ja": "ダッシュボードの API Credentials"
        },
        "validation": {
          "zh": "Username 太短",
          "en": "Username is too short",
          "ja": "Username が短すぎます"
        }
      },
      {
        "key": "clientSecret",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true,
        "validation": {
          "zh": "API Key 太短，确认复制完整",
          "en": "API Key is too short. Make sure you copied the whole thing.",
          "ja": "API Key が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 ClickSend 的 API 文档页，从控制台 API Credentials 复制 Username 和 API Key。认证走 HTTP Basic。",
        "en": "Open the ClickSend API docs page and copy Username and API Key from API Credentials in the dashboard. Auth is HTTP Basic.",
        "ja": "ClickSend の API のドキュメントページを開き、ダッシュボードの API Credentials から Username と API Key をコピーします。認証は HTTP Basic です。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "凭据无效。",
          "en": "The credentials are invalid.",
          "ja": "認証情報が無効です。"
        },
        "nextStep": {
          "zh": "回上一步重新签发一把。",
          "en": "Go back a step and issue a new one.",
          "ja": "前の手順に戻って発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把凭据读不到账单。",
          "en": "These credentials can’t read billing.",
          "ja": "この認証情報では請求を読めません。"
        },
        "nextStep": {
          "zh": "确认权限和账号属于同一组织。",
          "en": "Confirm the permission and account belong to the same organization.",
          "ja": "権限とアカウントが同じ組織か確認してください。"
        },
        "httpStatus": 403
      },
      {
        "explanation": {
          "zh": "官方余额的币种不在汇率表里，没法折成美元。",
          "en": "The official balance’s currency isn’t in the rate table, so it can’t convert to USD.",
          "ja": "公式残高の通貨が為替表にないため、ドルに換算できません。"
        },
        "nextStep": {
          "zh": "改成手工录入本月花费。",
          "en": "Switch to entering this month’s spend by hand.",
          "ja": "今月の支出を手入力に切り替えてください。"
        },
        "httpStatus": 200
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://dashboard.clicksend.com",
    "credentialSetupURL": "https://developers.clicksend.com/docs",
    "summary": {
      "zh": "中小企业短信、传真和邮件。按本月用量，账户币种会折成美元。",
      "en": "SMB SMS, fax, and email. This month’s usage. The account currency converts to USD.",
      "ja": "中小企業向け SMS、FAX、メール。今月の用量で、口座通貨はドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 ClickSend 后台还剩的余额对得上。App 里按汇率折成美元显示。",
      "en": "This number should match the remaining balance in the ClickSend dashboard. The app converts it to USD at the catalog rate.",
      "ja": "この数字は ClickSend 管理画面の残額と一致するはずです。App では為替でドル表示します。"
    }
  },
  {
    "key": "infobip",
    "name": "Infobip",
    "kind": "prepaid",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "与 Twilio 并列 CPaaS 领导者，愿景轴略占优。",
    "searchKeywords": [
      "infobip.com",
      "sms",
      "cpaas"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true,
        "validation": {
          "zh": "API Key 太短，确认复制完整",
          "en": "API Key is too short. Make sure you copied the whole thing.",
          "ja": "API Key が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Infobip 的签发 API key 文档，在门户签发一把带 account-management:manage 范围的 API Key。认证头是 App。",
        "en": "Open Infobip’s issue an API key docs and issue an API Key with the account-management:manage scope in the portal. The auth header is App.",
        "ja": "Infobip の API key 発行のドキュメントを開き、ポータルで account-management:manage 範囲の API Key を発行します。認証ヘッダは App です。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "凭据无效。",
          "en": "The credentials are invalid.",
          "ja": "認証情報が無効です。"
        },
        "nextStep": {
          "zh": "回上一步重新签发一把。",
          "en": "Go back a step and issue a new one.",
          "ja": "前の手順に戻って発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把凭据读不到账单。",
          "en": "These credentials can’t read billing.",
          "ja": "この認証情報では請求を読めません。"
        },
        "nextStep": {
          "zh": "确认 API Key 带 account-management:manage 范围。",
          "en": "Confirm the API Key has the account-management:manage scope.",
          "ja": "API Key に account-management:manage 範囲があるか確認してください。"
        },
        "httpStatus": 403
      },
      {
        "explanation": {
          "zh": "官方余额的币种不在汇率表里，没法折成美元。",
          "en": "The official balance’s currency isn’t in the rate table, so it can’t convert to USD.",
          "ja": "公式残高の通貨が為替表にないため、ドルに換算できません。"
        },
        "nextStep": {
          "zh": "改成手工录入本月花费。",
          "en": "Switch to entering this month’s spend by hand.",
          "ja": "今月の支出を手入力に切り替えてください。"
        },
        "httpStatus": 200
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://portal.infobip.com",
    "summary": {
      "zh": "企业短信、语音和 CPaaS。预充值，报剩余额度，账户币种会折成美元。",
      "en": "Enterprise SMS, voice, and CPaaS. Prepaid remaining balance. The account currency converts to USD.",
      "ja": "企業向け SMS、音声、CPaaS。プリペイドの残額で、口座通貨はドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 Infobip 后台还剩的余额对得上。App 里按汇率折成美元显示。",
      "en": "This number should match the remaining balance in the Infobip dashboard. The app converts it to USD at the catalog rate.",
      "ja": "この数字は Infobip 管理画面の残額と一致するはずです。App では為替でドル表示します。"
    }
  },
  {
    "key": "textmagic",
    "name": "Textmagic",
    "kind": "prepaid",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "传统按量短信工具，正被销售向 SMS 套件替代。",
    "searchKeywords": [
      "textmagic.com",
      "sms"
    ],
    "fields": [
      {
        "key": "clientID",
        "label": {
          "zh": "Username",
          "en": "Username",
          "ja": "Username"
        },
        "isSecret": false,
        "validation": {
          "zh": "Username 太短",
          "en": "Username is too short",
          "ja": "Username が短すぎます"
        }
      },
      {
        "key": "clientSecret",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true,
        "validation": {
          "zh": "API Key 太短，确认复制完整",
          "en": "API Key is too short. Make sure you copied the whole thing.",
          "ja": "API Key が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Textmagic 的 API 设置页，复制 Username 和 API Key。认证走 HTTP Basic。",
        "en": "Open the Textmagic API settings page and copy Username and API Key. Auth is HTTP Basic.",
        "ja": "Textmagic の API の設定ページを開き、Username と API Key をコピーします。認証は HTTP Basic です。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "凭据无效。",
          "en": "The credentials are invalid.",
          "ja": "認証情報が無効です。"
        },
        "nextStep": {
          "zh": "回上一步重新签发一把。",
          "en": "Go back a step and issue a new one.",
          "ja": "前の手順に戻って発行し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把凭据读不到账单。",
          "en": "These credentials can’t read billing.",
          "ja": "この認証情報では請求を読めません。"
        },
        "nextStep": {
          "zh": "确认权限和账号属于同一组织。",
          "en": "Confirm the permission and account belong to the same organization.",
          "ja": "権限とアカウントが同じ組織か確認してください。"
        },
        "httpStatus": 403
      },
      {
        "explanation": {
          "zh": "官方余额的币种不在汇率表里，没法折成美元。",
          "en": "The official balance’s currency isn’t in the rate table, so it can’t convert to USD.",
          "ja": "公式残高の通貨が為替表にないため、ドルに換算できません。"
        },
        "nextStep": {
          "zh": "改成手工录入本月花费。",
          "en": "Switch to entering this month’s spend by hand.",
          "ja": "今月の支出を手入力に切り替えてください。"
        },
        "httpStatus": 200
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://app.textmagic.com",
    "credentialSetupURL": "https://app.textmagic.com/settings/api",
    "summary": {
      "zh": "按量短信工具。预充值，报剩余额度，账户币种会折成美元。",
      "en": "Pay-as-you-go SMS. Prepaid remaining balance. The account currency converts to USD.",
      "ja": "従量の SMS ツール。プリペイドの残額で、口座通貨はドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 Textmagic 后台还剩的余额对得上。App 里按汇率折成美元显示。",
      "en": "This number should match the remaining balance in the Textmagic dashboard. The app converts it to USD at the catalog rate.",
      "ja": "この数字は Textmagic 管理画面の残額と一致するはずです。App では為替でドル表示します。"
    }
  },
  {
    "key": "sinch",
    "name": "Sinch",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "CPaaS 份额第二梯队寡头，与 Twilio、Infobip 几分天下。",
    "searchKeywords": [
      "sinch.com",
      "sms",
      "voice"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "官方声明没有 Billing API，账单只在控制台。"
  },
  {
    "key": "smtp2go",
    "name": "SMTP2GO",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "投递测试领先的小型 SMTP，发送量不在第一档。",
    "searchKeywords": [
      "smtp2go.com",
      "email"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "公开 API 只有发送配额，没有账单金额。"
  },
  {
    "key": "mailjet",
    "name": "Mailjet",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "Sinch 旗下欧盟邮件品牌，发送量远小于同胞 Mailgun。",
    "searchKeywords": [
      "mailjet.com",
      "email"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "公开 API 只有资料和发送统计，没有账单金额。"
  },
  {
    "key": "n8n",
    "name": "n8n Cloud",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "开源工作流自动化的强挑战者，一年内冲到亿美元 ARR 并拿到 SAP 战略入股。",
    "searchKeywords": [
      "n8n.io",
      "workflow",
      "automation"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [
      {
        "name": {
          "zh": "Starter（年付）",
          "en": "Starter (annual)",
          "ja": "Starter（年払い）"
        },
        "amountUSD": "260.4",
        "period": "annual"
      },
      {
        "name": {
          "zh": "Pro（年付）",
          "en": "Pro (annual)",
          "ja": "Pro（年払い）"
        },
        "amountUSD": "651",
        "period": "annual"
      }
    ],
    "notices": [],
    "guideURLs": [],
    "declineReason": "n8n Cloud 没有公开账单金额接口。"
  },
  {
    "key": "hasura",
    "name": "Hasura",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "GraphQL 自动 API 红利消退，2022 年后未再融资并转向 PromptQL 咨询。",
    "searchKeywords": [
      "hasura.io",
      "graphql"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "账单只在控制台，没有公开账单金额接口。"
  },
  {
    "key": "elks",
    "name": "46elks",
    "kind": "prepaid",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "北欧自助短信/语音 API，区域利基且仍被列为欧洲替代。",
    "searchKeywords": [
      "46elks",
      "elks",
      "sms"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "官方 GET /a1/me 的 balance 是未写清单位的整数，不能自行折钱。"
  },
  {
    "key": "keycdn",
    "name": "KeyCDN",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "长尾廉价 CDN，站点份额约 0.1% 且无扩张信号。",
    "searchKeywords": [
      "keycdn.com",
      "cdn"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "公开报表是流量字节和 credit 流水，没有一份本月应付合计。"
  },
  {
    "key": "cdn77",
    "name": "CDN77",
    "kind": "prepaid",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "媒体 CDN 收入过两亿美元且现金流转正，仍远小于三巨头。",
    "searchKeywords": [
      "cdn77.com",
      "cdn"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "credit-balance 没写货币，不能当美元用。"
  },
  {
    "key": "astra",
    "name": "DataStax Astra",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "Cassandra 托管已被 IBM 吞并，宽列库热度相对 DynamoDB 等持续走弱。",
    "searchKeywords": [
      "datastax",
      "astra",
      "cassandra"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "DevOps 账单是企业 consumption 报表，普通组织没有一份可读的本月账单。"
  },
  {
    "key": "dagster",
    "name": "Dagster Cloud",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "资产导向编排在现代数据团队中增长快，但份额小于 Prefect，且 2026 年已被收购。",
    "searchKeywords": [
      "dagster.io",
      "orchestrat"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "dbt",
    "name": "dbt Cloud",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "仓内 SQL 转换近乎垄断，分析工程师岗位与现代数据栈都围着 dbt 转。",
    "searchKeywords": [
      "getdbt",
      "dbt.com",
      "analytics"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "pulumi",
    "name": "Pulumi Cloud",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": true,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "用通用语言写 IaC 的主挑战者，客户与增速都在抬升，但仍远小于 Terraform 生态。",
    "searchKeywords": [
      "pulumi.com",
      "iac"
    ],
    "fields": [],
    "steps": [
      {
        "zh": "Pulumi Cloud 没有公开的账单金额接口。下一步会给你一段任务书，粘给 Claude Code、Cursor 或任何能上网的 AI 写抓取脚本。本月花费以 Settings 里的 Billing 为准。",
        "en": "Pulumi Cloud has no public billed-amount API. Next you’ll get a brief. Paste it into Claude Code, Cursor, or any AI that can reach the web, and have it write a scrape script. Treat Billing in Settings as the source for this month.",
        "ja": "Pulumi Cloud に公開の請求金額 API はありません。次の画面で依頼文を出します。Claude Code、Cursor、またはネットに出られる AI に貼って、取得スクリプトを書いてもらってください。今月の金額は Settings の Billing を正とします。"
      },
      {
        "zh": "投递 key 单独给你，放进脚本的环境变量。脚本每天跑一次，同一个月重复上报是覆盖。",
        "en": "The ingest key is yours alone. Put it in the script’s environment variables. Run the script once a day. Sending the same month again overwrites.",
        "ja": "投函キーはあなた専用です。スクリプトの環境変数に入れてください。スクリプトは 1 日 1 回。同じ月を再送すると上書きです。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "投递 key 已经被吊销了。",
          "en": "The ingest key has been revoked.",
          "ja": "投函キーはすでに取り消されています。"
        },
        "nextStep": {
          "zh": "去设置 → 读数信箱里再签一把，然后更新你的脚本。",
          "en": "Go to Settings → Inbox and issue a new one, then update your script.",
          "ja": "設定 → 検針ポストで発行し直し、スクリプトを更新してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "投递太频繁了。",
          "en": "You’re delivering too often.",
          "ja": "投函が頻繁すぎます。"
        },
        "nextStep": {
          "zh": "每天跑一次就够。",
          "en": "Once a day is enough.",
          "ja": "1 日 1 回で足ります。"
        },
        "httpStatus": 429
      }
    ],
    "plans": [
      {
        "name": {
          "zh": "Pulumi Cloud Team",
          "en": "Pulumi Cloud Team",
          "ja": "Pulumi Cloud Team"
        },
        "amountUSD": "40",
        "period": "monthly"
      },
      {
        "name": {
          "zh": "Pulumi Cloud Enterprise",
          "en": "Pulumi Cloud Enterprise",
          "ja": "Pulumi Cloud Enterprise"
        },
        "amountUSD": "400",
        "period": "monthly"
      }
    ],
    "notices": [
      {
        "zh": "Pulumi Cloud 没有公开账单金额接口。这家走读数信箱。Team / Enterprise 起步月费走手动订阅，额外 credits 以控制台为准。",
        "en": "Pulumi Cloud has no public billed-amount API. This one uses the inbox. Team / Enterprise starting monthly fees go in as a manual subscription. Extra credits follow the dashboard.",
        "ja": "Pulumi Cloud に公開の請求金額 API はありません。このサービスは検針ポストです。Team / Enterprise の起步月額は手動サブスクリプション、追加 credits はダッシュボードを正とします。"
      }
    ],
    "guideURLs": [],
    "billingURL": "https://app.pulumi.com",
    "credentialSetupURL": "https://www.pulumi.com/docs/pulumi-cloud/access-management/access-tokens/",
    "summary": {
      "zh": "基础设施即代码。没有公开账单金额接口，走读数信箱。",
      "en": "Infrastructure as code. There’s no public billed-amount API, so it uses the inbox.",
      "ja": "Infrastructure as Code。公開の請求金額 API はないので、検針ポストを使います。"
    },
    "verifyHint": {
      "zh": "接入之后先显示「等待投递」。脚本第一次上报之后数字才会出来。",
      "en": "After connecting, it first shows Waiting for delivery. The number appears after the script reports once.",
      "ja": "接続した直後は「投函待ち」です。スクリプトが一度報告してから数字が出ます。"
    }
  },
  {
    "key": "hashicorp",
    "name": "HashiCorp Cloud",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "Vault 仍是密钥与服务身份的事实标准，HCP 是该寡头产品线的托管面并并入 IBM。",
    "searchKeywords": [
      "hashicorp",
      "hcp",
      "vault",
      "terraform"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "HCP 没有公开账单金额接口。"
  },
  {
    "key": "appwrite",
    "name": "Appwrite Cloud",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "开源 Firebase 替代仍在扩云与产品面，但开发者规模和融资远落后于 Supabase。",
    "searchKeywords": [
      "appwrite.io",
      "baas"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "stytch",
    "name": "Stytch",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "独立 CIAM 挑战者已被 Twilio 以人才收购收掉。",
    "searchKeywords": [
      "stytch.com",
      "auth"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "okta",
    "name": "Okta",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "劳动力身份与微软、Ping 构成访问管理寡头，是独立 IdP 的规模王。",
    "searchKeywords": [
      "okta.com",
      "auth",
      "sso"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。"
  },
  {
    "key": "chargebee",
    "name": "Chargebee",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "订阅计费应用的 Gartner 领导者，规模小于 Stripe Billing 但在中大客户侧是强挑战者。",
    "searchKeywords": [
      "chargebee.com",
      "billing"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "公开接口是商户账单产品，不是 Chargebee 自己的订阅账单。"
  },
  {
    "key": "betterstack",
    "name": "Better Stack",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "独立可观测性/状态页赛道里增速很快的挑战者，仍小于 Datadog。",
    "searchKeywords": [
      "betterstack",
      "better stack",
      "better uptime",
      "logtail"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Better Stack 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the Better Stack dashboard, create API Token, then copy it.",
        "ja": "Better Stack ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://betterstack.com/",
    "credentialSetupURL": "https://betterstack.com/settings/api-tokens",
    "summary": {
      "zh": "状态页、日志和正常运行监控。按本月各产品费用相加。",
      "en": "Status pages, logs, and uptime monitoring. This month’s product costs, summed.",
      "ja": "ステータスページ、ログ、稼働監視。今月の各プロダクト費用の合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "easypost",
    "name": "EasyPost",
    "kind": "prepaid",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "美国开发者物流 API 的强挑战者，与 Shippo 等同台。",
    "searchKeywords": [
      "easypost",
      "easy post",
      "shipping"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 EasyPost 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the EasyPost dashboard, create API Key, then copy it.",
        "ja": "EasyPost ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://app.easypost.com/account",
    "credentialSetupURL": "https://docs.easypost.com/docs/authentication",
    "summary": {
      "zh": "打单和运费 API。预充值，报钱包剩余额度。",
      "en": "Shipping labels and rates. Prepaid. It reports the wallet balance.",
      "ja": "ラベル発行と運賃 API。プリペイドで、ウォレット残額を出します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "transloadit",
    "name": "Transloadit",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "媒体文件处理 API 细分市场的小而稳的选手。",
    "searchKeywords": [
      "transloadit",
      "encoding",
      "ffmpeg"
    ],
    "fields": [
      {
        "key": "clientSecret",
        "label": {
          "zh": "Client Secret",
          "en": "Client Secret",
          "ja": "Client Secret"
        },
        "isSecret": true
      },
      {
        "key": "clientID",
        "label": {
          "zh": "Client ID",
          "en": "Client ID",
          "ja": "Client ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台 API 凭证里的 ID",
          "en": "ID from API credentials in the dashboard",
          "ja": "ダッシュボードの API 認証情報の ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Transloadit 控制台 的 API 页面，创建 Client Secret，然后复制。",
        "en": "Open the API page in the Transloadit dashboard, create Client Secret, then copy it.",
        "ja": "Transloadit ダッシュボード の API ページを開き、Client Secret を作成してコピーします。"
      },
      {
        "zh": "打开 Transloadit 控制台 的 API 页面，创建 Client ID，然后复制。",
        "en": "Open the API page in the Transloadit dashboard, create Client ID, then copy it.",
        "ja": "Transloadit ダッシュボード の API ページを開き、Client ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://transloadit.com/c/",
    "credentialSetupURL": "https://transloadit.com/docs/api/authentication/",
    "summary": {
      "zh": "文件编码和媒体处理。按当月应付合计。",
      "en": "File encoding and media processing. This month’s amount due.",
      "ja": "ファイルエンコードとメディア処理。当月の支払い合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "lemon",
    "name": "Lemon Squeezy",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "已被 Stripe 收购，独立 MoR 品牌正让位于 Stripe Managed Payments。",
    "searchKeywords": [
      "lemonsqueezy",
      "lemon squeezy",
      "mor"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "订单只有 total，没有平台抽成字段，不能自己按费率发明。"
  },
  {
    "key": "mapbox",
    "name": "Mapbox",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "独立地图 SDK 的强挑战者，仍远小于 Google Maps Platform。",
    "searchKeywords": [
      "mapbox.com",
      "maps",
      "地图"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "官方说明用量数据没有公开 API，控制台只有计量单位。 (evidence: https://docs.mapbox.com/accounts/guides/statistics/)"
  },
  {
    "key": "googlemaps",
    "name": "Google Maps Platform",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "地图与地点 API 支出的绝对龙头。",
    "searchKeywords": [
      "google maps",
      "maps platform",
      "gmp",
      "地图"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有简单的只读账单金额 HTTP；金额要走 Cloud Billing BigQuery 导出。"
  },
  {
    "key": "docusign",
    "name": "DocuSign",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "电子签名市场近乎垄断，企业采购默认选项。",
    "searchKeywords": [
      "docusign.com",
      "esign",
      "电子签名"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "billing_charges 只给单价和用量数量，没有已发生金额合计。"
  },
  {
    "key": "typeform",
    "name": "Typeform",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "互动表单/调研的强挑战者，与 Google Forms 等分流。",
    "searchKeywords": [
      "typeform.com",
      "forms",
      "表单"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "公开 API 只有表单与回复，没有账单金额。"
  },
  {
    "key": "kit",
    "name": "Kit",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "创作者邮件营销细分里的中小型选手。",
    "searchKeywords": [
      "kit.com",
      "convertkit",
      "email",
      "newsletter"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "账户接口只有套餐元数据与额度，没有账单金额。"
  },
  {
    "key": "api2pdf",
    "name": "Api2Pdf",
    "kind": "prepaid",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "HTML/URL 转 PDF API 细分里的小型选手。",
    "searchKeywords": [
      "api2pdf",
      "pdf",
      "html to pdf"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Api2Pdf 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Api2Pdf dashboard, create API Key, then copy it.",
        "ja": "Api2Pdf ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://portal.api2pdf.com",
    "credentialSetupURL": "https://www.api2pdf.com/",
    "summary": {
      "zh": "HTML 和 URL 转 PDF。预充值，报剩余额度。",
      "en": "HTML and URL to PDF. Prepaid. It reports remaining balance.",
      "ja": "HTML と URL から PDF。プリペイドで、残額を出します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "hetrixtools",
    "name": "HetrixTools",
    "kind": "prepaid",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "服务器与黑名单监控细分里的小型选手。",
    "searchKeywords": [
      "hetrix",
      "hetrixtools",
      "uptime",
      "blacklist"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 HetrixTools 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the HetrixTools dashboard, create API Key, then copy it.",
        "ja": "HetrixTools ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://hetrixtools.com/dashboard/",
    "credentialSetupURL": "https://hetrixtools.com/dashboard/account/api/",
    "summary": {
      "zh": "服务器和黑名单监控。预充值，报账户剩余额度。",
      "en": "Server and blacklist monitoring. Prepaid. It reports account credit.",
      "ja": "サーバとブラックリスト監視。プリペイドで、アカウント残額を出します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "shipstation",
    "name": "ShipStation",
    "kind": "prepaid",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "电商出货/多承运商平台的强挑战者，北美中小卖家常用。",
    "searchKeywords": [
      "shipstation",
      "shipengine",
      "shipping",
      "label"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 ShipStation 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the ShipStation dashboard, create API Key, then copy it.",
        "ja": "ShipStation ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.shipstation.com/",
    "credentialSetupURL": "https://docs.shipstation.com/apis/shipengine/docs/getting-started",
    "summary": {
      "zh": "电商打单和多承运商发货。预充值，各承运商余额相加。",
      "en": "Ecommerce labels across carriers. Prepaid. Carrier balances, summed.",
      "ja": "EC のラベル発行と複数運送。プリペイドで、各キャリア残高を足します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "thanksio",
    "name": "thanks.io",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "实体感谢卡/直邮 API 细分里的小型选手。",
    "searchKeywords": [
      "thanks.io",
      "thanksio",
      "postcard",
      "direct mail"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 thanks.io 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the thanks.io dashboard, create API Token, then copy it.",
        "ja": "thanks.io ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.thanks.io/",
    "credentialSetupURL": "https://docs.thanks.io/authentication/bearer-token",
    "summary": {
      "zh": "实体感谢卡和直邮。按本月订单合计。",
      "en": "Physical thank-you cards and direct mail. This month’s orders, summed.",
      "ja": "実物のサンクスカードとダイレクトメール。今月の注文合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "click2mail",
    "name": "Click2Mail",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "美国商务直邮 API 细分里的区域选手。",
    "searchKeywords": [
      "click2mail",
      "click 2 mail",
      "direct mail",
      "postal"
    ],
    "fields": [
      {
        "key": "clientSecret",
        "label": {
          "zh": "Client Secret",
          "en": "Client Secret",
          "ja": "Client Secret"
        },
        "isSecret": true
      },
      {
        "key": "clientID",
        "label": {
          "zh": "Client ID",
          "en": "Client ID",
          "ja": "Client ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台 API 凭证里的 ID",
          "en": "ID from API credentials in the dashboard",
          "ja": "ダッシュボードの API 認証情報の ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Click2Mail 控制台 的 API 页面，创建 Client Secret，然后复制。",
        "en": "Open the API page in the Click2Mail dashboard, create Client Secret, then copy it.",
        "ja": "Click2Mail ダッシュボード の API ページを開き、Client Secret を作成してコピーします。"
      },
      {
        "zh": "打开 Click2Mail 控制台 的 API 页面，创建 Client ID，然后复制。",
        "en": "Open the API page in the Click2Mail dashboard, create Client ID, then copy it.",
        "ja": "Click2Mail ダッシュボード の API ページを開き、Client ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.click2mail.com/",
    "credentialSetupURL": "https://developers.click2mail.com/docs/building-your-first-api-call",
    "summary": {
      "zh": "美国商务直邮。按本月作业费用合计。",
      "en": "US business direct mail. This month’s job costs, summed.",
      "ja": "米国のビジネスダイレクトメール。今月のジョブ費用合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "gelato",
    "name": "Gelato",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "按需印刷与全球履约的强挑战者，与 Printful 等同台。",
    "searchKeywords": [
      "gelato",
      "print on demand",
      "pod"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Gelato 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Gelato dashboard, create API Key, then copy it.",
        "ja": "Gelato ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://dashboard.gelato.com/",
    "credentialSetupURL": "https://dashboard.gelato.com/apis/",
    "summary": {
      "zh": "按需印刷和全球履约。按本月订单实付合计。",
      "en": "Print-on-demand and global fulfillment. This month’s paid order totals.",
      "ja": "オンデマンド印刷とグローバルフルフィルメント。今月の実支払合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "prodigi",
    "name": "Prodigi",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "按需印刷 API 细分里的欧洲选手。",
    "searchKeywords": [
      "prodigi",
      "print api",
      "pod"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Prodigi 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Prodigi dashboard, create API Key, then copy it.",
        "ja": "Prodigi ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.prodigi.com/",
    "credentialSetupURL": "https://www.prodigi.com/print-api/docs/reference/",
    "summary": {
      "zh": "按需印刷 API。按本月订单收费合计。",
      "en": "A print-on-demand API. This month’s order charges, summed.",
      "ja": "オンデマンド印刷 API。今月の注文課金合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "qiniu",
    "name": "Qiniu",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "中国对象存储与 CDN 的强挑战者，份额次于阿里云等巨头。",
    "searchKeywords": [
      "qiniu",
      "七牛",
      "七牛云",
      "kodo"
    ],
    "fields": [
      {
        "key": "secretAccessKey",
        "label": {
          "zh": "Secret Access Key",
          "en": "Secret Access Key",
          "ja": "Secret Access Key"
        },
        "isSecret": true
      },
      {
        "key": "accessKeyID",
        "label": {
          "zh": "Access Key ID",
          "en": "Access Key ID",
          "ja": "Access Key ID"
        },
        "isSecret": false
      }
    ],
    "steps": [
      {
        "zh": "打开 Qiniu 控制台 的 API 页面，创建 Secret Access Key，然后复制。",
        "en": "Open the API page in the Qiniu dashboard, create Secret Access Key, then copy it.",
        "ja": "Qiniu ダッシュボード の API ページを開き、Secret Access Key を作成してコピーします。"
      },
      {
        "zh": "打开 Qiniu 控制台 的 API 页面，创建 Access Key ID，然后复制。",
        "en": "Open the API page in the Qiniu dashboard, create Access Key ID, then copy it.",
        "ja": "Qiniu ダッシュボード の API ページを開き、Access Key ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://portal.qiniu.com/",
    "credentialSetupURL": "https://developer.qiniu.com/kodo/1201/access-key",
    "summary": {
      "zh": "对象存储和 CDN。优先本月账单，否则报预充值余额；人民币会折成美元。",
      "en": "Object storage and CDN. Prefers this month’s bill, else prepaid balance. CNY converts to USD.",
      "ja": "オブジェクトストレージと CDN。今月の請求を優先し、なければプリペイド残額。人民元はドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "mysendingbox",
    "name": "MySendingBox",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "法国实体信函 API 细分里的小型选手。",
    "searchKeywords": [
      "mysendingbox",
      "my sending box",
      "courrier",
      "lettre"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 MySendingBox 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the MySendingBox dashboard, create API Key, then copy it.",
        "ja": "MySendingBox ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.mysendingbox.fr/",
    "credentialSetupURL": "https://docs.mysendingbox.fr/",
    "summary": {
      "zh": "法国实体信函。按本月信件费用合计，欧元会折成美元。",
      "en": "French physical letters. This month’s letter charges. Euros convert to USD.",
      "ja": "フランスの紙の郵便。今月の手紙費用合計で、ユーロはドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "stannp",
    "name": "Stannp",
    "kind": "prepaid",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "英国直邮/明信片 API 细分里的小型选手。",
    "searchKeywords": [
      "stannp",
      "direct mail",
      "postcard"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Stannp 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Stannp dashboard, create API Key, then copy it.",
        "ja": "Stannp ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.stannp.com/",
    "credentialSetupURL": "https://www.stannp.com/us/direct-mail-api/accounts",
    "summary": {
      "zh": "英国直邮和明信片。预充值，报剩余额度。",
      "en": "UK direct mail and postcards. Prepaid. It reports remaining balance.",
      "ja": "英国のダイレクトメールとはがき。プリペイドで、残額を出します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "phaxio",
    "name": "Phaxio",
    "kind": "prepaid",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "开发者传真 API 细分里的小型选手。",
    "searchKeywords": [
      "phaxio",
      "fax",
      "fax api"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      },
      {
        "key": "clientSecret",
        "label": {
          "zh": "Client Secret",
          "en": "Client Secret",
          "ja": "Client Secret"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Phaxio 控制台 的 API 页面，创建 API Key 和 Client Secret，然后复制。",
        "en": "Open the API page in the Phaxio dashboard, create API Key and Client Secret, then copy them.",
        "ja": "Phaxio ダッシュボード の API ページを開き、API Key と Client Secret を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.phaxio.com/",
    "credentialSetupURL": "https://www.phaxio.com/docs/api/v2/account/get_status",
    "summary": {
      "zh": "开发者传真。预充值，报剩余额度。",
      "en": "Developer fax. Prepaid. It reports remaining balance.",
      "ja": "開発者向け FAX。プリペイドで、残額を出します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "porkbun",
    "name": "Porkbun",
    "kind": "prepaid",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "低价域名注册商里的活跃挑战者，份额小于 GoDaddy/Namecheap。",
    "searchKeywords": [
      "porkbun",
      "domain",
      "dns"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      },
      {
        "key": "clientSecret",
        "label": {
          "zh": "Client Secret",
          "en": "Client Secret",
          "ja": "Client Secret"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Porkbun 控制台 的 API 页面，创建 API Key 和 Client Secret，然后复制。",
        "en": "Open the API page in the Porkbun dashboard, create API Key and Client Secret, then copy them.",
        "ja": "Porkbun ダッシュボード の API ページを開き、API Key と Client Secret を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://porkbun.com/",
    "credentialSetupURL": "https://porkbun.com/api/json/v3/documentation",
    "summary": {
      "zh": "低价域名。预充值，报剩余额度。",
      "en": "Low-cost domains. Prepaid. It reports remaining balance.",
      "ja": "低価格ドメイン。プリペイドで、残額を出します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "namecheap",
    "name": "Namecheap",
    "kind": "prepaid",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "大众域名注册的强挑战者，长期与 GoDaddy 争夺中小客户。",
    "searchKeywords": [
      "namecheap",
      "domain",
      "dns"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Account ID",
          "en": "Account ID",
          "ja": "Account ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台里的账户或组织 ID",
          "en": "Account or organization ID in the dashboard",
          "ja": "ダッシュボードのアカウントまたは組織 ID"
        }
      },
      {
        "key": "clientID",
        "label": {
          "zh": "Client ID",
          "en": "Client ID",
          "ja": "Client ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台 API 凭证里的 ID",
          "en": "ID from API credentials in the dashboard",
          "ja": "ダッシュボードの API 認証情報の ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Namecheap 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Namecheap dashboard, create API Key, then copy it.",
        "ja": "Namecheap ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      },
      {
        "zh": "打开 Namecheap 控制台 的 API 页面，创建 Account ID 和 Client ID，然后复制。",
        "en": "Open the API page in the Namecheap dashboard, create Account ID and Client ID, then copy them.",
        "ja": "Namecheap ダッシュボード の API ページを開き、Account ID と Client ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.namecheap.com/",
    "credentialSetupURL": "https://www.namecheap.com/support/api/intro/",
    "summary": {
      "zh": "大众域名注册。预充值，报可用余额。",
      "en": "Consumer domain registration. Prepaid. It reports available balance.",
      "ja": "一般向けドメイン登録。プリペイドで、利用可能残高を出します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "gandi",
    "name": "Gandi",
    "kind": "prepaid",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "欧洲域名与简易主机的传统选手，份额持续被挤压。",
    "searchKeywords": [
      "gandi",
      "domain",
      "dns",
      "gandinet"
    ],
    "fields": [
      {
        "key": "personalAccessToken",
        "label": {
          "zh": "Personal Access Token",
          "en": "Personal Access Token",
          "ja": "Personal Access Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Gandi 控制台 的 API 页面，创建 Personal Access Token，然后复制。",
        "en": "Open the API page in the Gandi dashboard, create Personal Access Token, then copy it.",
        "ja": "Gandi ダッシュボード の API ページを開き、Personal Access Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://admin.gandi.net/",
    "credentialSetupURL": "https://api.gandi.net/docs/authentication/",
    "summary": {
      "zh": "欧洲域名和简易主机。预充值，报剩余额度。",
      "en": "European domains and simple hosting. Prepaid. It reports remaining balance.",
      "ja": "欧州のドメインと簡易ホスティング。プリペイドで、残額を出します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "shippo",
    "name": "Shippo",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "开发者物流 API 的强挑战者，与 EasyPost 并列短名单。",
    "searchKeywords": [
      "shippo",
      "shipping",
      "label",
      "goshippo"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Shippo 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Shippo dashboard, create API Key, then copy it.",
        "ja": "Shippo ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://apps.goshippo.com/",
    "credentialSetupURL": "https://docs.goshippo.com/docs/guides_general/authentication/",
    "summary": {
      "zh": "买标签和物流 API。按本月已购标签运费合计。",
      "en": "Label purchase and shipping APIs. This month’s purchased-label postage, summed.",
      "ja": "ラベル購入と物流 API。今月買ったラベル運賃の合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "printful",
    "name": "Printful",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "按需印刷履约的龙头之一，品牌与卖家渗透率最高。",
    "searchKeywords": [
      "printful",
      "print on demand",
      "pod",
      "fulfillment"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Printful 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Printful dashboard, create API Key, then copy it.",
        "ja": "Printful ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.printful.com/dashboard",
    "credentialSetupURL": "https://developers.printful.com/docs/",
    "summary": {
      "zh": "按需印刷履约。按本月向你收取的履约成本合计。",
      "en": "Print-on-demand fulfillment. This month’s fulfillment costs charged to you.",
      "ja": "オンデマンド印刷のフルフィルメント。今月あなたに請求された履行コスト合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "gooten",
    "name": "Gooten",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "按需印刷聚合细分里的小型选手。",
    "searchKeywords": [
      "gooten",
      "print on demand",
      "pod",
      "print.io"
    ],
    "fields": [
      {
        "key": "clientSecret",
        "label": {
          "zh": "Client Secret",
          "en": "Client Secret",
          "ja": "Client Secret"
        },
        "isSecret": true
      },
      {
        "key": "clientID",
        "label": {
          "zh": "Client ID",
          "en": "Client ID",
          "ja": "Client ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台 API 凭证里的 ID",
          "en": "ID from API credentials in the dashboard",
          "ja": "ダッシュボードの API 認証情報の ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Gooten 控制台 的 API 页面，创建 Client Secret，然后复制。",
        "en": "Open the API page in the Gooten dashboard, create Client Secret, then copy it.",
        "ja": "Gooten ダッシュボード の API ページを開き、Client Secret を作成してコピーします。"
      },
      {
        "zh": "打开 Gooten 控制台 的 API 页面，创建 Client ID，然后复制。",
        "en": "Open the API page in the Gooten dashboard, create Client ID, then copy it.",
        "ja": "Gooten ダッシュボード の API ページを開き、Client ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.gooten.com/",
    "credentialSetupURL": "https://www.gooten.com/api-documentation/",
    "summary": {
      "zh": "按需印刷货源聚合。按本月订单应付合计。",
      "en": "A print-on-demand supplier network. This month’s order amounts due.",
      "ja": "オンデマンド印刷の仕入れ集約。今月の注文支払い合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "easyship",
    "name": "Easyship",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "跨境电商物流软件的强挑战者。",
    "searchKeywords": [
      "easyship",
      "shipping",
      "fulfillment"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Easyship 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the Easyship dashboard, create API Token, then copy it.",
        "ja": "Easyship ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://app.easyship.com/",
    "credentialSetupURL": "https://developers.easyship.com/reference/billing_documents_index",
    "summary": {
      "zh": "跨境电商物流软件。按本月账单文件合计。",
      "en": "Cross-border ecommerce shipping software. This month’s billing documents, summed.",
      "ja": "越境 EC の物流ソフト。今月の請求書類合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "huaweicloud",
    "name": "Huawei Cloud",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "中国公有云第二梯队强挑战者，全球份额仍小于三巨头。",
    "searchKeywords": [
      "huawei",
      "huaweicloud",
      "华为云",
      "bss"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Huawei Cloud 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the Huawei Cloud dashboard, create API Token, then copy it.",
        "ja": "Huawei Cloud ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://account-intl.myhuaweicloud.com/",
    "credentialSetupURL": "https://support.huaweicloud.com/intl/en-us/api-oce/mbc_00008.html",
    "summary": {
      "zh": "华为云国际站。按本月账单合计。",
      "en": "Huawei Cloud International. This month’s bill total.",
      "ja": "Huawei Cloud 国際サイト。今月の請求合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "zilliz",
    "name": "Zilliz Cloud",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "托管向量库里的强挑战者，与 Pinecone 等同台。",
    "searchKeywords": [
      "zilliz",
      "milvus",
      "vector",
      "向量"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Zilliz Cloud 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Zilliz Cloud dashboard, create API Key, then copy it.",
        "ja": "Zilliz Cloud ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://cloud.zilliz.com/",
    "credentialSetupURL": "https://docs.zilliz.com/docs/api-keys",
    "summary": {
      "zh": "托管 Milvus 向量库。按日用量花费。",
      "en": "Managed Milvus. Daily usage spend.",
      "ja": "マネージド Milvus。日次の用量支出です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "soniox",
    "name": "Soniox",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "语音转写 API 细分里的小型选手。",
    "searchKeywords": [
      "soniox",
      "stt",
      "speech",
      "asr",
      "语音"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Soniox 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Soniox dashboard, create API Key, then copy it.",
        "ja": "Soniox ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://console.soniox.com/",
    "credentialSetupURL": "https://soniox.com/docs/speech-to-text/api-reference/authentication",
    "summary": {
      "zh": "语音转写。按本月用量花费。",
      "en": "Speech-to-text. This month’s usage spend.",
      "ja": "音声書き起こし。今月の用量支出です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "quay",
    "name": "Quay.io",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "企业容器镜像仓库的强挑战者，红帽生态内地位稳固。",
    "searchKeywords": [
      "quay",
      "quay.io",
      "container registry",
      "镜像仓库"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://quay.io/organization/",
    "credentialSetupURL": "https://docs.quay.io/api/"
  },
  {
    "key": "glesys",
    "name": "GleSYS",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "北欧区域云/主机的小型选手。",
    "searchKeywords": [
      "glesys",
      "sweden",
      "invoice/list",
      "SEK",
      "customernumber"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Account ID",
          "en": "Account ID",
          "ja": "Account ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台里的账户或组织 ID",
          "en": "Account or organization ID in the dashboard",
          "ja": "ダッシュボードのアカウントまたは組織 ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 GleSYS 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the GleSYS dashboard, create API Key, then copy it.",
        "ja": "GleSYS ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      },
      {
        "zh": "打开 GleSYS 控制台 的 API 页面，创建 Account ID，然后复制。",
        "en": "Open the API page in the GleSYS dashboard, create Account ID, then copy it.",
        "ja": "GleSYS ダッシュボード の API ページを開き、Account ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://customer.glesys.com/",
    "credentialSetupURL": "https://github.com/glesys/api-docs/wiki/API-Documentation#invoicelist",
    "summary": {
      "zh": "北欧云主机。按本月发票合计，克朗会折成美元。",
      "en": "Nordic cloud hosts. This month’s invoices, summed. Kronor convert to USD.",
      "ja": "北欧のクラウドホスト。今月のインボイス合計で、クローナはドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "cloudsigma",
    "name": "CloudSigma",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 3,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "欧洲弹性云老将，近年声量与份额走弱。",
    "searchKeywords": [
      "cloudsigma",
      "ledger",
      "burst",
      "ignore balance",
      "CHF"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      },
      {
        "key": "email",
        "label": {
          "zh": "Email",
          "en": "Email",
          "ja": "Email"
        },
        "isSecret": false,
        "hint": {
          "zh": "登录邮箱",
          "en": "Sign-in email",
          "ja": "ログイン用メール"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 CloudSigma 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the CloudSigma dashboard, create API Key, then copy it.",
        "ja": "CloudSigma ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      },
      {
        "zh": "打开 CloudSigma 控制台 的 API 页面，创建 Email，然后复制。",
        "en": "Open the API page in the CloudSigma dashboard, create Email, then copy it.",
        "ja": "CloudSigma ダッシュボード の API ページを開き、Email を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://ui.cloudsigma.com/",
    "credentialSetupURL": "https://docs.cloudsigma.com/en/latest/billing.html",
    "summary": {
      "zh": "欧洲弹性云。按用量账本扣费，不报预付钱包。",
      "en": "European elastic cloud. Ledger usage charges; not the prepaid wallet.",
      "ja": "欧州のエラスティッククラウド。使用台帳の引き落としで、プリペイド残高は出しません。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "vpsnet",
    "name": "VPS.NET",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "老牌 VPS 品牌份额持续下滑。",
    "searchKeywords": [
      "vps.net",
      "vpsnet",
      "vps"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      },
      {
        "key": "email",
        "label": {
          "zh": "Email",
          "en": "Email",
          "ja": "Email"
        },
        "isSecret": false,
        "hint": {
          "zh": "登录邮箱",
          "en": "Sign-in email",
          "ja": "ログイン用メール"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 VPS.NET 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the VPS.NET dashboard, create API Key, then copy it.",
        "ja": "VPS.NET ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      },
      {
        "zh": "打开 VPS.NET 控制台 的 API 页面，创建 Email，然后复制。",
        "en": "Open the API page in the VPS.NET dashboard, create Email, then copy it.",
        "ja": "VPS.NET ダッシュボード の API ページを開き、Email を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://control.vps.net/",
    "credentialSetupURL": "https://control.vps.net/api/",
    "summary": {
      "zh": "老牌 VPS。按本月发票合计。",
      "en": "A long-running VPS brand. This month’s invoices, summed.",
      "ja": "老舗 VPS。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "voltagepark",
    "name": "Voltage Park",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "GPU 云算力新秀，规模仍远小于 CoreWeave/Vast。",
    "searchKeywords": [
      "voltage park",
      "voltagepark",
      "tensordock",
      "gpu"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Voltage Park 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the Voltage Park dashboard, create API Token, then copy it.",
        "ja": "Voltage Park ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://cloud.voltagepark.com",
    "credentialSetupURL": "https://docs.voltagepark.com/",
    "summary": {
      "zh": "GPU 云和裸金属。按本月按量扣费，充值不算进去。",
      "en": "GPU cloud and bare metal. This month’s usage charges; deposits are skipped.",
      "ja": "GPU クラウドとベアメタル。今月の従量課金で、入金は数えません。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "smsc",
    "name": "SMSC.ru",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "欧洲短信网关细分里的区域选手。",
    "searchKeywords": [
      "smsc.ru",
      "sms центр",
      "смс"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://smsc.ru",
    "credentialSetupURL": "https://smsc.ru/passwords/"
  },
  {
    "key": "openprovider",
    "name": "Openprovider",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "域名批发商细分里的欧洲选手。",
    "searchKeywords": [
      "openprovider",
      "domains",
      "reseller"
    ],
    "fields": [
      {
        "key": "clientSecret",
        "label": {
          "zh": "Client Secret",
          "en": "Client Secret",
          "ja": "Client Secret"
        },
        "isSecret": true
      },
      {
        "key": "email",
        "label": {
          "zh": "Email",
          "en": "Email",
          "ja": "Email"
        },
        "isSecret": false,
        "hint": {
          "zh": "登录邮箱",
          "en": "Sign-in email",
          "ja": "ログイン用メール"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Openprovider 控制台 的 API 页面，创建 Client Secret，然后复制。",
        "en": "Open the API page in the Openprovider dashboard, create Client Secret, then copy it.",
        "ja": "Openprovider ダッシュボード の API ページを開き、Client Secret を作成してコピーします。"
      },
      {
        "zh": "打开 Openprovider 控制台 的 API 页面，创建 Email，然后复制。",
        "en": "Open the API page in the Openprovider dashboard, create Email, then copy it.",
        "ja": "Openprovider ダッシュボード の API ページを開き、Email を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://rcp.openprovider.eu",
    "credentialSetupURL": "https://docs.openprovider.com/doc#tag/InvoiceService",
    "summary": {
      "zh": "域名批发。按本月用量。",
      "en": "Domain wholesale. This month’s usage.",
      "ja": "ドメイン卸売。今月の用量です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "realtimeregister",
    "name": "Realtime Register",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "域名注册 API 细分里的欧洲选手。",
    "searchKeywords": [
      "realtime register",
      "yoursrs",
      "financialtransactions",
      "cents",
      "EUR"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Realtime Register 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Realtime Register dashboard, create API Key, then copy it.",
        "ja": "Realtime Register ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://dm.realtimeregister.com",
    "credentialSetupURL": "https://dm.realtimeregister.com/docs/api/transactions/list",
    "summary": {
      "zh": "欧洲域名注册 API。按本月交易合计，欧元会折成美元。",
      "en": "A European domain-registration API. This month’s transactions, summed. Euros convert to USD.",
      "ja": "欧州のドメイン登録 API。今月の取引合計で、ユーロはドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "stackit",
    "name": "STACKIT",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "德国主权云/公共云挑战者，仍远小于 Hyperscaler。",
    "searchKeywords": [
      "stackit",
      "schwarz",
      "deutsche telekom cloud"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Account ID",
          "en": "Account ID",
          "ja": "Account ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台里的账户或组织 ID",
          "en": "Account or organization ID in the dashboard",
          "ja": "ダッシュボードのアカウントまたは組織 ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 STACKIT 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the STACKIT dashboard, create API Token, then copy it.",
        "ja": "STACKIT ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      },
      {
        "zh": "打开 STACKIT 控制台 的 API 页面，创建 Account ID，然后复制。",
        "en": "Open the API page in the STACKIT dashboard, create Account ID, then copy it.",
        "ja": "STACKIT ダッシュボード の API ページを開き、Account ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://portal.stackit.cloud",
    "credentialSetupURL": "https://docs.stackit.cloud/platform/cost-and-billing/how-tos/retrieve-stackit-invoices/",
    "summary": {
      "zh": "德国主权云。按本月用量。",
      "en": "German sovereign cloud. This month’s usage.",
      "ja": "ドイツのソブリンクラウド。今月の用量です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "unleash",
    "name": "Unleash",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "开源功能开关的强挑战者，与 LaunchDarkly 分流。",
    "searchKeywords": [
      "unleash",
      "feature flags",
      "invoices/list",
      "totalAmount",
      "enterprise"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Unleash 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the Unleash dashboard, create API Token, then copy it.",
        "ja": "Unleash ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.getunleash.io",
    "credentialSetupURL": "https://docs.getunleash.io/api/get-detailed-invoices",
    "summary": {
      "zh": "功能开关。按本月发票合计。",
      "en": "Feature flags. This month’s invoices, summed.",
      "ja": "フィーチャーフラグ。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "rediscloud",
    "name": "Redis Cloud",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 3,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "托管 Redis 的品类龙头，企业采购默认选项。",
    "searchKeywords": [
      "redis cloud",
      "redis labs",
      "cost-report",
      "FOCUS",
      "BilledCost"
    ],
    "fields": [
      {
        "key": "secretAccessKey",
        "label": {
          "zh": "Secret Access Key",
          "en": "Secret Access Key",
          "ja": "Secret Access Key"
        },
        "isSecret": true
      },
      {
        "key": "accessKeyID",
        "label": {
          "zh": "Access Key ID",
          "en": "Access Key ID",
          "ja": "Access Key ID"
        },
        "isSecret": false
      }
    ],
    "steps": [
      {
        "zh": "打开 Redis Cloud 控制台 的 API 页面，创建 Secret Access Key，然后复制。",
        "en": "Open the API page in the Redis Cloud dashboard, create Secret Access Key, then copy it.",
        "ja": "Redis Cloud ダッシュボード の API ページを開き、Secret Access Key を作成してコピーします。"
      },
      {
        "zh": "打开 Redis Cloud 控制台 的 API 页面，创建 Access Key ID，然后复制。",
        "en": "Open the API page in the Redis Cloud dashboard, create Access Key ID, then copy it.",
        "ja": "Redis Cloud ダッシュボード の API ページを開き、Access Key ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://app.redislabs.com/",
    "credentialSetupURL": "https://redis.io/docs/latest/operate/rc/api/examples/generate-cost-report/",
    "summary": {
      "zh": "托管 Redis。按本月 FOCUS 已计成本。",
      "en": "Managed Redis. This month’s FOCUS billed cost.",
      "ja": "マネージド Redis。今月の FOCUS 計上コストです。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "pdfshift",
    "name": "PDFShift",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "HTML 转 PDF API 细分里的小型选手。",
    "searchKeywords": [
      "pdfshift",
      "invoices",
      "USD",
      "html to pdf"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 PDFShift 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the PDFShift dashboard, create API Key, then copy it.",
        "ja": "PDFShift ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://app.pdfshift.io/dashboard/",
    "credentialSetupURL": "https://docs.pdfshift.io/api-reference/invoices-list",
    "summary": {
      "zh": "网页转 PDF。按本月发票合计。",
      "en": "Web pages to PDF. This month’s invoices, summed.",
      "ja": "ウェブページから PDF。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "surrealdb",
    "name": "SurrealDB Cloud",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "多模型数据库新秀，商业化仍早。",
    "searchKeywords": [
      "surrealdb",
      "surreal",
      "cloud"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Account ID",
          "en": "Account ID",
          "ja": "Account ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台里的账户或组织 ID",
          "en": "Account or organization ID in the dashboard",
          "ja": "ダッシュボードのアカウントまたは組織 ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 SurrealDB Cloud 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the SurrealDB Cloud dashboard, create API Token, then copy it.",
        "ja": "SurrealDB Cloud ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      },
      {
        "zh": "打开 SurrealDB Cloud 控制台 的 API 页面，创建 Account ID，然后复制。",
        "en": "Open the API page in the SurrealDB Cloud dashboard, create Account ID, then copy it.",
        "ja": "SurrealDB Cloud ダッシュボード の API ページを開き、Account ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://app.surrealdb.com",
    "credentialSetupURL": "https://docs.surrealdb.com/cloud/",
    "summary": {
      "zh": "多模型数据库。按本月用量花费。",
      "en": "A multi-model database. This month’s usage spend.",
      "ja": "マルチモデルデータベース。今月の用量支出です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "simply",
    "name": "Simply.com",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "北欧域名/主机的区域选手。",
    "searchKeywords": [
      "simply.com",
      "simply",
      "unoeuro",
      "dk host"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Simply.com 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Simply.com dashboard, create API Key, then copy it.",
        "ja": "Simply.com ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.simply.com/en/controlpanel/",
    "credentialSetupURL": "https://www.simply.com/en/docs/api/",
    "summary": {
      "zh": "丹麦域名和主机。按本月已付发票合计。",
      "en": "Danish domains and hosting. This month’s paid invoices, summed.",
      "ja": "デンマークのドメインとホスティング。今月の支払い済みインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "domeneshop",
    "name": "Domeneshop",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 36,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "挪威域名注册的区域选手。",
    "searchKeywords": [
      "domeneshop",
      "domainshop",
      "hyp.net",
      "norway"
    ],
    "fields": [
      {
        "key": "secretAccessKey",
        "label": {
          "zh": "Secret Access Key",
          "en": "Secret Access Key",
          "ja": "Secret Access Key"
        },
        "isSecret": true
      },
      {
        "key": "accessKeyID",
        "label": {
          "zh": "Access Key ID",
          "en": "Access Key ID",
          "ja": "Access Key ID"
        },
        "isSecret": false
      }
    ],
    "steps": [
      {
        "zh": "打开 Domeneshop 控制台 的 API 页面，创建 Secret Access Key，然后复制。",
        "en": "Open the API page in the Domeneshop dashboard, create Secret Access Key, then copy it.",
        "ja": "Domeneshop ダッシュボード の API ページを開き、Secret Access Key を作成してコピーします。"
      },
      {
        "zh": "打开 Domeneshop 控制台 的 API 页面，创建 Access Key ID，然后复制。",
        "en": "Open the API page in the Domeneshop dashboard, create Access Key ID, then copy it.",
        "ja": "Domeneshop ダッシュボード の API ページを開き、Access Key ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.domeneshop.no/",
    "credentialSetupURL": "https://api.domeneshop.no/docs/",
    "summary": {
      "zh": "挪威域名。按本月发票合计，克朗会折成美元。",
      "en": "Norwegian domains. This month’s invoices, summed. Kroner convert to USD.",
      "ja": "ノルウェーのドメイン。今月のインボイス合計で、クローネはドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "websupport",
    "name": "Websupport",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "中东欧主机与域名的区域选手。",
    "searchKeywords": [
      "websupport",
      "websupport.sk",
      "websupport.se",
      "slovakia"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      },
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Account ID",
          "en": "Account ID",
          "ja": "Account ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台里的账户或组织 ID",
          "en": "Account or organization ID in the dashboard",
          "ja": "ダッシュボードのアカウントまたは組織 ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Websupport 控制台 的 API 页面，创建 API Key 和 API Token，然后复制。",
        "en": "Open the API page in the Websupport dashboard, create API Key and API Token, then copy them.",
        "ja": "Websupport ダッシュボード の API ページを開き、API Key と API Token を作成してコピーします。"
      },
      {
        "zh": "打开 Websupport 控制台 的 API 页面，创建 Account ID，然后复制。",
        "en": "Open the API page in the Websupport dashboard, create Account ID, then copy it.",
        "ja": "Websupport ダッシュボード の API ページを開き、Account ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://admin.websupport.sk/",
    "credentialSetupURL": "https://rest.websupport.se/docs/v1.intro",
    "summary": {
      "zh": "斯洛伐克主机和域名。按本月正式发票合计。",
      "en": "Slovak hosting and domains. This month’s issued invoices, summed.",
      "ja": "スロバキアのホスティングとドメイン。今月の正式インボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "active24",
    "name": "Active24",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "中东欧主机与域名的区域选手。",
    "searchKeywords": [
      "active24",
      "active 24",
      "a24",
      "czech hosting"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Active24 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the Active24 dashboard, create API Token, then copy it.",
        "ja": "Active24 ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://client.active24.com/",
    "credentialSetupURL": "https://api.active24.com/",
    "summary": {
      "zh": "捷克主机和域名。按本月发票合计。",
      "en": "Czech hosting and domains. This month’s invoices, summed.",
      "ja": "チェコのホスティングとドメイン。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "azion",
    "name": "Azion",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "拉美边缘/CDN 的区域挑战者。",
    "searchKeywords": [
      "azion",
      "azion.com",
      "edge",
      "cdn brazil"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Azion 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the Azion dashboard, create API Token, then copy it.",
        "ja": "Azion ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://console.azion.com/billing",
    "credentialSetupURL": "https://www.azion.com/en/documentation/devtools/graphql-api/first-steps/",
    "summary": {
      "zh": "拉美边缘和 CDN。按账单债务窗口合计。",
      "en": "Latin-American edge and CDN. The billing-debt window, summed.",
      "ja": "ラテンアメリカのエッジと CDN。請求債務ウィンドウの合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "elastx",
    "name": "Elastx",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "瑞典本地云的区域选手。",
    "searchKeywords": [
      "elastx",
      "elastx.se",
      "cloudkitty",
      "openstack sweden",
      "sek"
    ],
    "fields": [
      {
        "key": "secretAccessKey",
        "label": {
          "zh": "Secret Access Key",
          "en": "Secret Access Key",
          "ja": "Secret Access Key"
        },
        "isSecret": true
      },
      {
        "key": "accessKeyID",
        "label": {
          "zh": "Access Key ID",
          "en": "Access Key ID",
          "ja": "Access Key ID"
        },
        "isSecret": false
      }
    ],
    "steps": [
      {
        "zh": "打开 Elastx 控制台 的 API 页面，创建 Secret Access Key，然后复制。",
        "en": "Open the API page in the Elastx dashboard, create Secret Access Key, then copy it.",
        "ja": "Elastx ダッシュボード の API ページを開き、Secret Access Key を作成してコピーします。"
      },
      {
        "zh": "打开 Elastx 控制台 的 API 页面，创建 Access Key ID，然后复制。",
        "en": "Open the API page in the Elastx dashboard, create Access Key ID, then copy it.",
        "ja": "Elastx ダッシュボード の API ページを開き、Access Key ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://ops.elastx.cloud/",
    "credentialSetupURL": "https://docs.elastx.cloud/docs/openstack-iaas/guides/billing/",
    "summary": {
      "zh": "瑞典 OpenStack 云。按本月评分合计，克朗会折成美元。",
      "en": "Swedish OpenStack cloud. This month’s rating total. Kronor convert to USD.",
      "ja": "スウェーデンの OpenStack クラウド。今月のレーティング合計で、クローナはドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "warpstream",
    "name": "WarpStream",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "无磁盘 Kafka 兼容新秀，体量仍小。",
    "searchKeywords": [
      "warpstream",
      "kafka",
      "byoc",
      "streaming"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 WarpStream 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the WarpStream dashboard, create API Key, then copy it.",
        "ja": "WarpStream ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://console.warpstream.com/",
    "credentialSetupURL": "https://docs.warpstream.com/warpstream/reference/api-reference/invoices/get-pending-invoice",
    "summary": {
      "zh": "无磁盘 Kafka 兼容流。按当期未出账发票。",
      "en": "Diskless Kafka-compatible streaming. The current pending invoice.",
      "ja": "ディスクレスの Kafka 互換ストリーミング。当期の未出帳インボイスです。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "neo4j",
    "name": "Neo4j Aura",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 86400,
    "marketTier": 1,
    "marketTierReason": "图数据库品类的事实标准，Aura 托管份额领先。",
    "searchKeywords": [
      "neo4j",
      "aura",
      "graph",
      "acu",
      "cypher"
    ],
    "fields": [
      {
        "key": "clientID",
        "label": {
          "zh": "Client ID",
          "en": "Client ID",
          "ja": "Client ID"
        },
        "isSecret": false,
        "validation": {
          "zh": "Client ID 太短，确认复制完整",
          "en": "Client ID is too short. Make sure you copied the whole thing.",
          "ja": "Client ID が短すぎます。全部コピーできているか確認してください。"
        }
      },
      {
        "key": "clientSecret",
        "label": {
          "zh": "Client Secret",
          "en": "Client Secret",
          "ja": "Client Secret"
        },
        "isSecret": true,
        "validation": {
          "zh": "Client Secret 太短，确认复制完整",
          "en": "Client Secret is too short. Make sure you copied the whole thing.",
          "ja": "Client Secret が短すぎます。全部コピーできているか確認してください。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Neo4j Aura 的 Client credentials 页面，点 Create client credential。",
        "en": "Open Client credentials in Neo4j Aura and tap Create client credential.",
        "ja": "Neo4j Aura の Client credentials を開き、Create client credential をタップします。"
      },
      {
        "zh": "弹窗里会同时给出 Client ID 和 Client Secret。Secret 关掉就看不到了，立刻复制。",
        "en": "The modal shows Client ID and Client Secret together. The Secret is shown only once — copy it right away.",
        "ja": "ダイアログに Client ID と Client Secret が同時に出ます。Secret は閉じると二度と見えません。すぐにコピーしてください。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "Client ID / Secret 不匹配，或者这对凭据被删了。",
          "en": "Client ID / Secret don’t match, or this credential was deleted.",
          "ja": "Client ID / Secret が一致しないか、この認証情報が削除されています。"
        },
        "nextStep": {
          "zh": "回上一步重建一对。Secret 只在创建时显示一次。",
          "en": "Go back a step and create a new pair. The Secret is shown only once, at creation.",
          "ja": "前の手順に戻って作り直してください。Secret は作成時に一度だけ表示されます。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这对凭据跟着登录账号的角色走。看组织账单需要 Organization Owner 或 Organization Admin。",
          "en": "These credentials inherit the signed-in account’s roles. Organization billing needs Organization Owner or Organization Admin.",
          "ja": "この認証情報はログイン中のアカウントのロールを引き継ぎます。組織の請求を見るには Organization Owner または Organization Admin が必要です。"
        },
        "nextStep": {
          "zh": "换有权限的账号再创建一对。",
          "en": "Sign in with an account that has that role, then create a new pair.",
          "ja": "権限のあるアカウントでログインし直して、新しい組を作成してください。"
        },
        "httpStatus": 403
      },
      {
        "explanation": {
          "zh": "账单接口每个组织每天只能打 10 次，数据也是一天更新一次。",
          "en": "The billing API allows 10 calls per organization per day, and the data itself only updates once a day.",
          "ja": "請求 API は組織ごとに 1 日 10 回までで、データ自体も 1 日 1 回しか更新されません。"
        },
        "nextStep": {
          "zh": "今天已经取过就等到明天。",
          "en": "If you already fetched today, wait until tomorrow.",
          "ja": "今日すでに取得済みなら、明日まで待ってください。"
        },
        "httpStatus": 429
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://console.neo4j.io/",
    "credentialSetupURL": "https://console.neo4j.io/account/client-credentials",
    "summary": {
      "zh": "托管图数据库。按 ACU 用量月底结算。",
      "en": "Managed graph database. Billed by ACU usage at month end.",
      "ja": "マネージドグラフデータベース。ACU の従量課金で月末に精算します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和组织 Billing 页本月用量一致。免费实例是 $0。用量最多滞后两天。",
      "en": "This number should match this month’s usage on the organization Billing page. A Free instance is $0. Usage can lag by up to two days.",
      "ja": "この数字は組織の Billing ページの今月の利用額と一致するはずです。Free インスタンスは $0 です。利用量は最大 2 日遅れることがあります。"
    }
  },
  {
    "key": "digicert",
    "name": "DigiCert",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "公共信任 TLS 证书市场的寡头之一。",
    "searchKeywords": [
      "digicert",
      "certcentral",
      "ssl",
      "tls",
      "certificate"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 DigiCert 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the DigiCert dashboard, create API Key, then copy it.",
        "ja": "DigiCert ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.digicert.com/account/",
    "credentialSetupURL": "https://dev.digicert.com/certcentral-apis/services-api/finance/view-balance.html",
    "summary": {
      "zh": "TLS 证书。按应付发票和消费记录，不报存款钱包。",
      "en": "TLS certificates. Unpaid invoices and spend history; not the deposit wallet.",
      "ja": "TLS 証明書。未払いインボイスと消費履歴で、預金ウォレットは出しません。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "deel",
    "name": "Deel",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "全球雇佣/薪资合规的龙头挑战者，EOR 赛道份额领先。",
    "searchKeywords": [
      "deel.com",
      "letsdeel",
      "invoices",
      "platform fee"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Deel 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Deel dashboard, create API Key, then copy it.",
        "ja": "Deel ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://app.deel.com",
    "credentialSetupURL": "https://developer.deel.com",
    "summary": {
      "zh": "全球雇佣和薪资合规。这里只记平台费，工资过账不算。",
      "en": "Global hiring and payroll compliance. This records platform fees, not payroll funding.",
      "ja": "グローバル雇用と給与コンプライアンス。プラットフォーム手数料だけで、給与の立て替えは数えません。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "remote",
    "name": "Remote",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "全球雇佣平台的强挑战者，与 Deel 争夺中大客户。",
    "searchKeywords": [
      "remote.com",
      "eor",
      "peo",
      "billing-documents"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Remote 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Remote dashboard, create API Key, then copy it.",
        "ja": "Remote ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://employ.remote.com",
    "credentialSetupURL": "https://developer.remote.com/docs/pull-eor-cost-breakdown",
    "summary": {
      "zh": "远程团队的雇佣和发薪。这里只记平台和服务费，工资过账不算。",
      "en": "Hiring and payroll for remote teams. This records platform and service fees, not payroll funding.",
      "ja": "リモートチームの雇用と給与。プラットフォームとサービス手数料だけで、給与の立て替えは数えません。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "oyster",
    "name": "Oyster",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "全球雇佣平台里规模较小但仍在增长的选手。",
    "searchKeywords": [
      "oysterhr",
      "oyster",
      "scale",
      "contractor fees"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Oyster 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Oyster dashboard, create API Key, then copy it.",
        "ja": "Oyster ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://app.oysterhr.com",
    "credentialSetupURL": "https://docs.oysterhr.com/docs/invoicing-at-oyster",
    "summary": {
      "zh": "全球雇员和承包商雇佣。这里只记平台费，工资过账不算。",
      "en": "Global employees and contractors. This records platform fees, not payroll funding.",
      "ja": "グローバルの従業員と業務委託。プラットフォーム手数料だけで、給与の立て替えは数えません。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "outscale",
    "name": "3DS OUTSCALE",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "法国主权云挑战者，份额远小于三巨头。",
    "searchKeywords": [
      "outscale",
      "3ds",
      "secnumcloud",
      "tinaos",
      "ReadConsumptionAccount"
    ],
    "fields": [
      {
        "key": "secretAccessKey",
        "label": {
          "zh": "Secret Access Key",
          "en": "Secret Access Key",
          "ja": "Secret Access Key"
        },
        "isSecret": true
      },
      {
        "key": "accessKeyID",
        "label": {
          "zh": "Access Key ID",
          "en": "Access Key ID",
          "ja": "Access Key ID"
        },
        "isSecret": false
      }
    ],
    "steps": [
      {
        "zh": "打开 3DS OUTSCALE 控制台 的 API 页面，创建 Secret Access Key，然后复制。",
        "en": "Open the API page in the 3DS OUTSCALE dashboard, create Secret Access Key, then copy it.",
        "ja": "3DS OUTSCALE ダッシュボード の API ページを開き、Secret Access Key を作成してコピーします。"
      },
      {
        "zh": "打开 3DS OUTSCALE 控制台 的 API 页面，创建 Access Key ID，然后复制。",
        "en": "Open the API page in the 3DS OUTSCALE dashboard, create Access Key ID, then copy it.",
        "ja": "3DS OUTSCALE ダッシュボード の API ページを開き、Access Key ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://cockpit.outscale.com",
    "credentialSetupURL": "https://docs.outscale.com/en/userguide/Getting-Information-About-Your-Resource-Consumption.html",
    "summary": {
      "zh": "法国主权云。按本月用量合计。",
      "en": "French sovereign cloud. This month’s usage, summed.",
      "ja": "フランスのソブリンクラウド。今月の用量合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "orangecloud",
    "name": "Orange Cloud Avenue",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "法国运营商云的区域选手。",
    "searchKeywords": [
      "orange",
      "flexible engine",
      "cloud avenue",
      "documents",
      "eccs"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      },
      {
        "key": "clientSecret",
        "label": {
          "zh": "Client Secret",
          "en": "Client Secret",
          "ja": "Client Secret"
        },
        "isSecret": true
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Account ID",
          "en": "Account ID",
          "ja": "Account ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台里的账户或组织 ID",
          "en": "Account or organization ID in the dashboard",
          "ja": "ダッシュボードのアカウントまたは組織 ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Orange Cloud Avenue 控制台 的 API 页面，创建 API Key 和 Client Secret，然后复制。",
        "en": "Open the API page in the Orange Cloud Avenue dashboard, create API Key and Client Secret, then copy them.",
        "ja": "Orange Cloud Avenue ダッシュボード の API ページを開き、API Key と Client Secret を作成してコピーします。"
      },
      {
        "zh": "打开 Orange Cloud Avenue 控制台 的 API 页面，创建 Account ID，然后复制。",
        "en": "Open the API page in the Orange Cloud Avenue dashboard, create Account ID, then copy it.",
        "ja": "Orange Cloud Avenue ダッシュボード の API ページを開き、Account ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://cloud.orange-business.com",
    "credentialSetupURL": "https://cloud.orange-business.com/wp-content/uploads/2022/11/orange-api-v9-en.pdf",
    "summary": {
      "zh": "法国运营商云。按本月账单文件合计。",
      "en": "French carrier cloud. This month’s billing documents, summed.",
      "ja": "フランス通信キャリアのクラウド。今月の請求書類合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "gridscale",
    "name": "gridscale",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 1,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "德国中小企业云的区域选手。",
    "searchKeywords": [
      "gridscale",
      "current_price",
      "iaas"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Account ID",
          "en": "Account ID",
          "ja": "Account ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台里的账户或组织 ID",
          "en": "Account or organization ID in the dashboard",
          "ja": "ダッシュボードのアカウントまたは組織 ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 gridscale 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the gridscale dashboard, create API Token, then copy it.",
        "ja": "gridscale ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      },
      {
        "zh": "打开 gridscale 控制台 的 API 页面，创建 Account ID，然后复制。",
        "en": "Open the API page in the gridscale dashboard, create Account ID, then copy it.",
        "ja": "gridscale ダッシュボード の API ページを開き、Account ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://my.gridscale.io",
    "credentialSetupURL": "https://gridscale.io/en/api-documentation/index.html",
    "summary": {
      "zh": "德国中小企业云。按本账期累计价，欧元会折成美元。",
      "en": "German SMB cloud. Accumulated price this billing period. Euros convert to USD.",
      "ja": "ドイツの中小企業クラウド。今期の累計価格で、ユーロはドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "rackspace",
    "name": "Rackspace",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 1,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "托管云老将，公有云转型后份额持续下滑。",
    "searchKeywords": [
      "rackspace",
      "estimated_charges",
      "billing api"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Account ID",
          "en": "Account ID",
          "ja": "Account ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台里的账户或组织 ID",
          "en": "Account or organization ID in the dashboard",
          "ja": "ダッシュボードのアカウントまたは組織 ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Rackspace 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Rackspace dashboard, create API Key, then copy it.",
        "ja": "Rackspace ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      },
      {
        "zh": "打开 Rackspace 控制台 的 API 页面，创建 Account ID，然后复制。",
        "en": "Open the API page in the Rackspace dashboard, create Account ID, then copy it.",
        "ja": "Rackspace ダッシュボード の API ページを開き、Account ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://accounts.rackspace.com",
    "credentialSetupURL": "https://docs.rackspace.com/reference/billing-apiguide-v2",
    "summary": {
      "zh": "托管云。按本账期预估费用。",
      "en": "Managed cloud. Estimated charges for this period.",
      "ja": "マネージドクラウド。今期の見積もり費用です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "pika",
    "name": "Pika",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 3,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "AI 视频生成 API 细分里的小型挑战者。",
    "searchKeywords": [
      "pika",
      "pika.art",
      "video",
      "spend/daily"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Pika 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Pika dashboard, create API Key, then copy it.",
        "ja": "Pika ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://dev.pika.art",
    "credentialSetupURL": "https://dev.pika.art/openapi.json",
    "summary": {
      "zh": "AI 视频生成。按每日花费合计。",
      "en": "AI video generation. Daily spend, summed.",
      "ja": "AI 動画生成。日次支出の合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "hedra",
    "name": "Hedra",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 3,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "AI 视频/口型驱动细分里的新秀。",
    "searchKeywords": [
      "hedra",
      "avatar",
      "video",
      "usage"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Hedra 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Hedra dashboard, create API Key, then copy it.",
        "ja": "Hedra ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.hedra.com",
    "credentialSetupURL": "https://www.hedra.com/docs/api-reference/v3/billing/get-usage",
    "summary": {
      "zh": "AI 口型视频。按本月用量。",
      "en": "AI talking-head video. This month’s usage.",
      "ja": "AI の口パク動画。今月の用量です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "tidbcloud",
    "name": "TiDB Cloud",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 6,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "分布式 HTAP 数据库云的强挑战者。",
    "searchKeywords": [
      "tidb",
      "pingcap",
      "bills",
      "digest"
    ],
    "fields": [
      {
        "key": "secretAccessKey",
        "label": {
          "zh": "Secret Access Key",
          "en": "Secret Access Key",
          "ja": "Secret Access Key"
        },
        "isSecret": true
      },
      {
        "key": "accessKeyID",
        "label": {
          "zh": "Access Key ID",
          "en": "Access Key ID",
          "ja": "Access Key ID"
        },
        "isSecret": false
      }
    ],
    "steps": [
      {
        "zh": "打开 TiDB Cloud 控制台 的 API 页面，创建 Secret Access Key，然后复制。",
        "en": "Open the API page in the TiDB Cloud dashboard, create Secret Access Key, then copy it.",
        "ja": "TiDB Cloud ダッシュボード の API ページを開き、Secret Access Key を作成してコピーします。"
      },
      {
        "zh": "打开 TiDB Cloud 控制台 的 API 页面，创建 Access Key ID，然后复制。",
        "en": "Open the API page in the TiDB Cloud dashboard, create Access Key ID, then copy it.",
        "ja": "TiDB Cloud ダッシュボード の API ページを開き、Access Key ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://tidbcloud.com",
    "credentialSetupURL": "https://docs.pingcap.com/tidbcloud/api/v1beta1/billing/",
    "summary": {
      "zh": "分布式 HTAP 数据库。按账单摘要。",
      "en": "Distributed HTAP database. The bill digest.",
      "ja": "分散 HTAP データベース。請求ダイジェストです。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "hyperstack",
    "name": "Hyperstack",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 3,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "GPU 云算力的中小型选手。",
    "searchKeywords": [
      "hyperstack",
      "nexgen",
      "gpu",
      "incurred_bill",
      "last-day-cost"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Hyperstack 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Hyperstack dashboard, create API Key, then copy it.",
        "ja": "Hyperstack ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://console.hyperstack.cloud",
    "credentialSetupURL": "https://docs.hyperstack.cloud/docs/api-reference/get-last-day-cost",
    "summary": {
      "zh": "按需 GPU 云。按本月用量。",
      "en": "On-demand GPU cloud. This month’s usage.",
      "ja": "オンデマンド GPU クラウド。今月の用量です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "hostup",
    "name": "HostUp",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "瑞典主机/VPS 的区域选手。",
    "searchKeywords": [
      "hostup",
      "hostup.se",
      "invoices",
      "payg",
      "sek"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 HostUp 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the HostUp dashboard, create API Key, then copy it.",
        "ja": "HostUp ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://cloud.hostup.se",
    "credentialSetupURL": "https://developer.hostup.se/endpoints/billing/get-v2-billing-invoices-id",
    "summary": {
      "zh": "瑞典 VPS。按本月发票合计。",
      "en": "Swedish VPS. This month’s invoices, summed.",
      "ja": "スウェーデンの VPS。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "memset",
    "name": "Memset",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "英国托管老将，独立品牌声量走弱。",
    "searchKeywords": [
      "memset",
      "invoice.list",
      "gbp"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Memset 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Memset dashboard, create API Key, then copy it.",
        "ja": "Memset ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.memset.com/control/",
    "credentialSetupURL": "https://www.memset.com/apidocs/methods_invoice.html",
    "summary": {
      "zh": "英国托管云。按本月发票合计。",
      "en": "UK managed cloud. This month’s invoices, summed.",
      "ja": "英国のマネージドクラウド。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "mittwald",
    "name": "mittwald",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "德国主机与应用托管的区域选手。",
    "searchKeywords": [
      "mittwald",
      "totalGross",
      "invoices"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Account ID",
          "en": "Account ID",
          "ja": "Account ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台里的账户或组织 ID",
          "en": "Account or organization ID in the dashboard",
          "ja": "ダッシュボードのアカウントまたは組織 ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 mittwald 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the mittwald dashboard, create API Key, then copy it.",
        "ja": "mittwald ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      },
      {
        "zh": "打开 mittwald 控制台 的 API 页面，创建 Account ID，然后复制。",
        "en": "Open the API page in the mittwald dashboard, create Account ID, then copy it.",
        "ja": "mittwald ダッシュボード の API ページを開き、Account ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://my.mittwald.de",
    "credentialSetupURL": "https://developer.mittwald.de/docs/v2/reference/contract/invoice-detail/",
    "summary": {
      "zh": "德国应用托管。按本月发票合计。",
      "en": "German app hosting. This month’s invoices, summed.",
      "ja": "ドイツのアプリホスティング。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "soracom",
    "name": "Soracom",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 18,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "物联网蜂窝连接平台的强挑战者，日美市场渗透高。",
    "searchKeywords": [
      "soracom",
      "iot",
      "sim",
      "bills",
      "jpy",
      "dailybill"
    ],
    "fields": [
      {
        "key": "secretAccessKey",
        "label": {
          "zh": "Secret Access Key",
          "en": "Secret Access Key",
          "ja": "Secret Access Key"
        },
        "isSecret": true
      },
      {
        "key": "accessKeyID",
        "label": {
          "zh": "Access Key ID",
          "en": "Access Key ID",
          "ja": "Access Key ID"
        },
        "isSecret": false
      }
    ],
    "steps": [
      {
        "zh": "打开 Soracom 控制台 的 API 页面，创建 Secret Access Key，然后复制。",
        "en": "Open the API page in the Soracom dashboard, create Secret Access Key, then copy it.",
        "ja": "Soracom ダッシュボード の API ページを開き、Secret Access Key を作成してコピーします。"
      },
      {
        "zh": "打开 Soracom 控制台 的 API 页面，创建 Access Key ID，然后复制。",
        "en": "Open the API page in the Soracom dashboard, create Access Key ID, then copy it.",
        "ja": "Soracom ダッシュボード の API ページを開き、Access Key ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://console.soracom.io",
    "credentialSetupURL": "https://developers.soracom.io/en/docs/account/billing/",
    "summary": {
      "zh": "物联网蜂窝连接。按本月用量。",
      "en": "IoT cellular connectivity. This month’s usage.",
      "ja": "IoT セルラー接続。今月の用量です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "starlink",
    "name": "Starlink",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "低轨卫星宽带几乎垄断可规模采购的企业选项。",
    "searchKeywords": [
      "starlink",
      "spacex",
      "invoices",
      "iso4217"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Starlink 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the Starlink dashboard, create API Token, then copy it.",
        "ja": "Starlink ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.starlink.com/account",
    "credentialSetupURL": "https://starlink.readme.io/reference/get_public-v2-billing-invoices",
    "summary": {
      "zh": "低轨卫星宽带。按本月发票合计。",
      "en": "Low-earth-orbit satellite broadband. This month’s invoices, summed.",
      "ja": "低軌道衛星ブロードバンド。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "tibber",
    "name": "Tibber",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "北欧电力零售/智能用电的强挑战者。",
    "searchKeywords": [
      "tibber",
      "electricity",
      "consumption",
      "graphql",
      "nordic"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Tibber 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the Tibber dashboard, create API Token, then copy it.",
        "ja": "Tibber ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://tibber.com",
    "credentialSetupURL": "https://developer.tibber.com/docs/overview",
    "summary": {
      "zh": "北欧电力零售。按本月用电花费。",
      "en": "Nordic electricity retail. This month’s electricity spend.",
      "ja": "北欧の電力小売。今月の電気代です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "once",
    "name": "1NCE",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "物联网蜂窝（1NCE）低价长周期卡的强挑战者。",
    "searchKeywords": [
      "1nce",
      "once",
      "iot",
      "sim",
      "orders",
      "invoice_amount"
    ],
    "fields": [
      {
        "key": "clientSecret",
        "label": {
          "zh": "Client Secret",
          "en": "Client Secret",
          "ja": "Client Secret"
        },
        "isSecret": true
      },
      {
        "key": "clientID",
        "label": {
          "zh": "Client ID",
          "en": "Client ID",
          "ja": "Client ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台 API 凭证里的 ID",
          "en": "ID from API credentials in the dashboard",
          "ja": "ダッシュボードの API 認証情報の ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 1NCE 控制台 的 API 页面，创建 Client Secret，然后复制。",
        "en": "Open the API page in the 1NCE dashboard, create Client Secret, then copy it.",
        "ja": "1NCE ダッシュボード の API ページを開き、Client Secret を作成してコピーします。"
      },
      {
        "zh": "打开 1NCE 控制台 的 API 页面，创建 Client ID，然后复制。",
        "en": "Open the API page in the 1NCE dashboard, create Client ID, then copy it.",
        "ja": "1NCE ダッシュボード の API ページを開き、Client ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://portal.1nce.com",
    "credentialSetupURL": "https://help.1nce.com/api/order-management/",
    "summary": {
      "zh": "物联网蜂窝流量卡。按本月用量。",
      "en": "IoT cellular SIMs. This month’s usage.",
      "ja": "IoT セルラー SIM。今月の用量です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "octopusenergy",
    "name": "Octopus Energy",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "英国与多国电力零售的强挑战者，API 与智能电表渗透高。",
    "searchKeywords": [
      "octopus",
      "kraken",
      "costOfUsage",
      "EstimatedMoneyType",
      "electricity"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Account ID",
          "en": "Account ID",
          "ja": "Account ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台里的账户或组织 ID",
          "en": "Account or organization ID in the dashboard",
          "ja": "ダッシュボードのアカウントまたは組織 ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Octopus Energy 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Octopus Energy dashboard, create API Key, then copy it.",
        "ja": "Octopus Energy ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      },
      {
        "zh": "打开 Octopus Energy 控制台 的 API 页面，创建 Account ID，然后复制。",
        "en": "Open the API page in the Octopus Energy dashboard, create Account ID, then copy it.",
        "ja": "Octopus Energy ダッシュボード の API ページを開き、Account ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://octopus.energy",
    "credentialSetupURL": "https://developer.octopus.energy/graphql/reference/objects/costofusageperiod/",
    "summary": {
      "zh": "英国电力零售。按周期用电花费。",
      "en": "UK electricity retail. Usage cost for the billing period.",
      "ja": "英国の電力小売。請求周期の電気代です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "pge",
    "name": "PG&E",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "加州电网公用事业的区域垄断运营商。",
    "searchKeywords": [
      "pge",
      "share my data",
      "green button",
      "espi",
      "billLastPeriod"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Account ID",
          "en": "Account ID",
          "ja": "Account ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台里的账户或组织 ID",
          "en": "Account or organization ID in the dashboard",
          "ja": "ダッシュボードのアカウントまたは組織 ID"
        }
      },
      {
        "key": "projectID",
        "label": {
          "zh": "Project ID",
          "en": "Project ID",
          "ja": "Project ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台里的项目 ID",
          "en": "Project ID in the dashboard",
          "ja": "ダッシュボードのプロジェクト ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 PG&E 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the PG&E dashboard, create API Token, then copy it.",
        "ja": "PG&E ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      },
      {
        "zh": "打开 PG&E 控制台 的 API 页面，创建 Account ID 和 Project ID，然后复制。",
        "en": "Open the API page in the PG&E dashboard, create Account ID and Project ID, then copy them.",
        "ja": "PG&E ダッシュボード の API ページを開き、Account ID と Project ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.pge.com",
    "credentialSetupURL": "https://www.pge.com/assets/pge/docs/save-energy-and-money/energy-savings-programs/Supported-Data-Elements.pdf",
    "summary": {
      "zh": "加州电力账单。按上一期账单金额。",
      "en": "California electricity. The last billed period’s amount.",
      "ja": "カリフォルニアの電気代。直前の請求額です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "coned",
    "name": "Con Edison",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "纽约都会区电力公用事业的区域垄断运营商。",
    "searchKeywords": [
      "coned",
      "con edison",
      "oru",
      "share my data",
      "green button",
      "billLastPeriod",
      "espi"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Account ID",
          "en": "Account ID",
          "ja": "Account ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台里的账户或组织 ID",
          "en": "Account or organization ID in the dashboard",
          "ja": "ダッシュボードのアカウントまたは組織 ID"
        }
      },
      {
        "key": "projectID",
        "label": {
          "zh": "Project ID",
          "en": "Project ID",
          "ja": "Project ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台里的项目 ID",
          "en": "Project ID in the dashboard",
          "ja": "ダッシュボードのプロジェクト ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Con Edison 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the Con Edison dashboard, create API Token, then copy it.",
        "ja": "Con Edison ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      },
      {
        "zh": "打开 Con Edison 控制台 的 API 页面，创建 Account ID 和 Project ID，然后复制。",
        "en": "Open the API page in the Con Edison dashboard, create Account ID and Project ID, then copy them.",
        "ja": "Con Edison ダッシュボード の API ページを開き、Account ID と Project ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.coned.com",
    "credentialSetupURL": "https://www.coned.com/-/media/files/coned/documents/accountandbilling/share-my-data/onboarding-doc.pdf",
    "summary": {
      "zh": "纽约电力账单。按上一期账单金额。",
      "en": "New York electricity. The last billed period’s amount.",
      "ja": "ニューヨークの電気代。直前の請求額です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "dynatrace",
    "name": "Dynatrace",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "企业 APM/可观测性的寡头之一，与 Datadog 等并列。",
    "searchKeywords": [
      "dynatrace",
      "dps",
      "platform subscription",
      "account-uac-read",
      "currencyCode"
    ],
    "fields": [
      {
        "key": "clientSecret",
        "label": {
          "zh": "Client Secret",
          "en": "Client Secret",
          "ja": "Client Secret"
        },
        "isSecret": true
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Account ID",
          "en": "Account ID",
          "ja": "Account ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台里的账户或组织 ID",
          "en": "Account or organization ID in the dashboard",
          "ja": "ダッシュボードのアカウントまたは組織 ID"
        }
      },
      {
        "key": "projectID",
        "label": {
          "zh": "Project ID",
          "en": "Project ID",
          "ja": "Project ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台里的项目 ID",
          "en": "Project ID in the dashboard",
          "ja": "ダッシュボードのプロジェクト ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Dynatrace 控制台 的 API 页面，创建 Client Secret，然后复制。",
        "en": "Open the API page in the Dynatrace dashboard, create Client Secret, then copy it.",
        "ja": "Dynatrace ダッシュボード の API ページを開き、Client Secret を作成してコピーします。"
      },
      {
        "zh": "打开 Dynatrace 控制台 的 API 页面，创建 Account ID 和 Project ID，然后复制。",
        "en": "Open the API page in the Dynatrace dashboard, create Account ID and Project ID, then copy them.",
        "ja": "Dynatrace ダッシュボード の API ページを開き、Account ID と Project ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://myaccount.dynatrace.com",
    "credentialSetupURL": "https://docs.dynatrace.com/docs/dynatrace-api/account-management-api/dynatrace-platform-subscription-api/cost/get-cost",
    "summary": {
      "zh": "企业 APM 和可观测性。按订阅成本。",
      "en": "Enterprise APM and observability. Subscription cost.",
      "ja": "企業向け APM と可観測性。サブスクリプションコストです。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "zoom",
    "name": "Zoom",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "视频会议企业支出的寡头核心。",
    "searchKeywords": [
      "zoom",
      "billing invoices",
      "total_amount",
      "pro"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Zoom 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the Zoom dashboard, create API Token, then copy it.",
        "ja": "Zoom ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://zoom.us/billing",
    "credentialSetupURL": "https://developers.zoom.us/docs/api/billing/ma/",
    "summary": {
      "zh": "视频会议。按本月发票合计。",
      "en": "Video meetings. This month’s invoices, summed.",
      "ja": "ビデオ会議。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "namecom",
    "name": "Name.com",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "域名注册中小型选手，份额小于 GoDaddy/Namecheap。",
    "searchKeywords": [
      "name.com",
      "namecom",
      "finalAmount",
      "orders"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Account ID",
          "en": "Account ID",
          "ja": "Account ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台里的账户或组织 ID",
          "en": "Account or organization ID in the dashboard",
          "ja": "ダッシュボードのアカウントまたは組織 ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Name.com 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the Name.com dashboard, create API Token, then copy it.",
        "ja": "Name.com ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      },
      {
        "zh": "打开 Name.com 控制台 的 API 页面，创建 Account ID，然后复制。",
        "en": "Open the API page in the Name.com dashboard, create Account ID, then copy it.",
        "ja": "Name.com ダッシュボード の API ページを開き、Account ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.name.com",
    "credentialSetupURL": "https://docs.name.com/api/v1/reference/orders/get-order",
    "summary": {
      "zh": "美国域名注册。按本月订单合计。",
      "en": "US domain registration. This month’s orders, summed.",
      "ja": "米国のドメイン登録。今月の注文合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "ovhcloud",
    "name": "OVHcloud",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "欧洲公有云/裸金属的强挑战者，主权云叙事清晰。",
    "searchKeywords": [
      "ovh",
      "ovhcloud",
      "priceWithTax",
      "me/bill"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      },
      {
        "key": "clientSecret",
        "label": {
          "zh": "Client Secret",
          "en": "Client Secret",
          "ja": "Client Secret"
        },
        "isSecret": true
      },
      {
        "key": "accessKeyID",
        "label": {
          "zh": "Access Key ID",
          "en": "Access Key ID",
          "ja": "Access Key ID"
        },
        "isSecret": false
      }
    ],
    "steps": [
      {
        "zh": "打开 OVHcloud 控制台 的 API 页面，创建 API Token 和 Client Secret，然后复制。",
        "en": "Open the API page in the OVHcloud dashboard, create API Token and Client Secret, then copy them.",
        "ja": "OVHcloud ダッシュボード の API ページを開き、API Token と Client Secret を作成してコピーします。"
      },
      {
        "zh": "打开 OVHcloud 控制台 的 API 页面，创建 Access Key ID，然后复制。",
        "en": "Open the API page in the OVHcloud dashboard, create Access Key ID, then copy it.",
        "ja": "OVHcloud ダッシュボード の API ページを開き、Access Key ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.ovhcloud.com",
    "credentialSetupURL": "https://api.ovh.com/console/#/me/bill~GET",
    "summary": {
      "zh": "欧洲公有云和裸金属。按本月发票合计，含税。",
      "en": "European public cloud and bare metal. This month’s invoices, tax included.",
      "ja": "欧州のパブリッククラウドとベアメタル。今月のインボイス合計（税込）です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "sakuracloud",
    "name": "Sakura Cloud",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "日本本地云的强挑战者，中小企业渗透高。",
    "searchKeywords": [
      "sakura",
      "さくら",
      "bill/by-contract",
      "JPY"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      },
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Account ID",
          "en": "Account ID",
          "ja": "Account ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台里的账户或组织 ID",
          "en": "Account or organization ID in the dashboard",
          "ja": "ダッシュボードのアカウントまたは組織 ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Sakura Cloud 控制台 的 API 页面，创建 API Token 和 API Key，然后复制。",
        "en": "Open the API page in the Sakura Cloud dashboard, create API Token and API Key, then copy them.",
        "ja": "Sakura Cloud ダッシュボード の API ページを開き、API Token と API Key を作成してコピーします。"
      },
      {
        "zh": "打开 Sakura Cloud 控制台 的 API 页面，创建 Account ID，然后复制。",
        "en": "Open the API page in the Sakura Cloud dashboard, create Account ID, then copy it.",
        "ja": "Sakura Cloud ダッシュボード の API ページを開き、Account ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://secure.sakura.ad.jp",
    "credentialSetupURL": "https://manual.sakura.ad.jp/cloud/api/billapi.html",
    "summary": {
      "zh": "日本本地云。按本月发票合计，日元会折成美元。",
      "en": "Japanese local cloud. This month’s invoices, summed. Yen convert to USD.",
      "ja": "日本のローカルクラウド。今月のインボイス合計で、円はドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "akamai",
    "name": "Akamai",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "企业 CDN/边缘安全的寡头之一，份额长期稳固。",
    "searchKeywords": [
      "akamai",
      "invoicing-api",
      "invoiceTotal",
      "EdgeGrid"
    ],
    "fields": [
      {
        "key": "secretAccessKey",
        "label": {
          "zh": "Secret Access Key",
          "en": "Secret Access Key",
          "ja": "Secret Access Key"
        },
        "isSecret": true
      },
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      },
      {
        "key": "accessKeyID",
        "label": {
          "zh": "Access Key ID",
          "en": "Access Key ID",
          "ja": "Access Key ID"
        },
        "isSecret": false
      }
    ],
    "steps": [
      {
        "zh": "打开 Akamai 控制台 的 API 页面，创建 Secret Access Key 和 API Token，然后复制。",
        "en": "Open the API page in the Akamai dashboard, create Secret Access Key and API Token, then copy them.",
        "ja": "Akamai ダッシュボード の API ページを開き、Secret Access Key と API Token を作成してコピーします。"
      },
      {
        "zh": "打开 Akamai 控制台 的 API 页面，创建 Access Key ID，然后复制。",
        "en": "Open the API page in the Akamai dashboard, create Access Key ID, then copy it.",
        "ja": "Akamai ダッシュボード の API ページを開き、Access Key ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://control.akamai.com",
    "credentialSetupURL": "https://techdocs.akamai.com/invoicing",
    "summary": {
      "zh": "企业 CDN 和边缘安全。按本月发票合计。",
      "en": "Enterprise CDN and edge security. This month’s invoices, summed.",
      "ja": "企業向け CDN とエッジセキュリティ。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "hostens",
    "name": "Hostens",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "东欧/北欧区域 VPS 主机市场的中小型选手，体量远小于 OVH、Hetzner。",
    "searchKeywords": [
      "hostens",
      "invoice",
      "acc_balance",
      "vps"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Hostens 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Hostens dashboard, create API Key, then copy it.",
        "ja": "Hostens ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://billing.hostens.com",
    "credentialSetupURL": "https://billing.hostens.com/userapi",
    "summary": {
      "zh": "东欧 VPS。按本月发票合计。",
      "en": "Eastern-European VPS. This month’s invoices, summed.",
      "ja": "東欧の VPS。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "binarylane",
    "name": "BinaryLane",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "澳大利亚本地 VPS 主机的区域选手，规模小于亚太主流公有云。",
    "searchKeywords": [
      "binarylane",
      "binary lane",
      "unbilled_total",
      "AUD",
      "australia"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 BinaryLane 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the BinaryLane dashboard, create API Token, then copy it.",
        "ja": "BinaryLane ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.binarylane.com.au",
    "credentialSetupURL": "https://api.binarylane.com.au/reference/",
    "summary": {
      "zh": "澳大利亚 VPS。按本月发票合计。",
      "en": "Australian VPS. This month’s invoices, summed.",
      "ja": "オーストラリアの VPS。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "tierpoint",
    "name": "TierPoint Metallic",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "美国托管与 Metallic 消费云细分里的中型玩家，不及超大规模云。",
    "searchKeywords": [
      "tierpoint",
      "metallic",
      "usageReport",
      "consumption",
      "mrr"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 TierPoint Metallic 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the TierPoint Metallic dashboard, create API Token, then copy it.",
        "ja": "TierPoint Metallic ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.tierpoint.com",
    "credentialSetupURL": "https://api.tierpoint.com/api/v1/usage/v3/api-docs",
    "summary": {
      "zh": "美国托管和 Metallic 消费云。按本月发票合计。",
      "en": "US colocation and Metallic consumption cloud. This month’s invoices, summed.",
      "ja": "米国のコロケーションと Metallic 消費クラウド。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "postman",
    "name": "Postman",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "API 开发协作与测试平台近乎事实标准，份额远超同类工具。",
    "searchKeywords": [
      "postman",
      "invoices",
      "totalAmount",
      "x-api-key"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Postman 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Postman dashboard, create API Key, then copy it.",
        "ja": "Postman ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://go.postman.co/billing",
    "credentialSetupURL": "https://learning.postman.com/docs/developer/postman-api/authentication/",
    "summary": {
      "zh": "API 开发和测试。按已付发票合计。",
      "en": "API development and testing. Paid invoices, summed.",
      "ja": "API 開発とテスト。支払い済みインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "sevenbridges",
    "name": "Seven Bridges",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "基因组学生物信息云平台的强挑战者，细分赛道里位居前列。",
    "searchKeywords": [
      "seven bridges",
      "sbgenomics",
      "cavatica",
      "billing invoices"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Seven Bridges 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the Seven Bridges dashboard, create API Token, then copy it.",
        "ja": "Seven Bridges ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://igor.sbgenomics.com",
    "credentialSetupURL": "https://docs.sevenbridges.com/reference/list-invoices",
    "summary": {
      "zh": "基因组学分析云。按本月用量。",
      "en": "Genomics analysis cloud. This month’s usage.",
      "ja": "ゲノム解析クラウド。今月の用量です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "cmcom",
    "name": "CM.com",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 1,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "欧洲 CPaaS/消息市场的强挑战者，与 Twilio 等同台。",
    "searchKeywords": [
      "cm.com",
      "cmcom",
      "transactions",
      "producttoken",
      "sms"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 CM.com 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the CM.com dashboard, create API Key, then copy it.",
        "ja": "CM.com ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.cm.com",
    "credentialSetupURL": "https://developers.cm.com/messaging/docs/transactions-api",
    "summary": {
      "zh": "欧洲短信和 CPaaS。按本月用量。",
      "en": "European SMS and CPaaS. This month’s usage.",
      "ja": "欧州の SMS と CPaaS。今月の用量です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "shipbob",
    "name": "ShipBob",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "美国电商履约/仓储物流（3PL）的强挑战者，与大型履约网络并列短名单。",
    "searchKeywords": [
      "shipbob",
      "ship bob",
      "fulfillment",
      "wms",
      "invoices",
      "billing_read"
    ],
    "fields": [
      {
        "key": "personalAccessToken",
        "label": {
          "zh": "Personal Access Token",
          "en": "Personal Access Token",
          "ja": "Personal Access Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 ShipBob 控制台 的 API 页面，创建 Personal Access Token，然后复制。",
        "en": "Open the API page in the ShipBob dashboard, create Personal Access Token, then copy it.",
        "ja": "ShipBob ダッシュボード の API ページを開き、Personal Access Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://web.shipbob.com",
    "credentialSetupURL": "https://developer.shipbob.com/guides/billing",
    "summary": {
      "zh": "电商仓储履约。按本月发票合计。",
      "en": "Ecommerce warehousing and fulfillment. This month’s invoices, summed.",
      "ja": "EC の倉庫フルフィルメント。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "mikrocloud",
    "name": "MikroCloud",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "MikroTik 设备云管平台的细分选手，体量小于主流网络/物联网云。",
    "searchKeywords": [
      "mikrocloud",
      "mikrotik",
      "invoice",
      "account invoices"
    ],
    "fields": [
      {
        "key": "personalAccessToken",
        "label": {
          "zh": "Personal Access Token",
          "en": "Personal Access Token",
          "ja": "Personal Access Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 MikroCloud 控制台 的 API 页面，创建 Personal Access Token，然后复制。",
        "en": "Open the API page in the MikroCloud dashboard, create Personal Access Token, then copy it.",
        "ja": "MikroCloud ダッシュボード の API ページを開き、Personal Access Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://mikrocloud.com",
    "credentialSetupURL": "https://docs.mikrocloud.com/api/accounts/invoices",
    "summary": {
      "zh": "MikroTik 设备云管。按本月用量。",
      "en": "MikroTik device cloud management. This month’s usage.",
      "ja": "MikroTik 機器のクラウド管理。今月の用量です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "leaseweb",
    "name": "Leaseweb",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "全球裸金属/托管主机的强挑战者，欧洲与北美机房网络成熟。",
    "searchKeywords": [
      "leaseweb",
      "invoice",
      "X-LSW-Auth",
      "bare metal"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Leaseweb 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Leaseweb dashboard, create API Key, then copy it.",
        "ja": "Leaseweb ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://secure.leaseweb.com",
    "credentialSetupURL": "https://developer.leaseweb.com/api-docs/invoice_v1.html",
    "summary": {
      "zh": "全球裸金属和托管。按本月发票合计。",
      "en": "Global bare metal and colocation. This month’s invoices, summed.",
      "ja": "グローバルのベアメタルとコロケーション。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "qovery",
    "name": "Qovery",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "Kubernetes 部署/开发环境 PaaS 的细分选手，体量小于 Railway/Render 主流替代短名单。",
    "searchKeywords": [
      "qovery",
      "invoice",
      "organization invoice",
      "kubernetes"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Account ID",
          "en": "Account ID",
          "ja": "Account ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台里的账户或组织 ID",
          "en": "Account or organization ID in the dashboard",
          "ja": "ダッシュボードのアカウントまたは組織 ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Qovery 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the Qovery dashboard, create API Token, then copy it.",
        "ja": "Qovery ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      },
      {
        "zh": "打开 Qovery 控制台 的 API 页面，创建 Account ID，然后复制。",
        "en": "Open the API page in the Qovery dashboard, create Account ID, then copy it.",
        "ja": "Qovery ダッシュボード の API ページを開き、Account ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://console.qovery.com",
    "credentialSetupURL": "https://www.qovery.com/docs/api-reference/openapi.yaml",
    "summary": {
      "zh": "Kubernetes 开发环境。按本月用量。",
      "en": "Kubernetes development environments. This month’s usage.",
      "ja": "Kubernetes の開発環境。今月の用量です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "phoenixnap",
    "name": "phoenixNAP",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "全球裸金属/边缘机房的强挑战者，欧美机房网络成熟。",
    "searchKeywords": [
      "phoenixnap",
      "phoenix nap",
      "bmc",
      "invoices",
      "bare metal"
    ],
    "fields": [
      {
        "key": "clientSecret",
        "label": {
          "zh": "Client Secret",
          "en": "Client Secret",
          "ja": "Client Secret"
        },
        "isSecret": true
      },
      {
        "key": "clientID",
        "label": {
          "zh": "Client ID",
          "en": "Client ID",
          "ja": "Client ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台 API 凭证里的 ID",
          "en": "ID from API credentials in the dashboard",
          "ja": "ダッシュボードの API 認証情報の ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 phoenixNAP 控制台 的 API 页面，创建 Client Secret，然后复制。",
        "en": "Open the API page in the phoenixNAP dashboard, create Client Secret, then copy it.",
        "ja": "phoenixNAP ダッシュボード の API ページを開き、Client Secret を作成してコピーします。"
      },
      {
        "zh": "打开 phoenixNAP 控制台 的 API 页面，创建 Client ID，然后复制。",
        "en": "Open the API page in the phoenixNAP dashboard, create Client ID, then copy it.",
        "ja": "phoenixNAP ダッシュボード の API ページを開き、Client ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://bmc.phoenixnap.com",
    "credentialSetupURL": "https://developers.phoenixnap.com/docs/invoicing/1/overview",
    "summary": {
      "zh": "裸金属和边缘机房。按本月发票合计。",
      "en": "Bare metal and edge datacenters. This month’s invoices, summed.",
      "ja": "ベアメタルとエッジデータセンター。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "magalucloud",
    "name": "Magalu Cloud",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "巴西本土公有云的强挑战者，拉美市场渗透高于多数国际云。",
    "searchKeywords": [
      "magalu",
      "magalu cloud",
      "magazine luiza",
      "FOCUS",
      "BilledCost",
      "BRL"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Magalu Cloud 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Magalu Cloud dashboard, create API Key, then copy it.",
        "ja": "Magalu Cloud ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://console.magalu.cloud",
    "credentialSetupURL": "https://docs.magalu.cloud/api/consumption",
    "summary": {
      "zh": "巴西公有云。按本月用量。",
      "en": "Brazilian public cloud. This month’s usage.",
      "ja": "ブラジルのパブリッククラウド。今月の用量です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "transip",
    "name": "TransIP",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "荷兰域名/VPS 区域主机的细分选手，体量小于全球裸金属短名单。",
    "searchKeywords": [
      "transip",
      "invoice",
      "totalAmount",
      "EUR",
      "vps",
      "domain"
    ],
    "fields": [
      {
        "key": "personalAccessToken",
        "label": {
          "zh": "Personal Access Token",
          "en": "Personal Access Token",
          "ja": "Personal Access Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 TransIP 控制台 的 API 页面，创建 Personal Access Token，然后复制。",
        "en": "Open the API page in the TransIP dashboard, create Personal Access Token, then copy it.",
        "ja": "TransIP ダッシュボード の API ページを開き、Personal Access Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.transip.nl/cp/",
    "credentialSetupURL": "https://api.transip.nl/rest/docs.html#invoices",
    "summary": {
      "zh": "荷兰域名和 VPS。按本月发票合计。",
      "en": "Dutch domains and VPS. This month’s invoices, summed.",
      "ja": "オランダのドメインと VPS。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "serverscom",
    "name": "Servers.com",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "全球裸金属/托管主机的强挑战者，与 Leaseweb / phoenixNAP 并列短名单。",
    "searchKeywords": [
      "servers.com",
      "serverscom",
      "billing invoices",
      "total_due",
      "bare metal"
    ],
    "fields": [
      {
        "key": "personalAccessToken",
        "label": {
          "zh": "Personal Access Token",
          "en": "Personal Access Token",
          "ja": "Personal Access Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Servers.com 控制台 的 API 页面，创建 Personal Access Token，然后复制。",
        "en": "Open the API page in the Servers.com dashboard, create Personal Access Token, then copy it.",
        "ja": "Servers.com ダッシュボード の API ページを開き、Personal Access Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://portal.servers.com/",
    "credentialSetupURL": "https://www.servers.com/docs/api-reference/invoice/list-invoices/",
    "summary": {
      "zh": "全球裸金属。按本月发票合计。",
      "en": "Global bare metal. This month’s invoices, summed.",
      "ja": "グローバルのベアメタル。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "flexport",
    "name": "Flexport",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "全球货运代理/供应链平台的强挑战者，跨境物流数字化短名单。",
    "searchKeywords": [
      "flexport",
      "freight",
      "invoices",
      "currency_code",
      "logistics"
    ],
    "fields": [
      {
        "key": "personalAccessToken",
        "label": {
          "zh": "Personal Access Token",
          "en": "Personal Access Token",
          "ja": "Personal Access Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Flexport 控制台 的 API 页面，创建 Personal Access Token，然后复制。",
        "en": "Open the API page in the Flexport dashboard, create Personal Access Token, then copy it.",
        "ja": "Flexport ダッシュボード の API ページを開き、Personal Access Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://app.flexport.com/",
    "credentialSetupURL": "https://developers.flexport.com/tutorials/freight-invoices-api-tutorial/",
    "summary": {
      "zh": "跨境货运代理。按本月发票合计。",
      "en": "Cross-border freight forwarding. This month’s invoices, summed.",
      "ja": "越境フォワーディング。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "i3dnet",
    "name": "i3D.net",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "荷兰游戏/裸金属主机的细分选手，与 TransIP 同属荷兰区域主机短名单。",
    "searchKeywords": [
      "i3d",
      "i3dnet",
      "invoice",
      "amountIncVAT",
      "PRIVATE-TOKEN",
      "netherlands"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 i3D.net 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the i3D.net dashboard, create API Key, then copy it.",
        "ja": "i3D.net ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.i3d.net/",
    "credentialSetupURL": "https://docs.i3d.net/api-references/general/billing.md",
    "summary": {
      "zh": "荷兰游戏和裸金属。按本月发票合计。",
      "en": "Dutch game hosting and bare metal. This month’s invoices, summed.",
      "ja": "オランダのゲームホスティングとベアメタル。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "datapacket",
    "name": "DataPacket",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "欧洲专用服务器/高带宽托管的强挑战者，与 Leaseweb / Servers.com 并列短名单。",
    "searchKeywords": [
      "datapacket",
      "graphql",
      "invoices",
      "dedicated",
      "bare metal"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 DataPacket 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the DataPacket dashboard, create API Key, then copy it.",
        "ja": "DataPacket ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.datapacket.com/",
    "credentialSetupURL": "https://api.datapacket.com/",
    "summary": {
      "zh": "欧洲高带宽独立服务器。按本月发票合计。",
      "en": "European high-bandwidth dedicated servers. This month’s invoices, summed.",
      "ja": "欧州の高帯域専用サーバ。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "cudocompute",
    "name": "CUDO Compute",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "分布式 GPU 云的细分选手，体量小于 RunPod / Vast.ai 主流短名单。",
    "searchKeywords": [
      "cudo",
      "cudocompute",
      "gpu",
      "invoices",
      "billing account"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Account ID",
          "en": "Account ID",
          "ja": "Account ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台里的账户或组织 ID",
          "en": "Account or organization ID in the dashboard",
          "ja": "ダッシュボードのアカウントまたは組織 ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 CUDO Compute 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the CUDO Compute dashboard, create API Key, then copy it.",
        "ja": "CUDO Compute ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      },
      {
        "zh": "打开 CUDO Compute 控制台 的 API 页面，创建 Account ID，然后复制。",
        "en": "Open the API page in the CUDO Compute dashboard, create Account ID, then copy it.",
        "ja": "CUDO Compute ダッシュボード の API ページを開き、Account ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.cudocompute.com/",
    "credentialSetupURL": "https://docs.cudocompute.com/api/billing/list-invoices",
    "summary": {
      "zh": "分布式 GPU 云。按本月用量。",
      "en": "Distributed GPU cloud. This month’s usage.",
      "ja": "分散 GPU クラウド。今月の用量です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "shipwell",
    "name": "Shipwell",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "北美货运 TMS/结算平台的强挑战者，与 Flexport 并列物流数字化短名单。",
    "searchKeywords": [
      "shipwell",
      "freight-invoices",
      "TMS",
      "logistics",
      "settlements"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Shipwell 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Shipwell dashboard, create API Key, then copy it.",
        "ja": "Shipwell ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://shipwell.com/",
    "credentialSetupURL": "https://docs.shipwell.com/openapi_pages/settlements/operation/list_freight_invoices/",
    "summary": {
      "zh": "北美货运 TMS。按本月发票合计。",
      "en": "North-American freight TMS. This month’s invoices, summed.",
      "ja": "北米の貨物 TMS。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "ocamba",
    "name": "Ocamba",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "互动推送/广告变现平台的细分选手，账单 API 清晰但体量小于 Klaviyo 等主流营销云。",
    "searchKeywords": [
      "ocamba",
      "push",
      "invoices",
      "currency_code",
      "engagement"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Ocamba 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Ocamba dashboard, create API Key, then copy it.",
        "ja": "Ocamba ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://docs.ocamba.com/",
    "credentialSetupURL": "https://docs.ocamba.com/api/core/v2.0/reference/view-invoices/",
    "summary": {
      "zh": "互动推送和广告变现。按本月用量。",
      "en": "Interactive push and ad monetization. This month’s usage.",
      "ja": "インタラクティブプッシュと広告マネタイズ。今月の用量です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "inferencesh",
    "name": "inference.sh",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 1,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "推理/应用市场用量计费的细分选手，体量小于 OpenRouter / Fireworks 主流短名单。",
    "searchKeywords": [
      "inference.sh",
      "inferencesh",
      "usage",
      "microcents",
      "breakdown"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 inference.sh 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the inference.sh dashboard, create API Key, then copy it.",
        "ja": "inference.sh ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://inference.sh/",
    "credentialSetupURL": "https://inference.sh/docs/api/rest/usage",
    "summary": {
      "zh": "推理应用市场。按本月用量。",
      "en": "An inference app marketplace. This month’s usage.",
      "ja": "推論アプリのマーケット。今月の用量です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "voltview",
    "name": "VoltView",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "英国多站点能源发票聚合的细分选手，体量小于 Octopus / Tibber 消费级能源 API。",
    "searchKeywords": [
      "voltview",
      "energy",
      "invoices",
      "GBP",
      "UK"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 VoltView 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the VoltView dashboard, create API Key, then copy it.",
        "ja": "VoltView ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://docs.voltview.co.uk/",
    "credentialSetupURL": "https://docs.voltview.co.uk/api-reference/sites/invoices-for-all-sites",
    "summary": {
      "zh": "英国多站点能源发票。按本月发票合计。",
      "en": "UK multi-site energy invoices. This month’s invoices, summed.",
      "ja": "英国の複数拠点エネルギー請求。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "clevercloud",
    "name": "Clever Cloud",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "法国 PaaS/欧洲主权云的细分选手，体量小于 Scaleway / OVHcloud 主流短名单。",
    "searchKeywords": [
      "clever cloud",
      "clevercloud",
      "invoices",
      "EUR",
      "PaaS"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Account ID",
          "en": "Account ID",
          "ja": "Account ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台里的账户或组织 ID",
          "en": "Account or organization ID in the dashboard",
          "ja": "ダッシュボードのアカウントまたは組織 ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Clever Cloud 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the Clever Cloud dashboard, create API Token, then copy it.",
        "ja": "Clever Cloud ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      },
      {
        "zh": "打开 Clever Cloud 控制台 的 API 页面，创建 Account ID，然后复制。",
        "en": "Open the API page in the Clever Cloud dashboard, create Account ID, then copy it.",
        "ja": "Clever Cloud ダッシュボード の API ページを開き、Account ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://console.clever-cloud.com/",
    "credentialSetupURL": "https://www.clever.cloud/developers/api/v4/",
    "summary": {
      "zh": "法国 PaaS。按本月用量。",
      "en": "French PaaS. This month’s usage.",
      "ja": "フランスの PaaS。今月の用量です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "utilityapi",
    "name": "UtilityAPI",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "美国公用事业账单聚合的细分选手，与 VoltView 同属能源账单 API 短名单。",
    "searchKeywords": [
      "utilityapi",
      "utility",
      "bills",
      "bill_total_cost",
      "energy"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 UtilityAPI 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the UtilityAPI dashboard, create API Token, then copy it.",
        "ja": "UtilityAPI ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://utilityapi.com/",
    "credentialSetupURL": "https://utilityapi.com/docs/api/bills",
    "summary": {
      "zh": "美国公用事业账单聚合。按本月账单合计。",
      "en": "US utility-bill aggregation. This month’s bills, summed.",
      "ja": "米国の公共料金請求の集約。今月の請求合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "dnsimple",
    "name": "DNSimple",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "开发者向 DNS/域名托管的细分选手，体量小于 Cloudflare Registrar / Route 53 主流短名单。",
    "searchKeywords": [
      "dnsimple",
      "dns",
      "billing charges",
      "USD",
      "domains"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Account ID",
          "en": "Account ID",
          "ja": "Account ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台里的账户或组织 ID",
          "en": "Account or organization ID in the dashboard",
          "ja": "ダッシュボードのアカウントまたは組織 ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 DNSimple 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the DNSimple dashboard, create API Token, then copy it.",
        "ja": "DNSimple ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      },
      {
        "zh": "打开 DNSimple 控制台 的 API 页面，创建 Account ID，然后复制。",
        "en": "Open the API page in the DNSimple dashboard, create Account ID, then copy it.",
        "ja": "DNSimple ダッシュボード の API ページを開き、Account ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://dnsimple.com/",
    "credentialSetupURL": "https://developer.dnsimple.com/v2/billing-charges/",
    "summary": {
      "zh": "开发者 DNS 和域名。按已收讫费用合计。",
      "en": "Developer DNS and domains. Collected charges, summed.",
      "ja": "開発者向け DNS とドメイン。回収済み課金の合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "latitudesh",
    "name": "Latitude.sh",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 1,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "全球按需裸金属的强挑战者，与 phoenixNAP / Servers.com 并列短名单。",
    "searchKeywords": [
      "latitude.sh",
      "latitudesh",
      "billing usage",
      "bare metal",
      "cents"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      },
      {
        "key": "projectID",
        "label": {
          "zh": "Project ID",
          "en": "Project ID",
          "ja": "Project ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台里的项目 ID",
          "en": "Project ID in the dashboard",
          "ja": "ダッシュボードのプロジェクト ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Latitude.sh 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Latitude.sh dashboard, create API Key, then copy it.",
        "ja": "Latitude.sh ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      },
      {
        "zh": "打开 Latitude.sh 控制台 的 API 页面，创建 Project ID，然后复制。",
        "en": "Open the API page in the Latitude.sh dashboard, create Project ID, then copy it.",
        "ja": "Latitude.sh ダッシュボード の API ページを開き、Project ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.latitude.sh/",
    "credentialSetupURL": "https://www.latitude.sh/docs/api-reference/get-billing-usage",
    "summary": {
      "zh": "按需裸金属。按本月用量。",
      "en": "On-demand bare metal. This month’s usage.",
      "ja": "オンデマンドベアメタル。今月の用量です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "alchemy",
    "name": "Alchemy",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 1,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "以太坊/多链节点与增强 API 的强挑战者，开发者 Web3 基建短名单。",
    "searchKeywords": [
      "alchemy",
      "web3",
      "usage summary",
      "USD",
      "CU"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Alchemy 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the Alchemy dashboard, create API Token, then copy it.",
        "ja": "Alchemy ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://dashboard.alchemy.com/",
    "credentialSetupURL": "https://www.alchemy.com/docs/admin-api/usage/get-usage-summary",
    "summary": {
      "zh": "以太坊和多链节点。按本月至今花费。",
      "en": "Ethereum and multi-chain nodes. Month-to-date spend.",
      "ja": "Ethereum とマルチチェーンノード。今月これまでの支出です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "friendli",
    "name": "FriendliAI",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "韩国推理/GPU 服务的细分选手，体量小于 Fireworks / Together 主流短名单。",
    "searchKeywords": [
      "friendli",
      "friendliai",
      "team cost",
      "USD",
      "GPU"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 FriendliAI 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the FriendliAI dashboard, create API Token, then copy it.",
        "ja": "FriendliAI ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://friendli.ai/",
    "credentialSetupURL": "https://friendli.ai/docs/openapi/administration/cost",
    "summary": {
      "zh": "韩国模型推理。按团队花费。",
      "en": "Korean model inference. Team spend.",
      "ja": "韓国のモデル推論。チーム支出です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "mixpeek",
    "name": "Mixpeek",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 1,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "多模态检索/抽取 API 的细分选手，体量小于主流向量与推理短名单。",
    "searchKeywords": [
      "mixpeek",
      "spending-caps",
      "current_spending_usd",
      "multimodal"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Mixpeek 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the Mixpeek dashboard, create API Token, then copy it.",
        "ja": "Mixpeek ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://mixpeek.com/",
    "credentialSetupURL": "https://docs.mixpeek.com/",
    "summary": {
      "zh": "多模态检索。按本月花费。",
      "en": "Multimodal retrieval. This month’s spend.",
      "ja": "マルチモーダル検索。今月の支出です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "typebot",
    "name": "Typebot",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "开源对话流/表单机器人的细分选手，订阅体量小于主流 bot 平台。",
    "searchKeywords": [
      "typebot",
      "invoices",
      "stripe subtotal",
      "workspaceId"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Account ID",
          "en": "Account ID",
          "ja": "Account ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台里的账户或组织 ID",
          "en": "Account or organization ID in the dashboard",
          "ja": "ダッシュボードのアカウントまたは組織 ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Typebot 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the Typebot dashboard, create API Token, then copy it.",
        "ja": "Typebot ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      },
      {
        "zh": "打开 Typebot 控制台 的 API 页面，创建 Account ID，然后复制。",
        "en": "Open the API page in the Typebot dashboard, create Account ID, then copy it.",
        "ja": "Typebot ダッシュボード の API ページを開き、Account ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://app.typebot.io/",
    "credentialSetupURL": "https://docs.typebot.com/api-reference/billing/list-invoices",
    "summary": {
      "zh": "开源对话表单。按本月发票合计。",
      "en": "Open-source conversational forms. This month’s invoices, summed.",
      "ja": "オープンソースの会話フォーム。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "botpress",
    "name": "Botpress",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 1,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "对话机器人与 Agent 平台的强挑战者，开发者 bot 基建短名单。",
    "searchKeywords": [
      "botpress",
      "upcoming-invoice",
      "totalInCents",
      "workspace"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Account ID",
          "en": "Account ID",
          "ja": "Account ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台里的账户或组织 ID",
          "en": "Account or organization ID in the dashboard",
          "ja": "ダッシュボードのアカウントまたは組織 ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Botpress 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the Botpress dashboard, create API Token, then copy it.",
        "ja": "Botpress ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      },
      {
        "zh": "打开 Botpress 控制台 的 API 页面，创建 Account ID，然后复制。",
        "en": "Open the API page in the Botpress dashboard, create Account ID, then copy it.",
        "ja": "Botpress ダッシュボード の API ページを開き、Account ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://botpress.com/",
    "credentialSetupURL": "https://www.botpress.com/docs/api-reference/admin-api/concepts/",
    "summary": {
      "zh": "对话机器人和 Agent。按即将出账的发票。",
      "en": "Chatbots and agents. The upcoming invoice.",
      "ja": "チャットボットとエージェント。これから出るインボイスです。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "seeweb",
    "name": "Seeweb",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "意大利云主机/GPU 的区域选手，体量小于西欧主流 IaaS 短名单。",
    "searchKeywords": [
      "seeweb",
      "ecs",
      "billing servers",
      "EUR",
      "X-APITOKEN"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Seeweb 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the Seeweb dashboard, create API Token, then copy it.",
        "ja": "Seeweb ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.seeweb.it/",
    "credentialSetupURL": "https://docs.seeweb.it/en/hosting/cloudserver/rest-api/API-Endpoints/Billing/",
    "summary": {
      "zh": "意大利云主机和 GPU。按本月服务器账单合计，欧元会折成美元。",
      "en": "Italian cloud hosts and GPUs. This month’s server bills, summed. Euros convert to USD.",
      "ja": "イタリアのクラウドホストと GPU。今月のサーバ請求合計で、ユーロはドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "parasail",
    "name": "Parasail",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "Serverless/Dedicated GPU 推理的细分选手，体量小于 Fireworks / Together 主流短名单。",
    "searchKeywords": [
      "parasail",
      "invoices",
      "current",
      "USD",
      "GPU"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Parasail 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the Parasail dashboard, create API Token, then copy it.",
        "ja": "Parasail ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.parasail.io/",
    "credentialSetupURL": "https://docs.parasail.io/parasail-docs/api-reference/billing-api",
    "summary": {
      "zh": "Serverless GPU 推理。按当期发票。",
      "en": "Serverless GPU inference. The current invoice.",
      "ja": "サーバーレス GPU 推論。当期のインボイスです。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "bring",
    "name": "Bring",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "北欧邮政/包裹物流的强挑战者，挪威与北欧电商物流短名单。",
    "searchKeywords": [
      "bring",
      "posten",
      "mybring",
      "invoice",
      "NOK",
      "customerNumber"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      },
      {
        "key": "email",
        "label": {
          "zh": "Email",
          "en": "Email",
          "ja": "Email"
        },
        "isSecret": false,
        "hint": {
          "zh": "登录邮箱",
          "en": "Sign-in email",
          "ja": "ログイン用メール"
        }
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Account ID",
          "en": "Account ID",
          "ja": "Account ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台里的账户或组织 ID",
          "en": "Account or organization ID in the dashboard",
          "ja": "ダッシュボードのアカウントまたは組織 ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Bring 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Bring dashboard, create API Key, then copy it.",
        "ja": "Bring ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      },
      {
        "zh": "打开 Bring 控制台 的 API 页面，创建 Email 和 Account ID，然后复制。",
        "en": "Open the API page in the Bring dashboard, create Email and Account ID, then copy them.",
        "ja": "Bring ダッシュボード の API ページを開き、Email と Account ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.mybring.com/",
    "credentialSetupURL": "https://developer.bring.com/api/invoice/",
    "summary": {
      "zh": "北欧邮政包裹。按本月发票合计，克朗会折成美元。",
      "en": "Nordic postal parcels. This month’s invoices, summed. Kroner convert to USD.",
      "ja": "北欧の郵便小包。今月のインボイス合計で、クローネはドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "armada",
    "name": "Armada Delivery",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "中东即时配送平台的细分选手，体量小于全球货运 TMS 短名单。",
    "searchKeywords": [
      "armada",
      "delivery",
      "REGULAR",
      "invoice",
      "HMAC",
      "KWD"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      },
      {
        "key": "clientSecret",
        "label": {
          "zh": "Client Secret",
          "en": "Client Secret",
          "ja": "Client Secret"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Armada Delivery 控制台 的 API 页面，创建 API Key 和 Client Secret，然后复制。",
        "en": "Open the API page in the Armada Delivery dashboard, create API Key and Client Secret, then copy them.",
        "ja": "Armada Delivery ダッシュボード の API ページを開き、API Key と Client Secret を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.armadadelivery.com/",
    "credentialSetupURL": "https://docs.armadadelivery.com/v2/invoices/",
    "summary": {
      "zh": "中东即时配送。按本月发票合计。",
      "en": "Middle-East on-demand delivery. This month’s invoices, summed.",
      "ja": "中東の即時配送。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "mollie",
    "name": "Mollie",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "欧洲支付收单的强挑战者，与 Stripe / Adyen 并列商户支付基建短名单。",
    "searchKeywords": [
      "mollie",
      "invoices",
      "grossAmount",
      "access token",
      "EUR"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Mollie 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the Mollie dashboard, create API Token, then copy it.",
        "ja": "Mollie ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://my.mollie.com/",
    "credentialSetupURL": "https://docs.mollie.com/reference/list-invoices",
    "summary": {
      "zh": "欧洲收款。这里记的是手续费，不是你的营收。",
      "en": "European payments. This records processing fees, not your revenue.",
      "ja": "欧州の決済。ここは手数料で、あなたの売上ではありません。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "checkout",
    "name": "Checkout.com",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "全球收单的强挑战者，与 Stripe / Mollie / Adyen 并列商户支付基建短名单。",
    "searchKeywords": [
      "checkout",
      "checkout.com",
      "statements",
      "processing_fees",
      "secret key"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Checkout.com 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Checkout.com dashboard, create API Key, then copy it.",
        "ja": "Checkout.com ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://dashboard.checkout.com/",
    "credentialSetupURL": "https://checkoutdocs.readme.io/docs/statements-endpoint",
    "summary": {
      "zh": "全球收单。这里记的是手续费，不是你的营收。",
      "en": "Global card acquiring. This records processing fees, not your revenue.",
      "ja": "グローバルアクワイアリング。ここは手数料で、あなたの売上ではありません。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "printify",
    "name": "Printify",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "按需印刷 POD 的强挑战者，与 Printful / Gelato 并列电商履约短名单。",
    "searchKeywords": [
      "printify",
      "POD",
      "orders",
      "cost",
      "shop_id",
      "cents"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Account ID",
          "en": "Account ID",
          "ja": "Account ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台里的账户或组织 ID",
          "en": "Account or organization ID in the dashboard",
          "ja": "ダッシュボードのアカウントまたは組織 ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Printify 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Printify dashboard, create API Key, then copy it.",
        "ja": "Printify ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      },
      {
        "zh": "打开 Printify 控制台 的 API 页面，创建 Account ID，然后复制。",
        "en": "Open the API page in the Printify dashboard, create Account ID, then copy it.",
        "ja": "Printify ダッシュボード の API ページを開き、Account ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://printify.com/",
    "credentialSetupURL": "https://developers.printify.com/",
    "summary": {
      "zh": "按需印刷货源网络。按本月订单成本合计。",
      "en": "A print-on-demand catalog. This month’s order costs, summed.",
      "ja": "オンデマンド印刷の仕入れ網。今月の注文コスト合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "teelaunch",
    "name": "teelaunch",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "北美 POD 履约的细分选手，体量小于 Printful / Printify 短名单。",
    "searchKeywords": [
      "teelaunch",
      "payment-history",
      "amount",
      "POD",
      "JWT"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 teelaunch 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the teelaunch dashboard, create API Token, then copy it.",
        "ja": "teelaunch ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://teelaunch.com/",
    "credentialSetupURL": "https://api.teelaunch.com/documentation",
    "summary": {
      "zh": "北美按需印刷。按付款记录合计。",
      "en": "North-American print-on-demand. Payment history, summed.",
      "ja": "北米のオンデマンド印刷。支払い履歴の合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "paypal",
    "name": "PayPal",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 1,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "全球收单与钱包的收入寡头，商户支付基建短名单核心。",
    "searchKeywords": [
      "paypal",
      "fee_amount",
      "reporting/transactions",
      "client credentials"
    ],
    "fields": [
      {
        "key": "clientSecret",
        "label": {
          "zh": "Client Secret",
          "en": "Client Secret",
          "ja": "Client Secret"
        },
        "isSecret": true
      },
      {
        "key": "clientID",
        "label": {
          "zh": "Client ID",
          "en": "Client ID",
          "ja": "Client ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台 API 凭证里的 ID",
          "en": "ID from API credentials in the dashboard",
          "ja": "ダッシュボードの API 認証情報の ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 PayPal 控制台 的 API 页面，创建 Client Secret，然后复制。",
        "en": "Open the API page in the PayPal dashboard, create Client Secret, then copy it.",
        "ja": "PayPal ダッシュボード の API ページを開き、Client Secret を作成してコピーします。"
      },
      {
        "zh": "打开 PayPal 控制台 的 API 页面，创建 Client ID，然后复制。",
        "en": "Open the API page in the PayPal dashboard, create Client ID, then copy it.",
        "ja": "PayPal ダッシュボード の API ページを開き、Client ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.paypal.com/",
    "credentialSetupURL": "https://developer.paypal.com/docs/api/transaction-search/v1/",
    "summary": {
      "zh": "收款和钱包。这里记的是手续费，不是你的营收。",
      "en": "Payments and a wallet. This records processing fees, not your revenue.",
      "ja": "決済とウォレット。ここは手数料で、あなたの売上ではありません。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "paystack",
    "name": "Paystack",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "非洲收单的强挑战者，与 Flutterwave 并列区域支付基建短名单。",
    "searchKeywords": [
      "paystack",
      "fees",
      "transaction",
      "NGN",
      "secret key"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Paystack 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Paystack dashboard, create API Key, then copy it.",
        "ja": "Paystack ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://dashboard.paystack.com/",
    "credentialSetupURL": "https://paystack.com/docs/api/transaction/#list",
    "summary": {
      "zh": "非洲收款。这里记的是手续费，不是你的营收。",
      "en": "African payments. This records processing fees, not your revenue.",
      "ja": "アフリカの決済。ここは手数料で、あなたの売上ではありません。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "flutterwave",
    "name": "Flutterwave",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "非洲收单的强挑战者，与 Paystack 并列区域支付基建短名单。",
    "searchKeywords": [
      "flutterwave",
      "app_fee",
      "transactions",
      "secret key"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Flutterwave 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Flutterwave dashboard, create API Key, then copy it.",
        "ja": "Flutterwave ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://dashboard.flutterwave.com/",
    "credentialSetupURL": "https://developer.flutterwave.com/docs/transaction-verification",
    "summary": {
      "zh": "非洲收单。这里记的是手续费，不是你的营收。",
      "en": "African card acquiring. This records processing fees, not your revenue.",
      "ja": "アフリカのアクワイアリング。ここは手数料で、あなたの売上ではありません。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "conoha",
    "name": "ConoHa",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "日本主机市场的挑战者，面向个人与中小团队。",
    "searchKeywords": [
      "conoha",
      "gmo",
      "billing-invoices",
      "bill_plas_tax",
      "tyo1",
      "日本"
    ],
    "fields": [
      {
        "key": "clientSecret",
        "label": {
          "zh": "Client Secret",
          "en": "Client Secret",
          "ja": "Client Secret"
        },
        "isSecret": true
      },
      {
        "key": "clientID",
        "label": {
          "zh": "Client ID",
          "en": "Client ID",
          "ja": "Client ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台 API 凭证里的 ID",
          "en": "ID from API credentials in the dashboard",
          "ja": "ダッシュボードの API 認証情報の ID"
        }
      },
      {
        "key": "tenantID",
        "label": {
          "zh": "Tenant ID",
          "en": "Tenant ID",
          "ja": "Tenant ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台里的租户或区域",
          "en": "Tenant or region in the dashboard",
          "ja": "ダッシュボードのテナントまたはリージョン"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 ConoHa 控制台 的 API 页面，创建 Client Secret，然后复制。",
        "en": "Open the API page in the ConoHa dashboard, create Client Secret, then copy it.",
        "ja": "ConoHa ダッシュボード の API ページを開き、Client Secret を作成してコピーします。"
      },
      {
        "zh": "打开 ConoHa 控制台 的 API 页面，创建 Client ID 和 Tenant ID，然后复制。",
        "en": "Open the API page in the ConoHa dashboard, create Client ID and Tenant ID, then copy them.",
        "ja": "ConoHa ダッシュボード の API ページを開き、Client ID と Tenant ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.conoha.jp/",
    "credentialSetupURL": "https://doc.conoha.jp/reference/api-vps2/api-account-vps2/account-billing-invoices-list-v2/",
    "summary": {
      "zh": "日本 VPS。按本月发票合计，日元会折成美元。",
      "en": "Japanese VPS. This month’s invoices, summed. Yen convert to USD.",
      "ja": "日本の VPS。今月のインボイス合計で、円はドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "zcomcloud",
    "name": "Z.com Cloud",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "GMO 国际云/VPS 品牌，日本与亚太主机市场的挑战者。",
    "searchKeywords": [
      "z.com",
      "zcom",
      "gmo",
      "billing-invoices",
      "bill_plas_tax",
      "tyo1"
    ],
    "fields": [
      {
        "key": "clientSecret",
        "label": {
          "zh": "Client Secret",
          "en": "Client Secret",
          "ja": "Client Secret"
        },
        "isSecret": true
      },
      {
        "key": "clientID",
        "label": {
          "zh": "Client ID",
          "en": "Client ID",
          "ja": "Client ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台 API 凭证里的 ID",
          "en": "ID from API credentials in the dashboard",
          "ja": "ダッシュボードの API 認証情報の ID"
        }
      },
      {
        "key": "tenantID",
        "label": {
          "zh": "Tenant ID",
          "en": "Tenant ID",
          "ja": "Tenant ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台里的租户或区域",
          "en": "Tenant or region in the dashboard",
          "ja": "ダッシュボードのテナントまたはリージョン"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Z.com Cloud 控制台 的 API 页面，创建 Client Secret，然后复制。",
        "en": "Open the API page in the Z.com Cloud dashboard, create Client Secret, then copy it.",
        "ja": "Z.com Cloud ダッシュボード の API ページを開き、Client Secret を作成してコピーします。"
      },
      {
        "zh": "打开 Z.com Cloud 控制台 的 API 页面，创建 Client ID 和 Tenant ID，然后复制。",
        "en": "Open the API page in the Z.com Cloud dashboard, create Client ID and Tenant ID, then copy them.",
        "ja": "Z.com Cloud ダッシュボード の API ページを開き、Client ID と Tenant ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://cloud.z.com/",
    "credentialSetupURL": "https://cloud.z.com/th/en/cloud/docs/account-billing-invoices-list.html",
    "summary": {
      "zh": "亚太 VPS。按本月发票合计。",
      "en": "Asia-Pacific VPS. This month’s invoices, summed.",
      "ja": "アジア太平洋の VPS。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "idcf",
    "name": "IDCF Cloud",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "日本主权云/IDC 的区域选手，面向国内企业，远小于 Hyperscaler。",
    "searchKeywords": [
      "idcf",
      "idc frontier",
      "billings",
      "your.idcfcloud.com",
      "JPY"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      },
      {
        "key": "clientSecret",
        "label": {
          "zh": "Client Secret",
          "en": "Client Secret",
          "ja": "Client Secret"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 IDCF Cloud 控制台 的 API 页面，创建 API Key 和 Client Secret，然后复制。",
        "en": "Open the API page in the IDCF Cloud dashboard, create API Key and Client Secret, then copy them.",
        "ja": "IDCF Cloud ダッシュボード の API ページを開き、API Key と Client Secret を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.idcf.jp/",
    "credentialSetupURL": "https://www.idcf.jp/help/cloud/docs/",
    "summary": {
      "zh": "日本企业云。按本月账单合计，日元会折成美元。",
      "en": "Japanese enterprise cloud. This month’s bills, summed. Yen convert to USD.",
      "ja": "日本の企業クラウド。今月の請求合計で、円はドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "internetx",
    "name": "InterNetX",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "欧洲域名注册/AutoDNS 细分里的德国选手。",
    "searchKeywords": [
      "internetx",
      "autodns",
      "invoice",
      "domainrobot",
      "EUR"
    ],
    "fields": [
      {
        "key": "clientSecret",
        "label": {
          "zh": "Client Secret",
          "en": "Client Secret",
          "ja": "Client Secret"
        },
        "isSecret": true
      },
      {
        "key": "clientID",
        "label": {
          "zh": "Client ID",
          "en": "Client ID",
          "ja": "Client ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台 API 凭证里的 ID",
          "en": "ID from API credentials in the dashboard",
          "ja": "ダッシュボードの API 認証情報の ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 InterNetX 控制台 的 API 页面，创建 Client Secret，然后复制。",
        "en": "Open the API page in the InterNetX dashboard, create Client Secret, then copy it.",
        "ja": "InterNetX ダッシュボード の API ページを開き、Client Secret を作成してコピーします。"
      },
      {
        "zh": "打开 InterNetX 控制台 的 API 页面，创建 Client ID，然后复制。",
        "en": "Open the API page in the InterNetX dashboard, create Client ID, then copy it.",
        "ja": "InterNetX ダッシュボード の API ページを開き、Client ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.internetx.com/",
    "credentialSetupURL": "https://help.internetx.com/display/APIXMLEN/Invoice+list",
    "summary": {
      "zh": "德国域名和 AutoDNS。按本月发票合计，欧元会折成美元。",
      "en": "German domains and AutoDNS. This month’s invoices, summed. Euros convert to USD.",
      "ja": "ドイツのドメインと AutoDNS。今月のインボイス合計で、ユーロはドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "melbicom",
    "name": "Melbicom",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "欧洲独立服务器与 CDN 的区域选手，体量小于西欧主流 IaaS。",
    "searchKeywords": [
      "melbicom",
      "billing/invoices",
      "cdn",
      "dedicated",
      "USD"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Melbicom 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the Melbicom dashboard, create API Token, then copy it.",
        "ja": "Melbicom ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.melbicom.net/",
    "credentialSetupURL": "https://docs.api.melbicom.net/",
    "summary": {
      "zh": "欧洲独立服务器和 CDN。按本月发票合计。",
      "en": "European dedicated servers and CDN. This month’s invoices, summed.",
      "ja": "欧州の専用サーバと CDN。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "time4vps",
    "name": "Time4VPS",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "立陶宛 HostBill 发票型 VPS，区域体量小于西欧主流 IaaS。",
    "searchKeywords": [
      "time4vps",
      "hostbill",
      "invoice",
      "vps",
      "EUR",
      "USD"
    ],
    "fields": [
      {
        "key": "clientSecret",
        "label": {
          "zh": "Client Secret",
          "en": "Client Secret",
          "ja": "Client Secret"
        },
        "isSecret": true
      },
      {
        "key": "email",
        "label": {
          "zh": "Email",
          "en": "Email",
          "ja": "Email"
        },
        "isSecret": false,
        "hint": {
          "zh": "登录邮箱",
          "en": "Sign-in email",
          "ja": "ログイン用メール"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Time4VPS 控制台 的 API 页面，创建 Client Secret，然后复制。",
        "en": "Open the API page in the Time4VPS dashboard, create Client Secret, then copy it.",
        "ja": "Time4VPS ダッシュボード の API ページを開き、Client Secret を作成してコピーします。"
      },
      {
        "zh": "打开 Time4VPS 控制台 的 API 页面，创建 Email，然后复制。",
        "en": "Open the API page in the Time4VPS dashboard, create Email, then copy it.",
        "ja": "Time4VPS ダッシュボード の API ページを開き、Email を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://billing.time4vps.com/",
    "credentialSetupURL": "https://billing.time4vps.com/userapi/",
    "summary": {
      "zh": "立陶宛 VPS。按本月发票合计。",
      "en": "Lithuanian VPS. This month’s invoices, summed.",
      "ja": "リトアニアの VPS。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "bitlaunch",
    "name": "BitLaunch",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "加密货币友好的按小时 VPS 聚合层，周期 usage 美元清晰但体量偏小。",
    "searchKeywords": [
      "bitlaunch",
      "usage",
      "totalUsd",
      "vps",
      "USD"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 BitLaunch 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the BitLaunch dashboard, create API Token, then copy it.",
        "ja": "BitLaunch ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://app.bitlaunch.io/",
    "credentialSetupURL": "https://developers.bitlaunch.io/reference/view-usage",
    "summary": {
      "zh": "加密货币结算的按小时 VPS。按本周期美元用量。",
      "en": "Crypto-settled hourly VPS. This period’s usage in USD.",
      "ja": "暗号資産決済の時間課金 VPS。今期のドル用量です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "hivelocity",
    "name": "Hivelocity",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "美国裸金属 / Instant 托管，发票金额明确但不及超大规模云。",
    "searchKeywords": [
      "hivelocity",
      "invoice",
      "bare metal",
      "core.hivelocity.net",
      "USD"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Hivelocity 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Hivelocity dashboard, create API Key, then copy it.",
        "ja": "Hivelocity ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://my.hivelocity.net/",
    "credentialSetupURL": "https://developers.hivelocity.net/docs/billing",
    "summary": {
      "zh": "美国裸金属。按本月发票合计。",
      "en": "US bare metal. This month’s invoices, summed.",
      "ja": "米国のベアメタル。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "scalingo",
    "name": "Scalingo",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "法国 PaaS，发票欧分清晰但体量小于 Clever Cloud / Scaleway 短名单。",
    "searchKeywords": [
      "scalingo",
      "invoice",
      "total_price",
      "EUR",
      "PaaS",
      "osc-fr1"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Scalingo 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the Scalingo dashboard, create API Token, then copy it.",
        "ja": "Scalingo ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://dashboard.scalingo.com/",
    "credentialSetupURL": "https://developers.scalingo.com/invoices",
    "summary": {
      "zh": "法国应用托管。按本月发票合计，欧元会折成美元。",
      "en": "French app hosting. This month’s invoices, summed. Euros convert to USD.",
      "ja": "フランスのアプリホスティング。今月のインボイス合計で、ユーロはドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "upsun",
    "name": "Upsun",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "原 Platform.sh 的 PaaS，订单 total+currency 清晰但体量小于主流公有云。",
    "searchKeywords": [
      "upsun",
      "platform.sh",
      "orders",
      "currency",
      "PaaS"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Account ID",
          "en": "Account ID",
          "ja": "Account ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台里的账户或组织 ID",
          "en": "Account or organization ID in the dashboard",
          "ja": "ダッシュボードのアカウントまたは組織 ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Upsun 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the Upsun dashboard, create API Token, then copy it.",
        "ja": "Upsun ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      },
      {
        "zh": "打开 Upsun 控制台 的 API 页面，创建 Account ID，然后复制。",
        "en": "Open the API page in the Upsun dashboard, create Account ID, then copy it.",
        "ja": "Upsun ダッシュボード の API ページを開き、Account ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://console.upsun.com/",
    "credentialSetupURL": "https://developer.upsun.com/api-reference/orders/list-orders",
    "summary": {
      "zh": "应用托管 PaaS（原 Platform.sh）。按本月订单合计。",
      "en": "App-hosting PaaS, formerly Platform.sh. This month’s orders, summed.",
      "ja": "アプリホスティング PaaS（旧 Platform.sh）。今月の注文合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "ncloud",
    "name": "NAVER Cloud",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "韩国主权公有云龙头，月度请款 totalDemandAmount+payCurrency 清晰但全球份额远小于 Hyperscaler。",
    "searchKeywords": [
      "ncloud",
      "naver cloud",
      "navercloud",
      "demandCost",
      "KRW",
      "ntruss"
    ],
    "fields": [
      {
        "key": "secretAccessKey",
        "label": {
          "zh": "Secret Access Key",
          "en": "Secret Access Key",
          "ja": "Secret Access Key"
        },
        "isSecret": true
      },
      {
        "key": "accessKeyID",
        "label": {
          "zh": "Access Key ID",
          "en": "Access Key ID",
          "ja": "Access Key ID"
        },
        "isSecret": false
      }
    ],
    "steps": [
      {
        "zh": "打开 NAVER Cloud 控制台 的 API 页面，创建 Secret Access Key，然后复制。",
        "en": "Open the API page in the NAVER Cloud dashboard, create Secret Access Key, then copy it.",
        "ja": "NAVER Cloud ダッシュボード の API ページを開き、Secret Access Key を作成してコピーします。"
      },
      {
        "zh": "打开 NAVER Cloud 控制台 的 API 页面，创建 Access Key ID，然后复制。",
        "en": "Open the API page in the NAVER Cloud dashboard, create Access Key ID, then copy it.",
        "ja": "NAVER Cloud ダッシュボード の API ページを開き、Access Key ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://console.ncloud.com/",
    "credentialSetupURL": "https://api.ncloud-docs.com/docs/en/platform-costandusage-getdemandcostlist",
    "summary": {
      "zh": "韩国公有云。按本月请款合计，韩元会折成美元。",
      "en": "Korean public cloud. This month’s amount demanded. Won convert to USD.",
      "ja": "韓国のパブリッククラウド。今月の請求合計で、ウォンはドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "nomos",
    "name": "Nomos",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "德国能源零售用量发票 API，体量远小于 Octopus / Tibber，但 period EUR 清晰。",
    "searchKeywords": [
      "nomos",
      "nomos.energy",
      "usage invoice",
      "EUR",
      "electricity"
    ],
    "fields": [
      {
        "key": "clientSecret",
        "label": {
          "zh": "Client Secret",
          "en": "Client Secret",
          "ja": "Client Secret"
        },
        "isSecret": true
      },
      {
        "key": "clientID",
        "label": {
          "zh": "Client ID",
          "en": "Client ID",
          "ja": "Client ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台 API 凭证里的 ID",
          "en": "ID from API credentials in the dashboard",
          "ja": "ダッシュボードの API 認証情報の ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Nomos 控制台 的 API 页面，创建 Client Secret，然后复制。",
        "en": "Open the API page in the Nomos dashboard, create Client Secret, then copy it.",
        "ja": "Nomos ダッシュボード の API ページを開き、Client Secret を作成してコピーします。"
      },
      {
        "zh": "打开 Nomos 控制台 的 API 页面，创建 Client ID，然后复制。",
        "en": "Open the API page in the Nomos dashboard, create Client ID, then copy it.",
        "ja": "Nomos ダッシュボード の API ページを開き、Client ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://nomos.energy/",
    "credentialSetupURL": "https://docs.nomos.energy/api-reference/invoices/list-invoices",
    "summary": {
      "zh": "德国电力零售。按周期用电花费，欧元会折成美元。",
      "en": "German electricity retail. Period usage cost. Euros convert to USD.",
      "ja": "ドイツの電力小売。周期の電気代で、ユーロはドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "dnscale",
    "name": "DNScale",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "欧洲独立 DNS 小厂，billing summary EUR 清晰但份额远小于 Cloudflare / DNSimple。",
    "searchKeywords": [
      "dnscale",
      "dns",
      "billing summary",
      "EUR"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 DNScale 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the DNScale dashboard, create API Token, then copy it.",
        "ja": "DNScale ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://dnscale.eu/",
    "credentialSetupURL": "https://dnscale.eu/api/billing",
    "summary": {
      "zh": "欧洲独立 DNS。按账单摘要，欧元会折成美元。",
      "en": "Independent European DNS. The billing summary. Euros convert to USD.",
      "ja": "欧州の独立 DNS。請求サマリーで、ユーロはドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "formspring",
    "name": "Formspring",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "欧盟表单 SaaS，billing invoices USD cents 清晰但份额远小于 Typeform。",
    "searchKeywords": [
      "formspring",
      "formspring.io",
      "billing invoices",
      "USD cents",
      "billing:read"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Formspring 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the Formspring dashboard, create API Token, then copy it.",
        "ja": "Formspring ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://formspring.io/",
    "credentialSetupURL": "https://formspring.io/docs/api/reference/billing",
    "summary": {
      "zh": "欧盟在线表单。按本月发票合计。",
      "en": "EU online forms. This month’s invoices, summed.",
      "ja": "EU のオンラインフォーム。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "hostcircle",
    "name": "Hostcircle",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "荷兰 HostBill 主机商，发票 total+currency 清晰但全球份额远小于 Time4VPS / Hetzner。",
    "searchKeywords": [
      "hostcircle",
      "hostbill",
      "invoice",
      "EUR",
      "my.hostcircle.com"
    ],
    "fields": [
      {
        "key": "clientSecret",
        "label": {
          "zh": "Client Secret",
          "en": "Client Secret",
          "ja": "Client Secret"
        },
        "isSecret": true
      },
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      },
      {
        "key": "email",
        "label": {
          "zh": "Email",
          "en": "Email",
          "ja": "Email"
        },
        "isSecret": false,
        "hint": {
          "zh": "登录邮箱",
          "en": "Sign-in email",
          "ja": "ログイン用メール"
        }
      },
      {
        "key": "clientID",
        "label": {
          "zh": "Client ID",
          "en": "Client ID",
          "ja": "Client ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台 API 凭证里的 ID",
          "en": "ID from API credentials in the dashboard",
          "ja": "ダッシュボードの API 認証情報の ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Hostcircle 控制台 的 API 页面，创建 Client Secret 和 API Token，然后复制。",
        "en": "Open the API page in the Hostcircle dashboard, create Client Secret and API Token, then copy them.",
        "ja": "Hostcircle ダッシュボード の API ページを開き、Client Secret と API Token を作成してコピーします。"
      },
      {
        "zh": "打开 Hostcircle 控制台 的 API 页面，创建 Email 和 Client ID，然后复制。",
        "en": "Open the API page in the Hostcircle dashboard, create Email and Client ID, then copy them.",
        "ja": "Hostcircle ダッシュボード の API ページを開き、Email と Client ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://my.hostcircle.com/",
    "credentialSetupURL": "https://my.hostcircle.com/userapi/",
    "summary": {
      "zh": "荷兰主机。按本月发票合计，欧元会折成美元。",
      "en": "Dutch web hosting. This month’s invoices, summed. Euros convert to USD.",
      "ja": "オランダのホスティング。今月のインボイス合計で、ユーロはドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "loginet",
    "name": "Loginet",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "爱沙尼亚 IaaS，HostBill 发票 total+currency 清晰但体量远小于北欧大厂。",
    "searchKeywords": [
      "loginet",
      "hostbill.loginet.ee",
      "invoice",
      "EUR",
      "estonia"
    ],
    "fields": [
      {
        "key": "clientSecret",
        "label": {
          "zh": "Client Secret",
          "en": "Client Secret",
          "ja": "Client Secret"
        },
        "isSecret": true
      },
      {
        "key": "email",
        "label": {
          "zh": "Email",
          "en": "Email",
          "ja": "Email"
        },
        "isSecret": false,
        "hint": {
          "zh": "登录邮箱",
          "en": "Sign-in email",
          "ja": "ログイン用メール"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Loginet 控制台 的 API 页面，创建 Client Secret，然后复制。",
        "en": "Open the API page in the Loginet dashboard, create Client Secret, then copy it.",
        "ja": "Loginet ダッシュボード の API ページを開き、Client Secret を作成してコピーします。"
      },
      {
        "zh": "打开 Loginet 控制台 的 API 页面，创建 Email，然后复制。",
        "en": "Open the API page in the Loginet dashboard, create Email, then copy it.",
        "ja": "Loginet ダッシュボード の API ページを開き、Email を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://hostbill.loginet.ee/",
    "credentialSetupURL": "https://hostbill.loginet.ee/?cmd=userapi",
    "summary": {
      "zh": "爱沙尼亚云主机。按本月发票合计，欧元会折成美元。",
      "en": "Estonian cloud hosts. This month’s invoices, summed. Euros convert to USD.",
      "ja": "エストニアのクラウドホスト。今月のインボイス合計で、ユーロはドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "idcloudhost",
    "name": "IDCloudHost",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "印尼/SEA 区域云，period invoice totals 清晰，份额远小于阿里云 / AWS 亚太。",
    "searchKeywords": [
      "idcloudhost",
      "indonesia",
      "SEA",
      "invoice",
      "IDR",
      "jkt",
      "sgp"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Account ID",
          "en": "Account ID",
          "ja": "Account ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台里的账户或组织 ID",
          "en": "Account or organization ID in the dashboard",
          "ja": "ダッシュボードのアカウントまたは組織 ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 IDCloudHost 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the IDCloudHost dashboard, create API Key, then copy it.",
        "ja": "IDCloudHost ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      },
      {
        "zh": "打开 IDCloudHost 控制台 的 API 页面，创建 Account ID，然后复制。",
        "en": "Open the API page in the IDCloudHost dashboard, create Account ID, then copy it.",
        "ja": "IDCloudHost ダッシュボード の API ページを開き、Account ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://idcloudhost.com/",
    "credentialSetupURL": "https://api.idcloudhost.com/",
    "summary": {
      "zh": "印尼区域云。按本月发票合计，印尼盾会折成美元。",
      "en": "Indonesian regional cloud. This month’s invoices, summed. Rupiah convert to USD.",
      "ja": "インドネシアのリージョンクラウド。今月のインボイス合計で、ルピアはドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "iwinv",
    "name": "iwinv",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "韩国区域云 period 账单（payment_price），体量远小于 ncloud / AWS 亚太。",
    "searchKeywords": [
      "iwinv",
      "korea",
      "KRW",
      "bill",
      "stack"
    ],
    "fields": [
      {
        "key": "secretAccessKey",
        "label": {
          "zh": "Secret Access Key",
          "en": "Secret Access Key",
          "ja": "Secret Access Key"
        },
        "isSecret": true
      },
      {
        "key": "accessKeyID",
        "label": {
          "zh": "Access Key ID",
          "en": "Access Key ID",
          "ja": "Access Key ID"
        },
        "isSecret": false
      }
    ],
    "steps": [
      {
        "zh": "打开 iwinv 控制台 的 API 页面，创建 Secret Access Key，然后复制。",
        "en": "Open the API page in the iwinv dashboard, create Secret Access Key, then copy it.",
        "ja": "iwinv ダッシュボード の API ページを開き、Secret Access Key を作成してコピーします。"
      },
      {
        "zh": "打开 iwinv 控制台 的 API 页面，创建 Access Key ID，然后复制。",
        "en": "Open the API page in the iwinv dashboard, create Access Key ID, then copy it.",
        "ja": "iwinv ダッシュボード の API ページを開き、Access Key ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.iwinv.kr/",
    "credentialSetupURL": "https://api.iwinv.kr/doc-637859",
    "summary": {
      "zh": "韩国区域云。按周期账单，韩元会折成美元。",
      "en": "Korean regional cloud. Period bills. Won convert to USD.",
      "ja": "韓国のリージョンクラウド。周期請求で、ウォンはドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "frankenergie",
    "name": "Frank Energie",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "荷兰能源零售发票 GraphQL（totalAmount EUR），体量小于 Octopus / Tibber / Nomos。",
    "searchKeywords": [
      "frank",
      "frankenergie",
      "netherlands",
      "EUR",
      "invoice",
      "energy"
    ],
    "fields": [
      {
        "key": "clientSecret",
        "label": {
          "zh": "Client Secret",
          "en": "Client Secret",
          "ja": "Client Secret"
        },
        "isSecret": true
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Account ID",
          "en": "Account ID",
          "ja": "Account ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台里的账户或组织 ID",
          "en": "Account or organization ID in the dashboard",
          "ja": "ダッシュボードのアカウントまたは組織 ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Frank Energie 控制台 的 API 页面，创建 Client Secret，然后复制。",
        "en": "Open the API page in the Frank Energie dashboard, create Client Secret, then copy it.",
        "ja": "Frank Energie ダッシュボード の API ページを開き、Client Secret を作成してコピーします。"
      },
      {
        "zh": "打开 Frank Energie 控制台 的 API 页面，创建 Account ID，然后复制。",
        "en": "Open the API page in the Frank Energie dashboard, create Account ID, then copy it.",
        "ja": "Frank Energie ダッシュボード の API ページを開き、Account ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.frankenergie.nl/",
    "credentialSetupURL": "https://github.com/HiDiHo01/python-frank-energie",
    "summary": {
      "zh": "荷兰电力零售。按本月发票合计，欧元会折成美元。",
      "en": "Dutch electricity retail. This month’s invoices, summed. Euros convert to USD.",
      "ja": "オランダの電力小売。今月のインボイス合計で、ユーロはドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "dilmune",
    "name": "Dilmune",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "托管云 Stripe 发票列表（amount 分），份额远小于 DigitalOcean / AWS。",
    "searchKeywords": [
      "dilmune",
      "invoice",
      "stripe",
      "cloud",
      "hosting"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Dilmune 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the Dilmune dashboard, create API Token, then copy it.",
        "ja": "Dilmune ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://dilmune.com/",
    "credentialSetupURL": "https://docs.dilmune.com/",
    "summary": {
      "zh": "小型托管云。按本月发票合计。",
      "en": "A small managed cloud. This month’s invoices, summed.",
      "ja": "小型マネージドクラウド。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "hubble",
    "name": "Hubble",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "物联网卫星网络 period 发票（total_balance），体量小于 Soracom / 1NCE。",
    "searchKeywords": [
      "hubble",
      "iot",
      "satellite",
      "invoice",
      "billing"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Account ID",
          "en": "Account ID",
          "ja": "Account ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台里的账户或组织 ID",
          "en": "Account or organization ID in the dashboard",
          "ja": "ダッシュボードのアカウントまたは組織 ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Hubble 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the Hubble dashboard, create API Token, then copy it.",
        "ja": "Hubble ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      },
      {
        "zh": "打开 Hubble 控制台 的 API 页面，创建 Account ID，然后复制。",
        "en": "Open the API page in the Hubble dashboard, create Account ID, then copy it.",
        "ja": "Hubble ダッシュボード の API ページを開き、Account ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://hubble.com/",
    "credentialSetupURL": "https://hubble.com/docs/openapi.yaml",
    "summary": {
      "zh": "物联网卫星网络。按本月发票合计。",
      "en": "IoT satellite network. This month’s invoices, summed.",
      "ja": "IoT 衛星ネットワーク。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "filescom",
    "name": "Files.com",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "企业文件传输/对象存储 period 发票（amount+currency），体量小于 Backblaze / Wasabi。",
    "searchKeywords": [
      "files.com",
      "filescom",
      "invoice",
      "storage",
      "sftp"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Files.com 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Files.com dashboard, create API Key, then copy it.",
        "ja": "Files.com ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.files.com/",
    "credentialSetupURL": "https://developers.files.com/rest/resources/billing/account-line-items/",
    "summary": {
      "zh": "企业文件传输。按本月发票合计。",
      "en": "Enterprise file transfer. This month’s invoices, summed.",
      "ja": "企業向けファイル転送。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "doit",
    "name": "DoiT",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "多云 FinOps 发票列表（totalAmount），体量小于原生 AWS / GCP 账单适配。",
    "searchKeywords": [
      "doit",
      "doit.com",
      "finops",
      "invoice",
      "aws",
      "gcp"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 DoiT 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the DoiT dashboard, create API Token, then copy it.",
        "ja": "DoiT ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.doit.com/",
    "credentialSetupURL": "https://developer.doit.com/docs/invoice",
    "summary": {
      "zh": "多云账单管家。按发票合计。",
      "en": "A multi-cloud billing desk. Invoices, summed.",
      "ja": "マルチクラウドの請求デスク。インボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "timeweb",
    "name": "Timeweb Cloud",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "俄罗斯区域云 finances.monthly_cost+currency，体量远小于 Selectel / Yandex Cloud。",
    "searchKeywords": [
      "timeweb",
      "timeweb.cloud",
      "monthly_cost",
      "finances",
      "RU"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Timeweb Cloud 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the Timeweb Cloud dashboard, create API Token, then copy it.",
        "ja": "Timeweb Cloud ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://timeweb.cloud/",
    "credentialSetupURL": "https://timeweb.cloud/api-docs",
    "summary": {
      "zh": "俄罗斯云主机。按本月服务费用估算。",
      "en": "Russian cloud hosts. This month’s estimated service cost.",
      "ja": "ロシアのクラウドホスト。今月のサービス費用見積もりです。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "cloudheed",
    "name": "Cloudheed",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 1,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "新兴托管数据库 usage total+currency，体量远小于 Neon / PlanetScale / Cockroach。",
    "searchKeywords": [
      "cloudheed",
      "billing/usage",
      "database",
      "postgres"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Cloudheed 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the Cloudheed dashboard, create API Token, then copy it.",
        "ja": "Cloudheed ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://cloudheed.com/",
    "credentialSetupURL": "https://docs.cloudheed.com/billing",
    "summary": {
      "zh": "托管 Postgres。按本周期用量花费。",
      "en": "Managed Postgres. This period’s usage spend.",
      "ja": "マネージド Postgres。今期の用量支出です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "sevalla",
    "name": "Sevalla",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 2,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "新兴应用托管 PaaS（paas-usage cost USD），体量远小于 Railway / Render / Vercel。",
    "searchKeywords": [
      "sevalla",
      "paas-usage",
      "hosting",
      "kinsta"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Sevalla 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the Sevalla dashboard, create API Token, then copy it.",
        "ja": "Sevalla ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://sevalla.com/",
    "credentialSetupURL": "https://api-docs.sevalla.com/v2/company/get-usage",
    "summary": {
      "zh": "新兴应用托管。按本周期 PaaS 用量花费。",
      "en": "Newer app hosting. This period’s PaaS usage spend.",
      "ja": "新興のアプリホスティング。今期の PaaS 用量支出です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "catalystvm",
    "name": "CatalystVM",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "小型 HostBill VPS（invoice total+currency），体量远小于 Time4VPS / Hetzner。",
    "searchKeywords": [
      "catalystvm",
      "hostbill",
      "invoice",
      "USD",
      "my.catalystvm.com",
      "vps"
    ],
    "fields": [
      {
        "key": "clientSecret",
        "label": {
          "zh": "Client Secret",
          "en": "Client Secret",
          "ja": "Client Secret"
        },
        "isSecret": true
      },
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      },
      {
        "key": "email",
        "label": {
          "zh": "Email",
          "en": "Email",
          "ja": "Email"
        },
        "isSecret": false,
        "hint": {
          "zh": "登录邮箱",
          "en": "Sign-in email",
          "ja": "ログイン用メール"
        }
      },
      {
        "key": "clientID",
        "label": {
          "zh": "Client ID",
          "en": "Client ID",
          "ja": "Client ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台 API 凭证里的 ID",
          "en": "ID from API credentials in the dashboard",
          "ja": "ダッシュボードの API 認証情報の ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 CatalystVM 控制台 的 API 页面，创建 Client Secret 和 API Token，然后复制。",
        "en": "Open the API page in the CatalystVM dashboard, create Client Secret and API Token, then copy them.",
        "ja": "CatalystVM ダッシュボード の API ページを開き、Client Secret と API Token を作成してコピーします。"
      },
      {
        "zh": "打开 CatalystVM 控制台 的 API 页面，创建 Email 和 Client ID，然后复制。",
        "en": "Open the API page in the CatalystVM dashboard, create Email and Client ID, then copy them.",
        "ja": "CatalystVM ダッシュボード の API ページを開き、Email と Client ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://my.catalystvm.com/",
    "credentialSetupURL": "https://my.catalystvm.com/userapi/",
    "summary": {
      "zh": "小型 VPS。按本月发票合计，不报账户余额。",
      "en": "A small VPS host. This month’s invoices, summed; not account credit.",
      "ja": "小型 VPS。今月のインボイス合計で、口座残高は出しません。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "oxahost",
    "name": "Oxahost",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "非洲/法语区 HostBill 主机商（invoice total+currency），全球份额远小于主流 IaaS。",
    "searchKeywords": [
      "oxahost",
      "hostbill",
      "invoice",
      "USD",
      "my.oxahost.com",
      "afrinic"
    ],
    "fields": [
      {
        "key": "clientSecret",
        "label": {
          "zh": "Client Secret",
          "en": "Client Secret",
          "ja": "Client Secret"
        },
        "isSecret": true
      },
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      },
      {
        "key": "email",
        "label": {
          "zh": "Email",
          "en": "Email",
          "ja": "Email"
        },
        "isSecret": false,
        "hint": {
          "zh": "登录邮箱",
          "en": "Sign-in email",
          "ja": "ログイン用メール"
        }
      },
      {
        "key": "clientID",
        "label": {
          "zh": "Client ID",
          "en": "Client ID",
          "ja": "Client ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台 API 凭证里的 ID",
          "en": "ID from API credentials in the dashboard",
          "ja": "ダッシュボードの API 認証情報の ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Oxahost 控制台 的 API 页面，创建 Client Secret 和 API Token，然后复制。",
        "en": "Open the API page in the Oxahost dashboard, create Client Secret and API Token, then copy them.",
        "ja": "Oxahost ダッシュボード の API ページを開き、Client Secret と API Token を作成してコピーします。"
      },
      {
        "zh": "打开 Oxahost 控制台 的 API 页面，创建 Email 和 Client ID，然后复制。",
        "en": "Open the API page in the Oxahost dashboard, create Email and Client ID, then copy them.",
        "ja": "Oxahost ダッシュボード の API ページを開き、Email と Client ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://my.oxahost.com/",
    "credentialSetupURL": "https://my.oxahost.com/userapi/",
    "summary": {
      "zh": "非洲和法语区主机。按本月发票合计，不报账户余额。",
      "en": "African and francophone hosting. This month’s invoices, summed; not account credit.",
      "ja": "アフリカと仏語圏のホスティング。今月のインボイス合計で、口座残高は出しません。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "fiskil",
    "name": "Fiskil",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "澳洲 CDR 能源发票聚合（total_amount+currency），体量小于 UtilityAPI / VoltView 同类短名单。",
    "searchKeywords": [
      "fiskil",
      "cdr",
      "energy",
      "invoice",
      "AUD",
      "total_amount"
    ],
    "fields": [
      {
        "key": "clientSecret",
        "label": {
          "zh": "Client Secret",
          "en": "Client Secret",
          "ja": "Client Secret"
        },
        "isSecret": true
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Account ID",
          "en": "Account ID",
          "ja": "Account ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台里的账户或组织 ID",
          "en": "Account or organization ID in the dashboard",
          "ja": "ダッシュボードのアカウントまたは組織 ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Fiskil 控制台 的 API 页面，创建 Client Secret，然后复制。",
        "en": "Open the API page in the Fiskil dashboard, create Client Secret, then copy it.",
        "ja": "Fiskil ダッシュボード の API ページを開き、Client Secret を作成してコピーします。"
      },
      {
        "zh": "打开 Fiskil 控制台 的 API 页面，创建 Account ID，然后复制。",
        "en": "Open the API page in the Fiskil dashboard, create Account ID, then copy it.",
        "ja": "Fiskil ダッシュボード の API ページを開き、Account ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://fiskil.com/",
    "credentialSetupURL": "https://docs.fiskil.com/data-api/api-reference/getEnergyInvoices",
    "summary": {
      "zh": "澳洲能源发票。按本月发票合计，澳元会折成美元。",
      "en": "Australian energy invoices. This month’s invoices, summed. AUD converts to USD.",
      "ja": "オーストラリアのエネルギー請求。今月のインボイス合計で、豪ドルはドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "threeplguys",
    "name": "3PLGuys",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "北美电商履约/仓储 3PL 的细分选手，买方发票 totalAmount（分）+currency，与 ShipBob 同属履约账单短名单。",
    "searchKeywords": [
      "3plguys",
      "3pl",
      "fulfillment",
      "invoices",
      "totalAmount",
      "USD"
    ],
    "fields": [
      {
        "key": "personalAccessToken",
        "label": {
          "zh": "Personal Access Token",
          "en": "Personal Access Token",
          "ja": "Personal Access Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 3PLGuys 控制台 的 API 页面，创建 Personal Access Token，然后复制。",
        "en": "Open the API page in the 3PLGuys dashboard, create Personal Access Token, then copy it.",
        "ja": "3PLGuys ダッシュボード の API ページを開き、Personal Access Token を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://3plguys.com/",
    "credentialSetupURL": "https://developer.3plguys.com/docs/invoices/",
    "summary": {
      "zh": "北美仓储履约。按本月买方发票合计。",
      "en": "North-American 3PL fulfillment. This month’s buyer invoices, summed.",
      "ja": "北米の倉庫フルフィルメント。今月の買い手インボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "pleo",
    "name": "Pleo",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "欧洲企业支出卡 SaaS 的强挑战者；仅取 PLEO_INVOICE（买方平台费）minors+currency，排除报销/卡消费聚合。",
    "searchKeywords": [
      "pleo",
      "PLEO_INVOICE",
      "accounting-entries",
      "minors",
      "EUR"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Account ID",
          "en": "Account ID",
          "ja": "Account ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台里的账户或组织 ID",
          "en": "Account or organization ID in the dashboard",
          "ja": "ダッシュボードのアカウントまたは組織 ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Pleo 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Pleo dashboard, create API Key, then copy it.",
        "ja": "Pleo ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      },
      {
        "zh": "打开 Pleo 控制台 的 API 页面，创建 Account ID，然后复制。",
        "en": "Open the API page in the Pleo dashboard, create Account ID, then copy it.",
        "ja": "Pleo ダッシュボード の API ページを開き、Account ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.pleo.io/",
    "credentialSetupURL": "https://developers.pleo.io/reference/accounting-entries/v1/search-accounting-entries",
    "summary": {
      "zh": "企业支出卡。这里只记平台开给你的发票，不含卡消费。",
      "en": "Corporate spend cards. This records Pleo’s invoices to you, not card spend.",
      "ja": "法人支出カード。Pleo があなたに出すインボイスだけで、カード利用額は含みません。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "cerebrium",
    "name": "Cerebrium",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "Serverless GPU 部署云的细分选手，买方发票 amountDue（分）+currency，体量小于 RunPod / Fireworks 主流短名单。",
    "searchKeywords": [
      "cerebrium",
      "invoices",
      "amountDue",
      "currency",
      "serverless gpu"
    ],
    "fields": [
      {
        "key": "personalAccessToken",
        "label": {
          "zh": "Personal Access Token",
          "en": "Personal Access Token",
          "ja": "Personal Access Token"
        },
        "isSecret": true
      },
      {
        "key": "projectID",
        "label": {
          "zh": "Project ID",
          "en": "Project ID",
          "ja": "Project ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台里的项目 ID",
          "en": "Project ID in the dashboard",
          "ja": "ダッシュボードのプロジェクト ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Cerebrium 控制台 的 API 页面，创建 Personal Access Token，然后复制。",
        "en": "Open the API page in the Cerebrium dashboard, create Personal Access Token, then copy it.",
        "ja": "Cerebrium ダッシュボード の API ページを開き、Personal Access Token を作成してコピーします。"
      },
      {
        "zh": "打开 Cerebrium 控制台 的 API 页面，创建 Project ID，然后复制。",
        "en": "Open the API page in the Cerebrium dashboard, create Project ID, then copy it.",
        "ja": "Cerebrium ダッシュボード の API ページを開き、Project ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://dashboard.cerebrium.ai/",
    "credentialSetupURL": "https://cerebrium.ai/docs/api-reference/subscriptions/list-invoices",
    "summary": {
      "zh": "Serverless GPU 部署。按本月发票应付合计。",
      "en": "Serverless GPU deploy. This month’s invoices due, summed.",
      "ja": "サーバーレス GPU デプロイ。今月のインボイス支払い合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "shipmondo",
    "name": "Shipmondo",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "丹麦/欧盟电商发货 SaaS 的细分选手；买方账户流水 amount+currency_code，只计 sales_document 扣费、忽略充值。",
    "searchKeywords": [
      "shipmondo",
      "ledger",
      "amount",
      "currency_code",
      "sales_document",
      "shipping"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      },
      {
        "key": "email",
        "label": {
          "zh": "Email",
          "en": "Email",
          "ja": "Email"
        },
        "isSecret": false,
        "hint": {
          "zh": "登录邮箱",
          "en": "Sign-in email",
          "ja": "ログイン用メール"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Shipmondo 控制台 的 API 页面，创建 API Key，然后复制。",
        "en": "Open the API page in the Shipmondo dashboard, create API Key, then copy it.",
        "ja": "Shipmondo ダッシュボード の API ページを開き、API Key を作成してコピーします。"
      },
      {
        "zh": "打开 Shipmondo 控制台 的 API 页面，创建 Email，然后复制。",
        "en": "Open the API page in the Shipmondo dashboard, create Email, then copy it.",
        "ja": "Shipmondo ダッシュボード の API ページを開き、Email を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://app.shipmondo.com/",
    "credentialSetupURL": "https://shipmondo.dev/api-reference#/operations/user_ledger_entries_get",
    "summary": {
      "zh": "丹麦电商发货。按账户流水里的发货扣费，充值不算。",
      "en": "Danish ecommerce shipping. Ledger shipping charges; top-ups are skipped.",
      "ja": "デンマークの EC 発送。口座明細の発送引き落としで、チャージは数えません。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "sendcloud",
    "name": "Sendcloud",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": true,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "荷兰/欧盟电商发货 SaaS 主流选手；买方发票 price_taxable/tax value+currency 同资源，Basic Public+Private Key。",
    "searchKeywords": [
      "sendcloud",
      "invoice",
      "price_taxable",
      "currency",
      "shipping",
      "eu"
    ],
    "fields": [
      {
        "key": "apiKey",
        "label": {
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      },
      {
        "key": "clientSecret",
        "label": {
          "zh": "Client Secret",
          "en": "Client Secret",
          "ja": "Client Secret"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Sendcloud 控制台 的 API 页面，创建 API Key 和 Client Secret，然后复制。",
        "en": "Open the API page in the Sendcloud dashboard, create API Key and Client Secret, then copy them.",
        "ja": "Sendcloud ダッシュボード の API ページを開き、API Key と Client Secret を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://panel.sendcloud.sc/",
    "credentialSetupURL": "https://sendcloud.dev/api/v3/invoices/retrieve-a-list-of-invoices",
    "summary": {
      "zh": "欧洲电商发货。按本月发票合计，含税。",
      "en": "European ecommerce shipping. This month’s invoices, tax included.",
      "ja": "欧州の EC 発送。今月のインボイス合計（税込）です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "alibabacloud",
    "name": "Alibaba Cloud",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "亚太超大规模云龙头，与 AWS / Azure / GCP 并列全球公有云短名单；BSS QueryBillOverview 同资源 PretaxAmount+Currency。",
    "searchKeywords": [
      "alibaba",
      "aliyun",
      "阿里云",
      "bss",
      "querybilloverview",
      "accesskey"
    ],
    "fields": [
      {
        "key": "secretAccessKey",
        "label": {
          "zh": "Secret Access Key",
          "en": "Secret Access Key",
          "ja": "Secret Access Key"
        },
        "isSecret": true
      },
      {
        "key": "accessKeyID",
        "label": {
          "zh": "Access Key ID",
          "en": "Access Key ID",
          "ja": "Access Key ID"
        },
        "isSecret": false
      }
    ],
    "steps": [
      {
        "zh": "打开 Alibaba Cloud 控制台 的 API 页面，创建 Secret Access Key，然后复制。",
        "en": "Open the API page in the Alibaba Cloud dashboard, create Secret Access Key, then copy it.",
        "ja": "Alibaba Cloud ダッシュボード の API ページを開き、Secret Access Key を作成してコピーします。"
      },
      {
        "zh": "打开 Alibaba Cloud 控制台 的 API 页面，创建 Access Key ID，然后复制。",
        "en": "Open the API page in the Alibaba Cloud dashboard, create Access Key ID, then copy it.",
        "ja": "Alibaba Cloud ダッシュボード の API ページを開き、Access Key ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://usercenter2.aliyun.com/finance/expense-report",
    "credentialSetupURL": "https://ram.console.aliyun.com/manage/ak",
    "summary": {
      "zh": "阿里云。按账单概览税前金额，人民币会折成美元。",
      "en": "Alibaba Cloud. Pretax bill overview. CNY converts to USD.",
      "ja": "Alibaba Cloud。請求概要の税引前金額で、人民元はドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "volcengine",
    "name": "Volcengine",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "字节跳动旗下公有云，国内主流短名单常见，体量次于阿里云 / 华为云；ListBillDetail 同资源 PayableAmount+Currency。",
    "searchKeywords": [
      "volcengine",
      "火山引擎",
      "bytedance",
      "billing",
      "listbilldetail",
      "accesskey"
    ],
    "fields": [
      {
        "key": "secretAccessKey",
        "label": {
          "zh": "Secret Access Key",
          "en": "Secret Access Key",
          "ja": "Secret Access Key"
        },
        "isSecret": true
      },
      {
        "key": "accessKeyID",
        "label": {
          "zh": "Access Key ID",
          "en": "Access Key ID",
          "ja": "Access Key ID"
        },
        "isSecret": false
      }
    ],
    "steps": [
      {
        "zh": "打开 Volcengine 控制台 的 API 页面，创建 Secret Access Key，然后复制。",
        "en": "Open the API page in the Volcengine dashboard, create Secret Access Key, then copy it.",
        "ja": "Volcengine ダッシュボード の API ページを開き、Secret Access Key を作成してコピーします。"
      },
      {
        "zh": "打开 Volcengine 控制台 的 API 页面，创建 Access Key ID，然后复制。",
        "en": "Open the API page in the Volcengine dashboard, create Access Key ID, then copy it.",
        "ja": "Volcengine ダッシュボード の API ページを開き、Access Key ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://console.volcengine.com/finance/bill/detail/",
    "credentialSetupURL": "https://console.volcengine.com/iam/keymanage/",
    "summary": {
      "zh": "火山引擎。按账单明细应付金额，人民币会折成美元。",
      "en": "Volcengine. Payable amount from bill details. CNY converts to USD.",
      "ja": "Volcengine。請求明細の支払額で、人民元はドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "kingsoftcloud",
    "name": "Kingsoft Cloud",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "国内主流公有云短名单常见（金山云），体量次于阿里云 / 华为云 / 腾讯云；DescribeBillSummaryByProduct 同资源 RealTotalCost+Currency。",
    "searchKeywords": [
      "ksyun",
      "kingsoft",
      "金山云",
      "bill-union",
      "describebillsummarybyproduct",
      "accesskey"
    ],
    "fields": [
      {
        "key": "secretAccessKey",
        "label": {
          "zh": "Secret Access Key",
          "en": "Secret Access Key",
          "ja": "Secret Access Key"
        },
        "isSecret": true
      },
      {
        "key": "accessKeyID",
        "label": {
          "zh": "Access Key ID",
          "en": "Access Key ID",
          "ja": "Access Key ID"
        },
        "isSecret": false
      }
    ],
    "steps": [
      {
        "zh": "打开 Kingsoft Cloud 控制台 的 API 页面，创建 Secret Access Key，然后复制。",
        "en": "Open the API page in the Kingsoft Cloud dashboard, create Secret Access Key, then copy it.",
        "ja": "Kingsoft Cloud ダッシュボード の API ページを開き、Secret Access Key を作成してコピーします。"
      },
      {
        "zh": "打开 Kingsoft Cloud 控制台 的 API 页面，创建 Access Key ID，然后复制。",
        "en": "Open the API page in the Kingsoft Cloud dashboard, create Access Key ID, then copy it.",
        "ja": "Kingsoft Cloud ダッシュボード の API ページを開き、Access Key ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://bill.console.ksyun.com/",
    "credentialSetupURL": "https://ucenter.console.ksyun.com/#/api",
    "summary": {
      "zh": "金山云。按产品线账单汇总，人民币会折成美元。",
      "en": "Kingsoft Cloud. Bill summary by product line. CNY converts to USD.",
      "ja": "Kingsoft Cloud。製品ライン別の請求集計で、人民元はドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "tencentcloud",
    "name": "Tencent Cloud",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 12,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "国内超大规模公有云龙头，与阿里云 / AWS / Azure 并列全球短名单；DescribeBillDetail 同资源 Component.RealCost+Currency。",
    "searchKeywords": [
      "tencent",
      "qcloud",
      "腾讯云",
      "billing",
      "describebilldetail",
      "tc3",
      "secretid"
    ],
    "fields": [
      {
        "key": "secretAccessKey",
        "label": {
          "zh": "Secret Access Key",
          "en": "Secret Access Key",
          "ja": "Secret Access Key"
        },
        "isSecret": true
      },
      {
        "key": "accessKeyID",
        "label": {
          "zh": "Access Key ID",
          "en": "Access Key ID",
          "ja": "Access Key ID"
        },
        "isSecret": false
      }
    ],
    "steps": [
      {
        "zh": "打开 Tencent Cloud 控制台 的 API 页面，创建 Secret Access Key，然后复制。",
        "en": "Open the API page in the Tencent Cloud dashboard, create Secret Access Key, then copy it.",
        "ja": "Tencent Cloud ダッシュボード の API ページを開き、Secret Access Key を作成してコピーします。"
      },
      {
        "zh": "打开 Tencent Cloud 控制台 的 API 页面，创建 Access Key ID，然后复制。",
        "en": "Open the API page in the Tencent Cloud dashboard, create Access Key ID, then copy it.",
        "ja": "Tencent Cloud ダッシュボード の API ページを開き、Access Key ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://console.cloud.tencent.com/expense/bill/overview",
    "credentialSetupURL": "https://console.cloud.tencent.com/cam/capi",
    "summary": {
      "zh": "腾讯云。按账单明细实付金额，人民币会折成美元。",
      "en": "Tencent Cloud. Actual cost from bill details. CNY converts to USD.",
      "ja": "Tencent Cloud。請求明細の実コストで、人民元はドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "make",
    "name": "Make",
    "kind": "usage",
    "status": "pendingVerification",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 24,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "欧洲无代码自动化龙头（原 Integromat），Celonis 旗下与 Zapier 并列短名单；组织 payments 同资源 amount_total+currency_code。",
    "searchKeywords": [
      "make",
      "integromat",
      "celonis",
      "payments",
      "amount_total",
      "automation"
    ],
    "fields": [
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Account ID",
          "en": "Account ID",
          "ja": "Account ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台里的账户或组织 ID",
          "en": "Account or organization ID in the dashboard",
          "ja": "ダッシュボードのアカウントまたは組織 ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Make 控制台 的 API 页面，创建 API Token，然后复制。",
        "en": "Open the API page in the Make dashboard, create API Token, then copy it.",
        "ja": "Make ダッシュボード の API ページを開き、API Token を作成してコピーします。"
      },
      {
        "zh": "打开 Make 控制台 的 API 页面，创建 Account ID，然后复制。",
        "en": "Open the API page in the Make dashboard, create Account ID, then copy it.",
        "ja": "Make ダッシュボード の API ページを開き、Account ID を作成してコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙需要重新签发。",
          "en": "This key needs to be issued again.",
          "ja": "このキーは再発行が必要です。"
        },
        "nextStep": {
          "zh": "回上一步重新创建一把，创建后立刻复制。",
          "en": "Go back a step, create a new one, and copy it right away.",
          "ja": "前の手順に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账单只读权限还待打开。",
          "en": "Billing read permission still needs to be turned on.",
          "ja": "請求の読み取り権限をまだ付ける必要があります。"
        },
        "nextStep": {
          "zh": "回上一步按只读权限重建一把。",
          "en": "Go back a step and recreate the key with read-only billing access.",
          "ja": "前の手順に戻り、請求の読み取り専用で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.make.com/en/pricing",
    "credentialSetupURL": "https://developers.make.com/api-documentation/authentication/create-authentication-token",
    "summary": {
      "zh": "无代码自动化。按本月组织付款合计。",
      "en": "No-code automation. This month’s organization payments, summed.",
      "ja": "ノーコード自動化。今月の組織支払い合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月花费一致。",
      "en": "This number should match this month’s spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の利用額と一致するはずです。"
    }
  },
  {
    "key": "amberelectric",
    "name": "Amber Electric",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "澳洲零售电力与智能电价细分里的中小型选手。",
    "searchKeywords": [
      "amber electric",
      "electricity",
      "australia",
      "电力"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "账单金额接口缺币种字段，无法作为账单 SoT。"
  },
  {
    "key": "shiphero",
    "name": "ShipHero",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "DTC 履约/WMS 细分挑战者，规模小于大型 3PL。",
    "searchKeywords": [
      "shiphero",
      "wms",
      "fulfillment",
      "履约"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "金额字段缺币种，无法作为账单 SoT。"
  },
  {
    "key": "worldstream",
    "name": "Worldstream",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "荷兰机柜/裸金属区域性主机商。",
    "searchKeywords": [
      "worldstream",
      "dedicated",
      "netherlands",
      "裸金属"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "用量/账单金额缺币种，无法作为账单 SoT。"
  },
  {
    "key": "imprezahost",
    "name": "Impreza Host",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "小众主机商，区域与品牌认知有限。",
    "searchKeywords": [
      "impreza",
      "hosting",
      "vps"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "账单金额缺币种，无法作为账单 SoT。"
  },
  {
    "key": "bitwarden",
    "name": "Bitwarden",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "开源密码管理强挑战者，企业采购常见短名单。",
    "searchKeywords": [
      "bitwarden",
      "password",
      "密码管理"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "billing 接口金额缺币种或非买家账单形态，无法作为账单 SoT。"
  },
  {
    "key": "sematext",
    "name": "Sematext",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "日志/APM 可观测性中小厂商。",
    "searchKeywords": [
      "sematext",
      "logs",
      "apm",
      "日志"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "账单金额缺币种，无法作为账单 SoT。"
  },
  {
    "key": "crusoe",
    "name": "Crusoe",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "低碳能源驱动的 GPU 云挑战者。",
    "searchKeywords": [
      "crusoe",
      "gpu",
      "cloud",
      "energy"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "costs 接口缺币种或非期间账单合计，无法作为账单 SoT。"
  },
  {
    "key": "here",
    "name": "HERE",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "地图与定位平台强挑战者（汽车/物流场景）。",
    "searchKeywords": [
      "here",
      "here maps",
      "maps",
      "地图",
      "定位"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "usage 计量无账单金额币种，无法作为账单 SoT。"
  },
  {
    "key": "bluerocktel",
    "name": "BlueRockTel",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "小众电信/语音 API 供应商。",
    "searchKeywords": [
      "bluerocktel",
      "telecom",
      "voice"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "账单金额缺币种，无法作为账单 SoT。"
  },
  {
    "key": "ucloud",
    "name": "UCloud",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "中国公有云第二梯队常见选项。",
    "searchKeywords": [
      "ucloud",
      "优刻得",
      "云主机"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "ListUBillDetail 金额缺可用币种/形态，无法作为账单 SoT。"
  },
  {
    "key": "qingcloud",
    "name": "QingCloud",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "青云公有云/混合云区域性选手。",
    "searchKeywords": [
      "qingcloud",
      "青云",
      "云"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "GetChargeSums 金额缺币种，无法作为账单 SoT。"
  },
  {
    "key": "ctyun",
    "name": "CTYun",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "中国电信天翼云，国内政企常见短名单。",
    "searchKeywords": [
      "ctyun",
      "天翼云",
      "中国电信"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "账单明细缺稳定币种字段，无法作为账单 SoT。"
  },
  {
    "key": "ecloud",
    "name": "China Mobile eCloud",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "中国移动云，政企采购常见选项。",
    "searchKeywords": [
      "ecloud",
      "移动云",
      "china mobile",
      "中国移动"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "账单接口缺币种或非标准金额合计，无法作为账单 SoT。"
  },
  {
    "key": "zenlayer",
    "name": "Zenlayer",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "边缘云/跨国互联中型选手。",
    "searchKeywords": [
      "zenlayer",
      "edge",
      "cdn",
      "边缘"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "账单金额缺币种，无法作为账单 SoT。"
  },
  {
    "key": "selectel",
    "name": "Selectel",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "俄语区云与机柜区域龙头之一。",
    "searchKeywords": [
      "selectel",
      "russia",
      "vps",
      "cloud"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "stats/账单金额缺币种，无法作为账单 SoT。"
  },
  {
    "key": "storyblok",
    "name": "Storyblok",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "头less CMS 强挑战者。",
    "searchKeywords": [
      "storyblok",
      "cms",
      "headless"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "invoices 币种未文档化/不稳定，无法作为账单 SoT。"
  },
  {
    "key": "elasticemail",
    "name": "Elastic Email",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "交易/营销邮件中小厂商。",
    "searchKeywords": [
      "elastic email",
      "email",
      "smtp",
      "邮件"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "LoadPaymentHistory 缺币种，无法作为账单 SoT。"
  },
  {
    "key": "baiducloud",
    "name": "Baidu AI Cloud",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "百度智能云，国内 AI/云采购短名单。",
    "searchKeywords": [
      "baidu",
      "百度云",
      "智能云",
      "ai"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "finance 账单接口缺稳定币种/金额形态，无法作为账单 SoT。"
  },
  {
    "key": "jdcloud",
    "name": "JD Cloud",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "京东云，国内电商/政企场景常见选项。",
    "searchKeywords": [
      "jd cloud",
      "京东云"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "bill summary 缺币种，无法作为账单 SoT。"
  },
  {
    "key": "apivideo",
    "name": "api.video",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "视频 API 中小厂商。",
    "searchKeywords": [
      "api.video",
      "video",
      "视频"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅分钟等用量单位，无账单金额币种，无法作为账单 SoT。"
  },
  {
    "key": "bitmovin",
    "name": "Bitmovin",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "视频编码/播放企业向中型选手。",
    "searchKeywords": [
      "bitmovin",
      "encoding",
      "video",
      "编码"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅 GB 等用量，无账单金额币种，无法作为账单 SoT。"
  },
  {
    "key": "airtable",
    "name": "Airtable",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "低代码表格/业务库市场默认短名单。",
    "searchKeywords": [
      "airtable",
      "spreadsheet",
      "表格"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票/金额 API。"
  },
  {
    "key": "clickup",
    "name": "ClickUp",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "全能项目管理强挑战者。",
    "searchKeywords": [
      "clickup",
      "project",
      "项目管理"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "asana",
    "name": "Asana",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "项目管理企业采购默认选项之一。",
    "searchKeywords": [
      "asana",
      "work management",
      "项目管理"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "zendesk",
    "name": "Zendesk",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "客服/工单市场近乎默认选项。",
    "searchKeywords": [
      "zendesk",
      "support",
      "客服",
      "工单"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台/伙伴门户账单，没有公开买家发票金额 API。"
  },
  {
    "key": "customerio",
    "name": "Customer.io",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "产品导向消息自动化强挑战者。",
    "searchKeywords": [
      "customer.io",
      "customerio",
      "messaging",
      "营销自动化"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "activecampaign",
    "name": "ActiveCampaign",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "营销自动化强挑战者。",
    "searchKeywords": [
      "activecampaign",
      "marketing",
      "营销自动化"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "canva",
    "name": "Canva",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "设计 SaaS 大众市场绝对龙头。",
    "searchKeywords": [
      "canva",
      "design",
      "设计"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台订阅账单，没有公开买家发票 API。"
  },
  {
    "key": "hostinger",
    "name": "Hostinger",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "大众主机/VPS 高销量挑战者。",
    "searchKeywords": [
      "hostinger",
      "hosting",
      "vps",
      "主机"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "kakaocloud",
    "name": "Kakao Cloud",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "韩国公有云区域性选项。",
    "searchKeywords": [
      "kakao cloud",
      "카카오",
      "韩国云"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "mercari",
    "name": "Mercari",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "日本二手电商平台；开发者计费非核心账单场景。",
    "searchKeywords": [
      "mercari",
      "メルカリ",
      "marketplace"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开买家账单/发票 API。"
  },
  {
    "key": "linedevelopers",
    "name": "LINE Developers",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "日本/东南亚即时通讯平台消息 API 龙头。",
    "searchKeywords": [
      "line",
      "line developers",
      "messaging",
      "ライン"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "billing 仅控制台，没有公开买家发票金额 API。"
  },
  {
    "key": "cybozu",
    "name": "Cybozu / kintone",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "日本业务应用/kintone 低代码区域龙头。",
    "searchKeywords": [
      "cybozu",
      "kintone",
      "キントーン",
      "低コード"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "onepassword",
    "name": "1Password",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "团队密码管理企业采购默认短名单。",
    "searchKeywords": [
      "1password",
      "onepassword",
      "password",
      "密码"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "Business 账单仅控制台，没有公开买家发票 API。"
  },
  {
    "key": "lastpass",
    "name": "LastPass",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "密码管理老牌挑战者。",
    "searchKeywords": [
      "lastpass",
      "password",
      "密码"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "duo",
    "name": "Duo",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "Cisco 旗下 MFA，企业采购常见默认项。",
    "searchKeywords": [
      "duo",
      "duo security",
      "mfa",
      "cisco"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台/伙伴门户账单，没有公开买家发票 API。"
  },
  {
    "key": "aftership",
    "name": "AfterShip",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "物流追踪 SaaS 强挑战者。",
    "searchKeywords": [
      "aftership",
      "tracking",
      "物流追踪"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "dhl",
    "name": "DHL",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "国际快递默认短名单。",
    "searchKeywords": [
      "dhl",
      "express",
      "shipping",
      "快递"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "买家账单走门户/EDI，没有可用的公开发票金额 API。"
  },
  {
    "key": "fedex",
    "name": "FedEx",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "国际快递默认短名单。",
    "searchKeywords": [
      "fedex",
      "shipping",
      "快递"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "Billing 走门户，没有公开买家发票金额 HTTP API。"
  },
  {
    "key": "ups",
    "name": "UPS",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "国际快递默认短名单。",
    "searchKeywords": [
      "ups",
      "ups billing",
      "shipping",
      "快递"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "UPS Billing 仅门户，没有公开买家发票金额 API。"
  },
  {
    "key": "royalmail",
    "name": "Royal Mail",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "英国邮政寄递默认选项。",
    "searchKeywords": [
      "royal mail",
      "uk post",
      "shipping"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅门户账单，没有公开买家发票金额 API。"
  },
  {
    "key": "parcel2go",
    "name": "Parcel2Go",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "英国包裹比价寄递聚合中小厂商。",
    "searchKeywords": [
      "parcel2go",
      "parcel",
      "uk shipping"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅门户/账户账单，没有公开买家发票 API。"
  },
  {
    "key": "dpd",
    "name": "DPD",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "欧洲包裹寄递强品牌。",
    "searchKeywords": [
      "dpd",
      "shipping",
      "parcel",
      "快递"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅门户账单，没有公开买家发票金额 API。"
  },
  {
    "key": "gls",
    "name": "GLS",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "欧洲陆运包裹强品牌。",
    "searchKeywords": [
      "gls",
      "shipping",
      "parcel"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅门户账单，没有公开买家发票金额 API。"
  },
  {
    "key": "appdynamics",
    "name": "AppDynamics",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "Cisco 旗下 APM 企业默认短名单。",
    "searchKeywords": [
      "appdynamics",
      "apm",
      "cisco"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台/Cisco 商务门户，没有公开买家发票 API。"
  },
  {
    "key": "infomaniak",
    "name": "Infomaniak",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "瑞士主机/云区域性选手。",
    "searchKeywords": [
      "infomaniak",
      "swiss",
      "hosting",
      "cloud"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "公开 schema 不足以构成买家期间账单金额 API。"
  },
  {
    "key": "webdock",
    "name": "Webdock",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "丹麦 VPS 小众主机商。",
    "searchKeywords": [
      "webdock",
      "vps",
      "denmark"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "cubbit",
    "name": "Cubbit",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "分布式对象存储早期选手。",
    "searchKeywords": [
      "cubbit",
      "storage",
      "s3",
      "对象存储"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "beehiiv",
    "name": "Beehiiv",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "创作者 Newsletter 强挑战者。",
    "searchKeywords": [
      "beehiiv",
      "newsletter",
      "email",
      "邮件"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "packiyo",
    "name": "Packiyo",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "履约/仓储小众 SaaS。",
    "searchKeywords": [
      "packiyo",
      "fulfillment",
      "wms"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "greenely",
    "name": "Greenely",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "北欧家庭能源管理细分选手。",
    "searchKeywords": [
      "greenely",
      "energy",
      "sweden",
      "电力"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台/App 账单，没有公开买家发票 API。"
  },
  {
    "key": "gorgias",
    "name": "Gorgias",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "电商客服台强挑战者。",
    "searchKeywords": [
      "gorgias",
      "helpdesk",
      "shopify",
      "客服"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "jwplayer",
    "name": "JW Player",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "企业视频播放/托管老牌挑战者。",
    "searchKeywords": [
      "jw player",
      "jwplayer",
      "video",
      "视频"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "cachefly",
    "name": "CacheFly",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "CDN 中型选手。",
    "searchKeywords": [
      "cachefly",
      "cdn"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "cherryservers",
    "name": "Cherry Servers",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "欧洲裸金属/云主机中小厂商。",
    "searchKeywords": [
      "cherry servers",
      "bare metal",
      "裸金属"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "sav",
    "name": "Sav.com",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "域名注册小众商。",
    "searchKeywords": [
      "sav.com",
      "sav",
      "domains",
      "域名"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台余额/账单，没有公开买家发票 API。"
  },
  {
    "key": "hover",
    "name": "Hover",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "域名注册友好型中小品牌。",
    "searchKeywords": [
      "hover",
      "domains",
      "域名"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "epik",
    "name": "Epik",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "域名注册小众商。",
    "searchKeywords": [
      "epik",
      "domains",
      "域名"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "eurodns",
    "name": "EuroDNS",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "欧洲域名/DNS 区域性厂商。",
    "searchKeywords": [
      "eurodns",
      "domains",
      "dns",
      "域名"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "mezmo",
    "name": "Mezmo",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "日志管道（原 LogDNA）中型选手。",
    "searchKeywords": [
      "mezmo",
      "logdna",
      "logs",
      "日志"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "chronosphere",
    "name": "Chronosphere",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "大规模可观测性（Prometheus/持久化）强挑战者。",
    "searchKeywords": [
      "chronosphere",
      "prometheus",
      "observability",
      "可观测"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "highlight",
    "name": "Highlight.io",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "会话回放+观测一体化早期挑战者。",
    "searchKeywords": [
      "highlight.io",
      "highlight",
      "session replay"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "ultahost",
    "name": "Ultahost",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "大众主机小众品牌。",
    "searchKeywords": [
      "ultahost",
      "hosting",
      "vps"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "hostpresto",
    "name": "HostPresto",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "英国主机小众商。",
    "searchKeywords": [
      "hostpresto",
      "hosting",
      "uk"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "whiplash",
    "name": "Whiplash",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "履约物流（Radial 体系）中型选手。",
    "searchKeywords": [
      "whiplash",
      "fulfillment",
      "radial",
      "履约"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台/门户账单，没有公开买家发票 API。"
  },
  {
    "key": "customcat",
    "name": "CustomCat",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "印花 POD 履约中型选手。",
    "searchKeywords": [
      "customcat",
      "pod",
      "print on demand",
      "印花"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台/门户账单，没有公开买家发票 API。"
  },
  {
    "key": "printedmint",
    "name": "PrintedMint",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "POD 履约小众品牌。",
    "searchKeywords": [
      "printedmint",
      "pod",
      "print on demand"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "shineon",
    "name": "ShineOn",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "饰品 POD 履约小众品牌。",
    "searchKeywords": [
      "shineon",
      "pod",
      "jewelry"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "eneco",
    "name": "Eneco",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "荷兰能源零售区域龙头之一。",
    "searchKeywords": [
      "eneco",
      "energy",
      "netherlands",
      "电力",
      "天然气"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅门户/App 账单，没有公开买家发票金额 API。"
  },
  {
    "key": "locaweb",
    "name": "Locaweb",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "巴西主机/云区域龙头之一。",
    "searchKeywords": [
      "locaweb",
      "brazil",
      "hosting"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "termina",
    "name": "Termina",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "GPU/算力小众供应商。",
    "searchKeywords": [
      "termina",
      "gpu",
      "compute"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "withflex",
    "name": "Flex (withflex)",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "PSP/嵌入式支付小众方案。",
    "searchKeywords": [
      "withflex",
      "flex",
      "psp",
      "payments"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "属 PSP 类/卖家侧形态，没有可用的买家期间账单 API。"
  },
  {
    "key": "requestfinance",
    "name": "Request Finance",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "加密/法币应付账款工具中小厂商。",
    "searchKeywords": [
      "request.finance",
      "request finance",
      "crypto",
      "ap"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "产品形态是应付/开票工具，不是买家云账单 SoT。"
  },
  {
    "key": "extensiv",
    "name": "Extensiv",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "多渠道履约/仓储中型选手。",
    "searchKeywords": [
      "extensiv",
      "fulfillment",
      "wms"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "公开 API 账单为空/不可用，仅门户。"
  },
  {
    "key": "packlink",
    "name": "Packlink",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "欧洲寄递聚合平台。",
    "searchKeywords": [
      "packlink",
      "shipping",
      "parcel"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台/门户账单，没有公开买家发票金额 API。"
  },
  {
    "key": "shippingbo",
    "name": "Shippingbo",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "法语区电商物流 OMS 小众商。",
    "searchKeywords": [
      "shippingbo",
      "oms",
      "shipping",
      "france"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "boxtal",
    "name": "Boxtal",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "法国寄递比价/聚合中型选手。",
    "searchKeywords": [
      "boxtal",
      "shipping",
      "france"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "myparcel",
    "name": "MyParcel",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "荷比卢寄递 API 区域选手。",
    "searchKeywords": [
      "myparcel",
      "shipping",
      "netherlands"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "账单以 PDF/门户为主，没有可用的公开金额 JSON API。"
  },
  {
    "key": "webshipper",
    "name": "Webshipper",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "北欧电商物流小众商。",
    "searchKeywords": [
      "webshipper",
      "shipping",
      "denmark"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "coolrunner",
    "name": "Coolrunner",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "丹麦寄递聚合小众商。",
    "searchKeywords": [
      "coolrunner",
      "shipping",
      "denmark"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "billbee",
    "name": "Billbee",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "德语区电商 ERP/开票卖家工具。",
    "searchKeywords": [
      "billbee",
      "erp",
      "invoicing",
      "卖家"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "卖家开票/ERP 形态，不是买家云账单 SoT。"
  },
  {
    "key": "beam",
    "name": "Beam",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "无服务器 GPU 推理中型挑战者。",
    "searchKeywords": [
      "beam.cloud",
      "beam",
      "gpu",
      "serverless"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票金额 API。"
  },
  {
    "key": "inferless",
    "name": "Inferless",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "模型部署小众平台。",
    "searchKeywords": [
      "inferless",
      "inference",
      "gpu"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "fluidstack",
    "name": "Fluidstack",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "分布式 GPU 云中型选手。",
    "searchKeywords": [
      "fluidstack",
      "gpu",
      "cloud"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "shadeform",
    "name": "Shadeform",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "GPU 云聚合小众平台。",
    "searchKeywords": [
      "shadeform",
      "gpu"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "thundercompute",
    "name": "Thunder Compute",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "低价 GPU 云早期选手。",
    "searchKeywords": [
      "thunder compute",
      "thundercompute",
      "gpu"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "tensordock",
    "name": "TensorDock",
    "kind": "prepaid",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "社区 GPU 云中型选手。",
    "searchKeywords": [
      "tensordock",
      "gpu",
      "prepaid",
      "预付费"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "预付费余额模型，不是期间买家发票 SoT。"
  },
  {
    "key": "anyscale",
    "name": "Anyscale",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "Ray 商业化平台，企业 AI 基础设施短名单。",
    "searchKeywords": [
      "anyscale",
      "ray",
      "ai"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票金额 API。"
  },
  {
    "key": "ai21",
    "name": "AI21",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "大模型实验室强挑战者。",
    "searchKeywords": [
      "ai21",
      "jurassic",
      "llm"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "sambanova",
    "name": "SambaNova",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "企业 AI 芯片/云推断短名单挑战者。",
    "searchKeywords": [
      "sambanova",
      "ai",
      "inference"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台/销售门户账单，没有公开买家发票 API。"
  },
  {
    "key": "wandb",
    "name": "Weights & Biases",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "MLOps 实验追踪近乎默认选项。",
    "searchKeywords": [
      "wandb",
      "weights and biases",
      "mlops"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "clarifai",
    "name": "Clarifai",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "计算机视觉 API 老牌中型选手。",
    "searchKeywords": [
      "clarifai",
      "vision",
      "ai",
      "视觉"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "easydns",
    "name": "EasyDNS",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "域名/DNS 老牌中小厂商。",
    "searchKeywords": [
      "easydns",
      "dns",
      "domains",
      "域名"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "binero",
    "name": "Binero",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "瑞典云/主机小众商。",
    "searchKeywords": [
      "binero",
      "sweden",
      "cloud",
      "hosting"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "dogado",
    "name": "dogado",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "德语区主机区域性厂商。",
    "searchKeywords": [
      "dogado",
      "hosting",
      "germany"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "monday",
    "name": "Monday.com",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "工作 OS/项目管理大众市场龙头之一。",
    "searchKeywords": [
      "monday.com",
      "monday",
      "workos",
      "项目管理"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "teachable",
    "name": "Teachable",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "创作者课程平台强挑战者。",
    "searchKeywords": [
      "teachable",
      "courses",
      "课程"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "thinkific",
    "name": "Thinkific",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "创作者课程平台强挑战者。",
    "searchKeywords": [
      "thinkific",
      "courses",
      "课程"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "hex",
    "name": "Hex",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "协作式数据分析笔记本强挑战者。",
    "searchKeywords": [
      "hex",
      "hex.tech",
      "analytics",
      "notebook"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "mode",
    "name": "Mode",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "分析/SQL 协作老牌挑战者（Salesforce 体系）。",
    "searchKeywords": [
      "mode analytics",
      "mode",
      "sql"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "sigma",
    "name": "Sigma",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "云数据仓库上的电子表格分析强挑战者。",
    "searchKeywords": [
      "sigma computing",
      "sigma",
      "analytics"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "looker",
    "name": "Looker",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "BI 企业采购默认短名单（Google Cloud）。",
    "searchKeywords": [
      "looker",
      "bi",
      "google",
      "分析"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台/GCP 商务，没有独立买家发票金额 API。"
  },
  {
    "key": "statuspage",
    "name": "Statuspage",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "状态页市场默认选项（Atlassian）。",
    "searchKeywords": [
      "statuspage",
      "status page",
      "atlassian"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台/Atlassian 商务门户，没有公开买家发票 API。"
  },
  {
    "key": "incidentio",
    "name": "incident.io",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "事件响应协作强挑战者。",
    "searchKeywords": [
      "incident.io",
      "incident",
      "oncall",
      "事故"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "rootly",
    "name": "Rootly",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "事件管理中型挑战者。",
    "searchKeywords": [
      "rootly",
      "incident",
      "oncall"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "cloudhealth",
    "name": "CloudHealth",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "云成本管理企业默认短名单（VMware/Broadcom）。",
    "searchKeywords": [
      "cloudhealth",
      "vmware",
      "finops",
      "云成本"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "伙伴/企业门户形态，没有公开买家发票金额 API。"
  },
  {
    "key": "apptio",
    "name": "Apptio",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "IT 财务/FinOps 企业默认短名单（IBM）。",
    "searchKeywords": [
      "apptio",
      "ibm",
      "finops",
      "tbm"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "企业商务/伙伴门户，没有公开买家发票 API。"
  },
  {
    "key": "kubecost",
    "name": "Kubecost",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "Kubernetes 成本可见性强挑战者。",
    "searchKeywords": [
      "kubecost",
      "kubernetes",
      "finops",
      "k8s"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台/许可账单，没有公开买家发票金额 API。"
  },
  {
    "key": "softbankcloud",
    "name": "SoftBank Cloud",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "日本软银云区域性选项。",
    "searchKeywords": [
      "softbank",
      "ソフトバンク",
      "cloud",
      "日本云"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台/企业合同账单，没有公开买家发票 API。"
  },
  {
    "key": "yahoojpcloud",
    "name": "Yahoo! JAPAN Cloud",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "雅虎日本云区域性选项。",
    "searchKeywords": [
      "yahoo japan",
      "yahoo jp cloud",
      "ヤフー"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "nttdocomo",
    "name": "NTT Docomo Bills",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "日本通信运营商账单场景龙头。",
    "searchKeywords": [
      "ntt",
      "docomo",
      "ドコモ",
      "通信费"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "运营商账单仅门户/OAuth 缺可用凭据字段，无法作为产品账单 SoT。"
  },
  {
    "key": "otc",
    "name": "Open Telekom Cloud",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "Deutsche Telekom 公有云区域性选项。",
    "searchKeywords": [
      "otc",
      "open telekom cloud",
      "deutsche telekom",
      "t-systems"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台/企业合同账单，没有公开买家发票金额 API。"
  },
  {
    "key": "statsig",
    "name": "Statsig",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "功能开关/实验平台强挑战者。",
    "searchKeywords": [
      "statsig",
      "feature flags",
      "experiment",
      "实验"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "账单导出以 CSV/控制台为主，没有可用的公开发票金额 API。"
  },
  {
    "key": "noonahq",
    "name": "Noona HQ",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "预约/门店运营小众 SaaS。",
    "searchKeywords": [
      "noona",
      "noona hq",
      "booking",
      "预约"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅控制台账单，没有公开买家发票 API。"
  },
  {
    "key": "googleads",
    "name": "Google Ads",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "数字广告支出绝对龙头。",
    "searchKeywords": [
      "google ads",
      "adwords",
      "广告"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "InvoiceService 需 OAuth，缺产品可用的只读凭据字段模型（HOLD）。"
  },
  {
    "key": "metabusiness",
    "name": "Meta Business Invoices",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "社交广告支出绝对龙头之一。",
    "searchKeywords": [
      "meta",
      "facebook ads",
      "business invoices",
      "广告"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "business_invoices 需 Business/OAuth，缺产品可用凭据字段（HOLD）。"
  },
  {
    "key": "microsoftads",
    "name": "Microsoft Advertising",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "搜索广告第二极。",
    "searchKeywords": [
      "microsoft advertising",
      "bing ads",
      "广告"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "GetBillingDocuments 需 OAuth，缺产品可用凭据字段（HOLD）。"
  },
  {
    "key": "nebius",
    "name": "Nebius",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "GPU 云新兴挑战者。",
    "searchKeywords": [
      "nebius",
      "gpu",
      "focus",
      "cloud"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "FOCUS 导出过重/非即时账单 API，产品模型未覆盖（HOLD）。"
  },
  {
    "key": "temporal",
    "name": "Temporal Cloud",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "工作流引擎托管强挑战者。",
    "searchKeywords": [
      "temporal",
      "workflow",
      "focus"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "FOCUS 导出过重，产品模型未覆盖（HOLD）。"
  },
  {
    "key": "yandexcloud",
    "name": "Yandex Cloud",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "俄语区公有云龙头。",
    "searchKeywords": [
      "yandex cloud",
      "yandex",
      "grpc"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "账单以 gRPC-only 为主，产品 HTTP 接入模型未覆盖（HOLD）。"
  },
  {
    "key": "oracleoci",
    "name": "Oracle Cloud (OCI)",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "企业公有云默认短名单之一。",
    "searchKeywords": [
      "oracle",
      "oci",
      "oracle cloud",
      "rsa"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "OSP/Usage 需 RSA 签名与复杂凭据，产品模型未覆盖（HOLD）。"
  },
  {
    "key": "pliant",
    "name": "Pliant",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "企业卡/支出小众方案。",
    "searchKeywords": [
      "pliant",
      "cards",
      "spend"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "KAM/企业开通流程，没有自助公开买家账单 API（HOLD）。"
  },
  {
    "key": "atlassian",
    "name": "Atlassian Commerce",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "开发者协作套件企业默认短名单。",
    "searchKeywords": [
      "atlassian",
      "jira",
      "confluence",
      "commerce"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "Commerce 以伙伴/组织门户为主，缺产品可用的自助买家发票 API（HOLD）。"
  },
  {
    "key": "bandwidth",
    "name": "Bandwidth",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "企业通信 CPaaS 强挑战者。",
    "searchKeywords": [
      "bandwidth",
      "cpaas",
      "voice",
      "sms"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "异步 BDR 导出过重，产品模型未覆盖（HOLD）。"
  },
  {
    "key": "megaport",
    "name": "Megaport",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "网络互联/云连接强挑战者。",
    "searchKeywords": [
      "megaport",
      "interconnect",
      "network"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "账单 schema 不清晰，无法稳定作为期间金额 SoT（HOLD）。"
  },
  {
    "key": "edf",
    "name": "EDF",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "法国电力零售龙头。",
    "searchKeywords": [
      "edf",
      "electricity",
      "france",
      "电力"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "能源账户 OAuth 缺产品可用凭据字段（HOLD）。"
  },
  {
    "key": "eonnext",
    "name": "E.ON Next",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "英国能源零售（E.ON）常见选项。",
    "searchKeywords": [
      "e.on next",
      "eon next",
      "kraken",
      "energy",
      "电力"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "Kraken OAuth 缺产品可用凭据字段（HOLD）。"
  },
  {
    "key": "engie",
    "name": "Engie",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "欧洲能源零售/公用事业龙头之一。",
    "searchKeywords": [
      "engie",
      "energy",
      "电力",
      "天然气"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "能源账户 OAuth 缺产品可用凭据字段（HOLD）。"
  },
  {
    "key": "vattenfall",
    "name": "Vattenfall",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "北欧/欧洲能源零售龙头之一。",
    "searchKeywords": [
      "vattenfall",
      "energy",
      "电力"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "能源账户 OAuth 缺产品可用凭据字段（HOLD）。"
  },
  {
    "key": "britishgas",
    "name": "British Gas",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "英国能源零售默认短名单。",
    "searchKeywords": [
      "british gas",
      "kraken",
      "energy",
      "电力",
      "天然气"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "Kraken OAuth 缺产品可用凭据字段（HOLD）。"
  },
  {
    "key": "travelperk",
    "name": "TravelPerk",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "商务差旅管理强挑战者。",
    "searchKeywords": [
      "travelperk",
      "travel",
      "差旅"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "差旅报销/费用形态，不是买家云服务期间账单 SoT。"
  },
  {
    "key": "payhawk",
    "name": "Payhawk",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "企业支出卡欧洲中型选手。",
    "searchKeywords": [
      "payhawk",
      "spend",
      "cards",
      "支出"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "企业支出/卡账单形态，不是云服务买家发票 SoT。"
  },
  {
    "key": "moss",
    "name": "Moss",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "欧洲企业支出管理中型选手。",
    "searchKeywords": [
      "moss",
      "spend",
      "支出"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "支出管理形态，不是云服务买家发票 SoT。"
  },
  {
    "key": "soldo",
    "name": "Soldo",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "预付企业卡中型选手。",
    "searchKeywords": [
      "soldo",
      "cards",
      "prepaid",
      "支出"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "预付卡/支出形态，不是云服务买家发票 SoT。"
  },
  {
    "key": "ramp",
    "name": "Ramp",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "美国企业卡/支出管理龙头之一。",
    "searchKeywords": [
      "ramp",
      "spend",
      "cards",
      "支出"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "企业支出卡形态，不是云服务买家发票 SoT。"
  },
  {
    "key": "brex",
    "name": "Brex",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "美国创业公司企业卡默认短名单。",
    "searchKeywords": [
      "brex",
      "cards",
      "spend",
      "支出"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "企业卡/支出形态，不是云服务买家发票 SoT。"
  },
  {
    "key": "hubspot",
    "name": "HubSpot CRM Invoices",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "CRM/营销套件大众市场龙头。",
    "searchKeywords": [
      "hubspot",
      "crm",
      "invoices",
      "卖家开票"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "CRM 开票属卖家 AR，不是买家云账单 SoT。"
  },
  {
    "key": "shopifypartner",
    "name": "Shopify Partner Billing",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "电商平台伙伴生态绝对龙头。",
    "searchKeywords": [
      "shopify",
      "partner billing",
      "partners",
      "卖家"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "Partner Billing 属卖家/伙伴分成，不是买家云账单 SoT。"
  },
  {
    "key": "bigcommerce",
    "name": "BigCommerce Unified Billing",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "电商平台强挑战者。",
    "searchKeywords": [
      "bigcommerce",
      "ecommerce",
      "卖家"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "Unified Billing 属平台/卖家侧，不是买家云账单 SoT。"
  },
  {
    "key": "salesforce",
    "name": "Salesforce Revenue Cloud",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "企业 CRM 绝对龙头。",
    "searchKeywords": [
      "salesforce",
      "revenue cloud",
      "crm",
      "卖家"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "Revenue Cloud 属卖家收入/开票，不是买家云账单 SoT。"
  },
  {
    "key": "servicenow",
    "name": "ServiceNow AP Invoice",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "企业 ITSM 绝对龙头。",
    "searchKeywords": [
      "servicenow",
      "ap invoice",
      "itsm"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "AP Invoice 属应付/采购发票，不是云服务买家用量账单 SoT。"
  },
  {
    "key": "workday",
    "name": "Workday",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "企业 HCM/财务默认短名单。",
    "searchKeywords": [
      "workday",
      "hcm",
      "finance"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "财务/应付形态，不是云服务买家用量账单 SoT。"
  },
  {
    "key": "rippling",
    "name": "Rippling Bill Pay",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "HR/IT 一体化强挑战者。",
    "searchKeywords": [
      "rippling",
      "bill pay",
      "hr"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "Bill Pay 属应付付款，不是云服务买家账单 SoT。"
  },
  {
    "key": "gusto",
    "name": "Gusto Embedded",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "美国中小企业薪资默认短名单之一。",
    "searchKeywords": [
      "gusto",
      "payroll",
      "embedded",
      "薪资"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "Embedded 薪资/卖家侧嵌入，不是买家云账单 SoT。"
  },
  {
    "key": "wefact",
    "name": "WeFact",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "荷兰开票/会计中小工具。",
    "searchKeywords": [
      "wefact",
      "invoicing",
      "netherlands",
      "卖家开票"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "卖家开票工具，不是买家云账单 SoT。"
  },
  {
    "key": "lago",
    "name": "Lago",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "开源用量计费引擎中型选手。",
    "searchKeywords": [
      "lago",
      "billing",
      "usage metering",
      "卖家计费"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "卖家计费引擎，不是买家云账单 SoT。"
  },
  {
    "key": "factuarea",
    "name": "Factuarea",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "开票小众工具。",
    "searchKeywords": [
      "factuarea",
      "invoicing",
      "卖家开票"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "卖家开票工具，不是买家云账单 SoT。"
  },
  {
    "key": "spaceinvoices",
    "name": "Space Invoices",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "开票 API 小众工具。",
    "searchKeywords": [
      "space invoices",
      "invoicing",
      "卖家开票"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "卖家开票 API，不是买家云账单 SoT。"
  },
  {
    "key": "beel",
    "name": "Beel",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "开票/财务小众工具。",
    "searchKeywords": [
      "beel",
      "invoicing",
      "卖家开票"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "卖家开票形态，不是买家云账单 SoT。"
  },
  {
    "key": "invoiced",
    "name": "Invoiced",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "应收开票自动化中型选手。",
    "searchKeywords": [
      "invoiced",
      "ar",
      "invoicing",
      "卖家开票"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "卖家 AR 开票，不是买家云账单 SoT。"
  },
  {
    "key": "moneybird",
    "name": "Moneybird",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "荷兰中小会计/开票常见选项。",
    "searchKeywords": [
      "moneybird",
      "accounting",
      "netherlands",
      "卖家开票"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "卖家会计开票，不是买家云账单 SoT。"
  },
  {
    "key": "economic",
    "name": "e-conomic",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "丹麦中小会计常见选项（Visma）。",
    "searchKeywords": [
      "e-conomic",
      "economic",
      "visma",
      "accounting",
      "卖家开票"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "卖家会计开票，不是买家云账单 SoT。"
  },
  {
    "key": "tripletex",
    "name": "Tripletex",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "挪威中小会计常见选项。",
    "searchKeywords": [
      "tripletex",
      "accounting",
      "norway",
      "卖家开票"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "卖家会计开票，不是买家云账单 SoT。"
  },
  {
    "key": "fortnox",
    "name": "Fortnox",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "瑞典中小会计龙头之一。",
    "searchKeywords": [
      "fortnox",
      "accounting",
      "sweden",
      "卖家开票"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "卖家会计开票，不是买家云账单 SoT。"
  },
  {
    "key": "visma",
    "name": "Visma",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "北欧企业财务/ERP 默认短名单。",
    "searchKeywords": [
      "visma",
      "erp",
      "accounting",
      "卖家开票"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "卖家 ERP/开票，不是买家云账单 SoT。"
  },
  {
    "key": "fyatu",
    "name": "Fyatu",
    "kind": "prepaid",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "预付通信/虚拟号码小众商。",
    "searchKeywords": [
      "fyatu",
      "prepaid",
      "sms",
      "预付费"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "预付费余额模型，不是期间买家发票 SoT。"
  },
  {
    "key": "smsglobal",
    "name": "SMSGlobal",
    "kind": "prepaid",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "短信网关中小厂商。",
    "searchKeywords": [
      "smsglobal",
      "sms",
      "prepaid"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "预付费/卖家侧余额形态，不是期间买家发票 SoT。"
  },
  {
    "key": "burstsms",
    "name": "BurstSMS",
    "kind": "prepaid",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 3,
    "marketTierReason": "短信网关中小厂商（Transmitsms）。",
    "searchKeywords": [
      "burstsms",
      "transmit sms",
      "sms",
      "prepaid"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "预付费余额模型，不是期间买家发票 SoT。"
  },
  {
    "key": "serverspace",
    "name": "Serverspace",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "国际 VPS 小众云商。",
    "searchKeywords": [
      "serverspace",
      "vps",
      "cloud"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "公开能力偏卖家/控制台，缺少可用买家期间发票 API。"
  },
  {
    "key": "tilaa",
    "name": "Tilaa",
    "kind": "usage",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 4,
    "marketTierReason": "荷兰 VPS 小众商。",
    "searchKeywords": [
      "tilaa",
      "vps",
      "netherlands"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "公开能力不足以构成买家期间发票 SoT。"
  },
  {
    "key": "qonto",
    "name": "Qonto",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "欧洲新银行/商务账户强挑战者。",
    "searchKeywords": [
      "qonto",
      "banking",
      "neobank",
      "标价"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "subscription list 仅标价，不是已发生买家账单合计。"
  },
  {
    "key": "factorial",
    "name": "Factorial",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "欧洲 HR 软件强挑战者。",
    "searchKeywords": [
      "factorial",
      "hr",
      "expense",
      "报销"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "费用/HR 报销形态，不是云服务买家账单 SoT。"
  },
  {
    "key": "personio",
    "name": "Personio",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "欧洲 HR 软件强挑战者。",
    "searchKeywords": [
      "personio",
      "hr",
      "expense",
      "报销"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "费用/HR 报销形态，不是云服务买家账单 SoT。"
  },
  {
    "key": "pandadoc",
    "name": "PandaDoc",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "提案/电子签强挑战者。",
    "searchKeywords": [
      "pandadoc",
      "esign",
      "proposals",
      "电子签"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅门户账单，没有公开买家发票金额 API。"
  },
  {
    "key": "dropboxsign",
    "name": "Dropbox Sign",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "电子签名默认短名单之一（原 HelloSign）。",
    "searchKeywords": [
      "dropbox sign",
      "hellosign",
      "esign",
      "电子签"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "仅门户账单，没有公开买家发票金额 API。"
  },
  {
    "key": "adobevip",
    "name": "Adobe VIP",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 1,
    "marketTierReason": "创意软件企业采购默认短名单。",
    "searchKeywords": [
      "adobe",
      "vip",
      "creative cloud",
      "伙伴门户"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "VIP 伙伴门户许可，不是自助买家云账单 API。"
  },
  {
    "key": "spendesk",
    "name": "Spendesk",
    "kind": "subscription",
    "status": "declined",
    "inbox": false,
    "costsMoneyToRefresh": false,
    "supportsDailyGranularity": false,
    "historyLookbackMonths": 0,
    "minimumRefreshInterval": 0,
    "marketTier": 2,
    "marketTierReason": "欧洲企业支出管理强挑战者。",
    "searchKeywords": [
      "spendesk",
      "spend",
      "expense",
      "支出"
    ],
    "fields": [],
    "steps": [],
    "troubleshooting": [],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "企业支出管理形态，不是云服务买家发票 SoT。"
  }
];

export const catalogByKey: Readonly<Record<string, CatalogEntry>> = Object.fromEntries(catalogEntries.map((item) => [item.key, item]));
