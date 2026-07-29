# NumberFormat

Luau utilities for formatting numbers, currency, and time — and parsing them back into numbers.

A pure-Luau port of [`@rbxts/formatting`](https://github.com/R-unic/rbx-formatting) (originally written for roblox-ts), rewritten for plain Luau/Wally projects.

## Installation

Add to your `wally.toml`:

```toml
[dependencies]
NumberFormat = "hollower233/numberformat@0.1.0"
```

Then run:

```bash
wally install
```

## API

### Number formatting

```lua
local NumberFormat = require(ReplicatedStorage.Packages.NumberFormat)

NumberFormat.commaFormat(1000000) --> "1,000,000"
NumberFormat.abbreviate(1000000) --> "1M"
NumberFormat.abbreviate(1000000000000000000) --> "1Qt"
NumberFormat.parseAbbreviated("1B") --> 1000000000
```

- `commaFormat(n: number | string, minimum: number?, separator: string?, decimal: string?): string`
  Places commas (or a custom separator) between every three digits.
- `abbreviate(n: number, threshold: number?, suffixes: {string}?): string`
  Abbreviates numbers at or above `threshold` (default `1000`) using suffixes like `K`, `M`, `B`, ...
- `parseAbbreviated(suffixed: string, suffixes: {string}?): number`
  Parses a string produced by `abbreviate()` back into a number.

### Time formatting

```lua
NumberFormat.toSeconds("10m 20s") --> 620
NumberFormat.toRemainingTime(310) --> "5m 10s"
NumberFormat.toLongRemainingTime(3690) --> "01:01:30"
```

- `toSeconds(time: string): number`
  Converts a time string (e.g. `"1h 5m"`) into seconds.
- `toRemainingTime(seconds: number, secondsFormat: string?, minutesFormat: string?, hoursFormat: string?, daysFormat: string?): string`
  Converts seconds into a short remaining-time string.
- `toLongRemainingTime(seconds: number): string`
  Converts seconds into an `HH:MM:SS` string.

## License

MIT
