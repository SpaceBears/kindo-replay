---
---

@setup = () ->
    build_params()
    set_theme_name(param_theme_name())
    refresh_theme()
    if is_in_game()
        in_game_setup()

    fetch_game game_id(), (game, error) ->
        if game
            @game = game
            set_theme_name(@game.theme) unless @theme_name?
            refresh_theme()
            setup_game @game.gameboard, @game.player1, @game.player2, @game.max_play_count_by_turn
            @current_index = null
            load_next_gameboard_state()
            @play() if auto_play()
        else if error
            document.getElementById("error_container").style.display = "block"
            document.getElementById("gameboard_container").style.display = "none"
        else
            window.location = "http://kindogame.fr"

@load_next_gameboard_state = () ->
    if @current_index == null
        @current_index = 0
    else
        @current_index++

    if @game.gameboard_states.length <= @current_index
        should_replay = auto_play()
        @pause()
        if should_replay
            @reload()
            @play()
            @auto_play = true
        return

    gameboard_state = @game.gameboard_states[@current_index]
    count = @game.gameboard.tile_count_by_side
    last = @current_index + 1 == @game.gameboard_states.length
    load_gameboard_state gameboard_state, count, last, (tile, state, substate) ->
        if state or substate
            console.log tile

@play = () ->
    return if @interval
    @interval = setInterval(@load_next_gameboard_state, 800)
    play_control().style.display = "none"
    pause_control().style.display = "inline"

@pause = () ->
    clearInterval @interval
    @interval = null
    @auto_play = false
    play_control().style.display = "inline"
    pause_control().style.display = "none"

@reload = () ->
    @pause()
    @current_index = null
    @load_next_gameboard_state()

play_control = () ->
    document.getElementById "play"

pause_control = () ->
    document.getElementById "pause"

in_game_setup = () ->
    document.getElementById('footer').style.display = "none"
    document.getElementById('controls').style.display = "none"

build_params = () ->
    @params = {}
    dict = window.location.search.replace '?', ''
    for param in dict.split '&'
        components = param.split '='
        continue if components.length < 2
        @params[components[0]] = components[1]

is_in_game = ->
    @params["ingame"] == "1"

param_theme_name = ->
    @params["theme"]

auto_play = ->
    return @auto_play if @auto_play?
    @auto_play = @params["play"] == "1" || is_in_game()

game_id = ->
    return window.location.hash[1..-1]

set_theme_name = (name) ->
    if name of @themes()
        @theme_name = name
    else
        @theme_name = "green-orange-light"

refresh_theme = ->
    return unless @theme_name?

    document.body.style.backgroundColor = background_color()
    document.body.style.color = text_color()

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

    get "https://s3.eu-central-1.amazonaws.com/kindogame/replays/#{file_name}.json", (req) ->
        if req
            game = JSON.parse req.response
            console.log "game fetched"
            completion game, false
        else
            completion null, true

setup_game = (gameboard, player1, player2, max_play_count) ->
    build_players [player1, player2], max_play_count
    build_gameboard gameboard
    build_controls()

build_players = (players, max_play_count) ->
    for player, i in players
        # Image
        image = document.getElementById "player#{i+1}_image"
        image.innerHTML = if i == 0 then "P1" else "P2"
        image.style.color = background_color()
        refresh_background_color image, i + 1

        # Image highlight
        highlight = document.getElementById "player#{i+1}_image_highlight"
        get 'assets/player_highlight.svg', (req) ->
            svg = req.response
            highlight.innerHTML = svg
            highlight.getElementsByTagName("svg")[0].setAttribute "stroke", color_from_state(i+1)

        # Title
        title = document.getElementById "player#{i+1}_title"
        title.innerHTML = player.username
        title.style.color = color_from_state(i+1)

        # plays count
        plays_count = document.getElementById "player#{i+1}_plays_count"
        for i in [0..max_play_count - 1]
            micro_tile = document.createElement "div"
            micro_tile.className = "micro_tile"
            plays_count.appendChild micro_tile

build_gameboard = (gameboard) ->
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
            refresh_background_color tile, 0

            # Divs
            for name in ["unfortifiable_container", "tile_image", "just_played_container"]
                img = document.createElement "div"
                img.className = name
                tile.appendChild img

            # Svgs
            if unfortifiable
                get 'assets/unfortifiable.svg', (req) ->
                    svg = req.response
                    tile.firstChild.innerHTML = svg

                    refresh_icon_color tile, 0

            get 'assets/just_played.svg', (req) ->
                svg = req.response
                tile.lastChild.innerHTML = svg

                refresh_icon_color tile, 0

            # Add to gameboard
            gameboard.appendChild tile

load_gameboard_state = (gameboard_state, count, last, changes) ->
    # Players
    for player, i in ["player1", "player2"]
        current_turn_count = gameboard_state[player].current_turn_count
        next_turn_count = gameboard_state[player].next_turn_count

        plays_count_element = document.getElementById "#{player}_plays_count"
        refresh_player_plays_count plays_count_element, current_turn_count, next_turn_count, i+1

        card = document.getElementById "#{player}_card"
        modify_class card, "highlight", current_turn_count > 0

    # Gameboard
    states = gameboard_state.states
    substates = gameboard_state.substates
    just_played_tiles = gameboard_state.just_played

    for j in [0..count-1]
        for i in [0..count-1]
            tile = document.getElementById "#{i}-#{j}"

            state = get_object states, j, i, count
            state_changed = refresh_tile_state tile, state
            just_played = if last then false else get_object(just_played_tiles, j, i, count) == 1

            if state_changed
                refresh_icon_color tile, state
                refresh_background_color tile, state

            tile.lastChild.style.display = if just_played then "block" else "none"

            substate = get_object substates, j, i, count
            substate_changed = refresh_tile_substate tile, substate

            changes(tile, state_changed, substate_changed)

build_controls = () ->
    for control in ["play", "pause", "reload"]
        get "assets/#{control}.svg", (req) ->
            svg = req.response
            element = document.getElementById control
            element.innerHTML = svg

            refresh_icon_color element, 0, text_color()

            element.style.display = "none" if control == "pause"

refresh_icon_color = (tile, state, color = null) ->
    unless color
        color = unfortifiable_tile_color()
        if state == 1 or state == 3
            color = player_1_unfortifiable_tile_color()
        if state == 2 or state == 4
            color = player_2_unfortifiable_tile_color()

    for icon in tile.getElementsByTagName('svg')
        icon.setAttribute "fill", color
        icon.setAttribute "width", "100%"
        icon.setAttribute "height", "100%"

color_from_state = (state) ->
    color = standard_tile_color()
    if state == 1 or state == 3
        color = player_1_color()
    if state == 2 or state == 4
        color = player_2_color()
    color

refresh_background_color = (el, state) ->
    el.style.backgroundColor = color_from_state(state)

refresh_player_plays_count = (plays_count_element, current_count, next_count, state) ->
    for tile, i in plays_count_element.children
        if i < current_count
            highlight_micro_tile tile, state
        else if i < next_count
            fill_micro_tile tile
        else
            empty_micro_tile tile

highlight_micro_tile = (micro_tile, state) ->
    color = color_from_state state
    micro_tile.style.backgroundColor = color
    micro_tile.style.borderColor = color

fill_micro_tile = (micro_tile) ->
    color = standard_tile_color()
    micro_tile.style.backgroundColor = color
    micro_tile.style.borderColor = color

empty_micro_tile = (micro_tile) ->
    micro_tile.style.background = "none"
    micro_tile.style.borderColor = standard_tile_color()

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

