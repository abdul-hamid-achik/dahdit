CREATE OR REPLACE FUNCTION dahdit_streak_decay()
RETURNS void
LANGUAGE sql
AS $$
  UPDATE user_stats
  SET streak_days = 0
  WHERE streak_days > 0
    AND last_active_on IS NOT NULL
    AND last_active_on < (now() AT TIME ZONE 'UTC')::date - interval '1 day';
$$;

CREATE OR REPLACE FUNCTION dahdit_hearts_refill()
RETURNS void
LANGUAGE sql
AS $$
  UPDATE user_stats
  SET
    hearts = LEAST(5, hearts + GREATEST(1, FLOOR(EXTRACT(EPOCH FROM (now() - hearts_refill_at)) / 3600)::integer + 1)),
    hearts_refill_at = CASE
      WHEN hearts + 1 >= 5 THEN NULL
      ELSE now() + interval '1 hour'
    END
  WHERE hearts < 5
    AND hearts_refill_at IS NOT NULL
    AND hearts_refill_at <= now();
$$;

CREATE OR REPLACE FUNCTION dahdit_account_purge()
RETURNS void
LANGUAGE sql
AS $$
  DELETE FROM users
  WHERE deleted_at IS NOT NULL
    AND deleted_at < now() - interval '30 days';
$$;

SELECT cron.schedule('streak_decay', '0 3 * * *', 'SELECT dahdit_streak_decay();')
WHERE NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'streak_decay');

SELECT cron.schedule('hearts_refill', '*/15 * * * *', 'SELECT dahdit_hearts_refill();')
WHERE NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'hearts_refill');

SELECT cron.schedule('account_purge', '0 4 * * *', 'SELECT dahdit_account_purge();')
WHERE NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'account_purge');

