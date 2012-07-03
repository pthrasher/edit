# vim: et:ts=4:sw=4:sts=4
define ->

    tokenize = (source, syntax) ->
        '''
        Loop through every line in source, check the syntax for matching
        patterns, jump to proper states within the syntax, tokenize all
        the things!
        '''

        lines         = []
        lineIdx       = 0
        tokens        = lines[lineIdx] = []
        stack         = []
        stateIdx      = 0
        state         = syntax[0] # This is always the initial state.
        pos           = 0
        linePos       = 0
        style         = null
        EOL           = /\r\n|\r|\n/g
        EOL.lastIndex = 0
        matchCache    = []

        genToken = (text, _style) ->
            '''
            Generates a token given a style, and some text.
            This is a utility function for DRYness' sake.
            '''
            return unless text.length > 0
            unless stack.length is 0
                # Get the current pattern
                pattern = stack[stack.length - 1]
                
                # Is this an environment?
                unless pattern[3]
                    unless _style is 'url'
                        _style = pattern[1]

            # If the style has changed.
            if style isnt _style
                if style?
                    # has to exist in order to reset the styles.
                    tokens.push [
                        _style
                        __start
                        __stop
                    ]

                if _style?
                    # Add this new token to the list sans stopping point.
                    # No need to store the text. Keeps tokens small, and makes
                    # rendering faster.
                    __start = pos
                    if text.length is 1
                        __stop = pos + 1
                    else
                        __stop = pos + text.length

                    tokens.push [
                        _style
                        __start
                        __stop
                    ]

            else
                __start = pos
                if text.length is 1
                    __stop = pos + 1
                else
                    __stop = pos + text.length

                tokens.push [
                    _style
                    __start
                    __stop
                ]

            text = text
            pos += text.length
            style = _style

        
        # Begin main token-extraction loop.
        # Instead of splitting on all line endings, it's better to simply loop
        # through the string. We use far less memory this way.
        sourceLen = source.length
        while pos < sourceLen
            start    = pos # set a marker for the line position below
            eolMatch = EOL.exec source
            unless eolMatch?
                end      = sourceLen
                nextLine = sourceLen # next-line index (start of next line)
            else
                end      = eolMatch.index
                nextLine = EOL.lastIndex

            line = source.slice start, end + 1
            # Below, we'll cache the match objects to save cpu cycles
            matchCache = []

            loop
                linePos = pos - start # normalize our pos within current line.
                stackLen = stack.length # we use this a lot below. Good to cache.

                unless stackLen
                    stateIdx = 0
                else
                    stateIdx = stack[stackLen - 1][2]

                state    = syntax[stateIdx]
                stateLen = state.length
                mc = matchCache[stateIdx] = matchCache[stateIdx] ? []

                match = null # this will hold our best match if any.
                winner = null # will be a cache of the winning pattern if any.
                matchPatternIdx = -1 # used for a reference further down.

                for pattern, i in state
                    _match = null
                    haveCache = i < mc.length

                    if haveCache and (not mc[i]? or linePos <= mc[i].index)
                        # We have a cached match no need to actually do the
                        # search
                        _match = mc[i]
                    else
                        # No cached match. Let's run it and see.
                        regex = state[i][0]
                        regex.lastIndex = linePos # starting point for the re.
                        _match = regex.exec line
                        mc[i] = _match

                    if _match? and (not match? or _match.index < match.index)
                        # Either we didn't yet have any matches, or the
                        # starting index of this match is lower than our
                        # current best.
                        match = _match
                        winner = state[i] # cache the winning pattern.

                        # If the match is the current line pos, that's as
                        # good as it gets... Stop looking for better ones.
                        break if _match.index is linePos
                # End pattern loop.

                # Done testing for best match. Let's see if we had any hits.
                unless match?
                    # no more matches, just return the rest of this line.
                    genToken line.slice(linePos), null
                    # Add a "new line" token
                    lineIdx++
                    tokens = lines[lineIdx] = []
                    # Advance to the next line
                    pos = nextLine
                    break # break inf loop.
                else
                    # match hit! work some magic.
                    if match.index > linePos # is linePos wrong?
                        # the best match we could find is ahead of our pos.
                        # let's just go ahead and gen a token for the current
                        # stuff.
                        # t = line.slice(linePos, match.index)
                        # console.log t, style, style is null
                        genToken line.slice(linePos, match.index), null


                    # time to gen a token from our match.
                    _style = winner[1] # get the new style we should switch to
                    if toString.call(_style) == '[object Array]'
                        # This pattern had multiple match groups, and therefore
                        # means to emit multiple tokens.
                        for __style, i in _style
                            genToken match[i + 1], __style
                    else
                        # Just one matching string, and one matching style.
                        genToken match[0], _style

                    # Alter the state
                    # -1 means do nothing.
                    # -2 means remove current pattern from stack.
                    # -3 means kill entire stack.
                    # > -1 means push that pattern onto the stack.
                    switch winner[2]
                        when -2
                            stack.pop()
                        when -3
                            stack.splice 0 # quickly clear the entire stack.
                        else
                            unless winner[2] is -1 # do nothing if -1
                                stack.push winner
            # End line inf loop
            if style?
                # We had a valid token, we need to mark it's end point.
                # tokens[tokens.length - 1].stop = tokens[tokens.length - 1].stop + 1
                style = null # clear the style, we'll grab it again from the pattern.

        # end of loop over source contents
        lines


