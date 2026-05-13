// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

nonisolated protocol DahditGraphQLGenerated_SelectionSet: ApolloAPI.SelectionSet & ApolloAPI.RootSelectionSet
where Schema == DahditGraphQLGenerated.SchemaMetadata {}

nonisolated protocol DahditGraphQLGenerated_InlineFragment: ApolloAPI.SelectionSet & ApolloAPI.InlineFragment
where Schema == DahditGraphQLGenerated.SchemaMetadata {}

nonisolated protocol DahditGraphQLGenerated_MutableSelectionSet: ApolloAPI.MutableRootSelectionSet
where Schema == DahditGraphQLGenerated.SchemaMetadata {}

nonisolated protocol DahditGraphQLGenerated_MutableInlineFragment: ApolloAPI.MutableSelectionSet & ApolloAPI.InlineFragment
where Schema == DahditGraphQLGenerated.SchemaMetadata {}

extension DahditGraphQLGenerated {
  typealias SelectionSet = DahditGraphQLGenerated_SelectionSet

  typealias InlineFragment = DahditGraphQLGenerated_InlineFragment

  typealias MutableSelectionSet = DahditGraphQLGenerated_MutableSelectionSet

  typealias MutableInlineFragment = DahditGraphQLGenerated_MutableInlineFragment

  nonisolated enum SchemaMetadata: ApolloAPI.SchemaMetadata {
    static let configuration: any ApolloAPI.SchemaConfiguration.Type = SchemaConfiguration.self

    private static let objectTypeMap: [String: ApolloAPI.Object] = [
      "AuthPayload": DahditGraphQLGenerated.Objects.AuthPayload,
      "CompleteReviewsResult": DahditGraphQLGenerated.Objects.CompleteReviewsResult,
      "Exercise": DahditGraphQLGenerated.Objects.Exercise,
      "LeaderboardEntry": DahditGraphQLGenerated.Objects.LeaderboardEntry,
      "Lesson": DahditGraphQLGenerated.Objects.Lesson,
      "LessonAttempt": DahditGraphQLGenerated.Objects.LessonAttempt,
      "LessonResult": DahditGraphQLGenerated.Objects.LessonResult,
      "Mutation": DahditGraphQLGenerated.Objects.Mutation,
      "Query": DahditGraphQLGenerated.Objects.Query,
      "ReviewCard": DahditGraphQLGenerated.Objects.ReviewCard,
      "Skill": DahditGraphQLGenerated.Objects.Skill,
      "SkillTree": DahditGraphQLGenerated.Objects.SkillTree,
      "User": DahditGraphQLGenerated.Objects.User,
      "UserStats": DahditGraphQLGenerated.Objects.UserStats
    ]

    static func objectType(forTypename typename: String) -> ApolloAPI.Object? {
      objectTypeMap[typename]
    }
  }

  nonisolated enum Objects {}
  nonisolated enum Interfaces {}
  nonisolated enum Unions {}

}