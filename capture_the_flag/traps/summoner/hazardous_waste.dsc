#Create a trap that summons a small army of zombies when triggered.
#Awful external name for players, needs to be changed.
hazardous_waste:
    type: item
    material: note_block
    mechanisms:
        hides: all
    display name: <blue>Hazardous Waste
    lore:
        - Activate this note block...
    enchantments:
        - unbreaking:1
    flags:
        trap:
            hazardous_waste: true

#Events for the hazardous waste trap.
hazardous_waste_events:
    type: world
    debug: true
    events:
        on noteblock plays note location_flagged:trap.hazardous_waste:
            #Spawns a zombie army of 5 at the location
            - repeat 5:
                #Spawn regular zombie
                - spawn zombie <context.location.center> target:<context.location.find_players_within[50].get[1].if_null[]>
                - playsound <context.location> sound:entity_zombie_break_wooden_door pitch:1 volume:2
                - wait 1s