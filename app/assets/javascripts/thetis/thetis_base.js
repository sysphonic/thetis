/**-----------------**-----------------**-----------------**
 Copyright (c) 2007-2019, MORITA Shintaro, Sysphonic. [http://sysphonic.com/]
 This module is released under MIT License.
 **-----------------**-----------------**-----------------**/

function layoutBaseElem(mainWidth, mainHeight, init)
{
  var main_div = _z("main_div");
  main_div.style.height = (_mainHeight - (3+3)) + "px";

  var availHeight = main_div.offsetHeight;
  var availWidth = main_div.offsetWidth;

  var frameScrolling = null;
  var div = null;

  if (div = _z("div_desktop")) {

    frameScrolling = false

    var h = availHeight - 6;
    div.style.height = h + "px";

    var deskTrs = document.getElementsByClassName("desktop_tr");
    for (var i=0; deskTrs != null && i < deskTrs.length; i++) {
      deskTrs[i].style.height = (h-1) / deskTrs.length + "px";
    }
    var deskTds = document.getElementsByClassName("desktop_td");
    if (deskTds != null) {
      var deskColNum = deskTds.length / deskTrs.length;
      for (var i=0; i < deskColNum; i++) {
        deskTds[i].style.width = availWidth / deskColNum + "px";
      }
    }

    var toolbox = _z("toolbox");
    var toolbox_top = availHeight - 20;
    var toolbox_left = 40;
    if (toolbox != null) {
      toolbox_top = availHeight - toolbox.clientHeight - 20;
      toolbox.style.top = toolbox_top + "px";
      toolbox.style.left = toolbox_left + "px";
    }

    var menubox = _z("menubox");
    if (menubox != null) {
      menubox.style.top = (toolbox_top - 35) + "px";
      menubox.style.left = (toolbox_left + 30) + "px";
    }

  } else if (div = _z("div_list")) {

    frameScrolling = false;

    div.style.height = (availHeight - 95) + "px";

  } else if ((div = _z("divFolderTree")) || (div = _z("divGroupTree"))) {

    frameScrolling = false;

    var h = availHeight - ((_z("tr_admin_panel"))?(95):(54));

    div.style.height = h + "px";
   // Firefox: offsetHeight = style.height + style.paddingTop + style.paddingBottom
    if (div.offsetHeight != h) {
      h -= div.offsetHeight - h;
      div.style.height = h + "px";
    }

    var tree_main = _z("tree_main");
    var treeMainWidth = tree_main.offsetWidth - (3+7+3);
    div.style.width = treeMainWidth/100*37 + "px";

    var view = _z("div_view");
    view.style.height = div.offsetHeight + "px";
    view.style.width = (treeMainWidth/100*63) + "px";

    _z("td_tree").style.width = div.style.width;
    _z("td_view").style.width = view.style.width;

  } else if (div = _z("divMailTree")) {

    frameScrolling = false;

    var h = availHeight - 52;

    var td_tree = _z("td_tree");
    var td_view = _z("td_view");

    var div_mails = _z("div_mails");
    var div_mail_content = _z("div_mail_content");

    var tree_main = _z("tree_main");
    var treeMainWidth = tree_main.offsetWidth - (3+5+3);

    div.style.width = treeMainWidth / 4 + "px";
    div.style.height = (h - 44) + "px";

    td_tree.style.width = div.style.width;
    td_view.style.width   = treeMainWidth / 4 * 3 + "px";
    td_tree.style.height = h + "px" ;
    td_view.style.height  = td_tree.style.height;

    var mailTreePos = getPos(div);
    var borderPos = getPos(_z("drag_v_border"));
    var leftWidth = borderPos.x - mailTreePos.x;
    div_mails.style.width  = (treeMainWidth - leftWidth) + "px";
    div_mails.style.height = ((h-5) / 2) + "px";

    div_mail_content.style.width  = div_mails.style.width;
    div_mail_content.style.height = (h / 2) + "px";

    arrangeMailContentSection(div_mail_content);

  } else if (div = _z("div_users")) {

    frameScrolling = false;

    div.style.height = (availHeight - 120) + "px";

  } else if (div = _z("div_addresses")) {

    frameScrolling = false;

    div.style.height = (availHeight - 120) + "px";

  } else if (div = _z("div_logs")) {

    frameScrolling = false;

    div.style.height = (availHeight - 120) + "px";

  } else if (div = _z("div_teams")) {

    frameScrolling = false;

    div.style.height = (availHeight - 120) + "px";

  } else if (div = _z("div_equipment")) {

    frameScrolling = false;

    div.style.height = (availHeight - 120) + "px";

  } else if (div = _z("div_calendar")) {

    frameScrolling = (true);

    div.style.height = (availHeight - 100) + "px";

  } else if (div = _z("div_workflow_list")) {

    frameScrolling = false;

    div.style.height = (availHeight - 25) + "px";

    _z("workflow_list_received").style.height = (availHeight - 110) + "px";
    _z("div_ajax_workflow").style.height = (availHeight - 235) + "px";

  } else if (div = _z("div_login")) {

    frameScrolling = false;

    div.style.height = (availHeight - 20) + "px";

  } else {

    if (div = _z("div_item_workflow")) {
      div.style.height = (availHeight - 120) + "px";
    }
    if (div = _z("div_item_basic")) {
      div.style.height = (availHeight - 120) + "px";
    }
    if (div = _z("div_item_description")) {
      div.style.height = (availHeight - 120) + "px";
    }
    if (div = _z("div_item_image")) {
      div.style.height = (availHeight - 120) + "px";
    }
    if (div = _z("div_item_attachment")) {
      div.style.height = (availHeight - 120) + "px";
    }

    if (div = _z("div_research_records")) {
      div.style.height = (availHeight - 120) + "px";
    }
    if (div = _z("div_research_lists")) {
      div.style.height = (availHeight - 120) + "px";
    }

    frameScrolling = (div == null);
  }

  if (init && (frameScrolling != null)) {
    enableFrameScrolling(frameScrolling);
  }
}

function enableFrameScrolling(sw)
{
  var iframe_groupware = top._z("iframe_groupware");
  if (iframe_groupware) {
    iframe_groupware.style.overflow = (sw)?"auto":"hidden";
    document.body.style.overflow = (sw)?"auto":"hidden";
  }
}

function toSysDateForm(date)
{
  return date;
//  return replaceAll(date, "/", "-");
}

function removeOptionNotSelected(elem)
{
  if (!elem || !elem.options) {
    return;
  }

  var selected = false;
  for (var i=0; i < elem.options.length; i++) {
    if (elem.options[i].selected) {
      selected = true;
      break;
    }
  }
  if (!selected) {
    return;
  }

  for (var i=0; i < elem.options.length; i++) {
    var option = elem.options[i];
    if (option.value == "" && !option.selected) {
      elem.options[i] = null;
      break;
    }
  }
}

function isModelErrorContained(resText)
{
  if (!resText) {
    return false;
  }
  return (resText.indexOf("errorExplanation") >= 0);
}

function doUpdateView(method, action, addParams)
{
  if (!addParams) {
    addParams = [];
  }
  if (method == "post") {
    addParams.push("authenticity_token="+getCsrfToken());
  }

  var thetisBox = prog("TOP-RIGHT");
  new Ajax.Updater(
      "div_view",
      action,
      {
        method: method,
        parameters: addParams.join("&"),
        evalScripts: true,
        onComplete: function(request){ thetisBox.remove(); }
      }
    );
}

function bound(desktop, elem)
{
  var elem = _z(elem);

  var deskWidth = desktop.clientWidth;
  var deskHeight = desktop.clientHeight;
  var deskPos = Position.cumulativeOffset(desktop);

  var elemPos = Position.cumulativeOffset(elem);
  elem.style.position = "absolute";
  var elemWidth = elem.clientWidth;
  var elemHeight = elem.clientHeight;
  var boundMargin = 5;

  var updated = false;

  if (elemPos[0] < deskPos[0]) {
    elemPos[0] = deskPos[0] + boundMargin;
    updated = true;
  }
  if (elemPos[1] < deskPos[1]) {
    elemPos[1] = deskPos[1] + boundMargin;
    updated = true;
  }
  if (elemWidth < (deskWidth - 25 - boundMargin)
      && (elemPos[0] + elemWidth) > (deskPos[0] + deskWidth)) {
    elemPos[0] = deskPos[0] + deskWidth - elemWidth - 25;
    updated = true;
  }
  if (elemHeight < (deskHeight - 25 - boundMargin)
      && (elemPos[1] + elemHeight) > (deskPos[1] + deskHeight)) {
    elemPos[1] = deskPos[1] + deskHeight - elemHeight - 25;
    updated = true;
  }

  if (updated) {
    elem.style.left = elemPos[0] + "px";
    elem.style.top = elemPos[1] + "px";
  }
}

function getAxis(desktop, elem)
{
  var elem = _z(elem);
  var elemPos = Position.cumulativeOffset(elem);

  var deskWidth = desktop.clientWidth;
  var deskHeight = desktop.clientHeight;
  var deskPos = Position.cumulativeOffset(desktop);

  var xAxis = Math.floor(Math.max(0, elemPos[0]-deskPos[0]) / deskWidth * 10000);
  if (xAxis >= 10000) {
    xAxis = 9500;
  }
  var yAxis = Math.floor(Math.max(0, elemPos[1]-deskPos[1]) / deskHeight * 10000);
  if (yAxis >= 10000) {
    yAxis = 9500;
  }

  return [xAxis, yAxis];
}

function showTab(name, nameArray, bgcolor)
{
  var tab = null;
  for (var i=0; i < nameArray.length; i++) {
    tab = _z("tab_"+nameArray[i]);
    if (!tab) {
      continue;
    }
    if (name == nameArray[i]) {
      if (bgcolor) {
        tab.style.backgroundColor = bgcolor;
      }
      appendClassName(tab, "selected");
    } else {
      if (bgcolor) {
        tab.style.backgroundColor = "";
      }
      removeClassName(tab, "selected");
    }
  }

  for (var i=0; i < nameArray.length; i++) {
    div = _z("tab_div_"+nameArray[i]);
    if (div != null) {
      div.style.display = "none";
    }
  }

  div = _z("tab_div_"+name);
  div.style.visibility = "visible";
  div.style.display = "inline";
}

function showErrorMsg(elem)
{
  var errorExps = document.getElementsByClassName("errorExplanation", elem);

  if (errorExps != null && errorExps.length > 0 && errorExps[0].innerHTML.length > 0) {
    var thetis = new ThetisBox;
    thetis.show("TOP-RIGHT", "", "MESSAGE", "", errorExps[0].innerHTML, "");
    return true;
  }
  return false;
}

function ajaxUploadFile(elemId, formId, action, targetId, funcComplete, funcError)
{
  var context = jQuery("#"+elemId);

  if (context.plupload("getFiles").length > 0) {
    var uploader = context.plupload("getUploader");
    uploader.setOption("url", action);
    var getHashFunc = null;
    if (formId) {
      var hash = null;
      switch (getTypeExp(formId)) {
        case "Object":
          hash = formId;
          break;
        case "function":
          getHashFunc = formId;
          hash = getHashFunc();
          break;
        default:    // i.e. "HTMLElement", "string"
          hash = Form.serialize(_z(formId), {hash: true});
          break;
      }
      if (hash) {
        uploader.setOption("params", hash);
      }
    }
    var lastResponse = null;
    uploader.bind("FileUploaded", function(uploader, file, object) {
      if (object.response) {
        if (getHashFunc) {
          _z(targetId).innerHTML = object.response;
          object.response.evalScripts();
          var hash = getHashFunc();
          if (hash) {
            uploader.setOption("params", hash);
          }
        } else {
          lastResponse = object.response;
        }
      }
    });

    context.on("complete", function(uploader, files) {
      if (lastResponse) {
        _z(targetId).innerHTML = lastResponse;
        lastResponse.evalScripts();

        if ((showErrorMsg(targetId) == true)
            && (typeof(funcError) == "function")) {
          setTimeout(funcError, 10);
        }
      }
      if (typeof(funcComplete) == "function") {
        funcComplete(context);
      }
    });
    if (typeof(funcError) == "function") {
      context.on("error", function(uploader, message, file, status) {
        funcError(context);
      });
    }
    context.plupload("start");
  } else {
    new Ajax.Updater(
        targetId,
        action,
        {
          method: "post",
          parameters: Form.serialize(_z(formId)),
          evalScripts: true,
          onComplete: function(request){
            if (typeof(funcComplete) == "function") {
              funcComplete();
            }
          }
        }
      );
  }
}

function getFileSelector(onOk, onCancel, btnOk, btnCancel, contextId)
{
  var html = "";

  html += "<table style=\"width:100%; height:100%;\">";
  html += "  <tr style=\"height:90%;\">";
  html += "    <td style=\"text-align:center;\">";
  html += "      <div id=\""+contextId+"\">";
  html += "        <p>Your browser doesn't have HTML5 support.</p>";
  html += "      </div>";
  html += "    </td>";
  html += "  </tr>";
  html += "  <tr>";
  html += "    <td style=\"text-align:center; padding:10px 0px;\">";
  html += "      <input id=\"btn_file_ok\" type=\"button\" value=\""+btnOk+"\" onclick=\""+onOk+"\" style=\"width:80px;\" />";
  html += "      &nbsp;<input id=\"btn_file_cancel\" type=\"button\" value=\""+btnCancel+"\" onclick=\""+onCancel+"\" style=\"width:80px;\" />";
  html += "    </td>";
  html += "  </tr>";
  html += "</table>";
  return html;
}

function initFileSelector(contextId, limitNum)
{
  var context = jQuery("#"+contextId);
  context.plupload(getPluploadOptions(limitNum));
  jQuery(".plupload_container", context)[0].style.height = "200px";
}

