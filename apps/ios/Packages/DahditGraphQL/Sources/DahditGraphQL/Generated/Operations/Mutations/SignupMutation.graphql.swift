// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension DahditGraphQLGenerated {
  nonisolated struct SignupMutation: GraphQLMutation {
    static let operationName: String = "Signup"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation Signup($email: String!, $username: String!, $password: String!, $tz: String) { signup(email: $email, username: $username, password: $password, tz: $tz) { __typename accessToken refreshToken user { __typename id email username tz } } }"#
      ))

    public var email: String
    public var username: String
    public var password: String
    public var tz: GraphQLNullable<String>

    public init(
      email: String,
      username: String,
      password: String,
      tz: GraphQLNullable<String>
    ) {
      self.email = email
      self.username = username
      self.password = password
      self.tz = tz
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "email": email,
      "username": username,
      "password": password,
      "tz": tz
    ] }

    nonisolated struct Data: DahditGraphQLGenerated.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DahditGraphQLGenerated.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("signup", Signup?.self, arguments: [
          "email": .variable("email"),
          "username": .variable("username"),
          "password": .variable("password"),
          "tz": .variable("tz")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SignupMutation.Data.self
      ] }

      var signup: Signup? { __data["signup"] }

      /// Signup
      ///
      /// Parent Type: `AuthPayload`
      nonisolated struct Signup: DahditGraphQLGenerated.SelectionSet {
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
          SignupMutation.Data.Signup.self
        ] }

        var accessToken: String? { __data["accessToken"] }
        var refreshToken: String? { __data["refreshToken"] }
        var user: User? { __data["user"] }

        /// Signup.User
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
            SignupMutation.Data.Signup.User.self
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