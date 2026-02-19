# GuildLeaveSnark

A World of Warcraft addon that automatically posts snarky messages to guild chat when someone leaves, gets kicked, gets promoted, or gets demoted. Because sometimes you need to say what everyone's thinking.

## Features

- **Automatic Detection**: Detects leaves, kicks, promotions, and demotions from guild system messages
- **60+ Built-in Snarky Quotes**: Separate pools for leave, kick, promotion, and demotion events
- **Visual Options Window**: Configure settings in-game without typing commands
- **Minimap Button**: Click to open options, drag to reposition around minimap
- **Rank Filter**: Restrict output by guild rank index (e.g., only lower ranks)
- **Customizable**: Add your own quotes and remove unwanted ones
- **Smart Throttling**: 10-second cooldown prevents spam during mass exodus events
- **Flexible Output**: Post to guild, say, party, or raid chat
- **Optional Name Prefix**: Choose between "Bob: Another one bites dust" or just "Another one bites dust"

## Installation

1. Download or clone this addon
2. Place the entire `GuildLeaveSnark` folder into your WoW addons directory:
   ```
   <WoW Installation>/Interface/AddOns/GuildLeaveSnark
   ```
3. Restart WoW or type `/reload` in-game
4. You should see "GuildLeaveSnark loaded. /gls for options" in your chat

## Usage

### Basic Commands

```
/gls help           - Show all commands
/gls on             - Enable the addon
/gls off            - Disable the addon
/gls ui             - Toggle the visual options window
/gls testmode       - Show current test mode
/gls testmode <mode>- Set test mode: leave|kick|promote|demote
/gls test <name>    - Send a quick leave test with a fake name
```

### Configuration

```
/gls channel <type>      - Set output channel: guild|say|party|raid
/gls prefix on|off       - Toggle name prefix (e.g., "Name: quote")
/gls color <hex>         - Set message color (e.g., ff9900 for orange, ff0000 for red)
/gls rank all|<index>    - Set rank filter (0=GM, larger number=lower rank)
/gls debug on|off        - Enable debug mode (shows all system messages)
```

### Visual Interface (Minimap Button)

- Left-click the minimap button to open/close the options window
- Drag the minimap button to move it around the minimap
- Options window includes toggles for Enabled / Prefix / Debug
- Includes channel cycling button, rank filter input, and color picker
- Includes dedicated quote editors for leave, kick, promotion, and demotion (one quote per line)
- Includes separate test controls: **Send Test** (send now) and **Mode** (cycle leave/kick/promote/demote)

### Managing Quotes

```
/gls list                       - Display all available quotes (leave, kick, promotion, demotion)
/gls add <your quote>           - Alias for /gls addleave
/gls addleave <your quote>      - Add a custom quote for voluntary leaves
/gls addkick <your quote>       - Add a custom quote for guild kicks
/gls addpromotion <your quote>  - Add a custom quote for promotions
/gls adddemotion <your quote>   - Add a custom quote for demotions
/gls removeleave <number>       - Remove leave quote by number (from /gls list)
/gls removekick <number>        - Remove kick quote by number (from /gls list)
/gls removepromotion <number>   - Remove promotion quote by number (from /gls list)
/gls removedemotion <number>    - Remove demotion quote by number (from /gls list)
/gls clear                      - Restore all default quotes
```

### Customizing Colors

Change the message color to match your guild's style:

```
/gls color ff9900    - Orange (default)
/gls color ff0000    - Red
/gls color 00ff00    - Green
/gls color ffff00    - Yellow
/gls color ff00ff    - Magenta
/gls color 00ffff    - Cyan
/gls color ffffff    - White
```

You can use any 6-digit hex color code (with or without the `#` prefix).

## Adding Snarky Comments

The addon has **separate quote pools** for leave, kick, promotion, and demotion events, so you can tailor the tone appropriately.

You can edit each pool directly in the options popup:
- Leave quotes (one quote per line)
- Kick quotes (one quote per line)
- Promotion quotes (one quote per line)
- Demotion quotes (one quote per line)

**For Voluntary Leaves (they chose to go):**
```
/gls addleave They left for a "better" guild. Narrator: There wasn't one.
/gls addleave Off to touch grass.
/gls addleave Gone but not mourned.
/gls addleave The guild bank thanks them for their service.
```

**For Guild Kicks (they were shown the door):**
```
/gls addkick Promoted to "not our problem" rank.
/gls addkick Another victim of the guild bank tax.
/gls addkick Don't let the guild hall door hit you.
/gls addkick They were politely asked to leave. Results may vary.
```

**Pro Tips for Maximum Snark:**
- Keep it short and punchy
- Reference common WoW situations (wipes, loot drama, etc.)
- Balance humor with not being genuinely toxic
- Use different tones for kicks vs leaves
- Test quickly with slash commands: `/gls testmode promote` then `/gls test SomePlayer`
- Test from UI: pick **Mode** then click **Send Test**
- Remove quotes you don't like: `/gls removeleave 5`, `/gls removekick 3`, `/gls removepromotion 2`, `/gls removedemotion 4`

## Built-in Quotes

The addon comes with built-in quote pools for leave, kick, promotion, and demotion events, including:

**Leave Quotes:**
- "Another one returns to the wild."
- "Real life crit again."
- "Gone like a ninja."
- "They left mid-buff. Classic."
- "New guild, same wipes."
- "Press F. Or dont."
- And 19 more...

**Kick Quotes:**
- "Promoted to ex-member."
- "The trash took itself out."
- "Justice has been served."
- "Performance review: Failed."
- "Turns out actions have consequences."

**Promotion Quotes:**
- "A surprise promotion appears."
- "Grats on the new permissions."
- "Rank up achieved. Try not to abuse it."

**Demotion Quotes:**
- "Gravity works on guild ranks too."
- "Performance review was... brief."
- "Permissions have left the party."

## Default Settings

- **Enabled**: Yes
- **Channel**: Guild chat
- **Name Prefix**: Enabled (shows "PlayerName: quote")
- **Rank Filter**: All ranks
- **Color**: Orange (#ff9900)
- **Throttle**: 10 seconds between messages

## FAQ

**Q: Will this get me gkicked?**  
A: Possibly. Choose your guild wisely.

**Q: Does this work for guild kicks or just voluntary leaves?**  
A: It supports all four: leave, kick, promotion, and demotion (English system message parsing).

**Q: Does this work for all languages?**  
A: It parses English system messages ("has left" / "has been kicked out"). For non-English clients, the addon still updates its roster tracking but may not trigger automatically.

**Q: Can I disable it temporarily?**  
A: Yes! `/gls off` to disable, `/gls on` to re-enable.

**Q: Can I configure it without slash commands?**  
A: Yes. Use the minimap button to open the visual options window.

**Q: Can I filter output by guild rank?**  
A: Yes. Use `/gls rank all` for everyone, or `/gls rank <index>` where `0=GM` and larger numbers are lower ranks.

**Q: How do I test kick/promotion/demotion quotes quickly?**  
A: Use `/gls testmode leave|kick|promote|demote` to set mode for the UI test button, then click **Send Test** in the options window. (`/gls test <name>` is a quick leave-test slash command.)

**Q: What if multiple people leave at once?**  
A: The 10-second throttle prevents spam. Only one message will fire.

**Q: Can I use this for other channels besides guild?**  
A: Yes! `/gls channel say` (or party/raid) to broadcast your snark elsewhere. Not recommended for random pugs.

**Q: How do I remove a quote I don't like?**  
A: Use `/gls list` to see all quotes with numbers, then remove by pool: `/gls removeleave`, `/gls removekick`, `/gls removepromotion`, or `/gls removedemotion`.

**Q: Can I reset to default quotes?**  
A: Yes! `/gls clear` removes all custom quotes and restores the defaults.

## Troubleshooting

**"Nothing happens when someone leaves"**
- Check if addon is enabled: `/gls on`
- Verify your guild chat permissions
- Make sure you're actually in a guild
- Check rank filter: `/gls rank` (or set `/gls rank all`)
- Enable debug mode to see system messages: `/gls debug on`

**"I can't find the options window"**
- Click the minimap button to toggle the UI
- Or run `/gls ui`
- If needed, `/reload` to reinitialize UI elements

**"Guild kicks aren't triggering the addon"**
- Enable debug mode: `/gls debug on`
- Kick someone and check what message appears
- If it doesn't match known kick wording, the server may use different text
- Report the exact message format for a fix

**"I see an error about 'match'"**
- This has been fixed in the latest version. Make sure you have the updated files.

## Credits

Created for players who believe every guild departure deserves commentary.

## License

Do whatever you want with it. Add more snark. Remove snark. Share it. Modify it. We don't care.

---

*Remember: With great snark comes great responsibility. Use wisely.*
