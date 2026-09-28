import Foundation
import TollcatCore

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

ResourceBootstrap.install()
exit(CLIRuntime.main())
