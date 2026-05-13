// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension DahditGraphQLGenerated {
  nonisolated struct LoginMutation: GraphQLMutation {
    static let operationName: String = "Login"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation Login($email: String!, $password: String!) { login(email: $email, password: $password) { __typename accessToken refreshToken user { __typename id email username tz } } }"#
      ))

    public var email: String
    public var password: String

    public init(
      email: String,
      password: String
    ) {
      self.email = email
      self.password = password
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "email": email,
      "password": password
    ] }

    nonisolated struct Data: DahditGraphQLGenerated.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DahditGraphQLGenerated.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("login", Login?.self, arguments: [
          "email": .variable("email"),
          "password": .variable("password")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        LoginMutation.Data.self
      ] }

      var login: Login? { __data["login"] }

      /// Login
      ///
      /// Parent Type: `AuthPayload`
      nonisolated struct Login: DahditGraphQLGenerated.SelectionSet {
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
          LoginMutation.Data.Login.self
        ] }

        var accessToken: String? { __data["accessToken"] }
        var refreshToken: String? { __data["refreshToken"] }
        var user: User? { __data["user"] }

        /// Login.User
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
            LoginMutation.Data.Login.User.self
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