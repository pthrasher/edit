Current State Of Affairs
------------------------

It's not currently rendering because I'm in the process of switching out the
renderer with a backbone view. It's honestly almost there. Only a few more
lines of code and the renderer will be working with the new format (more terse)
from the tokenizer.

The tokenizer is really fast, but that's not good enough for me. I want to
rewrite it as a set of smaller functions instead of one monolith maintaining
all of the state. There must be a faster way to do this, and I've been playing
around with a lot of tricks on jsperf.com to find the best tactics for
iteration.

Right now the tokenizer is really dumb... I'd like to add features to it, but
only if that means it will make it faster / not slow it down anymore. Right now
it will tokenize jquery (9,404 lines) in 150ms on decent hardware. While I feel
that is more than fast enough (since tokenizing a file is not done very often)
It should also be much faster. On slow hardware, or hardware that's busy with
other shit, this would take far too long.

#### Features to add to tokenizer:

1. smart retokenization. Given a line number that has changed, tokenize only
   lines that will truly need re-tokenizing.
1. Add useful meta info to each output line of tokens, most notably, add in
   what the token state was at the end of the line.

#### Features needed in general:

* Determine if there is a way to infer indentation rules from the GNU syntax
  highlight grammars. (really more of just a token key)
* If the above isn't possible, develop the easiest / simplest way to design
  this functionality. My initial thoughts were something like below (for
  javascript)

```javascript

// Note: the below regexes are probably wrong... This is just to demo the idea
// behind easily handling a definition of how to properly indent a language.
var indent = [
    [
        /(if|while|else|else if|function).*{[^}]?$/gi,
        1 // 1 denotes an increase in indentation on the following line(s)
    ], [
        /[^{]?}/gi,
        -1 // -1 denotes an increase in indentation.
    ], [
        /(return|continue|break)/gi,
        -1
    ]
]
```


TODO:
-----

1. Finish renderer to render tokens as is.
1. Rewrite tokenizer -- cut up into smaller functions, and optimize where
   possible.
1. Handle more window events such as keypress, mouse click, hover, etc. do
   special tokenizing for urls and make them clickable within the editor.
1. Do more experiementing... Make cool shit.

Goals:
------

* Learn how this stuff works.
* If it seems worth it, make this a real text editor.
* If making a real text editor, make it modal from the get-go. This way it will
  be easier to make it non-modal for those who don't want it that way as
  opposed to the other way around which is far more difficult (converting
  a non-modal text editor to a modal one via plugins)
* make a vim replacement that is awesome, and doesn't suck. Fix vim's problems
  (blocking while plugins do work, etc)


