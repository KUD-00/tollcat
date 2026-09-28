import Testing
@testable import TollcatCore

struct EnvironmentFieldTests {
    @Test func names() {
        #expect(
            EnvironmentField.variableName(providerID: "openai", field: "apiKey")
                == "TOLLCAT_OPENAI_APIKEY"
        )
        #expect(
            EnvironmentField.variableName(providerID: "aws", field: "secretAccessKey")
                == "TOLLCAT_AWS_SECRETACCESSKEY"
        )
    }

    @Test func readsFilledFields() {
        let fields = EnvironmentField.fields(
            providerID: "openai",
            keys: ["apiKey", "accountID"],
            environment: ["TOLLCAT_OPENAI_APIKEY": " sk-test "]
        )
        #expect(fields["apiKey"] == "sk-test")
        #expect(fields["accountID"] == nil)
    }
}
