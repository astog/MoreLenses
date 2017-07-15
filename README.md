# More Lenses

## Introduction
The goal of this mod is to add more lenses to the game, that help with empire management and in general quality of life improvements. Currently there are 9 new lenses, but you are welcome to suggest new ones and I can add them.

## New Lenses

#### Builder Lens
This lens highlights unimproved resources, hills and removable features. This lens auto applies when a builder is selected (can be disabled in the file. See FAQ).

![Imgur](http://i.imgur.com/6ayAc9V.jpg)
___
#### Archaeologist Lens:
Highlights artifacts and shipwrecks. No longer do you need to hunt around the map for antiquity sites. Automatically applies when a archaeologist is selected (can be disabled in the file. See FAQ).

![Imgur](http://i.imgur.com/Fe0UYRF.jpg)
___
#### City Overlap 6 or 9:
Shows how many cities a particular hex overlaps with. Range 6 or 9. This lens will help you find that sweet spot where the maximum amount of cities overlap so you can build that district / wonder.

![Imgur](http://i.imgur.com/TnLHfG3.jpg)
___
#### Barbarian Lens:
Highlights barbarian encampments on the map

![Imgur](http://i.imgur.com/V0GXjP2.jpg)
___
#### Resource Lens:
Highlights resources on the map based on their category (Bonus vs Strategic vs Luxury) and if they are connected or not.

![Imgur](http://i.imgur.com/VO36PR1.jpg)
___
#### Wonder Lens:
Highlights natural and player made wonders.

![Imgur](http://i.imgur.com/FvMyNAH.jpg)
___
#### Adjacency Yield Lens:
One of the best parts about Civ 6 is the city / district placement. This lens shows the various adjacency bonuses in a gradient, allowing you to relish in your pristine city planning skills.

![Imgur](http://i.imgur.com/myYKklk.jpg)
___
#### Scout Lens:
Highlights goody huts on the map. Automatically applies when a scout / ranger is selected (can be disabled in the file. See FAQ)

![Imgur](http://i.imgur.com/TnnErfb.jpg)
___

## Installation
If you are using [Chao's QUI](https://github.com/chaorace/cqui) follow these steps:

1. Get the mod from [here](https://www.dropbox.com/s/sd48t2g0j0g2b33/More%20Lenses%20-%20CQUI.zip?dl=0)
2. Delete **MinimapPanel.lua** and **MinimapPanel.xml** from CQUI. These are the two files that conflict with More Lenses.
3. Follow the steps mentioned below, and you should be able to use CQUI and More Lenses together

Once you have the mod follow these steps:

1. Extract the file to your Mods folder. For me this is in *Documents\My Games\Sid Meier's Civilization VI\Mods*
2. Activate the Mod in *Additional Content* inside Civilization VI.

## Troubleshooting
If you encounter issues with getting the mod working try the following steps:

1. Try installing the Mod into the DLC folder. This folder is the folder where you installed Civilization VI, example *C:\Program Files (x86)\Steam\steamapps\common\Sid Meier's Civilization VI\DLC*
2. Delete the cache. This can be found here - *Documents\My Games\Sid Meier's Civilization VI\Cache*
3. Check out this [thread](https://forums.civfanatics.com/threads/mods-not-working-at-all-help.606288/)
4. If none of the above work, let me know in this repository or [here](https://forums.civfanatics.com/threads/more-lenses.606150/)

## FAQ
##### How did you add lenses?
> There isn't a built-in functionality to add lenses. I went around that by making the game think it is displaying Appeal Lens, but change the hexes being highlighted.

##### Can I change what color is being used?
>You can find the colors in **MoreLenses_Colors.sql**. I used the following websites to find the values: website1, website2. Fair warning, colors on the map will look different from these websites mainly because on a civ 6 map the background to a lens'ed hex is usually a green plot or a blue sea. That mean blue starts to look like purple and all other issues. This was the main reason why I could only get the gradient to 8 distinguishable colors.

##### Can I disable a lens being auto-applied, like the builder lens, archaeologist lens, scout lens?
>On top of MinimapPanel.lua you should find the following lines of code:
> ```lua
> local AUTO_APPLY_BUILDER_LENS:boolean = true
> local AUTO_APPLY_ARCHEOLOGIST_LENS:boolean = true
> local AUTO_APPLY_SCOUT_LENS:boolean = true
> ```
>
>Change the respective variable to **false**.

## Credits

* @ZhouYzzz for providing the Chinese localization in #161-CQUI
* @deggesim (Simone1974 on Civfanatics) for providing the Italian localization in #250-CQUI
* @e1ectron for providing the Russian localization in #251-CQUI
* @sejbr for providing the Polish localization in #253-CQUI
* @frytom for providing the German localization in #283-CQUI
* @lctrs for providing a partial French localization in #273-CQUI
* @wbqd for providing a Korean translation in #309-CQUI
