gun_events:
    type: world
    debug: true
    events:
        on player right clicks block with:item_flagged:gun:
            #Check that the player does not currently have a gun on cooldown
            - if <player.item_cooldown[<context.item.material>].in_ticks> > 0:
                - stop

            - determine passively cancelled

            #Grab the map containing all of the gun information
            - define gun <context.item.flag[gun]>
            - define props <[gun.properties]||<map[]>>

            #Grab the map containing the data that is SPECIFIC to the gun (e.g. ammo)
            - define gun_data <context.item.flag[gun_data]>

            #Tell the player to reload if they have no bullets left
            - if <[gun_data.bullets_left]> == 0:
                - itemcooldown <context.item.material> duration:0.5s
                - title subtitle:<red>RELOAD targets:<player> fade_in:1t fade_out:1t stay:1s
                - inject gun_sounds_need_reload
                - stop

            #Use archaic item cooldowns to prevent players from spamming the gun
            - itemcooldown <context.item.material> duration:<[gun.firerate]>s
            - inventory flag slot:hand gun_data.bullets_left:<[gun_data.bullets_left].sub[1]>

            #Play the fire sound
            - inject gun_sounds path:<[gun.fire_sound_path]>

            - repeat <[gun.bullets_per_shot]>:
                #Raytrace to find the impact point
                - define impact <player.eye_location.above[0.05].ray_trace[range=<[gun.bullet_range]>;ignore=<player>;entities=*;fluids=false;nonsolids=false].if_null[null]>
                #If the impact is absent, the bullet will travel straight to the end of the range
                - if <[impact]> == null:
                    - define impact <player.eye_location.forward[<[gun.bullet_range]>]>
                #Apply bullet spread, just randomly offset the impact location
                - if <[gun.bullet_spread]> != 0:
                    - define impact <[impact].random_offset[<[gun.bullet_spread]>,<[gun.bullet_spread].div[1.3]>,<[gun.bullet_spread]>]>

                - playeffect effect:<[gun.particle.type]||crit> offset:<[gun.particle.offset]||0.0,0.0,0.0> at:<player.eye_location.points_between[<[impact].forward[<[gun.particle.distance].if_null[0.6].mul[1.5]>]>].distance[<[gun.particle.distance]>]> special_data:<[gun.particle.special_data]||<empty>>

                #This repeat is here to allow for the collapsing of the properties section, for organization
                - repeat 1:
                    - if <[props].keys.contains[explosion]>:
                            - define fire <[props].deep_get[explosion.fire]||false>
                            - define block_damage <[props].deep_get[explosion.block_damage]||false>
                            - define power <[props].deep_get[explosion.power]||1>
                            - if <[fire]> && <[block_damage]>:
                                - explode <[impact]> power:<[power]> breakblocks fire
                            - else if <[fire]>:
                                - explode <[impact]> power:<[power]> fire
                            - else if <[block_damage]>:
                                - explode <[impact]> power:<[power]> breakblocks
                            - else:
                                - explode <[impact]> power:<[power]>

                    - if <[props].keys.contains[flash]>:
                        - define flash_radius <[props].deep_get[flash.radius]||5>
                        - define slow <[props].deep_get[flash.slow]||0>
                        - define darkness <[props].deep_get[flash.darkness]||0>
                        - define blind <[props].deep_get[flash.blind]||0>
                        - cast darkness <[impact].find_entities[*].within[<[flash_radius]>]> amplifier:4 duration:<[darkness]>s
                        - cast blindness <[impact].find_entities[*].within[<[flash_radius]>]> amplifier:4 duration:<[blind]>s
                        - cast slow <[impact].find_entities[*].within[<[flash_radius]>]> duration:<[slow]>s
                        - playeffect effect:flash at:<[impact].above[3.5]> quantity:35 offset:0.5,0.5,0.5
                        - playeffect effect:redstone at:<[impact].above[3.5].to_ellipsoid[<[flash_radius]>,<[flash_radius]>,<[flash_radius]>].shell> quantity:1 special_data:1|red

                    - if <[props].keys.contains[ignite]>:
                        - define ignite_targets <[impact].find_entities[*].within[<[props].deep_get[ignite.radius]||1>]>
                        - define ignite_targets <[ignite_targets].exclude[<player>]> if:!<[props].deep_get[ignite.self]||true>
                        - burn <[ignite_targets]> duration:<[props].deep_get[ignite.duration]||10>s

                #splash damage to each living entity nearby
                - foreach <[impact].find_entities[living].within[0.2].exclude[<player>]> as:entity:
                    - hurt <[gun.damage]> <[entity]> source:<player>
                #SOON: make splash damage radius customizable
                #SOON: make player exclusion customizable (for example, a gun that if you shoot at the ground will hurt you too)

        on player left clicks block with:item_flagged:gun:
            #Get the item in the player's hand
            - define item <context.item.if_null[<player.item_in_hand>]>

            - determine passively cancelled

            #Check that the player does not currently have a gun on cooldown
            - if <player.item_cooldown[<[item].material>].in_ticks> > 0:
                - stop

            #Grab gun information or whatever
            - define gun <[item].flag[gun]>

            #Grab the gun data
            - define gun_data <[item].flag[gun_data]>

            #If the player's magazine is full, no reloading required
            - if <[gun_data.bullets_left]> == <[gun.clip]>:
                - stop

            - title subtitle:<yellow>RELOADING... targets:<player> fade_in:1t fade_out:1t stay:1s
            - inject gun_sounds path:<[gun.reload_start_sound_path]>
            - itemcooldown <[item].material> duration:<[gun.reload]>s
            - inventory flag slot:hand gun_data.bullets_left:<[gun.clip]>
            - wait <[gun.reload]>s
            - title subtitle:<green>RELOADED targets:<player> fade_in:1t fade_out:1t stay:1s
            - inject gun_sounds path:<[gun.reload_end_sound_path]>

gun_bullet_counter:
    type: world
    debug: false
    events:
        after tick every:5:
            - foreach <server.online_players> as:__player:

                - if <player.item_in_hand.has_flag[gun].not>:
                    - actionbar <empty> targets:<player>
                    - foreach next

                - define gun <player.item_in_hand.flag[gun]>
                - define gun_data <player.item_in_hand.flag[gun_data]>

                - if <[gun_data.bullets_left]> == <[gun.clip]>:
                    - actionbar "<green><bold><[gun_data.bullets_left]> <gray>| <gold><bold><[gun.clip]>"
                - else if <[gun_data.bullets_left]> > 0:
                    - actionbar "<yellow><bold><[gun_data.bullets_left]> <gray>| <gold><bold><[gun.clip]>"
                - else:
                    - actionbar "<red><bold><[gun_data.bullets_left]> <gray>| <gold><bold><[gun.clip]>"

testing_gun:
    type: item
    material: wooden_hoe
    mechanisms:
        unbreakable: false
        hides: enchants|attributes|unbreakable
    enchantments:
        - unbreaking:1

default_revolver:
    type: item
    material: testing_gun
    display name: <gold>Default Revolver
    flags:
        gun_data:
            bullets_left: 0
        gun:
            type: revolver
            properties:
                ignite: 1
                explosion:
                    power: 0
                    fire: false
                    block_damage: false
            fire_sound_path: generic_revolver
            #Time between shots in seconds
            firerate: 0.5
            #Bullet damage
            damage: 10
            #Bullet spread
            spread: 0.01
            #Bullet range
            range: 100
            #Bullet count
            count: 1
            #Shots per clip
            clip: 6
            #Reload time in seconds
            reload: 2.0
            #Reload sound paths
            reload_start_sound_path: generic_revolver_rl_1
            reload_end_sound_path: generic_revolver_rl_2

flare_gun:
    type: item
    material: testing_gun
    display name: <red>Flare Gun
    flags:
        gun_data:
            bullets_left: 0
        gun:
            type: revolver
            properties:
                ignite:
                    duration: 15
                    radius: 5
                    self: true
                flash:
                    radius: 5
                    slow: 10
                    blind: 0
                    darkness: 10
                explosion:
                    power: 1.5
                    fire: true
                    block_damage: false
            fire_sound_path: generic_revolver
            #Time between shots in seconds
            firerate: 0.5
            #Bullet damage
            damage: 4
            #Bullet spread
            spread: 0.3
            #Bullet range
            range: 150
            #Bullet count
            count: 1
            #Shots per clip
            clip: 1
            #Reload time in seconds
            reload: 1.5
            #Reload sound paths
            reload_start_sound_path: generic_revolver_rl_1
            reload_end_sound_path: generic_revolver_rl_2

default_smg:
    type: item
    material: testing_gun
    display name: <gold>Default SMG
    flags:
        gun_data:
            bullets_left: 0
        gun:
            type: smg
            fire_sound_path: generic_smg
            #Time between shots in seconds
            firerate: 0.05
            #Bullet damage
            damage: 10
            #Bullet spread
            spread: 1.0
            #Bullet range
            range: 75
            #Bullet count
            count: 1
            #Shots per clip
            clip: 30
            #Reload time in seconds
            reload: 2.0
            #Reload sound path
            reload_sound_path: generic_smg

default_shotgun:
    type: item
    material: testing_gun
    display name: <gold>Default Shotgun
    flags:
        gun_data:
            bullets_left: 0
        gun:
            type: shotgun
            particle:
                type: redstone
                distance: 0.3
                special_data: 0.4|#915519
            fire_sound_path: generic_shotgun
            #Time between shots in seconds
            firerate: 0.5
            #Bullet damage
            damage: 15
            #Bullet spread
            spread: 1
            #Bullet range
            range: 20
            #Bullet count
            count: 12
            #Shots per clip
            clip: 6
            #Reload time in seconds
            reload: 2.0
            #Reload sound path
            reload_start_sound_path: generic_shotgun
            #Reload complete sound path
            reload_end_sound_path: generic_shotgun

double_barrel:
    type: item
    material: testing_gun
    display name: <dark_blue>Double Barrel
    flags:
        gun_data:
            bullets_left: 2
        gun:
            type: shotgun
            properties:
                explosion:
                    power: 1.2
                    fire: false
                    block_damage: false
            particle:
                type: redstone
                distance: 0.5
                special_data: 0.6|black
            fire_sound_path: generic_shotgun
            #Time between shots in seconds
            firerate: 0.85
            #Bullet damage
            damage: 17
            #Bullet spread
            spread: 0.25
            #Bullet range
            range: 20
            #Bullet count
            count: 5
            #Shots per clip
            clip: 2
            #Reload time in seconds
            reload: 5.0
            #Reload sound path
            reload_start_sound_path: generic_shotgun
            #Reload complete sound path
            reload_end_sound_path: generic_shotgun
