---
---

class @ClickHandler
    constructor: (@element, @callback) ->
        if window.Touch
            @element.addEventListener 'touchstart', this, false
        else
            @element.addEventListener 'click', this, false

    handleEvent: (event) ->
        switch event.type
            when 'touchstart' then this.onTouchStart()
            when 'touchmove'  then this.onTouchMove()
            when 'touchend'   then this.onTouchEnd()
            when 'click'      then this.onClick()

    onClick: () ->
        this.onTouchStart()
        this.onTouchEnd()

    onTouchStart: () ->
        @moved = false

        @element.addEventListener 'touchmove', this, false
        @element.addEventListener 'touchend', this, false

    onTouchMove: () ->
        @moved = true

    onTouchEnd: (event) ->
        @element.removeEventListener 'touchmove', this, false
        @element.removeEventListener 'touchend', this, false

        unless @moved
            @callback()
