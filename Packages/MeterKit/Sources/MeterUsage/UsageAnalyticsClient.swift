import Foundation
import os

/// 把页面进入收成一批再发。连续停留在同一页不计第二次。
///
/// 失败丢掉这一批（成功前 `newVisit` 也不落盘），宁可少计，不要超时重试把次数打双。
public final class UsageAnalyticsClient: UsageAnalyticsRecording, Sendable {
    private struct State {
        var counts: [UsageAnalyticsScreen: Int] = [:]
        var lastScreen: UsageAnalyticsScreen?
        var flushGeneration = 0
        var inFlight = false
    }

    private let state = OSAllocatedUnfairLock(initialState: State())
    private let submitter: any UsageSubmitting
    private let visitMarker: any UsageVisitMarking
    private let now: @Sendable () -> Date
    private let debounceNanoseconds: UInt64
    private let platform: String
    private let appVersion: String

    public init(
        submitter: any UsageSubmitting,
        visitMarker: any UsageVisitMarking,
        platform: String = "ios",
        appVersion: String,
        now: @escaping @Sendable () -> Date = { Date() },
        debounceNanoseconds: UInt64 = 2_000_000_000
    ) {
        self.submitter = submitter
        self.visitMarker = visitMarker
        self.platform = platform
        self.appVersion = appVersion
        self.now = now
        self.debounceNanoseconds = debounceNanoseconds
    }

    public func record(_ screen: UsageAnalyticsScreen) {
        let shouldFlush = state.withLock { state -> Bool in
            if state.lastScreen == screen { return false }
            state.lastScreen = screen
            state.counts[screen, default: 0] += 1
            if state.counts[screen]! > UsageFieldLimits.count {
                state.counts[screen] = UsageFieldLimits.count
            }
            state.flushGeneration += 1
            return true
        }
        guard shouldFlush else { return }
        scheduleFlush()
    }

    public func flush() {
        let generation = state.withLock { state -> Int in
            state.flushGeneration += 1
            return state.flushGeneration
        }
        Task { await send(expectedGeneration: generation, wait: false) }
    }

    private func scheduleFlush() {
        let generation = state.withLock { $0.flushGeneration }
        Task { await send(expectedGeneration: generation, wait: true) }
    }

    private func send(expectedGeneration: Int, wait: Bool) async {
        if wait {
            try? await Task.sleep(nanoseconds: debounceNanoseconds)
        }
        let payload: UsageAnalyticsPayload? = state.withLock { state in
            guard state.flushGeneration == expectedGeneration, !state.inFlight else { return nil }
            guard let built = makePayloadLocked(&state) else { return nil }
            state.inFlight = true
            return built
        }
        guard let payload else { return }

        do {
            try await submitter.submit(payload)
            if payload.newVisit {
                visitMarker.markVisitSent(on: UsageUTCDay.string(from: now()))
            }
        } catch {
            state.withLock { $0.inFlight = false }
            return
        }

        let nextGeneration: Int? = state.withLock { state in
            state.inFlight = false
            guard !state.counts.isEmpty else { return nil }
            state.flushGeneration += 1
            return state.flushGeneration
        }
        if let nextGeneration {
            Task { await send(expectedGeneration: nextGeneration, wait: true) }
        }
    }

    private func makePayloadLocked(_ state: inout State) -> UsageAnalyticsPayload? {
        let day = UsageUTCDay.string(from: now())
        let newVisit = visitMarker.shouldCountVisit(on: day)
        let screens = state.counts
            .map { UsageAnalyticsPayload.ScreenCount(id: $0.key.rawValue, n: $0.value) }
            .sorted { $0.id < $1.id }
        state.counts.removeAll()
        guard newVisit || !screens.isEmpty else { return nil }
        return UsageAnalyticsPayload(
            platform: platform,
            appVersion: appVersion,
            newVisit: newVisit,
            screens: screens
        )
    }
}
