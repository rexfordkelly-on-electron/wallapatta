OPERATOR = "tag strong"
OPERATOR_INLINE = "string"

class Mode
 constructor: (CodeMirror) ->
  @CodeMirror = CodeMirror
  @CodeMirror.defineMode "docscript", (@defineMode.bind this), "xml"
  @CodeMirror.defineMIME "text/x-docscript", "docscript"

 defineMode: (cmCfg, modeCfg) ->
  @htmlMode = @CodeMirror.getMode cmCfg, name: "xml", htmlMode: true
  @getMode()

 matchBlock: (stream, state) ->
  stack = state.stack

  match = stream.match /^<<</
  if match
   stack.push indentation: stream.indentation(), type: 'html'
   stream.skipToEnd()
   state.htmlState = @CodeMirror.startState @htmlMode
   return OPERATOR

  match = stream.match /^\+\+\+/
  if match
   stack.push indentation: stream.indentation(), type: 'special'
   stream.skipToEnd()
   return OPERATOR

  match = stream.match /^>>>/
  if match
   stack.push indentation: stream.indentation(), type: 'sidenote'
   stream.skipToEnd()
   return OPERATOR

  match = stream.match /^```/
  if match
   stack.push indentation: stream.indentation(), type: 'code'
   stream.skipToEnd()
   return OPERATOR

  return null

 matchStart: (stream, state) ->
  match = stream.match /^\!/
  if match
   state.media = true
   return OPERATOR
  match = stream.match /^\* /
  if match
   @clearState state
   return OPERATOR
  match = stream.match /^- /
  if match
   @clearState state
   return OPERATOR
  match = stream.match /^#/
  if match
   stream.eatWhile '#'
   @clearState state
   state.heading = true
   return "#{OPERATOR} header"

 matchInline: (stream, state) ->
  match = stream.match /^``/
  if match
   state.code = not state.code
   return OPERATOR_INLINE

  if state.code
   return null

  match = stream.match /^\*\*/
  if match
   state.bold = not state.bold
   return OPERATOR_INLINE

  match = stream.match /^--/
  if match
   state.italics = not state.italics
   return OPERATOR_INLINE

  match = stream.match /^__/
  if match
   state.subscript = not state.subscript
   return OPERATOR_INLINE

  match = stream.match /^\^\^/
  if match
   state.superscript = not state.superscript
   return OPERATOR_INLINE

  match = stream.match /^<</
  if match
   state.link = true
   return OPERATOR_INLINE

  match = stream.match /^>>/
  if match
   state.link = false
   return OPERATOR_INLINE

  return null

 clearState: (state) ->
  state.bold = false
  state.italics = false
  state.subscript = false
  state.superscript = false
  state.code = false
  state.link = false

 startState: ->
  stack: []
  htmlState: null
  start: true

  bold: false
  italics: false
  subscript: false
  superscript: false
  code: false
  link: false

  heading: false
  media: false

 blankLine: (state) ->
  @clearState state

 token: (stream, state) ->
  if state.media
   stream.skipToEnd()
   state.media = false
   return "link"

  if stream.sol()
   state.start = true
   if state.heading
    state.heading = false
    @clearState state

   s = stream.eatSpace()
   if stream.eol()
    @clearState state

   return "" if s

  stack = state.stack

  if state.start
   while stack.length > 0
    if stack[stack.length - 1].indentation >= stream.indentation()
     stack.pop()
    else
     break

   types =
    sidenote: false
    html: false
    special: false
    code: false

   for t in stack
    types[t.type] = true

   if not types.code and not types.html
    match = @matchBlock stream, state
    return match if match?

  types =
   sidenote: false
   html: false
   special: false
   code: false

  for t in stack
   types[t.type] = true

  l = ""

  if types.html
   l = @htmlMode.token stream, state.htmlState
   l = "#{l}"
  else if types.code
   stream.skipToEnd()
   l = "meta"
  else
   if state.start
    match = @matchStart stream, state
    return match if match

   match = @matchInline stream, state
   return match if match?

   stream.next()
   state.start = false

   if state.heading
    l += " header"
   if state.bold
    l += " strong"
   if state.italics
    l += " em"
   if state.link
    l += " link"
   if state.code
    l += " meta"

  return l


 getMode: ->
  self = this

  mode =
   fold: "indent"
   startState: @startState
   blankLine: (state) -> self.blankLine state
   token: (stream, state) -> self.token stream, state

  return mode


if define? and brackets?
 define (require, exports, module) ->
  "use strict"

  LanguageManager = brackets.getModule "language/LanguageManager"
  CodeMirror = brackets.getModule "thirdparty/CodeMirror2/lib/codemirror"

  new Mode CodeMirror

  lang = LanguageManager.defineLanguage "docscript",
   name: "Docscript"
   mode: "docscript"
   fileExtensions: [".ds"]
   lineComment: ["\/\/"]

  lang.done ->
   console.log "[Docscript] Module loaded."

else if CodeMirror?
 new Mode CodeMirror