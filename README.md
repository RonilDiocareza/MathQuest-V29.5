# flutter_mathquest

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- Learn Flutter
- Write your first Flutter app
- Flutter learning resources

For help getting started with Flutter development, view the online Flutter documentation, which offers tutorials, codelabs, learning resources, and a full API reference.

## Global leaderboard

The global leaderboard collection is `leaderboard`. Each document is keyed by
the Firebase Authentication UID and contains:

- `uid`
- `displayName`
- `totalScore`
- `updatedAt`

The app reads `totalScore` and legacy `totalscore` values for migration and
sorts entries by score descending. Firestore rules permit reads only for users
with an active authenticated session and do not permit client writes to the
leaderboard.

The current gameplay awards are maintained in local screen state; the
`users/{uid}` Firestore document stores progress, not the awarded score total.
Consequently, no Spark-compatible client sync or historical backfill can
currently mirror actual gameplay scores without a persisted authoritative
score source. The Admin Dashboard reports this limitation rather than
deriving scores from progress or accepting client-provided score values.

## Firestore leaderboard structure

The leaderboard collection is:

`leaderboard`

Each student's leaderboard document uses the Firebase Authentication UID as its document ID:

`leaderboard/{uid}`

Example:

```text
leaderboard
├── userUid1
│   ├── uid: "userUid1"
│   ├── displayName: "Student One"
│   ├── totalScore: 120
│   └── updatedAt: timestamp
│
├── userUid2
│   ├── uid: "userUid2"
│   ├── displayName: "Student Two"
│   ├── totalScore: 100
│   └── updatedAt: timestamp
│
└── userUid3
    ├── uid: "userUid3"
    ├── displayName: "Student Three"
    ├── totalScore: 80
    └── updatedAt: timestamp