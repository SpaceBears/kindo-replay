---
---

@setup = () ->
    fetch_game param(), (game, error) ->
        if game
            @game = game
            setup_game @game.gameboard, @game.player1, @game.player2, @game.max_play_count_by_turn
            @current_index = null
            load_next_gameboard_state()
        else if error
            document.getElementById("error_container").style.display = "block"
            document.getElementById("gameboard_container").style.display = "none"
        else
            window.location = "http://kingdomsgame.fr"

@load_next_gameboard_state = () ->
    if @current_index == null
        @current_index = 0
    else
        @current_index++

    unless @game.gameboard_states.length > @current_index
        return

    gameboard_state = @game.gameboard_states[@current_index]
    count = @game.gameboard.tile_count_by_side
    load_gameboard_state gameboard_state, count, (tile, state, substate) ->
        if state or substate
            console.log tile

param = ->
    return window.location.hash[1..-1]

get = (path, completion) ->
    req = new XMLHttpRequest()

    req.addEventListener 'readystatechange', ->
        if req.readyState is 4                        # ReadyState Complete
            successResultCodes = [200, 304]
            if req.status in successResultCodes
                completion req
            else
                console.log "Error loading #{path}"
                completion null

    req.open 'GET', path, false
    req.send()

fetch_game = (file_name, completion) ->
    if file_name.length == 0
        completion null, false
        return

    console.log "fetching game…"

    get "https://s3.eu-central-1.amazonaws.com/kingdomsgame/replays/#{file_name}.json", (req) ->
        if req
            game = JSON.parse req.response
            console.log "game fetched"
            completion game, false
        else
            completion null, true

setup_game = (gameboard, player1, player2, max_play_count) ->
    # Players
    for player, i in [player1, player2]
        # Image
        image = document.getElementById "player#{i+1}_image"
        image.innerHTML = if i == 0 then "P1" else "P2"

        # Title
        title = document.getElementById "player#{i+1}_title"
        title.innerHTML = player.username

        # plays count
        plays_count = document.getElementById "player#{i+1}_plays_count"
        for i in [0..max_play_count - 1]
            micro_tile = document.createElement "div"
            micro_tile.className = "micro_tile"
            plays_count.appendChild micro_tile

    # Gameboard
    count = gameboard.tile_count_by_side
    types = gameboard.tile_types
    tile_size = 50

    gameboard = document.getElementById "gameboard"
    gameboard.innerHTML = ""

    for j in [0..count-1]
        for i in [0..count-1]
            # Tile
            tile = document.createElement "div"
            tile.id = "#{i}-#{j}"
            tile.className = "tile"

            unfortifiable = get_object(types, i, j, count) == 1

            if unfortifiable
                tile.className += " unfortifiable"
            tile.style.left = "#{i * tile_size}px"
            tile.style.top = "#{j * tile_size}px"

            # Svg
            if unfortifiable
                get 'assets/unfortifiable.svg', (req) ->
                    svg = req.response
                    tile.innerHTML = svg

                    refresh_icon_color tile, 0

            # Image
            img = document.createElement "div"
            img.className = "tile_image"
            tile.appendChild img

            # Add to gameboard
            gameboard.appendChild tile

load_gameboard_state = (gameboard_state, count, changes) ->
    # Players
    for player in ["player1", "player2"]
        current_turn_count = gameboard_state[player].current_turn_count
        next_turn_count = gameboard_state[player].next_turn_count

        plays_count_element = document.getElementById "#{player}_plays_count"
        refresh_player_plays_count plays_count_element, current_turn_count, next_turn_count

    # Gameboard
    states = gameboard_state.states
    substates = gameboard_state.substates

    for j in [0..count-1]
        for i in [0..count-1]
            tile = document.getElementById "#{i}-#{j}"

            state = get_object states, j, i, count
            state_changed = refresh_tile_state tile, state

            if state_changed
                refresh_icon_color tile, state

            substate = get_object substates, j, i, count
            substate_changed = refresh_tile_substate tile, substate

            changes(tile, state_changed, substate_changed)

refresh_icon_color = (tile, state) ->
    icon = tile.getElementsByTagName('svg')[0]

    unless icon
        return

    color = "#D9D5D2"
    if state == 1 or state == 3
        color = "#388C62"
    if state == 2 or state == 4
        color = "#CC7447"

    icon.setAttribute "fill", color

    icon.setAttribute "width", "100%"
    icon.setAttribute "height", "100%"

refresh_player_plays_count = (plays_count_element, current_count, next_count) ->
    for tile, i in plays_count_element.children
        tile.className = "micro_tile"
        if i < current_count
            tile.classList.add "micro_tile_highlighted"
        else if i < next_count
            tile.classList.add "micro_tile_plain"

refresh_tile_state = (tile, state) ->
    changed = false
    if modify_class tile, "king_state", state == 1 or state == 2
        changed = true
    if modify_class tile, "player1_state", state == 1 or state == 3
        changed = true
    if modify_class tile, "player2_state", state == 2 or state == 4
        changed = true

    return changed

refresh_tile_substate = (tile, substate) ->
    changed = false
    if modify_class tile, "substate_up", substate == 1
        changed = true
    if modify_class tile, "substate_right", substate == 2
        changed = true
    if modify_class tile, "substate_down", substate == 3
        changed = true
    if modify_class tile, "substate_left", substate == 4
        changed = true

    return changed

modify_class = (el, klass, add) ->
    changed = false
    if add
        unless el.classList.contains klass
            el.classList.add klass
            changed = true
    else
        if el.classList.contains klass
            el.classList.remove klass
            changed = true

    return changed

array_index = (row, col, count) ->
    return row * count + col

get_object = (array, row, col, count) ->
    length = array.length
    index = array_index row, col, count

    if index < length * length
        return array[index]
    return null

