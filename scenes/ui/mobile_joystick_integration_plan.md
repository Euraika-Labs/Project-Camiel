# Mobile Touch Overlay — Integration Plan for `main.tscn`

## Overview

The mobile controller lives in a **CanvasLayer** that is added to `main.tscn` as a
top-level child (sibling to `Camiel`, `UI`, `GameHUD`, etc.). The CanvasLayer is
shown only on devices with a touchscreen (`DisplayServer.is_touchscreen_available()`);
desktop players see nothing extra.

---

## Step 1 — Register the Autoload

In **Project Settings → Autoload**, add a new entry:

| Field | Value |
|-------|-------|
| Path | `res://scripts/mobile_controller.gd` |
| Name  | `MobileController` |

> The autoload script (`MobileController`) owns the **TouchLayer** and **ActionLayer**
> CanvasLayers. It is the single source of truth for all mobile input.
> `main.tscn` does **not** need any script on the CanvasLayer node itself.

---

## Step 2 — Add the CanvasLayer to `main.tscn`

Open `main.tscn` in the Godot editor and add a new top-level node:

```
Node2D
└── Main (script: intro_scene.gd)
    ├── Sky, Ground, Platform, …
    ├── Camiel
    ├── Camera2D
    ├── UI (CanvasLayer)
    ├── GameHUD (CanvasLayer)
    ├── WinLayer (CanvasLayer)
    └── MobileTouch (CanvasLayer)     ← NEW
 ├── TouchLayer (CanvasLayer)  ← child of MobileTouch
        │   └── MobileJoystick (scene instance: res://scenes/ui/mobile_joystick.tscn)
        └── ActionLayer (CanvasLayer) ← child of MobileTouch
 └── (buttons are inside mobile_joystick.tscn already)
```

**If you prefer to keep the joystick scene separate**, you can add the scene
instance directly as a child of `MobileTouch` instead of nesting it under
`TouchLayer`. The key requirement is that the node path used in
`mobile_controller.gd`'s `@onready` vars (`$TouchLayer`, `$ActionLayer`) matches
the actual scene tree.

**Simplest integration** — paste this at the end of `main.tscn` (before the
`[connection]` block):

```
[node name="MobileTouch" type="CanvasLayer" parent="."]

[node name="TouchLayer" type="CanvasLayer" parent="MobileTouch"]

[node name="JoystickArea" type="Control" parent="MobileTouch/TouchLayer"]
anchors_preset = 2
anchor_top = 1.0
anchor_bottom = 1.0
offset_left = 24.0
offset_top = -280.0
offset_right = 280.0
offset_bottom = -24.0
grow_vertical = 0

[node name="Base" type="Panel" parent="MobileTouch/TouchLayer/JoystickArea"]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -100.0
offset_top = -100.0
offset_right = 100.0
offset_bottom = 100.0
grow_horizontal = 2
grow_vertical = 2
pivot_offset = Vector2(100, 100)
mouse_filter = 2
theme_override_styles/normal = SubResource("StyleBoxFlat_joystick_base")

[node name="Tip" type="Panel" parent="MobileTouch/TouchLayer/JoystickArea/Base"]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -40.0
offset_top = -40.0
offset_right = 40.0
offset_bottom = 40.0
grow_horizontal = 2
grow_vertical = 2
pivot_offset = Vector2(40, 40)
mouse_filter = 2
theme_override_styles/normal = SubResource("StyleBoxFlat_joystick_tip")

[node name="ActionLayer" type="CanvasLayer" parent="MobileTouch"]

[node name="JumpButton" type="Button" parent="MobileTouch/ActionLayer"]
anchors_preset = 2
anchor_top = 1.0
anchor_bottom = 1.0
offset_left = -200.0
offset_top = -180.0
offset_right = -56.0
offset_bottom = -56.0
grow_vertical = 0
text = "⬆  spring"
flat = true
mouse_filter = 2

[node name="SitButton" type="Button" parent="MobileTouch/ActionLayer"]
anchors_preset = 2
anchor_top = 1.0
anchor_bottom = 1.0
offset_left = -200.0
offset_top = -310.0
offset_right = -56.0
offset_bottom = -186.0
grow_vertical = 0
text = "⬇  zitten"
flat = true
mouse_filter = 2

[node name="SleepButton" type="Button" parent="MobileTouch/ActionLayer"]
anchors_preset = 2
anchor_top = 1.0
anchor_bottom = 1.0
offset_left = -200.0
offset_top = -440.0
offset_right = -56.0
offset_bottom = -316.0
grow_vertical = 0
text = "💤  slapen"
flat = true
mouse_filter = 2
```

> **Note:** The sub-resource styleboxes (`StyleBoxFlat_joystick_base`,
> `StyleBoxFlat_joystick_tip`) must be defined in the scene's `[sub_resource]`
> block. See `scenes/ui/mobile_joystick.tscn` for the full working definition.

---

## Step 3 — Wire the InputMap actions

`camiel_controller.gd` currently uses raw `Input.is_key_pressed(KEY_*)` calls.
For mobile to work alongside keyboard, we need to either:

### Option A — Update `camiel_controller.gd` to check actions (Recommended)

Add `"jump"`, `"sit"`, `"sleep"` actions in **Project Settings → Input Map**,
then update `camiel_controller.gd` to use `Input.is_action_pressed()`:

```gdscript
## Replace _jump_pressed with:
func _jump_pressed() -> bool:
    return Input.is_key_pressed(KEY_SPACE) \
        or Input.is_key_pressed(KEY_W) \
        or Input.is_key_pressed(KEY_UP) \
        or MobileController.jump_pressed   ## ← new

## Replace _sit_pressed with:
func _sit_pressed() -> bool:
    return Input.is_key_pressed(KEY_S) \
        or Input.is_key_pressed(KEY_DOWN) \
        or MobileController.sit_pressed    ## ← new

## Replace _sleep_pressed with:
func _sleep_pressed() -> bool:
    return Input.is_key_pressed(KEY_X) \
        or MobileController.sleep_pressed   ## ← new
```

For direction, replace `_read_direction` with:

```gdscript
func _read_direction() -> int:
    var direction := 0
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) \
       or Input.is_action_pressed("ui_left"):
        direction -= 1
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) \
       or Input.is_action_pressed("ui_right"):
        direction += 1
    return direction
```

And `_run_pressed`:

```gdscript
func _run_pressed() -> bool:
    return Input.is_key_pressed(KEY_SHIFT) or MobileController.run_pressed
```

### Option B — Keep raw key reads, rely on action pumping

`mobile_controller.gd` already calls `Input.action_press()` / `Input.action_release()`
for `ui_left/right/up/down`, `jump`, `sit`, `sleep`.  If `camiel_controller.gd`
is updated to also check `Input.is_action_pressed()` (as shown above), both
keyboard and mobile work simultaneously without any changes to the existing
keyboard path.

---

## Step 4 — Project Settings for mobile

Ensure these settings are set in **Project Settings → General → Input Devices → Pointing**:

| Setting | Value | Reason |
|---------|-------|--------|
| `Emulate Touch from Mouse` | **ON** | Desktop testing of touch UI |
| `Emulate Mouse from Touch` | **OFF** | Avoid conflicts on real mobile |
| `Enable Long Press as Right Click` | **OFF** | Prevents TouchScreenButton hold issues on Android |

Add to `project.godot`:

```ini
[input_devices]

pointing/emulate_touch_from_mouse=true
pointing/emulate_mouse_from_touch=false
```

---

## Step 5 — InputMap entries

In **Project Settings → Input Map**, add these actions (all with an empty
action list — they are driven programmatically by `MobileController`):

| Action | Notes |
|--------|-------|
| `ui_left` | Already exists (keyboard arrow) |
| `ui_right` | Already exists (keyboard arrow) |
| `ui_up` | Already exists (keyboard arrow) |
| `ui_down` | Already exists (keyboard arrow) |
| `jump` | New — maps to Space/W/Up on keyboard |
| `sit` | New — maps to S/Down on keyboard |
| `sleep` | New — maps to X on keyboard |
| `run` | New — maps to Shift on keyboard |

---

## Scene hierarchy after integration

```
main (Node2D, script: intro_scene.gd)
├── Sky, Ground, Platform, LeftWall, RightWall, RedBlock, …
├── Camiel (CharacterBody2D, script: camiel_controller.gd)
├── Camera2D
├── UI (CanvasLayer) ← existing
├── GameHUD (CanvasLayer)         ← existing
├── WinLayer (CanvasLayer)        ← existing
└── MobileTouch (CanvasLayer)    ← NEW
    ├── TouchLayer (CanvasLayer)  ← NEW
    │   └── MobileJoystick        ← instanced scene or inline nodes
    └── ActionLayer (CanvasLayer) ← NEW
        └── (buttons inside MobileJoystick or inline)
```

---

## How input flows

```
Screen touch event
    │
    ▼
MobileController._input() ← autoload, always runs
    │ classifies touch → left zone (joystick) or right zone (buttons)
    │  updates MobileController.jump_pressed / touch_direction / etc.
    ▼
Input.action_press("ui_left")     ← pumps the Input map
    │
    ▼
camiel_controller.gd._physics_process()
    │  reads Input.is_action_pressed("ui_left") via updated _read_direction()
    │  OR Input.is_key_pressed(KEY_LEFT)  ← keyboard still works
    ▼
CharacterBody2D moves
```

---

## Performance notes

- `MobileController` uses `_input()` which is called only on touch events —
  no polling cost on desktop.
- `mouse_filter = 2` (`MOUSE_FILTER_IGNORE`) on all touch Control nodes ensures
  the touch events are NOT consumed by Godot's Control system — they propagate
  to `MobileController._input()` cleanly.
- Joystick math (`limit_length`, normalise) is O(1) per drag event.
- `_update_action_rects()` runs in `_process()` but only reads `get_global_rect()`
  on3 Button nodes — negligible cost.
- No custom `_draw()` or per-frame redraws; all visuals are plain `Panel` /
  `Button` nodes with stylebox overrides.

---

## Android APK export checklist

1. **Editor Settings → Export → Android**: set `Android SDK Path`
2. **Project Settings → Display → Android**: set `App Icon`, `Display Name`
3. **Project Settings → Application → Config → `version`**: set `0.0.3`
4. **Project Settings → Input Devices → Pointing**:
   - `Enable Long Press as Right Click` → **OFF**
5. Run export with the preset added in `export_presets.cfg` (see section 4)
6. Sign the APK with your keystore; test on a physical device (emulators do not
   reliably report `is_touchscreen_available`)
