---
---

class @ClickHandler
    constructor: (@element) ->
        if window.Touch
            @element.addEventListener 'touchstart', this, false

    handleEvent: (event) ->
        switch event.type
            when 'touchstart' then this.onTouchStart event
            when 'touchmove'  then this.onTouchMove
            when 'touchend'   then this.onTouchEnd event

    onTouchStart: (event) ->
        event.preventDefault()
        @moved = false

        @element.addEventListener 'touchmove', this, false
        @element.addEventListener 'touchend', this, false

    onTouchMove: ->
        @moved = true

    onTouchEnd: (event) ->
        @element.removeEventListener 'touchmove', this, false
        @element.removeEventListener 'touchend', this, false

        unless @moved
            target = @element
            event = document.createEvent 'MouseEvents'
            event.initEvent 'click', true, true
            target.dispatchEvent event
