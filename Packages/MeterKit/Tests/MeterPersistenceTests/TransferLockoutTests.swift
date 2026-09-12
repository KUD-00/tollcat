import Foundation
import Testing
@testable import MeterPersistence

struct TransferLockoutTests {
    @Test("前四次失败不锁，第五次起按次数退避")
    func backoffStartsOnFifthFailure() {
        var lockout = TransferLockout()
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        for _ in 0..<4 {
            lockout.registerFailure(now: now)
            #expect(!lockout.isLocked(now: now))
        }
        #expect(lockout.remainingFreeAttempts == 1)

        lockout.registerFailure(now: now)
        #expect(lockout.remainingFreeAttempts == 0)
        #expect(lockout.isLocked(now: now))
        #expect(lockout.isLocked(now: now.addingTimeInterval(14)))
        #expect(!lockout.isLocked(now: now.addingTimeInterval(15)))
        #expect(TransferLockout.delay(afterFailureCount: 5) == 15)

        lockout.registerFailure(now: now.addingTimeInterval(15))
        #expect(TransferLockout.delay(afterFailureCount: 6) == 30)
        #expect(lockout.isLocked(now: now.addingTimeInterval(15 + 29)))
        #expect(!lockout.isLocked(now: now.addingTimeInterval(15 + 30)))

        #expect(TransferLockout.delay(afterFailureCount: 7) == 60)
        #expect(TransferLockout.delay(afterFailureCount: 8) == 120)
        #expect(TransferLockout.delay(afterFailureCount: 9) == 300)
        #expect(TransferLockout.delay(afterFailureCount: 10) == 900)
    }

    @Test("成功后清零")
    func successClearsLockout() {
        var lockout = TransferLockout()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        for _ in 0..<5 {
            lockout.registerFailure(now: now)
        }
        lockout.registerSuccess()
        #expect(lockout.failureCount == 0)
        #expect(!lockout.isLocked(now: now))
        #expect(lockout.remainingFreeAttempts == TransferLockout.freeAttemptLimit)
    }
}
