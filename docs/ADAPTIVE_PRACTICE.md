# Adaptive practice

## Goal

Training should start quickly while still revisiting situations at useful
intervals. Curated training scenarios and private Real Life Replay cases use the
same scheduling rules, but remain separate practice pools.

The scheduler is not a performance score. It uses the existing contextual
overall signal only to choose a future review interval. Dimension signals are
never counted, averaged or converted into points.

## Review cadence

The private schedule has six internal stages:

| Stage | Next review |
| --- | --- |
| 0 | 1 day |
| 1 | 3 days |
| 2 | 7 days |
| 3 | 14 days |
| 4 | 30 days |
| 5 | 60 days |

After a completed response has schema-validated feedback:

- `focus` moves the item to stage 0.
- `developing` starts at stage 1 and later remains between stages 1 and 2;
  higher stages return to stage 2.
- `strong` starts at stage 2 and later advances one stage, up to stage 5.

The same response must never advance a schedule twice. Speech Challenge
results do not affect scenario schedules.

## Adaptive selection

Selection is random inside a learning-priority bucket:

1. Choose randomly from up to five of the longest-overdue items.
2. If nothing is due, choose a random unseen item.
3. If every item has a future date, choose randomly from the three closest
   future items so a voluntary practice start is never blocked.
4. Avoid the most recently practised item whenever another candidate exists.

Training considers only active curated scenarios in the selected app language.
Real Life Replay considers only the signed-in user's private cases. The two
pools are never mixed. Manually selected cases update the same schedule after
their feedback is saved.

## Training experience

Opening Training shows a calm preparation state, resolves one adaptive scene
and starts it automatically when audio is ready. The public scenario catalogue
is not part of the normal user flow. After feedback, the primary action starts
the next adaptive scene; repeating the same scene stays available as a
secondary action.

## Real Life Replay library

With no saved cases, opening Real Life Replay continues directly into the
voice-first capture flow. With saved cases, the entry screen shows a private
library, an adaptive random action and an action to tell a new situation.

A case becomes visible in the library only after its confirmed reconstruction
was saved. Each reconstruction is a schema-validated snapshot with a short,
non-sensitive title and model metadata. A separate snapshot is generated once
per app language and then reused. Existing cases without a snapshot are
reconstructed lazily on first use.

Similar variations remain temporary and do not become library entries.

## Privacy and audio

Schedules, cases and reconstruction snapshots are user-owned and protected by
RLS. Deleting a Real Life Replay case also deletes its snapshots and schedule.
Private scene text and audio are never placed in the shared product audio
cache.

