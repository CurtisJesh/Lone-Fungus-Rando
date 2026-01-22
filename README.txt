You will need to download Auto Hotkey 2 (https://github.com/AutoHotkey/AutoHotkey/releases) to use this script.

This was largely made using AI. It is functional however and I put a lot of work into it, but I want to be transparent on that point.

This is a macro. I was unable to make changes to the game itself, so it uses the console commands to get around that. DO NOT PRESS KEYS AFTER YOU PRESS A MACRO BUTTON! It could mess up the rando.

It should open the game when running the script and should close with the game, but if it doesn't you'll have to do both manually. I was unable to find out why it is inconsistent.

DO NOT PICKUP ITEMS NORMALLY! The macro has no way of tracking this, so don't actually touch an ability or spell. The only exception is picking back up and ability after fighting a boss. If you accidentally pickup up a non-boss ability and want to remove it, see the help section.

The keybinds are as follows:
-9: Gives a random item from the MAIN POOL. This can be ANY item the macro didn't already give you though upgrades to items can only be gotten after the base item (i.e. fire bounce after spin). It can only give spells and abilities as the game has no way of randomizing other items.

-8: Gives an item based on simple Logic. Unless you use the full StartKit, use this until you get out of the first area.

-7: Gives the StartKit (sword, parry, & heal). If you press it a second time it also gives the Mushmover and Mushmover Infusion. Do this instead of normally picking them up as if you do the first 3 pickups normally the macro may try to give you these items.

-0: This key pulls up a menu to remove a boss item. After beating a boss, you'll have to pick up the item to leave, but simply remove it with this and then give yourself a new random item. 
Bosses do not appear unless you don't have the item they give. This pulls up a menu to let you pick a boss to revive. You will have to do the fight without that item. After you win, pick back up the item normally then give yourself a new random item. If you give up on a boss, look at the help section down below.

-6: Swaps between variable and set dash height. Variable dash height is required for some skips, but if you don't like playing with it always on, here this is! 

-F9: Reset the pools. THE RANDO HAS PERSCISTANCE meaning this program will remember what items it has given you even after it is closed. Press F9 to reset the rando to starting conditions. (Don't worry, there is a confirmation popup)

-F10: Close the program. The macro should stop when the game is closed, but just in case, here is the kill-switch.



Tips Section:

You can make the rando a desktop shortcut.

When starting a game think about making it room respawn instead of shrine respawn. This is very nice QOL.



HELP Section:

Ever find yourself stuck with no possible items to get? 
Get a loan! Give yourself a new item (or two) now and just don't for the next pickup(s). It's not a bug, it's a feature!

If you want to do this with multiple saves, simply rename the "given_items" document to something else (like givenitems#1) then change it back when you want to play that save again. 

If you give up on a boss or accidentally picked up an item, you'll have to manually give/remove the item. To do this look here: https://lone-fungus.fandom.com/wiki/Console_Commands. After you do that, close the game and reopen it. This prevents further problems down the line.