/**-----------------**-----------------**-----------------**
 Copyright (c) 2007-2016, MORITA Shintaro, Sysphonic. All rights reserved.
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

var appName = window.navigator.appName;
var is_MS = (appName.toLowerCase().indexOf('explorer') >= 0);        // MSIE, Sleipnir
var is_Netscape = (appName.toLowerCase().indexOf('netscape') >= 0);  // Firefox, Safari
var is_Opera = (appName.toLowerCase().indexOf('opera') >= 0);

function getUserAgentName()
{
  var userAgent = window.navigator.userAgent.toLowerCase();

  if (userAgent.indexOf("opera") >= 0) {
    return "opera";
  } else if (userAgent.indexOf("msie") >= 0
              || userAgent.indexOf("trident") >= 0) {
    return "msie";
  } else if (userAgent.indexOf("chrome") >= 0) {
    return "chrome";
  } else if (userAgent.indexOf("safari") >= 0) {
    return "safari";
  } else if (userAgent.indexOf("gecko") >= 0) {
    return "gecko";
  } else {
    return "unknown";
  }
}

function getCsrfToken()
{
  var metas = document.getElementsByTagName("meta");
  for (var i=0; i < metas.length; i++) {
    var meta = metas[i];
    if (meta.name == "csrf-token") {
      return meta.content;
    }
  }
  return null;
}

function createPostForm(action, addParams)
{
  addParams = (addParams || []);

  var frm = document.createElement("form");
  frm.method = "post";
  frm.action = action;
  document.body.appendChild(frm);
  for (var i=0; i < addParams.length; i++) {
    var arr = addParams[i].split("=");
    addInputHidden(frm, null, arr[0], arr[1], null);
  }
  addInputHidden(frm, null, "authenticity_token", getCsrfToken(), null);
  return frm;
}

function focusFirstElem(frm)
{
  try {
    for (var i=0; i < frm.elements.length; i++) {
      var firstElem = frm.elements[i];
      if (firstElem.type != "select-one"
          && firstElem.type != "hidden"
          && !firstElem.readOnly
          && firstElem.name != "authenticity_token") {
        firstElem.focus();
        break;
      }
    }
  } catch(e) {
  }
}

function escapeRegExp(s)
{
  return s.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');
}

function appendClassName(elem, className)
{
  if (!elem || !className) {
    return;
  }
  var classNames = elem.className.split(/\s/);
  if (classNames.indexOf(className) < 0) {
    classNames.push(className);
    elem.className = classNames.join(" ");
  }
}

function removeClassName(elem, className)
{
  if (!elem || !className) {
    return;
  }
  var classNames = elem.className.split(/\s/);
  var idx = classNames.indexOf(className);
  if (idx >= 0) {
    classNames.splice(idx, 1);
    elem.className = classNames.join(" ");
  }
}

function hasClassName(elem, className)
{
  if (!elem || !className) {
    return false;
  }
  var classNames = elem.className.split(/\s/);
  var idx = classNames.indexOf(className);
  return (idx >= 0);
}

function avoidSubmit(evt)
{
  evt = (evt || window.event);

  if (evt.keyCode == 13) {
    if (evt.cancelBubble != null) {
      evt.cancelBubble = true;
      if (evt.preventDefault) { // for IE11
        evt.preventDefault();
      }
    }
    return false;
  } else {
    return true;
  }
}

function getVerIE()
{
  var m = navigator.appVersion.match(/.*MSIE[ ]*[0]*([0-9]+)/);
  if (m && m.length > 1) {
    var ie_ver = m[1];
    if (ie_ver) {
      return parseInt(ie_ver, 10);
    }
  }

  m = navigator.userAgent.match(/.*Trident[/ ]*([0-9]+)/);
  if (m && m.length > 1) {
    var trident_ver = m[1];
    if (trident_ver) {
      return (parseInt(trident_ver, 10) + 4);
    }
  }

  return -1;
}

function _z(elemId)
{
  if (!elemId) {
    return null;
  }
  /*
   * Shortcut for most popular case.
   */
  if (typeof(elemId) == "string") {
    return document.getElementById(elemId);
  }

  if (typeof(elemId.valueOf) != "undefined" // for HTMLBodyElement on IE8
      && typeof(elemId.valueOf()) == "string") {
    return document.getElementById(elemId);
  } else {
    return elemId;
  }
}

function addEvent(elem, eventName, func)
{
  // elem["on"+eventName] = func;

  if (elem.attachEvent){
    elem.attachEvent("on"+eventName, func);
  } else {
    elem.addEventListener(eventName, func, false);
  }
}

function removeEvent(elem, eventName, func)
{
  if (elem.detachEvent) {
    elem.detachEvent("on"+eventName, func);
  } else {
    elem.removeEventListener(eventName, func, false);
  }
}

function stopEvent(evt, preventDefault)
{
  evt = (evt || window.event);

  if (preventDefault == null) {
    preventDefault = true;
  }

  if (typeof(evt.stopPropagation) == "function") {
    evt.stopPropagation();
  } else {
    evt.cancelBubble = true;
  }
  if (preventDefault && (typeof(evt.preventDefault) == "function")) {
    evt.preventDefault();
  }
}

function getElemByTagNameInChildNodes(elem, tagName, recursive)
{
  if (!elem) {
    return null;
  }
  tagName = tagName.toLowerCase();

  for (var i=0; i < elem.childNodes.length; i++) {

    var curNode = elem.childNodes[i];

    if (curNode.tagName
        && tagName == curNode.tagName.toLowerCase()) {
      return curNode;
    }

    if (recursive) {
      var node = getElemByTagNameInChildNodes(curNode, tagName, true);
      if (node) {
        return node;
      }
    }
  }
  return null;
}

function getElemByClassNameInChildNodes(elem, className, recursive)
{
  for (var i=0; i < elem.childNodes.length; i++) {

    var curNode = elem.childNodes[i];

    if (curNode.className) {
      var classes = curNode.className.split(" ");
      for (var k=0; k < classes.length; k++) {
        if (className == classes[k]) {
          return curNode;
        }
      }
    }

    if (recursive) {
      var node = getElemByClassNameInChildNodes(curNode, className, true);
      if (node) {
        return node;
      }
    }
  }
  return null;
}

function getElemByClassNameInParentNodes(elem, className)
{
  var node = elem.parentNode;
  for (var i=0; node; node=node.parentNode) {
    if (node.className) {
      var classes = node.className.split(" ");
      for (var k=0; k < classes.length; k++) {
        if (className == classes[k]) {
          return node;
        }
      }
    }
  }
  return null;
}

function getElemByTagNameInParentNodes(elem, tagName)
{
  tagName = tagName.toLowerCase();

  var node = elem.parentNode;
  for (var i=0; node; node=node.parentNode) {
    if (node.tagName
        && tagName == node.tagName.toLowerCase()) {
      return node;
    }
  }
  return null;
}

function isElemDisplayed(elem)
{
  if (!elem) {
    return false;
  }

  for (var node=elem; node; node=node.parentNode) {
    if (node.style && node.style.display == "none") {
      return false;
    }
  }
  return true;
}

function floorDecimal(val, prec)
{
  var precVal = Math.pow(10, prec);
  return Math.floor(val*precVal) / precVal;
}

function roundDecimal(val, prec)
{
  var precVal = Math.pow(10, prec);
  return Math.round(val*precVal) / precVal;
}

function checkInteger(str, signed)
{
  if (signed) {
    return str.match(/^[ ]*[+-]?(0|[1-9]+[0-9]*)[ ]*$/);
  } else {
    return str.match(/^[ ]*(0|[1-9]+[0-9]*)[ ]*$/);
  }
}

function checkDecimal(str, signed, prec)
{
  var checkOk = false;

  if (signed) {
    checkOk = str.match(/^[ ]*[+-]?(0|[1-9]+[0-9]*)([.][0-9]+)?[ ]*$/);
  } else {
    checkOk = str.match(/^[ ]*(0|[1-9]+[0-9]*)([.][0-9]+)?[ ]*$/);
  }

  if (!checkOk) {
    return false;
  }

  if (prec) {
    var regexp = new RegExp("[.][0-9]{" + (prec+1) + "}");
    if (str.match(regexp)) {
      checkOk = false;
    }
  }

  return checkOk;
}

function collectionToArray(collection)
{
  var ret = [];
  for (var i=0; i < collection.length; i++) {
    ret.push(collection[i]);
  }
  return ret;
}

function isElemDisabled(elem)
{
  if (!elem) {
    return false;
  }

  for (var node=elem; node; node=node.parentNode) {
    if (node.disabled) {
      return true;
    }
  }
  return false;
}

function getFormValue(name)
{
  var ret = null;
  var entries = document.getElementsByName(name);
  if (entries) {
    for (var i=0; i < entries.length; i++) {
      var entry = entries[i];
      if (!entry
          || entry.disabled
          || ((entry.type == "radio" || entry.type == "checkbox") && !entry.checked)) {
        continue;
      }
      ret = entry.value;
    }
  }
  return ret;
}

// for Form.serialize() in prototype.js
function disableBlockElems(parentNode, disabled)
{
  if (disabled == null) {
    disabled = true;
  }
  for (var i=0; i < parentNode.childNodes.length; i++) {

    var curNode = parentNode.childNodes[i];

    switch (curNode.tagName) {
      case "INPUT":
      case "TEXTAREA":
      case "SELECT":
        curNode.disabled = disabled;
        break;
      default:
        break;
    }

    disableBlockElems(curNode, disabled);
  }
}

function posAbsolute(elem)
{
  var pos = getPos(elem);

  elem.style.top    = pos.y + "px";
  elem.style.left   = pos.x + "px";
  elem.style.width  = elem.offsetWidth + "px";
  elem.style.height = elem.offsetHeight + "px";
  elem.style.position = "absolute";
}

function getNaviLanguage()
{
  var lang = window.navigator.systemLanguage;
  if (lang == null) {
    lang = window.navigator.language;
  }
  if (lang == null) {
    return "";
  } else {
    return lang;
  }
}

function fillLeft(str, ch, len)
{
  if (str == null) {
    str = "";
  }

  var org_len = str.length;
  for (var i=0; i < len - org_len; i++) {
    str = ch + str;
  }
  return str;
}

function addInputHidden(frm, id, name, value, parentElem)
{
  if (frm.elements != null) {
    for (var i=0; i < frm.elements.length; i++) {
      var entry = frm.elements[i];
      if (entry.name == name) {
        removeElem(entry);
      }
    }
  }
  var elem = document.createElement("input");
  elem.type = "hidden";
  if (id != null) {
    elem.id = id;
  }
  elem.name = name;
  elem.value = value;
  if (parentElem) {
    parentElem.appendChild(elem);
  } else {
    frm.appendChild(elem);
  }
  return elem;
}

function removeElem(elem)
{
  if (elem && elem.parentNode) {
    elem.parentNode.removeChild(elem);
  }
}

function openWindow(url, width, height, name)
{
  options = "directories=no, location=no, resizable=no";

  if (width > 0 && height > 0) {
    w = screen.availWidth/2;
    h = screen.availHeight/2;
    options += ",left="+(w-(width/2))+",top="+(h-(height/2));
    options += ", width="+width+",height="+height;
  }

  subwin=window.open(url, name, options);
  subwin.focus();
}

function replaceAll(str, from, to)
{
  var idx = str.indexOf(from);

  var base = "";
  var startIdx = idx;
  while (idx > -1) {
    str = str.replace(from, to); 
    idx = str.indexOf(from);
    if (idx < startIdx) {
      break;
    }
    startIdx = idx;
  }
  return str;
}

function uniq(arr)
{
  var ret = [];
  for (var i=0; i < arr.length; i++) {
    if (ret.indexOf(arr[i]) < 0) {
      ret.push(arr[i]);
    }
  }
  return ret;
}

function removeArrayElements(arr, entries)
{
  for (var i=0; i < arr.length; i++) {
    for (k=0; k < entries.length; k++) {
      if (arr[i] == entries[k]) {
        arr.splice(i, 1);
        i--;
        break;
      }
    }
  }
  return arr;
}

function getListSelected(list, reqText)
{
  var entries = [];
  if (!list) {
    return entries;
  }
  for (var i=0; i < list.length; i++) {
    var option = list.options[i];
    if (option.selected == true) {
      entries.push((reqText)?(option.text):(option.value));
    }
  }
  return entries;
}

function getListText(list, val)
{
  if (!list) {
    return null;
  }
  for (var i=0; i < list.length; i++) {
    var option = list.options[i];
    if (option.value == val) {
      return option.text;
    }
  }
  return null;
}

function setListText(list, val)
{
  if (!list) {
    return null;
  }
  for (var i=0; i < list.length; i++) {
    var option = list.options[i];
    if (option.value == val) {
      return option.text;
    }
  }
  return null;
}

function getListOption(list, val, sep)
{
  if (!list) {
    return null;
  }
  var sepIdx = (sep)?(val.lastIndexOf(sep)):(-1);
  val = (sepIdx >= 0)?(val.substring(0, sepIdx)):(val);

  for (var i=0; i < list.length; i++) {
    var option = list.options[i];
    var sepIdx = (sep)?(option.value.lastIndexOf(sep)):(-1);
    var optVal = (sepIdx >= 0)?(option.value.substring(0, sepIdx)):(option.value);
    if (optVal == val) {
      return option;
    }
  }
  return null;
}

function addList(list, text, value, allowDuplex)
{
  if (!list) {
    return;
  }
  if (!allowDuplex) {
    for (var i=0; i < list.length; i++) {
      var option = list.options[i];
      if (option.value == value) {
        return;
      }
    }
  }
  list.options[list.length++] = new Option(text, value);
}

function deleteList(list, val)
{
  var entries = [];
  if (!list) {
    return entries;
  }
  for (var i=0; i < list.length; i++) {
    var opt = list.options[i];
    var del = ((val == null) && (opt.selected == true))
                || ((val != null) && (opt.value == val));
    if (del) {
      entries.push(opt.value);
      list.options[i] = null;
      i--;
    }
  }
  list.selectedIndex = -1;
  return entries;
}

function sortList(list, direction)
{
  var opts = [];
  for (var i=0; i < list.length; i++) {
    var option = list.options[i];
    opts.push(option);
  }
  list.length = 0;

  if (direction == "ASC") {
    opts.sort(_sortTextASC);
  } else {
    opts.sort(_sortTextDESC);
  }

  for (var i=0; i < opts.length; i++) {
    list.options[list.length++] = opts[i];
  }
}

function _sortTextASC(a, b)
{
  if (a.text == b.text) {
    return 0;
  }
  return (a.text > b.text)? 1 : -1;
}

function _sortTextDESC(a, b)
{
  return _sortTextASC(a, b) * (-1);
}

function moveList(src, dst)
{
  var arr = [];
  for (var i=0; i < src.length; i++) {
    var option = src.options[i];
    if (option.selected == true) {
      var duplex = false;
      for (var k=0; k < dst.length; k++) {
        if (dst.options[k].value == option.value) {
          dst.options[k].text = option.text;
          duplex = true;
          break;
        }
      }
      if (!duplex) {
        dst.options[dst.length++] = new Option(option.text, option.value);
        arr[arr.length] = option.value;
      }
      src.options[i] = null;
      i--;
    }
  }
  src.selectedIndex = -1;
  return arr;
}

function moveListWithSuffix(src, dst, valSuffix, textSuffix)
{
  var arr = [];
  for (var i=0; i<src.length; i++) {
    var option=src.options[i];
    if (option.selected == true) {
      var duplex = false;
      for (var k=0; k<dst.length; k++) {
        if (dst.options[k].value == option.value+valSuffix) {
          dst.options[k].text = option.text+textSuffix;
          duplex = true;
          break;
        }
      }
      if (!duplex) {
        dst.options[dst.length++] = new Option(option.text+textSuffix, option.value+valSuffix);
        arr[arr.length] = option.value+valSuffix;
      }
      src.options[i]=null;
      i--;
    }
  }
  src.selectedIndex=-1;
  return arr;
}

function moveListTrimSuffix(src, dst, valSeparator, textSeparator)
{
  var arr = [];
  for (var i=0; i<src.length; i++) {
    var option=src.options[i];
    if (option.selected == true) {
      var duplex = false;
      for (var k=0; k<dst.length; k++) {
        var sepIdx = option.value.lastIndexOf(valSeparator);
        var val = option.value.substring(0, sepIdx);
        if (dst.options[k].value == val) {
          var sepIdx = option.text.lastIndexOf(textSeparator);
          var text = option.text.substring(0, sepIdx);
          dst.options[k].text = text;
          duplex = true;
          break;
        }
      }
      if (!duplex) {
        var sepIdx = option.value.lastIndexOf(valSeparator);
        var val = option.value.substring(0, sepIdx);
        sepIdx = option.text.lastIndexOf(textSeparator);
        var text = option.text.substring(0, sepIdx);
        dst.options[dst.length++] = new Option(
                          text,
                          val
                        );
        arr[arr.length] = val;
      }
      src.options[i]=null;
      i--;
    }
  }
  src.selectedIndex=-1;
  return arr;
}

function moveListWithPrefix(src, dst, valPrefix, textPrefix)
{
  var arr = [];
  for (var i=0; i<src.length; i++) {
    var option=src.options[i];
    if (option.selected == true) {
      var duplex = false;
      for (var k=0; k<dst.length; k++) {
        if (dst.options[k].value == valPrefix+option.value) {
          dst.options[k].text = textPrefix+option.text;
          duplex = true;
          break;
        }
      }
      if (!duplex) {
        dst.options[dst.length++] = new Option(textPrefix+option.text, valPrefix+option.value);
        arr[arr.length] = valPrefix+option.value;
      }
      src.options[i]=null;
      i--;
    }
  }
  src.selectedIndex=-1;
  return arr;
}

function moveListTrimPrefix(src, dst, valSeparator, textSeparator)
{
  var arr = [];
  for (var i=0; i<src.length; i++) {
    var option=src.options[i];
    if (option.selected == true) {
      var duplex = false;
      for (var k=0; k<dst.length; k++) {
        var sepIdx = option.value.indexOf(valSeparator);
        var val = option.value.substr(sepIdx+valSeparator.length, option.value.length-(sepIdx+valSeparator.length));
        if (dst.options[k].value == val) {
          var sepIdx = option.text.indexOf(textSeparator);
          var text = option.text.substr(sepIdx+textSeparator.length, option.text.length-(sepIdx+textSeparator.length));
          dst.options[k].text = text;
          duplex = true;
          break;
        }
      }
      if (!duplex) {
        var sepIdx = option.value.indexOf(valSeparator);
        var val = option.value.substr(sepIdx+valSeparator.length, option.value.length-(sepIdx+valSeparator.length));
        sepIdx = option.text.indexOf(textSeparator);
        var text = option.text.substr(sepIdx+textSeparator.length, option.text.length-(sepIdx+textSeparator.length));
        dst.options[dst.length++] = new Option(
                          text,
                          val
                        );
        arr[arr.length] = val;
      }
      src.options[i]=null;
      i--;
    }
  }
  src.selectedIndex=-1;
  return arr;
}

function selectListAll(list)
{
  for (var i=0; i < list.length; i++) {
    list.options[i].selected = true;
  }
}

function deselectListAll(list)
{
  for (var i=0; i < list.length; i++) {
    list.options[i].selected = false;
  }
}

function _prepareShiftListItems(list)
{
  var selOptions = [];
  var firstIdx = -1;

  for (var i=0; i < list.options.length; i++) {

    var option = list.options[i];

    if (option.selected == true) {
      selOptions.push(option);

      if (firstIdx < 0) {
        firstIdx = i;
      }
    }
  }
  deleteList(list);

  return new Array(firstIdx, selOptions);
}

function shiftListUpper(list)
{
  var moveParams = _prepareShiftListItems(list);

  var firstIdx = moveParams[0];
  var selOptions = moveParams[1];

  if (firstIdx < 0) {
    return false;
  }

  var insertIdx = firstIdx;
  if (insertIdx > 0) {
    insertIdx--;
  }

  for (var i=0; i < selOptions.length; i++) {
    list.options.add(selOptions[i], insertIdx++);
  }
  return true;
}

function shiftListLower(list)
{
  var moveParams = _prepareShiftListItems(list);

  var firstIdx = moveParams[0];
  var selOptions = moveParams[1];

  if (firstIdx < 0) {
    return false;
  }

  var insertIdx = firstIdx + 1;

  for (var i=0; i < selOptions.length; i++) {
    list.options.add(selOptions[i], insertIdx++);
  }
  return true;
}

function getClientRegion()
{
  var obj = new Object();

  if (document.documentElement.clientWidth) {
    obj.width = document.documentElement.clientWidth;
  } else {
    obj.width = document.documentElement.offsetWidth;
  }
  if ((isNaN(obj.width) || obj.width == 0) && document.body != null)  {
    obj.width = document.body.clientWidth;
  }

  if (document.documentElement.clientHeight) {
    obj.height = document.documentElement.clientHeight;
  } else {
    obj.height = document.documentElement.offsetHeight;
  }
  if ((isNaN(obj.height) || obj.height == 0) && document.body != null)  {
    obj.height = document.body.clientHeight;
  }

  return obj;
}

function getDateString(date)
{
  if (date == null) {
    date = new Date();
  }
  var ret = "";
  ret += date.getFullYear();
  var month = String(date.getMonth()+1);
  if (month.length <= 1) {
    month = "0" + month;
  }
  ret += "-"+month;
  var day = String(date.getDate());
  if (day.length <= 1) {
    day = "0" + day;
  }
  ret += "-"+day;

  return ret;
}

function getDateFromString(date_s)
{
  var parts = date_s.split("-");

  return new Date(parts[0], parseInt(parts[1], 10)-1, parts[2]);
}

function getByteSize(str)
{
  var cnt = 0;
  for (var i=0; i<str.length; i++) {
    if (escape(str.charAt(i)).length < 4) {
      cnt++;
    } else {
      cnt += 2;
    }
  }
  return cnt;
}

function truncateStr(str, len)
{
  var truncation = "...";
  str = (str.length > len)?(str.substring(0, len - truncation.length)+truncation):(str);
/*
  var cnt = 0;
  for (var i=0; i < str.length; i++) {
    if (escape(str.charAt(i)).length < 4) {
      cnt++;
    } else {
      cnt += 2;
    }
    if (cnt > len) {
      return str.substr(0, i)+"...";
    }
  }
*/
  return str;
}

function trim(str, trimWchar)
{
  if (str == null) {
    return str;
  }

  if (trimWchar) {
    return str.replace(/(^[\s\u3000]+)|([\s\u3000]+$)/g, "");
  } else {
    return str.replace(/(^\s+)|(\s+$)/g, "");
  }
}

function removeCtrlChar(str)
{
  if (str == null) {
    return(str);
  }

  for (var i=0; i < str.length; i++) {
    var ch = str.charAt(i);
    if (ch <= '\u001F' || ch == '\u007F') {
      str = str.replace(ch, '');
      i--;
    }
  }
  return str;
}

function within(elem, x, y)
{
  var elemPos = getElemPos(elem);
  var eX = elemPos.x;
  var eY = elemPos.y;
  var eWidth = elem.offsetWidth;
  var eHeight = elem.offsetHeight;

  return(x >= eX && x <= eX + eWidth && y >= eY && y <= eY + eHeight);
}

function getPos(elem)
{
  if (!elem) {
    return null;
  }

  var change_display = false;
  if (elem.style.display == "none") {
    elem.style.display = "";
    change_display = true;
  }

  var obj = new Object();
  obj.x = elem.offsetLeft;
  obj.y = elem.offsetTop;

  var e = elem;
  while (e.offsetParent) {
    e = e.offsetParent;
    obj.x += e.offsetLeft;
    obj.y += e.offsetTop;
  }

  if (change_display) {
    elem.style.display = "none";
  }
  return obj;
}

function getScroll(elem)
{
  var obj = new Object();
  obj.left = 0;
  obj.top = 0;

  while (elem.parentNode.tagName.toLowerCase() != "html") {
    elem = elem.parentNode;
    if (elem.tagName.toLowerCase() == "body"
        || (elem.style != null && 
            (elem.style.overflow=="scroll") || (elem.style.overflow=="auto"))) {
      obj.left += elem.scrollLeft;
      obj.top += elem.scrollTop;
    }
  }
  return obj;
}

function getBodyScroll()
{
  var obj = new Object();
  obj.left = 0;
  obj.top = 0;

  if (document.documentElement != null) {
     obj.left = document.documentElement.scrollLeft;
     obj.top = document.documentElement.scrollTop;
  }
  if (document.body != null) {
    if (isNaN(obj.left) || obj.left == 0) {
      obj.left = document.body.scrollLeft;
    }
    if (isNaN(obj.top) || obj.top == 0) {
      obj.top = document.body.scrollTop;
    }
  }
  return obj;
}

function isFunc(func)
{
  if (!func) {
    return false;
  }
  var targetType = typeof(func);
  return (targetType && targetType == "function");
}

function isArray(x)
{
  var targetType = typeof(x);
  return (targetType && (targetType == "object") && (x.constructor == Array));
}

function escapeHTML(html)
{
  if (html == null || html.length <= 0) {
    return html;
  }
  return html.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

function restoreHTML(html)
{
  if (html == null || html.length <= 0) {
    return html;
  }
  return html.replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&amp;/g, "&");
}

function esc_quotes(str)
{
  if (str == null || str.length <= 0) {
    return str;
  }
  return str.replace(/[']/g, "\\'").replace(/["]/g, "&quot;");
}

function esc_w_quotes(str)
{
  if (str == null || str.length <= 0) {
    return str;
  }
  return str.replace(/["]/g, "&quot;");
}

function set_tr_bgcolor(tr, color)
{
  var cnt = tr.childNodes.length;

  for (var i=0; i < cnt; i++) {
    if (tr.childNodes[i].style)
      tr.childNodes[i].style.backgroundColor = color;
  }
}

function checkMailAddr(addr)
{
  if (!addr) {
    return false;
  }

  var check = addr.match(/^((([\w\!\#\$\%\&\'\*\+\-\.\/\=\?\^\_\`\{\}\|\~]+|"([\s!\x23-\x5b\x5d-\x7e]|(\\[\x21-\x7e]))+")((\.([\w\!\#\$\%\&\'\*\+\-\.\/\=\?\^\_\`\{\}\|\~]+|"([\s!\x23-\x5b\x5d-\x7e]|(\\[\x21-\x7e]))+"))*))@((([\w\!\#\$\%\&\'\*\+\-\.\/\=\?\^\_\`\{\}\|\~]+)|(\[(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})\]))(\.(([\w\!\#\$\%\&\'\*\+\-\.\/\=\?\^\_\`\{\}\|\~]*)|(\[(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})\])))*))$/);

  if (check) {
    return true;
  } else {
    return false;
  }
}

function checkMailAddrExp(addr)
{
  if (!addr) {
    return false;
  }

  var check = addr.match(/^(((([\w\!\#\$\%\&\'\*\+\-\.\/\=\?\^\_\`\{\}\|\~]+|"([\s!\x23-\x5b\x5d-\x7e]|(\\[\x21-\x7e]))+")((\.([\w\!\#\$\%\&\'\*\+\-\.\/\=\?\^\_\`\{\}\|\~]+|"([\s!\x23-\x5b\x5d-\x7e]|(\\[\x21-\x7e]))+"))*))@((([\w\!\#\$\%\&\'\*\+\-\.\/\=\?\^\_\`\{\}\|\~]+)|(\[(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})\]))(\.(([\w\!\#\$\%\&\'\*\+\-\.\/\=\?\^\_\`\{\}\|\~]+)|(\[(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})\])))*))|((([^\x00-\x1f\x7f\"\(\)\,\:\;\<\>\@\[\]\\]+|"([^"\\]|(\\[\x21-\x7e]))*")*)\s*<(([\w\!\#\$\%\&\'\*\+\-\.\/\=\?\^\_\`\{\}\|\~]+|"([\s!\x23-\x5b\x5d-\x7e]|(\\[\x21-\x7e]))+")((\.([\w\!\#\$\%\&\'\*\+\-\.\/\=\?\^\_\`\{\}\|\~]+|"([\s!\x23-\x5b\x5d-\x7e]|(\\[\x21-\x7e]))+"))*))@((([\w\!\#\$\%\&\'\*\+\-\.\/\=\?\^\_\`\{\}\|\~]+)|(\[(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})\]))(\.(([\w\!\#\$\%\&\'\*\+\-\.\/\=\?\^\_\`\{\}\|\~]+)|(\[(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})\])))*)>))$/);

  if (check) {
    return true;
  } else {
    return false;
  }
}

function getDateTimeExp(date)
{
  var exp = "";
  date = (date || new Date());

  exp += date.getFullYear();
  exp += "-";
  exp += fillLeft(String(date.getMonth()+1), "0", 2);
  exp += "-";
  exp += fillLeft(String(date.getDate()), "0", 2);
  exp += " ";
  exp += fillLeft(String(date.getHours()), "0", 2);
  exp += ":";
  exp += fillLeft(String(date.getMinutes()), "0", 2);
  exp += ":";
  exp += fillLeft(String(date.getSeconds()), "0", 2);
  exp += ".";
  exp += fillLeft(String(date.getMilliseconds()), "0", 3);

  return exp;
}

