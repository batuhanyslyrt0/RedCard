# Red Card – Design plan

## Brief
- **Subject:** a free iPhone app that keeps Turkish betting / casino SMS out of the inbox.
- **Audience:** everyday iPhone users in Turkey, many of them not technical, who get several bet SMS a day.
- **Primary job:** get the filter switched on in Settings in under a minute, and make people trust it.

## Tokens

| Name        | Light     | Dark      | Role |
|-------------|-----------|-----------|------|
| Card Red    | `#D7182A` | `#FF3D4A` | The only brand colour: the card, tint, primary buttons |
| Card Shine  | `#F2545F` | `#FF7A83` | Top-left highlight inside the card |
| Pass Green  | system green | system green | "This message passes" in the tester only |
| Surface     | system grouped background | system grouped background | Native iOS surfaces everywhere else |
| Text        | system label colours | system label colours | No custom text colours |

**Type:** SF Pro throughout. Headlines use SF Pro *Expanded* (`.fontWidth(.expanded)`) in bold, which gives the app a recognisable, sporty voice without a custom font. Body, lists and buttons stay standard SF Pro so Dynamic Type and accessibility work as Apple intends.

**Layout:** native `List` / `insetGrouped` screens. One custom element: a large, slightly tilted red card at the top of the home screen. Content is left aligned.

```
┌──────────────────────────────┐
│  Red Card                    │  expanded bold title
│                              │
│        ╱▔▔▔▔▔▔╲              │  tilted red card,
│       ╱  💬  ╱               │  message bubble cut out
│      ╱▁▁▁▁▁▁╱                │
│                              │
│  Bet SMS stay out of your    │  one plain sentence
│  inbox.                      │
│  [ Turn on the filter ]      │  only if setup not done
├──────────────────────────────┤
│  Try a message            >  │
│  Your rules               >  │
│  Strictness  Relaxed|Bal|Str │
│  Clean up old messages    >  │
│  How it works             >  │
└──────────────────────────────┘
```

## Principles
1. **Spend boldness once.** The red card is the memorable thing. Everything else is quiet, native iOS.
2. **Plain language.** No football, referee or bouncer jokes in the copy. Say what happens: "Goes to Junk", "Stays in your inbox".
3. **Honest about limits.** Apple only lets the filter see SMS from unknown senders, never lets it delete or count messages, and gives apps no way to read whether the filter is switched on. The app says this clearly instead of faking stats or a "filter is on" badge.
4. **One motion moment.** A short launch splash: the card flips up into place, the message bubble pops out of it, the name appears, then it fades into the home screen (under 2 s; no movement with Reduce Motion). Nothing else animates on its own.
5. **Own artwork only.** The bubble is drawn by hand. Apple's Messages icon and SF Symbols may not be used in an app icon.

## Review against the generic default
- A generic version would be a dark screen with a neon accent and a grid of identical rounded cards with a big "143 blocked" counter. Changed: native light/dark surfaces, a single physical object as the hero, and no fake counter (the extension cannot store counts anyway).
- No ALL-CAPS labels, no single coloured word in headlines, no numbered markers except the setup steps, which really are a sequence.
