import Foundation
import Testing
import MeterProviders
@testable import MeterFeatures

struct AddProviderSearchTests {
    @Test("搜 groq 不出现：不接入的家产品列表滤掉")
    func declinedProvidersAreHiddenFromAddList() {
        let hits = AddProviderSearch.filteredDescriptors(query: "groq")
        #expect(hits.isEmpty)
        #expect(AddProviderSearch.showsEmptySearch(query: "groq"))
        #expect(AddProviderSearch.visibleDescriptors(query: "supabase", browse: .featured).map(\.id).contains(.supabase))
        #expect(AddProviderSearch.filteredDescriptors(query: "google cloud").map(\.id).contains(.gcp))
        #expect(AddProviderSearch.filteredDescriptors(query: "slack").map(\.id).contains(.slack))
        #expect(AddProviderSearch.filteredDescriptors(query: "notion").map(\.id).contains(.notion))
        #expect(AddProviderSearch.filteredDescriptors(query: "figma").map(\.id).contains(.figma))
        #expect(AddProviderSearch.filteredDescriptors(query: "linear").map(\.id).contains(.linear))
        #expect(AddProviderSearch.filteredDescriptors(query: "pulumi").map(\.id).contains(.pulumi))
        #expect(AddProviderSearch.filteredDescriptors(query: "mistral").map(\.id).contains(.mistral))
        #expect(AddProviderSearch.filteredDescriptors(query: "pinecone").isEmpty)
        #expect(AddProviderSearch.filteredDescriptors(query: "linode").map(\.id).contains(.linode))
        #expect(AddProviderSearch.filteredDescriptors(query: "bunny").map(\.id).contains(.bunny))
        #expect(AddProviderSearch.filteredDescriptors(query: "datadog").map(\.id).contains(.datadog))
        #expect(AddProviderSearch.filteredDescriptors(query: "pagerduty").isEmpty)
        #expect(AddProviderSearch.filteredDescriptors(query: "novita").map(\.id).contains(.novita))
        #expect(AddProviderSearch.filteredDescriptors(query: "apify").map(\.id).contains(.apify))
        #expect(AddProviderSearch.filteredDescriptors(query: "tavily").map(\.id).contains(.tavily))
        #expect(AddProviderSearch.filteredDescriptors(query: "cerebras").isEmpty)
        #expect(AddProviderSearch.filteredDescriptors(query: "wasabi").isEmpty)
        #expect(AddProviderSearch.filteredDescriptors(query: "aiven").map(\.id).contains(.aiven))
        #expect(AddProviderSearch.filteredDescriptors(query: "硅基流动").map(\.id).contains(.siliconflow))
        #expect(AddProviderSearch.filteredDescriptors(query: "阶跃星辰").map(\.id).contains(.stepfun))
        #expect(AddProviderSearch.filteredDescriptors(query: "telnyx").map(\.id).contains(.telnyx))
        #expect(AddProviderSearch.filteredDescriptors(query: "minimax").isEmpty)
        #expect(AddProviderSearch.filteredDescriptors(query: "dashscope").isEmpty)
        #expect(AddProviderSearch.filteredDescriptors(query: "zhipu").isEmpty)
        #expect(AddProviderSearch.filteredDescriptors(query: "mariadb").map(\.id).contains(.mariadb))
        #expect(AddProviderSearch.filteredDescriptors(query: "ionos").map(\.id).contains(.ionos))
        #expect(AddProviderSearch.filteredDescriptors(query: "upcloud").map(\.id).contains(.upcloud))
        #expect(AddProviderSearch.filteredDescriptors(query: "confluent").map(\.id).contains(.confluent))
        #expect(AddProviderSearch.filteredDescriptors(query: "circleci").isEmpty)
        #expect(AddProviderSearch.filteredDescriptors(query: "tailscale").isEmpty)
        #expect(AddProviderSearch.filteredDescriptors(query: "postmark").isEmpty)
        #expect(AddProviderSearch.filteredDescriptors(query: "vonage").map(\.id).contains(.vonage))
        #expect(AddProviderSearch.filteredDescriptors(query: "plivo").map(\.id).contains(.plivo))
        #expect(AddProviderSearch.filteredDescriptors(query: "messagebird").map(\.id).contains(.messagebird))
        #expect(AddProviderSearch.filteredDescriptors(query: "ibm").map(\.id).contains(.ibm))
        #expect(AddProviderSearch.filteredDescriptors(query: "brevo").isEmpty)
        #expect(AddProviderSearch.filteredDescriptors(query: "mailchimp").isEmpty)
        #expect(AddProviderSearch.filteredDescriptors(query: "bitbucket").isEmpty)
        #expect(AddProviderSearch.filteredDescriptors(query: "clicksend").map(\.id).contains(.clicksend))
        #expect(AddProviderSearch.filteredDescriptors(query: "infobip").map(\.id).contains(.infobip))
        #expect(AddProviderSearch.filteredDescriptors(query: "textmagic").map(\.id).contains(.textmagic))
        #expect(AddProviderSearch.filteredDescriptors(query: "sinch").isEmpty)
        #expect(AddProviderSearch.filteredDescriptors(query: "n8n").isEmpty)
        #expect(AddProviderSearch.filteredDescriptors(query: "okta").isEmpty)
    }

    @Test("搜 cursor 结果里有 Cursor")
    func cursorFindsCursor() {
        let hits = AddProviderSearch.filteredDescriptors(query: "cursor")
        #expect(hits.map(\.id).contains(.cursor))
        #expect(!AddProviderSearch.showsEmptySearch(query: "cursor"))
    }

    @Test("搜 claude 结果里有 Anthropic")
    func claudeFindsAnthropic() {
        let hits = AddProviderSearch.filteredDescriptors(query: "claude")
        #expect(hits.map(\.id).contains(.anthropic))
        #expect(!AddProviderSearch.showsEmptySearch(query: "claude"))
    }

    @Test("搜大写 S3 结果里有 AWS")
    func uppercaseS3FindsAWS() {
        let hits = AddProviderSearch.filteredDescriptors(query: "S3")
        #expect(hits.map(\.id).contains(.aws))
    }

    @Test("搜克劳德结果里有 Anthropic")
    func chineseAliasFindsAnthropic() {
        let hits = AddProviderSearch.filteredDescriptors(query: "克劳德")
        #expect(hits.map(\.id).contains(.anthropic))
    }

    @Test("空搜索列档 1、2，刨去读数信箱和不接入，按品类分组")
    func emptyQueryListsFeaturedTiersByCategory() {
        let hits = AddProviderSearch.filteredDescriptors(query: "")
        let expected = ProviderCatalog.offered.filter {
            ($0.tier == .one || $0.tier == .two) && !$0.supportsInboxIngest
        }
        #expect(Set(hits.map(\.id)) == Set(expected.map(\.id)))
        #expect(hits.allSatisfy { ($0.tier == .one || $0.tier == .two) && !$0.supportsInboxIngest })
        #expect(hits.map(\.id).contains(.aws))
        #expect(hits.map(\.id).contains(.digitalocean))
        #expect(!hits.map(\.id).contains(.supabase))
        #expect(!hits.map(\.id).contains(.fly))
        #expect(!hits.map(\.id).contains(.groq))
        #expect(!hits.map(\.id).contains(.netlify))
        let sections = AddProviderSearch.sections(from: hits)
        #expect(sections.count > 1)
        #expect(sections.allSatisfy { $0.category != nil })
        #expect(AddProviderSearch.showsMoreRow(query: ""))
    }

    @Test("一打字就搜全目录，档 3 也能命中")
    func typingSearchesEveryOfferedTier() {
        let apify = AddProviderSearch.visibleDescriptors(query: "apify", browse: .featured)
        #expect(apify.map(\.id).contains(.apify))
        #expect(ProviderCatalog.apify.tier > .two)
        let empty = AddProviderSearch.visibleDescriptors(query: "", browse: .featured)
        #expect(!empty.map(\.id).contains(.apify))
    }

    @Test("更多服务空搜索列出剩下的全部，不含常见服务")
    func moreBrowseListsTheRestUntilSearch() {
        let featured = AddProviderSearch.visibleDescriptors(query: "", browse: .featured)
        let rest = AddProviderSearch.visibleDescriptors(query: "", browse: .more)
        #expect(!rest.isEmpty)
        #expect(Set(featured.map(\.id)).isDisjoint(with: Set(rest.map(\.id))))
        #expect(
            Set(featured.map(\.id)).union(rest.map(\.id))
                == Set(ProviderCatalog.offered.map(\.id))
        )
        #expect(rest.map(\.id).contains(.supabase))
        #expect(rest.map(\.id).contains(.fly))
        #expect(rest.map(\.id).contains(.apify))
        #expect(!rest.map(\.id).contains(.aws))
        #expect(!rest.map(\.id).contains(.digitalocean))
        let aws = AddProviderSearch.visibleDescriptors(query: "aws", browse: .more)
        #expect(aws.map(\.id).contains(.aws))
    }

    @Test("搜不存在的词返回空，并走 ContentUnavailableView.search")
    func unknownQueryShowsSystemEmptySearch() {
        let query = "zzzz-not-a-provider"
        #expect(AddProviderSearch.filteredDescriptors(query: query).isEmpty)
        #expect(!AddProviderSearch.matchesManualRow(query))
        #expect(AddProviderSearch.showsEmptySearch(query: query))
        #expect(usesSystemSearchUnavailable)
    }

    @Test("已经加进来的不出现在添加列表")
    func membersAreHiddenFromAddList() {
        let hits = AddProviderSearch.filteredDescriptors(
            query: "",
            excluding: [.anthropic, .openai]
        )
        let ids = hits.map(\.id)
        #expect(!ids.contains(.anthropic))
        #expect(!ids.contains(.openai))
        #expect(ids.contains(.aws))
        #expect(
            Set(ids)
                == Set(
                    ProviderCatalog.offered.filter {
                        ($0.tier == .one || $0.tier == .two) && !$0.supportsInboxIngest
                    }.map(\.id)
                )
                .subtracting([.anthropic, .openai])
        )
    }

    @Test("搜已经加进来的那家走空搜索，不把那一行找回来")
    func searchingAnAddedProviderShowsEmptySearch() {
        #expect(
            AddProviderSearch.filteredDescriptors(
                query: "claude",
                excluding: [.anthropic]
            ).isEmpty
        )
        #expect(
            AddProviderSearch.showsEmptySearch(query: "claude", excluding: [.anthropic])
        )
        #expect(
            !AddProviderSearch.showsEmptySearch(query: "", excluding: [.anthropic])
        )
    }

    /// 空搜索必须用系统 `ContentUnavailableView.search`，不要自造空态。
    private var usesSystemSearchUnavailable: Bool {
        guard let text = try? GuardrailSourceScan.sourceText(named: "AddProviderView.swift") else {
            return false
        }
        return text.contains("ContentUnavailableView.search")
    }

    @Test("搜索栏进页就钉在导航栏下，不藏进底部抽屉")
    func searchFieldAlwaysVisibleInNavigationBar() throws {
        // 搜索框走 `meterColumnSearchable`：iOS 钉在导航栏下，Mac 画在列顶。
        let text = try GuardrailSourceScan.sourceText(named: "AddProviderView.swift")
        #expect(text.contains("meterColumnSearchable("))
        #expect(!text.contains(".searchable("))
        let search = try GuardrailSourceScan.sourceText(named: "MeterColumnSearch.swift")
        #expect(search.contains("placement: .navigationBarDrawer(displayMode: .always)"))
    }

    @Test("常显搜索栏下面不再叠一截 insetGrouped 顶距")
    func searchResultsDropTheDefaultListTopMargin() throws {
        let text = try GuardrailSourceScan.sourceText(named: "AddProviderView.swift")
        #expect(text.contains("contentMargins(.top, MeterSpacing.xs, for: .scrollContent)"))
        #expect(text.contains("defaultMinListHeaderHeight, 0"))
    }

    @Test("添加列表排除已加进来的，不再把那一行推进详情")
    func addListExcludesMembersInsteadOfLinkingToDetail() throws {
        let text = try GuardrailSourceScan.sourceText(named: "AddProviderView.swift")
        #expect(text.contains("excluding: memberIDs"))
        #expect(!text.contains("ServicesRoute.detail"))
        #expect(!text.contains("connectedCount"))
        #expect(!text.contains("isMember"))
    }

    @Test("点添加先关抽屉，关完才进详情")
    func confirmSheetDismissesBeforeNavigating() throws {
        let text = try GuardrailSourceScan.sourceText(named: "AddProviderView.swift")
        #expect(text.contains("onDismiss:"))
        #expect(text.contains("confirmedProviderID"))
        #expect(text.contains("await Task.yield()"))
        #expect(!text.contains("onAdd: { onAdd(id) }"))
    }

    @Test("从添加页进详情是推进，不是整栈替换")
    func finishAddPushesDetailOntoAdd() throws {
        let text = try GuardrailSourceScan.sourceText(named: "ServicesView.swift")
        #expect(text.contains("path.last == .add || path.last == .addMore"))
        #expect(text.contains("path.append(.detail(id))"))
    }

    @Test("添加确认按内容高度，不用 fitted 撑成全屏")
    func confirmSheetUsesHeightDetentNotFitted() throws {
        let text = try GuardrailSourceScan.sourceText(named: "AddProviderConfirmSheet.swift")
        #expect(text.contains("meterDrawerChrome"))
        #expect(text.contains(".compact"))
        #expect(!text.contains("presentationSizing(.fitted)"))
    }
}