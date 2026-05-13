// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension DahditGraphQLGenerated {
  nonisolated struct DueReviewsQuery: GraphQLQuery {
    static let operationName: String = "DueReviews"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query DueReviews($limit: Int) { dueReviews(limit: $limit) { __typename cardKey ease intervalDays dueOn } }"#
      ))

    public var limit: GraphQLNullable<Int32>

    public init(limit: GraphQLNullable<Int32>) {
      self.limit = limit
    }

    @_spi(Unsafe) public var __variables: Variables? { ["limit": limit] }

    nonisolated struct Data: DahditGraphQLGenerated.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DahditGraphQLGenerated.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("dueReviews", [DueReview]?.self, arguments: ["limit": .variable("limit")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        DueReviewsQuery.Data.self
      ] }

      var dueReviews: [DueReview]? { __data["dueReviews"] }

      /// DueReview
      ///
      /// Parent Type: `ReviewCard`
      nonisolated struct DueReview: DahditGraphQLGenerated.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DahditGraphQLGenerated.Objects.ReviewCard }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("cardKey", String?.self),
          .field("ease", Double?.self),
          .field("intervalDays", Int?.self),
          .field("dueOn", String?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          DueReviewsQuery.Data.DueReview.self
        ] }

        var cardKey: String? { __data["cardKey"] }
        var ease: Double? { __data["ease"] }
        var intervalDays: Int? { __data["intervalDays"] }
        var dueOn: String? { __data["dueOn"] }
      }
    }
  }

}