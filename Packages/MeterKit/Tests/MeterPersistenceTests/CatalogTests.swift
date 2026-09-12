import Foundation
import Testing
import MeterCore
@testable import MeterPersistence

struct CatalogTests {
    @Test("打包目录能解析，Cloudflare / OpenAI 是完整向导")
    func bundledCatalogParses() async throws {
        let catalog = try await BundledCatalogSource().load()

        #expect(catalog.schemaVersion == CatalogCodec.supportedSchemaVersion)
        #expect(catalog.guides.count >= 84)

        let cloudflare = try #require(catalog.guides[.cloudflare])
        #expect(cloudflare.summary.contains("CDN"))
        #expect(cloudflare.needsLine == "API Token · Account ID")
        #expect(cloudflare.parts.count == 2)
        #expect(cloudflare.parts[0].fields.map(\.key) == ["apiToken"])
        #expect(cloudflare.parts[1].fields.map(\.key) == ["accountID"])
        #expect(cloudflare.steps[0].linkPhrases == ["Cloudflare 控制台"])
        #expect(cloudflare.steps[0].linkTarget.isEmpty)
        let accountStep = try #require(cloudflare.parts[1].steps.first)
        #expect(accountStep.text == "请查阅 查找 Account ID")
        #expect(accountStep.linkPhrases == ["查找 Account ID"])
        #expect(accountStep.linkTarget == "findAccountAndZoneIDs")
        #expect(cloudflare.steps.contains { $0.text.contains("Account · Billing · Read") })
        #expect(cloudflare.steps.allSatisfy { $0.copyable == nil })
        #expect(Set(cloudflare.fields.map(\.key)) == ["apiToken", "accountID"])
        let accountID = try #require(cloudflare.fields.first { $0.key == "accountID" })
        #expect(accountID.validation?.exactLength == 32)
        #expect(accountID.validation?.allowedCharacters == "0123456789abcdefABCDEF")
        #expect(accountID.validation?.message == "Account ID 应该是 32 位十六进制")
        #expect(Set(cloudflare.troubleshooting.map(\.httpStatus)) == [401, 403])
        #expect(cloudflare.troubleshooting.contains { $0.httpStatus == 403 && $0.nextStep.contains("Billing") })
        #expect(!cloudflare.verifyHint.isEmpty)

        let openai = try #require(catalog.guides[.openai])
        #expect(openai.steps.contains { $0.text.contains("Admin Key") })
        #expect(openai.steps.contains { $0.text.contains("Read only") })
        #expect(openai.fields.contains { $0.key == "apiKey" && $0.label.contains("Admin") })
        let adminKey = try #require(openai.fields.first { $0.key == "apiKey" })
        #expect(adminKey.validation?.prefix == "sk-admin-")
        #expect(adminKey.validation?.message.contains("sk-admin-") == true)
        #expect(adminKey.hint?.contains("Read only") == true)
        #expect(Set(openai.troubleshooting.map(\.httpStatus)) == [401, 403])
        #expect(openai.troubleshooting.contains { $0.explanation.contains("Admin Key") })
        #expect(openai.troubleshooting.contains { $0.httpStatus == 403 && $0.nextStep.contains("Read only") })

        let aws = try #require(catalog.guides[.aws])
        #expect(aws.steps.count == 3)
        #expect(aws.steps.contains { $0.copyable?.value.contains("ce:GetCostAndUsage") == true })
        #expect(Set(aws.fields.map(\.key)) == ["accessKeyID", "secretAccessKey"])
        let accessKey = try #require(aws.fields.first { $0.key == "accessKeyID" })
        #expect(accessKey.validation?.prefix == "AKIA")
        #expect(Set(aws.troubleshooting.map(\.httpStatus)) == [401, 403])
        #expect(aws.troubleshooting.contains { $0.explanation.contains("ce:GetCostAndUsage") })

        let neon = try #require(catalog.guides[.neon])
        #expect(neon.steps.count == 2)
        #expect(neon.fields.map(\.key) == ["apiKey"])
        #expect(neon.steps[0].text.contains("Settings"))
        #expect(neon.steps[0].text.contains("Create new API key"))
        #expect(neon.steps[1].text.contains("Org-wide"))
        #expect(neon.steps[1].text.contains("Key name"))
        #expect(!neon.steps[1].text.contains("不要选 Project-scoped"))
        #expect(neon.steps.contains { $0.text.contains("没有只读选项") })
        #expect(neon.steps.allSatisfy { !$0.text.contains("只给读权限") })
        #expect(neon.troubleshooting.contains { $0.httpStatus == 403 && $0.nextStep.contains("Org-wide") })
        #expect(!neon.verifyHint.isEmpty)

        let vercel = try #require(catalog.guides[.vercel])
        #expect(vercel.steps.count == 2)
        #expect(vercel.fields.map(\.key) == ["apiToken"])
        #expect(vercel.steps.contains { $0.text.contains("Expiration") })
        #expect(vercel.steps.contains { $0.text.contains("没有只读选项") })
        #expect(vercel.steps.contains { $0.text.contains("项目") })
        #expect(vercel.summary.contains("$0"))
        #expect(vercel.verifyHint.contains("$0"))
        #expect(vercel.troubleshooting.contains {
            $0.httpStatus == 403 && $0.nextStep.contains("项目")
        })

        let twilio = try #require(catalog.guides[.twilio])
        #expect(twilio.needsLine == "Account SID · API Key SID · API Key Secret")
        #expect(Set(twilio.fields.map(\.key)) == ["accountID", "accessKeyID", "apiToken"])
        #expect(twilio.parts[0].steps[0].linkTarget == "accountSettings")
        #expect(twilio.steps.contains { $0.text.contains("Restricted") && $0.text.contains("United States (US1)") })
        #expect(twilio.steps.contains { $0.text.contains("Billing") && $0.text.contains("usage") && $0.text.contains("Read") })
        #expect(twilio.steps.allSatisfy { !$0.text.contains("Auth Token") })
        let keySID = try #require(twilio.fields.first { $0.key == "accessKeyID" })
        #expect(keySID.validation?.prefix == "SK")
        #expect(keySID.validation?.exactLength == 34)
        #expect(twilio.troubleshooting.contains { $0.httpStatus == 403 && $0.nextStep.contains("usage") })

        let github = try #require(catalog.guides[.github])
        #expect(github.steps.count == 1)
        #expect(github.steps.contains {
            $0.text.contains("No expiration")
                && $0.text.contains("Public repositories")
                && $0.text.contains("Plan")
                && $0.text.contains("Read-only")
        })
        #expect(github.steps.allSatisfy { !$0.text.contains("Billing: Read") })
        let pat = try #require(github.fields.first { $0.key == "personalAccessToken" })
        #expect(pat.validation?.prefix == "github_pat_")
        #expect(github.steps.allSatisfy { $0.copyable == nil })
        #expect(github.troubleshooting.contains {
            $0.httpStatus == 403 && $0.nextStep.contains("Plan")
        })

        let openrouter = try #require(catalog.guides[.openrouter])
        #expect(openrouter.steps.count == 1)
        #expect(openrouter.steps[0].text.contains("Management key"))

        let fly = try #require(catalog.guides[.fly])
        #expect(fly.fields.isEmpty)
        #expect(fly.steps.contains { $0.text.contains("没有公开的账单接口") })
        for id: ProviderID in [.fly, .clerk, .render, .expo, .gcp, .slack, .notion, .figma, .supabase, .linear, .pulumi] {
            let inbox = try #require(catalog.guides[id])
            #expect(
                inbox.steps.allSatisfy { $0.copyable == nil },
                "\(id.rawValue) 连接参考不要单独渲染环境变量名"
            )
        }

        let cursor = try #require(catalog.guides[.cursor])
        #expect(cursor.fields.isEmpty)
        #expect(cursor.steps.contains { $0.text.contains("固定订阅") })
        #expect(cursor.steps.allSatisfy { $0.copyable == nil })

        let anthropic = try #require(catalog.guides[.anthropic])
        #expect(anthropic.steps.contains { $0.text.contains("Organization") })
        let admin = try #require(anthropic.fields.first { $0.key == "apiKey" })
        #expect(admin.label.contains("Admin"))
        #expect(admin.validation?.prefix == "sk-ant-")
        #expect(anthropic.troubleshooting.contains { $0.nextStep.contains("手工录入") })

        #expect(!catalog.plans.isEmpty)
        #expect(catalog.notices.contains { $0.id == "anthropic-needs-organization" })

        let copyOnlySteps: Set<String> = [
            "创建后立刻复制",
            "创建后立刻复制。",
            "创建后复制 token",
            "创建后复制 token。",
            "创建后复制。",
            "立刻复制。",
        ]
        let allowedCopyableLabels: Set<String> = ["IAM 策略"]
        for (id, guide) in catalog.guides {
            #expect(!guide.summary.isEmpty, "\(id.rawValue) 缺简介")
            for step in guide.steps {
                let text = step.text.trimmingCharacters(in: .whitespacesAndNewlines)
                #expect(
                    !copyOnlySteps.contains(text),
                    "\(id.rawValue) 不要把复制单独写成一步：\(step.text)"
                )
                if let copyable = step.copyable {
                    #expect(
                        allowedCopyableLabels.contains(copyable.label),
                        "\(id.rawValue) 连接参考不要单独渲染最小权限：\(copyable.label)"
                    )
                }
            }
        }
    }

    @Test("旧目录没有 summary 也能解")
    func guideWithoutSummaryDecodes() throws {
        let json = Data(#"{ "parts": [], "verifyHint": "", "troubleshooting": [] }"#.utf8)
        let guide = try JSONDecoder().decode(SetupGuide.self, from: json)
        #expect(guide.summary.isEmpty)
        #expect(guide.parts.isEmpty)
    }

    @Test("简介是这家自己的句子，不是类别定型文")
    func summariesAreSpecific() async throws {
        let catalog = try await BundledCatalogSource().load()
        let formulaSummaries: Set<String> = [
            "在线服务。按用量月底结算。",
            "在线服务。预充值，按用量扣余额。",
            "云主机与应用托管。按用量月底结算。",
            "托管数据库。按用量月底结算。",
            "模型推理 API。按用量月底结算。",
            "GPU 算力租用。按用量月底结算。",
            "CDN、DNS 或边缘网络。按用量月底结算。",
            "CDN、DNS 或边缘网络。预充值，按用量扣余额。",
            "短信、邮件或通讯。按用量月底结算。",
            "短信、邮件或通讯。预充值，按用量扣余额。",
            "监控与可观测性。按用量月底结算。",
            "监控与可观测性。预充值，按用量扣余额。",
            "对象存储。按用量月底结算。",
            "收款与计费。按用量月底结算。",
            "工作流自动化。按用量月底结算。",
            "协作工具。按用量月底结算。",
            "身份与安全。按用量月底结算。",
            "媒体处理与分发。按用量月底结算。",
            "开发平台。按用量月底结算。",
            "通信平台。预充值，账户币种余额会折成美元。",
            "云主机和托管数据库。按用量月底结算。",
            "短信、语音和通讯 API。按用量计。",
        ]
        let formulaEnglish: Set<String> = [
            "An online service. Billed by usage at month end.",
            "An online service. Prepaid. Usage debits the balance.",
            "Cloud hosting. Billed by usage at month end.",
            "A managed database. Billed by usage at month end.",
            "A model inference API. Billed by usage at month end.",
            "Rented GPU compute. Billed by usage at month end.",
            "CDN, DNS, or edge network. Billed by usage at month end.",
            "Messaging or communications. Billed by usage at month end.",
            "Monitoring and observability. Billed by usage at month end.",
            "Object storage. Billed by usage at month end.",
            "Payments and billing. Billed by usage at month end.",
            "Workflow automation. Billed by usage at month end.",
            "A communications platform. Prepaid. The account-currency balance converts to USD.",
            "Cloud hosts and managed databases. Billed by usage at month-end.",
        ]
        var summariesByText: [String: ProviderID] = [:]
        for (id, guide) in catalog.guides {
            #expect(
                !formulaSummaries.contains(guide.summary),
                "\(id.rawValue) 简介仍是类别定型文"
            )
            if let english = guide.en?.summary {
                #expect(
                    !formulaEnglish.contains(english),
                    "\(id.rawValue) 英文简介仍是类别定型文"
                )
            }
            if let other = summariesByText[guide.summary] {
                Issue.record("\(id.rawValue) 与 \(other.rawValue) 共用简介")
            } else {
                summariesByText[guide.summary] = id
            }
        }
    }

    @Test("超版本目录直接抛，谁都不许拿到一份「兜底」写进缓存")
    func decodeThrowsOnFutureSchema() {
        let json = """
        { "schemaVersion": 99, "updatedAt": "2026-08-16T00:00:00Z" }
        """.data(using: .utf8)!
        #expect(throws: CatalogError.unsupportedSchema) {
            _ = try CatalogCodec.decode(json)
        }
    }

    @Test("目录和 SetupGuide 都不带 URL / 端点字段")
    func catalogCarriesNoURLs() async throws {
        let catalog = try await BundledCatalogSource().load()
        assertNoURLShapedProperties(catalog)
        for guide in catalog.guides.values {
            assertNoURLShapedProperties(guide)
            for part in guide.parts {
                assertNoURLShapedProperties(part)
                for field in part.fields {
                    assertNoURLShapedProperties(field)
                }
                for step in part.steps {
                    assertNoURLShapedProperties(step)
                    if let copyable = step.copyable {
                        assertNoURLShapedProperties(copyable)
                    }
                }
            }
        }

        let jsonURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "Sources/MeterPersistence/Catalog/catalog.json")
        let text = try String(contentsOf: jsonURL, encoding: .utf8)
        #expect(!text.contains("http://"))
        #expect(!text.contains("https://"))
        #expect(!text.contains("consoleURL"))
        #expect(!text.contains("estimatedMinutes"))
        #expect(!text.contains("\"copyables\""))
    }

    @Test("可点片段是这句话里的字，不是 URL")
    func linkPhrasesAreSubstringsNotURLs() async throws {
        let catalog = try await BundledCatalogSource().load()
        var linkedGuides = 0
        for (id, guide) in catalog.guides {
            for step in guide.steps {
                for phrase in step.emphasized + step.linkPhrases {
                    #expect(
                        step.text.contains(phrase),
                        "\(id.rawValue) 找不到 \(phrase)"
                    )
                    #expect(!phrase.contains("://"), "\(id.rawValue) 的片段里出现了 URL")
                }
                #expect(!step.linkTarget.contains("://"), "\(id.rawValue) 的 linkTarget 里出现了 URL")
                if !step.linkPhrases.isEmpty {
                    linkedGuides += 1
                    break
                }
            }
        }
        #expect(linkedGuides >= 72)
        #expect(catalog.guides[.clerk]?.steps.first?.linkPhrases.isEmpty == true)
        #expect(catalog.guides[.render]?.steps.first?.linkPhrases.isEmpty == true)
        #expect(catalog.guides[.expo]?.steps.first?.linkPhrases.isEmpty == true)
        #expect(catalog.guides[.fly]?.steps.first?.linkPhrases.isEmpty == true)
        #expect(catalog.guides[.gcp]?.steps.first?.linkPhrases.isEmpty == true)
        #expect(catalog.guides[.slack]?.steps.first?.linkPhrases.isEmpty == true)
        #expect(catalog.guides[.notion]?.steps.first?.linkPhrases.isEmpty == true)
        #expect(catalog.guides[.figma]?.steps.first?.linkPhrases.isEmpty == true)
        #expect(catalog.guides[.supabase]?.steps.first?.linkPhrases.isEmpty == true)
        #expect(catalog.guides[.linear]?.steps.first?.linkPhrases.isEmpty == true)
        #expect(catalog.guides[.pulumi]?.steps.first?.linkPhrases.isEmpty == true)
        #expect(catalog.guides[.cursor]?.steps.first?.linkPhrases.isEmpty == true)
        #expect(catalog.guides[.gitlab]?.steps.first?.linkPhrases.isEmpty == true)
    }

    @Test("旧步骤没有 linkPhrases 也能解")
    func stepWithoutLinkPhrasesDecodes() throws {
        let json = Data(#"{ "text": "打开控制台。", "emphasized": ["控制台"] }"#.utf8)
        let step = try JSONDecoder().decode(SetupStep.self, from: json)
        #expect(step.linkPhrases.isEmpty)
        #expect(step.emphasized == ["控制台"])
        #expect(step.linkTarget.isEmpty)
    }

    @Test("没有规则的字段只拦空值")
    func emptyOnlyWhenNoRules() {
        let field = SetupField(key: "apiToken", label: "API Token", isSecret: true)
        #expect(field.errorMessage(for: "") == String(localized: L("请填写\(field.label)")))
        #expect(field.errorMessage(for: "   ") == String(localized: L("请填写\(field.label)")))
        #expect(field.errorMessage(for: "anything") == nil)
    }

    @Test("Cloudflare Account ID：32 位十六进制，提示是具体的")
    func cloudflareAccountIDValidation() {
        let field = SetupField(
            key: "accountID",
            label: "Account ID",
            isSecret: false,
            validation: SetupFieldValidation(
                message: "Account ID 应该是 32 位十六进制",
                exactLength: 32,
                allowedCharacters: "0123456789abcdefABCDEF"
            )
        )
        let valid = "0123456789abcdef0123456789ABCDEF"
        #expect(field.errorMessage(for: valid) == nil)
        #expect(field.errorMessage(for: " \(valid) ") == nil)
        #expect(field.errorMessage(for: "") == String(localized: L("请填写\(field.label)")))
        #expect(field.errorMessage(for: String(valid.dropLast())) == field.validation?.message)
        #expect(field.errorMessage(for: "g123456789abcdef0123456789abcdef") == field.validation?.message)
        #expect(field.errorMessage(for: valid) != "格式不正确")
    }

    @Test("OpenAI Admin Key：固定前缀，普通 API key 过不了")
    func openaiAdminKeyPrefix() {
        let field = SetupField(
            key: "apiKey",
            label: "Admin Key",
            isSecret: true,
            validation: SetupFieldValidation(
                message: "Admin Key 应该以 sk-admin- 开头，普通 API key 读不到账单",
                prefix: "sk-admin-"
            )
        )
        #expect(field.errorMessage(for: "sk-admin-abc") == nil)
        #expect(field.errorMessage(for: "sk-proj-abc") == field.validation?.message)
        #expect(field.errorMessage(for: "sk-abc") == field.validation?.message)
        #expect(field.errorMessage(for: "") == String(localized: L("请填写\(field.label)")))
    }

    @Test("AWS Access Key ID：只要 AKIA 长期密钥")
    func awsAccessKeyPrefix() {
        let field = SetupField(
            key: "accessKeyID",
            label: "Access Key ID",
            isSecret: false,
            validation: SetupFieldValidation(
                message: "Access Key ID 应该以 AKIA 开头。临时密钥（ASIA）不能长期放在这台手机上",
                prefix: "AKIA"
            )
        )
        #expect(field.errorMessage(for: "AKIATESTKEYEXAMPLE") == nil)
        #expect(field.errorMessage(for: "ASIATESTKEYEXAMPLE") == field.validation?.message)
        #expect(field.errorMessage(for: "") == String(localized: L("请填写\(field.label)")))
    }

    @Test("GitHub PAT：只要 Fine-grained")
    func githubFineGrainedPrefix() {
        let field = SetupField(
            key: "personalAccessToken",
            label: "Personal Access Token",
            isSecret: true,
            validation: SetupFieldValidation(
                message: "请用 Fine-grained token（github_pat_ 开头）。Classic token（ghp_）读不到新的 Billing API",
                prefix: "github_pat_"
            )
        )
        #expect(field.errorMessage(for: "github_pat_abc") == nil)
        #expect(field.errorMessage(for: "ghp_abc") == field.validation?.message)
        #expect(field.errorMessage(for: "") == String(localized: L("请填写\(field.label)")))
    }

    private func assertNoURLShapedProperties<T>(_ value: T) {
        for child in Mirror(reflecting: value).children {
            let label = (child.label ?? "").lowercased()
            #expect(!label.contains("url"), "unexpected URL field \(child.label ?? "?")")
            #expect(!label.contains("endpoint"), "unexpected endpoint field \(child.label ?? "?")")
        }
    }
}
