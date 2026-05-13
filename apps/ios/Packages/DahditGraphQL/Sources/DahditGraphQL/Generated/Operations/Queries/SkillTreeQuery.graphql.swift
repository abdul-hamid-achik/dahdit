// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension DahditGraphQLGenerated {
  nonisolated struct SkillTreeQuery: GraphQLQuery {
    static let operationName: String = "SkillTree"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query SkillTree { skillTree { __typename unlockedSkillIds unlockedLessonIds skills { __typename id slug title description position prereqIds } lessons { __typename id skillId slug title position xpReward } } }"#
      ))

    public init() {}

    nonisolated struct Data: DahditGraphQLGenerated.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DahditGraphQLGenerated.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("skillTree", SkillTree?.self),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SkillTreeQuery.Data.self
      ] }

      var skillTree: SkillTree? { __data["skillTree"] }

      /// SkillTree
      ///
      /// Parent Type: `SkillTree`
      nonisolated struct SkillTree: DahditGraphQLGenerated.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DahditGraphQLGenerated.Objects.SkillTree }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("unlockedSkillIds", [String]?.self),
          .field("unlockedLessonIds", [String]?.self),
          .field("skills", [Skill]?.self),
          .field("lessons", [Lesson]?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SkillTreeQuery.Data.SkillTree.self
        ] }

        var unlockedSkillIds: [String]? { __data["unlockedSkillIds"] }
        var unlockedLessonIds: [String]? { __data["unlockedLessonIds"] }
        var skills: [Skill]? { __data["skills"] }
        var lessons: [Lesson]? { __data["lessons"] }

        /// SkillTree.Skill
        ///
        /// Parent Type: `Skill`
        nonisolated struct Skill: DahditGraphQLGenerated.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { DahditGraphQLGenerated.Objects.Skill }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", String?.self),
            .field("slug", String?.self),
            .field("title", String?.self),
            .field("description", String?.self),
            .field("position", Int?.self),
            .field("prereqIds", [String]?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            SkillTreeQuery.Data.SkillTree.Skill.self
          ] }

          var id: String? { __data["id"] }
          var slug: String? { __data["slug"] }
          var title: String? { __data["title"] }
          var description: String? { __data["description"] }
          var position: Int? { __data["position"] }
          var prereqIds: [String]? { __data["prereqIds"] }
        }

        /// SkillTree.Lesson
        ///
        /// Parent Type: `Lesson`
        nonisolated struct Lesson: DahditGraphQLGenerated.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { DahditGraphQLGenerated.Objects.Lesson }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", String?.self),
            .field("skillId", String?.self),
            .field("slug", String?.self),
            .field("title", String?.self),
            .field("position", Int?.self),
            .field("xpReward", Int?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            SkillTreeQuery.Data.SkillTree.Lesson.self
          ] }

          var id: String? { __data["id"] }
          var skillId: String? { __data["skillId"] }
          var slug: String? { __data["slug"] }
          var title: String? { __data["title"] }
          var position: Int? { __data["position"] }
          var xpReward: Int? { __data["xpReward"] }
        }
      }
    }
  }

}