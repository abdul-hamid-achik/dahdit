// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension DahditGraphQLGenerated {
  nonisolated struct StartLessonMutation: GraphQLMutation {
    static let operationName: String = "StartLesson"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation StartLesson($lessonId: String!) { startLesson(lessonId: $lessonId) { __typename id lessonId startedAt maxHearts exercises { __typename id lessonId kind position payload } } }"#
      ))

    public var lessonId: String

    public init(lessonId: String) {
      self.lessonId = lessonId
    }

    @_spi(Unsafe) public var __variables: Variables? { ["lessonId": lessonId] }

    nonisolated struct Data: DahditGraphQLGenerated.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DahditGraphQLGenerated.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("startLesson", StartLesson?.self, arguments: ["lessonId": .variable("lessonId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        StartLessonMutation.Data.self
      ] }

      var startLesson: StartLesson? { __data["startLesson"] }

      /// StartLesson
      ///
      /// Parent Type: `LessonAttempt`
      nonisolated struct StartLesson: DahditGraphQLGenerated.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DahditGraphQLGenerated.Objects.LessonAttempt }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String?.self),
          .field("lessonId", String?.self),
          .field("startedAt", DahditGraphQLGenerated.DateTime?.self),
          .field("maxHearts", Int?.self),
          .field("exercises", [Exercise]?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          StartLessonMutation.Data.StartLesson.self
        ] }

        var id: String? { __data["id"] }
        var lessonId: String? { __data["lessonId"] }
        var startedAt: DahditGraphQLGenerated.DateTime? { __data["startedAt"] }
        var maxHearts: Int? { __data["maxHearts"] }
        var exercises: [Exercise]? { __data["exercises"] }

        /// StartLesson.Exercise
        ///
        /// Parent Type: `Exercise`
        nonisolated struct Exercise: DahditGraphQLGenerated.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { DahditGraphQLGenerated.Objects.Exercise }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", String?.self),
            .field("lessonId", String?.self),
            .field("kind", String?.self),
            .field("position", Int?.self),
            .field("payload", DahditGraphQLGenerated.JSON?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            StartLessonMutation.Data.StartLesson.Exercise.self
          ] }

          var id: String? { __data["id"] }
          var lessonId: String? { __data["lessonId"] }
          var kind: String? { __data["kind"] }
          var position: Int? { __data["position"] }
          var payload: DahditGraphQLGenerated.JSON? { __data["payload"] }
        }
      }
    }
  }

}