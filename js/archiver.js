var OrderData, OrderDataList, ProcessView, collectOrderNumbers, createArchiveFunction, createShipFunction, debug, insertCheckbox, isArchiveButton, isShipButton, log, pickupButton, pickupFooterRow, pickupTableRow;

debug = true;

log = function() {
  if (debug) return console.log.apply(console, arguments);
};

collectOrderNumbers = function() {
  var orderNumberList;
  orderNumberList = [];
  $("a#orderNumLink").each(function() {
    var el, orderNumber;
    el = $(this);
    orderNumber = el.text();
    return orderNumberList.push(orderNumber);
  });
  return orderNumberList;
};

pickupButton = function(orderNumber) {
  return $("input#actionButton" + orderNumber);
};

pickupTableRow = function(orderNumber) {
  var td;
  td = $("td#cell" + orderNumber);
  return td.parent();
};

pickupFooterRow = function() {
  var footerTable, tr;
  footerTable = $(".tfoot");
  tr = footerTable.find("tr");
  return tr.first();
};

insertCheckbox = function(tableRow, id) {
  var check, td;
  check = $("<input type=\"checkbox\" id=\"" + id + "\"/>");
  td = $("<td/>").append(check);
  tableRow.prepend(td);
  return check;
};

isArchiveButton = function(button) {
  return button.attr("name") === "archiveButton";
};

isShipButton = function(button) {
  return button.attr("name") === "closeOrderButton";
};

createArchiveFunction = function(button) {
  return function() {
    return button.click();
  };
};

createShipFunction = function(button) {
  var func;
  func = function() {
    var iframe;
    button.click();
    iframe = $("#shipItemsDiv");
    return iframe.load(function() {
      button = $(this.contentDocument).find("input[name=shipButton]");
      return button.click();
    });
  };
  return func;
};

OrderData = (function() {

  OrderData.prototype.orderNumber = null;

  OrderData.prototype.processFunction = null;

  OrderData.prototype.enabled = false;

  function OrderData(orderNumber) {
    var button, checkbox,
      _this = this;
    this.orderNumber = orderNumber;
    _.bindAll(this);
    button = pickupButton(orderNumber);
    if (isArchiveButton(button)) {
      this.processFunction = createArchiveFunction(button);
    } else if (isShipButton(button)) {
      this.processFunction = createShipFunction(button);
    }
    checkbox = insertCheckbox(pickupTableRow(this.orderNumber), "vv-archiver-" + this.orderNumber);
    checkbox.change(function(event) {
      return _this.enabled = checkbox.attr('checked') === "checked";
    });
  }

  OrderData.prototype.process = function() {
    log("process!! " + this.orderNumber);
    if (this.enabled) return this.processFunction();
  };

  OrderData.prototype.getOrderNumber = function() {
    return this.orderNumber;
  };

  OrderData.prototype.getEnabled = function() {
    return this.enabled;
  };

  return OrderData;

})();

OrderDataList = (function() {
  var orderDataList;

  orderDataList = [];

  function OrderDataList() {
    var checkbox, orderNumberList;
    _.bindAll(this);
    orderNumberList = collectOrderNumbers();
    this.orderDataList = _.map(orderNumberList, function(orderNumber) {
      return new OrderData(orderNumber);
    });
    checkbox = insertCheckbox($(".theader"), "vv-archiver-parent");
  }

  OrderDataList.prototype.process = function() {
    var enabledList;
    log("start process");
    enabledList = _.filter(this.orderDataList, function(data) {
      return data.getEnabled();
    });
    log(enabledList);
    if (enabledList.length !== 0) return enabledList[0].process();
  };

  return OrderDataList;

})();

ProcessView = (function() {

  ProcessView.prototype.orderDataList = [];

  function ProcessView() {
    var button, footerRow,
      _this = this;
    _.bindAll(this);
    this.orderDataList = new OrderDataList();
    footerRow = pickupFooterRow();
    button = $("<input type=\"button\" value=\"Archive\" />");
    button.click(function() {
      return _this.orderDataList.process();
    });
    footerRow.prepend(button);
  }

  return ProcessView;

})();

new ProcessView();
