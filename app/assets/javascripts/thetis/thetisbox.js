/**-----------------**-----------------**-----------------**
 Copyright (c) 2007-2018, MORITA Shintaro, Sysphonic. All rights reserved.
   http://sysphonic.com/
 This module is released under New BSD License.
 **-----------------**-----------------**-----------------**/

var __thetisbox_id = 0;
var __thetisbox_title = "Thetis";
var __thetisbox_ok = "OK";
var __thetisbox_cancel = "Cancel";
var __thetisbox_close = "Close";
var __thetisbox_close_img = null;

/**----------------**----------------**----------------**----------------**/
// DRAG BY PROTOTYPE.JS >>>
var ThetisBoxDragObserver = Class.create();
ThetisBoxDragObserver.prototype = {
  initialize: function() {
  },
  onStart: function(eventName, draggable, event) {
    var elem = draggable.element;

    if (hasClassName(elem, "thetisbox_resize_handle_l")) {
      var id = elem.id.split("-")[1];
      var thetisBox = ThetisBox.getInstance(parseInt(id, 10));
      var box = thetisBox.getContainer();
      var pos = getPos(box);
      draggable.posTopRight = {x:(pos.x + box.offsetWidth), y:pos.y};
    }
    if (hasClassName(elem, "thetisbox_resize_handle_r")
        || hasClassName(elem, "thetisbox_resize_handle_l")) {
      ThetisBox.onResizeHandleDragged(elem, draggable);
    }
  },
  onDrag: function(eventName, draggable, event) {
    var elem = draggable.element;
  },
  onEnd: function(eventName, draggable, event) {
    var elem = draggable.element;

    if (hasClassName(elem, "thetisbox_resize_handle_l")) {
      elem.style.left = "0px";
    }
  }
}
if (typeof(Draggables) != "undefined") {
  Draggables.addObserver( new ThetisBoxDragObserver() );
}
// DRAG BY PROTOTYPE.JS <<<
/**----------------**----------------**----------------**----------------**/

var ThetisBox = Class.create();
ThetisBox.Base = function() {};
ThetisBox.Base.prototype = {
   id: 0,
   position: null
}

ThetisBox.VERSION_MAJOR = 2;
ThetisBox.setTitle = function(title) {__thetisbox_title=title};
ThetisBox.setOk = function(ok) {__thetisbox_ok=ok};
ThetisBox.setCancel = function(cancel) {__thetisbox_cancel=cancel};
ThetisBox.setClose = function(close) {__thetisbox_close=close};
ThetisBox.setCloseImg = function(image) {__thetisbox_close_img=image;};

// DRAG BY PROTOTYPE.JS >>>
ThetisBox.onResizeHandleDragged = function(elem, draggable, evt)
{
  var id = elem.id.split("-")[1];
  var thetisBox = ThetisBox.getInstance(parseInt(id, 10));

  if (hasClassName(elem, "thetisbox_resize_handle_l")) {
    draggable.options.snap = function(x, y) {
      var ret = ThetisBox.resizeByLeftHandle(x, y, draggable, thetisBox, evt);
      if (typeof(thetisBox.onResized) == "function") {
        setTimeout(thetisBox.onResized, 0);
      }
      return ret;
    };
  } else {
    draggable.options.snap = function(x, y) {
      var ret = ThetisBox.resizeByRightHandle(x, y, draggable, thetisBox, evt);
      if (typeof(thetisBox.onResized) == "function") {
        setTimeout(thetisBox.onResized, 0);
      }
      return ret;
    };
  }
}

ThetisBox.resizeByLeftHandle = function(x, y, draggable, thetisBox, evt)
{
  var elem = draggable.element;
  elem.style.left = x+"px";   // To prenvent rattling

  var posTopRight = draggable.posTopRight;
  var base =  thetisBox.getBase();
  var box =  thetisBox.getContainer();
  var content = (thetisBox.getContent() || _z("thetisBoxTree-"+thetisBox.id) || _z("thetisBoxEdit-"+thetisBox.id));
  var marginWidth = Math.max((base.offsetWidth - content.offsetWidth), 0);
  var marginHeight = Math.max(base.offsetHeight - content.offsetHeight, 0);
  var clientRegion = ThetisBox.getClientRegion();
  var elemPos = getPos(elem);
  var bodyScroll = ThetisBox.getBodyScroll();

//tip("["+Math.round(x)+", "+Math.round(y)+"]");
  var aborted = false;
  var contentWidth = posTopRight.x - elemPos.x;
  var contentHeight = (elemPos.y + elem.offsetHeight) - posTopRight.y;

  if (contentWidth < 100) {
//tip("aborted_1["+x+", "+y+"] w="+contentWidth+", h="+contentHeight);
    aborted = true;
  }
  if (contentHeight < 100) {
    aborted = true;
  } else if (contentHeight > clientRegion.height && y > 0) {
    aborted = true;
  }
  if (aborted) {
    return [x, y];
  }
//tip("["+x+", "+y+"] w="+contentWidth+", h="+contentHeight);
  box.style.left = elemPos.x + "px";
  elem.style.left = "0px";

  base.style.width = contentWidth + "px";
  box.style.width = contentWidth + "px";
  if (box.style.minWidth) {
    box.style.minWidth = contentWidth + "px";
  }
  content.style.width = ((contentWidth >= marginWidth)?(contentWidth - marginWidth):0) + "px";

  base.style.height = contentHeight + "px";
  box.style.height = contentHeight + "px";
  if (box.style.minHeight) {
    box.style.minHeight = contentHeight + "px";
  }
  content.style.height = ((contentHeight >= marginHeight)?(contentHeight - marginHeight):0) + "px";

  return [x, y];
};

ThetisBox.resizeByRightHandle = function(x, y, draggable, thetisBox, evt)
{
  var elem = draggable.element;

  var base =  thetisBox.getBase();
  var box =  thetisBox.getContainer();
  var content = (thetisBox.getContent() || _z("thetisBoxTree-"+thetisBox.id) || _z("thetisBoxEdit-"+thetisBox.id));
  var marginWidth = Math.max((base.offsetWidth - content.offsetWidth), 0);
  var marginHeight = Math.max(base.offsetHeight - content.offsetHeight, 0);
  var clientRegion = ThetisBox.getClientRegion();
  var pos = getPos(box);
  var bodyScroll = ThetisBox.getBodyScroll();

  var aborted = false;
  var contentWidth = x + elem.clientWidth;
  var contentHeight = y + elem.clientHeight;
  if (contentWidth < 30 && x < 0) {
//tip("aborted_1["+x+", "+y+"] w="+contentWidth+", h="+contentHeight);
    aborted = true;
  } else if ((pos.x + contentWidth - bodyScroll.left) > clientRegion.width && x > 0) {
    aborted = true;
  }
  if (contentHeight < 30 && y < 0) {
    aborted = true;
  } else if ((pos.y + contentHeight - bodyScroll.top) > clientRegion.height && y > 0) {
    aborted = true;
  }
  if (aborted) {
    return [x, y];
  }
  base.style.width = contentWidth + "px";
  box.style.width = contentWidth + "px";
  if (box.style.minWidth) {
    box.style.minWidth = contentWidth + "px";
  }
  content.style.width = ((contentWidth >= marginWidth)?(contentWidth - marginWidth):0) + "px";
  base.style.height = contentHeight + "px";
  box.style.height = contentHeight + "px";
  if (box.style.minHeight) {
    box.style.minHeight = contentHeight + "px";
  }
  content.style.height = ((contentHeight >= marginHeight)?(contentHeight - marginHeight):0) + "px";
  return [x, y];
};
// DRAG BY PROTOTYPE.JS <<<

ThetisBox.getContainer = function(elem)
{
  if (typeof(elem) == "number") {
    var thetisBox = ThetisBox.getInstance(elem);
    if (thetisBox) {
      return thetisBox.getContainer();
    }
  } else {
    while (elem && elem.tagName.toLowerCase() != "html") {
      if ((typeof(elem.id) == "string") && (elem.id.indexOf("divThetisBox-") >= 0)) {
        return elem;
      }
      elem = elem.parentNode;
    }
  }
  return null;
}

ThetisBox.array = [];

Object.extend(Object.extend(ThetisBox.prototype, ThetisBox.Base.prototype), {
  initialize: function(element) {
    this.element = _z(element);
    this.id = ++__thetisbox_id;
    this.z_index += this.id;

    ThetisBox.array.push(this);
  },
  // INPUT
  drawInput: function(action, hasTitlebar, allowEmpty, cap)
  {
    var html = "";
    html += "<div class='thetisbox input' id='divThetisBox-"+this.id+"' style='position:absolute; z-index:"+this.z_index+"; display:none;'>";
    html += "<table class='thetisbox_input_dialog' id='thetisBoxBase-"+this.id+"' style='width:100%; height:100%; border:solid 2px; border-top-color:whitesmoke; border-left-color:whitesmoke; border-bottom-color:dimgray; border-right-color:dimgray; background-color:"+this.bgcolor_body+";'>";
    if (hasTitlebar) {
      html += "  <tr style='height:25px;'>";
      if (this.close_by_icon_button) {
        html += "  <td colspan='2' style='background-color:"+this.bgcolor_title+";'>";
        html += "    <table style='width:100%; border-spacing:0px;'>";
        html += "      <tr>";
        html += "        <td class='thetisbox_input_title' style='color:white; text-indent:5px;'>";
        html += "          <b>"+this.title+"</b>";
        html += "        </td>";
        html += "        <td style='text-align:right; vertical-align:middle; padding-right:5px; width:20px;'>";
        html += "          <img class='nodrag' src='"+this.button_close_img+"' style='cursor:pointer; vertical-align:middle;' onclick=\"ThetisBox.remove('"+this.id+"');\">";
        html += "        </td>";
        html += "      </tr>";
        html += "    </table>";
        html += "  </td>";
      } else {
        html += "  <td class='thetisbox_input_title' colspan='2' style='color:white; background-color:"+this.bgcolor_title+"; text-indent:5px;'><b>"+this.title+"</b></td>";
      }
      html += "  </tr>";
    }
    html += "  <tr>";
    html += "    <td style='cursor:default; padding-left:3px;'>";
    html += "      <div id='thetisBoxCaption-"+this.id+"'>" + cap + "</div>";
    html += "    </td>";
    html += "    <td style='width:100px;'>";
    html += "      <table style='width:100%; height:100%;'>";
    html += "        <tr>";
    html += "          <td>";
    html += "            <input type='button' id='thetisBoxOk-"+this.id+"' value='"+this.button_ok+"' onclick=\""+action+"\" tabindex='2' style='width:90px; height:25px'>";
    html += "          </td>";
    html += "        </tr>";
    html += "        <tr style='height:5px;'><td></td></tr>";
    html += "        <tr>";
    html += "          <td>";
    html += "            <input type='button' id='thetisBoxCancel-"+this.id+"' value='"+this.button_cancel+"' tabindex='3' style='width:90px; height:25px' onkeypress=\"ThetisBox.remove('"+this.id+"'); return true;\" onclick=\"ThetisBox.remove('"+this.id+"');\">";
    html += "          </td>";
    html += "        </tr>";
    html += "      </table>";
    html += "    </td>";
    html += "  </tr>";
    html += "  <tr>";
    html += "    <td colspan='2'>";
    html += "      <input type='text' id='thetisBoxEdit-"+this.id+"' name='thetisBoxEdit' value='' tabindex='1' style='width:99%'>";
    html += "    </td>";
    html += "  </tr>";
    html += "</table>";
    for (i=0; this.additionalParams != null && i<this.additionalParams.length; i++) {
      var param = this.additionalParams[i].split("=");
      var eqidx = this.additionalParams[i].indexOf("=");
      var val = this.additionalParams[i].substring(eqidx+1);
      html += "<input type='hidden' name='"+param[0]+"' value='"+val+"'>";
    }

    if (this.resizable == "left") {
      html += "  <div class=\"thetisbox_resize_handle_l\" id=\"thetisBoxResizeHandle-"+this.id+"\" style=\"display:inline-block; position:absolute; width:20px; height:20px; cursor:move;\"></div>";
    }
    if (this.resizable == "right") {
      html += "  <div class=\"thetisbox_resize_handle_r\" id=\"thetisBoxResizeHandle-"+this.id+"\" style=\"position:absolute; width:20px; height:20px; cursor:move;\"></div>";
    }
    html += "</div>";
    var d = document.createElement("div");
    d.innerHTML = html;
    this.parent_elem.appendChild(d.firstChild);
  },
  // TEXTAREA
  drawTextArea: function(action, hasTitlebar, allowEmpty, cap)
  {
    var html = "";
    html += "<div class='thetisbox textarea' id='divThetisBox-"+this.id+"' style='position:absolute; z-index:"+this.z_index+"; display:none;'>";
    html += "<table class='thetisbox_textarea_dialog' id='thetisBoxBase-"+this.id+"' style='width:100%; height:100%; border:solid 2px; border-top-color:whitesmoke; border-left-color:whitesmoke; border-bottom-color:dimgray; border-right-color:dimgray; background-color:"+this.bgcolor_body+";'>";
    if (hasTitlebar) {
      html += "  <tr style='height:25px;'>";
      if (this.close_by_icon_button) {
        html += "  <td style='background-color:"+this.bgcolor_title+";'>";
        html += "    <table style='width:100%; border-spacing:0px;'>";
        html += "      <tr>";
        html += "        <td class='thetisbox_textarea_title' style='color:white; text-indent:5px;'>";
        html += "          <b>"+this.title+"</b>";
        html += "        </td>";
        html += "        <td style='text-align:right; vertical-align:middle; padding-right:5px; width:20px;'>";
        html += "          <img class='nodrag' src='"+this.button_close_img+"' style='cursor:pointer; vertical-align:middle;' onclick=\"ThetisBox.remove('"+this.id+"');\">";
        html += "        </td>";
        html += "      </tr>";
        html += "    </table>";
        html += "  </td>";
      } else {
        html += "  <td class='thetisbox_textarea_title' style='color:white; background-color:"+this.bgcolor_title+"; text-indent:5px;'><b>"+this.title+"</b></td>";
      }
      html += "  </tr>";
    }
    if (cap != null && cap.length > 0) {
      html += "  <tr>";
      html += "    <td style='cursor:default; padding-left:3px;'>";
      html += "      <div id='thetisBoxCaption-"+this.id+"'>" + cap + "</div>";
      html += "    </td>";
      html += "  </tr>";
    }
    html += "  <tr>";
    html += "    <td>";
    html += "      <textarea id='thetisBoxEdit-"+this.id+"' name='thetisBoxEdit' wrap='off' tabindex='1' style='width:99%; height:170px;'></textarea>";
    html += "    </td>";
    html += "  </tr>";
    html += "  <tr style='height:40px;'>";
    html += "    <td style='text-align:center;'>";
    html += "      <table style='width:10%; margin:0px auto; border:none;'>";
    html += "        <tr>";
    html += "          <td>";
    html += "            <input type='button' id='thetisBoxOk-"+this.id+"' value='"+this.button_ok+"' onclick=\""+action+"\" tabindex='2' style='width:90px; height:25px'>";
    html += "          </td>";
    html += "          <td style='min-width:15px; width:15px;'></td>";
    html += "          <td>";
    html += "            <input type='button' id='thetisBoxCancel-"+this.id+"' value='"+this.button_cancel+"' tabindex='3' style='width:90px; height:25px' onkeypress=\"ThetisBox.remove('"+this.id+"'); return true;\" onclick=\"ThetisBox.remove('"+this.id+"');\">";
    html += "          </td>";
    html += "        </tr>";
    html += "      </table>";
    html += "    </td>";
    html += "  </tr>";
    html += "</table>";
    for (i=0; this.additionalParams != null && i<this.additionalParams.length; i++) {
      var param = this.additionalParams[i].split("=");
      var eqidx = this.additionalParams[i].indexOf("=");
      var val = this.additionalParams[i].substring(eqidx+1);
      html += "<input type='hidden' name='"+param[0]+"' value='"+val+"'>";
    }

    if (this.resizable == "left") {
      html += "  <div class=\"thetisbox_resize_handle_l\" id=\"thetisBoxResizeHandle-"+this.id+"\" style=\"display:inline-block; position:absolute; width:20px; height:20px; cursor:move;\"></div>";
    }
    if (this.resizable == "right") {
      html += "  <div class=\"thetisbox_resize_handle_r\" id=\"thetisBoxResizeHandle-"+this.id+"\" style=\"position:absolute; width:20px; height:20px; cursor:move;\"></div>";
    }
    html += "</div>";
    var d = document.createElement("div");
    d.innerHTML = html;
    this.parent_elem.appendChild(d.firstChild);
  },
  // TREE
  drawTree: function(action, hasTitlebar, cap)
  {
    var html = "";
    html += "<div class='thetisbox tree' id='divThetisBox-"+this.id+"' style='position:absolute; z-index:"+this.z_index+"; display:none;'>";
    html += "<table class='thetisbox_tree_dialog' id='thetisBoxBase-"+this.id+"' style='width:100%; height:100%; border:solid 2px; border-top-color:whitesmoke; border-left-color:whitesmoke; border-bottom-color:dimgray; border-right-color:dimgray; background-color:"+this.bgcolor_body+";'>";
    if (hasTitlebar) {
      html += "  <tr style='height:25px;'>";
      if (this.close_by_icon_button) {
        html += "  <td style='background-color:"+this.bgcolor_title+";'>";
        html += "    <table style='width:100%; border-spacing:0px;'>";
        html += "      <tr>";
        html += "        <td class='thetisbox_tree_title' style='color:white; text-indent:5px;'>";
        html += "          <b>"+this.title+"</b>";
        html += "        </td>";
        html += "        <td style='text-align:right; vertical-align:middle; padding-right:5px; width:20px;'>";
        html += "          <img class='nodrag' src='"+this.button_close_img+"' style='cursor:pointer; vertical-align:middle;' onclick=\"ThetisBox.remove('"+this.id+"');\">";
        html += "        </td>";
        html += "      </tr>";
        html += "    </table>";
        html += "  </td>";
      } else {
        html += "  <td class='thetisbox_tree_title' style='color:white; background-color:"+this.bgcolor_title+"; text-indent:5px;'><b>"+this.title+"</b></td>";
      }
      html += "  </tr>";
    }
    if (cap != null && cap.length > 0) {
      html += "  <tr>";
      html += "    <td style='cursor:default; padding-left:15px;'>";
      html += "      <div id='thetisBoxCaption-"+this.id+"'>" + cap + "</div>";
      html += "    </td>";
      html += "  </tr>";
    }
    html += "  <tr>";
    html += "    <td style='text-align:center; vertical-align:top;'>";
    html += "      <div class='nodrag' id='thetisBoxTree-"+this.id+"' style='text-align:left; padding-left:10px; padding-top:5px; width:350px; height:280px; overflow:auto; background-color:floralwhite;'></div>";
    html += "    </td>";
    html += "  </tr>";
    html += "  <tr style='height:40px;'>";
    html += "    <td style='text-align:center; vertical-align:top;'>";
    html += "      <table style='width:10%; margin:0px auto; border:none;'>";
    html += "        <tr>";
    html += "          <td>";
    html += "            <input type='button' id='thetisBoxOk-"+this.id+"' value='"+this.button_ok+"' onclick=\""+action+"\" tabindex='2' style='width:90px; height:25px'>";
    html += "          </td>";
    html += "          <td style='min-width:15px; width:15px;'></td>";
    html += "          <td>";
    html += "            <input type='button' id='thetisBoxCancel-"+this.id+"' value='"+this.button_cancel+"' tabindex='3' style='width:90px; height:25px' onkeypress=\"ThetisBox.remove('"+this.id+"'); return true;\" onclick=\"ThetisBox.remove('"+this.id+"');\">";
    html += "          </td>";
    html += "        </tr>";
    html += "      </table>";
    html += "    </td>";
    html += "  </tr>";
    html += "</table>";
    for (i=0; this.additionalParams != null && i<this.additionalParams.length; i++) {
      var param = this.additionalParams[i].split("=");
      var eqidx = this.additionalParams[i].indexOf("=");
      var val = this.additionalParams[i].substring(eqidx+1);
      html += "<input type='hidden' name='"+param[0]+"' value='"+val+"'>";
    }

    if (this.resizable == "left") {
      html += "  <div class=\"thetisbox_resize_handle_l\" id=\"thetisBoxResizeHandle-"+this.id+"\" style=\"display:inline-block; position:absolute; width:20px; height:20px; cursor:move;\"></div>";
    }
    if (this.resizable == "right") {
      html += "  <div class=\"thetisbox_resize_handle_r\" id=\"thetisBoxResizeHandle-"+this.id+"\" style=\"position:absolute; width:20px; height:20px; cursor:move;\"></div>";
    }
    html += "</div>";
    var d = document.createElement("div");
    d.innerHTML = html;
    this.parent_elem.appendChild(d.firstChild);
  },
  // MINI-TREE
  drawMiniTree: function()
  {
    var html = "";
    html += "<div class='thetisbox minitree' id='divThetisBox-"+this.id+"' style='position:absolute; z-index:"+this.z_index+"; display:none;'>";
    html += "<table class='thetisbox_minitree_dialog' id='thetisBoxBase-"+this.id+"' style='width:100%; height:100%; border:solid 2px; border-top-color:whitesmoke; border-left-color:whitesmoke; border-bottom-color:dimgray; border-right-color:dimgray; background-color:"+this.bgcolor_body+";'>";
    html += "  <tr style='height:25px;'>";
    html += "    <td style='width:100%; background-color:"+this.bgcolor_title+";'>";
    html += "      <table style='width:100%; border-spacing:0px;'>";
    html += "        <tr>";
    html += "          <td class='thetisbox_minitree_title' style='color:white; text-indent:5px;'>";
    html += "            <b>"+this.title+"</b>";
    html += "          </td>";
    html += "          <td style='text-align:right; vertical-align:middle; padding-right:5px; width:20px;'>";
    html += "            <img class='nodrag' src='"+this.button_close_img+"' style='cursor:pointer; vertical-align:middle;' onclick=\"ThetisBox.remove('"+this.id+"');\">";
    html += "          </td>";
    html += "        </tr>";
    html += "      </table>";
    html += "    </td>";
    html += "  </tr>";
    html += "  <tr>";
    html += "    <td style='text-align:center; vertical-align:top;'>";
    html += "      <div id='thetisBoxTree-"+this.id+"' class='nodrag' style='text-align:left; padding-left:10px; padding-top:5px; width:100%; height:210px; overflow:auto; background-color:floralwhite;'></div>";
    html += "    </td>";
    html += "  </tr>";
    html += "</table>";
    for (i=0; this.additionalParams != null && i<this.additionalParams.length; i++) {
      var param = this.additionalParams[i].split("=");
      var eqidx = this.additionalParams[i].indexOf("=");
      var val = this.additionalParams[i].substring(eqidx+1);
      html += "<input type='hidden' name='"+param[0]+"' value='"+val+"'>";
    }

    if (this.resizable == "left") {
      html += "  <div class=\"thetisbox_resize_handle_l\" id=\"thetisBoxResizeHandle-"+this.id+"\" style=\"display:inline-block; position:absolute; width:20px; height:20px; cursor:move;\"></div>";
    }
    if (this.resizable == "right") {
      html += "  <div class=\"thetisbox_resize_handle_r\" id=\"thetisBoxResizeHandle-"+this.id+"\" style=\"position:absolute; width:20px; height:20px; cursor:move;\"></div>";
    }
    html += "</div>";
    var d = document.createElement("div");
    d.innerHTML = html;
    this.parent_elem.appendChild(d.firstChild);
  },
  // CONFIRM
  drawConfirm: function(ok_act, cancel_act, hasTitlebar, cap)
  {
    var html = "";
    html += "<div class='thetisbox confirm' id='divThetisBox-"+this.id+"' style='position:absolute; z-index:"+this.z_index+"; display:none;'>";
    html += "<table class='thetisbox_confirm_dialog' id='thetisBoxBase-"+this.id+"' style='width:100%; height:100%; border:solid 2px; border-top-color:whitesmoke; border-left-color:whitesmoke; border-bottom-color:dimgray; border-right-color:dimgray; background-color:"+this.bgcolor_body+";'>";
    if (hasTitlebar) {
      html += "  <tr style='height:25px;'>";
      if (this.close_by_icon_button) {
        html += "  <td style='background-color:"+this.bgcolor_title+";'>";
        html += "    <table style='width:100%; border-spacing:0px;'>";
        html += "      <tr>";
        html += "        <td class='thetisbox_confirm_title' style='color:white; text-indent:5px;'>";
        html += "          <b>"+this.title+"</b>";
        html += "        </td>";
        html += "        <td style='text-align:right; vertical-align:middle; padding-right:5px; width:20px;'>";
        html += "          <img class='nodrag' src='"+this.button_close_img+"' style='cursor:pointer; vertical-align:middle;' onclick=\"ThetisBox.remove('"+this.id+"');\">";
        html += "        </td>";
        html += "      </tr>";
        html += "    </table>";
        html += "  </td>";
      } else {
        html += "  <td class='thetisbox_confirm_title' style='color:white; background-color:"+this.bgcolor_title+"; text-indent:5px;'><b>"+this.title+"</b></td>";
      }
      html += "  </tr>";
    }
    if (cap != null && cap.length > 0) {
      html += "  <tr>";
      html += "    <td style='cursor:default; padding-left:3px;'>";
      html += "      <div id='thetisBoxCaption-"+this.id+"'>" + cap + "</div>";
      html += "    </td>";
      html += "  </tr>";
    }
    html += "  <tr style='height:40px;'>";
    html += "    <td style='width:100%;'>";
    html += "      <table style='width:100%; height:100%;'>";
    html += "        <tr>";
    html += "          <td style='text-align:right;'>";
    html += "            <input type='button' id='thetisBoxOk-"+this.id+"' value='"+this.button_ok+"' onclick=\""+ok_act +"; ThetisBox.remove('"+this.id+"');\" tabindex='2' style='width:90px; height:25px'>";
    html += "          </td>";
    html += "          <td style='width:5px;'></td>";
    html += "          <td style='text-align:left;'>";
    html += "            <input type='button' id='thetisBoxCancel-"+this.id+"' value='"+this.button_cancel+"' onclick=\""+cancel_act +"; ThetisBox.remove('"+this.id+"');\" tabindex='3' style='width:90px; height:25px' onkeypress=\"ThetisBox.remove('"+this.id+"'); return true;\" onclick=\"ThetisBox.remove('"+this.id+"');\">";
    html += "          </td>";
    html += "        </tr>";
    html += "      </table>";
    html += "    </td>";
    html += "  </tr>";
    html += "</table>";

    if (this.resizable == "left") {
      html += "  <div class=\"thetisbox_resize_handle_l\" id=\"thetisBoxResizeHandle-"+this.id+"\" style=\"display:inline-block; position:absolute; width:20px; height:20px; cursor:move;\"></div>";
    }
    if (this.resizable == "right") {
      html += "  <div class=\"thetisbox_resize_handle_r\" id=\"thetisBoxResizeHandle-"+this.id+"\" style=\"position:absolute; width:20px; height:20px; cursor:move;\"></div>";
    }
    html += "</div>";
    var d = document.createElement("div");
    d.innerHTML = html;
    this.parent_elem.appendChild(d.firstChild);
  },
  // MESSAGE
  drawMessage: function(hasTitlebar, cap)
  {
    var html = "";
    html += "<div class='thetisbox message' id='divThetisBox-"+this.id+"' style='position:absolute; z-index:"+this.z_index+"; display:none;'>";
    html += "<table class='thetisbox_message_dialog' id='thetisBoxBase-"+this.id+"' style='width:100%; height:100%; border:solid 2px; border-top-color:whitesmoke; border-left-color:whitesmoke; border-bottom-color:dimgray; border-right-color:dimgray; background-color:"+this.bgcolor_body+";'>";
    if (hasTitlebar) {
      html += "  <tr style='height:25px;'>";
      if (this.close_by_icon_button) {
        html += "  <td style='background-color:"+this.bgcolor_title+";'>";
        html += "    <table style='width:100%; border-spacing:0px;'>";
        html += "      <tr>";
        html += "        <td class='thetisbox_message_title' style='color:white; text-indent:5px;'>";
        html += "          <b>"+this.title+"</b>";
        html += "        </td>";
        html += "        <td style='text-align:right; vertical-align:middle; padding-right:5px; width:20px;'>";
        html += "          <img class='nodrag' src='"+this.button_close_img+"' style='cursor:pointer; vertical-align:middle;' onclick=\"ThetisBox.remove('"+this.id+"');\">";
        html += "        </td>";
        html += "      </tr>";
        html += "    </table>";
        html += "  </td>";
      } else {
        html += "  <td class='thetisbox_message_title' style='color:white; background-color:"+this.bgcolor_title+"; text-indent:5px;'><b>"+this.title+"</b></td>";
      }
      html += "  </tr>";
    }
    if (cap != null && cap.length > 0) {
      html += "  <tr>";
      html += "    <td style='cursor:default; padding-left:3px;'>";
      html += "      <div id='thetisBoxCaption-"+this.id+"'>" + cap + "</div>";
      html += "    </td>";
      html += "  </tr>";
    }
//    if (!this.close_by_icon_button) {
      html += "  <tr style='height:40px;'>";
      html += "    <td style='width:100%; text-align:center;'>";
      html += "      <table style='width:100%; height:100%;'>";
      html += "        <tr>";
      html += "          <td style='text-align:center;'>";
      html += "            <input type='button' id='thetisBoxOk-"+this.id+"' value='"+this.button_ok+"' tabindex='2' style='width:90px; height:25px' onclick=\"ThetisBox.remove('"+this.id+"');\">";
      html += "          </td>";
      html += "        </tr>";
      html += "      </table>";
      html += "    </td>";
      html += "  </tr>";
//    }
    html += "</table>";

    if (this.resizable == "left") {
      html += "  <div class=\"thetisbox_resize_handle_l\" id=\"thetisBoxResizeHandle-"+this.id+"\" style=\"display:inline-block; position:absolute; width:20px; height:20px; cursor:move;\"></div>";
    }
    if (this.resizable == "right") {
      html += "  <div class=\"thetisbox_resize_handle_r\" id=\"thetisBoxResizeHandle-"+this.id+"\" style=\"position:absolute; width:20px; height:20px; cursor:move;\"></div>";
    }
    html += "</div>";
    var d = document.createElement("div");
    d.innerHTML = html;
    this.parent_elem.appendChild(d.firstChild);
  },
  // PROGRESS
  drawProgress: function(hasTitlebar, cap)
  {
    var html = "";
    html += "<div class='thetisbox progress' id='divThetisBox-"+this.id+"' style='position:absolute; z-index:"+this.z_index+"; display:none;'>";
    html += "<table class='thetisbox_progress_dialog' id='thetisBoxBase-"+this.id+"' style='width:100%; height:100%; border:solid 2px; border-top-color:whitesmoke; border-left-color:whitesmoke; border-bottom-color:dimgray; border-right-color:dimgray; background-color:"+this.bgcolor_body+";'>";
    if (hasTitlebar) {
      html += "  <tr style='height:25px;'>";
      html += "    <td class='thetisbox_progress_title' style='color:white; background-color:"+this.bgcolor_title+"; text-indent:5px;'><b>"+this.title+"</b></td>";
      html += "  </tr>";
    }
    if (cap != null && cap.length > 0) {
      html += "  <tr>";
      html += "    <td style='text-align:center; cursor:default; padding-left:3px;'>";
      html += "      <div id='thetisBoxCaption-"+this.id+"'>" + cap + "</div>";
      html += "    </td>";
      html += "  </tr>";
    }
    html += "  <tr>";
    html += "    <td style='text-align:center; cursor:default;'>";
    html += "      <table style='border:solid limegreen 1px; margin:0px auto; background-color:#fff; border-spacing:2px;'>";
    html += "        <tr>";
    for (i=1; i<=20; i++) {
      html += "          <td style='min-width:10px; width:10px; height:20px;' id='thetisBoxProgress-"+this.id+"_"+i+"'></td>";
    }
    html += "        </tr>";
    html += "      </table>";
    html += "    </td>";
    html += "  </tr>";
    html += "</table>";
    html += "</div>";
    var d = document.createElement("div");
    d.innerHTML = html;
    this.parent_elem.appendChild(d.firstChild);

    var progressor = new ThetisBoxProgressor(this.id);
    ThetisBoxProgressors.push(progressor);
    progressor.update();
  },
  // TIP
  drawTip: function(hasTitlebar, cap)
  {
    var html = "";
    html += "<div class='thetisbox tip' id='divThetisBox-"+this.id+"' style='position:absolute; z-index:"+this.z_index+"; display:none;'>";
    html += "<table class='thetisbox_tip_dialog' id='thetisBoxBase-"+this.id+"' style='width:100%; height:100%; border:solid 2px; border-top-color:whitesmoke; border-left-color:whitesmoke; border-bottom-color:dimgray; border-right-color:dimgray; background-color:"+this.bgcolor_body+";'>";
    if (hasTitlebar) {
      html += "  <tr style='height:25px;'>";
      html += "    <td class='thetisbox_tip_title' style='color:white; background-color:"+this.bgcolor_title+"; text-indent:5px;'><b>"+this.title+"</b></td>";
      html += "  </tr>";
    }
    html += "  <tr>";
    html += "    <td style='text-align:left; cursor:move; padding-left:20px; padding-right:20px;'>";
    html += "      <div id='thetisBoxCaption-"+this.id+"'>" + cap + "</div>";
    html += "    </td>";
    html += "  </tr>";
    html += "</table>";
    html += "</div>";
    var d = document.createElement("div");
    d.innerHTML = html;
    this.parent_elem.appendChild(d.firstChild);

    setTimeout("ThetisBox.remove("+this.id+");", 4000)
  },
  // IFRAME
  drawIFrame: function(hasTitlebar, src, cap)
  {
    var html = "";
    html += "<div class='thetisbox iframe' id='divThetisBox-"+this.id+"' style='position:absolute; z-index:"+this.z_index+"; display:none;'>";
    html += "<table class='thetisbox_iframe_dialog' id='thetisBoxBase-"+this.id+"' style='width:100%; border:solid 2px; border-top-color:whitesmoke; border-left-color:whitesmoke; border-bottom-color:dimgray; border-right-color:dimgray; background-color:"+this.bgcolor_body+";'>";
    if (hasTitlebar) {
      html += "  <tr>";
      if (this.button_close_img == null) {
        html += "  <td class='thetisbox_iframe_title' colspan='2' style='color:white; background-color:"+this.bgcolor_title+"; text-indent:5px;'>";
        html += "    <b>"+this.title+"</b>";
        html += "  </td>";
      } else {
        html += "  <td colspan='2' style='background-color:"+this.bgcolor_title+";'>";
        html += "    <table style='width:100%; border-spacing:0px;'>";
        html += "      <tr>";
        html += "        <td class='thetisbox_iframe_title' style='color:white; text-indent:5px;'>";
        html += "          <b>"+this.title+"</b>";
        html += "        </td>";
        html += "        <td style='text-align:right; vertical-align:middle; padding-right:5px; width:20px;'>";
        html += "          <img class='nodrag' src='"+this.button_close_img+"' style='cursor:pointer; vertical-align:middle;' onclick=\"ThetisBox.remove('"+this.id+"');\">";
        html += "        </td>";
        html += "      </tr>";
        html += "    </table>";
        html += "  </td>";
      }
      html += "  </tr>";
    }
    if (cap != null && cap.length > 0) {
      html += "  <tr>";
      html += "    <td style='width:95%; cursor:default; padding-left:3px;'>";
      html += "      <div id='thetisBoxCaption-"+this.id+"'>" + cap + "</div>";
      html += "    </td>";
      html += "    <td style='width:100px; text-align:center;'>";
      if (this.button_close_img == null) {
        html += "      <table style='width:100%; height:100%;'>";
        html += "        <tr>";
        html += "          <td style='text-align:center;'>";
        html += "            <input type='button' id='thetisBoxClose-"+this.id+"' value='"+this.button_close+"' tabindex='2' style='width:90px; height:25px' onclick=\"ThetisBox.remove('"+this.id+"');\">";
        html += "          </td>";
        html += "        </tr>";
        html += "      </table>";
      }
      html += "    </td>";
      html += "  </tr>";
    }
    var border_style = null;
    var frameborder = "";
    if (this.border_content == null) {
      border_style = "border:2px solid lightgrey; border-right:2px solid dimgray; border-bottom:2px solid dimgray;";
    } else if (this.border_content == "") {
      border_style = "border:none;";
      frameborder = "frameborder='0'";
    } else {
      border_style = this.border_content;
    }
    html += "  <tr>";
    html += "    <td colspan='2' style='text-align:center;'>";
    html += "      <iframe id='thetisBoxContent-"+this.id+"' src='"+src+"' "+frameborder+" style='width:100%; height:240px; "+border_style+" background-color:white;'></iframe>";
    html += "    </td>";
    html += "  </tr>";
    html += "</table>";

    if (this.resizable == "left") {
      html += "  <div class=\"thetisbox_resize_handle_l\" id=\"thetisBoxResizeHandle-"+this.id+"\" style=\"display:inline-block; position:absolute; width:20px; height:20px; cursor:move;\"></div>";
    }
    if (this.resizable == "right") {
      html += "  <div class=\"thetisbox_resize_handle_r\" id=\"thetisBoxResizeHandle-"+this.id+"\" style=\"position:absolute; width:20px; height:20px; cursor:move;\"></div>";
    }
    html += "</div>";
    var d = document.createElement("div");
    d.innerHTML = html;
    this.parent_elem.appendChild(d.firstChild);
  },
  // TRAY
  drawTray: function(hasTitlebar, cap)
  {
    var html = "";
    html += "<div class='thetisbox tray' id='divThetisBox-"+this.id+"' style='position:absolute; z-index:"+this.z_index+"; display:none;'>";
    html += "<table class='thetisbox_tray_dialog' id='thetisBoxBase-"+this.id+"' style='width:100%; border:solid 2px; border-top-color:whitesmoke; border-left-color:whitesmoke; border-bottom-color:dimgray; border-right-color:dimgray; background-color:"+this.bgcolor_body+";'>";
    if (hasTitlebar) {
      html += "  <tr id='thetisBoxTitlebar-"+this.id+"' style='height:25px;'>";
      if (this.button_close_img == null) {
        html += "  <td class='thetisbox_tray_title' colspan='2' style='color:white; background-color:"+this.bgcolor_title+"; text-indent:5px;'>";
        html += "    <b>"+this.title+"</b>";
        html += "  </td>";
      } else {
        html += "  <td colspan='2' style='background-color:"+this.bgcolor_title+";'>";
        html += "    <table style='width:100%; border-spacing:0px;'>";
        html += "      <tr>";
        html += "        <td class='thetisbox_tray_title' style='color:white; text-indent:5px;'>";
        html += "          <b>"+this.title+"</b>";
        html += "        </td>";
        html += "        <td style='text-align:right; vertical-align:middle; padding-right:5px; width:20px;'>";
        html += "          <img class='nodrag' id='thetisBoxClose-"+this.id+"' src='"+this.button_close_img+"' style='cursor:pointer; vertical-align:middle;' onclick=\"ThetisBox.remove('"+this.id+"');\">";
        html += "        </td>";
        html += "      </tr>";
        html += "    </table>";
        html += "  </td>";
      }
      html += "  </tr>";
    }
    if (cap != null && cap.length > 0) {
      html += "  <tr>";
      html += "    <td style='width:95%; cursor:default; padding-left:3px;'>";
      html += "      <div id='thetisBoxCaption-"+this.id+"'>" + cap + "</div>";
      html += "    </td>";
      if (this.button_close_img == null) {
        html += "    <td style='width:100px; text-align:center;'>";
        html += "      <table style='width:100%; height:100%;'>";
        html += "        <tr>";
        html += "          <td style='text-align:center;'>";
        html += "            <input type='button' id='thetisBoxClose-"+this.id+"' value='"+this.button_close+"' tabindex='2' style='width:90px; height:25px' onclick=\"ThetisBox.remove('"+this.id+"');\">";
        html += "          </td>";
        html += "        </tr>";
        html += "      </table>";
        html += "    </td>";
      }
      html += "  </tr>";
    }
    html += "  <tr>";
    html += "    <td colspan='2' style='text-align:center;'>";
    var border_style = null;
    if (this.border_content == null) {
      border_style = "border:2px solid lightgrey; border-right:2px solid dimgray; border-bottom:2px solid dimgray;";
    } else {
      border_style = this.border_content;
    }
    var bgcolor = null;
    if (this.bgcolor_content == null) {
      bgcolor = "white";
    } else {
      bgcolor = this.bgcolor_content;
    }
    html += "      <div id='thetisBoxContent-"+this.id+"' style='width:100%; "+border_style+" background-color:"+bgcolor+"; overflow:"+this.overflow+";'></div>";
    html += "    </td>";
    html += "  </tr>";
    html += "</table>";

    if (this.resizable == "left") {
      html += "  <div class=\"thetisbox_resize_handle_l\" id=\"thetisBoxResizeHandle-"+this.id+"\" style=\"display:inline-block; position:absolute; width:20px; height:20px; cursor:move;\"></div>";
    }
    if (this.resizable == "right") {
      html += "  <div class=\"thetisbox_resize_handle_r\" id=\"thetisBoxResizeHandle-"+this.id+"\" style=\"position:absolute; width:20px; height:20px; cursor:move;\"></div>";
    }
    html += "</div>";
    var d = document.createElement("div");
    d.innerHTML = html;
    this.parent_elem.appendChild(d.firstChild);
  },
  // Show
  show: function(p_position, p_size, p_type, p_action, p_caption, p_def)
  {
    if (!p_type) {
      ThetisBox.show(this.id);
      return;
    }
    this.box_type = p_type;

    if (!this.button_ok) {
      this.button_ok = __thetisbox_ok;
    }
    if (!this.button_cancel) {
      this.button_cancel = __thetisbox_cancel;
    }
    if (!this.button_close) {
      this.button_close = __thetisbox_close;
    }
    if (!this.button_close_img) {
      this.button_close_img = __thetisbox_close_img;
    }

    if (!this.parent_elem) {
      this.parent_elem = document.body;
    }

    if ((p_type == "TREE" || p_type == "MINI-TREE")
        && (this.resizable == null)) {
      this.resizable = true;
    }
    if (this.resizable == true) {
      if (p_position.indexOf("RIGHT") >= 0) {
        this.resizable = "left";
      } else {
        this.resizable = "right";
      }
    }
    var hasTitlebar = (this.title != null);

    if (p_type == "INPUT") {
      if (this.bgcolor_title == null) this.bgcolor_title = "#fd58ff";
      if (this.bgcolor_body == null) this.bgcolor_body = "peachpuff";
      this.drawInput(p_action, hasTitlebar, false, p_caption);

    } else if (p_type == "TEXTAREA") {
      if (this.bgcolor_title == null) this.bgcolor_title = "#5da5ff";
      if (this.bgcolor_body == null) this.bgcolor_body = "#cde3ff";
      this.drawTextArea(p_action, hasTitlebar, false, p_caption);

    } else if (p_type == "TREE" || p_type == "MINI-TREE") {
      if (this.bgcolor_title == null) this.bgcolor_title = "darkgoldenrod";
      if (this.bgcolor_body == null) this.bgcolor_body = "moccasin";
      if (p_type == "TREE") {
        this.drawTree(p_action, hasTitlebar, p_caption);
      } else {
        this.drawMiniTree();
      }

    } else if (p_type == "CONFIRM") {
      if (this.bgcolor_title == null) this.bgcolor_title = "#fd58ff";
      if (this.bgcolor_body == null) this.bgcolor_body = "peachpuff";
      var ok_act = "";
      var cancel_act = "";
      if (ThetisBox.isArray(p_action)) {
        try {
          ok_act = p_action[0];
          cancel_act = p_action[1];
        } catch (e) {}
      } else {
        ok_act = p_action;
      }
      this.drawConfirm(ok_act, cancel_act, hasTitlebar, p_caption);

    } else if (p_type == "MESSAGE") {
      if (this.bgcolor_title == null) this.bgcolor_title = "#fd58ff";
      if (this.bgcolor_body == null) this.bgcolor_body = "peachpuff";
      this.drawMessage(hasTitlebar, p_caption);

    } else if (p_type == "PROGRESS") {
      if (this.bgcolor_title == null) this.bgcolor_title = "#fd58ff";
      if (this.bgcolor_body == null) this.bgcolor_body = "palegreen";
      this.drawProgress(false, p_caption);

    } else if (p_type == "TIP") {
      if (this.bgcolor_title == null) this.bgcolor_title = "#fd58ff";
      if (this.bgcolor_body == null) this.bgcolor_body = "yellow";
      this.drawTip(false, p_caption);

    } else if (p_type == "IFRAME") {
      if (this.bgcolor_title == null) this.bgcolor_title = "royalblue";
      if (this.bgcolor_body == null) this.bgcolor_body = "#7FD6FF";   // "skyblue"
      this.drawIFrame(hasTitlebar, p_def, p_caption);

    } else if (p_type == "TRAY") {
      if (this.bgcolor_title == null) this.bgcolor_title = "royalblue";
      if (this.bgcolor_body == null) this.bgcolor_body = "#7FD6FF";   // "skyblue"
      this.drawTray(hasTitlebar, p_caption);
    }

    var box =  _z("divThetisBox-"+this.id);
    var edit = _z("thetisBoxEdit-"+this.id);
    var cap =  _z("thetisBoxCaption-"+this.id);
    var content =  _z("thetisBoxContent-"+this.id);

    // Default Value
    if (edit != null) {
       edit.value = p_def;
    }
    // Content
    if (p_type == "TRAY" && content != null && p_def != null) {
      content.innerHTML = p_def;
    }

    // Size and Position
    var x=0, y=0, width=0, height=0;

    switch (p_type) {
      case "MINI-TREE":
        width = 260;  break;
      default:
        width = 350;  break;
    }

    var size = p_size.split(",");
    var isMinWidth = false;
    var isMinHeight = false;
    if (size.length >= 2) {
      if (parseInt(size[0]) > 0) {
        width = parseInt(size[0]);
        isMinWidth = (size[0].charAt(0) == "+");
      }
      height = parseInt(size[1]);
      isMinHeight = (size[1].charAt(0) == "+");
    }

    if (width > 0) {
      if (isMinWidth) {
        box.style.minWidth = width + "px";
      } else {
        box.style.width = width + "px";
      }
    } else {
      width = 350;
    }
    if (height > 0) {
      if (isMinHeight) {
        box.style.minHeight = height + "px";
      } else {
        box.style.height = height + "px";
      }

      var chg_h = content;
      if (chg_h != null) {
        var cap_height = 0;
        if (cap != null) {
          box.style.display = "inline-block";   // to get cap_height
          cap_height = cap.offsetHeight + 8;
        }
        var h = height - cap_height - 56;
        if (h < 0) {
          h = 0;
        }
        if (isMinHeight) {
          chg_h.style.minHeight = h + "px";
        } else {
          chg_h.style.height = h + "px";
        }
      }
    } else {
      switch (p_type) {
        case "TEXTAREA":
          height = 250;  break;
        case "TREE":
          height = 420;  break;
        case "MINI-TREE":
          height = 260;  break;
        case "PROGRESS":
          height = 100;  break;
        case "TIP":
          height = 70;  break;
        case "IFRAME":
          height = 320;  break;
        case "TRAY":
          height = 320;  break;
        case "INPUT":
        case "CONFIRM":
        case "MESSAGE":
        default:
          height = 160;  break;
      }
    }

    var clientRegion = ThetisBox.getClientRegion();
    var bodyScroll = ThetisBox.getBodyScroll();

    var pos = p_position.split(",");
    if (pos.length == 1) {
      switch(pos[0]) {
        case "CENTER":
          x = bodyScroll.left + (clientRegion.width - width)/2;
          y = bodyScroll.top + (clientRegion.height - height)/2;
          break;
        case "TOP-LEFT":
          x = bodyScroll.left;
          y = bodyScroll.top;
          break;
        case "TOP-RIGHT":
        default:
          x = bodyScroll.left + clientRegion.width - width - 2; // 2 = Border Width maybe (for IE9)
          y = bodyScroll.top;
          break;
      }
    } else if (pos.length >= 2) {
      x = parseInt(pos[0]);
      y = parseInt(pos[1]);
    }

    if (x < 0) {
      x = 0;
    }
    if (y < 0) {
      y = 0;
    }

    box.style.left = x + "px";
    box.style.top = y + "px";
    box.style.display = "inline-block";

    // DRAG BY PROTOTYPE.JS >>>
    var resizeHandle = _z("thetisBoxResizeHandle-" + this.id);
    if (resizeHandle) {
      var base = this.getBase();
      if (this.resizable == "left") {
        resizeHandle.style.left = "0px";
        resizeHandle.style.top = (base.offsetHeight - resizeHandle.offsetHeight) + "px";
      } else {
        resizeHandle.style.left = (base.offsetWidth - resizeHandle.offsetWidth) + "px";
        resizeHandle.style.top = (base.offsetHeight - resizeHandle.offsetHeight) + "px";
      }
      new Draggable(resizeHandle, {revert:false, starteffect:"", endeffect:"", zindex:10000});
    }
    // DRAG BY PROTOTYPE.JS <<<

    // Focus
    if (edit != null) {
      edit.focus();
    }

    box.onmousedown = this.onMouseDown;
    box.onmousemove = this.onMouseMove;
    box.onmouseup = this.onMouseUp;

    return this.id;
  },
  getContainer: function()
  {
    return _z("divThetisBox-"+this.id);
  },
  getBase: function()
  {
    return _z("thetisBoxBase-"+this.id);
  },
  getContent: function()
  {
    return _z("thetisBoxContent-"+this.id);
  },
  // Remove
  remove: function()
  {
    ThetisBox.remove(this.id);
  },
  // Hide
  hide: function()
  {
    ThetisBox.hide(this.id);
  },
  // Additional Parameters
  setAdditionalParams: function(params)
  {
    this.additionalParams = params;
  },
  // Tree
  getTreeRootDivId: function()
  {
    return ("thetisBoxTree-"+this.id);
  },
  buildTree: function(parentTreeId, nodes, open, linkerTagName)
  {
    return ThetisBox.buildTree(parentTreeId, nodes, this.getTreeRootDivId(), this.folderImg, open, linkerTagName);
  },
  selectTree: function(nodeId, forceOpen)
  {
    return ThetisBox.selectTree(this.getTreeRootDivId(), nodeId, forceOpen);
  },
  getSelectedTreeNodeId: function()
  {
    return ThetisBox.getSelectedTreeNodeId(this.getTreeRootDivId());
  },
  setTree: function(url, selNodeId, onComplete)
  {
    var d = document.createElement("div");
    d.innerHTML = "<form method='get' name='form_ajax_thetisBoxTree'>"
        + "<input type='hidden' name='rootDiv' value='thetisBoxTree-"+this.id+"' />"
        + "<input type='hidden' name='selNodeId' value='"+selNodeId+"' />"
        + "</form>";
    this.parent_elem.appendChild(d);

    var thetisBox = new ThetisBox;
    thetisBox.show("CENTER", "", "PROGRESS", "", "", "");
    new Ajax.Updater(
        "thetisBoxTree-"+this.id,
        url,
        {
          method:"get",
          parameters: Form.serialize(document.form_ajax_thetisBoxTree),
          evalScripts: false,
          onComplete: function(request) {
            d.parentNode.removeChild(d);
            thetisBox.remove();

            request.responseText.evalScripts();

            if (onComplete) {
              onComplete();
            }
          }
        }
      );
  },
  // Start Dragging
  onMouseDown: function(evt)
  {
    evt = evt || window.event;
    var elem = evt.target || evt.srcElement;
    for (var node=elem; node && (!node.className || node.className.indexOf("thetisbox") != 0); node=node.parentNode) {
      if (node.className.indexOf("nodrag") >= 0
          || node.tagName.toLowerCase() == "select") {
        /*
         * For IE:
         * <select> which has a dropdown list can't recognize Click
         * on the options exceeding the popup window.
         */
        return true;
      }
    }

    var id = this.id.split("-")[1];

    // Excluded Control Area
    var excludeArray = [
      "thetisBoxOk-"+id,
      "thetisBoxCancel-"+id,
      "thetisBoxClose-"+id,
      "thetisBoxEdit-"+id,
      "thetisBoxTree-"+id,
      "thetisBoxContent-"+id
    ];

    var bodyScroll = ThetisBox.getBodyScroll();

    for (var i=0; i < excludeArray.length; i++) {
      var excludeCtrl = _z(excludeArray[i]);
      if (excludeCtrl == null) {
        //alert(excludeArray[i] + "is null!!");
        continue;
      }
      if (Position.within(excludeCtrl, bodyScroll.left+evt.clientX, bodyScroll.top+evt.clientY)) {
        return true;
      }
    }

    // Starting to Drag
    this.selected = true;
    if (document.all) {
      this.offsetX = evt.clientX + bodyScroll.left - parseInt(this.style.left);
      this.offsetY = evt.clientY + bodyScroll.top - parseInt(this.style.top);
    } else if (document.getElementById) {
      this.offsetX = evt.pageX - parseInt(this.style.left);
      this.offsetY = evt.pageY - parseInt(this.style.top);
    }
    return false;
  },
  // Dragging
  onMouseMove: function(e)
  {
    if (!this.selected) {
      return true;
    }

    var l, t;
    if (document.all) {
      var bodyScroll = ThetisBox.getBodyScroll();
      l = event.clientX + bodyScroll.left - this.offsetX;
      t = event.clientY + bodyScroll.top - this.offsetY;
    } else if (document.getElementById) {
      l = e.pageX - this.offsetX;
      t = e.pageY - this.offsetY;
    }
    if (l >= 0 && t >= 0 && l <= 5000 && t <= 10000) {
      this.style.left = l + "px";
      this.style.top = t + "px";
    } else {
      this.selected = false;
      try {
        document.selection.empty();
      } catch(e){}
    }
    return false;
  },
  // Release
  onMouseUp: function(e)
  {
    this.selected = false;
  },
  setOnClose: function(func) {
    ThetisBox.setOnClose(this.id, func);
  },
  setBeforeClose: function(func) {
    ThetisBox.setBeforeClose(this.id, func);
  },
  box_type: null,
  close_by_icon_button: true,
  offsetX: 0,
  offsetY: 0,
  additionalParams: null,
  title: __thetisbox_title,
  button_ok: null,
  button_cancel: null,
  button_close: null,
  button_close_img: null,
  bgcolor_title: null,
  bgcolor_body: null,
  bgcolor_content: null,
  border_content: null,
  resizable: null,
  z_index: 10000,
  overflow: "auto",
  parent_elem: null,
  ignore_clear: false,
  setAutoClose: function() {
    var self = this;

    var onBoxMouseUp = function(evt) {
      evt = (evt || window.event);
      var src = (evt.target || evt.srcElement);

      var resizeHandle = _z("thetisBoxResizeHandle-" + self.id);
      if (resizeHandle && src == resizeHandle) {
        return;
      }
      stopEvent(evt);
    };
    addEvent(this.getContainer(), "mouseup", onBoxMouseUp);

    var onBodyMouseUp = function(evt) {
      evt = (evt || window.event);
      var src = (evt.target || evt.srcElement);

      var resizeHandle = _z("thetisBoxResizeHandle-" + self.id);
      if (resizeHandle && src == resizeHandle) {
        return;
      }
      hideFunc();
    };

    var hideFunc = function() {
      removeEvent(document.body, "mouseup", onBodyMouseUp);
      self.remove();
    };

    this.setOnClose(
        function() {
          removeEvent(document.body, "mouseup", onBodyMouseUp);
        }
      );
    addEvent(document.body, "mouseup", onBodyMouseUp);
  },
  addChildBox: function(childBox) {
    if (!this.child_boxes) {
      this.child_boxes = [];
    }
    this.child_boxes.push(childBox);
  },
  onResized: null,
  child_boxes: null
});

ThetisBox.alignPosInsideFrame = function(elem)
{
  var width = elem.clientWidth;
  var height = elem.clientHeight;
  var pos = getPos(elem);
  var regionWidth = document.documentElement.clientWidth;
  var regionHeight = document.documentElement.clientHeight;

  var bodyScroll = ThetisBox.getBodyScroll();

  if ((regionWidth >= width) && ((pos.x + width) > (bodyScroll.left+regionWidth))) {
    elem.style.left = (bodyScroll.left+(regionWidth - width)) + "px";
  }
  if ((regionHeight >= height) && ((pos.y + height) > (bodyScroll.top+regionHeight))) {
    elem.style.top = (bodyScroll.top+(regionHeight - height)) + "px";
  }
}

ThetisBox.show = function(id)
{
  var box = _z("divThetisBox-"+id);
  if (box == null) {
    return;
  }
  box.style.display = "inline-block";
}

ThetisBox.hide = function(id)
{
  var box = _z("divThetisBox-"+id);
  if (box == null) {
    return;
  }
  box.style.display = "none";
}

ThetisBox.getInstance = function(id)
{
  switch (typeof(id)) {
    case "string":
      id = parseInt(id, 10);
      // FALL THROUGH
    case "number":
    {
      for (var i=0; i < ThetisBox.array.length; i++) {
        var instance = ThetisBox.array[i];
        if (instance.id == id) {
          return instance;
        }
      }
      break;
    }
    default:
      return ThetisBox.getInstanceForElem(id);
  }
  return null;
}

ThetisBox.getInstanceForElem = function(elem)
{
  var container = ThetisBox.getContainer(elem);
  if (container){
    var id = container.id.split("-")[1];
    return ThetisBox.getInstance(id);
  }
  return null;
}

ThetisBox.remove = function(id)
{
  var box = _z("divThetisBox-"+id);
  if (box == null) {
    return;
  }

  var childBoxes = null;
  for (var i=0; i < ThetisBox.array.length; i++) {
    var instance = ThetisBox.array[i];
    if (instance.id == id) {
      childBoxes = instance.child_boxes;
      ThetisBox.array.splice(i, 1);
      break;
    }
  }

  if (childBoxes) {
    for (var i=0; i < childBoxes.length; i++) {
      childBoxes[i].remove();
    }
  }

  var arr = ThetisBoxEventHandlers;
  var onClose = null;
  var beforeClose = null;
  for (var i=0; i < arr.length; i++) {
    if (arr[i][0] == id) {
      onClose = arr[i][1];
      beforeClose = arr[i][2];
      arr.splice(i, 1);
      break;
    }
  }

  if (beforeClose != null) {
    if (typeof(beforeClose) == "function") {
      beforeClose();
    } else {
      eval(beforeClose);
    }
  }

  var progs = ThetisBoxProgressors;
  for (var i=0; i < progs.length; i++) {
    if (progs[i].id == id) {
      progs.splice(i, 1);
      break;
    }
  }

  box.style.display = "none";
  box.parentNode.removeChild(box);

  if (onClose != null) {
    if (typeof(onClose) == "function") {
      onClose();
    } else {
      eval(onClose);
    }
  }
}

ThetisBox.isAlive = function(id)
{
  return (_z("divThetisBox-"+id) != null);
}

ThetisBox.count = function(box_type)
{
  var cnt = 0;
  for (var i=__thetisbox_id; i >= 0; i--) {
    if (box_type) {
      var instance = ThetisBox.getInstance(i);
      if (!instance || instance.box_type != box_type) {
        continue;
      }
    }
    cnt++;
  }
  return cnt;
}

ThetisBox.clear = function(boxType)
{
  for (var i=__thetisbox_id; i >= 0; i--) {
    var instance = ThetisBox.getInstance(i);
    if (!instance || instance.ignore_clear) {
      continue;
    }
    if (boxType && (instance.box_type != boxType)) {
      continue;
    }
    ThetisBox.remove(i);
  }
}

ThetisBox.removeLastProgressBar = function()
{
  for (var i=__thetisbox_id; i >= 0; i--) {
    var box = _z("divThetisBox-"+i);
    if (box && box.className.indexOf("progress") >= 0) {
      ThetisBox.remove(i);
      return;
    }
  }
}

ThetisBox.setOnClose = function(id, onFunc)
{
  var beforeFunc = null;
  var arr = ThetisBoxEventHandlers;
  for (var i=0; i < arr.length; i++) {
    if (arr[i][0] == id) {
      beforeFunc = arr[i][2];
      arr.splice(i, 1);
    }
  }
  if ((onFunc != null) || (beforeFunc != null)) {
    arr.push([id, onFunc, beforeFunc]);
  }
}

ThetisBox.setBeforeClose = function(id, beforeFunc)
{
  var onFunc = null;
  var arr = ThetisBoxEventHandlers;
  for (var i=0; i < arr.length; i++) {
    if (arr[i][0] == id) {
      onFunc = arr[i][1];
      arr.splice(i, 1);
    }
  }
  if ((beforeFunc != null) || (onFunc != null)) {
    arr.push([id, onFunc, beforeFunc]);
  }
}

var ThetisBoxEventHandlers = [];

/**----------------**----------------**----------------**----------------**/

var ThetisBoxProgressors = [];

var ThetisBoxProgressor = Class.create();
ThetisBoxProgressor.prototype = {
  id: 0,
  progressAt: 0,
  progressTimer: null,
  progressDirection: 1,

  initialize: function(id) {
    this.id = id;
  },

  clear: function() {
    for (var i=1; i<=20; i++) {
      _z("thetisBoxProgress-"+this.id+"_"+i).style.backgroundColor = "transparent";
    }
    this.progressAt = 0;
    this.progressDirection = 1;
  },

  update: function() {
    if (_z("thetisBoxProgress-"+this.id+"_1") == null) {
      clearTimeout(this.progressTimer);
      return;
    }
    if (this.progressDirection > 0) {
      this.progressAt++;
    } else {
      this.progressAt--;
    }
    var pause = false;
    if (this.progressAt < 1 || this.progressAt > 20) {
       switch (this.progressDirection) {
       case 1:
         this.progressAt = 0;
         this.progressDirection = 2; break;
       case 2:
         pause = true;
         this.progressAt = 21;
         this.progressDirection = -1; break;
       case -1:
         this.progressAt = 21;
         this.progressDirection = -2; break;
       case -2:
         pause = true;
         this.progressAt = 0;
         this.progressDirection = 1; break;
       }

    } else {
      var bgcolor;
      if (Math.abs(this.progressDirection) == 1) {
        bgcolor = "lime";
      } else {
        bgcolor = "transparent";
      }
      _z("thetisBoxProgress-"+this.id+"_"+this.progressAt).style.backgroundColor = bgcolor;
    }
    this.progressTimer = setTimeout("ThetisBoxProgressor.progress("+this.id+")", pause?700:20);
  }
}

ThetisBoxProgressor.progress = function(id)
{
  var progressor = null;
  for (var i=0; i < ThetisBoxProgressors.length; i++) {
    if (ThetisBoxProgressors[i].id == id) {
      progressor = ThetisBoxProgressors[i];
      break;
    }
  }
  if (progressor == null) {
    return;
  }
  progressor.update();
}

/**----------------**----------------**----------------**----------------**/

ThetisBox.getTimeSpanDialog = function(hours, mins, onOk, onCancel, org_start, org_end)
{
  var start_hour = null;
  var start_min = null;
  var end_hour = null;
  var end_min = null;

  if (org_start) {
    start_hour = org_start.split(" ")[1].split(":")[0];
    start_min = org_start.split(" ")[1].split(":")[1];
  }
  if (org_end) {
    end_hour = org_end.split(" ")[1].split(":")[0];
    end_min = org_end.split(" ")[1].split(":")[1];
  }

  var html = "<form name='form_span'>";
  html += "<table style='width:100%; height:180px; border-spacing:0px;'>";
  html += "  <tr style='height:70px;'>";
  html += "    <td style='text-align:center; vertical-align:middle;'>";

  html += "      <select name='start_hour'>";
  for (var i=0; i<hours.length; i++) {
    var selected = "";
    if (start_hour == hours[i]) {
      selected = "selected";
    }
    html += "        <option value='" + hours[i] + "' " + selected + ">" + hours[i] + "</option>";
  }
  html += "      </select>";
  html += "      <select name='start_min'>";
  for (var i=0; i<mins.length; i++) {
    var selected = "";
    if (start_min == mins[i]) {
      selected = "selected";
    }
    html += "        <option value='" + mins[i] + "' " + selected + ">" + ((mins[i]<10)?('0'+mins[i]):mins[i]) + "</option>";
  }
  html += "      </select>";
  html += " ~ ";
  html += "      <select name='end_hour'>";
  var selected = "";
  for (var i=0; i<hours.length; i++) {
    var selected = "";
    if (end_hour == hours[i]) {
      selected = "selected";
    }
    html += "        <option value='" + hours[i] + "' " + selected + ">" + hours[i] + "</option>";
  }
  html += "      </select>";
  html += "      <select name='end_min'>";
  for (var i=0; i<mins.length; i++) {
    var selected = "";
    if (end_min == mins[i]) {
      selected = "selected";
    }
    html += "        <option value='" + mins[i] + "' " + selected + ">" + ((mins[i]<10)?('0'+mins[i]):mins[i]) + "</option>";
  }
  html += "      </select>";

  html += "    </td>";
  html += "  </tr>";
  html += "  <tr>";
  html += "    <td style='text-align:center; vertical-align:top;'>";
  html += "      <input type='button' value='"+__thetisbox_ok+"' onclick='"+onOk+"' style='width:80px' />";
  html += "      &nbsp;<input type='button' value='"+__thetisbox_cancel+"' onclick='"+onCancel+"' style='width:80px' />";
  html += "    </td>";
  html += "  </tr>";
  html += "  <tr style='height:100%'>";
  html += "    <td></td>";
  html += "  </tr>";
  html += "</table>";
  if (org_start) {
    html += "<input type='hidden' name='org_start' value='"+org_start+"' />";
  }
  if (org_end) {
    html += "<input type='hidden' name='org_end' value='"+org_end+"' />";
  }
  html += "</form>";
  return html;
}

/**----------------**----------------**----------------**----------------**/

ThetisBox.getSelKeeperId = function(rootDiv)
{
  return (rootDiv+":selectedNode");
}

ThetisBox.buildTree = function(parentTreeId, nodes, rootDiv, folderImg, open, linkerTagName)
{
  var selKeeperId = ThetisBox.getSelKeeperId(rootDiv);
  var selKeeper = _z(selKeeperId);
  if (!selKeeper) {
    selKeeper = addInputHidden(null, selKeeperId, null, "", _z(rootDiv));
  }
  var parent = null;
  if (parentTreeId == "") {
    parent = _z(rootDiv);
  } else {
    parent = _z(rootDiv+":"+parentTreeId);
    if (parent == null) {
      tip("No parentTree found! "+parentTreeId, "CENTER");
      return null;
    }
  }

  var firstNodeId = null;
  for (var i=0; i < nodes.length; i++) {

    var nodeId = nodes[i][0];
    var divId = rootDiv + ":" + nodeId;

    var base = document.createElement("div");
    base.id = "base_" + divId;

    base.style.padding = "0px";
    base.style.display = "block";
    base.noWrap = true;
    parent.appendChild(base);

    var linker = document.createElement((linkerTagName || "a"));
    linker.id = ThetisBox.getLinkerIdFromDivId(divId);
    linker.style.whiteSpace = "nowrap";
    if (firstNodeId == null) {
      firstNodeId = nodeId;
    }
    base.appendChild(linker);
    base.appendChild(document.createElement("br"));

    linker.innerHTML = "";
    if (folderImg != null) {
      if (ThetisBox.isArray(folderImg) && folderImg.length > 0) {
        try {
          var display_open = "";
          var display_close = "display:none;";
          if (open == false) {
            display_open = "display:none;";
            display_close = "";
          }
          linker.innerHTML += "<img id='"+divId+"_open' src='"+folderImg[nodes[i][4]][0]+"' border='0' style='vertical-align:middle;"+display_open+"'>";
          linker.innerHTML += "<img id='"+divId+"_close' src='"+folderImg[nodes[i][4]][1]+"' border='0' style='vertical-align:middle;"+display_close+"'>";
          linker.innerHTML += " ";
        } catch (e) {}
      } else if (folderImg != "") {
        linker.innerHTML += "<img src='"+folderImg+"' style='border:none; vertical-align:middle;'>";
        linker.innerHTML += " ";
      }
    }
    linker.innerHTML += "<span id='"+divId+"_name'>"+nodes[i][1]+"</span>";
    var onclick = "";
    if (nodes[i].length > 3) {
      onclick = nodes[i][3];
    }
    if (!nodes[i][2]) {    // Has subnodes
      var d = document.createElement("div");
      d.id = divId;
      d.className = "thetisBoxTreeBlock";
      d.style.paddingLeft = "20px";
      d.style.borderLeft = "1px dotted navy";
      if (open == false) {
        d.style.display = "none";
      }
      base.appendChild(d);

      linker.href = "javascript:void(0)";
      ThetisBox.addEvent(linker, "click",
          function(_onclick, _nodeId) {
            return function(evt) {

              eval(_onclick);

              var selNodeId = ThetisBox.getSelectedTreeNodeId(rootDiv);
              if (selNodeId == _nodeId) {
                ThetisBox.toggleTree(rootDiv, _nodeId);
              } else {
                ThetisBox.openTree(rootDiv, _nodeId, true);
              }
              ThetisBox.selectTree(rootDiv, _nodeId);
              return false;
            };
          }.call(this, onclick, nodeId)
        );
    } else {
      linker.href = "javascript:void(0)";
      ThetisBox.addEvent(linker, "click",
          function(_onclick, _nodeId) {
            return function(evt) {

              eval(_onclick);

              ThetisBox.selectTree(rootDiv, _nodeId);
              return false;
            };
          }.call(this, onclick, nodeId)
        );
    }
  }
  return firstNodeId;
}

ThetisBox.trimTree = function(rootDiv)
{
  return;    // doesn't work
  var d = _z(rootDiv);
  if (d == null) {
    return;
  }
  var childs = d.childNodes;
  if (childs != null && childs.length > 0) {
    for (var i=0; i < childs.length; i++) {
      if (childs[i].className != "thetisBoxTreeBlock") {
        continue;
      }
      ThetisBox.trimTree(childs[i].id);
    }
  } else {
    d.parentNode.removeChild(d);
  }
}

ThetisBox.toggleTree = function(rootDiv, nodeId)
{
  var divId = rootDiv+":"+nodeId;
  var nodeBlock = document.getElementById(divId);
  if (nodeBlock == null) {
    return;
  }

  ThetisBox._openTree(nodeBlock, (nodeBlock.style.display == "none"));
}

ThetisBox.openTree = function(rootDiv, nodeId, open)
{
  var divId = rootDiv+":"+nodeId;
  var nodeBlock = document.getElementById(divId);
  if (nodeBlock == null) {
    return;
  }
  ThetisBox._openTree(nodeBlock, open);
}

ThetisBox._openTree = function(nodeBlock, open)
{
  var openImg = document.getElementById(nodeBlock.id + "_open");
  var closeImg = document.getElementById(nodeBlock.id + "_close");

  if (open == true) {
    nodeBlock.style.display = "block";
    if (openImg != null) {
      openImg.style.display = "inline";
    }
    if (closeImg != null) {
      closeImg.style.display = "none";
    }
  } else {
    nodeBlock.style.display = "none";
    if (openImg != null) {
      openImg.style.display = "none";
    }
    if (closeImg != null) {
      closeImg.style.display = "inline";
    }
  }
}

ThetisBox.selectTree = function(rootDiv, nodeId, forceOpen)
{
  var selKeeperId = ThetisBox.getSelKeeperId(rootDiv);
  var selKeeper = _z(selKeeperId);
  if (!selKeeper) {
    return false;
  }
  var lastSelected = selKeeper.value;
  if (lastSelected) {
    _z(lastSelected).style.backgroundColor = "";
  }
  var linkerId = ThetisBox.getLinkerIdFromDivId(rootDiv+":"+nodeId);
  var linker = _z(linkerId);
  if (!linker) {
    return false;
  }
  linker.style.backgroundColor = "aquamarine";
  selKeeper.value = linkerId;

  if (forceOpen == true)
  {
    var elem = linker;
    ThetisBox.openTree(rootDiv, nodeId, true);

    while (elem = elem.parentNode) {
      if (elem.className == "thetisBoxTreeBlock") {
        var idParts = elem.id.split(":");
        ThetisBox.openTree(idParts[0], idParts[1], true);
      }
    }
  }
  return true;
}

ThetisBox.isSelectedTree = function(rootDiv, nodeId)
{
  var selNodeId = ThetisBox.getSelectedTreeNodeId(rootDiv);
  return (selNodeId == nodeId);
}

ThetisBox.getDivIdFromLinkerId = function(linkerId)
{
  return linkerId.substring(2, linkerId.length);
}

ThetisBox.getLinkerIdFromDivId = function(divId)
{
  return "a_" + divId;
}

ThetisBox.getSelectedTreeNodeId = function(rootDiv)
{
  var selKeeperId = ThetisBox.getSelKeeperId(rootDiv);
  var selKeeper = _z(selKeeperId);
  if (!selKeeper) {
    return null;
  }
  var val = selKeeper.value;
  if ((val == null) || (val == "")) {
    return null;
  }
  return ThetisBox.getTreeNodeIdFromLinkerId(val);
}

ThetisBox.getTreeNodeIdFromLinkerId = function(linkerId)
{
  if (!linkerId) {
    return null;
  }
  var tokens = linkerId.split(":");
  return tokens[tokens.length-1];
}

ThetisBox.getTreeFullPath = function(rootDiv, nodeId)
{
  var targetBlock = _z(rootDiv +":" + nodeId);

  var names = [];

  for (var node=targetBlock; node && node.id != rootDiv; node=node.parentNode) {
    if (node.className == "thetisBoxTreeBlock") {
      var nameNode = _z(node.id + "_name");
      if (nameNode) {
        names.splice(0, 0, ThetisBox.trim(nameNode.innerHTML, true));
      }
    }
  }
  return names.join("/");
}

ThetisBox.getTreeFullPathIds = function(rootDiv, nodeId)
{
  var targetBlock = _z(rootDiv +":" + nodeId);

  var ids = [];

  for (var node=targetBlock; node && node.id != rootDiv; node=node.parentNode) {
    if (node.className == "thetisBoxTreeBlock") {
      ids.splice(0, 0, node.id.split(":")[1]);
    }
  }
  return ids;
}

ThetisBox.trim = function(str, trimCRLF)
{
  if (str == null) {
    return null;
  }

  var avoid = " \u3000\t";
  if (trimCRLF) {
    avoid += "\r\n";
  }

  var start = -1;
  var end = -1;
  for (var i=0; i < str.length; i++){
    if (avoid.indexOf(str.charAt(i)) < 0) {
      start = i;
      break;
    }
  }
  for (var i=str.length -1; i >= 0; i--){
    if (avoid.indexOf(str.charAt(i)) < 0) {
      end = i+1;
      break;
    }
  }
  if (start == -1){
    return "";
  }
  return str.substring(start, end);
}

ThetisBox.isArray = function(obj)
{ 
  return ((typeof obj == "object") && (obj.constructor == Array));
}

ThetisBox.getBodyScroll = function()
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

ThetisBox.getClientRegion = function()
{
  var obj = new Object();

  //obj.width = document.body.offsetWidth;
  //obj.height = document.body.offsetHeight;

  obj.width = window.innerWidth;
  obj.height = window.innerHeight;

  return obj;
}

ThetisBox.addEvent = function(elem, eventName, func)
{
  // elem["on"+eventName] = func;

  if (elem.attachEvent){
    elem.attachEvent("on"+eventName, func);
  } else {
    elem.addEventListener(eventName, func, false);
  }
}

ThetisBox.removeEvent = function(elem, eventName, func)
{
  if (elem.detachEvent) {
    elem.detachEvent("on"+eventName, func);
  } else {
    elem.removeEventListener(eventName, func, false);
  }
}

msg = function(m, pos)
{
  pos = (pos || "CENTER");
  var thetisBox = new ThetisBox;
  thetisBox.show(pos, "", "MESSAGE", "", m, "");

  return thetisBox;
}

tip = function(m, position)
{
  if (!position) {
    position = "TOP-RIGHT";
  }
  var thetisBox = new ThetisBox;
  thetisBox.show(position, "", "TIP", "", m, "");

  return thetisBox;
}

prog = function(pos)
{
  var caption = "";

  if (arguments.length >= 2) {
    caption = arguments[1];
  }

  var thetisBox = new ThetisBox;
  thetisBox.show(pos, "", "PROGRESS", "", caption, "");

  return thetisBox;
}

confm = function(msg, action)
{
  var thetisBox = new ThetisBox;

  if (arguments.length >= 3) {
    thetisBox.setOnClose(arguments[2]);
  }
  if (arguments.length >= 4) {
    thetisBox.button_ok = arguments[3];
    thetisBox.button_cancel = arguments[4];
  }
  thetisBox.show("CENTER", "", "CONFIRM", action, msg, "");
  return thetisBox;
}
