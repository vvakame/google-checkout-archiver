debug = true

log = ->
  console.log.apply(console, arguments) if debug

# OrderNumber を収集する
collectOrderNumbers = ->
  orderNumberList = []
  $("a#orderNumLink").each ->
    el = $(this)
    orderNumber = el.text()
    orderNumberList.push orderNumber

  return orderNumberList

#### DOMから必要なパーツを拾い集める

pickupButton = (orderNumber) ->
  $("input#actionButton#{orderNumber}")

pickupTableRow = (orderNumber) ->
  td = $("td#cell#{orderNumber}")
  td.parent()

pickupFooterRow = ->
  footerTable = $(".tfoot")
  tr = footerTable.find "tr"
  tr.first()

#### DOMに要素を追加する

insertCheckbox = (tableRow, id)->
  check = $("<input type=\"checkbox\" id=\"#{id}\"/>")
  td = $("<td/>").append(check)
  tableRow.prepend(td)
  check

#### 要素の判定

isArchiveButton = (button)->
  button.attr("name") == "archiveButton"

isShipButton = (button)->
  button.attr("name") == "closeOrderButton"

#### ボタン押下後の処理

createArchiveFunction = (button) ->
  -> button.click()

createShipFunction = (button)->
  func = ->
    button.click()
    iframe = $("#shipItemsDiv")

    iframe.load ->
      button = $(this.contentDocument).find("input[name=shipButton]")
      button.click()

  return func

#### 各モデル&View作成を行うクラス

# 1明細を表す
class OrderData
  orderNumber:null
  processFunction: null
  enabled: false

  constructor: (@orderNumber)->
    _.bindAll @

    button = pickupButton orderNumber

    if isArchiveButton button
      @processFunction = createArchiveFunction button
    else if isShipButton button
      @processFunction = createShipFunction button

    # construct UI
    checkbox = insertCheckbox (pickupTableRow @orderNumber), "vv-archiver-#{@orderNumber}"
    checkbox.change (event)=>
      @enabled = checkbox.attr('checked') == "checked"

  process: ->
    log "process!! #{@orderNumber}"
    @processFunction() if @enabled

  getOrderNumber: ->
    @orderNumber

  getEnabled: ->
    @enabled

# 表示されている全明細を表す
class OrderDataList
  orderDataList = []

  constructor: ->
    _.bindAll @

    orderNumberList = collectOrderNumbers()
    @orderDataList = _.map orderNumberList, (orderNumber)-> new OrderData(orderNumber)

    # construct UI
    checkbox = insertCheckbox $(".theader"), "vv-archiver-parent"

  process: ->
    log "start process"
    enabledList = _.filter @orderDataList, (data)-> data.getEnabled()
    log enabledList
    enabledList[0].process() if enabledList.length != 0

# 画面下部にArchiveボタンを表示
class ProcessView
  orderDataList: []

  constructor: ->
    _.bindAll @

    @orderDataList = new OrderDataList()

    # construct UI
    footerRow = pickupFooterRow()
    button = $("<input type=\"button\" value=\"Archive\" />")
    button.click => @orderDataList.process()
    footerRow.prepend button

#### 実際の処理を開始する

new ProcessView()