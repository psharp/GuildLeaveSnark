# GuildLeaveSnark

A Turtle WoW addon that automatically posts snarky messages to guild chat when someone leaves or gets kicked from your guild. Because sometimes you need to say what everyone's thinking.

## Features

- **Automatic Detection**: Monitors guild roster and detects when members leave or get kicked
- **30+ Built-in Snarky Quotes**: From subtle to savage
- **Customizable**: Add your own quotes to match your guild's personality
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
/gls test <name>    - Test with a fake name (e.g., /gls test Bob)
```

### Configuration

```
/gls channel <type>      - Set output channel: guild|say|party|raid
/gls prefix on|off       - Toggle name prefix (e.g., "Name: quote")
/gls color <hex>         - Set message color (e.g., ff9900 for orange, ff0000 for red)
/gls debug on|off        - Enable debug mode (shows all system messages)
```

### Managing Quotes

```
/gls list                    - Display all available quotes
/gls add <your quote here>   - Add a custom snarky comment
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

Want to add your own zingers? Easy:

```
/gls add They left for a "better" guild. Narrator: There wasn't one.
/gls add Promoted to "not our problem" rank.
/gls add Gone but not mourned.
/gls add Another victim of the guild bank tax.
```

**Pro Tips for Maximum Snark:**
- Keep it short and punchy
- Reference common WoW situations (wipes, loot drama, etc.)
- Balance humor with not being genuinely toxic
- Test your quote first: `/gls test SomePlayer`

## Built-in Quotes

The addon comes with 30 snarky classics including:
- "Another one returns to the wild."
- "Real life crit again."
- "Gone like a ninja."
- "They left mid-buff. Classic."
- "New guild, same wipes."
- "Press F. Or dont."
- "At least no bank heist."
- And 23 more...

## Default Settings

- **Enabled**: Yes
- **Channel**: Guild chat
- **Name Prefix**: Enabled (shows "PlayerName: quote")
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

**Q: What if multiple people leave at once?**  
A: The 10-second throttle prevents spam. Only one message will fire.

**Q: Can I use this for other channels besides guild?**  
A: Yes! `/gls channel say` (or party/raid) to broadcast your snark elsewhere. Not recommended for random pugs.

## Troubleshooting

**"Nothing happens when someone leaves"**
- Check if addon is enabled: `/gls on`
- Verify your guild chat permissions
- Make sure you're actually in a guild
- Enable debug mode to see system messages: `/gls debug on`

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
