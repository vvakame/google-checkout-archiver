debug = true

log = ->
  console.log.apply(console, arguments) if debug

# OrderNumber �����W����
collectOrderNumbers = ->
  orderNumberList = []
  $("a#orderNumLink").each ->
    el = $(this)
    orderNumber = el.text()
    orderNumberList.push orderNumber

  return orderNumberList

#### DOM����K�v�ȃp�[�c���E���W�߂�

pickupButton = (orderNumber) ->
  $("input#actionButton#{orderNumber}")

pickupTableRow = (orderNumber) ->
  td = $("td#cell#{orderNumber}")
  td.parent()

pickupFooterRow = ->
  footerTable = $(".tfoot")
  tr = footerTable.find "tr"
  tr.first()

#### DOM�ɗv�f��ǉ�����

insertCheckbox = (tableRow, id, tagName)->
  tagName = tagName || "td"
  check = $("<input type=\"checkbox\" id=\"#{id}\"/>")
  td = $("<#{tagName}/>").append(check)
  tableRow.prepend(td)
  check

#### �v�f�̔���

isArchiveButton = (button)->
  button.attr("name") == "archiveButton"

isShipButton = (button)->
  button.attr("name") == "closeOrderButton"

#### �{�^��������̏���

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

#### �e���f��&View�쐬���s���N���X

# 1���ׂ�\��
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
    log "process!! #{@orderNumber}"
  # @processFunction() if @enabled

  getOrderNumber:->
    @orderNumber

  getCheckbox:->
    $("#vv-archiver-#{@orderNumber}")

  getEnabled:->
    @enabled

  setCheck:(enabled)->
    if(enabled)
      @enabled = true
      checkbox = @getCheckbox()
      checkbox.attr("checked", "checked")
      checkbox.change()
    else
      @enabled = false
      checkbox = @getCheckbox()
      checkbox.attr("checked", null)
      checkbox.change()

# �\������Ă���S���ׂ�\��
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
    else
      log "process selected invoice"
      enabledList = _.filter @orderDataList, (data)-> data.getEnabled()
      @save _.map enabledList, (data)-> data.getOrderNumber()
      enabledList[0].process() if enabledList.length != 0

  getCheckbox:->
    $("#vv-archiver-parent")

  getOrderDataList:->
    @orderDataList

  setCheck:(all)->
    if(all)
      @all = true
      checkbox = @getCheckbox()
      checkbox.attr("checked", "checked")
      checkbox.change()
    else
      @all = false
      checkbox = @getCheckbox()
      checkbox.attr("checked", null)
      checkbox.change()

  save:(processList)->
    log processList
    localStorage["processList"] = processList


# ��ʉ�����Archive�{�^����\��
class ProcessView
  orderDataList:{}

  constructor:->
    _.bindAll @

    @orderDataList = new OrderDataList()

    # construct UI
    footerRow = pickupFooterRow()
    button = $("<input type=\"button\" value=\"Archive\" />")
    button.click => @orderDataList.process()
    footerRow.prepend button

    # restore state from localStorege
    target = localStorage["processList"]
    return unless target?

    if target == "all"
      @orderDataList.setCheck true
    else
      orderNumberList = target.split(",")
      selectedOrderList = []

      _.map @orderDataList.getOrderDataList(), (data)=>
        _.map orderNumberList, (orderNumber)=>
          if orderNumber == data.getOrderNumber()
            selectedOrderList.push data
      log selectedOrderList
      _.map selectedOrderList, (data)->
        data.setCheck true

    @orderDataList.process()

#### ���ۂ̏������J�n����

new ProcessView()