import { builder } from '../builder'
import { UserRef } from '../types/objects'

builder.queryField('me', (t) =>
  t.field({
    type: UserRef,
    nullable: true,
    resolve: (_root, _args, ctx) => ctx.user,
  }),
)

