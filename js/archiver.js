var createAction, debug, isData, isHeader, log, process, processData, processHeader, raiseError;

debug = true;

log = function() {
  if (debug) return console.log.apply(console, arguments);
};

isHeader = function(el) {
  return el.children("th").length !== 0;
};

isData = function(el) {
  return el.children("td").length !== 0;
};

raiseError = function() {
  throw new Error();
};

process = function() {
  $("a#orderNumLink").each(function() {
    var el, orderNumber;
    el = $(this);
    orderNumber = el.text();
    return log(orderNumber);
  });
  return $("#inboxTable tr").each(function() {
    var el;
    el = $(this);
    if (isHeader(el)) {
      return processHeader(el);
    } else if (isData(el)) {
      return processData(el);
    } else {
      return raiseError();
    }
  });
};

processHeader = function(el) {
  var check, td;
  check = $('<input type="checkbox"/>');
  td = $("<td/>").append(check);
  return el.prepend(td);
};

processData = function(el) {
  var check, func, td;
  func = createAction(el);
  check = $('<input type="checkbox"/>');
  if (func != null) check.click(func);
  td = $("<td/>").append(check);
  return el.prepend(td);
};

createAction = function(el) {
  var createArchiveFunction, createShipFunction, pickupArchiveButton, pickupShipButton;
  pickupArchiveButton = function(el) {
    var button;
    button = $("input[name=archiveButton]", el);
    if (button.length === 1) return button.first();
    return null;
  };
  pickupShipButton = function(el) {
    var button;
    button = $("input[name=closeOrderButton]", el);
    if (button.length === 1) return button.first();
    return null;
  };
  createArchiveFunction = function(el) {
    var button, func;
    button = pickupArchiveButton(el);
    if (!(button != null)) return null;
    func = function() {
      return button.click();
    };
    return func;
  };
  createShipFunction = function(el) {
    var button, func;
    button = pickupShipButton(el);
    if (!(button != null)) return null;
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
  return createArchiveFunction(el) || createShipFunction(el);
};

process();
