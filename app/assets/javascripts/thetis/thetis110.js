/**-----------------**-----------------**-----------------**
 Copyright (c) 2007-2012, MORITA Shintaro, Sysphonic. All rights reserved.
 http://sysphonic.com/

 This module is released under New BSD License.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 * Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer. 

 * Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution. 

 * Neither the name of the Sysphonic nor the names of its contributors may
   be used to endorse or promote products derived from this software without
   specific prior written permission. 

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
 OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 **-----------------**-----------------**-----------------**/

toSysDateForm = function(date)
{
  return date;
//  return replaceAll(date, "/", "-");
}

removeOptionNotSelected = function(elem)
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

isModelErrorContained = function(resText)
{
  if (!resText) {
    return false;
  }
  return (resText.indexOf("errorExplanation") >= 0);
}

doUpdateView = function(method, action, addParams)
{
  if (!addParams) {
    addParams = new Array();
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
                  asynchronous: true,
                  evalScripts: true,
                  onComplete: function(request){ thetisBox.remove(); }
                }
              );
}

bound = function(desktop, elem)
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

getAxis = function(desktop, elem)
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

  return new Array(xAxis, yAxis);
}

showTab = function(name, nameArray, bgcolor)
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

showErrorMsg = function(target_element)
{
  var errorExps = document.getElementsByClassName("errorExplanation", target_element);

  if (errorExps != null && errorExps.length > 0 && errorExps[0].innerHTML.length > 0) {
    var thetis = new ThetisBox;
    thetis.show("TOP-RIGHT", "", "MESSAGE", "", errorExps[0].innerHTML, "");
    return true;
  }
  return false;
}

/*
var _thetis_ajax_item_data = null;
var _thetis_ajax_item_func_complete = null;
var _thetis_ajax_item_func_error = null;
*/
ajaxUploadFile = function(form_id, p_url, target_id, func_complete, func_error)
{
  dojo.io.iframe.send({
      handleAs: "html",
      url:      p_url,
      method:   "post",
      form: form_id,
//      content:{
//          "id" : 200
//      },
      load: function(response, ioArgs) {
/*
                if (is_Opera) {
                  _thetis_ajax_item_data = response;
                  _thetis_ajax_item_func_complete = func_complete;
                  _thetis_ajax_item_func_error = func_error;
                  setTimeout("_onUploadForOpera('"+target_id+"')", 100);
                  return;
                }
*/
                var content = response.documentElement.innerHTML;
/*
                // needed due to problem with IframeIO: http://trac.dojotoolkit.org/ticket/674
                if (response != null) {
                  content = response.documentElement.innerHTML;
                } else {
                  content = dojo.io.iframeContentWindow(dojo.io.IframeTransport.iframe).document.body.innerHTML;
                  if (content.match("/<pre>(.*)</pre>/i")) {
                      // Internet Explorer [Jon Aquino 2006-05-06]
                      content = RegExp.$1;
                  }
                }
*/
                _z(target_id).innerHTML = content.stripScripts();
                content.evalScripts();

                if (showErrorMsg(target_id) == true) {
                  setTimeout(func_error, 10);
                } else {
                  setTimeout(func_complete, 10);
                }
            },
      error: function(response, ioArgs) {
/*
                    if (error.reason != null) {
                        var thetisBoxErr = new ThetisBox;
                        thetisBoxErr.show("TOP-RIGHT", "", "MESSAGE", "", error.reason, "");
                    }
*/
                    if (response != null) {
                        var thetisBoxErr = new ThetisBox;
                        thetisBoxErr.show("TOP-RIGHT", "", "MESSAGE", "", response, "");
                    }
                    setTimeout(func_error(), 10);
                  }
  });
}

/*
_onUploadForOpera = function(target_id) {

  var data = _thetis_ajax_item_data;

  if (data == null)
    return;

  if (data.documentElement.innerHTML.length < 100) {

    setTimeout("_onUploadForOpera('"+target_id+"')", 100);

  } else {

    setTimeout("_onUploadCompletedForOpera('"+target_id+"')", 100);
  }
}

_onUploadCompletedForOpera = function(target_id) {

  var data = _thetis_ajax_item_data;
  var func_complete = _thetis_ajax_item_func_complete;
  var func_error = _thetis_ajax_item_func_error;

  if (data == null)
    return;

  var value = data.documentElement.innerHTML;
  _z(target_id).innerHTML = value.stripScripts();
  value.evalScripts();

  if (showErrorMsg(target_id) == true) {
    setTimeout(func_error, 10);
  } else {
    setTimeout(func_complete, 10);
  }
}
*/

function getFileSelector(onOk, onCancel, btnOk, btnCancel, authToken, input_name)
{
  content = "<form name='form_file' method='post' enctype='multipart/form-data'>";
  content += "<table style='width:100%; height:180px'>";
  content += "  <tr style='height:70px;'>";
  content += "    <td style='text-align:center; vertical-align:middle;'>";
  content += "      <input type='file' name='"+input_name+"' size='46' style='width:90%;' />";
  content += "    </td>";
  content += "  </tr>";
  content += "  <tr>";
  content += "    <td style='text-align:center; vertical-align:top;'>";
  content += "      <input id='btn_file_ok' type='button' value='"+btnOk+"' onclick='"+onOk+"' style='width:80px' />";
  content += "      &nbsp;<input id='btn_file_cancel' type='button' value='"+btnCancel+"' onclick='"+onCancel+"' style='width:80px' />";
  content += "    </td>";
  content += "  </tr>";
  content += "  <tr style='height:100%;'>";
  content += "    <td></td>";
  content += "  </tr>";
  content += "</table>";
  content += "<input type='hidden' name='authenticity_token' value='"+authToken+"' />";
  content += "</form>";
  return content;
}

