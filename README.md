# GuildLeaveSnark

A Turtle WoW addon that automatically posts snarky messages to guild chat when someone leaves your guild. Because sometimes you need to say what everyone's thinking.

## Features

- **Automatic Detection**: Monitors guild roster and detects when members leave
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
```

### Managing Quotes

```
/gls list                    - Display all available quotes
/gls add <your quote here>   - Add a custom snarky comment
```

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
- **Throttle**: 10 seconds between messages

## FAQ

**Q: Will this get me gkicked?**  
A: Possibly. Choose your guild wisely.

**Q: Does this work for all languages?**  
A: It parses English system messages but has a fallback roster-diff system that works regardless of client language.

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

**"I see an error about 'match'"**
- This has been fixed in the latest version. Make sure you have the updated files.

## Credits

Created for players who believe every guild departure deserves commentary.

## License

Do whatever you want with it. Add more snark. Remove snark. Share it. Modify it. We don't care.

---

*Remember: With great snark comes great responsibility. Use wisely.*
