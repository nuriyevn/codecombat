# http://stackoverflow.com/questions/1060008/is-there-a-way-to-detect-if-a-browser-window-is-not-currently-active

visibilityChange = (callback) ->
  onchange = (evt) ->
    v = 'visible'
    h = 'hidden'
    evtMap =
      focus: v
      focusin: v
      pageshow: v
      blur: h
      focusout: h
      pagehide: h
    evt = evt or window.event
    if evt.type of evtMap
      value = evtMap[evt.type]
    else
      value = if @[hidden] then 'hidden' else 'visible'
    return callback(value)
  
  hidden = 'hidden'
  # Standards:
  if hidden of document
    document.addEventListener 'visibilitychange', onchange
  else if (hidden = 'mozHidden') of document
    document.addEventListener 'mozvisibilitychange', onchange
  else if (hidden = 'webkitHidden') of document
    document.addEventListener 'webkitvisibilitychange', onchange
  else if (hidden = 'msHidden') of document
    document.addEventListener 'msvisibilitychange', onchange
  else if 'onfocusin' of document
    document.onfocusin = document.onfocusout = onchange
  else
    window.onpageshow = window.onpagehide = window.onfocus = window.onblur = onchange

  return

module.exports = visibilityChange
