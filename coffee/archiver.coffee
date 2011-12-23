debug = true

log = ->
  console.log.apply(console, arguments) if debug

waitTime = 2000

# OrderNumber を収集する
collectOrderNumbers = ->
  orderNumberList = []
  $("a#orderNumLink").each ->
    orderNumberList.push $(@).text()

  orderNumberList

#### DOMから必要なパーツを拾い集める

pickupButton = (orderNumber) ->
  $("input#actionButton#{orderNumber}")

pickupTableRow = (orderNumber) ->
  $("td#cell#{orderNumber}").parent()

pickupFooterRow = ->
  tr = $(".tfoot").find "tr"
  tr.first()

#### DOMに要素を追加する

insertCheckbox = (tableRow, id, tagName)->
  tagName = tagName || "td"
  check = $("<input type=\"checkbox\" id=\"#{id}\"/>")
  td = $("<#{tagName}/>").append(check)
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

  func

#### 各モデル&View作成を行うクラス

# 1明細を表す
class OrderData
  orderNumber:null
  processFunction:null
  enabled:false

  constructor:(@orderNumber)->
    _.bindAll @

    button = pickupButton orderNumber

    if isArchiveButton button
      @processFunction = createArchiveFunction button
    else if isShipButton button
      @processFunction = createShipFunction button

    # construct UI
    row = pickupTableRow @orderNumber
    checkbox = insertCheckbox row, "vv-archiver-#{@orderNumber}"
    checkbox.change =>
      @enabled = checkbox.attr('checked') == "checked"

  process:->
    log "process #{@orderNumber}"
    @processFunction()

  getOrderNumber:->
    @orderNumber

  getCheckbox:->
    $("#vv-archiver-#{@orderNumber}")

  getEnabled:->
    @enabled

  setCheck:->
    @enabled = true
    checkbox = @getCheckbox()
    checkbox.attr("checked", "checked")
    checkbox.change()

# 表示されている全明細を表す
class OrderDataList
  orderDataList :[]
  all :false

  constructor:->
    _.bindAll @

    orderNumberList = collectOrderNumbers()
    @orderDataList = _.map orderNumberList, (orderNumber)-> new OrderData(orderNumber)

    # construct UI
    checkbox = insertCheckbox $(".theader"), "vv-archiver-parent", "th"
    checkbox.change =>
      _.map @orderDataList, (data)=>
        enable = checkbox.attr('checked') == "checked"
        if enable
          data.getCheckbox().attr("disabled", "true")
        else
          data.getCheckbox().attr("disabled", null)
        @all = enable

  process:->
    log "start process"
    if @all
      log "process all invoice"
      @save "all"
      @orderDataList[0].process() if @orderDataList.length != 0
    else
      log "process selected invoice"
      enabledList = _.filter @orderDataList, (data)-> data.getEnabled()
      @save _.map enabledList, (data)-> data.getOrderNumber()
      enabledList[0].process() if enabledList.length != 0

  getCheckbox:->
    $("#vv-archiver-parent")

  getOrderDataList:->
    @orderDataList

  save:(processList)->
    localStorage["processList"] = processList

  setCheck:->
    @all = true
    checkbox = @getCheckbox()
    checkbox.attr("checked", "checked")
    checkbox.change()

# 画面下部にArchiveボタンを表示
class ProcessView
  orderDataList:{}

  constructor:->
    _.bindAll @

    @orderDataList = new OrderDataList()

    # construct UI
    footerRow = pickupFooterRow()
    button = $("<input type=\"button\" value=\"Archive\" id=\"vv-archive\" />")
    button.click => @orderDataList.process()
    footerRow.prepend button

  restoreState: ->
    # restore state from localStorege
    target = localStorage["processList"]
    return unless target?

    if target == "all"
      @orderDataList.setCheck()
    else
      orderNumberList = target.split(",")
      selectedOrderList = []

      _.map @orderDataList.getOrderDataList(), (data)=>
        _.map orderNumberList, (orderNumber)=>
          if orderNumber == data.getOrderNumber()
            selectedOrderList.push data

      _.map selectedOrderList, (data)->
        data.setCheck()

    exec = -> $("#vv-archive").click()
    setTimeout exec, waitTime

#### 実際の処理を開始する

new ProcessView().restoreState()
