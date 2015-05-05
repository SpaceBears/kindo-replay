---
---

@isMobile = navigator.userAgent.match(/Android/i) ||
            navigator.userAgent.match(/BlackBerry/i) ||
            navigator.userAgent.match(/iPhone|iPad|iPod/i) ||
            navigator.userAgent.match(/Opera Mini/i) ||
            navigator.userAgent.match(/IEMobile/i)

class @ClickHandler
    constructor: (@element, @callback) ->
        if isMobile
            @element.addEventListener 'touchstart', this, false
        else
            @element.addEventListener 'click', this, false

    handleEvent: (event) ->
        switch event.type
            when 'touchstart' then @onTouchStart()
            when 'touchmove'  then @onTouchMove()
            when 'touchend'   then @onTouchEnd()
            when 'click'      then @onClick()

    onClick: ->
        @onTouchStart()
        @onTouchEnd()

    onTouchStart: ->
        @moved = false

        @element.addEventListener 'touchmove', this, false
        @element.addEventListener 'touchend', this, false

    onTouchMove: ->
        @moved = true

    onTouchEnd: (event) ->
        @element.removeEventListener 'touchmove', this, false
        @element.removeEventListener 'touchend', this, false

        unless @moved
            @callback()

@Layout =
    Portrait: "portrait"
    Landscape: "landscape"
    FlatLandscape: "flat_landscape"

class @LayoutHandler
    constructor: (@tile_count_by_side) ->
        @gameboard_max_size = 520

    reset: ->
        @layout_string = null
        @refresh_layout()

    layout: ->
        return @layout_string if @layout_string?
        @layout_string = @measure_layout()

    refresh_layout: ->
        switch @layout()
            when Layout.Portrait then @refresh_portrait_layout()
            when Layout.Landscape then @refresh_landscape_layout()
            when Layout.FlatLandscape then @refresh_flat_landscape_layout()
        @refresh_player_image()
        if @layout() == Layout.Portrait
            @refresh_portrait_elements_position()
        else
            @refresh_player_cards_position()

    measure_layout: ->
        width = window.innerWidth
        height = window.innerHeight

        ratio = width / height

        if ratio <= 1
            return Layout.Portrait

        if ratio <= 1.7
            return Layout.Landscape
        return Layout.FlatLandscape

    page: ->
        document.getElementById "page"

    gameboard_container: ->
        document.getElementById "gameboard_container"

    gameboard_wrapper: ->
        document.getElementById "gameboard_wrapper"

    gameboard: ->
        document.getElementById "gameboard"

    player_card_container: (num) ->
        document.getElementById "player#{num}_card_container"

    player_card: (num) ->
        document.getElementById "player#{num}_card"

    player_title: (num) ->
        document.getElementById "player#{num}_title"

    player_outcome: (num) ->
        document.getElementById "player#{num}_outcome"

    tile: (i, j) ->
        document.getElementById "#{i}-#{j}"

    player_image_container: (num) ->
        document.getElementById "player#{num}_image_container"

    player_image: (num) ->
        document.getElementById "player#{num}_image"

    player_image_highlight: (num) ->
        document.getElementById "player#{num}_image_highlight"

    controls: ->
        document.getElementById "controls"

    refresh_portrait_layout: ->
        @gameboard_size = @measure_gameboard_size(window.innerWidth)
        @gameboard_h_margin = (window.innerWidth - @gameboard_size) / 2

        @page().style.width = "#{@gameboard_size}px"
        @page().style.height = "100%"
        page_height = @page().offsetHeight

        if @controls_hidden()
            height = page_height
        else
            controls_height = @controls_height @gameboard_size
            @refresh_controls_height controls_height
            height = page_height - 2 * controls_height

        margin = Math.min @min_margin(window.innerWidth), @gameboard_h_margin
        container_height = @measure_container_height height, @gameboard_size, margin
        @gameboard_container().style.height = "#{container_height}px"

        @gameboard_container().style.width = "100%"

        # Player cards
        card_width = "#{Math.floor(@gameboard_size / 2)}px"
        card_margin = "#{@gameboard_h_margin}px"
        for i in [1, 2]
            @player_card_container(i).style.width = card_width

        @player_card_container(2).style.clear = "none"
        @player_card_container(2).style.float = "right"

        # Board
        @resize_gameboard(@gameboard_size, @tile_count_by_side)

    refresh_portrait_elements_position: ->
        player_card_container_height = 0
        player_card_container_margin_top = 0
        container_height = @gameboard_container().offsetHeight
        gameboard_top = 0

        if @gameboard_size < @gameboard_max_size
            @gameboard_v_margin = @gameboard_h_margin
            player_card_container_height = container_height - @gameboard_v_margin - @gameboard_size
            gameboard_top = player_card_container_height
        else
            player_cards_gameboard_margin = Math.min @gameboard_size / 6, Math.round((container_height - @player_card_height - @gameboard_size) / 3)
            player_card_container_height = @player_card_height + 2 * player_cards_gameboard_margin
            player_card_container_margin_top = (container_height - (player_card_container_height + @gameboard_size + player_cards_gameboard_margin)) / 2
            gameboard_top = player_card_container_margin_top + player_card_container_height

        for i in [1, 2]
            @player_card_container(i).style.marginTop = "#{player_card_container_margin_top}px"
        @refresh_player_cards_position(player_card_container_height)
        @gameboard_wrapper().style.paddingTop = "#{gameboard_top}px"
        @gameboard_wrapper().style.paddingLeft = 0
        @gameboard_wrapper().style.width = "#{@gameboard_size}px"
        @gameboard_wrapper().style.margin = "0 auto"

    refresh_landscape_layout: ->
        @page().style.width = "100%"
        @page().style.height = "100%"


        if @controls_hidden()
            @gameboard_container().style.height = "100%"
        else
            page_height = @page().offsetHeight

            @gameboard_size = @measure_gameboard_size(page_height)
            controls_height = @controls_height @gameboard_size
            @refresh_controls_height controls_height

            @gameboard_container().style.height = "#{page_height - 2 * controls_height}px"

        @gameboard_container().style.width = "100%"

        container_height = @gameboard_container().offsetHeight
        container_width = @gameboard_container().offsetWidth
        @gameboard_size = @measure_gameboard_size(container_height)
        @gameboard_v_margin = Math.round((container_height - @gameboard_size) / 2)

        # Player cards
        card_width = container_width - @gameboard_size - @gameboard_v_margin
        card_height = Math.floor @gameboard_size / 2
        for i in [1, 2]
            @player_card_container(i).style.width = "#{card_width}px"
            @player_card_container(i).style.height = "#{card_height}px"
            @player_card_container(i).style.margin = 0

        @player_card_container(1).style.marginTop = "#{@gameboard_v_margin}px"
        @player_card_container(2).style.clear = "both"
        @player_card_container(2).style.float = "left"


        # Board
        @resize_gameboard(@gameboard_size, @tile_count_by_side)
        @gameboard_wrapper().style.paddingTop = "#{@gameboard_v_margin}px"
        @gameboard_wrapper().style.paddingLeft = "#{card_width}px"
        @gameboard_wrapper().style.width = "#{@gameboard_size}px"
        @gameboard_wrapper().style.margin = 0

    refresh_flat_landscape_layout: ->
        @page().style.width = "100%"
        @page().style.height = "100%"

        if @controls_hidden()
            @gameboard_container().style.height = "100%"
        else
            page_height = @page().offsetHeight

            @gameboard_size = @measure_gameboard_size(page_height)
            controls_height = @controls_height @gameboard_size
            @refresh_controls_height controls_height

            @gameboard_container().style.height = "#{page_height - 2 * controls_height}px"

        @gameboard_container().style.width = "100%"

        container_height = @gameboard_container().offsetHeight
        container_width = @gameboard_container().offsetWidth
        @gameboard_size = @measure_gameboard_size(container_height)

        # Player cards
        card_width = "#{Math.floor((container_width - @gameboard_size) / 2)}px"
        for i in [1, 2]
            @player_card_container(i).style.width = card_width
            @player_card_container(i).style.height = "100%"
            @player_card_container(i).style.margin = 0

        @player_card_container(2).style.clear = "none"
        @player_card_container(2).style.float = "right"

        # Board
        @resize_gameboard(@gameboard_size, @tile_count_by_side)
        @gameboard_wrapper().style.paddingTop = "#{Math.round((container_height - @gameboard_size) / 2)}px"
        @gameboard_wrapper().style.paddingLeft = 0
        @gameboard_wrapper().style.width = "#{@gameboard_size}px"
        @gameboard_wrapper().style.margin = "0 auto"


    resize_gameboard: (size, count) ->
        @gameboard().style.width = "#{size}px"
        @gameboard().style.height = "#{size}px"

        tile_container_size = size / count
        tile_margin = tile_container_size / 26
        tile_size = tile_container_size - 2 * tile_margin

        border_radius = "#{tile_container_size / 12}px"

        for i in [0..count - 1]
            for j in [0..count - 1]
                tile = @tile(i, j)
                tile.style.left = "#{i * tile_container_size}px"
                tile.style.top = "#{j * tile_container_size}px"
                tile.style.width = "#{tile_size}px"
                tile.style.height = "#{tile_size}px"
                tile.style.margin = "#{tile_margin}px"
                @set_border_radius tile, border_radius

    refresh_player_image: ->
        @image_size = @measure_image_size @gameboard_size
        [@player_card_height, t_h, t_m, c_h, h_s, h_w] = @player_image_sizes @image_size

        for i in [1, 2]
            @player_image_container(i).style.width = "#{@image_size}px"
            @player_image_container(i).style.height = "#{@image_size}px"

            @player_image(i).style.lineHeight = "#{@image_size}px"
            @player_image(i).style.fontSize = "#{@image_size / 3.2}px"
            @set_border_radius @player_image(i), "#{@image_size / 2}px"

            @player_image_highlight(i).style.width = "#{h_s}px"
            @player_image_highlight(i).style.height = "#{h_s}px"
            @player_image_highlight(i).style.margin = "#{-2 * h_w}px"

            @player_title(i).style.fontSize = "#{t_h}px"
            @player_title(i).style.lineHeight = "#{t_h}px"
            @player_title(i).style.marginTop = "#{t_m}px"
            @player_title(i).style.marginBottom = "#{t_m}px"
            @player_outcome(i).style.fontSize = "#{t_h}px"
            @player_outcome(i).style.lineHeight = "#{t_h}px"
            @player_outcome(i).style.marginTop = "-#{Math.round t_h / 5}px"

            @refresh_micro_tile i, c_h

            @player_card(i).style.height = "#{@player_card_height}px"

    refresh_player_cards_position: (container_size) ->
        unless container_size?
            container_size = @player_card_container(1).offsetHeight
        margin = (container_size - @player_card_height) / 2
        for i in [1, 2]
            @player_card_container(i).style.height = "#{container_size}px"
            @player_card(i).style.marginTop = "#{margin}px"
            @player_card(i).style.marginBottom = "#{margin}px"

    set_border_radius: (el, border_radius) ->
        el.style.borderRadius = border_radius
        el.style.MozBorderRadius = border_radius
        el.style.WebkitBorderRadius = border_radius

    min_margin: (in_size) ->
        in_size / @tile_count_by_side / 3.5

    measure_gameboard_size: (in_size) ->
        tile_size = Math.floor((in_size - 2 * @min_margin(in_size)) / @tile_count_by_side)
        Math.min(tile_size * @tile_count_by_side, @gameboard_max_size)

    refresh_micro_tile: (num, in_size) ->
        unit = in_size / 10
        border = Math.max Math.round(unit), 1
        size = Math.round 8 * unit
        margin = Math.round 2 * unit

        for tile in document.getElementById("player#{num}_plays_count").children
            tile.style.margin = "0 #{margin}px"
            @set_border_radius tile, "#{2 * unit}px"
            tile.style.width = "#{size}px"
            tile.style.height = "#{size}px"
            tile.style.borderWidth = "#{border}px"

    refresh_controls_height: (height) ->
        @controls().style.height = "#{height}px"
        @controls().style.lineHeight = "#{height}px"
        @controls().style.marginBottom = "#{height}px"
        for control in @controls().children
            control.style.height = "#{height}px"
            control.style.width = "#{height}px"
            control.style.margin = "0 #{height / 4}px"

    controls_height: (gameboard_size) ->
        Math.round gameboard_size / 14

    controls_hidden: ->
        @controls().style.display == "none"

    measure_image_size: (gameboard_size) ->
        Math.round gameboard_size / 4.2

    measure_container_height: (ideal_height, gameboard_size, margin) ->
        image_size = @measure_image_size(gameboard_size)
        image_height = @player_image_sizes(image_size)[0]
        console.log image_size
        Math.max ideal_height, image_size + gameboard_size + 3 * margin

    player_image_sizes: (image_size) ->
        h_w = image_size * 3 / 88
        h_s = image_size + 4 * h_w
        t_h = Math.max Math.round(image_size / 6.4), 7
        t_m = Math.max Math.round(image_size / 20), 2
        c_h = Math.max Math.round(image_size / 8.6), 4
        height = image_size + t_h + 2 * t_m + c_h
        [height, t_h, t_m, c_h, h_s, h_w]

