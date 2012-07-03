# vim: et:ts=4:sw=4:sts=4

define ['jquery', 'cs!tokenizer', 'syntax_js', 'theme_bright', 'text!jquery.dev.js', 'underscore'], ($, tokenize, synJs, theme, jqtxt) ->
    class Document
        padding: [5, 5, 5, 5]
        lineHeight: 15
        fontSize: 12
        fontFamily: "Menlo"
        content: jqtxt
        cursorPosition:[0,0]

    class Renderer
        highlight:true
        _offset:0
        lastOffset:0
        t:''
        tokens:[]
        fontWeight:null
        fontStyle:null
        color:null
        stroke:null
        setOffset: (val) =>
            @lastOffset = @_offset
            @_offset = val
            @_redraw()
        getOffset: =>
            @_offset
        constructor: (@document, @tokenizer, @syntax) ->
            @density = window.devicePixelRatio
            @width = $(window).width()
            @height = $(window).height()
            @$canvas = $('<canvas />').appendTo('body')
                .attr('id', 'editor')
                .attr('width', @width * @density)
                .attr('height', @height * @density)
                .width(@width)
                .height(@height)

            @canvas = @$canvas[0]

            @ctx = @canvas.getContext '2d'
            @ctx.scale @density, @density

            @setStyles 'normal', 'normal', '#333', '#333'
            @redraw = _.debounce @_redraw, 250

            $(window).resize @resize
            @$canvas.click @_redraw

        resize: =>
            @width = $(window).width()
            @height = $(window).height()
            @$canvas
                .attr('width', @width * @density)
                .attr('height', @height * @density)
                .width(@width)
                .height(@height)
            @redraw()

        clear: =>
            @ctx.save()
            @ctx.setTransform 1, 0, 0, 1, 0, 0
            @ctx.clearRect 0, 0, @canvas.width, @canvas.height
            @ctx.restore()

        setStyles: (fontStyle, fontWeight, color, stroke) =>
            '''
            Only change styles when absolutely necessary.
            Saves a ton of friggin time.
            '''
            fontChanged = false
            if fontStyle?  and fontStyle isnt @fontStyle
                fontChanged = true
                @fontStyle = fontStyle
            if fontWeight? fontWeight isnt @fontWeight
                fontChanged = true
                @fontWeight = fontWeight

            if color? and color isnt @color
                @color = color
                @ctx.fillStyle = color

            if stroke? and stroke isnt @stroke
                @stroke = stroke
                @ctx.strokeStyle = stroke
    
            if fontChanged
                @ctx.font = "#{fontStyle} normal #{fontWeight} #{@document.fontSize}px #{@document.fontFamily}"


        _redraw: () =>
            @clear()

            t       = @document.content
            p       = @document.padding[0]
            if t isnt @t
                console.log "#{start = +new Date()}"
                @tokens = @tokenizer t, @syntax
                console.log "#{+new Date() - start}"
            tokens = @tokens
            @t = t
            x       = p
            lineNum = 1
            y = (lineNum * @document.lineHeight) + @_offset
            s       = 0
            e       = 0

            setStyles = (style) =>
                fstyle = theme[style]['font-style'] ? 'normal'
                weight = theme[style]['font-weight'] ? 'normal'
                color = theme[style]['color'] ? '#333'
                td = theme[style]['text-decoration'] ? ''
                underline = td is 'underline'
                ulcolor = if underline then color else null

                @setStyles fstyle, weight, color, ulcolor

                underline

            underlineText = (w) =>
                @ctx.beginPath()
                @ctx.moveTo(x,y + 3)
                @ctx.lineTo(x+w,y + 3)
                @ctx.stroke()


            renderSlice = (__s, __e, style) =>

                # get text and clean it. Tokenizer leaves line endings, need to
                # take them out since we're only dealing with a single line at
                # a time anyway. -- these take up space in our calculations.
                text = t.slice __s, __e
                text = text.replace(/\r\n|\r|\n/g, '')
                tm = @ctx.measureText text

                if style and @highlight
                    if theme? and theme[style]?
                        underline = setStyles(style)
                        if underline
                            underlineText tm.width
                else
                    @setStyles 'normal', 'normal', '#333'

                @ctx.fillText text, x, y
                x += tm.width

            handleEOL = =>

                lineNum++
                y = (lineNum * @document.lineHeight) + @_offset
                x = p

            for token in tokens
                # if @interrupt
                #     return @interrupt = false

                _s = token.start
                _e = token.stop

                if token is "EOL"
                    handleEOL()
                    continue

                # dont' worry about tokens we can't see.
                if y < 0 or y > @canvas.height
                    s = _s
                    e = _e
                    continue

                if _s > e
                    renderSlice e, _s, null

                renderSlice _s, _e, token.style
                s = _s
                e = _e
                

    main = ->
        console.log tokenize jqtxt, synJs
        return

        d = new Document()
        r = new Renderer d, tokenize, synJs
        window.rend = r
        
        window.slowScroll = ->
            r.setOffset(r.getOffset() - 50)
            setTimeout window.slowScroll, 0

        $ ->
            $(window).on 'mousewheel wheel', (e) ->
                e.preventDefault()
                r.setOffset(r.getOffset() + (e.originalEvent.wheelDeltaY / 2))


    return {
        main
    }



