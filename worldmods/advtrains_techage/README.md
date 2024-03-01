# advtrains_techage

Techage integrations add-on for advtrains

## Liquids in tank wagons

Liquids can be pumped into and out of tank wagons.

### Placement of spigots

The filling spigot needs to be placed 3 nodes above the tracks. It needs to be vertically above a track node, as follows:

```
        |Spigot|
...     |      |     ...
...     |      |     ...
...Track|Track |Track...
```

The draining funnel needs to be placed directly below a track:
```
...Track |Track|Track...
...Ground|Drain|Ground..
```

For a tank wagon to be filled/drained, the wagon needs to be positioned with its center at the spigot (+-1m) and it must not move. Then, use a regular TechAge pump to pump a liquid into or out of a wagon.

### Tank wagon support

Tank wagons need to add the following field to the wagon definition:

```
techage_liquid_capacity = <capacity_in_liquid_units>
```

The tank wagons from Basic Trains have a capacity of 1000 units (like the TA3 tanks)

## License

Code License:
Copyright (C) 2023 orwell96
GNU AGPL 3.0-or-later
see LICENSE.txt

Media: textures modified from Techage
(C) 2022 Joachim Stolberg
CC-BY-SA 3.0
You can obtain the license text at https://creativecommons.org/licenses/by-sa/3.0/legalcode or see LICENSE_MEDIA.txt
