# Starship Prompt — Color Reference

Source: `modules/shared/config/starship.toml`
Palette: `gruvbox_dark`

---

## Palette

| Name           | Hex       | Role                        |
|----------------|-----------|-----------------------------|
| `color_fg0`    | `#fbf1c7` | Text foreground (cream)     |
| `color_bg1`    | `#3c3836` | Dark segment background     |
| `color_bg3`    | `#665c54` | Mid-dark segment background |
| `color_orange` | `#d65d0e` | OS / username segment       |
| `color_yellow` | `#d79921` | Directory segment           |
| `color_aqua`   | `#689d6a` | Git segment                 |
| `color_blue`   | `#458588` | Language/runtime segment    |
| `color_purple` | `#b16286` | AWS segment                 |
| `color_green`  | `#98971a` | Success prompt character    |
| `color_red`    | `#cc241d` | Error prompt character      |

---

## Segment Styles

| Segment                        | Background  | Foreground  | Notes                                         |
|--------------------------------|-------------|-------------|-----------------------------------------------|
| `os`                           | `#d65d0e`   | `#fbf1c7`   |                                               |
| `username`                     | `#d65d0e`   | `#fbf1c7`   |                                               |
| `directory`                    | `#d79921`   | `#fbf1c7`   | Truncated to 3 components, symbol `…/`        |
| `git_branch`                   | `#689d6a`   | `#fbf1c7`   | Truncated to 25 chars                         |
| `git_status`                   | `#689d6a`   | `#fbf1c7`   |                                               |
| `c`, `cpp`, `rust`, `golang`   | `#458588`   | `#fbf1c7`   | Language version segments; nodejs disabled    |
| `php`, `java`, `kotlin`        | `#458588`   | `#fbf1c7`   |                                               |
| `haskell`, `python`            | `#458588`   | `#fbf1c7`   |                                               |
| `aws`                          | `#b16286`   | `#fbf1c7`   | Shows profile and region                      |
| `docker_context`               | `#665c54`   | `#83a598`   | Hardcoded fg `#83a598` (gruvbox bright-blue)  |
| `conda`                        | `#665c54`   | `#83a598`   | Hardcoded fg `#83a598`                        |
| `pixi`                         | `#665c54`   | `#fbf1c7`   |                                               |
| `time`                         | `#3c3836`   | `#fbf1c7`   | Disabled                                      |

---

## Separator Colors (Powerline arrows)

Each `` separator transitions between adjacent segment backgrounds. The arrow takes `fg` = outgoing segment color and `bg` = incoming segment color.

| Position                          | Arrow fg (`color_*`) | Arrow fg hex | Arrow bg (`color_*`) | Arrow bg hex |
|-----------------------------------|----------------------|--------------|----------------------|--------------|
| Start of prompt                   | none                 | —            | `color_orange`       | `#d65d0e`    |
| orange → yellow                   | `color_orange`       | `#d65d0e`    | `color_yellow`       | `#d79921`    |
| yellow → aqua                     | `color_yellow`       | `#d79921`    | `color_aqua`         | `#689d6a`    |
| aqua → blue                       | `color_aqua`         | `#689d6a`    | `color_blue`         | `#458588`    |
| blue → purple                     | `color_blue`         | `#458588`    | `color_purple`       | `#b16286`    |
| purple → bg3                      | `color_purple`       | `#b16286`    | `color_bg3`          | `#665c54`    |
| bg3 → bg1                         | `color_bg3`          | `#665c54`    | `color_bg1`          | `#3c3836`    |
| End (bg1 → terminal)              | `color_bg1`          | `#3c3836`    | none                 | —            |

---

## Visual Prompt Flow

```
[orange #d65d0e]  [yellow #d79921]  [aqua #689d6a]  [blue #458588]  [purple #b16286]  [bg3 #665c54]  [bg1 #3c3836]
  OS  username     directory          git branch/status  lang versions    aws             docker/conda     time*
```

Line 2 (new line):
```
❯  (green #98971a on success, red #cc241d on error)
```

`*` `time` segment is disabled in current config.

---

## Anomalies / Hardcoded Values

- `docker_context` and `conda` foreground is `#83a598` (gruvbox bright-blue), not a palette variable — it is hardcoded in the format string.
- All other segments use `color_fg0` (`#fbf1c7`) as foreground text.
