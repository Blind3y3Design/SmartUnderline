window.SmartUnderline =
  init: ->
  destroy: ->

return unless window['getComputedStyle'] and document.documentElement.getAttribute

selectionColor = '#b4d5fe'

linkColorAttrName = 'data-smart-underline-link-color'
linkSmallAttrName = 'data-smart-underline-link-small'
linkLargeAttrName = 'data-smart-underline-link-large'
linkContainerIdAttrName = 'data-smart-underline-container-id'

performanceTimes = []
time = -> + new Date

uniqueLinkContainerID = do ->
  id = 0
  return -> id += 1

isTransparent = (color) ->
  return true if color in ['transparent', 'rgba(0, 0, 0, 0)']
  rgbaAlphaMatch = color.match /^rgba\(.*,(.+)\)/i

  if rgbaAlphaMatch?.length is 2
    alpha = parseFloat rgbaAlphaMatch[1]

    if alpha < .0001
      return true

  return false

getBackgroundColorNode = (node) ->
  computedStyle = getComputedStyle node
  backgroundColor = computedStyle.backgroundColor

  parentNode = node.parentNode
  reachedRootNode = not parentNode or parentNode is document.documentElement or parentNode is node

  if computedStyle.backgroundImage isnt 'none'
    return null

  if isTransparent backgroundColor
    if reachedRootNode
      return node.parentNode or node

    else
      return getBackgroundColorNode parentNode

  else
    return node

getBackgroundColor = (node) ->
  backgroundColor = getComputedStyle(node).backgroundColor
  if node is document.documentElement and isTransparent backgroundColor
    return 'rgb(255, 255, 255)'
  else
    return backgroundColor

getLinkColor = (node) ->
  getComputedStyle(node).color

styleNode = document.createElement 'style'

init = (options) ->
  startTime = time()

  links = document.querySelectorAll "#{ if options.location then options.location + ' ' else '' }a"
  return unless links.length

  linkContainers = {}
  for link in links
    style = getComputedStyle link
    fontSize = parseFloat style.fontSize
    if style.textDecoration is 'underline' and style.display is 'inline' and fontSize >= 8
      container = getBackgroundColorNode link

      if container
        link.setAttribute linkColorAttrName, getLinkColor(link)

        if fontSize <= 14
          link.setAttribute linkSmallAttrName, ''

        if fontSize >= 20
          link.setAttribute linkLargeAttrName, ''

        id = container.getAttribute linkContainerIdAttrName

        if id
          linkContainers[id].links.push link
        else
          id = uniqueLinkContainerID()
          container.setAttribute linkContainerIdAttrName, id
          linkContainers[id] =
            container: container
            links: [link]

  styles = ''

  for id, container of linkContainers
    linkColors = {}
    linkColors[getLinkColor link] = true for link in container.links

    backgroundColor = getBackgroundColor container.container

    for color of linkColors
      linkSelector = """[#{ linkContainerIdAttrName }="#{ id }"] a[#{ linkColorAttrName }="#{ color }"]"""
      linkSmallSelector = """#{ linkSelector }[#{ linkSmallAttrName }]"""
      linkLargeSelector = """#{ linkSelector }[#{ linkLargeAttrName }]"""

      styles += """
        #{ linkSelector }, #{ linkSelector }:visited {
          color: #{ color };
          text-decoration: none !important;
          text-shadow: 0.03em 0 #{ backgroundColor }, -0.03em 0 #{ backgroundColor }, 0 0.03em #{ backgroundColor }, 0 -0.03em #{ backgroundColor }, 0.06em 0 #{ backgroundColor }, -0.06em 0 #{ backgroundColor }, 0.09em 0 #{ backgroundColor }, -0.09em 0 #{ backgroundColor }, 0.12em 0 #{ backgroundColor }, -0.12em 0 #{ backgroundColor }, 0.15em 0 #{ backgroundColor }, -0.15em 0 #{ backgroundColor };
          background-color: transparent;
          background-image: -webkit-linear-gradient(#{ backgroundColor }, #{ backgroundColor }), -webkit-linear-gradient(#{ backgroundColor }, #{ backgroundColor }), -webkit-linear-gradient(#{ color }, #{ color });
          background-image: -moz-linear-gradient(#{ backgroundColor }, #{ backgroundColor }), -moz-linear-gradient(#{ backgroundColor }, #{ backgroundColor }), -moz-linear-gradient(#{ color }, #{ color });
          background-image: -o-linear-gradient(#{ backgroundColor }, #{ backgroundColor }), -o-linear-gradient(#{ backgroundColor }, #{ backgroundColor }), -o-linear-gradient(#{ color }, #{ color });
          background-image: -ms-linear-gradient(#{ backgroundColor }, #{ backgroundColor }), -ms-linear-gradient(#{ backgroundColor }, #{ backgroundColor }), -ms-linear-gradient(#{ color }, #{ color });
          background-image: linear-gradient(#{ backgroundColor }, #{ backgroundColor }), linear-gradient(#{ backgroundColor }, #{ backgroundColor }), linear-gradient(#{ color }, #{ color });
          -webkit-background-size: 0.05em 1px, 0.05em 1px, 1px 1px;
          -moz-background-size: 0.05em 1px, 0.05em 1px, 1px 1px;
          background-size: 0.05em 1px, 0.05em 1px, 1px 1px;
          background-repeat: no-repeat, no-repeat, repeat-x;
          background-position: 0% 90%, 100% 90%, 0% 90%;
        }

        #{ linkSmallSelector } {
          background-position: 0% 96%, 100% 96%, 0% 96%;
        }

        #{ linkLargeSelector } {
          background-position: 0% 87%, 100% 87%, 0% 87%;
        }

        #{ linkSelector }::selection {
          text-shadow: 0.03em 0 #{ selectionColor }, -0.03em 0 #{ selectionColor }, 0 0.03em #{ selectionColor }, 0 -0.03em #{ selectionColor }, 0.06em 0 #{ selectionColor }, -0.06em 0 #{ selectionColor }, 0.09em 0 #{ selectionColor }, -0.09em 0 #{ selectionColor }, 0.12em 0 #{ selectionColor }, -0.12em 0 #{ selectionColor }, 0.15em 0 #{ selectionColor }, -0.15em 0 #{ selectionColor };
          background: #{ selectionColor };
        }

        #{ linkSelector }::-moz-selection {
          text-shadow: 0.03em 0 #{ selectionColor }, -0.03em 0 #{ selectionColor }, 0 0.03em #{ selectionColor }, 0 -0.03em #{ selectionColor }, 0.06em 0 #{ selectionColor }, -0.06em 0 #{ selectionColor }, 0.09em 0 #{ selectionColor }, -0.09em 0 #{ selectionColor }, 0.12em 0 #{ selectionColor }, -0.12em 0 #{ selectionColor }, 0.15em 0 #{ selectionColor }, -0.15em 0 #{ selectionColor };
          background: #{ selectionColor };
        }
      """

  styleNode.innerHTML = styles
  document.body.appendChild styleNode

  performanceTimes.push time() - startTime

destroy = ->
  styleNode.parentNode?.removeChild styleNode

  for attribute in [linkColorAttrName, linkSmallAttrName, linkLargeAttrName, linkContainerIdAttrName]
    Array::forEach.call document.querySelectorAll("[#{ attribute }]"), (node) ->
      node.removeAttribute attribute

window.SmartUnderline =
  init: (options = {}) ->
    if document.readyState is 'loading'
      window.addEventListener 'DOMContentLoaded', ->
        init options

      window.addEventListener 'load', ->
        destroy()
        init options

    else
      destroy()
      init options

  destroy: ->
    destroy()

  performanceTimes: ->
    performanceTimes
