import Testing
@testable import TollcatCore

struct ArgumentParserTests {
    @Test func dashboardDefault() throws {
        let invocation = try ArgumentParser.parse([])
        #expect(invocation.verb == nil)
        #expect(invocation.json == false)
        #expect(invocation.oneline == false)
    }

    @Test func verbsAndFlags() throws {
        let invocation = try ArgumentParser.parse(
            ["--json", "providers", "--locale", "ja", "--max-age=0", "--no-color"]
        )
        #expect(invocation.verb == .providers)
        #expect(invocation.json)
        #expect(invocation.locale == "ja")
        #expect(invocation.maxAgeMinutes == 0)
        #expect(invocation.noColor)
    }

    @Test func addPositional() throws {
        let invocation = try ArgumentParser.parse(["add", "openai"])
        #expect(invocation.verb == .add)
        #expect(invocation.positional == ["openai"])
    }

    @Test func unknownFlag() {
        #expect(throws: ParseError.unknownFlag("--foo")) {
            try ArgumentParser.parse(["--foo"])
        }
    }

    @Test func unknownCommand() {
        #expect(throws: ParseError.unknownCommand("dance")) {
            try ArgumentParser.parse(["dance"])
        }
    }

    @Test func conflictingOutput() {
        #expect(throws: ParseError.conflictingOutput) {
            try ArgumentParser.parse(["--json", "--oneline"])
        }
    }

    @Test func missingLocale() {
        #expect(throws: ParseError.missingValue("--locale")) {
            try ArgumentParser.parse(["--locale"])
        }
    }

    @Test func invalidMaxAge() {
        #expect(throws: ParseError.invalidMaxAge("nope")) {
            try ArgumentParser.parse(["--max-age", "nope"])
        }
    }

    @Test func versionAndHelp() throws {
        #expect(try ArgumentParser.parse(["--version"]).version)
        #expect(try ArgumentParser.parse(["-h"]).help)
    }
}
