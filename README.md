# GuildLeaveSnark

A World of Warcraft addon that automatically posts snarky messages to guild chat when someone leaves or gets kicked from your guild. Because sometimes you need to say what everyone's thinking.

## Features

- **Automatic Detection**: Monitors guild roster and detects when members leave or get kicked
- **40+ Built-in Snarky Quotes**: Separate pools for voluntary leaves vs guild kicks
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
/gls test <name>    - Test with a fake name (e.g., /gls test Bob)
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
- Includes channel cycling button, rank filter input, and color input
- Includes a "Send Test" button to preview output quickly

### Managing Quotes

```
/gls list                       - Display all available quotes (leave and kick)
/gls addleave <your quote>      - Add a custom quote for voluntary leaves
/gls addkick <your quote>       - Add a custom quote for guild kicks
/gls removeleave <number>       - Remove leave quote by number (from /gls list)
/gls removekick <number>        - Remove kick quote by number (from /gls list)
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

The addon has **separate quote pools** for voluntary leaves and guild kicks, so you can tailor the tone appropriately:

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
- Test your quote: `/gls test SomePlayer`
- Remove quotes you don't like: `/gls removeleave 5` or `/gls removekick 3`

## Built-in Quotes

The addon comes with **25 leave quotes** and **15 kick quotes**, including:

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
- And 10 more...

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
A: Both! It detects "has left the guild" (voluntary) and "has been kicked out of the guild by" (forced removal).

**Q: Does this work for all languages?**  
A: It parses English system messages ("has left" / "has been kicked out"). For non-English clients, the addon still updates its roster tracking but may not trigger automatically.

**Q: Can I disable it temporarily?**  
A: Yes! `/gls off` to disable, `/gls on` to re-enable.

**Q: Can I configure it without slash commands?**  
A: Yes. Use the minimap button to open the visual options window.

**Q: Can I filter output by guild rank?**  
A: Yes. Use `/gls rank all` for everyone, or `/gls rank <index>` where `0=GM` and larger numbers are lower ranks.

**Q: What if multiple people leave at once?**  
A: The 10-second throttle prevents spam. Only one message will fire.

**Q: Can I use this for other channels besides guild?**  
A: Yes! `/gls channel say` (or party/raid) to broadcast your snark elsewhere. Not recommended for random pugs.

**Q: How do I remove a quote I don't like?**  
A: Use `/gls list` to see all quotes with numbers, then `/gls removeleave <number>` or `/gls removekick <number>` to remove it.

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
- If it doesn't match "has been kicked out of the guild by", the server may use different text
- Report the exact message format for a fix

**"I see an error about 'match'"**
- This has been fixed in the latest version. Make sure you have the updated files.

## Credits

Created for players who believe every guild departure deserves commentary.

## License

Do whatever you want with it. Add more snark. Remove snark. Share it. Modify it. We don't care.

---

*Remember: With great snark comes great responsibility. Use wisely.*
