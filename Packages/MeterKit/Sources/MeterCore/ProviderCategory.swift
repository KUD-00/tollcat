import Foundation

/// 服务归哪一类花钱。仪表盘「按类别构成」用它把几十家收成几段；
/// 目录里每家标一个，不在这里猜。文案在展示层。
public enum ProviderCategory: String, Hashable, Sendable, Codable, CaseIterable {
    /// 模型推理、语音、向量检索、AI 应用平台
    case aiInference
    /// GPU 租用、模型托管算力
    case gpuCompute
    /// 应用托管、云平台、VPS
    case hosting
    /// 数据库、缓存、数据仓库
    case database
    /// 全文搜索、向量搜索
    case search
    /// CDN、边缘、网络
    case networkEdge
    /// 对象存储、备份
    case storage
    /// 图片、视频处理与分发
    case media
    /// 代码托管、开发平台
    case devTools
    /// CI、测试、代码质量
    case ciCd
    /// 监控、日志、错误追踪、告警
    case observability
    /// 登录、身份、密钥管理
    case authSecurity
    /// 收款、订阅计费
    case payments
    /// 短信、邮件、推送、通话
    case messaging
    /// 协作、设计、项目管理
    case collaboration
    /// 内容管理、建站
    case cms
    /// 产品分析、埋点、A/B
    case analytics
    /// 工作流自动化、任务队列
    case automation
    /// 数据管道、ETL、基础设施编排
    case dataPipeline
    /// 归不进上面任何一类
    case other
}
