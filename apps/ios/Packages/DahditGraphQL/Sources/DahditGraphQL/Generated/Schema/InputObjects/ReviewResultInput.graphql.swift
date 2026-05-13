// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

extension DahditGraphQLGenerated {
  nonisolated struct ReviewResultInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      cardKey: String,
      grade: String
    ) {
      __data = InputDict([
        "cardKey": cardKey,
        "grade": grade
      ])
    }

    var cardKey: String {
      get { __data["cardKey"] }
      set { __data["cardKey"] = newValue }
    }

    var grade: String {
      get { __data["grade"] }
      set { __data["grade"] = newValue }
    }
  }

}