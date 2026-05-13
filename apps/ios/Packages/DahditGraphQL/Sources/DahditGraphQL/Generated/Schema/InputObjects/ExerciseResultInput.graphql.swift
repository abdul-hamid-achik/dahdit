// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

extension DahditGraphQLGenerated {
  nonisolated struct ExerciseResultInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      answer: JSON,
      correct: Bool,
      exerciseId: String,
      timeMs: Int32
    ) {
      __data = InputDict([
        "answer": answer,
        "correct": correct,
        "exerciseId": exerciseId,
        "timeMs": timeMs
      ])
    }

    var answer: JSON {
      get { __data["answer"] }
      set { __data["answer"] = newValue }
    }

    var correct: Bool {
      get { __data["correct"] }
      set { __data["correct"] = newValue }
    }

    var exerciseId: String {
      get { __data["exerciseId"] }
      set { __data["exerciseId"] = newValue }
    }

    var timeMs: Int32 {
      get { __data["timeMs"] }
      set { __data["timeMs"] = newValue }
    }
  }

}