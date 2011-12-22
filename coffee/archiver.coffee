debug = true

log = ->
  console.log.apply(console, arguments) if debug

isHeader = (el)->
  el.children("th").length != 0

isData = (el)->
  el.children("td").length != 0

raiseError = ->
  throw new Error()

process = ->
  $("a#orderNumLink").each ->
    el = $(this)
    orderNumber = el.text()
    log orderNumber

  $("#inboxTable tr").each ->
    el = $(this)

    if isHeader el
      processHeader el
    else if isData el
      processData el
    else
      raiseError()

processHeader = (el)->
  check = $('<input type="checkbox"/>')

  td = $("<td/>").append(check)
  el.prepend(td)

processData = (el)->
  func = createAction el

  check = $('<input type="checkbox"/>')

  check.click func if func?

  td = $("<td/>").append(check)
  el.prepend(td)


createAction = (el)->

  pickupArchiveButton = (el)->
    button = $("input[name=archiveButton]", el)
    if button.length == 1
      return button.first()

    return null

  pickupShipButton = (el)->
    button = $("input[name=closeOrderButton]", el)
    if button.length == 1
      return button.first()

    return null

  createArchiveFunction = (el)->
    button = pickupArchiveButton el
    return null if not button?

    func = ->
      button.click()
    return func

  createShipFunction = (el)->
    button = pickupShipButton el
    return null if not button?

    func = ->
      button.click()
      iframe = $("#shipItemsDiv")

      iframe.load ->
        button = $(this.contentDocument).find("input[name=shipButton]")
        button.click()

    return func

  return createArchiveFunction(el) || createShipFunction(el)

process()
