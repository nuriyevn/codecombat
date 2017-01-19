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
    @throttleRate = 50
    super()

  startTimer: (@featureName) ->
    if not @featureName
      throw new Error('No view name!')
    if @running and window.performance.now() - @startTime > @throttleRate
      throw(new Error('Starting a timer over another one!'))
    if not @running and (not @startTime or window.performance.now() - @startTime > @throttleRate)
      @running = true
      @startTime = window.performance.now()

  stopTimer: ({ subtractTimeout = false, clearName = false } = { })->
    clearTimeout(@awayTimeoutId)
    if @running
      @running = false
      @endTime = if subtractTimeout then @lastActive else window.performance.now()
      timeViewed = @endTime - @startTime
      if timeViewed > @throttleRate # Prevent event spam when triggered in rapid succession
        window.tracker.trackEvent 'Premium Feature Viewed', { @featureName, timeViewed }
    @featureName = null if clearName
    
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
    @startTimer(@featureName) if not @running and @featureName
    
  onHidden: ->
    @stopTimer({ subtractTimeout: false })
    
  onVisible: ->
    @startTimer(@featureName) if @featureName
    
  destroy: ->
    @stopTimer()
    super()

module.exports = ViewVisibleTimer
