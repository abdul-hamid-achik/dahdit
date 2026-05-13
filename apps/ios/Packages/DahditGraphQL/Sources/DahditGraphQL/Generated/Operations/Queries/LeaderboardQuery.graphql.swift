// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension DahditGraphQLGenerated {
  nonisolated struct LeaderboardQuery: GraphQLQuery {
    static let operationName: String = "Leaderboard"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query Leaderboard($limit: Int) { leaderboard(limit: $limit) { __typename userId username xpTotal streakDays rank } }"#
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
        .field("leaderboard", [Leaderboard]?.self, arguments: ["limit": .variable("limit")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        LeaderboardQuery.Data.self
      ] }

      var leaderboard: [Leaderboard]? { __data["leaderboard"] }

      /// Leaderboard
      ///
      /// Parent Type: `LeaderboardEntry`
      nonisolated struct Leaderboard: DahditGraphQLGenerated.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DahditGraphQLGenerated.Objects.LeaderboardEntry }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("userId", String?.self),
          .field("username", String?.self),
          .field("xpTotal", Int?.self),
          .field("streakDays", Int?.self),
          .field("rank", Int?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          LeaderboardQuery.Data.Leaderboard.self
        ] }

        var userId: String? { __data["userId"] }
        var username: String? { __data["username"] }
        var xpTotal: Int? { __data["xpTotal"] }
        var streakDays: Int? { __data["streakDays"] }
        var rank: Int? { __data["rank"] }
      }
    }
  }

}