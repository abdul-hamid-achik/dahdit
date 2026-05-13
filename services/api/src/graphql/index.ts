import './types/objects'
import './queries/me'
import './queries/skillTree'
import './queries/lesson'
import './queries/leaderboard'
import './queries/reviews'
import './mutations/auth'
import './mutations/lessons'
import './mutations/reviews'
import { builder } from './builder'

export const schema = builder.toSchema()
