// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension DahditGraphQLGenerated {
  nonisolated struct RefreshTokenMutation: GraphQLMutation {
    static let operationName: String = "RefreshToken"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation RefreshToken($refreshToken: String!) { refreshToken(refreshToken: $refreshToken) { __typename accessToken refreshToken user { __typename id email username tz } } }"#
      ))

    public var refreshToken: String

    public init(refreshToken: String) {
      self.refreshToken = refreshToken
    }

    @_spi(Unsafe) public var __variables: Variables? { ["refreshToken": refreshToken] }

    nonisolated struct Data: DahditGraphQLGenerated.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DahditGraphQLGenerated.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("refreshToken", RefreshToken?.self, arguments: ["refreshToken": .variable("refreshToken")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        RefreshTokenMutation.Data.self
      ] }

      var refreshToken: RefreshToken? { __data["refreshToken"] }

      /// RefreshToken
      ///
      /// Parent Type: `AuthPayload`
      nonisolated struct RefreshToken: DahditGraphQLGenerated.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DahditGraphQLGenerated.Objects.AuthPayload }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("accessToken", String?.self),
          .field("refreshToken", String?.self),
          .field("user", User?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          RefreshTokenMutation.Data.RefreshToken.self
        ] }

        var accessToken: String? { __data["accessToken"] }
        var refreshToken: String? { __data["refreshToken"] }
        var user: User? { __data["user"] }

        /// RefreshToken.User
        ///
        /// Parent Type: `User`
        nonisolated struct User: DahditGraphQLGenerated.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { DahditGraphQLGenerated.Objects.User }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", String?.self),
            .field("email", String?.self),
            .field("username", String?.self),
            .field("tz", String?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            RefreshTokenMutation.Data.RefreshToken.User.self
          ] }

          var id: String? { __data["id"] }
          var email: String? { __data["email"] }
          var username: String? { __data["username"] }
          var tz: String? { __data["tz"] }
        }
      }
    }
  }

}