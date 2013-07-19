# mwsload

###rapid input of MTG card names for quickly creating decks from clipboard in Magic Workstation

#### Background

I love [MWS](http://www.magicworkstation.com/) for creating and analyzing decks. It is a great tool that I've used for years. 

But when I went to put my absolutely gigantic [Type4](http://www.wizards.com/magic/magazine/Article.aspx?x=mtgcom/feature/198) pile into the deckbuilder I noticed that it wasn't very streamlined for adding cards quickly, in rapid succession.

MWS does fine finding the card as characters are entered into the search box, most cards don't usually require more than a handful of keystrokes. *But...* 

After adding the selected card to the deck, the user must (*slowly*) backspace or click the search box and delete the card's name. No Ctrl+a and delete. No auto-clear. Just frustrating when one has hundreds of cards to input!

#### Synopsis

**mwsload** is a perl script which takes short, quick user input to create a deck listing file (text) which can be copied and loaded directly from the clipboard into a MWS deck using `Tools->Paste Deck from Clipboard` 

#### Simple, Quick Input:
The first alphanumeric characters of the first word (all lower-case) of a MTG card's name and looks up the corresponding card(s) in the masterbase.

`card name: bosh`

And voila:
 
`added 1 Bosh, Iron Golem to deck`

Now good ol' Bosh is ready to be written to file.

Some additional menu options:

- **q - save+quit**, all cards will be written to file and script exits
- **w - save**, all unsaved cards are written to file and continues accepting cards
- **d - delete** last entry, repeatable for all history (but cannot reverse already written cards) 

quit
```
card name: q

saving and exiting...
deck file: test.deck
[1] card(s) written
```

write
```
card name: w

writing cards in memory to deck file... done
[1] card(s) written

card name:
```

delete
```
added 1 Test of Faith to deck

card name: d

deleted previous entry: 1 Test of Faith
```

##### Multiple Matches
Sometimes more than one card will match a particular entry:

`card name: sol`

Returns a sorted list of all matching cards:

```
	0: Sol Grail  
	1: Sol Ring  
	2: Sol'kanar the Swamp King  
	[0-2]: 
```

The desired card can be selected by number. Aren't you glad you didn't have to enter a certain Swamp King's lengthy moniker?

#### Optimized Masterbase

The MTG masterbase as of 7/2013 (pre-M14) is provided in CSV form. This can be exported from MWS using `File->Export Deck/Base`

Cards are loaded from this file into a Perl hash. A performance improvement (mostly on older hardware) is gained by serializing Perl's hash representation of the masterbase and writing this to a file for a quicker load time for future executions.
This function is triggered using the `--rebuild` command line switch and can be used to rebuild the masterbase upon future set/card releases.

It is also possible enter cards without a masterbase. This option is set using the `--skip` command line switch. 
It is important to note that in this mode the *entire* card name must be entered in lower case, mwsload will intelligently capitalize words, hyphenated words, split cards, etc.


#### TODO:
- specify card quantities (currently singleton mode)
- load additional card info, do something with it
- Tk GUI


#### LICENSE
This package is free software; you can redistribute it and/or modify it under
the following terms:

1. The GNU General Public License as published by the Free Software Foundation; either version 1, or (at your option) any later version, or.

2. The original Artistic License, as published by Larry Wall.

3. The Artistic License Version 2.0