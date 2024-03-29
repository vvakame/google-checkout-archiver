var OrderData, OrderDataList, ProcessView, collectOrderNumbers, createArchiveFunction, createShipFunction, debug, insertCheckbox, isArchiveButton, isShipButton, log, pickupButton, pickupFooterRow, pickupTableRow, waitTime;

debug = true;

log = function() {
  if (debug) return console.log.apply(console, arguments);
};

waitTime = 2000;

collectOrderNumbers = function() {
  var orderNumberList;
  orderNumberList = [];
  $("a#orderNumLink").each(function() {
    return orderNumberList.push($(this).text());
  });
  return orderNumberList;
};

pickupButton = function(orderNumber) {
  return $("input#actionButton" + orderNumber);
};

pickupTableRow = function(orderNumber) {
  return $("td#cell" + orderNumber).parent();
};

pickupFooterRow = function() {
  var tr;
  tr = $(".tfoot").find("tr");
  return tr.first();
};

insertCheckbox = function(tableRow, id, tagName) {
  var check, td;
  tagName = tagName || "td";
  check = $("<input type=\"checkbox\" id=\"" + id + "\"/>");
  td = $("<" + tagName + "/>").append(check);
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
    var button, checkbox, row,
      _this = this;
    this.orderNumber = orderNumber;
    _.bindAll(this);
    button = pickupButton(orderNumber);
    if (isArchiveButton(button)) {
      this.processFunction = createArchiveFunction(button);
    } else if (isShipButton(button)) {
      this.processFunction = createShipFunction(button);
    }
    row = pickupTableRow(this.orderNumber);
    checkbox = insertCheckbox(row, "vv-archiver-" + this.orderNumber);
    checkbox.change(function() {
      return _this.enabled = checkbox.attr('checked') === "checked";
    });
  }

  OrderData.prototype.process = function() {
    log("process " + this.orderNumber);
    return this.processFunction();
  };

  OrderData.prototype.getOrderNumber = function() {
    return this.orderNumber;
  };

  OrderData.prototype.getCheckbox = function() {
    return $("#vv-archiver-" + this.orderNumber);
  };

  OrderData.prototype.getEnabled = function() {
    return this.enabled;
  };

  OrderData.prototype.setCheck = function() {
    var checkbox;
    this.enabled = true;
    checkbox = this.getCheckbox();
    checkbox.attr("checked", "checked");
    return checkbox.change();
  };

  return OrderData;

})();

OrderDataList = (function() {

  OrderDataList.prototype.orderDataList = [];

  OrderDataList.prototype.all = false;

  function OrderDataList() {
    var checkbox, orderNumberList,
      _this = this;
    _.bindAll(this);
    orderNumberList = collectOrderNumbers();
    this.orderDataList = _.map(orderNumberList, function(orderNumber) {
      return new OrderData(orderNumber);
    });
    checkbox = insertCheckbox($(".theader"), "vv-archiver-parent", "th");
    checkbox.change(function() {
      return _.map(_this.orderDataList, function(data) {
        var enable;
        enable = checkbox.attr('checked') === "checked";
        if (enable) {
          data.getCheckbox().attr("disabled", "true");
        } else {
          data.getCheckbox().attr("disabled", null);
        }
        return _this.all = enable;
      });
    });
  }

  OrderDataList.prototype.process = function() {
    var enabledList;
    log("start process");
    if (this.all) {
      log("process all invoice");
      this.save("all");
      if (this.orderDataList.length !== 0) return this.orderDataList[0].process();
    } else {
      log("process selected invoice");
      enabledList = _.filter(this.orderDataList, function(data) {
        return data.getEnabled();
      });
      this.save(_.map(enabledList, function(data) {
        return data.getOrderNumber();
      }));
      if (enabledList.length !== 0) return enabledList[0].process();
    }
  };

  OrderDataList.prototype.getCheckbox = function() {
    return $("#vv-archiver-parent");
  };

  OrderDataList.prototype.getOrderDataList = function() {
    return this.orderDataList;
  };

  OrderDataList.prototype.save = function(processList) {
    return localStorage["processList"] = processList;
  };

  OrderDataList.prototype.setCheck = function() {
    var checkbox;
    this.all = true;
    checkbox = this.getCheckbox();
    checkbox.attr("checked", "checked");
    return checkbox.change();
  };

  return OrderDataList;

})();

ProcessView = (function() {

  ProcessView.prototype.orderDataList = {};

  function ProcessView() {
    var button, footerRow,
      _this = this;
    _.bindAll(this);
    this.orderDataList = new OrderDataList();
    footerRow = pickupFooterRow();
    button = $("<input type=\"button\" value=\"Archive\" id=\"vv-archive\" />");
    button.click(function() {
      return _this.orderDataList.process();
    });
    footerRow.prepend(button);
  }

  ProcessView.prototype.restoreState = function() {
    var exec, orderNumberList, selectedOrderList, target,
      _this = this;
    target = localStorage["processList"];
    if (target == null) return;
    if (target === "all") {
      this.orderDataList.setCheck();
    } else {
      orderNumberList = target.split(",");
      selectedOrderList = [];
      _.map(this.orderDataList.getOrderDataList(), function(data) {
        return _.map(orderNumberList, function(orderNumber) {
          if (orderNumber === data.getOrderNumber()) {
            return selectedOrderList.push(data);
          }
        });
      });
      _.map(selectedOrderList, function(data) {
        return data.setCheck();
      });
    }
    exec = function() {
      return $("#vv-archive").click();
    };
    return setTimeout(exec, waitTime);
  };

  return ProcessView;

})();

new ProcessView().restoreState();
