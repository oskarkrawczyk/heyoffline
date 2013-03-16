# extend object with another objects
extend = (destination, source) ->
  if source
    for property of source
      if source[property] and source[property].constructor and source[property].constructor is Object
        destination[property] = destination[property] or {}
        arguments.callee destination[property], source[property]
      else
        destination[property] = source[property]
  destination

addEvent = (element, event, fn, useCapture = false) ->
  element.addEventListener event, fn, useCapture

setStyles = (element, styles) ->
  for key of styles
    element.style[key] = styles[key]

destroy = (element) ->
  element.parentNode?.removeChild(element)

class Heyoffline

  # default options
  options:
    text:
      title: "You're currently offline"
      content: "Seems like you've gone offline,
                you might want to wait until your network comes back before continuing.<br /><br />
                This message will self-destruct once you're online again."
      button: "Relax, I know what I'm doing"
    monitorFields: false
    prefix: 'heyoffline'
    noStyles: false
    disableDismiss: false
    elements: ['input', 'select', 'textarea', '*[contenteditable]']

    usePolling: false
    pollingInterval: 3000
    requestSettings:
      url: window.location.href
      cache: false
      type: "HEAD"
  # onOnline: ->
  #   console.log 'online', @
  # onOffline: ->
  #   console.log 'offline', @

  # set a global flag if any field on the page has been modified
  modified: false
  connectionStatus: "online"

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
        zIndex: 500
      modal:
        padding: '15px'
        background: '#fff'
        boxShadow: '0 2px 30px rgba(0, 0, 0, 0.3)'
        width: '450px'
        margin: '0 auto'
        position: 'relative'
        top: '30%'
        color: '#444'
        borderRadius: '2px'
        zIndex: 600
      heading:
        fontSize: '1.7em'
        paddingBottom: '15px'
      content:
        paddingBottom: '15px'
      button:
        fontWeight: 'bold'
        cursor: 'pointer'

    @attachEvents()

    if @options.usePolling and not @options.monitorFields

      startPollingOnWindowActive = => @startPolling(@online, @offline)
      document.addEventListener("visibilitychange", startPollingOnWindowActive)
      document.addEventListener("webkitvisibilitychange", startPollingOnWindowActive)
      document.addEventListener("msvisibilitychange", startPollingOnWindowActive)
      document.addEventListener("mozvisibilitychange", startPollingOnWindowActive)

      @startPolling(@online, @offline)

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
    @elements[element] = context.appendChild @elements[element]
    @elements[element].innerHTML = text if text
    setStyles @elements[element], @defaultStyles[element] unless @options.noStyles

  resizeOverlay: ->
    setStyles @elements.overlay,
      height: "#{window.innerHeight}px"

  destroyElements: ->
    destroy @elements.overlay if @elements.overlay

  attachEvents: ->
    @elementEvents field for field in @elements.fields

    if not @options.usePolling
      @networkEvents event for event in @events.network

    addEvent window, 'resize', =>
      @resizeOverlay()

  elementEvents: (field) ->
    for event in @events.element
      do (event) =>
        addEvent field, event, =>
          console.log('field event')
          console.log(field)
          @modified = true
          @testConnection(@online, @offline) if @options.usePolling

  networkEvents: (event) ->
    addEvent window, event, @[event]

  online: (event) =>
    if "online" isnt @connectionStatus
      @hideMessage()
      @connectionStatus = "online"

  offline: =>
    if "offline" isnt @connectionStatus
      if @options.monitorFields
        @showMessage() if @modified
      else
        @showMessage()

      @connectionStatus = "offline"

  showMessage: ->
    @createElements()
    @options.onOnline.call @ if @options.onOnline

  hideMessage: (event) =>
    event.preventDefault() if event
    @destroyElements()
    @options.onOffline.call @ if @options.onOffline


  isWindowActive: ->
    !(document.hidden || document.webkitHidden || document.msHidden || document.mozHidden)

  testConnection: (onlineCallback, offlineCallback) ->
    $.ajax(@options.requestSettings)
      .done(onlineCallback)
      .fail(offlineCallback)

  startPolling: (onlineCallback, offlineCallback) =>
    if @isWindowActive()
      @testConnection(onlineCallback, offlineCallback).always( =>
        scheduleNextCheck = => @startPolling(onlineCallback, offlineCallback)
        setTimeout(scheduleNextCheck, @options.pollingInterval))