# vim: et:ts=4:sw=4:sts=4

define ['jquery', 'underscore', 'backbone'], ($) ->

    'use strict'

    class CanvasViewModel extends Backbone.Model
        '''
        This maintains some of the state for the CanvasView. Any data that
        needs actions taken when it is altered should be in here.
        '''
        defaults:
            offsetX: 0
            offsetY: 0
            padding: 5, 5, 5, 5

            # The view subscribes to changes to these three to update ctx.
            fillColor: '#333'
            strokeColor: '#333'
            fontSettings: "normal normal normal 12px menlo"
            bgColor: "#eee"

            lineHeight: 14
            fontWeight: 'normal'
            fontStyle: 'normal'
            textSize: 12
            fontFamily: "Menlo"
            tokens: null

        initialize: ->
            # give one field for the view to watch for changes on for all font
            # styles
            @on 'change:fontFamily', @setFontSettings
            @on 'change:fontStyle', @setFontSettings
            @on 'change:fontWeight', @setFontSettings
            @on 'change:fontSize', @setFontSettings

        setFontSettings: =>
            fS = @get 'fontStyle'
            fW = @get 'fontWeight'
            tS = @get 'textSize'
            fF = @get 'fontFamily'

            @set fontSettings: "#{fS} normal #{fW} #{tS}px #{fF}"

            if _fC isnt fC
                ctx.fillStyle = fC
            
            if _fS isnt fS
                ctx.strokeStyle = sC

            if _fW isnt fW or _fS isnt fS or _tS isnt tS or _fF isnt fF
                ctx.font = "#{_fS} normal #{_fW} #{_tS}px #{_fF}"


    class CanvasView extends Backbone.View
        tagName: 'canvas'
        id: 'editor'

        initialize: (options) ->

            @doc = options.document
            @tok = options.tokenizer

            @getContext()
            @doResize()

            @state = new CanvasViewModel()
            @state.set
                ctx: @ctx
            @state.setStyles(null)

            @watchStyles()
            @updateFont()
            @updateFillColor()
            @updateStrokeColor()

        updateFont: =>
            @ctx.font = @state.get 'fontSettings'

        updateFillColor: =>
            @ctx.fillStyle = @state.get 'fillColor'

        updateStrokeColor: =>
            @ctx.strokeStyle = @state.get 'strokeColor'

        watchStyles: =>
            '''
            Only update the styles when they've actually changed
            '''
            @state.on 'change:fontSettings', @updateFont
            @state.on 'change:fillColor', @updateFillColor
            @state.on 'change:strokeColor', @updateStrokeColor

        getContext: =>
            @ctx = @el.getContext '2d'
        
        doResize: =>
            @w = $(window).width()
            @h = $(window).height()

            # Necessary if you want the text to be properly anti-aliased
            @density = window.devicePixelRatio
            @el.width = @w * @density
            @el.height = @h * @density
            @ctx.scale @density, @density

            @$el.width @w
            @$el.height @h

        clear: =>
            '''
            Central method for clearing the screen. Right now it just wipes
            every time. In the future, we'll probably need to adapt this to
            try and intellegently decide between multiple clearing strategies.
            '''
            @ctx.save()
            @ctx.setTransform 1, 0, 0, 1, 0, 0
            @ctx.clearRect 0, 0, @canvas.width, @canvas.height
            @ctx.restore()

        doRedraw: =>
            @clear()
            @render()

        renderSlice: (text, style, x, y) ->

        renderLine: (tokens, text, x, y) ->
            s = 0
            e = 0
            _s = 0
            _e = 0
            for token in tokens
                _s = token[0]
                _e = token[1]

                if _s > e
                    snip = text.slice e, _s
                    snip = snip.replace /\r\n|\r|\n/g, ''
                    @state.set
                        fillColor: '#333'
                        strokeColor: '#333'
                        fontWeight: 'normal'
                        fontStyle: 'normal'

                    @ctx.fillText snip, x, y
                    w = @ctx.measureText snip
                    x += w.width

                





            

        render: (start=0, stop=-1) =>
            text = @doc.get 'content'
            tokens = @state.get 'tokens'
            return unless tokens

            padding = @state.get 'padding'
            offsetX = @state.get 'offsetX'
            offsetY = @state.get 'offsetY'

            paddingX = padding[3]
            paddingY = padding[0]

            if offsetY < 0
                paddingY = 0
            if offsetX < 0
                paddingX = 0
