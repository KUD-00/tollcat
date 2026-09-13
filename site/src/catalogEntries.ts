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
    "status": "available",
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
    "status": "available",
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
    "status": "available",
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
        "zh": "打开 Together AI 的 API keys 页，点 Create key，起个名字，立刻复制。新 key 只显示一次。",
        "en": "Open the Together AI API keys page, tap Create key, give it a name, and copy it immediately. New keys are shown only once.",
        "ja": "Together AI の API keys ページを開き、Create key をタップして名前を付け、すぐにコピーします。新しい key は一度しか表示されません。"
      },
      {
        "zh": "没有按账单只读的 scope。这把 key 能调推理也能读用量，请当密码保管。",
        "en": "There is no billing-read-only scope. This key can run inference and read usage, so treat it like a password.",
        "ja": "請求の読み取り専用 scope はありません。この key は推論も用量も読めるので、パスワードと同じ扱いにしてください。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙无效，或者已经被撤销了。",
          "en": "This key is invalid, or it has already been revoked.",
          "ja": "このキーは無効か、すでに取り消されています。"
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
          "zh": "这把 key 读不到组织用量。",
          "en": "This key cannot read organization usage.",
          "ja": "この key では組織の用量を読めません。"
        },
        "nextStep": {
          "zh": "回上一步在付账那个项目里重新 Create key。",
          "en": "Go back a step and Create key again in the paying project.",
          "ja": "前の手順に戻り、支払いプロジェクトで Create key し直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://api.together.ai/settings/billing",
    "credentialSetupURL": "https://api.together.ai/settings/projects/~current/api-keys",
    "summary": {
      "zh": "开源模型推理。按本月组织用量花费。",
      "en": "Open-source model inference. This month’s organization usage spend.",
      "ja": "オープンソースモデルの推論。今月の組織用量支出です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月组织用量花费一致。",
      "en": "This number should match this month’s organization usage spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の組織用量支出と一致するはずです。"
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
        "zh": "打开 CockroachDB Cloud 的 Service Accounts，新建一个服务账号。创建后签发一把 secret key，立刻复制。",
        "en": "Open Service Accounts in CockroachDB Cloud and create a service account. After creating it, issue a secret key and copy it right away.",
        "ja": "CockroachDB Cloud の Service Accounts を開き、サービスアカウントを新規作成します。作成したら secret key を発行し、すぐにコピーします。"
      },
      {
        "zh": "给这个账号 Edit Roles：Scope 选 Organization，Role 选 Billing Coordinator。",
        "en": "Edit Roles for this account: set Scope to Organization and Role to Billing Coordinator.",
        "ja": "このアカウントで Edit Roles：Scope は Organization、Role は Billing Coordinator にします。"
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
          "zh": "回 Service Accounts 给这个账号 Edit Roles：Scope 选 Organization，Role 选 Billing Coordinator。",
          "en": "Go back to Service Accounts and Edit Roles for this account: Scope Organization, Role Billing Coordinator.",
          "ja": "Service Accounts に戻り、このアカウントで Edit Roles：Scope は Organization、Role は Billing Coordinator にします。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://cockroachlabs.cloud",
    "credentialSetupURL": "https://cockroachlabs.cloud/service-accounts",
    "summary": {
      "zh": "托管数据库。按本周期草稿发票。免费期间没有发票，读数是 $0。",
      "en": "A managed database. The draft invoice for this cycle. During the free period there are no invoices, so the reading is $0.",
      "ja": "マネージドデータベース。本周期の下書きインボイスです。無料期間はインボイスがなく、読み取りは $0 です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 CockroachDB Cloud 本周期草稿发票合计一致。免费期间没有发票，会显示 $0。",
      "en": "This number should match the draft invoice total for this cycle on CockroachDB Cloud. During the free period there are no invoices, so it shows $0.",
      "ja": "この数字は CockroachDB Cloud の本周期下書きインボイス合計と一致するはずです。無料期間はインボイスがなく、$0 と表示されます。"
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
        "zh": "打开 Gcore Customer Portal：右上角头像 → Profile → API tokens，点 Create token。",
        "en": "In the Gcore Customer Portal, open the top-right avatar → Profile → API tokens, then tap Create token.",
        "ja": "Gcore Customer Portal で右上のアバター → Profile → API tokens を開き、Create token をタップします。"
      },
      {
        "zh": "填 Name。Expiration 可选 Never expire。Cloud 和 Billing 的角色至少给只读，且不能高于你自己的角色。点 Create，立刻复制，再点 OK, I’ve copied token。系统不存明文。",
        "en": "Fill in Name. Expiration may be Never expire. Give Cloud and Billing at least a read role, no higher than your own. Tap Create, copy immediately, then OK, I’ve copied token. Gcore does not store the plaintext.",
        "ja": "Name を入れます。Expiration は Never expire でも構いません。Cloud と Billing は少なくとも読み取りで、自分の役割より上にはできません。Create をタップしてすぐにコピーし、OK, I’ve copied token を押します。平文は保存されません。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙无效，或者已经被撤销了。",
          "en": "This key is invalid, or it has already been revoked.",
          "ja": "このキーは無効か、すでに取り消されています。"
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
          "zh": "这把 token 的 Billing 角色不够，读不到成本报告。",
          "en": "This token’s Billing role is too low to read the cost report.",
          "ja": "この token の Billing ロールが足りず、コスト報告を読めません。"
        },
        "nextStep": {
          "zh": "回上一步，给 Billing 至少只读后再签发。",
          "en": "Go back a step and issue another token with at least read on Billing.",
          "ja": "前の手順に戻り、Billing を少なくとも読み取りにして発行し直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://gcore.com/cloud",
    "credentialSetupURL": "https://docs.gcore.com/account-settings/api-tokens",
    "summary": {
      "zh": "CDN、边缘和 GPU 云。按月度成本报告，含包月和按量。",
      "en": "CDN, edge, and GPU cloud. The monthly cost report, including commit and pay-as-you-go.",
      "ja": "CDN、エッジ、GPU クラウド。月次コスト報告で、コミットと従量を含みます。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月成本报告一致。",
      "en": "This number should match this month’s cost report in the dashboard.",
      "ja": "この数字はダッシュボードの今月のコスト報告と一致するはずです。"
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
        "zh": "打开 Northflank 的 API Tokens 页（Team Settings → API → Tokens），点 Create API Token。",
        "en": "Open API Tokens in Northflank (Team Settings → API → Tokens), then tap Create API Token.",
        "ja": "Northflank の API Tokens（Team Settings → API → Tokens）を開き、Create API Token をタップします。"
      },
      {
        "zh": "选一个带 Account · Billing · General · Read 的 RBAC 角色（权限跟角色走，不跟单把 token）。立刻复制，只显示一次。",
        "en": "Pick an RBAC role that includes Account · Billing · General · Read. Permissions follow the role, not the token. Copy immediately; it is shown only once.",
        "ja": "Account · Billing · General · Read を含む RBAC ロールを選びます。権限はロール側で、token 単体ではありません。すぐにコピー。表示は一度だけです。"
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
          "zh": "这个 token 的角色没有 Account · Billing · General · Read，所以列不出发票。",
          "en": "This token’s role is missing Account · Billing · General · Read, so invoices cannot be listed.",
          "ja": "この token のロールに Account · Billing · General · Read が無く、インボイスを列挙できません。"
        },
        "nextStep": {
          "zh": "回上一步，换一个带账单读取权限的 RBAC 角色再签发。",
          "en": "Go back a step and issue another token from an RBAC role that can read billing.",
          "ja": "前の手順に戻り、請求の読み取りができる RBAC ロールで発行し直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://app.northflank.com/",
    "credentialSetupURL": "https://app.northflank.com/s/account/api/tokens",
    "summary": {
      "zh": "微服务和 BYOC 托管。按本月已出账发票合计。",
      "en": "Microservices and BYOC hosting. This month’s issued invoices, summed.",
      "ja": "マイクロサービスと BYOC ホスティング。今月の出帳済みインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月已出账发票一致。",
      "en": "This number should match this month’s issued invoices in the dashboard.",
      "ja": "この数字はダッシュボードの今月の出帳済みインボイスと一致するはずです。"
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
        "zh": "Klaviyo 没有公开账单金额接口，向导连上了也不会出现本月花费。若仍要签发一把 Private API Key：打开 Settings 的 API keys 页（需要 Owner、Admin 或 Manager）。",
        "en": "Klaviyo has no public billed-amount API, so connecting here will not show this month’s spend. If you still want a Private API Key: open Settings → API keys (Owner, Admin, or Manager).",
        "ja": "Klaviyo に公開の請求金額 API は無く、接続しても今月の利用額は出ません。それでも Private API Key を出すなら、Settings の API keys を開きます（Owner / Admin / Manager）。"
      },
      {
        "zh": "在 Private API Keys 点 Create Private API Key。选 Read-Only Key 或 Custom。立刻复制。前缀 pk_。之后再也看不到。",
        "en": "Under Private API Keys, tap Create Private API Key. Choose Read-Only Key or Custom. Copy immediately. It starts with pk_. You cannot view it again.",
        "ja": "Private API Keys で Create Private API Key をタップします。Read-Only Key か Custom を選び、すぐにコピー。接頭辞は pk_。再表示できません。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把 Private API Key 无效，或已被删除。",
          "en": "This Private API Key is invalid, or it has been deleted.",
          "ja": "この Private API Key は無効か、削除されています。"
        },
        "nextStep": {
          "zh": "回上一步重新 Create Private API Key，创建后立刻复制。",
          "en": "Go back a step, Create Private API Key again, and copy it right away.",
          "ja": "前の手順に戻り、Create Private API Key をやり直してすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 key 的 scope 不够。Klaviyo 也没有公开账单金额接口。",
          "en": "This key’s scopes are too narrow. Klaviyo also has no public billed-amount API.",
          "ja": "この key の scope が足りません。Klaviyo に公開の請求金額 API もありません。"
        },
        "nextStep": {
          "zh": "回上一步用 Read-Only Key 重建。即使用上了，这里也读不到账单金额。",
          "en": "Go back a step and recreate a Read-Only Key. Even then, this app cannot read a billed amount.",
          "ja": "前の手順に戻り、Read-Only Key で作り直してください。それでも請求金額は読めません。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "declineReason": "没有公开账单金额接口。",
    "summary": {
      "zh": "电商邮件和短信。没有公开的账单金额接口，这家接不上用量。",
      "en": "Ecommerce email and SMS. There is no public billed-amount API, so this app cannot read usage.",
      "ja": "EC のメールと SMS。公開の請求金額 API は無く、このアプリでは用量を読めません。"
    },
    "verifyHint": {
      "zh": "这家没有公开账单金额接口，连上了也不会出现本月花费。",
      "en": "There is no public billed-amount API, so connecting will not show this month’s spend.",
      "ja": "公開の請求金額 API は無いので、接続しても今月の利用額は出ません。"
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
        "isSecret": true,
        "hint": {
          "zh": "Global API tokens 页",
          "en": "Global API tokens page",
          "ja": "Global API tokens ページ"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Better Stack 的 API tokens，进 Global API tokens。组织级账单用这把，不要用某个 Team 的 Uptime token。",
        "en": "Open API tokens in Better Stack and go to Global API tokens. Use this for org-wide billing — not a team Uptime token.",
        "ja": "Better Stack の API tokens を開き、Global API tokens に入ります。組織の請求にはこちらを使い、Team の Uptime token は使わないでください。"
      },
      {
        "zh": "复制已有的，或新建一把，立刻复制。",
        "en": "Copy an existing token, or create a new one and copy it right away.",
        "ja": "既存の token をコピーするか、新しく作ってすぐにコピーします。"
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
          "zh": "回 Global API tokens 重新复制或新建一把，创建后立刻复制。",
          "en": "Go back to Global API tokens, copy it again or create a new one, and copy it right away.",
          "ja": "Global API tokens に戻り、再コピーするか作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把多半是某个 Team 的 Uptime token，读不到组织账单。",
          "en": "This is probably a team Uptime token, so it can’t read org billing.",
          "ja": "Team の Uptime token の可能性が高く、組織の請求を読めません。"
        },
        "nextStep": {
          "zh": "回上一步改用 Global API tokens 里那把。",
          "en": "Go back a step and use a token from Global API tokens.",
          "ja": "前の手順に戻り、Global API tokens の token を使ってください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://betterstack.com/",
    "credentialSetupURL": "https://betterstack.com/settings/global-api-tokens",
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
        "isSecret": true,
        "hint": {
          "zh": "Account Settings → API Keys 的 Production",
          "en": "Production key on Account Settings → API Keys",
          "ja": "Account Settings → API Keys の Production"
        }
      }
    ],
    "steps": [
      {
        "zh": "先设好 EasyPost Wallet。打开 EasyPost 控制台 Account Settings，切到 API Keys。",
        "en": "Set up the EasyPost Wallet first. Open Account Settings in the EasyPost dashboard and switch to API Keys.",
        "ja": "先に EasyPost Wallet を用意します。EasyPost ダッシュボードの Account Settings を開き、API Keys に切り替えます。"
      },
      {
        "zh": "点 Add Additional API Key，选 Production，立刻复制。不要用 Test。",
        "en": "Tap Add Additional API Key, choose Production, and copy it right away. Don’t use Test.",
        "ja": "Add Additional API Key をタップし、Production を選んですぐにコピーします。Test は使わないでください。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把 API Key 无效，或者已经在控制台里关掉。",
          "en": "This API Key is invalid, or it was already disabled in the dashboard.",
          "ja": "この API Key は無効か、ダッシュボードで無効化済みです。"
        },
        "nextStep": {
          "zh": "回 Account Settings → API Keys 复制 Production 那把，或再签发一把。",
          "en": "Go back to Account Settings → API Keys, copy the Production key, or issue a new one.",
          "ja": "Account Settings → API Keys に戻り、Production をコピーするか、作り直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "多半用了 Test 钥匙，或者钱包还没设好。",
          "en": "You probably used a Test key, or the wallet isn’t set up yet.",
          "ja": "Test キーを使っているか、Wallet がまだです。"
        },
        "nextStep": {
          "zh": "改用 Production，并确认 Wallet 已经开通。",
          "en": "Switch to Production and confirm the Wallet is set up.",
          "ja": "Production に切り替え、Wallet が開通しているか確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://app.easypost.com/account",
    "credentialSetupURL": "https://www.easypost.com/account/settings?tab=api-keys",
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
        "isSecret": true,
        "hint": {
          "zh": "Credentials 页的 Auth Secret",
          "en": "Auth Secret on the Credentials page",
          "ja": "Credentials ページの Auth Secret"
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
          "zh": "Credentials 页的 Auth Key",
          "en": "Auth Key on the Credentials page",
          "ja": "Credentials ページの Auth Key"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Transloadit 控制台的 Credentials 页，复制 Auth Secret。这是工作区已有的，不用单独创建 Client Secret。",
        "en": "Open the Credentials page in the Transloadit dashboard and copy Auth Secret. It already belongs to the workspace — don’t create a separate Client Secret.",
        "ja": "Transloadit ダッシュボードの Credentials ページを開き、Auth Secret をコピーします。ワークスペースに既にあるので、Client Secret を別に作らないでください。"
      },
      {
        "zh": "同一页复制 Auth Key，填进 Client ID。不要去创建 Client ID。",
        "en": "On the same page, copy Auth Key into Client ID. Don’t create a Client ID.",
        "ja": "同じページで Auth Key をコピーし、Client ID に入れます。Client ID は作らないでください。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "Auth Key 或 Auth Secret 不对。",
          "en": "Auth Key or Auth Secret is wrong.",
          "ja": "Auth Key か Auth Secret が違います。"
        },
        "nextStep": {
          "zh": "回 Credentials 页重新复制这两项，注意不要抄成第三方云存储的 Template Credentials。",
          "en": "Go back to Credentials and copy both again. Don’t mix them up with third-party Template Credentials.",
          "ja": "Credentials に戻り、両方をコピーし直してください。サードパーティの Template Credentials と取り違えないでください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "工作区开了强制 Signature，光有 Key 还不够。",
          "en": "The workspace requires a Signature, so the key alone isn’t enough.",
          "ja": "ワークスペースで Signature 必須になっており、Key だけでは足りません。"
        },
        "nextStep": {
          "zh": "确认填的是 Auth Secret，并且请求按官方方式签名。",
          "en": "Confirm you pasted Auth Secret, and that requests are signed the official way.",
          "ja": "Auth Secret を入れたこと、公式どおり署名していることを確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://transloadit.com/c/",
    "credentialSetupURL": "https://transloadit.com/c/credentials/",
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
        "isSecret": true,
        "hint": {
          "zh": "登录 portal 后控制台给出",
          "en": "Shown in the portal after you sign in",
          "ja": "portal にログインすると表示されます"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Api2Pdf 控制台，注册或登录 portal。账号建好后控制台会给出 API Key，立刻复制。",
        "en": "Open the Api2Pdf dashboard and sign up or log in to the portal. After the account exists, the dashboard shows an API Key — copy it right away.",
        "ja": "Api2Pdf ダッシュボードを開き、portal に登録またはログインします。アカウントができると API Key が出るので、すぐにコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这个 API Key 无效。",
          "en": "This API Key is invalid.",
          "ja": "この API Key は無効です。"
        },
        "nextStep": {
          "zh": "回 portal 重新复制控制台给出的那把。",
          "en": "Go back to the portal and copy the key shown in the dashboard.",
          "ja": "portal に戻り、ダッシュボードに出ているキーをコピーし直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把钥匙读不到账户余额。",
          "en": "This key can’t read the account balance.",
          "ja": "このキーでは残高を読めません。"
        },
        "nextStep": {
          "zh": "确认复制完整，并用 portal 里当前这把，不要用旧环境变量。",
          "en": "Make sure you copied the whole key, and use the current one in the portal — not an old env var.",
          "ja": "全部コピーできているか確認し、古い環境変数ではなく portal の現在のキーを使ってください。"
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
        "isSecret": true,
        "hint": {
          "zh": "顶栏 API Keys",
          "en": "API Keys in the top menu",
          "ja": "上部メニューの API Keys"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 HetrixTools 控制台，顶栏进 API Keys。页面上已有一把，也可点 Add a new API Key。",
        "en": "Open the HetrixTools dashboard and go to API Keys in the top menu. A key is already there; you can also tap Add a new API Key.",
        "ja": "HetrixTools ダッシュボードを開き、上部メニューの API Keys に入ります。キーは既にあり、Add a new API Key でも追加できます。"
      },
      {
        "zh": "默认是全权限。需要收窄时点 Configure Access。立刻复制。",
        "en": "Keys have full access by default. Tap Configure Access if you need to narrow them. Copy the key right away.",
        "ja": "初期状態は全権限です。絞るなら Configure Access をタップします。すぐにコピーしてください。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这个 API Key 无效，或者已经重新生成。",
          "en": "This API Key is invalid, or it was already regenerated.",
          "ja": "この API Key は無効か、再生成済みです。"
        },
        "nextStep": {
          "zh": "回 API Keys 复制当前那把，或再点 Add a new API Key。",
          "en": "Go back to API Keys and copy the current one, or tap Add a new API Key.",
          "ja": "API Keys に戻り、現在のキーをコピーするか、Add a new API Key してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把钥匙的 Access 没放开对应接口。",
          "en": "This key’s Access doesn’t allow that API call.",
          "ja": "このキーの Access が対象 API を許可していません。"
        },
        "nextStep": {
          "zh": "回 API Keys 点 Configure Access，或换一把默认全权限的。",
          "en": "Go back to API Keys, tap Configure Access, or use a default full-access key.",
          "ja": "API Keys で Configure Access するか、初期の全権限キーに替えてください。"
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
        "zh": "打开 ShipStation API 控制台，切到 Production，到 API Keys 点 Create new key，起名后立刻复制。请求头是 API-Key。不要用 TEST_ 开头的 Sandbox 钥匙。",
        "en": "Open the ShipStation API dashboard, switch to Production, go to API Keys, tap Create new key, name it, and copy it right away. The header is API-Key. Do not use a Sandbox key that starts with TEST_.",
        "ja": "ShipStation API ダッシュボード を開き、Production に切り替えて API Keys で Create new key をタップし、名前を付けたらすぐにコピーします。ヘッダは API-Key です。TEST_ で始まる Sandbox の鍵は使わないでください。"
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
    "credentialSetupURL": "https://dashboard.shipengine.com/",
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
        "zh": "打开 thanks.io 控制台 的 API Settings，在 Personal Access Tokens (API Key) 下创建一把，创建后立刻复制。请求头是 Authorization: Bearer。",
        "en": "Open API Settings in the thanks.io dashboard. Under Personal Access Tokens (API Key), create one and copy it right away. The header is Authorization: Bearer.",
        "ja": "thanks.io ダッシュボード の API Settings を開き、Personal Access Tokens (API Key) で発行し、作成したらすぐにコピーします。ヘッダは Authorization: Bearer です。"
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
    "credentialSetupURL": "https://dashboard.thanks.io/profile/api",
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
          "zh": "Click2Mail 账户用户名，不是 OAuth Client ID",
          "en": "Click2Mail account username, not an OAuth client ID",
          "ja": "Click2Mail のアカウントユーザー名。OAuth の client ID ではありません"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Getting access to the API。账户类型必须是 Business。到 My Account → Profile & Preference，在 API Access 点 Start Now 并完成问卷。Client Secret 就是账户密码，不是 OAuth secret。",
        "en": "Open Getting access to the API. The account type must be Business. Go to My Account → Profile & Preference, tap Start Now under API Access, and finish the survey. Client Secret is the account password, not an OAuth secret.",
        "ja": "Getting access to the API を開きます。アカウント種別は Business である必要があります。My Account → Profile & Preference の API Access で Start Now をタップし、アンケートを完了します。Client Secret はアカウントのパスワードで、OAuth の secret ではありません。"
      },
      {
        "zh": "Client ID 填账户用户名，不要创建 OAuth Client ID。生产用这套凭据；不要拿 staging 用户名去打生产接口。",
        "en": "Put the account username in Client ID. Do not create an OAuth Client ID. Use production credentials; do not call production with a staging username.",
        "ja": "Client ID にはアカウントのユーザー名を入れ、OAuth の Client ID は作らないでください。本番の認証情報を使ってください。staging のユーザー名で本番 API を呼ばないでください。"
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
    "credentialSetupURL": "https://developers.click2mail.com/docs/getting-access-to-the-api",
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
        "zh": "打开 Gelato Dashboard，左侧 Developer → API Keys。需要管理员权限。",
        "en": "Open the Gelato Dashboard. In the left menu go to Developer → API Keys. You need admin permission.",
        "ja": "Gelato Dashboard を開き、左メニューの Developer → API Keys に進みます。管理者権限が必要です。"
      },
      {
        "zh": "点 Add API key，起一个名字，再点 Create key。凭据只显示一次，立刻复制。",
        "en": "Tap Add API key, give it a unique name, then tap Create key. The key is shown only once — copy it right away.",
        "ja": "Add API key をタップして名前を付け、Create key をタップします。キーは一度しか表示されないので、すぐにコピーしてください。"
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
        "zh": "打开 Prodigi Dashboard（Live，不是 Sandbox），右上角齿轮里点 Show API key。",
        "en": "Open the Prodigi Dashboard (Live, not Sandbox). Tap the gear in the top-right, then Show API key.",
        "ja": "Prodigi Dashboard（Live。Sandbox ではない）を開き、右上の歯車から Show API key をタップします。"
      },
      {
        "zh": "复制这把 Live API Key。Sandbox 的钥匙不能用在 Live。",
        "en": "Copy this Live API Key. A Sandbox key cannot be used on Live.",
        "ja": "この Live API Key をコピーします。Sandbox のキーは Live では使えません。"
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
    "credentialSetupURL": "https://dashboard.prodigi.com/",
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
          "zh": "SecretKey",
          "en": "SecretKey",
          "ja": "SecretKey"
        },
        "isSecret": true
      },
      {
        "key": "accessKeyID",
        "label": {
          "zh": "AccessKey",
          "en": "AccessKey",
          "ja": "AccessKey"
        },
        "isSecret": false,
        "hint": {
          "zh": "同一对密钥里的 AccessKey，不要另建",
          "en": "AccessKey from the same pair — don’t create another",
          "ja": "同じペアの AccessKey。別途作成しません"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开七牛云 密钥管理。没有密钥就点创建密钥；一对 AccessKey / SecretKey 会一起出现。",
        "en": "Open Qiniu Key Management. If you have none, tap Create key — AccessKey and SecretKey appear together as a pair.",
        "ja": "七牛クラウドのキー管理を開きます。まだ無ければキーを作成します。AccessKey と SecretKey はペアで出ます。"
      },
      {
        "zh": "点显示，立刻复制 SecretKey。不要再单独创建一把。",
        "en": "Tap Show and copy the SecretKey right away. Don’t create a second pair just for this field.",
        "ja": "表示をタップして SecretKey をすぐにコピーします。この欄のために別ペアを作らないでください。"
      },
      {
        "zh": "同一页复制 AccessKey。一个账号最多两对，不要为这个字段再创建。",
        "en": "Copy the AccessKey on the same page. An account can have at most two pairs — don’t create another for this field.",
        "ja": "同じページで AccessKey をコピーします。1 アカウント最大 2 ペアなので、この欄のために新規作成しないでください。"
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
        "zh": "打开 MySendingBox 开发者门户 的 API keys 页，复制 live API Key。不要用 test 钥匙。",
        "en": "Open the API keys page in the MySendingBox developer portal and copy the live API Key. Don’t use the test key.",
        "ja": "MySendingBox 開発者ポータル の API keys ページを開き、live API Key をコピーします。test キーは使わないでください。"
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
    "credentialSetupURL": "https://app.mysendingbox.fr/account/keys",
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
        "zh": "打开 Stannp 控制台，进 Settings → API，复制 API Key。",
        "en": "Open the Stannp dashboard, go to Settings → API, and copy the API Key.",
        "ja": "Stannp ダッシュボード を開き、Settings → API で API Key をコピーします。"
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
    "credentialSetupURL": "https://dash.stannp.com",
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
        "zh": "打开 Phaxio 控制台 的 API Settings，复制 live 的 API Key 和 API secret。secret 贴进 Client Secret。不要用 test 钥匙，那不会动余额。",
        "en": "Open API Settings in the Phaxio dashboard and copy the live API Key and API secret. Paste the secret into Client Secret. Don’t use test keys — they won’t change the balance.",
        "ja": "Phaxio ダッシュボード の API Settings を開き、live の API Key と API secret をコピーします。secret は Client Secret に貼ります。test キーは残高が動かないので使わないでください。"
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
    "credentialSetupURL": "https://www.phaxio.com/apiSettings",
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
        "zh": "打开 Porkbun 控制台，右上角 ACCOUNT → API Access。起个名字，点 Create API Key。立刻复制 API Key 和 Secret Key；Secret 只显示一次，贴进 Client Secret。",
        "en": "Open the Porkbun dashboard, then ACCOUNT → API Access in the top right. Name the key and tap Create API Key. Copy the API Key and Secret Key immediately — the Secret is shown once. Paste the Secret into Client Secret.",
        "ja": "Porkbun ダッシュボード を開き、右上の ACCOUNT → API Access へ。名前を付けて Create API Key をタップします。API Key と Secret Key をすぐにコピーしてください。Secret は一度しか表示されません。Secret は Client Secret に貼ります。"
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
    "credentialSetupURL": "https://porkbun.com/account/api",
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
          "zh": "Namecheap 登录用户名（ApiUser）",
          "en": "Namecheap username (ApiUser)",
          "ja": "Namecheap のログインユーザー名（ApiUser）"
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
          "zh": "已加白的出口 IPv4（ClientIp）",
          "en": "Whitelisted egress IPv4 (ClientIp)",
          "ja": "許可した出口 IPv4（ClientIp）"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Namecheap 控制台 Profile → Tools → Business & Dev Tools → Namecheap API Access，点 MANAGE。打开开关，同意条款并输入账户密码，然后复制分配到的 APIKey。",
        "en": "Open Profile → Tools in the Namecheap dashboard, find Business & Dev Tools → Namecheap API Access, and tap MANAGE. Toggle it on, accept the terms, enter your account password, then copy the APIKey you’re allotted.",
        "ja": "Namecheap ダッシュボード の Profile → Tools を開き、Business & Dev Tools → Namecheap API Access の MANAGE をタップします。スイッチをオンにし、規約に同意してアカウントパスワードを入力し、割り当てられた APIKey をコピーします。"
      },
      {
        "zh": "Account ID 填 Namecheap 登录用户名（文档里的 ApiUser），不要新建。同一页把本机出口 IPv4 加进 Whitelisted IPs，Client ID 填这个已加白的地址（文档里的 ClientIp）。",
        "en": "Put your Namecheap username in Account ID (ApiUser in the docs). Don’t create one. On the same page add this device’s egress IPv4 to Whitelisted IPs, and put that address in Client ID (ClientIp in the docs).",
        "ja": "Account ID には Namecheap のログインユーザー名（ドキュメントの ApiUser）を入れます。新規作成はしません。同じページでこの端末の出口 IPv4 を Whitelisted IPs に追加し、そのアドレスを Client ID（ドキュメントの ClientIp）に入れます。"
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
    "credentialSetupURL": "https://ap.www.namecheap.com/settings/tools/apiaccess/",
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
        "zh": "打开 Gandi 控制台，左侧 ORGANIZATIONS，点付账那个组织，打开 Sharing。到底部点 Create a token。选组织、有效期，资源选 The whole organization，打开账单相关权限，点 Create。立刻复制 Personal Access Token，只显示一次。",
        "en": "Open the Gandi dashboard, choose ORGANIZATIONS, open the organization you pay from, then Sharing. At the bottom tap Create a token. Pick the organization and expiry, set resources to The whole organization, enable billing permissions, then Create. Copy the Personal Access Token immediately — it’s shown once.",
        "ja": "Gandi ダッシュボード を開き、左の ORGANIZATIONS から支払い中の組織を選び、Sharing を開きます。下部の Create a token をタップ。組織と有効期限を選び、リソースは The whole organization、請求関連の権限をオンにして Create。Personal Access Token は一度しか表示されないので、すぐにコピーします。"
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
    "credentialSetupURL": "https://admin.gandi.net/organizations/account/pat",
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
        "isSecret": true,
        "hint": {
          "zh": "API Portal → Developer keys 的 Live keys",
          "en": "Live keys in API Portal → Developer keys",
          "ja": "API Portal → Developer keys の Live keys"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Shippo API Portal，在 API Configuration 里选 Developer keys。",
        "en": "Open the Shippo API Portal and choose Developer keys under API Configuration.",
        "ja": "Shippo API Portal を開き、API Configuration の Developer keys を選びます。"
      },
      {
        "zh": "在 Live keys 点 Create new live key。完整钥匙只显示一次，立刻复制。以 shippo_live_ 开头。不要用 Test。",
        "en": "Under Live keys, tap Create new live key. You only see the full key once — copy it right away. It starts with shippo_live_. Don’t use Test.",
        "ja": "Live keys で Create new live key をタップします。全文は一度しか出ないのですぐにコピーします。先頭は shippo_live_。Test は使わないでください。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "Token 不存在，或者已经删掉、过期。",
          "en": "The token doesn’t exist, or it was already deleted or expired.",
          "ja": "token が存在しないか、削除・期限切れです。"
        },
        "nextStep": {
          "zh": "回 Developer keys 再签发一把 Live key，创建后立刻复制。",
          "en": "Go back to Developer keys, issue a new Live key, and copy it right away.",
          "ja": "Developer keys に戻り、Live key を作り直してすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "多半用了 Test 钥匙去读线上数据。",
          "en": "You probably used a Test key against live data.",
          "ja": "Test キーで本番データを読んでいる可能性が高いです。"
        },
        "nextStep": {
          "zh": "改用 shippo_live_ 开头的 Live key。",
          "en": "Switch to a Live key that starts with shippo_live_.",
          "ja": "shippo_live_ で始まる Live key に切り替えてください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://apps.goshippo.com/",
    "credentialSetupURL": "https://portal.goshippo.com/api-config/api",
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
        "isSecret": true,
        "hint": {
          "zh": "Developer Portal → Your tokens",
          "en": "Developer Portal → Your tokens",
          "ja": "Developer Portal → Your tokens"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Printful Developer Portal 的 Your tokens，创建一把 Private Token。",
        "en": "Open Your tokens in the Printful Developer Portal and create a Private Token.",
        "ja": "Printful Developer Portal の Your tokens を開き、Private Token を作成します。"
      },
      {
        "zh": "访问级别选 Account 或单个 store。账单只读勾 orders/read。创建后立刻复制，之后看不到。",
        "en": "Set access to Account or a single store. For billing read-only, check orders/read. Copy the token right away — you won’t see it again.",
        "ja": "アクセスは Account か単一 store。請求の読み取りだけなら orders/read。作成したらすぐにコピーし、あとからは見えません。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "Private Token 无效，或者已经过期、删掉。",
          "en": "The Private Token is invalid, or it already expired or was deleted.",
          "ja": "Private Token が無効か、期限切れ・削除済みです。"
        },
        "nextStep": {
          "zh": "回 Your tokens 再创建一把，创建后立刻复制。",
          "en": "Go back to Your tokens, create a new one, and copy it right away.",
          "ja": "Your tokens に戻り、作り直してすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 token 缺 orders/read，或者 store 范围不对。",
          "en": "This token is missing orders/read, or the store scope is wrong.",
          "ja": "orders/read がないか、store の範囲が違います。"
        },
        "nextStep": {
          "zh": "回上一步按 orders/read 重建，Account 级还要选对 store。",
          "en": "Go back a step and recreate it with orders/read. For Account-level tokens, pick the right store.",
          "ja": "前の手順に戻り、orders/read で作り直してください。Account レベルなら store も合わせてください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.printful.com/dashboard",
    "credentialSetupURL": "https://developers.printful.com/tokens",
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
        "isSecret": true,
        "hint": {
          "zh": "Settings → API 的 PartnerBillingKey",
          "en": "PartnerBillingKey on Settings → API",
          "ja": "Settings → API の PartnerBillingKey"
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
          "zh": "Settings → API 的 RecipeID",
          "en": "RecipeID on Settings → API",
          "ja": "Settings → API の RecipeID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Gooten Admin 的 Settings → API，点 Show，复制 PartnerBillingKey。这是已有的私钥，不用创建 Client Secret。",
        "en": "Open Settings → API in Gooten Admin, tap Show, and copy PartnerBillingKey. It’s an existing private key — don’t create a Client Secret.",
        "ja": "Gooten Admin の Settings → API を開き、Show をタップして PartnerBillingKey をコピーします。既にある秘密鍵なので、Client Secret は作らないでください。"
      },
      {
        "zh": "同一页复制 RecipeID，填进 Client ID。这是公开 ID，不用创建。",
        "en": "On the same page, copy RecipeID into Client ID. It’s a public ID — don’t create one.",
        "ja": "同じページで RecipeID をコピーし、Client ID に入れます。公開 ID なので作成は不要です。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "RecipeID 或 PartnerBillingKey 不对。",
          "en": "RecipeID or PartnerBillingKey is wrong.",
          "ja": "RecipeID か PartnerBillingKey が違います。"
        },
        "nextStep": {
          "zh": "回 Settings → API 再点 Show，两把都复制完整。",
          "en": "Go back to Settings → API, tap Show again, and copy both in full.",
          "ja": "Settings → API に戻り、Show をもう一度押して両方を全部コピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "订单类接口还要 PartnerBillingKey，只填 RecipeID 不够。",
          "en": "Order APIs also need PartnerBillingKey; RecipeID alone isn’t enough.",
          "ja": "注文系 API には PartnerBillingKey も必要で、RecipeID だけでは足りません。"
        },
        "nextStep": {
          "zh": "确认 Client Secret 里是 PartnerBillingKey，不要把 RecipeID 填进密钥栏。",
          "en": "Confirm Client Secret is PartnerBillingKey — don’t put RecipeID in the secret field.",
          "ja": "Client Secret が PartnerBillingKey か確認し、RecipeID を秘密欄に入れないでください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.gooten.com/",
    "credentialSetupURL": "https://www.gooten.com/admin#/settings/api",
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
        "isSecret": true,
        "hint": {
          "zh": "Connect → API Integration 的 Production Access Token",
          "en": "Production Access Token from Connect → API Integration",
          "ja": "Connect → API Integration の Production Access Token"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Easyship 控制台 Connect → New Integration，选 API Integration，起名后点 Connect。",
        "en": "In the Easyship dashboard, open Connect → New Integration, choose API Integration, name it, then tap Connect.",
        "ja": "Easyship ダッシュボードで Connect → New Integration を開き、API Integration を選んで名前を付け、Connect をタップします。"
      },
      {
        "zh": "复制 Production Access Token（prod_ 开头）。需要账单时把 Company 等 scope 打开。不要用 sand_ 沙箱。",
        "en": "Copy the Production Access Token (it starts with prod_). Turn on Company and any billing scopes you need. Don’t use a sand_ sandbox token.",
        "ja": "Production Access Token（先頭 prod_）をコピーします。請求が必要なら Company などの scope をオン。sand_ のサンドボックスは使わないでください。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "Access Token 无效，或者已经撤销。",
          "en": "The Access Token is invalid, or it was already revoked.",
          "ja": "Access Token が無効か、取り消されています。"
        },
        "nextStep": {
          "zh": "回 Connect → API 复制 Production 那把，或再建一个 Integration。",
          "en": "Go back to Connect → API, copy the Production token, or create another Integration.",
          "ja": "Connect → API に戻り、Production をコピーするか、Integration を作り直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 token 的 scope 读不到账单文件。",
          "en": "This token’s scopes can’t read billing documents.",
          "ja": "この token の scope では請求書類を読めません。"
        },
        "nextStep": {
          "zh": "在 Connect → API 打开 Company 等相关 scope，不要用 sand_ 沙箱。",
          "en": "In Connect → API, turn on Company and related scopes. Don’t use a sand_ sandbox token.",
          "ja": "Connect → API で Company などの scope をオンにし、sand_ は使わないでください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://app.easyship.com/",
    "credentialSetupURL": "https://app.easyship.com/connect",
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
        "isSecret": true,
        "hint": {
          "zh": "获取用户 Token 的 X-Subject-Token，约 24 小时过期",
          "en": "X-Subject-Token from Obtaining a User Token; expires in about 24 hours",
          "ja": "ユーザー Token 取得の X-Subject-Token。約 24 時間で期限切れ"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Huawei Cloud 获取用户 Token 文档。在控制台 My Credentials 记下 IAM Username 和 Account Name。",
        "en": "Open Huawei Cloud’s Obtaining a User Token docs. In the console under My Credentials, note IAM Username and Account Name.",
        "ja": "Huawei Cloud の Obtaining a User Token ドキュメントを開きます。コンソールの My Credentials で IAM Username と Account Name を控えます。"
      },
      {
        "zh": "按文档用密码换一把 domain 范围的 Token，复制响应头 X-Subject-Token。有效期约 24 小时。IAM 用户需要 bss:bill:view。",
        "en": "Follow the docs to exchange the password for a domain-scoped token, then copy X-Subject-Token from the response header. It lasts about 24 hours. IAM users need bss:bill:view.",
        "ja": "ドキュメントどおりパスワードで domain スコープの Token を取り、応答ヘッダの X-Subject-Token をコピーします。有効期限は約 24 時間。IAM ユーザーには bss:bill:view が必要です。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "Token 无效，或者已经超过约 24 小时。",
          "en": "The token is invalid, or it already passed the ~24 hour lifetime.",
          "ja": "token が無効か、約 24 時間を過ぎています。"
        },
        "nextStep": {
          "zh": "回 My Credentials 确认账号名，再按文档换一把新的 X-Subject-Token。",
          "en": "Confirm the account name in My Credentials, then obtain a new X-Subject-Token from the docs.",
          "ja": "My Credentials でアカウント名を確認し、ドキュメントから新しい X-Subject-Token を取り直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这个 Token 缺 bss:bill:view，读不到账单。",
          "en": "This token is missing bss:bill:view, so it can’t read billing.",
          "ja": "bss:bill:view がないため、請求を読めません。"
        },
        "nextStep": {
          "zh": "给 IAM 用户加上账单只读，并用 domain 范围重新换 Token。",
          "en": "Grant the IAM user billing read-only, then obtain a new domain-scoped token.",
          "ja": "IAM ユーザーに請求の読み取りを付け、domain スコープで Token を取り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://account-intl.myhuaweicloud.com/",
    "credentialSetupURL": "https://support.huaweicloud.com/intl/en-us/api-iam/iam_30_0001.html",
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
        "isSecret": true,
        "hint": {
          "zh": "组织 API Keys 的 Customized key",
          "en": "A customized key on the org API Keys page",
          "ja": "組織 API Keys の Customized key"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Zilliz Cloud 组织的 API Keys。生产环境不要用个人钥匙。",
        "en": "Open API Keys for your Zilliz Cloud organization. Don’t use a personal key in production.",
        "ja": "Zilliz Cloud 組織の API Keys を開きます。本番では個人キーを使わないでください。"
      },
      {
        "zh": "组织所有者或项目管理员点 + API Key，填名称。角色尽量只给 Organization Billing Admin，创建后立刻复制。",
        "en": "Organization Owners or Project Admins tap + API Key and enter a name. Prefer Organization Billing Admin only, then copy the key right away.",
        "ja": "Organization Owner または Project Admin が + API Key をタップし、名前を入れます。権限はできれば Organization Billing Admin だけ。作成したらすぐにコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这个 API Key 无效，或者已经重置、删除。",
          "en": "This API Key is invalid, or it was already reset or deleted.",
          "ja": "この API Key は無効か、リセット・削除済みです。"
        },
        "nextStep": {
          "zh": "回组织 API Keys 重置或新建一把 Customized key，立刻复制。",
          "en": "Go back to the org API Keys page, reset or create a customized key, and copy it right away.",
          "ja": "組織の API Keys に戻り、Customized key をリセットまたは新規作成してすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把钥匙没有账单角色。",
          "en": "This key doesn’t have a billing role.",
          "ja": "このキーに請求ロールがありません。"
        },
        "nextStep": {
          "zh": "改成 Organization Billing Admin，或换一把有账单权限的 Customized key。",
          "en": "Switch it to Organization Billing Admin, or use a customized key that can read billing.",
          "ja": "Organization Billing Admin にするか、請求を読める Customized key に替えてください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://cloud.zilliz.com/",
    "credentialSetupURL": "https://docs.zilliz.com/docs/manage-api-keys",
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
        "isSecret": true,
        "hint": {
          "zh": "项目里的 API Keys，不要用临时钥匙",
          "en": "Project API Keys — not a temporary key",
          "ja": "プロジェクトの API Keys。一時キーは使わない"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Soniox 控制台，进项目（默认 My First Project）的 API Keys，生成一把。钥匙按项目签发。立刻复制。",
        "en": "Open the Soniox console, go to API Keys for your project (default My First Project), and generate one. Keys are issued per project. Copy it right away.",
        "ja": "Soniox コンソールを開き、プロジェクト（初期は My First Project）の API Keys で発行します。キーはプロジェクト単位です。すぐにコピーしてください。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这个 API Key 无效，或者用了过期的临时钥匙。",
          "en": "This API Key is invalid, or you used an expired temporary key.",
          "ja": "この API Key は無効か、期限切れの一時キーです。"
        },
        "nextStep": {
          "zh": "回项目 API Keys 生成一把长期钥匙，不要用 Temporary API key。",
          "en": "Go back to the project API Keys and generate a long-lived key. Don’t use a Temporary API key.",
          "ja": "プロジェクトの API Keys で長期キーを発行し、Temporary API key は使わないでください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把钥匙不属于当前项目。",
          "en": "This key doesn’t belong to the current project.",
          "ja": "このキーは現在のプロジェクトのものではありません。"
        },
        "nextStep": {
          "zh": "进付账那个项目的 API Keys 再签发一把。",
          "en": "Issue a key from API Keys in the project you pay from.",
          "ja": "支払い中のプロジェクトの API Keys で発行し直してください。"
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
        "isSecret": true,
        "hint": {
          "zh": "GleSYS Cloud 里给项目签发的 API key",
          "en": "API key issued for a project in GleSYS Cloud",
          "ja": "GleSYS Cloud でプロジェクトに発行した API key"
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
          "zh": "客户编号 customernumber，不用创建",
          "en": "Customer number (customernumber) — don’t create one",
          "ja": "顧客番号 customernumber。作成は不要"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 GleSYS Cloud，给项目签发一把 API key。账单接口 invoice/list 要用客户编号，不要用 CL 开头的项目号当用户名。",
        "en": "Open GleSYS Cloud and issue an API key for your project. The invoice/list billing API authenticates with the customer number — don’t use a CL… project key as the username.",
        "ja": "GleSYS Cloud を開き、プロジェクト用の API key を発行します。請求の invoice/list は顧客番号で認証するので、CL で始まるプロジェクト番号をユーザー名にしないでください。"
      },
      {
        "zh": "Account ID 是客户门户里的客户编号 customernumber，复制即可，不要创建。",
        "en": "Account ID is the customer number (customernumber) in the customer portal. Copy it — don’t create an Account ID.",
        "ja": "Account ID は顧客ポータルの顧客番号 customernumber です。コピーするだけで、Account ID は作らないでください。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "API key 或客户编号不对。",
          "en": "The API key or customer number is wrong.",
          "ja": "API key か顧客番号が違います。"
        },
        "nextStep": {
          "zh": "回 GleSYS Cloud 重新复制 API key，Account ID 填 customernumber，不要填 CL 项目号。",
          "en": "Copy the API key again from GleSYS Cloud. Put customernumber in Account ID — not the CL project key.",
          "ja": "GleSYS Cloud で API key をコピーし直し、Account ID には customernumber を入れて、CL のプロジェクト番号は使わないでください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把钥匙不能调 invoice/list，多半用了项目号去认证。",
          "en": "This key can’t call invoice/list. You probably authenticated with a project key.",
          "ja": "invoice/list を呼べません。プロジェクト番号で認証している可能性が高いです。"
        },
        "nextStep": {
          "zh": "改用客户编号 + API key。需要的话在 Cloud 里限制钥匙只能打发票接口。",
          "en": "Use the customer number plus API key. In Cloud, you can also limit the key to invoice functions.",
          "ja": "顧客番号と API key の組み合わせに変えてください。必要なら Cloud で請求 API だけに制限します。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://customer.glesys.com/",
    "credentialSetupURL": "https://cloud.glesys.com",
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
        "isSecret": true,
        "hint": {
          "zh": "登录密码（官方 API 没有单独的 API Key）",
          "en": "Sign-in password (the official API has no separate API Key)",
          "ja": "ログインパスワード（公式 API に独立した API Key はない）"
        }
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
          "zh": "登录邮箱，不用创建",
          "en": "Sign-in email — don’t create one",
          "ja": "ログイン用メール。作成は不要"
        }
      }
    ],
    "steps": [
      {
        "zh": "CloudSigma API 用登录邮箱和密码做 HTTP Basic，没有单独签发的 API Key。把登录密码填进 API Key。",
        "en": "The CloudSigma API uses HTTP Basic with your sign-in email and password. There is no separately issued API Key. Put the sign-in password in API Key.",
        "ja": "CloudSigma API はログイン用メールとパスワードの HTTP Basic で、個別の API Key はありません。ログインパスワードを API Key に入れます。"
      },
      {
        "zh": "Email 填登录邮箱，不要创建。",
        "en": "Put your sign-in email in Email. Don’t create an Email.",
        "ja": "Email にはログイン用メールを入れます。作成はしないでください。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "邮箱或密码不对。",
          "en": "The email or password is wrong.",
          "ja": "メールかパスワードが違います。"
        },
        "nextStep": {
          "zh": "用控制台同一套登录邮箱和密码，不要去找不存在的 API Key 页。",
          "en": "Use the same sign-in email and password as the dashboard. There isn’t a separate API Key page.",
          "ja": "ダッシュボードと同じログイン用メールとパスワードを使い、存在しない API Key ページは探さないでください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "账号没权限读账单账本。",
          "en": "This account can’t read the billing ledger.",
          "ja": "このアカウントでは請求台帳を読めません。"
        },
        "nextStep": {
          "zh": "用主账号登录，或让管理员放开账单权限。",
          "en": "Sign in with the primary account, or ask an admin to grant billing access.",
          "ja": "主アカウントで入るか、管理者に請求権限を付けてもらってください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://ui.cloudsigma.com/",
    "credentialSetupURL": "https://docs.cloudsigma.com/en/latest/general.html#http-basic-auth",
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
        "isSecret": true,
        "hint": {
          "zh": "Profile 页 Generate 出来的 API key",
          "en": "API key generated on the Profile page",
          "ja": "Profile ページで Generate した API key"
        }
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
          "zh": "登录邮箱，不用创建",
          "en": "Sign-in email — don’t create one",
          "ja": "ログイン用メール。作成は不要"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 VPS.NET 控制台，顶栏进 Profile，在 API key 旁点 Generate，立刻复制。",
        "en": "Open the VPS.NET dashboard, go to Profile in the top bar, tap Generate next to API key, and copy it right away.",
        "ja": "VPS.NET ダッシュボードを開き、上部の Profile で API key の横の Generate をタップし、すぐにコピーします。"
      },
      {
        "zh": "用户名是登录邮箱，填进 Email。不要去创建 Email。",
        "en": "The username is your sign-in email. Put that in Email. Don’t create an Email.",
        "ja": "ユーザー名はログイン用メールです。それを Email に入れます。Email は作らないでください。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "邮箱或 API key 不对，或者已经重新 Generate。",
          "en": "The email or API key is wrong, or the key was already regenerated.",
          "ja": "メールか API key が違うか、再 Generate 済みです。"
        },
        "nextStep": {
          "zh": "回 Profile 再 Generate 一次，并用登录邮箱，不要新建邮箱。",
          "en": "Go back to Profile, Generate again, and use your sign-in email. Don’t create a new email.",
          "ja": "Profile で Generate し直し、ログイン用メールを使ってください。新しいメールは作らないでください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把钥匙读不到账户接口。",
          "en": "This key can’t read the account API.",
          "ja": "このキーではアカウント API を読めません。"
        },
        "nextStep": {
          "zh": "确认用的是 Profile 里当前那把 API key，而不是旧的。",
          "en": "Confirm you’re using the current API key from Profile, not an old one.",
          "ja": "Profile の現在の API key か確認し、古いキーは使わないでください。"
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
        "zh": "打开 Voltage Park 控制台 的 Developers 页，创建新 token，立刻复制 API Token。token 有效期一年，过期要轮换。",
        "en": "Open the Developers page in the Voltage Park dashboard, create a new token, and copy the API Token immediately. Tokens last one year — rotate them before they expire.",
        "ja": "Voltage Park ダッシュボード の Developers ページを開き、新しい token を作って API Token をすぐにコピーします。有効期限は 1 年なので、切れる前にローテーションしてください。"
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
        "isSecret": true,
        "hint": {
          "zh": "RCP 密码（明文，不是 hash）",
          "en": "RCP password (plain, not the hash)",
          "ja": "RCP パスワード（平文。ハッシュではない）"
        }
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
          "zh": "RCP 登录用户名",
          "en": "RCP username",
          "ja": "RCP のログインユーザー名"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Openprovider 控制台 Account → Account Overview，确认 API access 是绿点。若是红的，点用户名 → Edit，勾 API access Enabled，再 Update contact。Client Secret 填该用户的 RCP 密码（REST 用明文密码，不是 XML 的 hash）。",
        "en": "Open Account → Account Overview in the Openprovider dashboard and check that API access is green. If it’s red, open the username → Edit, tick API access Enabled, then Update contact. Put that user’s RCP password in Client Secret (plain password for REST, not the XML hash).",
        "ja": "Openprovider ダッシュボード の Account → Account Overview を開き、API access が緑か確認します。赤ならユーザー名 → Edit で API access Enabled にチェックし、Update contact。Client Secret にはそのユーザーの RCP パスワードを入れます（REST は平文。XML のハッシュではない）。"
      },
      {
        "zh": "Email 填 RCP 登录用户名，和登录控制台的那个一样，不要新建。",
        "en": "Put the RCP username in Email — the same one you use to sign in. Don’t create one.",
        "ja": "Email には RCP のログインユーザー名を入れます。コンソールに入るものと同じで、新規作成はしません。"
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
    "credentialSetupURL": "https://support.openprovider.eu/hc/en-us/articles/360015453220-How-to-enable-API-access",
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
        "zh": "打开 Realtime Register 控制台，左侧 Account → Users。点你自己的用户，再点 API Keys。填 Description，点 Create API Key，立刻复制；钥匙只显示一次。需要 MANAGE_API_KEY 权限。",
        "en": "Open the Realtime Register dashboard, then Account → Users. Select your user, then API Keys. Enter a Description, tap Create API Key, and copy it immediately — it’s shown once. You need the MANAGE_API_KEY permission.",
        "ja": "Realtime Register ダッシュボード を開き、左の Account → Users へ。自分のユーザーを選び、API Keys を開きます。Description を入れて Create API Key をタップし、すぐにコピーします。キーは一度しか表示されません。MANAGE_API_KEY 権限が必要です。"
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
    "credentialSetupURL": "https://dm.realtimeregister.com/app/users",
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
          "zh": "客户组织 UUID，不是 Project ID",
          "en": "Customer organization UUID, not the Project ID",
          "ja": "顧客組織 UUID（Project ID ではない）"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 STACKIT 控制台，选项目，进 IAM and Management → Service accounts。点 Create service account。再打开该账号的 Access Tokens，点 Create token，立刻复制 API Token；JWT 只显示一次，会过期。",
        "en": "Open the STACKIT dashboard, pick the project, then IAM and Management → Service accounts. Tap Create service account. Open Access Tokens for that account, tap Create token, and copy the API Token immediately. The JWT is shown once and it expires.",
        "ja": "STACKIT ダッシュボード を開き、プロジェクトを選んで IAM and Management → Service accounts へ。Create service account をタップ。そのアカウントの Access Tokens で Create token し、API Token をすぐにコピーします。JWT は一度しか表示されず、期限切れになります。"
      },
      {
        "zh": "Account ID 填 Invoice Exporter 用的 Organization ID（客户组织 UUID），在门户里复制，不要新建。不要填 Project ID。",
        "en": "Put the Invoice Exporter Organization ID (customer organization UUID) in Account ID. Copy it from the portal — don’t create one. Don’t use the Project ID.",
        "ja": "Account ID には Invoice Exporter の Organization ID（顧客組織 UUID）を入れます。ポータルからコピーし、新規作成はしません。Project ID は使わないでください。"
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
    "credentialSetupURL": "https://docs.stackit.cloud/platform/access-and-identity/service-accounts/how-tos/manage-service-accounts/",
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
        "zh": "打开 Unleash 控制台，进 Profile → View profile settings → Personal API tokens。企业也可用 Admin settings → Service accounts。创建 token 并复制。不要用 Backend / Frontend token，发票接口是 Admin API。",
        "en": "Open the Unleash dashboard, then Profile → View profile settings → Personal API tokens. Enterprise can also use Admin settings → Service accounts. Create a token and copy it. Don’t use a Backend / Frontend token — invoices are an Admin API.",
        "ja": "Unleash ダッシュボード を開き、Profile → View profile settings → Personal API tokens へ。Enterprise なら Admin settings → Service accounts でも作れます。token を作ってコピーします。Backend / Frontend token は使わないでください。請求書は Admin API です。"
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
    "credentialSetupURL": "https://docs.getunleash.io/reference/api-tokens-and-client-keys",
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
        "zh": "打开 Redis Cloud 控制台，菜单 Access Management → API Keys。若看到 Enable API 先打开。点 Add 创建 User key，填 Key name 和 User name（需 owner、billing admin 或 viewer），点 Create。立刻复制 User key，贴进 Secret Access Key；只显示一次。",
        "en": "Open the Redis Cloud dashboard, then Access Management → API Keys. If Enable API is shown, turn it on first. Tap Add to create a User key, enter Key name and User name (owner, billing admin, or viewer), then Create. Copy the User key immediately into Secret Access Key — it’s shown once.",
        "ja": "Redis Cloud ダッシュボード を開き、メニューの Access Management → API Keys へ。Enable API が出ていれば先にオン。Add で User key を作り、Key name と User name（owner / billing admin / viewer）を入れて Create。User key は一度しか表示されないので、すぐに Secret Access Key へコピーします。"
      },
      {
        "zh": "同一页的 Account key 点 Show 再 Copy，贴进 Access Key ID。这是账户级钥匙，不要新建。",
        "en": "On the same page, tap Show then Copy on the Account key, and paste it into Access Key ID. This is the account-level key — don’t create one.",
        "ja": "同じページの Account key で Show して Copy し、Access Key ID に貼ります。アカウント級のキーなので、新規作成はしません。"
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
    "credentialSetupURL": "https://app.redislabs.com/#/access-management",
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
        "zh": "打开 PDFShift 控制台，进 API Keys，创建或复制 secret API Key（sk_ 开头）。",
        "en": "Open the PDFShift dashboard, go to API Keys, and create or copy a secret API Key (it starts with sk_).",
        "ja": "PDFShift ダッシュボード を開き、API Keys で secret API Key（sk_ で始まる）を作成またはコピーします。"
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
    "credentialSetupURL": "https://app.pdfshift.io",
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
          "zh": "组织 Settings 里的 Organisation ID",
          "en": "Organisation ID in Settings",
          "ja": "Settings の Organisation ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 SurrealDB 账户门户，创建 Personal Access Token。只勾 read:cloud（看组织和用量），立刻复制。token 不会自己过期。",
        "en": "Open the SurrealDB account portal and create a Personal Access Token. Tick only read:cloud (organisations, usage), then copy it immediately. The token does not expire on its own.",
        "ja": "SurrealDB アカウントポータル を開き、Personal Access Token を作成します。read:cloud（組織と用量の閲覧）だけにチェックを入れ、すぐにコピーします。token は自動では期限切れになりません。"
      },
      {
        "zh": "打开付账那个组织的 Settings，复制只读的 Organisation ID，贴进 Account ID。不要新建。",
        "en": "Open Settings for the organisation you pay from, copy the read-only Organisation ID, and paste it into Account ID. Don’t create one.",
        "ja": "支払い中の組織の Settings を開き、読み取り専用の Organisation ID をコピーして Account ID に貼ります。新規作成はしません。"
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
    "credentialSetupURL": "https://account.surrealdb.com/tokens",
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
        "zh": "打开 Simply.com 控制台，进 Account → API keys，创建一把 API Key，然后复制。",
        "en": "Open the Simply.com control panel, go to Account → API keys, create an API Key, then copy it.",
        "ja": "Simply.com コントロールパネルを開き、Account → API keys で API Key を作成してコピーします。"
      },
      {
        "zh": "认证用这把 key 当 Bearer，或放进 HTTP Basic 的密码栏（用户名随便填，key 本身就能认出账户）。",
        "en": "Send the key as a Bearer token, or as the HTTP Basic password (username can be anything; the key alone identifies the account).",
        "ja": "この key を Bearer にするか、HTTP Basic のパスワードにします（ユーザー名は何でもよく、key だけで口座が分かります）。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙无效，或者已经被撤销了。",
          "en": "This key is invalid, or it has already been revoked.",
          "ja": "このキーは無効か、すでに取り消されています。"
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
          "zh": "这把 API Key 无权读发票。",
          "en": "This API Key cannot read invoices.",
          "ja": "この API Key ではインボイスを読めません。"
        },
        "nextStep": {
          "zh": "回上一步在 Account → API keys 重建一把，确认是这个付账账户。",
          "en": "Go back a step, recreate it under Account → API keys, and confirm it belongs to the paying account.",
          "ja": "前の手順に戻り、Account → API keys で作り直し、支払い口座のものか確認してください。"
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
      "zh": "这个数字应该和后台本月已付发票一致。",
      "en": "This number should match this month’s paid invoices in the dashboard.",
      "ja": "この数字はダッシュボードの今月の支払い済みインボイスと一致するはずです。"
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
        "zh": "打开 Domeneshop 控制台的 API 页，生成一组凭据。secret 就是 Secret Access Key，和 token 一起诞生，不要单独再创建一把。",
        "en": "Open the API page in the Domeneshop control panel and generate credentials. The secret is Secret Access Key; it is issued with the token, so do not create a second pair.",
        "ja": "Domeneshop コントロールパネルの API ページを開き、認証情報を生成します。secret が Secret Access Key で、token と同時に出ます。別にもう一組作らないでください。"
      },
      {
        "zh": "同一页上的 token 就是 Access Key ID。认证是 HTTP Basic：token 当用户名，secret 当密码。",
        "en": "On that same page, token is Access Key ID. Auth is HTTP Basic: token as username, secret as password.",
        "ja": "同じページの token が Access Key ID です。認証は HTTP Basic で、token がユーザー名、secret がパスワードです。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "token 或 secret 不对，或这组凭据已被撤销。",
          "en": "token or secret is wrong, or this pair has been revoked.",
          "ja": "token か secret が違うか、この組は取り消されています。"
        },
        "nextStep": {
          "zh": "回上一步在 API 页重新生成一组，两把一起换。",
          "en": "Go back a step, generate a new pair on the API page, and replace both values.",
          "ja": "前の手順に戻り、API ページで組を作り直し、両方入れ替えてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这组凭据读不到发票。",
          "en": "This pair cannot read invoices.",
          "ja": "この組ではインボイスを読めません。"
        },
        "nextStep": {
          "zh": "回上一步用主账户重新生成，不要用子用户。",
          "en": "Go back a step and generate a new pair on the main account, not a sub-user.",
          "ja": "前の手順に戻り、サブユーザーではなく本口座で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.domeneshop.no/",
    "credentialSetupURL": "https://www.domeneshop.no/admin?view=api",
    "summary": {
      "zh": "挪威域名。按本月发票合计，克朗会折成美元。",
      "en": "Norwegian domains. This month’s invoices, summed. Kroner convert to USD.",
      "ja": "ノルウェーのドメイン。今月のインボイス合計で、クローネはドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月发票一致。克朗会折成美元。",
      "en": "This number should match this month’s invoices in the dashboard. Kroner convert to USD.",
      "ja": "この数字はダッシュボードの今月のインボイスと一致するはずです。クローネはドルに換算します。"
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
          "zh": "User ID，复制即可；斯洛伐克站在末尾加 |sk",
          "en": "User ID. Copy it; append |sk for the Slovak API host.",
          "ja": "User ID。コピーするだけ。スロバキアは末尾に |sk。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 WebAdmin：右上角账户名 → 安全与登录 → API autentifikácia，点 Vygenerovať nový API prístup。",
        "en": "In WebAdmin, open the account name (top right) → Security and login → API autentifikácia, then tap Vygenerovať nový API prístup.",
        "ja": "WebAdmin で右上の口座名 → セキュリティとログイン → API autentifikácia を開き、Vygenerovať nový API prístup をタップします。"
      },
      {
        "zh": "复制 identifikátor 为 API Key，Tajný kľúč 为 API Token（secret）。secret 只用来签 HMAC，不要当 Bearer 发出去。",
        "en": "Copy identifikátor as API Key and Tajný kľúč as API Token (the secret). The secret only signs HMAC; do not send it as a Bearer.",
        "ja": "identifikátor を API Key、Tajný kľúč を API Token（secret）としてコピーします。secret は HMAC 署名用で、Bearer として送らないでください。"
      },
      {
        "zh": "Account ID 是 User ID，不是创建出来的。在账户资料或 GET /v1/user/self 的 id 里复制。斯洛伐克站在 ID 后加 |sk。",
        "en": "Account ID is the User ID. It is not created. Copy id from account details or GET /v1/user/self. For the Slovak host, append |sk.",
        "ja": "Account ID は User ID で、作成しません。口座情報または GET /v1/user/self の id をコピー。スロバキアは末尾に |sk を付けます。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "API Key 或 secret 不对，或签名用的时间戳过期了。",
          "en": "API Key or secret is wrong, or the signed timestamp expired.",
          "ja": "API Key か secret が違うか、署名の時刻が期限切れです。"
        },
        "nextStep": {
          "zh": "回上一步重新生成 API 访问，两把一起换。",
          "en": "Go back a step, generate API access again, and replace both values.",
          "ja": "前の手順に戻り、API アクセスを作り直し、両方入れ替えてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这组凭据读不到该 User ID 的发票。",
          "en": "This pair cannot read invoices for that User ID.",
          "ja": "この組ではその User ID のインボイスを読めません。"
        },
        "nextStep": {
          "zh": "回上一步核对 User ID；斯洛伐克站记得加 |sk。",
          "en": "Go back a step and check the User ID; append |sk for the Slovak host.",
          "ja": "前の手順に戻り、User ID を確認してください。スロバキアは |sk を付けます。"
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
      "zh": "这个数字应该和后台本月正式发票一致。",
      "en": "This number should match this month’s issued invoices in the dashboard.",
      "ja": "この数字はダッシュボードの今月の正式インボイスと一致するはずです。"
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
        "zh": "打开 Customer Center 的 API management，点 Create a new token。必须用主账户，联系人账户不能建 token。",
        "en": "Open API management in the Customer Center and tap Create a new token. Use the main account; contact-person accounts cannot create tokens.",
        "ja": "Customer Center の API management を開き、Create a new token をタップします。本口座が必要で、連絡先アカウントでは作れません。"
      },
      {
        "zh": "备注和过期可选。确认账户密码后立刻复制。请求头是 Authorization: Bearer TOKEN。",
        "en": "Comment and expiration are optional. Confirm the account password, then copy immediately. Requests use Authorization: Bearer TOKEN.",
        "ja": "コメントと期限は任意です。口座パスワードを確認してすぐにコピー。リクエストは Authorization: Bearer TOKEN です。"
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
          "zh": "这个 token 被 IP 限制挡住了，或账户无权读发票。",
          "en": "This token is blocked by an IP restriction, or the account cannot read invoices.",
          "ja": "この token は IP 制限に阻まれたか、口座にインボイス読み取りがありません。"
        },
        "nextStep": {
          "zh": "回上一步用主账户重建，Access restrictions 先留空。",
          "en": "Go back a step, recreate it on the main account, and leave Access restrictions empty.",
          "ja": "前の手順に戻り、本口座で作り直し、Access restrictions は空のままにしてください。"
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
      "zh": "这个数字应该和后台本月发票一致。",
      "en": "This number should match this month’s invoices in the dashboard.",
      "ja": "この数字はダッシュボードの今月のインボイスと一致するはずです。"
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
          "zh": "Personal Token",
          "en": "Personal Token",
          "ja": "Personal Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Azion Console 的 Account Menu → Personal Tokens，点 + Personal Token，创建后立刻复制。",
        "en": "Open Azion Console Account Menu → Personal Tokens, tap + Personal Token, and copy it right away.",
        "ja": "Azion Console の Account Menu → Personal Tokens を開き、+ Personal Token をタップして、作成したらすぐにコピーします。"
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
    "credentialSetupURL": "https://console.azion.com",
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
        "key": "accessKeyID",
        "label": {
          "zh": "Application Credential ID",
          "en": "Application Credential ID",
          "ja": "Application Credential ID"
        },
        "isSecret": false
      },
      {
        "key": "secretAccessKey",
        "label": {
          "zh": "Application Credential Secret",
          "en": "Application Credential Secret",
          "ja": "Application Credential Secret"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Horizon 的 Identity → Application Credentials，点 Create Application Credential。ID 和 Secret 一起复制。",
        "en": "In Horizon open Identity → Application Credentials and tap Create Application Credential. Copy the ID and Secret together.",
        "ja": "Horizon の Identity → Application Credentials を開き、Create Application Credential をタップします。ID と Secret を一緒にコピーします。"
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
    "credentialSetupURL": "https://docs.elastx.cloud/docs/openstack-iaas/guides/application_credentials/",
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
          "zh": "Application Key",
          "en": "Application Key",
          "ja": "Application Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 WarpStream 控制台侧栏的 API Keys，新建一把 Application Key，然后复制。不要用 Agent Key。",
        "en": "Open API Keys in the WarpStream console sidebar, create an Application Key, and copy it. Don’t use an Agent Key.",
        "ja": "WarpStream コンソールのサイドバー API Keys を開き、Application Key を新規作成してコピーします。Agent Key は使わないでください。"
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
    "credentialSetupURL": "https://docs.warpstream.com/warpstream/reference/secrets-overview",
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
    "status": "available",
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
        "zh": "打开 CertCentral 的 Automation → API Keys，点 Add API Key。生成后立刻复制。",
        "en": "In CertCentral open Automation → API Keys and tap Add API Key. Copy it right away.",
        "ja": "CertCentral の Automation → API Keys を開き、Add API Key をタップします。生成したらすぐにコピーしてください。"
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
    "credentialSetupURL": "https://dev.digicert.com/certcentral-apis/authentication.html",
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
          "zh": "Organization token",
          "en": "Organization token",
          "ja": "Organization token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Deel 的 More → Developer → Access Tokens，点 Generate new token，选 Organization token，生成后立刻复制。",
        "en": "Open Deel More → Developer → Access Tokens, tap Generate new token, choose Organization token, and copy it right away.",
        "ja": "Deel の More → Developer → Access Tokens を開き、Generate new token をタップして Organization token を選び、生成したらすぐにコピーします。"
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
    "credentialSetupURL": "https://developer.deel.com/api/authentication",
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
          "zh": "API token",
          "en": "API token",
          "ja": "API token"
        },
        "isSecret": true,
        "hint": {
          "zh": "生产环境以 ra_live_ 开头",
          "en": "Production tokens start with ra_live_",
          "ja": "本番は ra_live_ で始まる"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Remote 的 Company Settings → Integrations & APIs → Integrations，点 Remote API，再点 Generate API token。",
        "en": "In Remote open Company Settings → Integrations & APIs → Integrations, tap Remote API, then Generate API token.",
        "ja": "Remote の Company Settings → Integrations & APIs → Integrations を開き、Remote API をタップしてから Generate API token をタップします。"
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
    "credentialSetupURL": "https://developer.remote.com/docs/authorization-for-customers",
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
          "zh": "Access Token",
          "en": "Access Token",
          "ja": "Access Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Oyster 的 Developer Tab，创建 Developer App 并授权，再用它换出 Access Token 后复制。",
        "en": "Open Oyster’s Developer Tab, create a Developer App, authorize it, then exchange it for an Access Token and copy that.",
        "ja": "Oyster の Developer Tab を開き、Developer App を作成して認可し、Access Token を取得してコピーします。"
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
    "credentialSetupURL": "https://docs.oysterhr.com/docs/customer-guide-to-creating-and-authorizing-a-developer-application",
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
        "key": "accessKeyID",
        "label": {
          "zh": "Access Key",
          "en": "Access Key",
          "ja": "Access Key"
        },
        "isSecret": false
      },
      {
        "key": "secretAccessKey",
        "label": {
          "zh": "Secret Key",
          "en": "Secret Key",
          "ja": "Secret Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Cockpit 右上角 Account Settings → Access Keys，点 Create Access Key。Access Key 和 Secret Key 一起复制。",
        "en": "In Cockpit open Account Settings → Access Keys and tap Create Access Key. Copy the Access Key and Secret Key together.",
        "ja": "Cockpit 右上の Account Settings → Access Keys を開き、Create Access Key をタップします。Access Key と Secret Key を一緒にコピーします。"
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
    "credentialSetupURL": "https://docs.outscale.com/en/userguide/Creating-an-Access-Key.html",
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
          "zh": "Contract ID",
          "en": "Contract ID",
          "ja": "Contract ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "Cloud Customer Space 里的 OCB000…",
          "en": "OCB000… in Cloud Customer Space",
          "ja": "Cloud Customer Space の OCB000…"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Orange Developer 的 My Apps，创建 Application。Credentials 里复制 Client Secret。订阅 Cloud Store Customer Space API 后，Orange 会另发一把 API Key，一并复制。",
        "en": "Open Orange Developer My Apps and create an Application. Copy the Client Secret from Credentials. After you subscribe the Cloud Store Customer Space API, Orange sends an API Key — copy that too.",
        "ja": "Orange Developer の My Apps を開き、Application を作成します。Credentials から Client Secret をコピーします。Cloud Store Customer Space API を申し込んだあと、Orange から別途届く API Key もコピーします。"
      },
      {
        "zh": "还需要 Contract ID。在 Cloud Customer Space 里复制，形如 OCB000…，不要创建。",
        "en": "You also need a Contract ID. Copy it from Cloud Customer Space — it looks like OCB000…. Don’t create one.",
        "ja": "Contract ID も必要です。Cloud Customer Space からコピーします。OCB000… の形で、作成するものではありません。"
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
    "credentialSetupURL": "https://developer.orange.com/myapps",
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
          "zh": "User UUID",
          "en": "User UUID",
          "ja": "User UUID"
        },
        "isSecret": false,
        "hint": {
          "zh": "Cloud Panel 里，和 API Token 一起",
          "en": "In the Cloud Panel, next to the API Token",
          "ja": "Cloud Panel の API Token と同じ場所"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Cloud Panel 的 API Token 页，创建一把，然后复制。",
        "en": "Open API Token in the Cloud Panel, create one, and copy it.",
        "ja": "Cloud Panel の API Token を開き、作成してコピーします。"
      },
      {
        "zh": "还需要 User UUID。在 Cloud Panel 里复制，不要创建。",
        "en": "You also need a User UUID. Copy it from the Cloud Panel — don’t create one.",
        "ja": "User UUID も必要です。Cloud Panel からコピーします。作成するものではありません。"
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
    "credentialSetupURL": "https://my.gridscale.io/APIKey",
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
          "zh": "Account Number",
          "en": "Account Number",
          "ja": "Account Number"
        },
        "isSecret": false,
        "hint": {
          "zh": "右上角 ACCOUNT 菜单顶部",
          "en": "Top of the ACCOUNT menu",
          "ja": "ACCOUNT メニューの一番上"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Cloud Control Panel 的 My Profile & Settings，在 Security Settings 里点 Show，复制 Rackspace API Key。",
        "en": "In the Cloud Control Panel open My Profile & Settings, tap Show under Security Settings, and copy the Rackspace API Key.",
        "ja": "Cloud Control Panel の My Profile & Settings を開き、Security Settings の Show をタップして Rackspace API Key をコピーします。"
      },
      {
        "zh": "还需要 Account Number。点右上角 ACCOUNT 菜单，顶部就是账号，复制即可，不要创建。",
        "en": "You also need an Account Number. Open the ACCOUNT menu at the top right — the number is at the top. Copy it; don’t create one.",
        "ja": "Account Number も必要です。右上の ACCOUNT メニューを開き、一番上の番号をコピーします。作成するものではありません。"
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
    "credentialSetupURL": "https://docs.rackspace.com/docs/view-and-reset-your-api-key",
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
        "zh": "打开 Pika 的 API keys，新建一把。",
        "en": "Open Pika API keys and create one.",
        "ja": "Pika の API keys を開き、新規作成します。"
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
    "credentialSetupURL": "https://dev.pika.art/keys",
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
        "zh": "打开 Hedra 的 API keys，生成一把。",
        "en": "Open Hedra API keys and generate one.",
        "ja": "Hedra の API keys を開き、生成します。"
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
    "credentialSetupURL": "https://www.hedra.com/develop/api-keys",
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
        "key": "accessKeyID",
        "label": {
          "zh": "Public Key",
          "en": "Public Key",
          "ja": "Public Key"
        },
        "isSecret": false
      },
      {
        "key": "secretAccessKey",
        "label": {
          "zh": "Private Key",
          "en": "Private Key",
          "ja": "Private Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 TiDB Cloud 的 Organization Settings → API Keys，点 Create API Key。Public Key 和 Private Key 一起复制。",
        "en": "In TiDB Cloud open Organization Settings → API Keys and tap Create API Key. Copy the Public Key and Private Key together.",
        "ja": "TiDB Cloud の Organization Settings → API Keys を開き、Create API Key をタップします。Public Key と Private Key を一緒にコピーします。"
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
    "credentialSetupURL": "https://docs.pingcap.com/tidbcloud/api/v1beta1/serverless",
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
        "zh": "打开 Hyperstack 控制台的 API Keys，生成一把。",
        "en": "Open API Keys in the Hyperstack console and generate one.",
        "ja": "Hyperstack コンソールの API Keys を開き、生成します。"
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
    "credentialSetupURL": "https://console.hyperstack.cloud/api-keys",
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
        "zh": "打开 HostUp 的 API management，创建一把 API Key。读账单勾 read:billing。",
        "en": "Open HostUp API management, create an API Key, and check read:billing for invoices.",
        "ja": "HostUp の API management を開き、API Key を作成します。請求を読むなら read:billing をオンにします。"
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
        "isSecret": true,
        "hint": {
          "zh": "32 位十六进制",
          "en": "32 hexadecimal characters",
          "ja": "32 桁の十六進数"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Memset Control Panel。有 Manage Users 权限的人可以管 API Keys。创建一把 API Key（32 位十六进制）。若限制 scope，method 里至少留 invoice.list。创建后复制。认证方式见 API 文档。",
        "en": "Open the Memset Control Panel. Anyone with Manage Users can manage API Keys. Create an API Key (32 hex digits). If you limit its scope, keep at least invoice.list under method. Copy it after creating. See the API docs for how authentication works.",
        "ja": "Memset Control Panel を開きます。Manage Users 権限があれば API Keys を管理できます。API Key（32 桁の十六進数）を作成します。scope を絞るなら method に invoice.list を残します。作成したらコピーします。認証の仕方は API ドキュメント を参照してください。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这个 API Key 无效，或者账号开了 IP 白名单却没放行当前出口。",
          "en": "This API Key is invalid, or the account has an IP whitelist that doesn’t include this exit.",
          "ja": "この API Key は無効か、IP ホワイトリストが今の出口を許可していません。"
        },
        "nextStep": {
          "zh": "回 Control Panel 重建一把 API Key，并确认 IP 白名单允许 API。",
          "en": "Go back to the Control Panel, create a new API Key, and confirm the IP whitelist allows the API.",
          "ja": "Control Panel に戻って API Key を作り直し、IP ホワイトリストが API を許可しているか確認してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 key 的 method scope 没有 invoice.list，所以读不到发票。",
          "en": "This key’s method scope doesn’t include invoice.list, so it can’t read invoices.",
          "ja": "この key の method scope に invoice.list がないため、インボイスを読めません。"
        },
        "nextStep": {
          "zh": "回上一步重建一把，method scope 至少包含 invoice.list，或不要加 method 限制。",
          "en": "Go back a step and recreate it with at least invoice.list in the method scope, or without a method restriction.",
          "ja": "前の手順に戻り、method scope に invoice.list を含めるか、method 制限なしで作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.memset.com/control/",
    "credentialSetupURL": "https://www.memset.com/apidocs/intro.html",
    "summary": {
      "zh": "英国托管云。按本月发票合计。",
      "en": "UK managed cloud. This month’s invoices, summed.",
      "ja": "英国のマネージドクラウド。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月发票合计一致。",
      "en": "This number should match this month’s invoice total in the dashboard.",
      "ja": "この数字はダッシュボードの今月のインボイス合計と一致するはずです。"
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
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Customer ID",
          "en": "Customer ID",
          "ja": "Customer ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "mStudio 里付账的那个客户 / 组织",
          "en": "The customer / organisation that pays in mStudio",
          "ja": "mStudio で支払い中の顧客 / 組織"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 mStudio 的 API tokens，新建一把。roles 勾 api_read 即可。创建后复制 token。",
        "en": "Open API tokens in mStudio and create one. Checking api_read for roles is enough. Copy the token after creating it.",
        "ja": "mStudio の API tokens を開き、新規作成します。roles は api_read で足ります。作成したら token をコピーします。"
      },
      {
        "zh": "在 mStudio 打开你付账的那个客户（Customer）页，复制 Customer ID。这是已有的组织编号，不要创建。",
        "en": "In mStudio, open the Customer that you pay from and copy the Customer ID. It’s an existing organisation number — don’t create one.",
        "ja": "mStudio で支払い中の Customer ページを開き、Customer ID をコピーします。既存の組織番号です。新規作成しないでください。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这个 API Token 无效，过期，或者已经被撤销。",
          "en": "This API Token is invalid, expired, or has already been revoked.",
          "ja": "この API Token は無効か、期限切れか、すでに取り消されています。"
        },
        "nextStep": {
          "zh": "回 API tokens 重新创建一把，创建后立刻复制。",
          "en": "Go back to API tokens, create a new one, and copy it right away.",
          "ja": "API tokens に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这个 token 没有 api_read，或看不到这个 Customer 的发票。",
          "en": "This token doesn’t have api_read, or it can’t see invoices for this Customer.",
          "ja": "この token に api_read がないか、この Customer のインボイスが見えません。"
        },
        "nextStep": {
          "zh": "确认 roles 含 api_read，并且 Customer ID 是你付账的那个组织。",
          "en": "Confirm roles include api_read, and the Customer ID is the organisation you pay from.",
          "ja": "roles に api_read があり、Customer ID が支払い中の組織か確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://my.mittwald.de",
    "credentialSetupURL": "https://studio.mittwald.de/app/profile/api-tokens",
    "summary": {
      "zh": "德国应用托管。按本月发票合计。",
      "en": "German app hosting. This month’s invoices, summed.",
      "ja": "ドイツのアプリホスティング。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 mStudio 里该客户本月发票合计一致。",
      "en": "This number should match this month’s invoice total for that customer in mStudio.",
      "ja": "この数字は mStudio のその顧客の今月のインボイス合計と一致するはずです。"
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
          "zh": "AuthKey Secret",
          "en": "AuthKey Secret",
          "ja": "AuthKey Secret"
        },
        "isSecret": true,
        "hint": {
          "zh": "只显示一次",
          "en": "shown only once",
          "ja": "一度しか表示されません"
        }
      },
      {
        "key": "accessKeyID",
        "label": {
          "zh": "AuthKey ID",
          "en": "AuthKey ID",
          "ja": "AuthKey ID"
        },
        "isSecret": false
      }
    ],
    "steps": [
      {
        "zh": "打开 Soracom User Console，点账号菜单 → Security → AuthKeys，再点 Generate an AuthKey。AuthKey Secret 只显示一次，立刻复制。给 SAM 用户开的话，进 Users → 该用户 → Authentication。",
        "en": "Open the Soracom User Console. From the account menu go to Security → AuthKeys, then tap Generate an AuthKey. The AuthKey Secret is shown once — copy it right away. For a SAM user, open Users → that user → Authentication.",
        "ja": "Soracom User Console を開き、アカウントメニュー → Security → AuthKeys から Generate an AuthKey をタップします。AuthKey Secret は一度しか出ないので、すぐにコピーします。SAM ユーザーなら Users → そのユーザー → Authentication です。"
      },
      {
        "zh": "同一对话框里还有 AuthKey ID，一并复制。不要单独再创建一把。给 SAM 用户用时，Permissions 至少要能读账单（Billing）。",
        "en": "The same dialog also shows the AuthKey ID — copy it too. Don’t generate a second pair. For a SAM user, Permissions must at least be able to read billing (Billing).",
        "ja": "同じダイアログに AuthKey ID もあるので、一緒にコピーします。もう一組作らないでください。SAM ユーザーなら Permissions に少なくとも Billing の読み取りが必要です。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "AuthKey ID 或 Secret 不对，或者 Secret 当时没复制下来。",
          "en": "The AuthKey ID or Secret is wrong, or the Secret wasn’t copied when it was shown.",
          "ja": "AuthKey ID か Secret が違うか、表示中に Secret をコピーしていません。"
        },
        "nextStep": {
          "zh": "回 AuthKeys 重新 Generate an AuthKey，Secret 显示时立刻复制。",
          "en": "Go back to AuthKeys, Generate an AuthKey again, and copy the Secret while it’s on screen.",
          "ja": "AuthKeys に戻って Generate an AuthKey し直し、表示中に Secret をコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 AuthKey 所属用户没有 Billing 权限。",
          "en": "The user this AuthKey belongs to doesn’t have Billing permission.",
          "ja": "この AuthKey のユーザーに Billing 権限がありません。"
        },
        "nextStep": {
          "zh": "给对应 SAM 用户加上 Billing 读取，或改用 Root 用户的 AuthKey。",
          "en": "Give that SAM user Billing read access, or use an AuthKey from the Root user.",
          "ja": "その SAM ユーザーに Billing の読み取りを付けるか、Root ユーザーの AuthKey を使ってください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://console.soracom.io",
    "credentialSetupURL": "https://developers.soracom.io/en/docs/security/authkeys",
    "summary": {
      "zh": "物联网蜂窝连接。按本月用量。",
      "en": "IoT cellular connectivity. This month’s usage.",
      "ja": "IoT セルラー接続。今月の用量です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 User Console 本月账单一致。",
      "en": "This number should match this month’s bill in the User Console.",
      "ja": "この数字は User Console の今月の請求と一致するはずです。"
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
          "zh": "Access Token",
          "en": "Access Token",
          "ja": "Access Token"
        },
        "isSecret": true,
        "hint": {
          "zh": "用 Service Account 换来的 Bearer JWT",
          "en": "Bearer JWT from the service account",
          "ja": "サービスアカウントから取得した Bearer JWT"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Starlink 账户 Settings。企业账号才有 API Service Accounts。点 Add Service Account，选好权限后记下 Client ID 和 Client Secret。",
        "en": "Open Starlink account Settings. Only enterprise accounts have API Service Accounts. Tap Add Service Account, choose permissions, then write down the Client ID and Client Secret.",
        "ja": "Starlink のアカウント Settings を開きます。API Service Accounts は企業アカウントにあります。Add Service Account をタップし、権限を選んで Client ID と Client Secret を控えます。"
      },
      {
        "zh": "用 Client ID 和 Client Secret 走 client_credentials，向 Starlink token 端点换一把 Bearer Access Token，把这把 token 贴进来。过期后要再换。",
        "en": "Exchange the Client ID and Client Secret for a Bearer Access Token with client_credentials against the Starlink token endpoint, then paste that token. You’ll need a new one after it expires.",
        "ja": "Client ID と Client Secret を client_credentials で Starlink の token エンドポイントに渡し、Bearer Access Token を取得して貼ります。期限が切れたら取り直します。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "Access Token 过期了，或 Client Secret 已经轮换。",
          "en": "The Access Token expired, or the Client Secret has been rotated.",
          "ja": "Access Token の期限が切れたか、Client Secret がローテーションされています。"
        },
        "nextStep": {
          "zh": "用同一组 Client ID / Secret 再换一把 Access Token。Secret 丢了就在 Service Accounts 里再生成一把。",
          "en": "Exchange the same Client ID / Secret for a new Access Token. If the Secret is gone, generate another one under Service Accounts.",
          "ja": "同じ Client ID / Secret で Access Token を取り直してください。Secret を失くしたら Service Accounts で再発行します。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这个 Service Account 没有账单权限，或账号不是企业 API 覆盖范围。",
          "en": "This service account doesn’t have billing permission, or the account isn’t in the enterprise API coverage.",
          "ja": "このサービスアカウントに請求権限がないか、企業 API の対象外です。"
        },
        "nextStep": {
          "zh": "确认创建人有 Admin 或 Service Account Management，并且权限里包含账单。",
          "en": "Confirm the creator has Admin or Service Account Management, and that permissions include billing.",
          "ja": "作成者が Admin または Service Account Management を持ち、権限に請求が含まれるか確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.starlink.com/account",
    "credentialSetupURL": "https://www.starlink.com/account/settings",
    "summary": {
      "zh": "低轨卫星宽带。按本月发票合计。",
      "en": "Low-earth-orbit satellite broadband. This month’s invoices, summed.",
      "ja": "低軌道衛星ブロードバンド。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 Starlink 账户本月发票合计一致。住宅套餐通常没有 API。",
      "en": "This number should match this month’s invoice total on the Starlink account. Residential plans usually have no API.",
      "ja": "この数字は Starlink アカウントの今月のインボイス合計と一致するはずです。住宅プランに API は通常ありません。"
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
          "zh": "Personal Access Token",
          "en": "Personal Access Token",
          "ja": "Personal Access Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Tibber 的 Access Tokens，用自己的 Tibber 账号登录，新建一把 Personal Access Token。读的是这把 token 对应的用电花费。",
        "en": "Open Tibber Access Tokens, sign in with your own Tibber account, and create a Personal Access Token. It reads the electricity spend for this token.",
        "ja": "Tibber の Access Tokens を開き、自分の Tibber アカウントでログインして Personal Access Token を新規作成します。この token に対応する電気代を読みます。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这个 Personal Access Token 无效，或者已经被撤销。",
          "en": "This Personal Access Token is invalid, or it has already been revoked.",
          "ja": "この Personal Access Token は無効か、すでに取り消されています。"
        },
        "nextStep": {
          "zh": "回 Access Tokens 重新创建一把。",
          "en": "Go back to Access Tokens and create a new one.",
          "ja": "Access Tokens に戻って作り直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 token 的 scope 读不到用电数据。",
          "en": "This token’s scopes can’t read electricity usage.",
          "ja": "この token の scope では電気の使用量を読めません。"
        },
        "nextStep": {
          "zh": "回 Access Tokens 重建一把，scope 勾选能读家用电量和费用的那几项。",
          "en": "Go back to Access Tokens and create one whose scopes can read home consumption and cost.",
          "ja": "Access Tokens に戻り、家庭の消費量と料金を読める scope で作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://tibber.com",
    "credentialSetupURL": "https://developer.tibber.com/settings/access-token",
    "summary": {
      "zh": "北欧电力零售。按本月用电花费。",
      "en": "Nordic electricity retail. This month’s electricity spend.",
      "ja": "北欧の電力小売。今月の電気代です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 Tibber 应用里本月用电花费一致。",
      "en": "This number should match this month’s electricity spend in the Tibber app.",
      "ja": "この数字は Tibber アプリの今月の電気代と一致するはずです。"
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
        "isSecret": true,
        "hint": {
          "zh": "创建 API User 时自己设定",
          "en": "You set this when creating the API User",
          "ja": "API User 作成時に自分で設定します"
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
          "zh": "账号号 + 下划线 + 用户名",
          "en": "Account number, then an underscore, then the username",
          "ja": "アカウント番号、アンダースコア、ユーザー名"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 1NCE Customer Portal 的 Users，点 New User，角色选 API User。创建时自己设定 Client Secret 并立刻记下——这个角色没有邮箱，Secret 不会再寄给你。",
        "en": "Open Users in the 1NCE Customer Portal, tap New User, and set the role to API User. Set the Client Secret yourself at creation and write it down right away — this role has no email, so the Secret is never sent to you.",
        "ja": "1NCE Customer Portal の Users を開き、New User で役割を API User にします。作成時に Client Secret を自分で決め、すぐに控えます。この役割にメールはなく、Secret は送られてきません。"
      },
      {
        "zh": "同一张表会给出 Client ID。它带账号号前缀和下划线，不要自己编。Owner 账号本身也能调 Management API，但推荐单独的 API User。",
        "en": "The same form shows the Client ID. It has an account-number prefix and an underscore — don’t invent one. The Owner account can call the Management API too, but a dedicated API User is better.",
        "ja": "同じフォームに Client ID が出ます。アカウント番号の接頭辞とアンダースコア付きです。自分で作らないでください。Owner アカウントでも Management API は呼べますが、専用の API User がよいです。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "Client ID 或 Client Secret 不对。",
          "en": "The Client ID or Client Secret is wrong.",
          "ja": "Client ID か Client Secret が違います。"
        },
        "nextStep": {
          "zh": "回 Users 核对 Client ID 的账号前缀，或新建一个 API User 并重设 Secret。",
          "en": "Go back to Users and check the account prefix on the Client ID, or create a new API User and set the Secret again.",
          "ja": "Users に戻って Client ID のアカウント接頭辞を確認するか、新しい API User を作って Secret を設定し直してください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这个用户不是 API User / Owner，调不了 Management API。",
          "en": "This user isn’t an API User or Owner, so it can’t call the Management API.",
          "ja": "このユーザーは API User / Owner ではないため、Management API を呼べません。"
        },
        "nextStep": {
          "zh": "确认角色是 API User，或改用 Owner。",
          "en": "Confirm the role is API User, or use the Owner instead.",
          "ja": "役割が API User か、Owner を使うか確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://portal.1nce.com",
    "credentialSetupURL": "https://portal.1nce.com/portal/customer/users",
    "summary": {
      "zh": "物联网蜂窝流量卡。按本月用量。",
      "en": "IoT cellular SIMs. This month’s usage.",
      "ja": "IoT セルラー SIM。今月の用量です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和门户本月订单发票合计一致。",
      "en": "This number should match this month’s order invoices in the portal.",
      "ja": "この数字はポータルの今月の注文インボイス合計と一致するはずです。"
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
          "zh": "Account number",
          "en": "Account number",
          "ja": "Account number"
        },
        "isSecret": false,
        "hint": {
          "zh": "以 A- 开头，在仪表盘或账单上",
          "en": "Starts with A-, on the dashboard or a bill",
          "ja": "A- で始まります。ダッシュボードまたは請求書"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Octopus Energy 账户的 Personal details → Developer settings，进入 API access，复制或生成 API Key。手机 App 里往往没有这一页，用网页。",
        "en": "Open Personal details → Developer settings on your Octopus Energy account, then API access, and copy or generate an API Key. The mobile app often doesn’t show this page — use the website.",
        "ja": "Octopus Energy アカウントの Personal details → Developer settings を開き、API access で API Key をコピーまたは生成します。モバイルアプリにはこのページがないことが多いので、ウェブを使います。"
      },
      {
        "zh": "在账户仪表盘或账单上复制 Account number，一般是 A- 开头。这是已有编号，不要创建。",
        "en": "Copy the Account number from the account dashboard or a bill. It usually starts with A-. It’s an existing number — don’t create one.",
        "ja": "アカウントのダッシュボードまたは請求書から Account number をコピーします。だいたい A- で始まります。既存の番号です。新規作成しないでください。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这个 API Key 无效，或者已经被重新生成。",
          "en": "This API Key is invalid, or it has already been regenerated.",
          "ja": "この API Key は無効か、すでに再生成されています。"
        },
        "nextStep": {
          "zh": "回 Developer settings 的 API access 重新生成一把，立刻复制。",
          "en": "Go back to API access under Developer settings, generate a new one, and copy it right away.",
          "ja": "Developer settings の API access に戻って作り直し、すぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "Account number 对不上这把 API Key，或账号还没开通智能电表费用。",
          "en": "The Account number doesn’t match this API Key, or cost-of-usage isn’t enabled on the account yet.",
          "ja": "Account number がこの API Key と一致しないか、アカウントで使用料金がまだ有効ではありません。"
        },
        "nextStep": {
          "zh": "确认 Account number 带 A- 前缀，并且属于签发这把 key 的那个账户。",
          "en": "Confirm the Account number has the A- prefix and belongs to the account that issued this key.",
          "ja": "Account number に A- 接頭辞があり、この key を発行したアカウントのものか確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://octopus.energy",
    "credentialSetupURL": "https://octopus.energy/dashboard/new/accounts/personal-details",
    "summary": {
      "zh": "英国电力零售。按周期用电花费。",
      "en": "UK electricity retail. Usage cost for the billing period.",
      "ja": "英国の電力小売。請求周期の電気代です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 Octopus 账户该周期用电花费一致。",
      "en": "This number should match electricity spend for the billing period on the Octopus account.",
      "ja": "この数字は Octopus アカウントの当該周期の電気代と一致するはずです。"
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
          "zh": "Client Access Token",
          "en": "Client Access Token",
          "ja": "Client Access Token"
        },
        "isSecret": true,
        "hint": {
          "zh": "Share My Data 连通测试发给你的",
          "en": "Issued during Share My Data connectivity testing",
          "ja": "Share My Data の接続テストで発行されます"
        }
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Subscription ID",
          "en": "Subscription ID",
          "ja": "Subscription ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "自助授权后的 Authorization 资源里",
          "en": "From the Authorization resource after self-access",
          "ja": "セルフアクセス後の Authorization リソース"
        }
      },
      {
        "key": "projectID",
        "label": {
          "zh": "Usage Point ID",
          "en": "Usage Point ID",
          "ja": "Usage Point ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "你授权的那个服务 / 用电点",
          "en": "The service / usage point you authorised",
          "ja": "認可したサービス / 使用ポイント"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 PG&E Share My Data，按 Self Access 注册并完成连通测试。测试通过后会发给你 Client Access Token，复制这把，不是网上随便点出来的 API Key。",
        "en": "Open PG&E Share My Data, register as Self Access, and finish connectivity testing. After you pass, you’re given a Client Access Token — copy that, not a generic API key.",
        "ja": "PG&E の Share My Data を開き、Self Access で登録して接続テストを完了します。合格後に Client Access Token が渡されるので、それをコピーします。一般的な API Key ではありません。"
      },
      {
        "zh": "登录 PG&E 网上账户，打开 Share My Data，给自己建一条授权并勾选 Service ID。再用 Client Access Token 读 Authorization 资源，复制 Subscription ID 和 Usage Point ID。这两项是授权结果，不要创建。",
        "en": "Sign in to your PG&E online account, open Share My Data, create a self-access authorization, and select the Service IDs. Then use the Client Access Token to read the Authorization resource and copy the Subscription ID and Usage Point ID. They’re the result of authorization — don’t create them.",
        "ja": "PG&E のオンラインアカウントにログインし、Share My Data で自分向けの認可を作り、Service ID を選びます。Client Access Token で Authorization リソースを読み、Subscription ID と Usage Point ID をコピーします。認可の結果であり、新規作成しません。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "Client Access Token 过期了，或还没完成连通测试。",
          "en": "The Client Access Token expired, or connectivity testing isn’t finished.",
          "ja": "Client Access Token の期限が切れたか、接続テストが終わっていません。"
        },
        "nextStep": {
          "zh": "回 Share My Data 门户把连通测试跑完，用测试发给你的那把 Client Access Token。",
          "en": "Go back to the Share My Data portal, finish connectivity testing, and use the Client Access Token they issued.",
          "ja": "Share My Data ポータルに戻り、接続テストを完了して発行された Client Access Token を使ってください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这个 Subscription 还没授权，或 Usage Point 不在授权范围内。",
          "en": "This Subscription isn’t authorised yet, or the Usage Point isn’t in the authorization.",
          "ja": "この Subscription がまだ認可されていないか、Usage Point が認可の範囲外です。"
        },
        "nextStep": {
          "zh": "回网上账户的 Share My Data，确认给自己授权了对应的 Service ID。",
          "en": "Go back to Share My Data in your online account and confirm you authorised the matching Service IDs for yourself.",
          "ja": "オンラインアカウントの Share My Data に戻り、該当の Service ID を自分に認可したか確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.pge.com",
    "credentialSetupURL": "https://sharemydata.pge.com/",
    "summary": {
      "zh": "加州电力账单。按上一期账单金额。",
      "en": "California electricity. The last billed period’s amount.",
      "ja": "カリフォルニアの電気代。直前の請求額です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和上一期电费账单金额接近。Green Button 金额是上一结算周期，不是日历月至今。",
      "en": "This number should be close to the last electricity bill. Green Button amounts are the previous billing period, not month-to-date.",
      "ja": "この数字は直前の電気代に近いはずです。Green Button の金額は前の請求周期であり、今月これまでの額ではありません。"
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
          "zh": "Access Token",
          "en": "Access Token",
          "ja": "Access Token"
        },
        "isSecret": true,
        "hint": {
          "zh": "Green Button Connect 授权码换来的",
          "en": "From the Green Button Connect authorization code",
          "ja": "Green Button Connect の認可コードから取得"
        }
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Subscription ID",
          "en": "Subscription ID",
          "ja": "Subscription ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "Connect My Data 授权后的 Authorization 资源里",
          "en": "From the Authorization resource after Connect My Data",
          "ja": "Connect My Data 認可後の Authorization リソース"
        }
      },
      {
        "key": "projectID",
        "label": {
          "zh": "Usage Point ID",
          "en": "Usage Point ID",
          "ja": "Usage Point ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "已授权订阅里的用电点",
          "en": "The usage point in the authorised subscription",
          "ja": "認可されたサブスクリプション内の使用ポイント"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Con Edison 的第三方注册页，提交 Green Button Connect 注册并完成技术接入。用户授权后，用授权码向 token 端点换 Access Token。个人网上账户没有自助创建 API Key 这一步。",
        "en": "Open Con Edison’s third-party registration, submit Green Button Connect registration, and finish technical onboarding. After the customer authorizes, exchange the authorization code at the token endpoint for an Access Token. A personal My Account login has no self-serve API key.",
        "ja": "Con Edison のサードパーティ登録ページを開き、Green Button Connect の登録と技術オンボーディングを完了します。顧客が認可したら、認可コードを token エンドポイントで Access Token に換えます。個人の My Account にセルフサービスの API Key はありません。"
      },
      {
        "zh": "客户在 My Account 的 Billing & Usage → Share My Data 授权之后，从 Authorization 资源复制 Subscription ID 和 Usage Point ID。这两项是授权结果，不要创建。",
        "en": "After the customer authorizes under Billing & Usage → Share My Data in My Account, copy the Subscription ID and Usage Point ID from the Authorization resource. They’re the result of authorization — don’t create them.",
        "ja": "顧客が My Account の Billing & Usage → Share My Data で認可したあと、Authorization リソースから Subscription ID と Usage Point ID をコピーします。認可の結果であり、新規作成しません。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "Access Token 过期了（文档写明会过期），或第三方还没完成接入。",
          "en": "The Access Token expired (the onboarding doc says they expire), or third-party onboarding isn’t finished.",
          "ja": "Access Token の期限が切れたか（オンボーディング資料に期限あり）、サードパーティ登録が終わっていません。"
        },
        "nextStep": {
          "zh": "用 refresh token 再换一把 Access Token。还没注册就先走完 Green Button Connect 接入。",
          "en": "Exchange the refresh token for a new Access Token. If you haven’t registered yet, finish Green Button Connect onboarding first.",
          "ja": "refresh token で Access Token を取り直してください。未登録なら先に Green Button Connect のオンボーディングを完了します。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这个 Subscription 没有有效授权，或授权闲置超过 45 天被收回。",
          "en": "This Subscription has no valid authorization, or it was revoked after more than 45 days of inactivity.",
          "ja": "この Subscription に有効な認可がないか、45 日以上使われず取り消されています。"
        },
        "nextStep": {
          "zh": "请客户在 My Account 的 Share My Data 里重新授权。",
          "en": "Ask the customer to re-authorize under Share My Data in My Account.",
          "ja": "顧客に My Account の Share My Data で再認可してもらってください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.coned.com",
    "credentialSetupURL": "https://www.coned.com/en/accounts-billing/share-energy-usage-data/become-a-third-party",
    "summary": {
      "zh": "纽约电力账单。按上一期账单金额。",
      "en": "New York electricity. The last billed period’s amount.",
      "ja": "ニューヨークの電気代。直前の請求額です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和上一期电费账单金额接近。Green Button 金额是上一结算周期。",
      "en": "This number should be close to the last electricity bill. Green Button amounts are the previous billing period.",
      "ja": "この数字は直前の電気代に近いはずです。Green Button の金額は前の請求周期です。"
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
        "isSecret": true,
        "hint": {
          "zh": "只显示一次；同一屏还有 Client ID",
          "en": "Shown once; Client ID is on the same screen",
          "ja": "一度しか表示されません。同じ画面に Client ID もあります"
        }
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Account UUID",
          "en": "Account UUID",
          "ja": "Account UUID"
        },
        "isSecret": false,
        "hint": {
          "zh": "OAuth clients 页上的，不要带 urn:dtaccount: 前缀",
          "en": "From the OAuth clients page, without the urn:dtaccount: prefix",
          "ja": "OAuth clients ページ。urn:dtaccount: 接頭辞は除く"
        }
      },
      {
        "key": "projectID",
        "label": {
          "zh": "Subscription UUID",
          "en": "Subscription UUID",
          "ja": "Subscription UUID"
        },
        "isSecret": false,
        "hint": {
          "zh": "平台订阅，不是某个监控环境",
          "en": "The Dynatrace Platform Subscription, not a monitoring environment",
          "ja": "Dynatrace Platform Subscription。監視環境ではありません"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Account Management → Identity & access management → OAuth clients，点 Create client。Grant type 选 Client credentials，权限勾 account-uac-read。创建后立刻复制 Client Secret（只显示一次）。同一屏的 Client ID 也要记下。",
        "en": "Open Account Management → Identity & access management → OAuth clients and tap Create client. Set Grant type to Client credentials and check account-uac-read. Copy the Client Secret right away — it’s shown once. Write down the Client ID on the same screen.",
        "ja": "Account Management → Identity & access management → OAuth clients を開き、Create client をタップします。Grant type は Client credentials、権限は account-uac-read。Client Secret は一度しか出ないのですぐコピーします。同じ画面の Client ID も控えます。"
      },
      {
        "zh": "还在 OAuth clients 页复制 Account UUID（urn:dtaccount: 后面那一段，不要创建）。再到 Account Management 的订阅列表复制 Subscription UUID。",
        "en": "Still on the OAuth clients page, copy the Account UUID (the part after urn:dtaccount: — don’t create one). Then copy the Subscription UUID from the subscriptions list in Account Management.",
        "ja": "OAuth clients ページで Account UUID（urn:dtaccount: の後ろ。新規作成しない）をコピーします。続いて Account Management のサブスクリプション一覧から Subscription UUID をコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "Client Secret 错了，或当时没复制下来。",
          "en": "The Client Secret is wrong, or it wasn’t copied when it was shown.",
          "ja": "Client Secret が違うか、表示中にコピーしていません。"
        },
        "nextStep": {
          "zh": "回 OAuth clients 重建一个 Client credentials 客户端，Secret 显示时立刻复制。",
          "en": "Go back to OAuth clients, create another Client credentials client, and copy the Secret while it’s on screen.",
          "ja": "OAuth clients に戻り、Client credentials のクライアントを作り直し、表示中に Secret をコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这个客户端没有 account-uac-read，或 Account UUID / Subscription UUID 对不上。",
          "en": "This client doesn’t have account-uac-read, or the Account UUID / Subscription UUID doesn’t match.",
          "ja": "このクライアントに account-uac-read がないか、Account UUID / Subscription UUID が一致しません。"
        },
        "nextStep": {
          "zh": "重建客户端并勾 account-uac-read。UUID 从 OAuth clients 和订阅列表抄，不要手打。",
          "en": "Recreate the client with account-uac-read checked. Copy the UUIDs from OAuth clients and the subscriptions list — don’t type them.",
          "ja": "account-uac-read を付けて作り直してください。UUID は OAuth clients とサブスクリプション一覧からコピーし、手入力しないでください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://myaccount.dynatrace.com",
    "credentialSetupURL": "https://docs.dynatrace.com/docs/manage/identity-access-management/access-tokens-and-oauth-clients/oauth-clients",
    "summary": {
      "zh": "企业 APM 和可观测性。按订阅成本。",
      "en": "Enterprise APM and observability. Subscription cost.",
      "ja": "企業向け APM と可観測性。サブスクリプションコストです。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 Account Management 里该平台订阅的成本一致。",
      "en": "This number should match the platform subscription cost in Account Management.",
      "ja": "この数字は Account Management のそのプラットフォーム サブスクリプションのコストと一致するはずです。"
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
          "zh": "Access Token",
          "en": "Access Token",
          "ja": "Access Token"
        },
        "isSecret": true,
        "hint": {
          "zh": "Server-to-Server OAuth 换来的 Bearer token",
          "en": "Bearer token from Server-to-Server OAuth",
          "ja": "Server-to-Server OAuth から取得した Bearer token"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Zoom App Marketplace，Develop → Build an app，选 Server-to-Server OAuth。Scopes 加上 billing:read:list_invoices:admin。填完 Information 后必须 Activation，否则换不了 token。",
        "en": "Open the Zoom App Marketplace, go to Develop → Build an app, and choose Server-to-Server OAuth. Add the billing:read:list_invoices:admin scope. Complete Information and Activation — you can’t mint a token until the app is activated.",
        "ja": "Zoom App Marketplace を開き、Develop → Build an app で Server-to-Server OAuth を選びます。Scopes に billing:read:list_invoices:admin を追加します。Information のあと Activation が必要で、有効化しないと token を取れません。"
      },
      {
        "zh": "在 App credentials 记下 Account ID、Client ID、Client Secret。用 account_credentials 换一把 Access Token，把这把 Bearer token 贴进来。它大约一小时过期，过期后再换。需要 Pro 及以上，且账号有 Zoom for developers / Server-to-Server OAuth 角色。",
        "en": "On App credentials, write down the Account ID, Client ID, and Client Secret. Exchange them with account_credentials for an Access Token and paste that Bearer token. It expires in about an hour, then you mint another. You need Pro or above, plus the Zoom for developers / Server-to-Server OAuth role.",
        "ja": "App credentials で Account ID、Client ID、Client Secret を控えます。account_credentials で Access Token を取得し、その Bearer token を貼ります。およそ 1 時間で切れるので、切れたら取り直します。Pro 以上と Zoom for developers / Server-to-Server OAuth のロールが必要です。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "Access Token 过期了，或应用被停用。",
          "en": "The Access Token expired, or the app was deactivated.",
          "ja": "Access Token の期限が切れたか、アプリが無効です。"
        },
        "nextStep": {
          "zh": "用同一组 App credentials 再换一把 token。应用必须保持 Activation。",
          "en": "Mint another token with the same App credentials. The app must stay Activated.",
          "ja": "同じ App credentials で token を取り直してください。アプリは Activation のままにしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "缺少 billing:read:list_invoices:admin，或账号不是 Pro。",
          "en": "The app is missing billing:read:list_invoices:admin, or the account isn’t Pro.",
          "ja": "billing:read:list_invoices:admin がないか、アカウントが Pro ではありません。"
        },
        "nextStep": {
          "zh": "回 Scopes 补上账单只读范围，保存后再 Activation。确认套餐是 Pro 或更高。",
          "en": "Add the billing read scope under Scopes, save, then Activation again. Confirm the plan is Pro or higher.",
          "ja": "Scopes に請求の読み取りを足して保存し、もう一度 Activation してください。プランが Pro 以上か確認します。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://zoom.us/billing",
    "credentialSetupURL": "https://marketplace.zoom.us/develop/create",
    "summary": {
      "zh": "视频会议。按本月发票合计。",
      "en": "Video meetings. This month’s invoices, summed.",
      "ja": "ビデオ会議。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 Zoom Billing 本月发票合计一致。需要 Pro 及以上。",
      "en": "This number should match this month’s invoice total in Zoom Billing. Pro or above is required.",
      "ja": "この数字は Zoom Billing の今月のインボイス合計と一致するはずです。Pro 以上が必要です。"
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
        "isSecret": true,
        "hint": {
          "zh": "用 Production token，不要用 sandbox",
          "en": "Use the Production token, not sandbox",
          "ja": "sandbox ではなく Production token を使う"
        }
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Username",
          "en": "Username",
          "ja": "Username"
        },
        "isSecret": false,
        "hint": {
          "zh": "登录用户名，不是另外创建的 ID",
          "en": "The Name.com login username, not an ID you create",
          "ja": "Name.com のログインユーザー名。自分で作る ID ではありません"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Name.com 的 API Tokens，点 Create API Token，同意协议后 Generate new token。复制上面那条 Production token，不要用下面的 Development / sandbox。开了 2FA 的，还要在 Security 里打开 API Access。",
        "en": "Open Name.com API Tokens, tap Create API Token, accept the agreement, then Generate new token. Copy the Production token at the top, not the Development / sandbox one below. If 2FA is on, also turn on API Access under Security.",
        "ja": "Name.com の API Tokens を開き、Create API Token で規約に同意して Generate new token します。上の Production token をコピーし、下の Development / sandbox は使いません。2FA を付けている場合は Security で API Access もオンにします。"
      },
      {
        "zh": "复制 Name.com 登录用的 Username。HTTP Basic 用的是用户名 + API Token，不是另外创建一个 Account ID。用 Google/SSO 注册的，用户名往往就是邮箱。",
        "en": "Copy the Username you sign in to Name.com with. HTTP Basic uses username + API Token — don’t create a separate Account ID. If you signed up with Google/SSO, the username is often the email.",
        "ja": "Name.com のログイン Username をコピーします。HTTP Basic はユーザー名 + API Token で、別の Account ID は作りません。Google/SSO で登録した場合、ユーザー名はメールアドレスであることが多いです。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "用户名或 Production token 不对，或开了 2FA 却没打开 API Access。",
          "en": "The username or Production token is wrong, or 2FA is on without API Access.",
          "ja": "ユーザー名か Production token が違うか、2FA のまま API Access がオフです。"
        },
        "nextStep": {
          "zh": "确认用的是 Production token。开了 2FA 就去 Security 打开 API Access，或重新 Generate new token。",
          "en": "Confirm you’re using the Production token. If 2FA is on, turn on API Access under Security, or Generate new token again.",
          "ja": "Production token を使っているか確認してください。2FA なら Security で API Access をオンにするか、Generate new token し直します。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这个 token 读不到订单，或账号没有 API 权限。",
          "en": "This token can’t read orders, or the account doesn’t have API access.",
          "ja": "この token では注文を読めないか、アカウントに API 権限がありません。"
        },
        "nextStep": {
          "zh": "回 API Tokens 用 Production token 重建一把，并确认 API Access 已打开。",
          "en": "Go back to API Tokens, create a new Production token, and confirm API Access is on.",
          "ja": "API Tokens に戻り Production token を作り直し、API Access がオンか確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.name.com",
    "credentialSetupURL": "https://www.name.com/account/settings/api",
    "summary": {
      "zh": "美国域名注册。按本月订单合计。",
      "en": "US domain registration. This month’s orders, summed.",
      "ja": "米国のドメイン登録。今月の注文合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月订单合计一致。",
      "en": "This number should match this month’s orders in the dashboard.",
      "ja": "この数字はダッシュボードの今月の注文合計と一致するはずです。"
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
          "zh": "Application Secret",
          "en": "Application Secret",
          "ja": "Application Secret"
        },
        "isSecret": true,
        "hint": {
          "zh": "AS，只显示一次",
          "en": "AS, shown only once",
          "ja": "AS。一度しか表示されません"
        }
      },
      {
        "key": "clientSecret",
        "label": {
          "zh": "Consumer Key",
          "en": "Consumer Key",
          "ja": "Consumer Key"
        },
        "isSecret": true,
        "hint": {
          "zh": "CK，只显示一次",
          "en": "CK, shown only once",
          "ja": "CK。一度しか表示されません"
        }
      },
      {
        "key": "accessKeyID",
        "label": {
          "zh": "Application Key",
          "en": "Application Key",
          "ja": "Application Key"
        },
        "isSecret": false,
        "hint": {
          "zh": "AK，同一屏给出",
          "en": "AK, shown on the same screen",
          "ja": "AK。同じ画面に出ます"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 OVHcloud 的 createToken 页，填应用名。Validity 选 Unlimited。Rights 给 GET /me/bill*。点 Create keys 后立刻复制 Application Secret（AS）和 Consumer Key（CK），离开页面就没了。",
        "en": "Open OVHcloud’s createToken page and name the app. Set Validity to Unlimited. Under Rights allow GET /me/bill*. After Create keys, copy the Application Secret (AS) and Consumer Key (CK) right away — they won’t be shown again.",
        "ja": "OVHcloud の createToken ページを開き、アプリ名を入れます。Validity は Unlimited。Rights は GET /me/bill*。Create keys のあと Application Secret（AS）と Consumer Key（CK）をすぐにコピーします。この画面を離れると再表示されません。"
      },
      {
        "zh": "同一结果页还有 Application Key（AK），一并复制。三把钥匙一次生成，不要再单独创建。",
        "en": "The same result page also shows the Application Key (AK) — copy it too. All three keys are issued together; don’t create another set.",
        "ja": "同じ結果ページに Application Key（AK）もあるので、一緒にコピーします。3 つの鍵は一度に発行されます。もう一組作らないでください。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "Application Secret 或 Consumer Key 当时没复制下来，或已经过期。",
          "en": "The Application Secret or Consumer Key wasn’t copied when it was shown, or it has expired.",
          "ja": "Application Secret か Consumer Key を表示中にコピーしていないか、期限切れです。"
        },
        "nextStep": {
          "zh": "回 createToken 重新 Create keys，三把一起复制。Validity 选 Unlimited。",
          "en": "Go back to createToken, Create keys again, and copy all three. Set Validity to Unlimited.",
          "ja": "createToken に戻って Create keys し直し、3 つともコピーしてください。Validity は Unlimited にします。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 Consumer Key 的 Rights 没有 GET /me/bill。",
          "en": "This Consumer Key’s Rights don’t include GET /me/bill.",
          "ja": "この Consumer Key の Rights に GET /me/bill がありません。"
        },
        "nextStep": {
          "zh": "重建一把，Rights 至少给 GET /me/bill*。",
          "en": "Create a new set with at least GET /me/bill* in Rights.",
          "ja": "Rights に少なくとも GET /me/bill* を付けて作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.ovhcloud.com",
    "credentialSetupURL": "https://eu.api.ovh.com/createToken/",
    "summary": {
      "zh": "欧洲公有云和裸金属。按本月发票合计，含税。",
      "en": "European public cloud and bare metal. This month’s invoices, tax included.",
      "ja": "欧州のパブリッククラウドとベアメタル。今月のインボイス合計（税込）です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 OVHcloud 后台本月发票合计（含税）一致。",
      "en": "This number should match this month’s invoices in the OVHcloud dashboard, tax included.",
      "ja": "この数字は OVHcloud 管理画面の今月のインボイス合計（税込）と一致するはずです。"
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
          "zh": "Access Token",
          "en": "Access Token",
          "ja": "Access Token"
        },
        "isSecret": true,
        "hint": {
          "zh": "アクセストークン",
          "en": "Access Token",
          "ja": "アクセストークン"
        }
      },
      {
        "key": "apiKey",
        "label": {
          "zh": "Access Token Secret",
          "en": "Access Token Secret",
          "ja": "Access Token Secret"
        },
        "isSecret": true,
        "hint": {
          "zh": "只显示一次",
          "en": "shown only once",
          "ja": "一度しか表示されません"
        }
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Project ID",
          "en": "Project ID",
          "ja": "Project ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "当前项目的 Account.ID，不是另外创建的编号",
          "en": "Account.ID of this project, not a number you create",
          "ja": "このプロジェクトの Account.ID。自分で作る番号ではありません"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开さくらのクラウド控制台，左侧选 APIキー，点 APIキーの作成。种类选资源操作用。访问级别不要选「访问不可」，账单需要「請求閲覧」。创建后立刻复制 Access Token 和 Access Token Secret（Secret 离开页面就没了）。",
        "en": "Open the Sakura Cloud control panel, choose APIキー on the left, then APIキーの作成. Pick a resource-operation key. Don’t set access level to no-access; billing needs 請求閲覧. Copy the Access Token and Access Token Secret right away — the Secret isn’t shown again.",
        "ja": "さくらのクラウドのコントロールパネルを開き、左の APIキー から APIキーの作成 を選びます。種類はリソース操作用。アクセスレベルは「アクセス不可」以外、請求には 請求閲覧 が必要です。作成後すぐに Access Token と Access Token Secret をコピーします。Secret はこの画面でしか出ません。"
      },
      {
        "zh": "复制当前项目的 Project ID（控制台项目信息，或 auth-status 返回的 Account.ID）。这是已有编号，不要创建。",
        "en": "Copy this project’s Project ID (from the project info in the control panel, or Account.ID on auth-status). It’s an existing number — don’t create one.",
        "ja": "このプロジェクトの Project ID をコピーします（コントロールパネルのプロジェクト情報、または auth-status の Account.ID）。既存の番号です。新規作成しないでください。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "Access Token 或 Secret 不对，或 Secret 当时没复制下来。",
          "en": "The Access Token or Secret is wrong, or the Secret wasn’t copied when it was shown.",
          "ja": "Access Token か Secret が違うか、表示中に Secret をコピーしていません。"
        },
        "nextStep": {
          "zh": "回 APIキー 重新创建一把，Secret 显示时立刻复制。",
          "en": "Go back to APIキー, create a new key, and copy the Secret while it’s on screen.",
          "ja": "APIキー に戻って作り直し、表示中に Secret をコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 APIキー 没有請求閲覧，所以读不到发票。",
          "en": "This API key doesn’t have 請求閲覧, so it can’t read invoices.",
          "ja": "この APIキー に 請求閲覧 がないため、インボイスを読めません。"
        },
        "nextStep": {
          "zh": "编辑或重建 APIキー，访问级别带上請求閲覧。",
          "en": "Edit or recreate the API key with 請求閲覧 in the access level.",
          "ja": "アクセスレベルに 請求閲覧 を付けて編集または作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://secure.sakura.ad.jp",
    "credentialSetupURL": "https://manual.sakura.ad.jp/cloud/api/apikey.html",
    "summary": {
      "zh": "日本本地云。按本月发票合计，日元会折成美元。",
      "en": "Japanese local cloud. This month’s invoices, summed. Yen convert to USD.",
      "ja": "日本のローカルクラウド。今月のインボイス合計で、円はドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月发票合计一致。日元会折成美元。",
      "en": "This number should match this month’s invoices in the dashboard. Yen convert to USD.",
      "ja": "この数字はダッシュボードの今月のインボイス合計と一致するはずです。円はドルに換算します。"
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
          "zh": "Client Secret",
          "en": "Client Secret",
          "ja": "Client Secret"
        },
        "isSecret": true,
        "hint": {
          "zh": ".edgerc 里的 client_secret",
          "en": "client_secret in .edgerc",
          "ja": ".edgerc の client_secret"
        }
      },
      {
        "key": "apiToken",
        "label": {
          "zh": "Access Token",
          "en": "Access Token",
          "ja": "Access Token"
        },
        "isSecret": true,
        "hint": {
          "zh": ".edgerc 里的 access_token",
          "en": "access_token in .edgerc",
          "ja": ".edgerc の access_token"
        }
      },
      {
        "key": "accessKeyID",
        "label": {
          "zh": "Client Token",
          "en": "Client Token",
          "ja": "Client Token"
        },
        "isSecret": false,
        "hint": {
          "zh": ".edgerc 里的 client_token",
          "en": "client_token in .edgerc",
          "ja": ".edgerc の client_token"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Akamai Control Center 的 Identity and Access Management，点 Create API client。选 Advanced，给 Invoicing API 只读。创建后 Download 凭据，从 .edgerc 复制 client_secret 和 access_token。",
        "en": "Open Identity and Access Management in Akamai Control Center and tap Create API client. Choose Advanced and grant read-only Invoicing API. After creating, Download the credentials and copy client_secret and access_token from the .edgerc.",
        "ja": "Akamai Control Center の Identity and Access Management を開き、Create API client をタップします。Advanced を選び、Invoicing API は読み取り専用にします。作成後に Download し、.edgerc から client_secret と access_token をコピーします。"
      },
      {
        "zh": "同一份 .edgerc 里还有 client_token，一并复制。三值一次下载，不要再单独创建。",
        "en": "The same .edgerc also has client_token — copy it too. All three values come from one download; don’t create another client.",
        "ja": "同じ .edgerc に client_token もあるので、一緒にコピーします。3 つの値は一度の Download です。もう一つ作らないでください。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "client_token、client_secret 或 access_token 抄错了，或客户端已撤销。",
          "en": "client_token, client_secret, or access_token was copied wrong, or the client was revoked.",
          "ja": "client_token、client_secret、access_token のコピー違いか、クライアントが取り消されています。"
        },
        "nextStep": {
          "zh": "回 Identity and Access Management 重新 Create API client，从新的 .edgerc 三值一起复制。",
          "en": "Go back to Identity and Access Management, Create API client again, and copy all three values from the new .edgerc.",
          "ja": "Identity and Access Management に戻って Create API client し直し、新しい .edgerc から 3 つともコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这个 API client 没有 Invoicing API 只读。",
          "en": "This API client doesn’t have read access to the Invoicing API.",
          "ja": "この API client に Invoicing API の読み取りがありません。"
        },
        "nextStep": {
          "zh": "用 Advanced 重建客户端，只给 Invoicing API 读权限。",
          "en": "Recreate the client as Advanced with read-only Invoicing API.",
          "ja": "Advanced で作り直し、Invoicing API は読み取り専用にしてください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://control.akamai.com",
    "credentialSetupURL": "https://control.akamai.com/apps/identity-management/#/tabs/users/list",
    "summary": {
      "zh": "企业 CDN 和边缘安全。按本月发票合计。",
      "en": "Enterprise CDN and edge security. This month’s invoices, summed.",
      "ja": "企業向け CDN とエッジセキュリティ。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和 Control Center 本月发票合计一致。",
      "en": "This number should match this month’s invoice total in Control Center.",
      "ja": "この数字は Control Center の今月のインボイス合計と一致するはずです。"
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
        "zh": "打开 Hostens 客户区 的 User API 文档。认证用客户区登录邮箱和密码做 HTTP Basic，不是另外签发的钥匙。把完整 Authorization 值（含 Basic 前缀）贴进 API Key。",
        "en": "Open the User API docs in the Hostens client area. Auth is HTTP Basic with your client-area email and password — not a separately issued key. Paste the full Authorization value (including the Basic prefix) into API Key.",
        "ja": "Hostens クライアントエリア の User API ドキュメントを開きます。認証はクライアントエリアのメールとパスワードによる HTTP Basic で、別途発行するキーではありません。Authorization 値（Basic プレフィックス付き）をそのまま API Key に貼ります。"
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
        "zh": "打开 BinaryLane 控制台 Account 页，Security 里 Nova API Key 旁点 Manage。点 + Create Token，起名后点 Create，立刻复制 API Token；只显示一次。",
        "en": "Open Account in the BinaryLane dashboard. Under Security, tap Manage next to Nova API Key. Tap + Create Token, name it, tap Create, and copy the API Token immediately — it’s shown once.",
        "ja": "BinaryLane ダッシュボード の Account を開き、Security の Nova API Key の横の Manage をタップ。+ Create Token で名前を付けて Create し、API Token をすぐにコピーします。一度しか表示されません。"
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
        "zh": "打开 Metallic Usage API 文档，点 Authorize，填入门户签发的 Bearer token，然后复制。这是 OAuth2 Bearer，不是应用 API Key。",
        "en": "Open the Metallic Usage API docs, tap Authorize, paste the Bearer token issued by the portal, then copy it. This is an OAuth2 Bearer token, not an app API Key.",
        "ja": "Metallic Usage API のドキュメントを開き、Authorize をタップして、ポータルで発行された Bearer token を貼り付けてコピーします。アプリの API Key ではなく OAuth2 Bearer です。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把 Bearer token 无效或已过期。",
          "en": "This Bearer token is invalid or expired.",
          "ja": "この Bearer token は無効か、期限切れです。"
        },
        "nextStep": {
          "zh": "回门户重新签发，再到 Authorize 贴进去，立刻复制。",
          "en": "Issue a new one in the portal, paste it under Authorize, and copy it right away.",
          "ja": "ポータルで発行し直し、Authorize に貼ってすぐコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 token 读不到 Metallic 用量。",
          "en": "This token cannot read Metallic usage.",
          "ja": "この token では Metallic の用量を読めません。"
        },
        "nextStep": {
          "zh": "确认签发时带了用量权限，并且这是 Metallic 的 Bearer，不是别的产品的钥匙。",
          "en": "Confirm it was issued with usage access, and that it is a Metallic Bearer token, not a key from another product.",
          "ja": "用量の権限付きで発行したか、別製品のキーではないか確認してください。"
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
        "zh": "打开 Postman 的 Account settings → API keys，点 Generate API Key，起个名字，再点一次 Generate API Key，然后复制。",
        "en": "Open Postman Account settings → API keys, tap Generate API Key, name it, tap Generate API Key again, then copy it.",
        "ja": "Postman の Account settings → API keys を開き、Generate API Key をタップして名前を付け、もう一度 Generate API Key をタップしてコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把 API Key 无效，或者已经被撤销。",
          "en": "This API Key is invalid, or it has already been revoked.",
          "ja": "この API Key は無効か、すでに取り消されています。"
        },
        "nextStep": {
          "zh": "回上一步重新签发，签发后立刻复制。",
          "en": "Go back a step, issue a new one, and copy it right away.",
          "ja": "前の手順に戻って発行し直し、発行したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 API Key 读不到已付发票。",
          "en": "This API Key cannot read paid invoices.",
          "ja": "この API Key では支払い済みインボイスを読めません。"
        },
        "nextStep": {
          "zh": "确认这个账号能看 Billing，并且团队没有关掉 API key 生成。",
          "en": "Confirm this account can see Billing, and that the team has not turned off API key generation.",
          "ja": "このアカウントが Billing を見られるか、チームが API key の生成を止めていないか確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://go.postman.co/billing",
    "credentialSetupURL": "https://go.postman.co/settings/me/api-keys",
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
        "zh": "打开 Seven Bridges 的 Developer 仪表盘，选 Authentication token，复制现有 token。需要轮换就重新生成，然后立刻复制。",
        "en": "Open the Seven Bridges Developer dashboard, choose Authentication token, and copy the existing token. If you need to rotate it, regenerate it and copy immediately.",
        "ja": "Seven Bridges の Developer ダッシュボードを開き、Authentication token を選んで、既存の token をコピーします。回すなら再生成してすぐコピーしてください。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把 authentication token 无效，或者已经被撤销。",
          "en": "This authentication token is invalid, or it has already been revoked.",
          "ja": "この authentication token は無効か、すでに取り消されています。"
        },
        "nextStep": {
          "zh": "回上一步重新签发，签发后立刻复制。",
          "en": "Go back a step, issue a new one, and copy it right away.",
          "ja": "前の手順に戻って発行し直し、発行したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 token 读不到发票。",
          "en": "This token cannot read invoices.",
          "ja": "この token ではインボイスを読めません。"
        },
        "nextStep": {
          "zh": "确认你开的是付账那个平台（US 或 EU），并且账号能看 Billing。",
          "en": "Confirm you are on the platform you pay (US or EU), and that the account can see Billing.",
          "ja": "支払いしているプラットフォーム（US または EU）か、アカウントに Billing を見る権限があるか確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://igor.sbgenomics.com",
    "credentialSetupURL": "https://igor.sbgenomics.com/developer#token",
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
          "zh": "Product Token",
          "en": "Product Token",
          "ja": "Product Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 CM.com 的 Channels，左侧进 API Access and Settings → Authentication，复制 Product Token。不要用同一页的 API Keys。",
        "en": "Open CM.com Channels, go to API Access and Settings → Authentication, and copy the Product Token. Do not use the API Keys on the same page.",
        "ja": "CM.com の Channels を開き、左の API Access and Settings → Authentication で Product Token をコピーします。同じページの API Keys は使わないでください。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这个 Product Token 无效。",
          "en": "This Product Token is invalid.",
          "ja": "この Product Token は無効です。"
        },
        "nextStep": {
          "zh": "回 Authentication 页重新复制 Product Token，不要复制 API Keys。",
          "en": "Go back to Authentication and copy the Product Token again. Do not copy API Keys.",
          "ja": "Authentication に戻って Product Token をコピーし直してください。API Keys は使わないでください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这个 Product Token 读不到交易。",
          "en": "This Product Token cannot read transactions.",
          "ja": "この Product Token では取引を読めません。"
        },
        "nextStep": {
          "zh": "确认复制的是付短信费那个账号的 Product Token，并且你能打开 Channels。",
          "en": "Confirm you copied the Product Token for the account that pays for messaging, and that you can open Channels.",
          "ja": "メッセージ料金を払っているアカウントの Product Token か、Channels を開けるか確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.cm.com",
    "credentialSetupURL": "https://www.cm.com/app/channels",
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
        "isSecret": true,
        "hint": {
          "zh": "只显示一次，不会过期",
          "en": "Shown once. Does not expire.",
          "ja": "一度しか表示されません。期限はありません。"
        }
      }
    ],
    "steps": [
      {
        "zh": "用根用户登录 ShipBob，打开 Integrations → API Tokens，点 Generate New Token，填名称和用途后 Generate Token。立刻复制 Personal Access Token，关掉就看不到了。PAT 自带 billing_read，不会过期。",
        "en": "Sign in to ShipBob as the root user. Open Integrations → API Tokens, tap Generate New Token, fill in a name and description, then Generate Token. Copy the Personal Access Token right away — it isn’t shown again. A PAT includes billing_read and does not expire.",
        "ja": "ShipBob にルートユーザーでログインし、Integrations → API Tokens を開き、Generate New Token で名前と用途を入れて Generate Token します。Personal Access Token はすぐにコピーし、閉じると再表示されません。PAT には billing_read が含まれ、期限はありません。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这个 Personal Access Token 无效，或者已经被撤销。",
          "en": "This Personal Access Token is invalid, or it has already been revoked.",
          "ja": "この Personal Access Token は無効か、すでに取り消されています。"
        },
        "nextStep": {
          "zh": "回 API Tokens 再 Generate New Token，显示时立刻复制。",
          "en": "Go back to API Tokens, Generate New Token again, and copy it while it’s on screen.",
          "ja": "API Tokens に戻って Generate New Token し直し、表示中にコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "不是根用户签发的 PAT，或这个 channel 没有 billing_read。",
          "en": "The PAT wasn’t issued by the root user, or this channel doesn’t have billing_read.",
          "ja": "ルートユーザー以外が発行した PAT か、この channel に billing_read がありません。"
        },
        "nextStep": {
          "zh": "用根用户重新 Generate New Token。PAT 默认带全账户权限，含 billing_read。",
          "en": "Generate New Token again as the root user. A PAT includes full-account access, including billing_read.",
          "ja": "ルートユーザーで Generate New Token し直してください。PAT はアカウント全体の権限（billing_read を含む）が付きます。"
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
      "zh": "这个数字应该和后台本月发票合计一致。",
      "en": "This number should match this month’s invoice total in the dashboard.",
      "ja": "この数字はダッシュボードの今月のインボイス合計と一致するはずです。"
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
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 MikroCloud Authentication 文档。Obtaining an API Token 写明目前不能在控制台自助签发，要联系 support 领取。",
        "en": "Open the MikroCloud Authentication docs. Obtaining an API Token says tokens are not self-serve in the dashboard; contact support to get one.",
        "ja": "MikroCloud Authentication ドキュメントを開きます。Obtaining an API Token では、ダッシュボードでは自分で発行できず、support に連絡して受け取る必要があると書かれています。"
      },
      {
        "zh": "拿到 API Token 后立刻复制。格式是 uuid:uuid:token，属于整个 team。",
        "en": "Copy the API Token as soon as you receive it. The format is uuid:uuid:token, and it belongs to the whole team.",
        "ja": "API Token を受け取ったらすぐにコピーします。形式は uuid:uuid:token で、team 全体に属します。"
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
    "credentialSetupURL": "https://mikrocloud.com/documentation/api-reference/authentication",
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
        "zh": "打开 Leaseweb Customer Portal，左侧 Administration 里点 API Key。需要 Master 或 Admin。",
        "en": "Open the Leaseweb Customer Portal. Under Administration in the left menu, tap API Key. You need a Master or Admin role.",
        "ja": "Leaseweb Customer Portal を開き、左メニューの Administration から API Key をタップします。Master または Admin が必要です。"
      },
      {
        "zh": "点 Add API Key。凭据只显示一次，立刻复制。",
        "en": "Tap Add API Key. The key is shown only once — copy it right away.",
        "ja": "Add API Key をタップします。キーは一度しか表示されないので、すぐにコピーしてください。"
      },
      {
        "zh": "用铅笔图标把权限收成只勾 GET，当作只读。",
        "en": "Use the pencil icon and leave only GET checked, so the key is read-only.",
        "ja": "鉛筆アイコンで権限を開き、GET だけをオンにして読み取り専用にします。"
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
    "credentialSetupURL": "https://kb.leaseweb.com/kb/customer-portal-api/customer-portal-api-api-key-management/",
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
          "zh": "Organization ID",
          "en": "Organization ID",
          "ja": "Organization ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "控制台地址栏里的组织 UUID，不要创建",
          "en": "Organization UUID in the console URL — copy it, don’t create one",
          "ja": "コンソール URL の組織 UUID。作成せずコピーします"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Qovery Console，进 Organization Settings 的 Token API。",
        "en": "Open the Qovery Console, then go to Token API in Organization Settings.",
        "ja": "Qovery Console を開き、Organization Settings の Token API に進みます。"
      },
      {
        "zh": "点 Add new，填 Name 和 Description，Role 选 Viewer。创建后 token 只显示一次，立刻复制。",
        "en": "Tap Add new, fill in Name and Description, and set Role to Viewer. The token is shown only once — copy it right away.",
        "ja": "Add new をタップし、Name と Description を入れ、Role は Viewer にします。token は一度しか表示されないので、すぐにコピーしてください。"
      },
      {
        "zh": "不要创建 Organization ID。打开组织总览，从控制台地址栏复制 Organization ID（UUID）。",
        "en": "Don’t create an Organization ID. Open the organization overview and copy the Organization ID (UUID) from the console URL.",
        "ja": "Organization ID は作成しません。組織の概要を開き、コンソールのアドレスバーから Organization ID（UUID）をコピーします。"
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
    "credentialSetupURL": "https://www.qovery.com/docs/configuration/organization/api-token",
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
          "zh": "同一把凭据确认窗口里的 Client ID",
          "en": "Client ID from the same credential confirmation window",
          "ja": "同じ認証情報の確認ウィンドウにある Client ID"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 phoenixNAP BMC 控制台，左侧进 API Credentials，点 Create Credentials。",
        "en": "Open the phoenixNAP BMC portal. In the left menu go to API Credentials, then tap Create Credentials.",
        "ja": "phoenixNAP BMC ポータルを開き、左メニューの API Credentials から Create Credentials をタップします。"
      },
      {
        "zh": "填 credential name，权限勾 invoices.read（账单只读），点 Create。确认窗口里立刻复制 Client Secret。",
        "en": "Enter a credential name, check invoices.read (read-only invoicing), then tap Create. Copy the Client Secret from the confirmation window right away.",
        "ja": "credential name を入れ、invoices.read（請求の読み取り専用）にチェックして Create をタップします。確認ウィンドウで Client Secret をすぐにコピーしてください。"
      },
      {
        "zh": "同一把凭据的确认窗口里复制 Client ID，不要再创建一把。之后也可在表格 Actions 里点 View Credentials。",
        "en": "Copy the Client ID from the same confirmation window — don’t create another credential. Later you can also open Actions → View Credentials in the table.",
        "ja": "同じ確認ウィンドウから Client ID をコピーします。新しく作り直さないでください。あとから表の Actions → View Credentials でも見られます。"
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
    "credentialSetupURL": "https://phoenixnap.com/kb/bare-metal-cloud-portal-quick-start-guide",
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
        "zh": "打开 ID Magalu 的 API Keys 页面，确认右上角是要读账单的那个 tenant。",
        "en": "Open the API Keys page in ID Magalu, and make sure the tenant in the top-right is the one whose bill you want to read.",
        "ja": "ID Magalu の API Keys ページを開き、右上の tenant が請求を読みたい側であることを確認します。"
      },
      {
        "zh": "点 Criar API Key，填名称，选过期时间。应用权限勾读用量需要的项，有只读就只勾只读。",
        "en": "Tap Criar API Key, name it, and pick an expiration. Under Magalu Cloud applications, check only what you need to read usage — prefer read-only.",
        "ja": "Criar API Key をタップし、名前と有効期限を決めます。Magalu Cloud のアプリケーションは用量の読み取りに必要なものだけ、読み取り専用があればそれだけにします。"
      },
      {
        "zh": "创建后立刻复制 API Key，离开页面就看不到了。",
        "en": "Copy the API Key right away. You won’t see it again after leaving the page.",
        "ja": "API Key は作成したらすぐにコピーします。ページを離れると再表示されません。"
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
    "credentialSetupURL": "https://id.magalu.com/api-keys",
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
          "zh": "Access Token",
          "en": "Access Token",
          "ja": "Access Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 TransIP 控制台，右上角头像进 My account → Api。把 Status 滑到 On。",
        "en": "Open the TransIP control panel. From the profile icon go to My account → Api, then set Status to On.",
        "ja": "TransIP コントロールパネルを開き、右上のアイコンから My account → Api に進み、Status を On にします。"
      },
      {
        "zh": "在 Access Tokens 里手动创建一把：填 Label，选过期时间，需要只读就勾 Read-only，然后复制 token。",
        "en": "Under Access Tokens, create one by hand: set a Label and expiry, check Read-only if that’s enough, then copy the token.",
        "ja": "Access Tokens で手動作成します。Label と有効期限を入れ、読み取りだけでよければ Read-only をオンにし、token をコピーします。"
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
    "credentialSetupURL": "https://www.transip.nl/cp/account/api/",
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
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Servers.com Customer Portal，左侧 Identity and Access 里点 API tokens。",
        "en": "Open the Servers.com Customer Portal. In the left menu go to Identity and Access, then tap API tokens.",
        "ja": "Servers.com Customer Portal を開き、左メニューの Identity and Access から API tokens をタップします。"
      },
      {
        "zh": "点 Create，填名称，权限选 Read only（只允许 GET）。创建后立刻复制 token，丢了不能再看。",
        "en": "Tap Create, name the token, and choose Read only (GET only). Copy it right away — it can’t be shown again.",
        "ja": "Create をタップし、名前を付けて Read only（GET のみ）を選びます。token は再表示できないので、すぐにコピーしてください。"
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
    "credentialSetupURL": "https://portal.servers.com/iam/api-tokens",
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
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Flexport Developer Portal 的 Using API Credentials，进 API Credentials。",
        "en": "Open Using API Credentials in the Flexport Developer Portal, then go to API Credentials.",
        "ja": "Flexport Developer Portal の Using API Credentials を開き、API Credentials に進みます。"
      },
      {
        "zh": "点 Create Credentials。选 API Key（Bearer，长期有效），只开读发票需要的资源，然后复制。",
        "en": "Tap Create Credentials. Choose API Key (a long-lived Bearer token), enable only the resources needed to read invoices, then copy it.",
        "ja": "Create Credentials をタップします。API Key（有効期限のない Bearer）を選び、請求書の読み取りに必要なリソースだけをオンにしてコピーします。"
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
    "credentialSetupURL": "https://developers.flexport.com/tutorials/using-api-credentials/",
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
        "zh": "打开 i3D.net 控制台的 API Keys 页面，点 Generate API key。",
        "en": "Open the API Keys page in the i3D.net control panel, then tap Generate API key.",
        "ja": "i3D.net コントロールパネルの API Keys ページを開き、Generate API key をタップします。"
      },
      {
        "zh": "默认不过期、不限 IP。需要的话再填 IP 范围或过期日期。创建后立刻复制 API Key。",
        "en": "By default it has no expiry and no IP whitelist. Add an IP range or expiry if you want. Copy the API Key right away.",
        "ja": "初期状態では有効期限も IP 制限もありません。必要なら範囲や期限を足します。API Key はすぐにコピーしてください。"
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
    "credentialSetupURL": "https://one.i3d.net/Account/API-Keys",
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
        "zh": "打开 DataPacket 客户面板的 Security 页面，点 Add API key。",
        "en": "Open the Security page in the DataPacket client panel, then tap Add API key.",
        "ja": "DataPacket クライアントパネルの Security ページを開き、Add API key をタップします。"
      },
      {
        "zh": "给 token 起名，类型选 read-only。凭据只显示一次，立刻复制。",
        "en": "Name the token and choose read-only. It’s shown only once — copy it right away.",
        "ja": "token に名前を付け、read-only を選びます。一度しか表示されないので、すぐにコピーしてください。"
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
    "credentialSetupURL": "https://app.datapacket.com/settings/security#api-keys",
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
          "zh": "Billing Account ID",
          "en": "Billing Account ID",
          "ja": "Billing Account ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "账单账户页上的 id，不要创建",
          "en": "id on the billing account page — copy it, don’t create one",
          "ja": "課金アカウントページの id。作成せずコピーします"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 CUDO Compute 控制台，按 Authentication 文档在控制台生成一把 API key。",
        "en": "Open the CUDO Compute console and generate an API key there, as described in the Authentication docs.",
        "ja": "CUDO Compute コンソールを開き、Authentication ドキュメントの手順で API key を発行します。"
      },
      {
        "zh": "key 只在创建时返回一次，立刻复制。之后用 Authorization: Bearer 发送。",
        "en": "The key is returned only once at creation — copy it right away. Later requests use Authorization: Bearer.",
        "ja": "key は作成時に一度だけ返ります。すぐにコピーしてください。以降は Authorization: Bearer で送ります。"
      },
      {
        "zh": "不要创建 Billing Account ID。打开账单账户页，复制已有账户的 id。",
        "en": "Don’t create a Billing Account ID. Open the billing account page and copy the id of an existing account.",
        "ja": "Billing Account ID は作成しません。課金アカウントのページを開き、既存アカウントの id をコピーします。"
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
    "credentialSetupURL": "https://compute.cudo.org",
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
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Shipwell 控制台，进 Manage → Company → Developer Tools。需要管理员或开发者角色。",
        "en": "Open the Shipwell dashboard and go to Manage → Company → Developer Tools. You need an administrator or developer role.",
        "ja": "Shipwell ダッシュボードを開き、Manage → Company → Developer Tools に進みます。管理者または開発者の役割が必要です。"
      },
      {
        "zh": "打开 API Keys 页，点 Get Token，再输入一次该用户密码，然后复制 Token。",
        "en": "Open the API Keys tab, tap Get Token, re-enter that user’s password, then copy the Token.",
        "ja": "API Keys タブを開き、Get Token をタップしてそのユーザーのパスワードを再入力し、Token をコピーします。"
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
    "credentialSetupURL": "https://app.shipwell.com/",
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
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Ocamba 平台右上角 Profile，点 API Tokens。",
        "en": "In the Ocamba platform, open Profile in the top-right, then tap API Tokens.",
        "ja": "Ocamba プラットフォーム右上の Profile から API Tokens をタップします。"
      },
      {
        "zh": "点 Add Token，填 Token Name。Valid From / Valid Until 可留空（立刻生效、永不过期）。",
        "en": "Tap Add Token and enter a Token Name. Leave Valid From / Valid Until empty to start immediately and never expire.",
        "ja": "Add Token をタップし、Token Name を入れます。Valid From / Valid Until を空にすると即時有効・無期限です。"
      },
      {
        "zh": "确认页会显示 Token Key，立刻复制。每人最多 5 把。",
        "en": "The confirmation screen shows the Token Key — copy it right away. Each member can have up to 5 tokens.",
        "ja": "確認画面に Token Key が出ます。すぐにコピーしてください。1 人あたり最大 5 個です。"
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
    "credentialSetupURL": "https://docs.ocamba.com/user/core/core-platform-settings/api-tokens/",
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
        "zh": "打开 inference.sh 的 Settings → API Keys，点 Create API Key。",
        "en": "Open Settings → API Keys on inference.sh, then tap Create API Key.",
        "ja": "inference.sh の Settings → API Keys を開き、Create API Key をタップします。"
      },
      {
        "zh": "立刻复制。key 以 inf_ 开头。可按最少权限加 scope；用量接口走 Authorization: Bearer，并带 X-API-Version: 2。",
        "en": "Copy immediately. The key starts with inf_. You can add least-privilege scopes. Usage calls use Authorization: Bearer and X-API-Version: 2.",
        "ja": "すぐにコピーします。key は inf_ で始まります。最小権限の scope を付けられます。用量は Authorization: Bearer と X-API-Version: 2 です。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙无效，或者已经被撤销了。",
          "en": "This key is invalid, or it has already been revoked.",
          "ja": "このキーは無効か、すでに取り消されています。"
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
          "zh": "这把 key 的 scope 读不到用量。",
          "en": "This key’s scopes cannot read usage.",
          "ja": "この key の scope では用量を読めません。"
        },
        "nextStep": {
          "zh": "回上一步重建一把，不要把用量相关 scope 拿掉。",
          "en": "Go back a step and recreate it without dropping usage-related scopes.",
          "ja": "前の手順に戻り、用量の scope を外さずに作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://inference.sh/",
    "credentialSetupURL": "https://app.inference.sh/settings/keys",
    "summary": {
      "zh": "推理应用市场。按本月用量。",
      "en": "An inference app marketplace. This month’s usage.",
      "ja": "推論アプリのマーケット。今月の用量です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月用量花费一致。",
      "en": "This number should match this month’s usage spend in the dashboard.",
      "ja": "この数字はダッシュボードの今月の用量支出と一致するはずです。"
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
        "zh": "VoltView 没有自助「创建 API Key」按钮。打开 VoltView 注册页申请账号，等他们签发 API credentials。",
        "en": "VoltView has no self-serve Create API Key button. Open the VoltView registration page, request an account, and wait for them to issue API credentials.",
        "ja": "VoltView に自前の Create API Key ボタンはありません。VoltView の登録ページで口座を申し込み、API credentials の発行を待ちます。"
      },
      {
        "zh": "把发给你的 key 贴进来。请求头是 x-api-key，不用再换 Bearer。",
        "en": "Paste the key they send you. The header is x-api-key; there is no Bearer exchange.",
        "ja": "送られてきた key を貼ります。ヘッダーは x-api-key で、Bearer への交換はありません。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙无效，或者已经被撤销了。",
          "en": "This key is invalid, or it has already been revoked.",
          "ja": "このキーは無効か、すでに取り消されています。"
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
          "zh": "这把 key 读不到站点发票。",
          "en": "This key cannot read site invoices.",
          "ja": "この key では拠点のインボイスを読めません。"
        },
        "nextStep": {
          "zh": "回上一步向 VoltView 重新申请一把能读 invoices 的 key。",
          "en": "Go back a step and ask VoltView for a key that can read invoices.",
          "ja": "前の手順に戻り、invoices を読める key を VoltView に再発行してもらってください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://docs.voltview.co.uk/",
    "credentialSetupURL": "https://docs.voltview.co.uk/register",
    "summary": {
      "zh": "英国多站点能源发票。按本月发票合计。",
      "en": "UK multi-site energy invoices. This month’s invoices, summed.",
      "ja": "英国の複数拠点エネルギー請求。今月のインボイス合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月能源发票合计一致。英镑会折成美元。",
      "en": "This number should match this month’s energy invoices in the dashboard. Pounds convert to USD.",
      "ja": "この数字はダッシュボードの今月のエネルギーインボイス合計と一致するはずです。ポンドはドルに換算します。"
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
          "zh": "组织 ID，形如 orga_…。从控制台抄，不要创建",
          "en": "Organisation ID like orga_…. Copy it; do not create one.",
          "ja": "orga_… 形式の組織 ID。コピーするだけで、作成しません"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Clever Cloud 控制台 的 API tokens 页，输入当前密码（开了 2FA 还要验证码），创建一把，创建后立刻复制。请求走 API Bridge，头是 Authorization: Bearer。",
        "en": "Open the API tokens page in the Clever Cloud console, enter your current password (and the 2FA code if it is on), create one, and copy it right away. Calls go through the API Bridge with Authorization: Bearer.",
        "ja": "Clever Cloud コンソール の API tokens ページを開き、現在のパスワード（2FA がオンならコードも）を入れて発行し、作成したらすぐにコピーします。リクエストは API Bridge 経由で、ヘッダは Authorization: Bearer です。"
      },
      {
        "zh": "Account ID 是组织 ID，形如 orga_…。在控制台选好付账的组织，从 Information 抄下来，不要创建。个人空间也可以。",
        "en": "Account ID is the organisation ID, shaped like orga_…. In the console pick the organisation that pays the bills, copy it from Information, and do not create one. Personal Space works too.",
        "ja": "Account ID は組織 ID で、orga_… の形です。コンソールで請求先の組織を選び、Information からコピーしてください。作成しません。Personal Space でも構いません。"
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
    "credentialSetupURL": "https://console.clever-cloud.com/users/me/api-tokens",
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
        "zh": "打开 UtilityAPI 控制台 的 Settings，在 API settings 点 Create an API token，类型选 API，然后复制。请求头是 Authorization: Bearer。",
        "en": "Open Settings in the UtilityAPI dashboard. Under API settings tap Create an API token, choose type API, then copy it. The header is Authorization: Bearer.",
        "ja": "UtilityAPI ダッシュボード の Settings を開き、API settings で Create an API token をタップし、種類は API を選んでコピーします。ヘッダは Authorization: Bearer です。"
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
    "credentialSetupURL": "https://utilityapi.com/settings#api-settings",
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
          "zh": "控制台 URL 里 /a/ 后面的数字。抄下来，不要创建",
          "en": "Numeric ID after /a/ in the dashboard URL. Copy it; do not create one.",
          "ja": "ダッシュボード URL の /a/ の後ろの数字。コピーするだけで、作成しません"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 API Access Token 说明，到账户的 API & Access，点 Add，起名后 Generate token。用 Account token，创建后立刻复制。请求头是 Authorization: Bearer。",
        "en": "Open the API Access Token help. On the account API & Access page tap Add, name it, then Generate token. Use an Account token and copy it right away. The header is Authorization: Bearer.",
        "ja": "API Access Token の説明 を開き、アカウントの API & Access で Add をタップし、名前を付けて Generate token します。Account token を使い、作成したらすぐにコピーします。ヘッダは Authorization: Bearer です。"
      },
      {
        "zh": "Account ID 是数字。用账户切换器选好账户后，URL 里 /a/ 后面那段就是，例如 /a/1234/domains 里的 1234。抄下来，不要创建。",
        "en": "Account ID is a number. After you pick the account in the switcher, it is the digits after /a/ in the URL, for example 1234 in /a/1234/domains. Copy it; do not create one.",
        "ja": "Account ID は数字です。アカウント切り替えで選んだあと、URL の /a/ の後ろ、たとえば /a/1234/domains の 1234 です。コピーするだけで、作成しません。"
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
    "credentialSetupURL": "https://support.dnsimple.com/articles/api-access-token/",
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
          "zh": "项目 Settings 里的 Project ID。抄下来，不要创建",
          "en": "From Project Settings. Copy it; do not create one.",
          "ja": "Project Settings からコピー。作成しません"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Latitude.sh 控制台，到 Settings & Billing → API Keys 创建。钥匙只显示一次。打开 Read-only，账单读取足够。请求头是 Authorization: Bearer。",
        "en": "Open the Latitude.sh dashboard and create a key under Settings & Billing → API Keys. It is shown only once. Turn on Read-only; that is enough to read billing. The header is Authorization: Bearer.",
        "ja": "Latitude.sh ダッシュボード を開き、Settings & Billing → API Keys で作成します。鍵は一度だけ表示されます。Read-only をオンにすれば請求の読み取りに足ります。ヘッダは Authorization: Bearer です。"
      },
      {
        "zh": "Project ID 在项目 Settings 里，用来限定账单项目。抄下来，不要创建。",
        "en": "Project ID is in Project Settings. It limits billing to that project. Copy it; do not create one.",
        "ja": "Project ID はプロジェクトの Settings にあり、請求をそのプロジェクトに限定します。コピーするだけで、作成しません。"
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
    "credentialSetupURL": "https://www.latitude.sh/dashboard",
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
          "zh": "Access Key",
          "en": "Access Key",
          "ja": "Access Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Alchemy 控制台的 Security，点 Create Access Key。权限勾 Usage（读用量），不要用 Apps 里的 API Key。创建后立刻复制，只显示一次。需要 billing 或 team admin。",
        "en": "Open Security in the Alchemy dashboard, tap Create Access Key. Enable Usage (read usage). Do not use the API Key from Apps. Copy it immediately — it is shown only once. You must be a billing or team admin.",
        "ja": "Alchemy ダッシュボードの Security を開き、Create Access Key をタップします。権限は Usage（用量の読み取り）を付け、Apps の API Key は使わないでください。作成したらすぐコピーします。一度しか表示されません。billing または team admin が必要です。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把 Access Key 无效，或者已经被撤销。",
          "en": "This Access Key is invalid, or it has already been revoked.",
          "ja": "この Access Key は無効か、すでに取り消されています。"
        },
        "nextStep": {
          "zh": "回上一步重新签发，签发后立刻复制。",
          "en": "Go back a step, issue a new one, and copy it right away.",
          "ja": "前の手順に戻って発行し直し、発行したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 Access Key 缺 Usage 权限，所以读不到用量。",
          "en": "This Access Key is missing Usage, so it cannot read usage.",
          "ja": "この Access Key に Usage がないため、用量を読めません。"
        },
        "nextStep": {
          "zh": "回 Security 重建一把，只打开 Usage 读取。不要用 Apps 里的 API Key。",
          "en": "Go back to Security and create a new key with Usage read. Do not use the API key from Apps.",
          "ja": "Security に戻り、Usage の読み取りだけ付けて作り直してください。Apps の API Key は使わないでください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://dashboard.alchemy.com/",
    "credentialSetupURL": "https://dashboard.alchemy.com/settings/security",
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
          "zh": "Personal API Key",
          "en": "Personal API Key",
          "ja": "Personal API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Friendli Suite 的 Settings → API Keys，点 Create API Key，可填名字和过期时间，再点 Create Key，然后立刻复制。这把是 Personal API Key（flp_ 开头），只显示一次。",
        "en": "Open Friendli Suite Settings → API Keys, tap Create API Key, optionally name it and set an expiry, tap Create Key, then copy it immediately. This is a Personal API Key (starts with flp_) and is shown only once.",
        "ja": "Friendli Suite の Settings → API Keys を開き、Create API Key をタップします。名前と期限は任意です。Create Key をタップしてすぐコピーしてください。Personal API Key（flp_ で始まる）で、一度しか表示されません。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把 Personal API Key 无效，或者已经被撤销。",
          "en": "This Personal API Key is invalid, or it has already been revoked.",
          "ja": "この Personal API Key は無効か、すでに取り消されています。"
        },
        "nextStep": {
          "zh": "回上一步重新签发，签发后立刻复制。",
          "en": "Go back a step, issue a new one, and copy it right away.",
          "ja": "前の手順に戻って発行し直し、発行したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 Personal API Key 读不到团队费用。",
          "en": "This Personal API Key cannot read team cost.",
          "ja": "この Personal API Key ではチーム費用を読めません。"
        },
        "nextStep": {
          "zh": "确认签发用的是付账那个 Friendli 账号，并且钥匙还没被 Revoke。",
          "en": "Confirm it was issued on the Friendli account that pays the bill, and that the key has not been revoked.",
          "ja": "支払いしている Friendli アカウントで発行したか、Revoke されていないか確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://friendli.ai/",
    "credentialSetupURL": "https://friendli.ai/suite/~/setting/keys",
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
          "zh": "API Key",
          "en": "API Key",
          "ja": "API Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Mixpeek 控制台的 Organization Settings，创建一把 API Key，然后立刻复制。请求头是 Bearer，钥匙一般是 sk_ 开头。",
        "en": "Open Organization Settings in the Mixpeek dashboard, create an API Key, and copy it immediately. Send it as a Bearer token; keys usually start with sk_.",
        "ja": "Mixpeek ダッシュボードの Organization Settings を開き、API Key を作成してすぐコピーします。ヘッダーは Bearer で、キーはたいてい sk_ で始まります。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把 API Key 无效，或者已经被撤销。",
          "en": "This API Key is invalid, or it has already been revoked.",
          "ja": "この API Key は無効か、すでに取り消されています。"
        },
        "nextStep": {
          "zh": "回上一步重新签发，签发后立刻复制。",
          "en": "Go back a step, issue a new one, and copy it right away.",
          "ja": "前の手順に戻って発行し直し、発行したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 API Key 读不到组织花费。",
          "en": "This API Key cannot read organization spend.",
          "ja": "この API Key では組織の支出を読めません。"
        },
        "nextStep": {
          "zh": "回 Organization Settings 用能看账单的成员重建一把。",
          "en": "Go back to Organization Settings and create a new key as a member who can see billing.",
          "ja": "Organization Settings に戻り、請求を見られるメンバーで作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://mixpeek.com/",
    "credentialSetupURL": "https://studio.mixpeek.com",
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
          "zh": "Workspace ID",
          "en": "Workspace ID",
          "ja": "Workspace ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "Settings & Members → Workspace → Settings 里复制，不要新建",
          "en": "Copy it in Settings & Members → Workspace → Settings. Do not create a workspace.",
          "ja": "Settings & Members → Workspace → Settings でコピー。新規作成しない"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Typebot 的 Settings & Members → My account，在 API tokens 点 Create，起个名字，再点 Create token，然后立刻复制。",
        "en": "Open Typebot Settings & Members → My account. Under API tokens tap Create, name it, tap Create token, then copy it immediately.",
        "ja": "Typebot の Settings & Members → My account を開き、API tokens で Create をタップし、名前を付けて Create token をタップし、すぐコピーします。"
      },
      {
        "zh": "打开 Settings & Members → Workspace → Settings，复制 Workspace ID。不要新建工作区。",
        "en": "Open Settings & Members → Workspace → Settings and copy the Workspace ID. Do not create a workspace.",
        "ja": "Settings & Members → Workspace → Settings を開き、Workspace ID をコピーします。ワークスペースは新規作成しないでください。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把 API Token 无效，或者已经被撤销。",
          "en": "This API Token is invalid, or it has already been revoked.",
          "ja": "この API Token は無効か、すでに取り消されています。"
        },
        "nextStep": {
          "zh": "回上一步重新签发，签发后立刻复制。",
          "en": "Go back a step, issue a new one, and copy it right away.",
          "ja": "前の手順に戻って発行し直し、発行したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 token 读不到这个工作区的发票。",
          "en": "This token cannot read invoices for this workspace.",
          "ja": "この token ではこのワークスペースのインボイスを読めません。"
        },
        "nextStep": {
          "zh": "确认 Workspace ID 是付账那个工作区的，并且签发 token 的账号能看它的账单。",
          "en": "Confirm the Workspace ID is the workspace that pays, and that the account that issued the token can see its billing.",
          "ja": "Workspace ID が支払いしているワークスペースか、token を発行したアカウントにその請求を見る権限があるか確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [
      {
        "id": "findWorkspaceID",
        "url": "https://docs.typebot.com/api-reference/how-to"
      }
    ],
    "billingURL": "https://app.typebot.io/",
    "credentialSetupURL": "https://app.typebot.io/typebots",
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
    "status": "available",
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
          "zh": "Personal Access Token",
          "en": "Personal Access Token",
          "ja": "Personal Access Token"
        },
        "isSecret": true
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
          "zh": "/w/ 和下一道 / 之间，类似 wkspace_…",
          "en": "Between /w/ and the next slash, like wkspace_…",
          "ja": "/w/ と次の / の間。wkspace_… の形"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Botpress 的 Account Settings → Access Tokens，生成一把 Personal Access Token，然后复制。",
        "en": "Open Botpress Account Settings → Access Tokens, generate a Personal Access Token, and copy it.",
        "ja": "Botpress の Account Settings → Access Tokens を開き、Personal Access Token を生成してコピーします。"
      },
      {
        "zh": "还需要 Workspace ID。地址栏是 /w/wkspace_…/account/access-tokens 这种，复制 /w/ 和下一道 / 之间那一段。",
        "en": "You also need a Workspace ID. The address bar looks like /w/wkspace_…/account/access-tokens. Copy the segment between /w/ and the next slash.",
        "ja": "Workspace ID も必要です。アドレスバーは /w/wkspace_…/account/access-tokens の形です。/w/ と次の / の間をコピーします。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把 Personal Access Token 无效，或者已经被撤销。",
          "en": "This Personal Access Token is invalid, or it has already been revoked.",
          "ja": "この Personal Access Token は無効か、すでに取り消されています。"
        },
        "nextStep": {
          "zh": "回 Access Tokens 重新生成一把，生成后立刻复制。",
          "en": "Go back to Access Tokens, generate a new one, and copy it right away.",
          "ja": "Access Tokens に戻って作り直し、生成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 token 读不到这个 Workspace 的账单。",
          "en": "This token can’t read billing for this workspace.",
          "ja": "この token ではこのワークスペースの請求を読めません。"
        },
        "nextStep": {
          "zh": "确认 Workspace ID 是当前工作区的，并且签发 token 的账号能看这个工作区的账单。",
          "en": "Confirm the Workspace ID is the current workspace, and the account that issued the token can see that workspace’s billing.",
          "ja": "Workspace ID が今のワークスペースで、token を発行したアカウントにその請求を見る権限があるか確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://viber.botpress.cloud/billing",
    "credentialSetupURL": "https://viber.botpress.cloud/account",
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
        "zh": "打开 Seeweb Ermes 控制台，创建一把长效 API-Token，创建后立刻复制，只显示一次。这把走 X-APITOKEN，不要用登录拿到的短期 JWT。",
        "en": "Open the Seeweb Ermes control panel, create a long-lived API-Token, and copy it immediately — it is shown only once. Send it as X-APITOKEN. Do not use the short-lived JWT from login.",
        "ja": "Seeweb Ermes コントロールパネルを開き、長寿命の API-Token を作成してすぐコピーします。一度しか表示されません。ヘッダーは X-APITOKEN です。ログインで得た短い JWT は使わないでください。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把 API-Token 无效，或者已经被撤销。",
          "en": "This API-Token is invalid, or it has already been revoked.",
          "ja": "この API-Token は無効か、すでに取り消されています。"
        },
        "nextStep": {
          "zh": "回上一步重新签发，签发后立刻复制。",
          "en": "Go back a step, issue a new one, and copy it right away.",
          "ja": "前の手順に戻って発行し直し、発行したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 API-Token 读不到服务器账单。",
          "en": "This API-Token cannot read server billing.",
          "ja": "この API-Token ではサーバ請求を読めません。"
        },
        "nextStep": {
          "zh": "回 Ermes 重建一把长效 API-Token，不要用登录 JWT。",
          "en": "Go back to Ermes and create a new long-lived API-Token. Do not use a login JWT.",
          "ja": "Ermes に戻り、長寿命の API-Token を作り直してください。ログイン JWT は使わないでください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.seeweb.it/",
    "credentialSetupURL": "https://ermes.cloudcenter.seeweb.it",
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
        "zh": "打开 Parasail 的 API Keys，点 Create API Key。Access Level 选 Read-only（账单只读），起个名字，再点 Create，然后立刻复制，只显示一次。",
        "en": "Open Parasail API Keys, tap Create API Key. Under Access Level choose Read-only (billing read), name it, tap Create, then copy it immediately — it is shown only once.",
        "ja": "Parasail の API Keys を開き、Create API Key をタップします。Access Level は Read-only（請求の読み取り）を選び、名前を付けて Create をタップし、すぐコピーします。一度しか表示されません。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把 API Key 无效，或者已经被撤销。",
          "en": "This API Key is invalid, or it has already been revoked.",
          "ja": "この API Key は無効か、すでに取り消されています。"
        },
        "nextStep": {
          "zh": "回上一步重新签发，签发后立刻复制。",
          "en": "Go back a step, issue a new one, and copy it right away.",
          "ja": "前の手順に戻って発行し直し、発行したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把钥匙读不到发票。",
          "en": "This key cannot read invoices.",
          "ja": "このキーではインボイスを読めません。"
        },
        "nextStep": {
          "zh": "回 API Keys 用 Read-only 重建一把，并确认当前组织是付账那个。",
          "en": "Go back to API Keys, create a Read-only key, and confirm the active organization is the one that pays.",
          "ja": "API Keys に戻り Read-only で作り直し、今の組織が支払いしている組織か確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.parasail.io/",
    "credentialSetupURL": "https://www.saas.parasail.io/keys",
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
          "zh": "Mybring 登录邮箱，不是新建的",
          "en": "Your Mybring login email. Do not create a new one.",
          "ja": "Mybring のログイン用メール。新規作成しない"
        }
      },
      {
        "key": "accountID",
        "label": {
          "zh": "Customer number",
          "en": "Customer number",
          "ja": "Customer number"
        },
        "isSecret": false,
        "hint": {
          "zh": "Mybring API 页上的客户号，复制即可",
          "en": "The customer number on the Mybring API page. Copy it.",
          "ja": "Mybring API ページの顧客番号。コピーするだけ"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Mybring API 页，创建 API Key，然后复制。这把钥匙绑在你的登录账号上。",
        "en": "Open the Mybring API page, create an API Key, then copy it. The key is tied to your login.",
        "ja": "Mybring API ページを開き、API Key を作成してコピーします。キーはログインアカウントに紐づきます。"
      },
      {
        "zh": "还在 Mybring API 页复制登录邮箱作为 Email，再复制要记账的 Customer number。不要去创建邮箱或客户号。没有财务权限就先在客户号上申请。",
        "en": "Still on the Mybring API page, copy your login email as Email, then copy the Customer number you bill against. Do not create an email or customer number. If you lack financial rights, apply for them on that customer number first.",
        "ja": "引き続き Mybring API ページで、ログイン用メールを Email としてコピーし、計上する Customer number もコピーします。メールも顧客番号も新規作成しないでください。財務権限がなければ、その顧客番号で先に申請します。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把 API Key 无效，或者已经被撤销。",
          "en": "This API Key is invalid, or it has already been revoked.",
          "ja": "この API Key は無効か、すでに取り消されています。"
        },
        "nextStep": {
          "zh": "回上一步重新签发，签发后立刻复制。",
          "en": "Go back a step, issue a new one, and copy it right away.",
          "ja": "前の手順に戻って発行し直し、発行したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这个账号对这个 Customer number 没有财务权限。",
          "en": "This user does not have financial rights on this Customer number.",
          "ja": "このユーザーにはこの Customer number の財務権限がありません。"
        },
        "nextStep": {
          "zh": "回 Mybring API 页确认客户号，并给这个用户申请财务权限。",
          "en": "Go back to the Mybring API page, confirm the customer number, and apply for financial rights for this user.",
          "ja": "Mybring API ページで顧客番号を確認し、このユーザーに財務権限を申請してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.mybring.com/",
    "credentialSetupURL": "https://www.mybring.com/useradmin/account/settings/api",
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
        "zh": "打开 Armada 商家控制台的 API Keys（Automated Ordering 下面），点 Create key。立刻复制 secret（创建时只明文显示一次），再复制 API Key（main_ 开头）。把 invoices:read 打开。",
        "en": "Open API Keys in the Armada business app (under Automated Ordering) and tap Create key. Copy the secret immediately — it is shown in plain text only once at creation — then copy the API Key (starts with main_). Turn on invoices:read.",
        "ja": "Armada ビジネスアプリの API Keys（Automated Ordering の下）を開き、Create key をタップします。secret は作成時に一度だけ平文表示されるのですぐコピーし、続けて API Key（main_ で始まる）もコピーします。invoices:read をオンにしてください。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把 API Key 无效，或者已经被撤销。",
          "en": "This API Key is invalid, or it has already been revoked.",
          "ja": "この API Key は無効か、すでに取り消されています。"
        },
        "nextStep": {
          "zh": "回上一步重新签发，签发后立刻复制。",
          "en": "Go back a step, issue a new one, and copy it right away.",
          "ja": "前の手順に戻って発行し直し、発行したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把钥匙缺 invoices:read，所以读不到发票。",
          "en": "This key is missing invoices:read, so it cannot read invoices.",
          "ja": "このキーに invoices:read がないため、インボイスを読めません。"
        },
        "nextStep": {
          "zh": "回 API Keys 打开 invoices:read。HMAC 对不上也是 401，先核对 secret。",
          "en": "Go back to API Keys and turn on invoices:read. A bad HMAC also returns 401 — check the secret first.",
          "ja": "API Keys に戻り invoices:read をオンにしてください。HMAC が違うと 401 になるので、先に secret を確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.armadadelivery.com/",
    "credentialSetupURL": "https://business.armadadelivery.com",
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
          "zh": "Advanced Access Token",
          "en": "Advanced Access Token",
          "ja": "Advanced Access Token"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Mollie 的 Developers → API access tokens，创建 Advanced Access Token。权限勾 invoices.read。不要用 live_ / test_ 支付 API Key。创建后立刻复制，只显示一次。需要 Admin 角色。",
        "en": "Open Mollie Developers → API access tokens and create an Advanced Access Token. Grant invoices.read. Do not use a live_ or test_ payment API key. Copy it immediately — it is shown only once. You need the Admin role.",
        "ja": "Mollie の Developers → API access tokens を開き、Advanced Access Token を作成します。権限は invoices.read を付け、live_ / test_ の支払い API Key は使わないでください。作成したらすぐコピーします。一度しか表示されません。Admin ロールが必要です。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把 Advanced Access Token 无效，或者已经被撤销。",
          "en": "This Advanced Access Token is invalid, or it has already been revoked.",
          "ja": "この Advanced Access Token は無効か、すでに取り消されています。"
        },
        "nextStep": {
          "zh": "回上一步重新签发，签发后立刻复制。",
          "en": "Go back a step, issue a new one, and copy it right away.",
          "ja": "前の手順に戻って発行し直し、発行したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 token 缺 invoices.read，或者只是支付用的 live_ / test_ 钥匙。",
          "en": "This token is missing invoices.read, or it is only a live_ / test_ payment key.",
          "ja": "この token に invoices.read がないか、live_ / test_ の支払いキーです。"
        },
        "nextStep": {
          "zh": "回 API access tokens 用 Admin 重建一把 Advanced Access Token，只打开 invoices.read。",
          "en": "Go back to API access tokens as Admin and create an Advanced Access Token with invoices.read.",
          "ja": "API access tokens に戻り、Admin で invoices.read 付きの Advanced Access Token を作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://my.mollie.com/",
    "credentialSetupURL": "https://my.mollie.com/dashboard/developers/api-access-tokens",
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
          "zh": "Secret API key",
          "en": "Secret API key",
          "ja": "Secret API key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 Checkout.com 控制台的 Developers → Keys，点 Create a new key，类型选 Secret API key（sk_ 开头）。需要报表明细就 Customize 打开 Reporting。创建后立刻复制密钥，只显示一次。不要用 Public API key。",
        "en": "Open Developers → Keys in the Checkout.com Dashboard, tap Create a new key, and choose Secret API key (starts with sk_). If you need statements, Customize and enable Reporting. Copy the secret immediately — it is shown only once. Do not use a Public API key.",
        "ja": "Checkout.com ダッシュボードの Developers → Keys を開き、Create a new key をタップして Secret API key（sk_ で始まる）を選びます。明細が必要なら Customize で Reporting を付けます。秘密値は一度しか表示されないのですぐコピーしてください。Public API key は使わないでください。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把 Secret API key 无效，或者已经被撤销。",
          "en": "This Secret API key is invalid, or it has already been revoked.",
          "ja": "この Secret API key は無効か、すでに取り消されています。"
        },
        "nextStep": {
          "zh": "回上一步重新签发，签发后立刻复制。",
          "en": "Go back a step, issue a new one, and copy it right away.",
          "ja": "前の手順に戻って発行し直し、発行したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把钥匙读不到对账单。",
          "en": "This key cannot read statements.",
          "ja": "このキーではステートメントを読めません。"
        },
        "nextStep": {
          "zh": "回 Keys 用 Secret API key 重建，Customize 打开 Reporting，不要用 Public API key。",
          "en": "Go back to Keys, create a Secret API key, Customize Reporting, and do not use a Public API key.",
          "ja": "Keys に戻り Secret API key を作り直し、Customize で Reporting を付けてください。Public API key は使わないでください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://dashboard.checkout.com/",
    "credentialSetupURL": "https://dashboard.checkout.com/developers/keys",
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
          "zh": "Shop ID",
          "en": "Shop ID",
          "ja": "Shop ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "My Stores 里店铺的数字 ID，复制即可，不要新建",
          "en": "The numeric shop id in My Stores. Copy it; do not create one.",
          "ja": "My Stores のショップ数字 ID。コピーするだけ。新規作成しない"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Printify 的 Connections，点 Generate，起个名字并勾 shops.read 和 orders.read，再点 Generate token，然后立刻复制。一年过期，丢了只能再签一把。",
        "en": "Open Printify Connections, tap Generate, name the token, check shops.read and orders.read, tap Generate token, then copy it immediately. Tokens expire after one year; if you lose it you must issue another.",
        "ja": "Printify の Connections を開き、Generate をタップして名前を付け、shops.read と orders.read にチェックを入れ、Generate token をタップしてすぐコピーします。有効期限は 1 年で、なくしたら作り直すしかありません。"
      },
      {
        "zh": "打开 My Stores，复制要记账的那家店的 Shop ID。不要创建 Account ID。",
        "en": "Open My Stores and copy the Shop ID of the shop you bill against. Do not create an Account ID.",
        "ja": "My Stores を開き、計上する店の Shop ID をコピーします。Account ID は作成しないでください。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把 API token 无效，或者已经被撤销。",
          "en": "This API token is invalid, or it has already been revoked.",
          "ja": "この API token は無効か、すでに取り消されています。"
        },
        "nextStep": {
          "zh": "回上一步重新签发，签发后立刻复制。",
          "en": "Go back a step, issue a new one, and copy it right away.",
          "ja": "前の手順に戻って発行し直し、発行したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 token 读不到这家店的订单。",
          "en": "This token cannot read orders for this shop.",
          "ja": "この token ではこのショップの注文を読めません。"
        },
        "nextStep": {
          "zh": "确认 Shop ID 是付印费那家店的，并且 token 勾了 orders.read。",
          "en": "Confirm the Shop ID is the shop that pays for prints, and that the token has orders.read.",
          "ja": "Shop ID が印刷代を払っている店か、token に orders.read が付いているか確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [
      {
        "id": "findShopID",
        "url": "https://developers.printify.com/#retrieving-shop-id"
      }
    ],
    "billingURL": "https://printify.com/",
    "credentialSetupURL": "https://printify.com/app/account/api",
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
        "zh": "打开 teelaunch 的 Account Settings，滚到 Developer Settings，复制 API Key。接口用 Authorization: Bearer。",
        "en": "Open teelaunch Account Settings, scroll to Developer Settings, and copy the API Key. Send it as Authorization: Bearer.",
        "ja": "teelaunch の Account Settings を開き、Developer Settings までスクロールして API Key をコピーします。ヘッダーは Authorization: Bearer です。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把 API Key 无效，或者已经被撤销。",
          "en": "This API Key is invalid, or it has already been revoked.",
          "ja": "この API Key は無効か、すでに取り消されています。"
        },
        "nextStep": {
          "zh": "回上一步重新签发，签发后立刻复制。",
          "en": "Go back a step, issue a new one, and copy it right away.",
          "ja": "前の手順に戻って発行し直し、発行したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 API Key 读不到付款记录。",
          "en": "This API Key cannot read payment history.",
          "ja": "この API Key では支払い履歴を読めません。"
        },
        "nextStep": {
          "zh": "回 Developer Settings 重新复制。文档没有单独的只读权限可勾。",
          "en": "Go back to Developer Settings and copy it again. The docs do not offer a separate read-only scope.",
          "ja": "Developer Settings に戻ってコピーし直してください。ドキュメントに読み取り専用の権限はありません。"
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
          "zh": "同一把 Live REST 应用里的 Client ID，不要用 Sandbox",
          "en": "From the same Live REST app. Not Sandbox.",
          "ja": "同じ Live の REST アプリから。Sandbox ではありません"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 PayPal 开发者后台 的 Apps & Credentials，切到 Live，在 REST API apps 点 Create App。点 Show 复制 Client Secret。必须勾选 Transaction Search 并 Save。",
        "en": "Open Apps & Credentials in the PayPal Developer Dashboard, switch to Live, and tap Create App under REST API apps. Tap Show and copy the Client Secret. Check Transaction Search and Save.",
        "ja": "PayPal デベロッパーダッシュボード の Apps & Credentials を開き、Live に切り替えて REST API apps で Create App をタップします。Show を押して Client Secret をコピーし、Transaction Search にチェックを入れて Save します。"
      },
      {
        "zh": "同一应用的 Client ID 一并复制，不要另建。不要用 Sandbox 钥匙。手续费走 Transaction Search，不是营收。",
        "en": "Copy the Client ID from the same app. Do not create another one. Do not use Sandbox keys. This records Transaction Search fees, not your revenue.",
        "ja": "同じアプリの Client ID もコピーし、別途作らないでください。Sandbox の鍵は使わないでください。ここは Transaction Search の手数料で、売上ではありません。"
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
          "zh": "这把应用没开 Transaction Search，读不到手续费。",
          "en": "This app does not have Transaction Search, so it cannot read fees.",
          "ja": "このアプリに Transaction Search がないため、手数料を読めません。"
        },
        "nextStep": {
          "zh": "回 Apps & Credentials 的 Live 应用勾选 Transaction Search 并 Save。刚改过要重新换 token。",
          "en": "Go back to the Live app under Apps & Credentials, check Transaction Search, and Save. After a change, request a new token.",
          "ja": "Apps & Credentials の Live アプリで Transaction Search をオンにして Save してください。変更したあとは token を取り直します。"
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
        "zh": "打开 Paystack 控制台的 Settings，进 API Keys & Webhooks（Canvas 则走 Developers overview）。",
        "en": "Open Settings in the Paystack dashboard, then API Keys & Webhooks (or Developers overview in Canvas).",
        "ja": "Paystack ダッシュボードの Settings を開き、API Keys & Webhooks に入ります（Canvas なら Developers overview）。"
      },
      {
        "zh": "复制 Live Secret Key（sk_live_ 开头）。不要用 Public Key 或 Test Key。需要轮换就在同一页生成新钥匙。",
        "en": "Copy the Live Secret Key (starts with sk_live_). Don’t use the Public Key or a Test Key. Rotate it on this same page if you need a new one.",
        "ja": "Live Secret Key（sk_live_ で始まる）をコピーします。Public Key や Test Key は使わないでください。作り直すなら同じページで生成します。"
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
    "credentialSetupURL": "https://dashboard.paystack.com/#/settings/developers",
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
        "zh": "打开 Flutterwave 控制台的 Settings，在 Developers 里点 API Keys。先切到 Live。",
        "en": "Open Settings in the Flutterwave dashboard, then API Keys under Developers. Switch to Live first.",
        "ja": "Flutterwave ダッシュボードの Settings を開き、Developers の API Keys を選びます。先に Live に切り替えます。"
      },
      {
        "zh": "点 Generate Secret Key，用邮件里的 7 位验证码确认，然后立刻复制或下载 Secret Key。不要用 Public Key。",
        "en": "Tap Generate Secret Key, confirm with the 7-digit code emailed to you, then copy or download the Secret Key right away. Don’t use the Public Key.",
        "ja": "Generate Secret Key をタップし、メールの 7 桁コードで確認してから、すぐ Secret Key をコピーまたはダウンロードします。Public Key は使わないでください。"
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
    "credentialSetupURL": "https://dashboard.flutterwave.com/dashboard/settings/apis",
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
        "isSecret": true,
        "hint": {
          "zh": "API 用户密码",
          "en": "API user password",
          "ja": "API ユーザーのパスワード"
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
          "zh": "API 用户名",
          "en": "API username",
          "ja": "API ユーザー名"
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
          "zh": "API 信息里的租户 ID，不用创建",
          "en": "Tenant ID in API information — don’t create one",
          "ja": "API 情報のテナント ID。作成は不要"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 ConoHa 控制台左侧 API，点 +用户，设密码并保存。密码填进 Client Secret。一个账号只能有一个 API 用户，默认全权限。",
        "en": "Open API in the left menu of the ConoHa dashboard, tap + User, set a password, and save. Put that password in Client Secret. One account can have only one API user, with full access by default.",
        "ja": "ConoHa コントロールパネル左メニューの API を開き、+ユーザー でパスワードを入れて保存します。そのパスワードを Client Secret に入れます。API ユーザーはアカウントにつき 1 人で、初期は全権限です。"
      },
      {
        "zh": "同一页复制 API 用户名，填进 Client ID。点开「租户信息」复制 Tenant ID。租户 ID 不用创建。",
        "en": "On the same page, copy the API username into Client ID. Expand Tenant information and copy Tenant ID. Don’t create a Tenant ID.",
        "ja": "同じページで API ユーザー名をコピーし、Client ID に入れます。「テナント情報」を開いて Tenant ID をコピーします。テナント ID は作らないでください。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "API 用户名或密码不对。",
          "en": "The API username or password is wrong.",
          "ja": "API ユーザー名かパスワードが違います。"
        },
        "nextStep": {
          "zh": "回控制台 API 页核对用户名，必要时点编辑重设密码，立刻复制。",
          "en": "Check the username on the dashboard API page. If needed, tap Edit to reset the password and copy it right away.",
          "ja": "コントロールパネルの API でユーザー名を確認し、必要なら編集でパスワードを再設定してすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "Token 换到了错误的租户。",
          "en": "The token was issued for the wrong tenant.",
          "ja": "別テナントの token になっています。"
        },
        "nextStep": {
          "zh": "Tenant ID 从「租户信息」复制，不要手填区域名。",
          "en": "Copy Tenant ID from Tenant information — don’t type a region name by hand.",
          "ja": "Tenant ID は「テナント情報」からコピーし、リージョン名を手入力しないでください。"
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
          "zh": "API 用户名，不是 OAuth Client ID",
          "en": "API username, not an OAuth client ID",
          "ja": "API ユーザー名。OAuth の client ID ではありません"
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
          "zh": "控制台 API 菜单里的 Tenant ID。抄下来，不要创建",
          "en": "From the console API menu. Copy it; do not create one.",
          "ja": "コンソールの API メニューからコピー。作成しません"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 创建 API 用户，在控制台 API 菜单点 +User，设好密码后立刻复制。这是 Identity 密码，不是 OAuth Client Secret。",
        "en": "Open Create an API user. In the console API menu tap +User, set a password, and copy it right away. This is the Identity password, not an OAuth Client Secret.",
        "ja": "APIユーザーを作成する を開き、コンソールの API メニューで +User をタップし、パスワードを設定したらすぐにコピーします。OAuth の Client Secret ではなく、Identity 用のパスワードです。"
      },
      {
        "zh": "Client ID 填 API 用户名，不要再创建一把。Tenant ID 从控制台 API 菜单抄，见 确认 API 信息，不要创建。",
        "en": "Put the API username in Client ID; do not create another one. Copy Tenant ID from the console API menu; see Check API information. Do not create a Tenant ID.",
        "ja": "Client ID には API ユーザー名を入れ、新しく作らないでください。Tenant ID はコンソールの API メニューからコピーします。API情報を確認する を参照。Tenant ID は作成しません。"
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
    "guideURLs": [
      {
        "id": "findTenant",
        "url": "https://cloud.z.com/jp/guide/cp-get_api_info/"
      }
    ],
    "billingURL": "https://cloud.z.com/",
    "credentialSetupURL": "https://cloud.z.com/jp/guide/cp-create_api_user/",
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
        "zh": "打开 IDCF Cloud 控制台 的 コンピュート → API，复制已有的 API Key 和 Secret Key。Secret Key 填进 Client Secret。这是看的，不是另建一套 OAuth。",
        "en": "Open Compute → API in the IDCF Cloud console and copy the API Key and Secret Key already shown. Put Secret Key in Client Secret. These keys are listed there; do not create a separate OAuth pair.",
        "ja": "IDCF Cloud コンソール の コンピュート → API を開き、表示されている API Key と Secret Key をコピーします。Secret Key は Client Secret に入れます。別の OAuth は作りません。"
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
    "credentialSetupURL": "https://console.idcfcloud.com/user/apikey",
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
          "zh": "AutoDNS 用户名，不是 OAuth Client ID",
          "en": "AutoDNS username, not an OAuth client ID",
          "ja": "AutoDNS のユーザー名。OAuth の client ID ではありません"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Authentication。用 AutoDNS 用户名和自己设定的密码做 HTTP Basic。Client Secret 就是这份密码，不是 OAuth secret。Live 的 X-Domainrobot-Context 默认是 4。",
        "en": "Open Authentication. Use the AutoDNS username and a password you set, as HTTP Basic. Client Secret is that password, not an OAuth secret. For Live, X-Domainrobot-Context defaults to 4.",
        "ja": "Authentication を開きます。AutoDNS のユーザー名と自分で決めたパスワードを HTTP Basic に使います。Client Secret はそのパスワードで、OAuth の secret ではありません。Live の X-Domainrobot-Context の初期値は 4 です。"
      },
      {
        "zh": "Client ID 填 AutoDNS 用户名，不要创建 OAuth Client ID。JSON API 无需额外开通。User-Agent 必填。",
        "en": "Put the AutoDNS username in Client ID. Do not create an OAuth Client ID. The JSON API needs no extra activation. User-Agent is required.",
        "ja": "Client ID には AutoDNS のユーザー名を入れ、OAuth の Client ID は作らないでください。JSON API に追加の有効化は不要です。User-Agent は必須です。"
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
    "credentialSetupURL": "https://help.internetx.com/display/APIXMLEN/Authentication",
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
        "zh": "打开 Melbicom API 文档。每个请求必须带 Authorization: Bearer TOKEN。在客户区签发 API Token，创建后立刻复制。",
        "en": "Open the Melbicom API docs. Every request must send Authorization: Bearer TOKEN. Issue an API Token in the client area and copy it right away.",
        "ja": "Melbicom API ドキュメント を開きます。各リクエストに Authorization: Bearer TOKEN が必要です。顧客エリアで API Token を発行し、作成したらすぐにコピーします。"
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
        "zh": "打开 Time4VPS 客户门户的 User API 文档。认证用的是客户区登录密码，不是另开一把钥匙。把客户区密码填进 Client Secret。",
        "en": "Open the User API docs in the Time4VPS client portal. Auth uses your client-area password, not a separate key. Put that password in Client Secret.",
        "ja": "Time4VPS クライアントポータルの User API ドキュメントを開きます。認証はクライアントエリアのパスワードで、別の鍵ではありません。そのパスワードを Client Secret に入れます。"
      },
      {
        "zh": "同一份 User API 文档写明用户名就是客户区登录邮箱。把那封邮箱填进 Email，不要新建邮箱。",
        "en": "The same User API docs say the username is your client-area login email. Put that address in Email — don’t create a new mailbox.",
        "ja": "同じ User API ドキュメントでは、ユーザー名はクライアントエリアのログインメールです。そのアドレスを Email に入れ、新しいメールは作らないでください。"
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
        "zh": "打开 BitLaunch 控制台，点右上角头像进账户设置。",
        "en": "Open the BitLaunch dashboard, tap the face icon at the top right, and go to account settings.",
        "ja": "BitLaunch ダッシュボードを開き、右上の顔アイコンからアカウント設定に入ります。"
      },
      {
        "zh": "生成 Personal Access Token，创建后立刻复制。泄露了就马上再生成一把。",
        "en": "Generate a Personal Access Token and copy it right away. If it leaks, regenerate it immediately.",
        "ja": "Personal Access Token を生成し、すぐにコピーします。漏れたらすぐ作り直してください。"
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
    "credentialSetupURL": "https://developers.bitlaunch.io/docs/getting-started",
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
        "zh": "打开 Hivelocity 控制台（myVelocity），进 Settings > API Keys。",
        "en": "Open the Hivelocity dashboard (myVelocity), then go to Settings > API Keys.",
        "ja": "Hivelocity ダッシュボード（myVelocity）を開き、Settings > API Keys に入ります。"
      },
      {
        "zh": "每位用户只有一把 API Key。要轮换就点 GENERATE NEW KEY，创建后立刻复制。",
        "en": "Each user has a single API Key. To rotate it, tap GENERATE NEW KEY, then copy it right away.",
        "ja": "ユーザーごとに API Key は 1 本です。ローテーションするなら GENERATE NEW KEY をタップし、すぐにコピーします。"
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
    "credentialSetupURL": "https://developers.hivelocity.net/docs/api-keys",
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
        "zh": "打开 Scalingo 控制台，右上角头像 → User settings → API Tokens，生成一把 API Token，然后复制。",
        "en": "Open the Scalingo dashboard, then the top-right avatar → User settings → API Tokens. Generate an API Token and copy it.",
        "ja": "Scalingo ダッシュボードを開き、右上のアバター → User settings → API Tokens で API Token を生成してコピーします。"
      },
      {
        "zh": "这把是长效 token（tk-us- 开头）。App 会拿它去换一小时的 Bearer。不要把换来的 Bearer 填进来。",
        "en": "This is the long-lived token (starts with tk-us-). The app exchanges it for a one-hour Bearer. Do not paste that Bearer here.",
        "ja": "これは長寿命 token（tk-us- で始まる）です。アプリが 1 時間の Bearer に交換します。その Bearer をここに貼らないでください。"
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
          "zh": "这个 token 换不出能读发票的 Bearer。",
          "en": "This token cannot be exchanged for a Bearer that can read invoices.",
          "ja": "この token ではインボイスを読める Bearer に交換できません。"
        },
        "nextStep": {
          "zh": "回上一步用付账那个账户重新生成一把 API Token。",
          "en": "Go back a step and generate a new API Token on the paying account.",
          "ja": "前の手順に戻り、支払い口座で API Token を作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://dashboard.scalingo.com/",
    "credentialSetupURL": "https://doc.scalingo.com/platform/user-management/scalingo-account/navigating",
    "summary": {
      "zh": "法国应用托管。按本月发票合计，欧元会折成美元。",
      "en": "French app hosting. This month’s invoices, summed. Euros convert to USD.",
      "ja": "フランスのアプリホスティング。今月のインボイス合計で、ユーロはドルに換算します。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月发票一致。欧元会折成美元。",
      "en": "This number should match this month’s invoices in the dashboard. Euros convert to USD.",
      "ja": "この数字はダッシュボードの今月のインボイスと一致するはずです。ユーロはドルに換算します。"
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
          "zh": "组织 ID，复制即可，不要去创建",
          "en": "Organization ID. Copy it; do not create one.",
          "ja": "組織 ID。コピーするだけで、新規作成しません。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Upsun Console：用户菜单 → My profile → API tokens，点 Create API token。立刻复制，关掉就看不到。",
        "en": "In the Upsun Console, open the user menu → My profile → API tokens, then tap Create API token. Copy immediately; you cannot view it again after closing the tab.",
        "ja": "Upsun Console でユーザーメニュー → My profile → API tokens を開き、Create API token をタップします。すぐにコピー。タブを閉じると再表示できません。"
      },
      {
        "zh": "Account ID 是 organization id，不是创建出来的。在组织 Settings 里复制付账那个组织的 ID。",
        "en": "Account ID is the organization id. It is not created. Copy the paying organization’s ID from organization Settings.",
        "ja": "Account ID は organization id で、作成するものではありません。組織 Settings から支払い組織の ID をコピーします。"
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
          "zh": "这个 token 读不到该组织的订单，或 organization id 填错了。",
          "en": "This token cannot read that organization’s orders, or the organization id is wrong.",
          "ja": "この token ではその組織の注文を読めないか、organization id が違います。"
        },
        "nextStep": {
          "zh": "回上一步确认组织 ID，并用该组织成员重新签发 API token。",
          "en": "Go back a step, check the organization ID, and issue a new API token as a member of that organization.",
          "ja": "前の手順に戻り、組織 ID を確認し、その組織のメンバーで API token を発行し直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://console.upsun.com/",
    "credentialSetupURL": "https://developer.upsun.com/cli/api-tokens",
    "summary": {
      "zh": "应用托管 PaaS（原 Platform.sh）。按本月订单合计。",
      "en": "App-hosting PaaS (formerly Platform.sh). This month’s orders, summed.",
      "ja": "アプリホスティング PaaS（旧 Platform.sh）。今月の注文合計です。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月订单合计一致。",
      "en": "This number should match this month’s orders in the dashboard.",
      "ja": "この数字はダッシュボードの今月の注文合計と一致するはずです。"
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
        "zh": "打开 NAVER Cloud 控制台右上角 My Account > Manage Account and Security，再进 Manage security > Manage access。",
        "en": "In the NAVER Cloud console, open My Account > Manage Account and Security at the top right, then Manage security > Manage access.",
        "ja": "NAVER Cloud コンソール右上の My Account > Manage Account and Security を開き、Manage security > Manage access に入ります。"
      },
      {
        "zh": "点 Create New Authentication Key（或 Create new API authentication key）。立刻复制 Secret Key。子账号要主账号先打开 API 权限，读账单还要财务相关策略。",
        "en": "Tap Create New Authentication Key (or Create new API authentication key). Copy the Secret Key right away. A sub account needs the main account to turn on API access first, plus a finance-related policy to read bills.",
        "ja": "Create New Authentication Key（または Create new API authentication key）をタップし、すぐ Secret Key をコピーします。サブアカウントは先にメインアカウントが API 権限を付け、請求を読むなら財務系のポリシーも必要です。"
      },
      {
        "zh": "同一把认证钥匙会同时给出 Access Key ID。把它复制下来，不要再新建一把。账号最多两把。",
        "en": "The same authentication key also shows an Access Key ID. Copy that — don’t create a second key. Each account can have at most two.",
        "ja": "同じ認証キーに Access Key ID も出ます。それをコピーし、もう 1 本作らないでください。アカウントあたり最大 2 本です。"
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
    "credentialSetupURL": "https://api.ncloud-docs.com/docs/en/common-ncpapi",
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
        "zh": "打开 Nomos 控制台，创建一个 API key。范围只勾 read:*，不要 write:*。创建后立刻复制 Client Secret。",
        "en": "Open the Nomos dashboard and create an API key. Check only read:*, not write:*. Copy the Client Secret right away.",
        "ja": "Nomos ダッシュボードを開き、API key を作ります。範囲は read:* だけにし、write:* は付けません。作成したらすぐ Client Secret をコピーします。"
      },
      {
        "zh": "同一把 API key 上复制 Client ID，不要再新建一把。范围创建后改不了，要换权限只能另开一把再轮换。",
        "en": "Copy the Client ID from that same API key — don’t create another. Scopes can’t be changed later; rotate to a new key if you need different access.",
        "ja": "同じ API key の Client ID をコピーし、もう 1 本作らないでください。範囲は後から変えられないので、権限を変えるなら新しいキーに切り替えます。"
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
    "credentialSetupURL": "https://dashboard.nomos.energy",
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
        "zh": "打开 DNScale 控制台的 Settings > API Keys，点 Create API Key。",
        "en": "Open Settings > API Keys in the DNScale dashboard, then tap Create API Key.",
        "ja": "DNScale ダッシュボードの Settings > API Keys を開き、Create API Key をタップします。"
      },
      {
        "zh": "勾 billing:read。账单只要这一项。创建后立刻复制，只显示一次。",
        "en": "Check billing:read. That’s all billing needs. Copy the key right away — it’s shown only once.",
        "ja": "billing:read にチェックします。請求にはこれだけで足ります。キーは一度しか出ないので、すぐにコピーします。"
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
    "credentialSetupURL": "https://dnscale.eu/api/authentication",
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
        "zh": "先切到要记账的那个团队，打开 Formspring 控制台的 API tokens 页，点 Create token。",
        "en": "Switch to the team you pay from, open API tokens in the Formspring dashboard, then tap Create token.",
        "ja": "支払い中のチームに切り替えてから、Formspring ダッシュボードの API tokens を開き、Create token をタップします。"
      },
      {
        "zh": "能力只勾 billing:read。创建后立刻复制，只显示一次。",
        "en": "Check only the billing:read ability. Copy the token right away — it’s shown only once.",
        "ja": "能力は billing:read だけにします。トークンは一度しか出ないので、すぐにコピーします。"
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
    "credentialSetupURL": "https://formspring.io/tokens",
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
          "zh": "账户详情里的用户编号",
          "en": "User number from account details",
          "ja": "アカウント詳細のユーザー番号"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Hostcircle 客户门户的 User API 文档。Client Secret 是客户区密码，不是新钥匙。",
        "en": "Open the User API docs in the Hostcircle client portal. Client Secret is your client-area password, not a new key.",
        "ja": "Hostcircle クライアントポータルの User API ドキュメントを開きます。Client Secret はクライアントエリアのパスワードで、新しい鍵ではありません。"
      },
      {
        "zh": "若文档提供 JWT，用同一套邮箱和密码换 token 填 API Token；只用密码认证就把客户区密码再贴一次。",
        "en": "If the docs offer JWT, exchange that same email and password for a token and put it in API Token. If you only use password auth, paste the client-area password here too.",
        "ja": "ドキュメントが JWT を出すなら、同じメールとパスワードで token を取り、API Token に入れます。パスワード認証だけなら、クライアントエリアのパスワードをもう一度貼ります。"
      },
      {
        "zh": "Email 填客户区登录邮箱，不要新建。Client ID 在账户详情里复制（用户编号），不要创建。",
        "en": "Put your client-area login email in Email — don’t create a new mailbox. Copy Client ID from account details (the user number) — don’t create one.",
        "ja": "Email にはクライアントエリアのログインメールを入れ、新規作成しないでください。Client ID はアカウント詳細のユーザー番号をコピーし、作らないでください。"
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
        "zh": "打开 Loginet 客户门户的 User API 文档。认证用的是客户区登录密码，不是另开一把钥匙。把客户区密码填进 Client Secret。",
        "en": "Open the User API docs in the Loginet client portal. Auth uses your client-area password, not a separate key. Put that password in Client Secret.",
        "ja": "Loginet クライアントポータルの User API ドキュメントを開きます。認証はクライアントエリアのパスワードで、別の鍵ではありません。そのパスワードを Client Secret に入れます。"
      },
      {
        "zh": "同一份 User API 文档写明用户名就是客户区登录邮箱。把那封邮箱填进 Email，不要新建邮箱。",
        "en": "The same User API docs say the username is your client-area login email. Put that address in Email — don’t create a new mailbox.",
        "ja": "同じ User API ドキュメントでは、ユーザー名はクライアントエリアのログインメールです。そのアドレスを Email に入れ、新しいメールは作らないでください。"
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
          "zh": "billing_account_id，复制即可，不要去创建",
          "en": "billing_account_id. Copy it; do not create one.",
          "ja": "billing_account_id。コピーするだけで、新規作成しません。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 IDCloudHost Console：Core Service → API Token。Type 选 API Token。",
        "en": "Open IDCloudHost Console → Core Service → API Token. Set Type to API Token.",
        "ja": "IDCloudHost Console の Core Service → API Token を開きます。Type は API Token にします。"
      },
      {
        "zh": "Scope 选 Restricted 时指定 Billing account，或选 Global。填 Access name，点 Create，立刻复制 token。请求头是 apikey。",
        "en": "For Restricted scope, pick the Billing account; or choose Global. Fill Access name, tap Create, and copy the token immediately. The header is apikey.",
        "ja": "Restricted なら Billing account を指定し、または Global を選びます。Access name を入れて Create をタップし、token をすぐにコピー。ヘッダーは apikey です。"
      },
      {
        "zh": "Account ID 是 billing_account_id，不是创建出来的。在 Billing 菜单复制对应账单账户的 ID。Restricted token 必须对上这个账户。",
        "en": "Account ID is billing_account_id. It is not created. Copy it from the Billing menu. A Restricted token must match this account.",
        "ja": "Account ID は billing_account_id で、作成しません。Billing メニューからコピーします。Restricted token はこの口座と一致している必要があります。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把钥匙无效，或者已经被撤销了。",
          "en": "This key is invalid, or it has already been revoked.",
          "ja": "このキーは無効か、すでに取り消されています。"
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
          "zh": "这把 token 的 Billing account 对不上，或 Restricted 范围太窄。",
          "en": "This token’s Billing account does not match, or Restricted scope is too narrow.",
          "ja": "この token の Billing account が一致しないか、Restricted の範囲が狭すぎます。"
        },
        "nextStep": {
          "zh": "回上一步核对应账单账户 ID，或改用 Global 再签发。",
          "en": "Go back a step, check the billing account ID, or issue a Global token.",
          "ja": "前の手順に戻り、請求口座 ID を確認するか、Global で発行し直してください。"
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
      "zh": "这个数字应该和后台本月发票一致。印尼盾会折成美元。",
      "en": "This number should match this month’s invoices in the dashboard. Rupiah convert to USD.",
      "ja": "この数字はダッシュボードの今月のインボイスと一致するはずです。ルピアはドルに換算します。"
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
        "zh": "打开 iwinv 控制台，签发 Access Key。Secret Key 只显示一次，填进 Secret Access Key。认证头是 X-iwinv-Credential 和 X-iwinv-Signature。",
        "en": "Open the iwinv console and issue an Access Key. The Secret Key is shown only once; put it in Secret Access Key. Auth headers are X-iwinv-Credential and X-iwinv-Signature.",
        "ja": "iwinv コンソール を開き、Access Key を発行します。Secret Key は一度だけ表示されるので Secret Access Key に入れます。認証ヘッダは X-iwinv-Credential と X-iwinv-Signature です。"
      },
      {
        "zh": "同一把钥匙的 Access Key 填进 Access Key ID，不要再创建一把。",
        "en": "Put the Access Key from the same pair into Access Key ID. Do not create another key.",
        "ja": "同じ鍵の Access Key を Access Key ID に入れ、別の鍵は作らないでください。"
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
    "credentialSetupURL": "https://console.iwinv.kr/",
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
          "zh": "siteReference：邮编加门牌，例如 1000AA 101。抄下来，不要创建",
          "en": "siteReference: postcode plus house number, e.g. 1000AA 101. Copy it; do not create one.",
          "ja": "siteReference。郵便番号と番地、例 1000AA 101。コピーするだけで、作成しません"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 python-frank-energie。Frank Energie 没有公开的开发者 token 页。Client Secret 填客户门户登录密码，社区客户端用 GraphQL login mutation 换 authToken。",
        "en": "Open python-frank-energie. Frank Energie has no public developer token page. Put the customer-portal password in Client Secret. The community client exchanges it for an authToken with a GraphQL login mutation.",
        "ja": "python-frank-energie を開きます。Frank Energie に公開の開発者 token ページはありません。Client Secret には顧客ポータルのログインパスワードを入れます。コミュニティクライアントは GraphQL の login mutation で authToken に換えます。"
      },
      {
        "zh": "Account ID 是 siteReference，邮编加门牌，例如 1000AA 101。从客户门户或发票抄，不要创建。",
        "en": "Account ID is siteReference: postcode plus house number, for example 1000AA 101. Copy it from the customer portal or an invoice. Do not create one.",
        "ja": "Account ID は siteReference で、郵便番号と番地、たとえば 1000AA 101 です。顧客ポータルかインボイスからコピーし、作成しません。"
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
        "zh": "打开 Dilmune Portal，到 Settings → API Keys，点 Create API Key。钥匙以 dcs_ 开头，只显示一次。需要已开通账单。请求头是 Authorization: Bearer。",
        "en": "Open the Dilmune Portal, go to Settings → API Keys, and tap Create API Key. The key starts with dcs_ and is shown only once. Billing must already be active. The header is Authorization: Bearer.",
        "ja": "Dilmune Portal を開き、Settings → API Keys で Create API Key をタップします。鍵は dcs_ で始まり、一度だけ表示されます。請求アカウントが有効である必要があります。ヘッダは Authorization: Bearer です。"
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
    "credentialSetupURL": "https://cloud.dilmune.com/",
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
          "zh": "org_id，在 API Tokens 或 Organization Settings。抄下来，不要创建",
          "en": "org_id on API Tokens or Organization Settings. Copy it; do not create one.",
          "ja": "API Tokens または Organization Settings の org_id。コピーするだけで、作成しません"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Hubble 控制台 的 Developer Tools → API Tokens，起名并创建。只勾 read-billing-invoices，不要默认全权限。钥匙只显示一次。",
        "en": "Open Developer Tools → API Tokens in the Hubble dashboard, name the key, and create it. Check only read-billing-invoices; do not leave full admin scopes. The key is shown only once.",
        "ja": "Hubble ダッシュボード の Developer Tools → API Tokens を開き、名前を付けて作成します。read-billing-invoices だけをオンにし、全権限のままにしないでください。鍵は一度だけ表示されます。"
      },
      {
        "zh": "Account ID 是 org_id，同一页或 Organization Settings 能看到。抄下来，不要创建。",
        "en": "Account ID is org_id. It is on the same page or under Organization Settings. Copy it; do not create one.",
        "ja": "Account ID は org_id です。同じページか Organization Settings にあります。コピーするだけで、作成しません。"
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
          "zh": "这把钥匙缺 read-billing-invoices，读不到发票。",
          "en": "This key is missing read-billing-invoices, so it cannot read invoices.",
          "ja": "この鍵に read-billing-invoices がないため、インボイスを読めません。"
        },
        "nextStep": {
          "zh": "回 Developer Tools → API Tokens 重建一把，只勾 read-billing-invoices。",
          "en": "Go back to Developer Tools → API Tokens and recreate it with only read-billing-invoices.",
          "ja": "Developer Tools → API Tokens に戻り、read-billing-invoices だけをオンにして作り直してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://hubble.com/",
    "credentialSetupURL": "https://dash.hubble.com/developer/api-tokens",
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
        "zh": "打开 Files.com 控制台，顶部搜索 API Keys，进 API Keys 页。需要站点管理员。",
        "en": "Open the Files.com dashboard, search for API Keys at the top, and open that page. You need to be a site administrator.",
        "ja": "Files.com ダッシュボードを開き、上部で API Keys を検索してそのページに入ります。サイト管理者が必要です。"
      },
      {
        "zh": "权限选 Full，不要选 Files Only（Files Only 不能读账单）。创建后立刻复制，只显示一次。",
        "en": "Set the permission scope to Full, not Files Only — Files Only cannot read billing. Copy the key right away; it’s shown only once.",
        "ja": "権限は Full にし、Files Only は選ばないでください。Files Only では請求を読めません。キーは一度しか出ないので、すぐにコピーします。"
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
    "credentialSetupURL": "https://www.files.com/docs/clients-and-protocols/sdk-and-apis/api-keys",
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
        "zh": "打开 DoiT 控制台，点右上角头像再点自己的名字，进 API 页，点 Create API token。",
        "en": "Open the DoiT console, tap your avatar then your name, open the API tab, and tap Create API token.",
        "ja": "DoiT コンソールを開き、右上のアバターから自分の名前を選び、API タブで Create API token をタップします。"
      },
      {
        "zh": "个人脚本用 Personal API token。创建后立刻复制。权限跟你当前角色走，读发票需要账单权限。",
        "en": "Use a Personal API token for your own scripts. Copy it right away. It inherits your current role; reading invoices needs billing permission.",
        "ja": "自分用のスクリプトなら Personal API token を使います。すぐにコピーしてください。権限は今の役割に従い、請求書を読むには請求権限が必要です。"
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
    "credentialSetupURL": "https://app.doit.com/profile/api",
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
        "zh": "打开 Timeweb Cloud 控制台的 API 和 Terraform 页，点添加令牌。",
        "en": "Open API and Terraform in the Timeweb Cloud dashboard, then tap Add token.",
        "ja": "Timeweb Cloud ダッシュボードの API と Terraform を開き、トークンを追加します。"
      },
      {
        "zh": "填名称，期限可选永久。主账号可勾有限权限。点发行后立刻复制，只显示一次。",
        "en": "Give it a name. Expiry can be never. The main user can limit which services it reaches. Tap Issue, then copy it right away — it won’t be shown again.",
        "ja": "名前を付け、期限は無期限でも構いません。メインユーザーなら権限を絞れます。発行したらすぐコピーしてください。再表示できません。"
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
    "credentialSetupURL": "https://timeweb.cloud/my/api-keys",
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
        "zh": "打开 Cloudheed 认证文档，按 API Keys 一节签发一把长期 API Key。不要用登录接口返回的 1 小时 JWT。",
        "en": "Open the Cloudheed authentication docs and, under API Keys, issue a long-lived API Key. Don’t use the one-hour JWT returned by login.",
        "ja": "Cloudheed の認証ドキュメントを開き、API Keys の節で長期の API Key を発行します。ログインが返す 1 時間の JWT は使わないでください。"
      },
      {
        "zh": "scopes 勾 billing:read。创建后立刻复制，完整 key 只显示一次。",
        "en": "Check the billing:read scope. Copy the key right after creating it — the full key is shown only once.",
        "ja": "scopes は billing:read にチェック。作成したらすぐにコピーします。完全な key は一度しか表示されません。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把 API Key 无效，或者你贴的是已过期的 JWT。",
          "en": "This API Key is invalid, or you pasted an expired JWT.",
          "ja": "この API Key は無効か、期限切れの JWT を貼っています。"
        },
        "nextStep": {
          "zh": "回认证文档按 API Keys 重开一把长期 key，创建后立刻复制。",
          "en": "Go back to the authentication docs, issue a new long-lived API Key, and copy it right away.",
          "ja": "認証ドキュメントに戻り、長期の API Key を作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 key 没有 billing:read，所以读不到用量。",
          "en": "This key doesn’t have billing:read, so it can’t read usage.",
          "ja": "この key に billing:read がないため、用量を読めません。"
        },
        "nextStep": {
          "zh": "回上一步重建一把，scopes 只勾 billing:read。",
          "en": "Go back a step and recreate it with only the billing:read scope.",
          "ja": "前の手順に戻り、scopes は billing:read だけにして作り直してください。"
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
      "zh": "这个数字应该和后台本周期用量花费一致。",
      "en": "This number should match this period’s usage spend in the dashboard.",
      "ja": "この数字はダッシュボードの今期の用量支出と一致するはずです。"
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
        "zh": "打开 Sevalla 控制台，进 Integration → API keys，点 Create API key。",
        "en": "Open the Sevalla dashboard, go to Integration → API keys, then tap Create API key.",
        "ja": "Sevalla ダッシュボードを開き、Integration → API keys に入り、Create API key をタップします。"
      },
      {
        "zh": "可选预定义角色或自定义权限。创建后立刻复制，完整 key 只显示一次。",
        "en": "Pick a predefined role or custom capabilities. Copy the key right after creating it — the full key is shown only once.",
        "ja": "定義済みロールかカスタム権限を選べます。作成したらすぐにコピーします。完全な key は一度しか表示されません。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把 API key 无效，或者已经被删除。",
          "en": "This API key is invalid, or it has already been deleted.",
          "ja": "この API key は無効か、すでに削除されています。"
        },
        "nextStep": {
          "zh": "回 Integration → API keys 重开一把，创建后立刻复制。",
          "en": "Go back to Integration → API keys, create a new one, and copy it right away.",
          "ja": "Integration → API keys に戻って作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 key 的角色或自定义权限读不到公司用量。",
          "en": "This key’s role or custom capabilities can’t read company usage.",
          "ja": "この key のロールまたはカスタム権限では会社の用量を読めません。"
        },
        "nextStep": {
          "zh": "回上一步重建一把，自定义权限给公司用量只读。",
          "en": "Go back a step and recreate it with read-only company usage access.",
          "ja": "前の手順に戻り、会社の用量を読み取り専用にして作り直してください。"
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
      "zh": "这个数字应该和公司设置里 Usage 本周期花费一致。",
      "en": "This number should match this period’s spend on Usage in company settings.",
      "ja": "この数字は会社設定の Usage の今期支出と一致するはずです。"
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
        "isSecret": true,
        "hint": {
          "zh": "若走 HTTP Basic，填客户区密码",
          "en": "Account password if this portal uses HTTP Basic",
          "ja": "HTTP Basic のときはクライアントエリアのパスワード"
        }
      },
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true,
        "hint": {
          "zh": "POST /api/login 返回的 JWT",
          "en": "JWT returned by POST /api/login",
          "ja": "POST /api/login が返す JWT"
        }
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
          "zh": "客户区登录邮箱",
          "en": "Client-area login email",
          "ja": "クライアントエリアのログインメール"
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
          "zh": "User Details 里的数字 id，复制即可",
          "en": "Numeric id from User Details. Copy it; do not create one.",
          "ja": "User Details の数字 id。コピーするだけで、新規作成しません。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 CatalystVM 的 User API 说明。认证是 JWT：用客户区邮箱和密码 POST /api/login，把返回的 token 填进 API Token。",
        "en": "Open the CatalystVM User API docs. Auth is JWT: POST /api/login with your client-area email and password, then paste the returned token as API Token.",
        "ja": "CatalystVM の User API 説明を開きます。認証は JWT で、クライアントエリアのメールとパスワードで POST /api/login し、返ってきた token を API Token にします。"
      },
      {
        "zh": "若该门户开了 HTTP Basic，客户区密码填进 Client Secret。不要凭空「创建」一把 Client Secret。",
        "en": "If this portal enables HTTP Basic, put the client-area password in Client Secret. Do not invent a Client Secret.",
        "ja": "このポータルが HTTP Basic を開いていれば、クライアントエリアのパスワードを Client Secret に入れます。Client Secret を勝手に「作成」しないでください。"
      },
      {
        "zh": "Email 是客户区登录邮箱，username 就是它，不要去创建。Client ID 是 User Details（GET /api/details）里的数字 id，复制即可。",
        "en": "Email is your client-area login email (the username). Do not create it. Client ID is the numeric id in User Details (GET /api/details); copy it.",
        "ja": "Email はクライアントエリアのログインメールで、username そのものです。作成しません。Client ID は User Details（GET /api/details）の数字 id をコピーします。"
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
          "zh": "这组登录读不到发票。",
          "en": "This login cannot read invoices.",
          "ja": "このログインではインボイスを読めません。"
        },
        "nextStep": {
          "zh": "回上一步用主账户邮箱重新换 JWT，不要用没有账单权限的联系人。",
          "en": "Go back a step and exchange a JWT with the main-account email, not a contact without billing access.",
          "ja": "前の手順に戻り、請求権限の無い連絡先ではなく本口座のメールで JWT を取り直してください。"
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
      "zh": "这个数字应该和后台本月发票一致，不是账户余额。",
      "en": "This number should match this month’s invoices, not account credit.",
      "ja": "この数字は今月のインボイスと一致するはずで、口座残高ではありません。"
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
        "isSecret": true,
        "hint": {
          "zh": "若走 HTTP Basic，填客户区密码",
          "en": "Account password if this portal uses HTTP Basic",
          "ja": "HTTP Basic のときはクライアントエリアのパスワード"
        }
      },
      {
        "key": "apiToken",
        "label": {
          "zh": "API Token",
          "en": "API Token",
          "ja": "API Token"
        },
        "isSecret": true,
        "hint": {
          "zh": "POST /api/login 返回的 JWT",
          "en": "JWT returned by POST /api/login",
          "ja": "POST /api/login が返す JWT"
        }
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
          "zh": "客户区登录邮箱",
          "en": "Client-area login email",
          "ja": "クライアントエリアのログインメール"
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
          "zh": "User Details 里的数字 id，复制即可",
          "en": "Numeric id from User Details. Copy it; do not create one.",
          "ja": "User Details の数字 id。コピーするだけで、新規作成しません。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Oxahost 的 User API 说明。认证是 JWT：用客户区邮箱和密码 POST /api/login，把返回的 token 填进 API Token。",
        "en": "Open the Oxahost User API docs. Auth is JWT: POST /api/login with your client-area email and password, then paste the returned token as API Token.",
        "ja": "Oxahost の User API 説明を開きます。認証は JWT で、クライアントエリアのメールとパスワードで POST /api/login し、返ってきた token を API Token にします。"
      },
      {
        "zh": "若该门户开了 HTTP Basic，客户区密码填进 Client Secret。不要凭空「创建」一把 Client Secret。",
        "en": "If this portal enables HTTP Basic, put the client-area password in Client Secret. Do not invent a Client Secret.",
        "ja": "このポータルが HTTP Basic を開いていれば、クライアントエリアのパスワードを Client Secret に入れます。Client Secret を勝手に「作成」しないでください。"
      },
      {
        "zh": "Email 是客户区登录邮箱，username 就是它，不要去创建。Client ID 是 User Details（GET /api/details）里的数字 id，复制即可。",
        "en": "Email is your client-area login email (the username). Do not create it. Client ID is the numeric id in User Details (GET /api/details); copy it.",
        "ja": "Email はクライアントエリアのログインメールで、username そのものです。作成しません。Client ID は User Details（GET /api/details）の数字 id をコピーします。"
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
          "zh": "这组登录读不到发票。",
          "en": "This login cannot read invoices.",
          "ja": "このログインではインボイスを読めません。"
        },
        "nextStep": {
          "zh": "回上一步用主账户邮箱重新换 JWT，不要用没有账单权限的联系人。",
          "en": "Go back a step and exchange a JWT with the main-account email, not a contact without billing access.",
          "ja": "前の手順に戻り、請求権限の無い連絡先ではなく本口座のメールで JWT を取り直してください。"
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
      "en": "African and Francophone hosting. This month’s invoices, summed; not account credit.",
      "ja": "アフリカと仏語圏のホスティング。今月のインボイス合計で、口座残高は出しません。"
    },
    "verifyHint": {
      "zh": "这个数字应该和后台本月发票一致，不是账户余额。",
      "en": "This number should match this month’s invoices, not account credit.",
      "ja": "この数字は今月のインボイスと一致するはずで、口座残高ではありません。"
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
          "zh": "End Users 里的 end_user_id",
          "en": "end_user_id from End Users",
          "ja": "End Users の end_user_id"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Fiskil 控制台的 Settings > API Keys，创建一把 API key，勾所需 scopes。立刻复制 Client Secret，只显示一次。",
        "en": "Open Settings > API Keys in the Fiskil console, create an API key, and select the scopes you need. Copy the Client Secret right away — it won’t be shown again.",
        "ja": "Fiskil コンソールの Settings > API Keys を開き、API key を作って必要な scopes を選びます。Client Secret は再表示されないので、すぐにコピーします。"
      },
      {
        "zh": "打开 End Users，复制要记账的那个 end_user_id 填进 Account ID。不要创建 Account ID。",
        "en": "Open End Users and copy the end_user_id whose invoices you want into Account ID. Don’t create an Account ID.",
        "ja": "End Users を開き、請求を見たい end_user_id を Account ID にコピーします。Account ID は作らないでください。"
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
    "credentialSetupURL": "https://console.fiskil.com/data-api/settings/api-keys",
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
        "zh": "打开 3PLGuys 控制台的 Account Settings > API Keys。选组织，勾 invoices，可选过期时间。",
        "en": "Open Account Settings > API Keys in the 3PLGuys dashboard. Pick the organization, check invoices, and set an expiry if you want.",
        "ja": "3PLGuys ダッシュボードの Account Settings > API Keys を開きます。組織を選び、invoices にチェックし、必要なら期限を付けます。"
      },
      {
        "zh": "创建后立刻复制（3pl_ 开头），只显示一次。",
        "en": "Copy the key right away (it starts with 3pl_). It’s shown only once.",
        "ja": "作成したらすぐコピーします（3pl_ で始まります）。一度しか表示されません。"
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
          "zh": "公司 UUID，复制即可，不要去创建",
          "en": "Company UUID. Copy it; do not create one.",
          "ja": "会社の UUID。コピーするだけで、新規作成しません。"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Pleo Web App 的 API keys 页。需要 admin 或 bookkeeper，且这家必须已开通 Standalone API Keys；看不到入口就不要硬建。",
        "en": "Open API keys in the Pleo Web App. You must be an admin or bookkeeper, and Standalone API Keys must already be enabled for this company; if the page is missing, do not invent a key.",
        "ja": "Pleo Web App の API keys を開きます。admin または bookkeeper が必要で、この会社に Standalone API Keys が開いている必要があります。入口が無ければ無理に作らないでください。"
      },
      {
        "zh": "点 Create API Key。填 Name 和 Expiration，Access level 选对应公司。权限勾 accounting-entries:read。点 Create API Key，立刻复制；关掉窗口就再也看不到，也不能 regenerate。",
        "en": "Tap Create API Key. Fill in Name and Expiration, and set Access level to the company. Tick accounting-entries:read. Tap Create API Key and copy it immediately; after you close the dialog you cannot see it again, and there is no regenerate.",
        "ja": "Create API Key をタップします。Name と Expiration を入れ、Access level はその会社にします。権限は accounting-entries:read を付けます。Create API Key をタップしたらすぐにコピー。閉じると二度と見えず、regenerate もありません。"
      },
      {
        "zh": "Account ID 就是 company_id，不是创建出来的。在公司资料里复制，或从员工列表响应里的 companyId 抄。请求必须带这个 UUID。",
        "en": "Account ID is company_id. It is not created. Copy it from company details, or from companyId in the employees list. Requests must include this UUID.",
        "ja": "Account ID は company_id で、作成するものではありません。会社情報、または従業員一覧の companyId からコピーします。リクエストにはこの UUID が必要です。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把 Standalone API Key 无效、过期，或还没开通。",
          "en": "This Standalone API Key is invalid, expired, or not enabled.",
          "ja": "この Standalone API Key は無効、期限切れ、または未開通です。"
        },
        "nextStep": {
          "zh": "回上一步重建一把。没有 regenerate，丢了只能新建。",
          "en": "Go back a step and create a new one. There is no regenerate; if you lost it, issue another.",
          "ja": "前の手順に戻って作り直してください。regenerate はなく、無くしたら新規発行です。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "缺 accounting-entries:read，或 company_id 对不上这把钥匙。",
          "en": "Missing accounting-entries:read, or company_id does not match this key.",
          "ja": "accounting-entries:read が無いか、company_id がこのキーと一致しません。"
        },
        "nextStep": {
          "zh": "回上一步按 accounting-entries:read 重建，并核对公司 UUID。",
          "en": "Go back a step, recreate with accounting-entries:read, and check the company UUID.",
          "ja": "前の手順に戻り、accounting-entries:read で作り直し、会社 UUID を確認してください。"
        },
        "httpStatus": 403
      }
    ],
    "plans": [],
    "notices": [],
    "guideURLs": [],
    "billingURL": "https://www.pleo.io/",
    "credentialSetupURL": "https://app.pleo.io/settings/api-keys",
    "summary": {
      "zh": "企业支出卡。这里只记平台开给你的发票，不含卡消费。",
      "en": "Corporate spend cards. This records Pleo’s invoices to you, not card spend.",
      "ja": "法人支出カード。Pleo があなたに出すインボイスだけで、カード利用額は含みません。"
    },
    "verifyHint": {
      "zh": "这个数字只含 Pleo 开给你的平台费发票，不含卡消费。对不上先别保存。",
      "en": "This number is only Pleo’s platform invoices to you, not card spend. If it does not match, do not save yet.",
      "ja": "この数字は Pleo があなたに出すプラットフォーム手数料のインボイスだけで、カード利用額は含みません。違うならまだ保存しないでください。"
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
          "zh": "控制台里形如 p-xxxxxxxx",
          "en": "Looks like p-xxxxxxxx in the dashboard",
          "ja": "ダッシュボードの p-xxxxxxxx 形式"
        }
      }
    ],
    "steps": [
      {
        "zh": "按 Cerebrium 签发说明，打开控制台的 API Keys 页面，点 Create Service Account，起名、选过期时间，点 Create。",
        "en": "Follow the Cerebrium token guide, open the API Keys page in the dashboard, tap Create Service Account, name it, pick an expiry, then tap Create.",
        "ja": "Cerebrium の発行手順に従い、ダッシュボードの API Keys ページを開き、Create Service Account をタップし、名前と有効期限を入れて Create します。"
      },
      {
        "zh": "立刻复制生成的 token，填到 Personal Access Token。完整 token 只显示一次。",
        "en": "Copy the generated token right away and paste it into Personal Access Token. The full token is shown only once.",
        "ja": "生成された token をすぐにコピーし、Personal Access Token に貼ります。完全な token は一度しか表示されません。"
      },
      {
        "zh": "在 Cerebrium 控制台复制当前项目的 Project ID（形如 p-xxxxxxxx）。不要新建项目。",
        "en": "In the Cerebrium dashboard, copy the current project’s Project ID (looks like p-xxxxxxxx). Don’t create a new project.",
        "ja": "Cerebrium ダッシュボードで、今のプロジェクトの Project ID（p-xxxxxxxx 形式）をコピーします。新しいプロジェクトは作らないでください。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这个 Service Account Token 无效，过期，或者已经被删除。",
          "en": "This Service Account Token is invalid, expired, or has already been deleted.",
          "ja": "この Service Account Token は無効か、期限切れか、すでに削除されています。"
        },
        "nextStep": {
          "zh": "回 API Keys 点 Create Service Account 重开一把，创建后立刻复制。",
          "en": "Go back to API Keys, tap Create Service Account, and copy the token right away.",
          "ja": "API Keys に戻り、Create Service Account で作り直し、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这个 token 读不到该项目的发票，或者 Project ID 填错了。",
          "en": "This token can’t read invoices for that project, or the Project ID is wrong.",
          "ja": "この token ではそのプロジェクトのインボイスを読めないか、Project ID が違います。"
        },
        "nextStep": {
          "zh": "确认 Project ID 是当前项目的 p-xxxxxxxx，并在该项目下重开一把 Service Account Token。",
          "en": "Confirm the Project ID is this project’s p-xxxxxxxx, and recreate a Service Account Token in that project.",
          "ja": "Project ID が今のプロジェクトの p-xxxxxxxx か確認し、そのプロジェクトで Service Account Token を作り直してください。"
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
      "zh": "这个数字应该和该项目本月发票应付合计一致。",
      "en": "This number should match this month’s invoices due for that project.",
      "ja": "この数字はそのプロジェクトの今月のインボイス支払い合計と一致するはずです。"
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
          "zh": "API User，不是登录邮箱",
          "en": "API User, not the sign-in email",
          "ja": "ログイン用メールではなく API User"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Shipmondo 的 API 访问页（Settings → Integrations → API），点创建 API keys。立刻复制 API Key。",
        "en": "Open Shipmondo’s API access page (Settings → Integrations → API) and create API keys. Copy the API Key right away.",
        "ja": "Shipmondo の API アクセスページ（Settings → Integrations → API）を開き、API keys を作成します。API Key はすぐにコピーしてください。"
      },
      {
        "zh": "同一页复制 API User，填到 Email。这是接口用户名，不是登录邮箱，不要另建一把。",
        "en": "On the same page, copy API User and paste it into Email. That’s the API username, not your sign-in email. Don’t create a new one.",
        "ja": "同じページで API User をコピーし、Email に貼ります。これは API のユーザー名で、ログイン用メールではありません。新しく作らないでください。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "API User 或 API Key 不对，或者这把 key 已被停用。",
          "en": "API User or API Key is wrong, or this key has been deactivated.",
          "ja": "API User または API Key が違うか、この key は停止されています。"
        },
        "nextStep": {
          "zh": "回 API 访问页确认 Email 填的是 API User，不是登录邮箱；必要时重开一把 API Key。",
          "en": "Go back to API access and confirm Email is the API User, not the sign-in email. Create a new API Key if needed.",
          "ja": "API アクセスに戻り、Email がログイン用メールではなく API User か確認してください。必要なら API Key を作り直します。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把 API key 没有读流水的权限。",
          "en": "This API key doesn’t have permission to read the ledger.",
          "ja": "この API key に明細を読む権限がありません。"
        },
        "nextStep": {
          "zh": "回 API 访问页确认这把 key 已激活。",
          "en": "Go back to API access and confirm this key is active.",
          "ja": "API アクセスに戻り、この key が有効か確認してください。"
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
      "zh": "这个数字应该和账户流水里的发货扣费一致，充值不算。",
      "en": "This number should match ledger shipping charges. Top-ups are skipped.",
      "ja": "この数字は口座明細の発送引き落としと一致するはずです。チャージは数えません。"
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
        "isSecret": true,
        "hint": {
          "zh": "Public Key",
          "en": "Public Key",
          "ja": "Public Key"
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
        "hint": {
          "zh": "Secret Key",
          "en": "Secret Key",
          "ja": "Secret Key"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Sendcloud 的 Integrations，找到 Sendcloud API，点 Connect。起名后 Save。",
        "en": "Open Sendcloud Integrations, find Sendcloud API, and tap Connect. Name it, then tap Save.",
        "ja": "Sendcloud の Integrations を開き、Sendcloud API を見つけて Connect をタップします。名前を入れて Save します。"
      },
      {
        "zh": "Public Key 填到 API Key，Secret Key 填到 Client Secret。关掉页面后看不到，立刻复制。",
        "en": "Paste Public Key into API Key and Secret Key into Client Secret. They’re hidden after you leave the page — copy them right away.",
        "ja": "Public Key を API Key に、Secret Key を Client Secret に貼ります。ページを閉じると見えなくなるので、すぐにコピーしてください。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "Public Key 或 Secret Key 不对，或者两把填反了。",
          "en": "Public Key or Secret Key is wrong, or the two are swapped.",
          "ja": "Public Key または Secret Key が違うか、入れ違えています。"
        },
        "nextStep": {
          "zh": "回 Integrations 的 Sendcloud API，必要时点 Regenerate keys，Public Key 填 API Key，Secret Key 填 Client Secret。",
          "en": "Go back to Sendcloud API under Integrations. Regenerate keys if needed. Public Key goes in API Key; Secret Key goes in Client Secret.",
          "ja": "Integrations の Sendcloud API に戻ってください。必要なら Regenerate keys。Public Key は API Key、Secret Key は Client Secret です。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把集成读不到发票。",
          "en": "This integration can’t read invoices.",
          "ja": "この連携ではインボイスを読めません。"
        },
        "nextStep": {
          "zh": "回 Integrations 确认 Sendcloud API 仍处于已连接。",
          "en": "Go back to Integrations and confirm Sendcloud API is still connected.",
          "ja": "Integrations に戻り、Sendcloud API がまだ接続中か確認してください。"
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
      "zh": "这个数字应该和后台本月发票合计（含税）一致。",
      "en": "This number should match this month’s invoices in the dashboard, tax included.",
      "ja": "この数字はダッシュボードの今月のインボイス合計（税込）と一致するはずです。"
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
        "key": "accessKeyID",
        "label": {
          "zh": "Access Key ID",
          "en": "Access Key ID",
          "ja": "Access Key ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "RAM 用户的 AccessKey ID",
          "en": "RAM user’s AccessKey ID",
          "ja": "RAM ユーザーの AccessKey ID"
        }
      },
      {
        "key": "secretAccessKey",
        "label": {
          "zh": "Secret Access Key",
          "en": "Secret Access Key",
          "ja": "Secret Access Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开 RAM 控制台，单独建一个只给这个 App 用的 RAM 用户。不要用主账号 AccessKey。",
        "en": "Open the RAM console and create a RAM user just for this app. Don’t use the Alibaba Cloud account AccessKey.",
        "ja": "RAM コンソールを開き、この App 専用の RAM ユーザーを作ります。主アカウントの AccessKey は使わないでください。"
      },
      {
        "zh": "给这个用户贴系统策略 AliyunBSSReadOnlyAccess。",
        "en": "Attach the AliyunBSSReadOnlyAccess system policy to this user.",
        "ja": "このユーザーにシステムポリシー AliyunBSSReadOnlyAccess を付けます。"
      },
      {
        "zh": "打开该用户的凭证管理，点创建 AccessKey。AccessKey ID 和 AccessKey Secret 一起复制。Secret 只显示一次。",
        "en": "Open that user’s credentials, tap Create AccessKey, and copy the AccessKey ID and AccessKey Secret together. The Secret is shown only once.",
        "ja": "そのユーザーの認証情報を開き、AccessKey の作成をタップします。AccessKey ID と AccessKey Secret を一緒にコピーします。Secret は一度しか表示されません。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把 AccessKey 无效，或者已经被停用。",
          "en": "This AccessKey is invalid, or it has already been disabled.",
          "ja": "この AccessKey は無効か、すでに停止されています。"
        },
        "nextStep": {
          "zh": "回该 RAM 用户的凭证管理，停掉旧钥匙，重新创建 AccessKey。Secret 创建后立刻复制。",
          "en": "Go back to that RAM user’s credentials, disable the old keys, and create a new AccessKey. Copy the Secret right away.",
          "ja": "その RAM ユーザーの認証情報に戻り、古いキーを止めて AccessKey を作り直してください。Secret は作成したらすぐにコピーします。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把钥匙没有 AliyunBSSReadOnlyAccess，所以读不到账单总览。",
          "en": "These keys don’t have AliyunBSSReadOnlyAccess, so they can’t read the bill overview.",
          "ja": "このキーに AliyunBSSReadOnlyAccess がないため、請求概要を読めません。"
        },
        "nextStep": {
          "zh": "给这个 RAM 用户贴系统策略 AliyunBSSReadOnlyAccess。",
          "en": "Attach the AliyunBSSReadOnlyAccess system policy to this RAM user.",
          "ja": "この RAM ユーザーにシステムポリシー AliyunBSSReadOnlyAccess を付けてください。"
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
      "zh": "这个数字应该和费用中心账单总览的税前金额一致。人民币会折成美元。",
      "en": "This number should match the pretax amount on the Expenses bill overview. CNY converts to USD.",
      "ja": "この数字は費用センター請求概要の税引前金額と一致するはずです。人民元はドルに換算します。"
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
        "key": "accessKeyID",
        "label": {
          "zh": "Access Key ID",
          "en": "Access Key ID",
          "ja": "Access Key ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "IAM 访问密钥 ID",
          "en": "IAM Access Key ID",
          "ja": "IAM の Access Key ID"
        }
      },
      {
        "key": "secretAccessKey",
        "label": {
          "zh": "Secret Access Key",
          "en": "Secret Access Key",
          "ja": "Secret Access Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开火山引擎访问控制，左侧选资源管理 → 密钥管理。建议给 IAM 用户建密钥，不要用主账号。",
        "en": "Open Volcengine Access Control and, on the left, choose Resource management → Key management. Create keys for an IAM user. Don’t use the root account.",
        "ja": "Volcengine のアクセス制御を開き、左でリソース管理 → キー管理を選びます。IAM ユーザーにキーを作ります。主アカウントは使わないでください。"
      },
      {
        "zh": "给该 IAM 用户授予费用中心账单查询权限，再点新建密钥。Access Key ID 和 Secret Access Key 一起复制。Secret 只显示一次。",
        "en": "Grant this IAM user billing-query access in Billing Center, then tap Create key. Copy the Access Key ID and Secret Access Key together. The Secret is shown only once.",
        "ja": "この IAM ユーザーに費用センターの請求照会権限を付け、キーの新規作成をタップします。Access Key ID と Secret Access Key を一緒にコピーします。Secret は一度しか表示されません。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把访问密钥无效，或者已经被停用。",
          "en": "These access keys are invalid, or they’ve already been disabled.",
          "ja": "このアクセスキーは無効か、すでに停止されています。"
        },
        "nextStep": {
          "zh": "回密钥管理停掉旧钥匙，点新建密钥。Secret 创建后立刻复制。",
          "en": "Go back to Key management, disable the old keys, and tap Create key. Copy the Secret right away.",
          "ja": "キー管理に戻り、古いキーを止めて新規作成してください。Secret は作成したらすぐにコピーします。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把钥匙没有费用中心账单查询权限。",
          "en": "These keys don’t have Billing Center query permission.",
          "ja": "このキーに費用センターの請求照会権限がありません。"
        },
        "nextStep": {
          "zh": "给这个 IAM 用户授予费用中心账单查询权限后再试。",
          "en": "Grant this IAM user billing-query access in Billing Center, then try again.",
          "ja": "この IAM ユーザーに費用センターの請求照会権限を付けてから、もう一度試してください。"
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
      "zh": "这个数字应该和费用中心账单明细的应付金额一致。人民币会折成美元。",
      "en": "This number should match the payable amount on Billing Center bill details. CNY converts to USD.",
      "ja": "この数字は費用センター請求明細の支払額と一致するはずです。人民元はドルに換算します。"
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
        "key": "accessKeyID",
        "label": {
          "zh": "Access Key ID",
          "en": "Access Key ID",
          "ja": "Access Key ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "IAM 子用户的 AccessKey ID",
          "en": "IAM sub-user AccessKey ID",
          "ja": "IAM サブユーザーの AccessKey ID"
        }
      },
      {
        "key": "secretAccessKey",
        "label": {
          "zh": "Secret Access Key",
          "en": "Secret Access Key",
          "ja": "Secret Access Key"
        },
        "isSecret": true
      }
    ],
    "steps": [
      {
        "zh": "打开金山云访问控制。建议给 IAM 子用户建访问密钥，不要用主账号。",
        "en": "Open Kingsoft Cloud Access Control. Create access keys for an IAM sub-user. Don’t use the root account.",
        "ja": "Kingsoft Cloud のアクセス制御を開きます。IAM サブユーザーにアクセスキーを作ります。主アカウントは使わないでください。"
      },
      {
        "zh": "人员管理 → 子用户 → 用户详情 → 安全管理，点创建秘钥。AccessKey ID 和 SecretAccessKey 一起复制。Secret 只显示一次。",
        "en": "Go to People management → Sub-users → user details → Security, then tap Create key. Copy the AccessKey ID and SecretAccessKey together. The Secret is shown only once.",
        "ja": "人員管理 → サブユーザー → ユーザー詳細 → セキュリティ管理で、キー作成をタップします。AccessKey ID と SecretAccessKey を一緒にコピーします。Secret は一度しか表示されません。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把访问密钥无效，或者已经被停用。",
          "en": "These access keys are invalid, or they’ve already been disabled.",
          "ja": "このアクセスキーは無効か、すでに停止されています。"
        },
        "nextStep": {
          "zh": "回该子用户的安全管理，停掉旧钥匙，再点创建秘钥。Secret 创建后立刻复制。",
          "en": "Go back to that sub-user’s Security, disable the old keys, and tap Create key. Copy the Secret right away.",
          "ja": "そのサブユーザーのセキュリティ管理に戻り、古いキーを止めてキー作成してください。Secret は作成したらすぐにコピーします。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把钥匙没有读账单汇总的权限。",
          "en": "These keys don’t have permission to read the bill summary.",
          "ja": "このキーに請求集計を読む権限がありません。"
        },
        "nextStep": {
          "zh": "给这个 IAM 子用户授予费用中心账单查询权限后再试。",
          "en": "Grant this IAM sub-user billing-query access, then try again.",
          "ja": "この IAM サブユーザーに費用センターの請求照会権限を付けてから、もう一度試してください。"
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
      "zh": "这个数字应该和费用中心按产品线汇总的账单一致。人民币会折成美元。",
      "en": "This number should match the product-line bill summary in Billing. CNY converts to USD.",
      "ja": "この数字は費用センターの製品ライン別請求集計と一致するはずです。人民元はドルに換算します。"
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
        "key": "accessKeyID",
        "label": {
          "zh": "Access Key ID",
          "en": "Access Key ID",
          "ja": "Access Key ID"
        },
        "isSecret": false,
        "hint": {
          "zh": "CAM 的 SecretId",
          "en": "CAM SecretId",
          "ja": "CAM の SecretId"
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
        "hint": {
          "zh": "CAM 的 SecretKey",
          "en": "CAM SecretKey",
          "ja": "CAM の SecretKey"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开访问管理，单独建一个子用户。不要用主账号密钥。",
        "en": "Open CAM and create a sub-user just for this app. Don’t use the root-account keys.",
        "ja": "アクセス管理を開き、この App 専用のサブユーザーを作ります。主アカウントのキーは使わないでください。"
      },
      {
        "zh": "给这个用户贴 QcloudFinanceBillReadOnlyAccess。",
        "en": "Attach QcloudFinanceBillReadOnlyAccess to this user.",
        "ja": "このユーザーに QcloudFinanceBillReadOnlyAccess を付けます。"
      },
      {
        "zh": "打开该用户详情的 API 密钥，点新建密钥。SecretId 填到 Access Key ID，SecretKey 填到 Secret Access Key。SecretKey 只在创建时显示。",
        "en": "Open API Keys on that user’s details and tap Create key. Paste SecretId into Access Key ID and SecretKey into Secret Access Key. SecretKey is shown only at creation.",
        "ja": "そのユーザー詳細の API キーを開き、キーの新規作成をタップします。SecretId を Access Key ID に、SecretKey を Secret Access Key に貼ります。SecretKey は作成時だけ表示されます。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这把 API 密钥无效，或者已经被停用。",
          "en": "These API keys are invalid, or they’ve already been disabled.",
          "ja": "この API キーは無効か、すでに停止されています。"
        },
        "nextStep": {
          "zh": "回该子用户的 API 密钥，停掉旧钥匙，再点新建密钥。SecretKey 创建后立刻复制。",
          "en": "Go back to that sub-user’s API Keys, disable the old keys, and tap Create key. Copy SecretKey right away.",
          "ja": "そのサブユーザーの API キーに戻り、古いキーを止めて新規作成してください。SecretKey は作成したらすぐにコピーします。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这把钥匙没有 QcloudFinanceBillReadOnlyAccess，所以读不到账单明细。",
          "en": "These keys don’t have QcloudFinanceBillReadOnlyAccess, so they can’t read bill details.",
          "ja": "このキーに QcloudFinanceBillReadOnlyAccess がないため、請求明細を読めません。"
        },
        "nextStep": {
          "zh": "给这个子用户贴 QcloudFinanceBillReadOnlyAccess。",
          "en": "Attach QcloudFinanceBillReadOnlyAccess to this sub-user.",
          "ja": "このサブユーザーに QcloudFinanceBillReadOnlyAccess を付けてください。"
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
      "zh": "这个数字应该和费用中心账单明细的实付金额一致。人民币会折成美元。",
      "en": "This number should match the actual cost on Billing Center bill details. CNY converts to USD.",
      "ja": "この数字は費用センター請求明細の実コストと一致するはずです。人民元はドルに換算します。"
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
          "zh": "地址栏 organization/ 后面的数字",
          "en": "The number after organization/ in the URL",
          "ja": "URL の organization/ の後ろの数字"
        }
      }
    ],
    "steps": [
      {
        "zh": "打开 Make，点左下角头像 → Profile → API，点 Add token。这是个人资料里的 API token，不是场景模块里的连接。",
        "en": "Open Make, tap your avatar at the bottom left → Profile → API, then tap Add token. This is the Profile API token, not a scenario-module connection.",
        "ja": "Make を開き、左下のアバター → Profile → API で Add token をタップします。これはプロフィールの API token で、シナリオモジュールの接続ではありません。"
      },
      {
        "zh": "起 Label，Scopes 勾 organizations:read。点 Save，立刻复制。多区要分别签发。",
        "en": "Set a Label and check the organizations:read scope. Tap Save and copy the token right away. Issue a separate token for each zone.",
        "ja": "Label を入れ、Scopes は organizations:read にチェック。Save をタップし、すぐにコピーします。ゾーンごとに別の token が必要です。"
      },
      {
        "zh": "登录后看地址栏 organization/ 后面的数字，复制成 Account ID。这是 organizationId，不要新建。",
        "en": "After signing in, copy the number after organization/ in the address bar into Account ID. That’s the organizationId — don’t create a new one.",
        "ja": "ログイン後、アドレスバーの organization/ の後ろの数字を Account ID にコピーします。これが organizationId です。新しく作らないでください。"
      }
    ],
    "troubleshooting": [
      {
        "explanation": {
          "zh": "这个 API token 无效，或者已经被撤销。",
          "en": "This API token is invalid, or it has already been revoked.",
          "ja": "この API token は無効か、すでに取り消されています。"
        },
        "nextStep": {
          "zh": "回 Profile → API 点 Add token 重开一把，Scopes 勾 organizations:read，创建后立刻复制。",
          "en": "Go back to Profile → API, tap Add token, check organizations:read, and copy it right away.",
          "ja": "Profile → API に戻り、Add token で作り直し、Scopes は organizations:read、作成したらすぐにコピーしてください。"
        },
        "httpStatus": 401
      },
      {
        "explanation": {
          "zh": "这个 token 缺 organizations:read，或者当前套餐不能调用 Make API。",
          "en": "This token is missing organizations:read, or the current plan can’t call the Make API.",
          "ja": "この token に organizations:read がないか、今のプランでは Make API を呼べません。"
        },
        "nextStep": {
          "zh": "回 Profile → API 重建一把，只勾 organizations:read。Make API 需要 Core 及以上套餐。",
          "en": "Go back to Profile → API and recreate it with only organizations:read. The Make API needs Core or above.",
          "ja": "Profile → API に戻り、organizations:read だけにして作り直してください。Make API は Core 以上のプランが必要です。"
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
      "zh": "这个数字应该和该组织本月付款合计一致。",
      "en": "This number should match this month’s organization payments.",
      "ja": "この数字はその組織の今月の支払い合計と一致するはずです。"
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
