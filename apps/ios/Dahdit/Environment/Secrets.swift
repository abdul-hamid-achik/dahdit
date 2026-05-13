import Foundation

enum Secrets {
    static var graphQLEndpoint: String {
        Bundle.main.object(forInfoDictionaryKey: "DAHDIT_GRAPHQL_ENDPOINT") as? String
            ?? "http://localhost:4000/graphql"
    }
}

