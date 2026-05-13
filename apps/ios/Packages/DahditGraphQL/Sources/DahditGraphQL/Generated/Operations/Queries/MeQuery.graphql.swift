// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension DahditGraphQLGenerated {
  nonisolated struct MeQuery: GraphQLQuery {
    static let operationName: String = "Me"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query Me { me { __typename id email username tz stats { __typename xpTotal streakDays hearts heartsRefillAt } } }"#
      ))

    public init() {}

    nonisolated struct Data: DahditGraphQLGenerated.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DahditGraphQLGenerated.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("me", Me?.self),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        MeQuery.Data.self
      ] }

      var me: Me? { __data["me"] }

      /// Me
      ///
      /// Parent Type: `User`
      nonisolated struct Me: DahditGraphQLGenerated.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DahditGraphQLGenerated.Objects.User }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String?.self),
          .field("email", String?.self),
          .field("username", String?.self),
          .field("tz", String?.self),
          .field("stats", Stats?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          MeQuery.Data.Me.self
        ] }

        var id: String? { __data["id"] }
        var email: String? { __data["email"] }
        var username: String? { __data["username"] }
        var tz: String? { __data["tz"] }
        var stats: Stats? { __data["stats"] }

        /// Me.Stats
        ///
        /// Parent Type: `UserStats`
        nonisolated struct Stats: DahditGraphQLGenerated.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { DahditGraphQLGenerated.Objects.UserStats }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("xpTotal", Int?.self),
            .field("streakDays", Int?.self),
            .field("hearts", Int?.self),
            .field("heartsRefillAt", DahditGraphQLGenerated.DateTime?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            MeQuery.Data.Me.Stats.self
          ] }

          var xpTotal: Int? { __data["xpTotal"] }
          var streakDays: Int? { __data["streakDays"] }
          var hearts: Int? { __data["hearts"] }
          var heartsRefillAt: DahditGraphQLGenerated.DateTime? { __data["heartsRefillAt"] }
        }
      }
    }
  }

}