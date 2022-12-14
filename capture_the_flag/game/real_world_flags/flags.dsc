flag_red:
    type: item
    material: dirt
    mechanisms:
        custom_model_data: 1
    display name: <dark_red><bold>Red Flag
    lore:
        - flaggy flaggy heeeeeheee
    flags:
        flag_item: true
        flag_color: red
        uniquefier: <util.random_uuid>

flag_blue:
    type: item
    material: dirt
    mechanisms:
        custom_model_data: 2
    display name: <blue><bold>Blue Flag
    lore:
        - flaggy flaggy heeeeeheee
    flags:
        flag_item: true
        flag_color: blue
        uniquefier: <util.random_uuid>

flag_item_events:
    type: world
    debug: true
    events:
        on player places flag_*:
            - determine cancelled
        on player drops flag_*:
            - determine passively cancelled
            - narrate "YOU CANT DROP THE FLAG IDIOT GO BACK TO YOUR BASE"
        on player picks up flag_*:
            - narrate "kys "
        on player opens inventory:
            - if <player.inventory.contains_item[flag_*]> && <context.inventory.script.exists.not>:
                - determine cancelled
        on player right clicks block with:flag_* location_flagged:flag_block:
            - if <context.location.flag[flag_color]> != <context.item.flag[flag_color]>:
                - narrate ratio
                - take iteminhand from:<player> quantity:1

flag_player_prevent:
    type: world
    debug: false
    events:
        on player opens inventory:
        - if <player.has_flag[flag_held]>:
            - determine cancelled
        on player left_click clicks item in inventory:
        - if <player.has_flag[flag_held]>:
            - determine cancelled
        on delta time secondly:
        - foreach <server.online_players> as:__player:
            - if <player.inventory.contains_item[flag_*].not>:
                - flag <player> flag_held:!
