# auto-farm

Roblox auto farm script (quests, dungeons, Tower, bosses, gear goals).

## Run once (any executor, PC or phone)

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/thanasankiminoto-art/auto-farm/main/auto_farm.lua"))()
```

## Start by itself every time

Put `auto_farm_start.lua` in your executor's auto-execute folder.
It presses Play on the start screen and downloads the newest version on every game start,
so every computer gets updates without copying files.

Settings are saved per account on each device (`auto_farm_state_<UserId>.json` in the executor workspace).
