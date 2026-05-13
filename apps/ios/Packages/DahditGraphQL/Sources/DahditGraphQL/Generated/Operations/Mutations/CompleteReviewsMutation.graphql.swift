// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension DahditGraphQLGenerated {
  nonisolated struct CompleteReviewsMutation: GraphQLMutation {
    static let operationName: String = "CompleteReviews"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation CompleteReviews($results: [ReviewResultInput!]!) { completeReviews(results: $results) { __typename completedCount remainingDueCount } }"#
      ))

    public var results: [ReviewResultInput]

    public init(results: [ReviewResultInput]) {
      self.results = results
    }

    @_spi(Unsafe) public var __variables: Variables? { ["results": results] }

    nonisolated struct Data: DahditGraphQLGenerated.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DahditGraphQLGenerated.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("completeReviews", CompleteReviews?.self, arguments: ["results": .variable("results")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CompleteReviewsMutation.Data.self
      ] }

      var completeReviews: CompleteReviews? { __data["completeReviews"] }

      /// CompleteReviews
      ///
      /// Parent Type: `CompleteReviewsResult`
      nonisolated struct CompleteReviews: DahditGraphQLGenerated.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DahditGraphQLGenerated.Objects.CompleteReviewsResult }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("completedCount", Int?.self),
          .field("remainingDueCount", Int?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CompleteReviewsMutation.Data.CompleteReviews.self
        ] }

        var completedCount: Int? { __data["completedCount"] }
        var remainingDueCount: Int? { __data["remainingDueCount"] }
      }
    }
  }

}