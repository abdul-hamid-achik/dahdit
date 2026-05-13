// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension DahditGraphQLGenerated {
  nonisolated struct CompleteLessonMutation: GraphQLMutation {
    static let operationName: String = "CompleteLesson"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation CompleteLesson($attemptId: String!, $log: [ExerciseResultInput!]!) { completeLesson(attemptId: $attemptId, log: $log) { __typename xpEarned newStreak unlockedLessons } }"#
      ))

    public var attemptId: String
    public var log: [ExerciseResultInput]

    public init(
      attemptId: String,
      log: [ExerciseResultInput]
    ) {
      self.attemptId = attemptId
      self.log = log
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "attemptId": attemptId,
      "log": log
    ] }

    nonisolated struct Data: DahditGraphQLGenerated.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DahditGraphQLGenerated.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("completeLesson", CompleteLesson?.self, arguments: [
          "attemptId": .variable("attemptId"),
          "log": .variable("log")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CompleteLessonMutation.Data.self
      ] }

      var completeLesson: CompleteLesson? { __data["completeLesson"] }

      /// CompleteLesson
      ///
      /// Parent Type: `LessonResult`
      nonisolated struct CompleteLesson: DahditGraphQLGenerated.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DahditGraphQLGenerated.Objects.LessonResult }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("xpEarned", Int?.self),
          .field("newStreak", Int?.self),
          .field("unlockedLessons", [String]?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CompleteLessonMutation.Data.CompleteLesson.self
        ] }

        var xpEarned: Int? { __data["xpEarned"] }
        var newStreak: Int? { __data["newStreak"] }
        var unlockedLessons: [String]? { __data["unlockedLessons"] }
      }
    }
  }

}