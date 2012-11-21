# extend object with another objects
extend = (obj, extensions...) ->
  (obj[key] = value) for key, value of ext for ext in extensions
  obj

class Utilities
  
  log: ->
    console.log (if arguments.length <= 1 then arguments[0] else arguments) if typeof console isnt 'undefined'
  
  # set class options
  setOptions: (options) ->
    extend @options, options
    
  addEvent: (element, event, fn, useCapture = true) ->
    element.addEventListener event, fn, useCapture
    
  setStyles: (element, styles) ->
    for key of styles
      value = styles[key];
      element.style[key] = if not isNaN value then "#{value}px" else value
    
class Heyoffline extends Utilities
  
  # default options
  options:
    text:
      title: "You're currently offline"
      content: "Seems like you've became offline,
                you might want to wait until your network comes so you don't
                loose any data already entered into fields"
      button: "That's OK, I know what I'm doing"
    monitorFields: true
    delay: 1000
    prefix: 'heyoffline'
    customStyles: false
    enableDimiss: true
    elements: ['input', 'select', 'textarea', '*[contenteditable]']
  
  # set a global flag if any field on the page has been modified
  modified: false
  
  constructor: (options) ->
    @setOptions options
    
    @log @options # navigator.onLine
    
    @setup()
    
  setup: ->
    @events =
      element: ['keyup', 'change']
      network: ['online', 'offline']
    
    @elements =
      fields: document.querySelectorAll @options.elements.join ','
      overlay: document.createElement 'div'
      modal: document.createElement 'div'
      heading: document.createElement 'h2'
      content: document.createElement 'p'
      button: document.createElement 'a'
      
    @defaultStyles =
      overlay:
        position: 'absolute'
        top: 0
        left: 0
        width: '100%'
      modal:
        padding: 10
        background: '#fff'
        boxShadow: '0 0 20px rgba(0, 0, 0, 0.3)'
        width: 400
        margin: '10% auto'
      heading:
        color: '#f00'
      content:
        color: ''
      button:
        color: '#ccc'
      
    @attachEvents()
    @createElements()
  
  createElements: ->
    # overlay
    @elements.overlay.setAttribute 'class', "#{@options.prefix}_overlay"
    @elements.overlay = document.body.insertBefore @elements.overlay
    overlayStyles = extend @defaultStyles.overlay,
      background: 'rgba(0, 0, 0, 0.3)'
      height: window.innerHeight
      
    @setStyles @elements.overlay, overlayStyles
    
    # modal
    @elements.modal.setAttribute 'class', "#{@options.prefix}_modal"
    @elements.modal = @elements.overlay.insertBefore @elements.modal
    @setStyles @elements.modal, @defaultStyles.modal
    
    # heading
    @elements.heading.setAttribute 'class', "#{@options.prefix}_heading"
    @elements.heading = @elements.modal.insertBefore @elements.heading
    @setStyles @elements.heading, @defaultStyles.heading
    @elements.heading.innerHTML = @options.text.title
    
    # content
    @elements.content.setAttribute 'class', "#{@options.prefix}_content"
    @elements.content = @elements.modal.insertBefore @elements.content
    @setStyles @elements.content, @defaultStyles.content
    @elements.content.innerHTML = @options.text.content
    
    # button
    if @options.enableDimiss
      @elements.button.setAttribute 'class', "#{@options.prefix}_button"
      @elements.button.setAttribute 'href', '#dismiss-message'
      @elements.button = @elements.modal.insertBefore @elements.button
      @setStyles @elements.button, @defaultStyles.button
      @elements.button.innerHTML = @options.text.button
      @addEvent @elements.button, 'click', @hideMessage
    
    @log @elements.overlay
    
  destroyElements: ->
    @elements.overlay.parentNode.removeChild(@elements.overlay);
    
  attachEvents: ->
    @elementEvents field for field in @elements.fields
    @networkEvents event for event in @events.network
    
  elementEvents: (field) ->
    for event in @events.element
      do (event) =>
        @addEvent field, event, =>
          @modified = true
          
  networkEvents: (event) ->
    @addEvent window, event, @[event]
    
  online: =>
    @showMessage()
    
  offline: =>
    @hideMessage()
    
  showMessage: ->
    console.log 'offline'
    
  hideMessage: =>
    console.log 'online'
    @destroyElements()
    
window.addEventListener 'load', ->
  new Heyoffline
    delay: 2000
, true
