CocoClass = require 'core/CocoClass'

idleTracker = new Idle
  onAway: ->
    Backbone.Mediator.publish 'view-visibility:away', {}
  onAwayBack: ->
    Backbone.Mediator.publish 'view-visibility:away-back', {}
  onHidden: ->
    Backbone.Mediator.publish 'view-visibility:hidden', {}
  onVisible: ->
    Backbone.Mediator.publish 'view-visibility:visible', {}
  awayTimeout: 1000

idleTracker.start()

class ViewVisibleTimer extends CocoClass
  subscriptions:
    'view-visibility:away': 'onAway'
    'view-visibility:away-back': 'onAwayBack'
    'view-visibility:hidden': 'onHidden'
    'view-visibility:visible': 'onVisible'
  
  constructor: () ->
    @running = false
    # If the user is inactive for this many seconds, stop the timer and
    #   record the time they were active (NOT including this timeout)
    # If they come back before this timeout, include the time they were "away"
    #   in the timer
    @awayTimeoutLimit = 5 * 1000
    @awayTimeoutId = null
    super()

  startTimer: (@viewName) ->
    if not @viewName
      throw new Error('No view name!')
    if @running and window.performance.now() - @startTime > 50
      throw(new Error('Starting a timer over another one!'))
    if not @running
      # console.log "Start timer!", @viewName
      # console.trace()
      @running = true
      @startTime = window.performance.now()

  stopTimer: ({ subtractTimeout = false, clearName = false } = { })->
    # console.log "stopTimer", @viewName
    # console.trace()
    clearTimeout(@awayTimeoutId)
    if @running
      @running = false
      @endTime = if subtractTimeout then @lastActive else window.performance.now()
      timeViewed = @endTime - @startTime
      window.tracker.trackEvent 'Premium Feature Viewed', { @viewName, timeViewed }
    @viewName = null if clearName
    
  markLastActive: ->
    @lastActive = window.performance.now()

  onAway: ->
    @markLastActive()
    e = new Error()
    if @running
      @awayTimeoutId = setTimeout(( =>
        @stopTimer({ subtractTimeout: true })
      ), @awayTimeoutLimit)
    
  onAwayBack: ->
    clearTimeout(@awayTimeoutId)
    @startTimer(@viewName) if not @running and @viewName
    
  onHidden: ->
    @stopTimer({ subtractTimeout: false })
    
  onVisible: ->
    @startTimer(@viewName) if @viewName
    
  destroy: ->
    @stopTimer()
    super()

module.exports = ViewVisibleTimer
