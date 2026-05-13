/** Internal type. DO NOT USE DIRECTLY. */
type Exact<T extends { [key: string]: unknown }> = { [K in keyof T]: T[K] };
/** Internal type. DO NOT USE DIRECTLY. */
export type Incremental<T> = T | { [P in keyof T]?: P extends ' $fragmentName' | '__typename' ? T[P] : never };
export type Maybe<T> = T | null;
export type InputMaybe<T> = Maybe<T>;
/** All built-in and custom scalars, mapped to their actual values */
export type Scalars = {
  ID: { input: string; output: string; }
  String: { input: string; output: string; }
  Boolean: { input: boolean; output: boolean; }
  Int: { input: number; output: number; }
  Float: { input: number; output: number; }
  DateTime: { input: string; output: string; }
  JSON: { input: unknown; output: unknown; }
};

export type AuthPayload = {
  readonly __typename?: 'AuthPayload';
  readonly accessToken: Maybe<Scalars['String']['output']>;
  readonly refreshToken: Maybe<Scalars['String']['output']>;
  readonly user: Maybe<User>;
};

export type CompleteReviewsResult = {
  readonly __typename?: 'CompleteReviewsResult';
  readonly completedCount: Maybe<Scalars['Int']['output']>;
  readonly remainingDueCount: Maybe<Scalars['Int']['output']>;
};

export type Exercise = {
  readonly __typename?: 'Exercise';
  readonly id: Maybe<Scalars['String']['output']>;
  readonly kind: Maybe<Scalars['String']['output']>;
  readonly lessonId: Maybe<Scalars['String']['output']>;
  readonly payload: Maybe<Scalars['JSON']['output']>;
  readonly position: Maybe<Scalars['Int']['output']>;
};

export type ExerciseResultInput = {
  readonly answer: Scalars['JSON']['input'];
  readonly correct: Scalars['Boolean']['input'];
  readonly exerciseId: Scalars['String']['input'];
  readonly timeMs: Scalars['Int']['input'];
};

export type LeaderboardEntry = {
  readonly __typename?: 'LeaderboardEntry';
  readonly rank: Maybe<Scalars['Int']['output']>;
  readonly streakDays: Maybe<Scalars['Int']['output']>;
  readonly userId: Maybe<Scalars['String']['output']>;
  readonly username: Maybe<Scalars['String']['output']>;
  readonly xpTotal: Maybe<Scalars['Int']['output']>;
};

export type Lesson = {
  readonly __typename?: 'Lesson';
  readonly id: Maybe<Scalars['String']['output']>;
  readonly position: Maybe<Scalars['Int']['output']>;
  readonly skillId: Maybe<Scalars['String']['output']>;
  readonly slug: Maybe<Scalars['String']['output']>;
  readonly title: Maybe<Scalars['String']['output']>;
  readonly xpReward: Maybe<Scalars['Int']['output']>;
};

export type LessonAttempt = {
  readonly __typename?: 'LessonAttempt';
  readonly exercises: Maybe<ReadonlyArray<Exercise>>;
  readonly id: Maybe<Scalars['String']['output']>;
  readonly lessonId: Maybe<Scalars['String']['output']>;
  readonly maxHearts: Maybe<Scalars['Int']['output']>;
  readonly startedAt: Maybe<Scalars['DateTime']['output']>;
};

export type LessonResult = {
  readonly __typename?: 'LessonResult';
  readonly newStreak: Maybe<Scalars['Int']['output']>;
  readonly unlockedLessons: Maybe<ReadonlyArray<Scalars['String']['output']>>;
  readonly xpEarned: Maybe<Scalars['Int']['output']>;
};

export type Mutation = {
  readonly __typename?: 'Mutation';
  readonly completeLesson: Maybe<LessonResult>;
  readonly completeReviews: Maybe<CompleteReviewsResult>;
  readonly deleteAccount: Maybe<Scalars['Boolean']['output']>;
  readonly login: Maybe<AuthPayload>;
  readonly refreshToken: Maybe<AuthPayload>;
  readonly signup: Maybe<AuthPayload>;
  readonly startLesson: Maybe<LessonAttempt>;
};


export type MutationCompleteLessonArgs = {
  attemptId: Scalars['String']['input'];
  log: ReadonlyArray<ExerciseResultInput>;
};


export type MutationCompleteReviewsArgs = {
  results: ReadonlyArray<ReviewResultInput>;
};


export type MutationLoginArgs = {
  email: Scalars['String']['input'];
  password: Scalars['String']['input'];
};


export type MutationRefreshTokenArgs = {
  refreshToken: Scalars['String']['input'];
};


export type MutationSignupArgs = {
  email: Scalars['String']['input'];
  password: Scalars['String']['input'];
  tz?: InputMaybe<Scalars['String']['input']>;
  username: Scalars['String']['input'];
};


export type MutationStartLessonArgs = {
  lessonId: Scalars['String']['input'];
};

export type Query = {
  readonly __typename?: 'Query';
  readonly dueReviews: Maybe<ReadonlyArray<ReviewCard>>;
  readonly leaderboard: Maybe<ReadonlyArray<LeaderboardEntry>>;
  readonly lesson: Maybe<Lesson>;
  readonly lessonExercises: Maybe<ReadonlyArray<Exercise>>;
  readonly me: Maybe<User>;
  readonly skillTree: Maybe<SkillTree>;
};


export type QueryDueReviewsArgs = {
  limit?: InputMaybe<Scalars['Int']['input']>;
};


export type QueryLeaderboardArgs = {
  limit?: InputMaybe<Scalars['Int']['input']>;
};


export type QueryLessonArgs = {
  id: Scalars['String']['input'];
};


export type QueryLessonExercisesArgs = {
  lessonId: Scalars['String']['input'];
};

export type ReviewCard = {
  readonly __typename?: 'ReviewCard';
  readonly cardKey: Maybe<Scalars['String']['output']>;
  readonly dueOn: Maybe<Scalars['String']['output']>;
  readonly ease: Maybe<Scalars['Float']['output']>;
  readonly intervalDays: Maybe<Scalars['Int']['output']>;
};

export type ReviewResultInput = {
  readonly cardKey: Scalars['String']['input'];
  readonly grade: Scalars['String']['input'];
};

export type Skill = {
  readonly __typename?: 'Skill';
  readonly description: Maybe<Scalars['String']['output']>;
  readonly id: Maybe<Scalars['String']['output']>;
  readonly position: Maybe<Scalars['Int']['output']>;
  readonly prereqIds: Maybe<ReadonlyArray<Scalars['String']['output']>>;
  readonly slug: Maybe<Scalars['String']['output']>;
  readonly title: Maybe<Scalars['String']['output']>;
};

export type SkillTree = {
  readonly __typename?: 'SkillTree';
  readonly lessons: Maybe<ReadonlyArray<Lesson>>;
  readonly skills: Maybe<ReadonlyArray<Skill>>;
  readonly unlockedLessonIds: Maybe<ReadonlyArray<Scalars['String']['output']>>;
  readonly unlockedSkillIds: Maybe<ReadonlyArray<Scalars['String']['output']>>;
};

export type User = {
  readonly __typename?: 'User';
  readonly email: Maybe<Scalars['String']['output']>;
  readonly id: Maybe<Scalars['String']['output']>;
  readonly stats: Maybe<UserStats>;
  readonly tz: Maybe<Scalars['String']['output']>;
  readonly username: Maybe<Scalars['String']['output']>;
};

export type UserStats = {
  readonly __typename?: 'UserStats';
  readonly hearts: Maybe<Scalars['Int']['output']>;
  readonly heartsRefillAt: Maybe<Scalars['DateTime']['output']>;
  readonly streakDays: Maybe<Scalars['Int']['output']>;
  readonly xpTotal: Maybe<Scalars['Int']['output']>;
};

export type ExerciseResultInput = {
  readonly answer: unknown;
  readonly correct: boolean;
  readonly exerciseId: string;
  readonly timeMs: number;
};

export type ReviewResultInput = {
  readonly cardKey: string;
  readonly grade: string;
};

export type SignupMutationVariables = Exact<{
  email: string;
  username: string;
  password: string;
  tz: string | null | undefined;
}>;


export type SignupMutation = { readonly signup: { readonly accessToken: string | null, readonly refreshToken: string | null, readonly user: { readonly id: string | null, readonly email: string | null, readonly username: string | null, readonly tz: string | null } | null } | null };

export type LoginMutationVariables = Exact<{
  email: string;
  password: string;
}>;


export type LoginMutation = { readonly login: { readonly accessToken: string | null, readonly refreshToken: string | null, readonly user: { readonly id: string | null, readonly email: string | null, readonly username: string | null, readonly tz: string | null } | null } | null };

export type RefreshTokenMutationVariables = Exact<{
  refreshToken: string;
}>;


export type RefreshTokenMutation = { readonly refreshToken: { readonly accessToken: string | null, readonly refreshToken: string | null, readonly user: { readonly id: string | null, readonly email: string | null, readonly username: string | null, readonly tz: string | null } | null } | null };

export type DeleteAccountMutationVariables = Exact<{ [key: string]: never; }>;


export type DeleteAccountMutation = { readonly deleteAccount: boolean | null };

export type MeQueryVariables = Exact<{ [key: string]: never; }>;


export type MeQuery = { readonly me: { readonly id: string | null, readonly email: string | null, readonly username: string | null, readonly tz: string | null, readonly stats: { readonly xpTotal: number | null, readonly streakDays: number | null, readonly hearts: number | null, readonly heartsRefillAt: string | null } | null } | null };

export type LeaderboardQueryVariables = Exact<{
  limit: number | null | undefined;
}>;


export type LeaderboardQuery = { readonly leaderboard: ReadonlyArray<{ readonly userId: string | null, readonly username: string | null, readonly xpTotal: number | null, readonly streakDays: number | null, readonly rank: number | null }> | null };

export type StartLessonMutationVariables = Exact<{
  lessonId: string;
}>;


export type StartLessonMutation = { readonly startLesson: { readonly id: string | null, readonly lessonId: string | null, readonly startedAt: string | null, readonly maxHearts: number | null, readonly exercises: ReadonlyArray<{ readonly id: string | null, readonly lessonId: string | null, readonly kind: string | null, readonly position: number | null, readonly payload: unknown }> | null } | null };

export type CompleteLessonMutationVariables = Exact<{
  attemptId: string;
  log: ReadonlyArray<ExerciseResultInput> | ExerciseResultInput;
}>;


export type CompleteLessonMutation = { readonly completeLesson: { readonly xpEarned: number | null, readonly newStreak: number | null, readonly unlockedLessons: ReadonlyArray<string> | null } | null };

export type DueReviewsQueryVariables = Exact<{
  limit: number | null | undefined;
}>;


export type DueReviewsQuery = { readonly dueReviews: ReadonlyArray<{ readonly cardKey: string | null, readonly ease: number | null, readonly intervalDays: number | null, readonly dueOn: string | null }> | null };

export type CompleteReviewsMutationVariables = Exact<{
  results: ReadonlyArray<ReviewResultInput> | ReviewResultInput;
}>;


export type CompleteReviewsMutation = { readonly completeReviews: { readonly completedCount: number | null, readonly remainingDueCount: number | null } | null };

export type SkillTreeQueryVariables = Exact<{ [key: string]: never; }>;


export type SkillTreeQuery = { readonly skillTree: { readonly unlockedSkillIds: ReadonlyArray<string> | null, readonly unlockedLessonIds: ReadonlyArray<string> | null, readonly skills: ReadonlyArray<{ readonly id: string | null, readonly slug: string | null, readonly title: string | null, readonly description: string | null, readonly position: number | null, readonly prereqIds: ReadonlyArray<string> | null }> | null, readonly lessons: ReadonlyArray<{ readonly id: string | null, readonly skillId: string | null, readonly slug: string | null, readonly title: string | null, readonly position: number | null, readonly xpReward: number | null }> | null } | null };
