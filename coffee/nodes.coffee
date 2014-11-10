Mod.require 'Weya.Base',
 (Base) ->

  NODE_ID = 0

  TYPES =
   code: 'code'
   list: 'list'
   listItem: 'listItem'
   block: 'block'
   sidenote: 'sidenote'
   section: 'section'
   heading: 'heading'
   media: 'media'


  class Node extends Base
   @extend()

   @initialize (options) ->
    @indentation = options.indentation
    @_parent = null
    @children = []
    @id = NODE_ID
    @elems = {}
    NODE_ID++

   setParent: (parent) ->  @_parent = parent
   parent: -> @_parent

   _add: (node) ->
    node.setParent this
    @children.push node
    return node

   template: ->
    @$.elem = @div ".node", null

   render: (options) ->
    Weya elem: options.elem, context: this, @template
    options.nodes[@id] = this

    @renderChildren @elem, options

   renderChildren: (elem, options) ->
    for child in @children
     child.render
      elem: elem
      nodes: options.nodes



  class Text extends Node
   @extend()

   type: TYPES.text

   @initialize (options) ->
    @text = options.text

   template: ->
    @$.elem = @span ".text", @$.text



  class Block extends Node
   @extend()

   type: TYPES.block

   @initialize (options) ->
    @paragraph = options.paragraph

   add: ->
    throw new Error 'New line expected'

   addText: (text) ->
    if @children.length > 0
     text = " #{text}"
    @_add new Text text: text

   template: ->
    if @$.paragraph
     @$.elem = @p ".paragraph", null
    else
     @$.elem = @span ".block", null


  class Article extends Node
   @extend()

   type: TYPES.document

   @initialize (options) ->

   add: (node) -> @_add node

   template: ->
    @$.elem = @div ".article", null



  class Section extends Node
   @extend()

   type: TYPES.section

   @initialize (options) ->
    @heading = new Block indentation: options.indentation
    @level = options.level

   add: (node) -> @_add node

   template: ->
    @$.elem = @div ".section", ->
     h = switch @$.level
      when 1 then @h1
      when 2 then @h2
      when 3 then @h3
      when 4 then @h4
      when 5 then @h5
      when 6 then @h6

     @$.elems.heading = h.call this, ".heading", null
     @$.elems.content = @div ".content", null


   render: (options) ->
    Weya elem: options.elem, context: this, @template

    @heading.render
     elem: @elems.heading
     nodes: options.nodes

    @renderChildren @elems.content, options



  class List extends Node
   @extend()

   type: TYPES.list

   @initialize (options) ->
    @ordered = options.ordered

   add: (node) ->
    if node.type isnt TYPES.listItem
     throw new Error 'List item expected'
    if node.ordered isnt @ordered
     throw new Error 'List item type mismatch'

    @_add node

   template: ->
    if @$.ordered
     @$.elem = @ol ".list", null
    else
     @$.elem = @ul ".list", null



  class ListItem extends Node
   @extend()

   type: TYPES.listItem

   @initialize (options) ->
    @ordered = options.ordered

   add: (node) -> @_add node

   template: ->
    @$.elem = @li ".list-item", null


  class Sidenote extends Node
   @extend()

   type: TYPES.sidenote

   add: (node) -> @_add node


  Mod.set 'Docscript.Text', Text
  Mod.set 'Docscript.Block', Block
  Mod.set 'Docscript.Section', Section
  Mod.set 'Docscript.List', List
  Mod.set 'Docscript.ListItem', ListItem
  Mod.set 'Docscript.Sidenote', Sidenote
  Mod.set 'Docscript.Article', Article

  Mod.set 'Docscript.TYPES', TYPES