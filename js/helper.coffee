---
---

isMobile = navigator.userAgent.match(/Android/i) ||
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
