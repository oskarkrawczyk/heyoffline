# extend object with another objects
extend = (obj, extensions...) ->
  (obj[key] = value) for key, value of ext for ext in extensions
  obj
  
addEvent = (element, event, fn, useCapture = true) ->
  element.addEventListener event, fn, useCapture
  
setStyles = (element, styles) ->
  for key of styles
    value = styles[key]
    element.style[key] = if not isNaN value then "#{value}px" else value
    
destroy = (element) ->
  element.parentNode.removeChild element
  
class Heyoffline
  
  # default options
  options:
    text:
      title: "You’re currently offline"
      content: "Seems like you’ve gone offline,
                you might want to wait until your network comes back before continuing.<br /><br />
                This message will self-destruct once you’re online again."
      button: "Relax, I know what I’m doing"
    monitorFields: false
    prefix: 'heyoffline'
    noStyles: false
    disableDismiss: false
    elements: ['input', 'select', 'textarea', '*[contenteditable]']
    # onOnline: ->
    #   console.log 'online', this
    # onOffline: ->
    #   console.log 'offline', this
    
  # set a global flag if any field on the page has been modified
  modified: false
  
  constructor: (options) ->
    extend @options, options
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
        background: 'rgba(0, 0, 0, 0.3)'
      modal:
        padding: 15
        background: '#fff'
        boxShadow: '0 2px 30px rgba(0, 0, 0, 0.3)'
        width: 450
        margin: '0 auto'
        position: 'relative'
        top: '30%'
        color: '#444'
        borderRadius: 2
      heading:
        fontSize: '1.7em'
        paddingBottom: 15
      content:
        paddingBottom: 15
      button:
        fontWeight: 'bold'
        cursor: 'pointer'
        
    @attachEvents()
    
  createElements: ->
    
    # overlay
    @createElement document.body, 'overlay'
    @resizeOverlay()
    
    # modal
    @createElement @elements.overlay, 'modal'
    
    # heading
    @createElement @elements.modal, 'heading', @options.text.title
    
    # content
    @createElement @elements.modal, 'content', @options.text.content
    
    # button
    if not @options.disableDismiss
      @createElement @elements.modal, 'button', @options.text.button
      addEvent @elements.button, 'click', @hideMessage
      
  createElement: (context, element, text) ->
    @elements[element].setAttribute 'class', "#{@options.prefix}_#{element}"
    @elements[element] = context.insertBefore @elements[element]
    @elements[element].innerHTML = text if text
    setStyles @elements[element], @defaultStyles[element] unless @options.noStyles
    
  resizeOverlay: ->
    setStyles @elements.overlay,
      height: window.innerHeight
      
  destroyElements: ->
    destroy @elements.overlay if @elements.overlay
    
  attachEvents: ->
    @elementEvents field for field in @elements.fields
    @networkEvents event for event in @events.network
    
    addEvent window, 'resize', =>
      @resizeOverlay()
      
  elementEvents: (field) ->
    for event in @events.element
      do (event) =>
        addEvent field, event, =>
          @modified = true
          
  networkEvents: (event) ->
    addEvent window, event, @[event]
    
  online: =>
    @hideMessage()
    
  offline: =>
    if @options.monitorFields
      @showMessage() if @modified
    else
      @showMessage()
      
  showMessage: ->
    @createElements()
    @options.onOnline.call this if @options.onOnline
    
  hideMessage: (event) =>
    event.preventDefault() if event
    @destroyElements()
    @options.onOffline.call this if @options.onOffline
    
addEvent window, 'load', ->
  window.Heyoffline = new Heyoffline
