/**-----------------**-----------------**-----------------**
   ThetisBox ver.1.1.0
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

var __thetisbox_id = 0;
var __thetisbox_title = 'Thetis';
var __thetisbox_OK = 'OK';
var __thetisbox_Cancel = 'Cancel';
var __thetisbox_Close = 'Close';
var __thetisbox_close_img = null;

/**----------------**----------------**----------------**----------------**/
// DRAG BY PROTOTYPE.JS >>>
var ThetisBoxDragObserver = Class.create();
ThetisBoxDragObserver.prototype = {
  initialize: function() {
  },
  onStart: function(eventName, draggable, event) {
    var elem = draggable.element;
    if (elem.className.indexOf("thetisbox_resize_handle") < 0) {
      return;
    }
    if (!is_MS && !is_Opera) {
      var id = elem.id.split("-")[1];
      var base = _z("thetisBoxBase-"+id);
      var box = _z("divThetisBox-"+id);
      var content = _z("thetisBoxContent-"+id);
      if (!content) {
        content = _z("thetisBoxTree-"+id);
      }
      var deltaWidth = base.offsetWidth - content.offsetWidth;
      if (deltaWidth < 0) {
        deltaWidth = 0;
      }
      var deltaHeight = base.offsetHeight - content.offsetHeight;
      if (deltaHeight < 0) {
        deltaHeight = 0;
      }

      draggable.options.snap = function(x, y) {
        return ThetisBox.onResizeHandleDragged(x, y, elem, base, box, content, deltaWidth, deltaHeight);
      };
    }
  },
  onDrag: function(eventName, draggable, event) {
    var elem = draggable.element;
    if (elem.className.indexOf("thetisbox_resize_handle") < 0) {
      return;
    }
    if (is_MS || is_Opera) {
      var id = elem.id.split("-")[1];
      var base = _z("thetisBoxBase-"+id);
      var box = _z("divThetisBox-"+id);
      var content = _z("thetisBoxContent-"+id);
      if (!content) {
        content = _z("thetisBoxTree-"+id);
      }
      var deltaWidth = base.offsetWidth - content.offsetWidth;
      if (deltaWidth < 0) {
        deltaWidth = 0;
      }
      var deltaHeight = base.offsetHeight - content.offsetHeight;
      if (deltaHeight < 0) {
        deltaHeight = 0;
      }

      draggable.options.snap = function(x, y) {
        return ThetisBox.onResizeHandleDragged(x, y, elem, base, box, content, deltaWidth, deltaHeight);
      };
    }
  },
  onEnd: function(eventName, draggable, event) {
    var elem = draggable.element;
    if (!is_MS && !is_Opera) {
      draggable.options.snap = false;
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

ThetisBox.setTitle = function(title) {__thetisbox_title=title};
ThetisBox.setOK = function(ok) {__thetisbox_OK=ok};
ThetisBox.setCancel = function(cancel) {__thetisbox_Cancel=cancel};
ThetisBox.setClose = function(close) {__thetisbox_Close=close};
ThetisBox.setCloseImg = function(image) {__thetisbox_close_img=image;};

// DRAG BY PROTOTYPE.JS >>>
ThetisBox.onResizeHandleDragged = function(x, y, elem, base, box, content, deltaWidth, deltaHeight)
{
  if (x <= 0 && y <= 0) {
    return [x, y];
  }
  var widthContent = x + elem.offsetWidth;
  var heightContent = y + elem.offsetHeight;
  if (widthContent < 30 && x < 0) {
    return [30, y];
  }
  if (heightContent < 30 && y < 0) {
    return [x, 30];
  }
  base.style.width = widthContent + "px";
  box.style.width = widthContent + "px";
  if (box.style.minWidth) {
    box.style.minWidth = widthContent + "px";
  }
  content.style.width = (widthContent - deltaWidth) + "px";
  base.style.height = heightContent + "px";
  box.style.height = heightContent + "px";
  if (box.style.minHeight) {
    box.style.minHeight = heightContent + "px";
  }
  content.style.height = (heightContent - deltaHeight) + "px";
  return [x, y];
};
// DRAG BY PROTOTYPE.JS <<<

ThetisBox.getContainer = function(elem)
{
  while (elem && elem.parentNode.tagName.toLowerCase() != "html") {
    elem = elem.parentNode;
    if (elem.id != null && elem.id.indexOf("divThetisBox-") >= 0) {
      return elem;
    }
  }
  return null;
}

ThetisBox.array = new Array();

Object.extend(Object.extend(ThetisBox.prototype, ThetisBox.Base.prototype), {
  initialize: function(element) {
    this.element = _z(element);
    this.id = ++__thetisbox_id;

    ThetisBox.array.push(this);
  },
  // INPUT
  drawInput: function(action, hasTitlebar, allowEmpty, cap)
  {
    avoidEmpty = '';
    if (!allowEmpty) {
      avoidEmpty = 'if (document.formThetisBox'+this.id+'.thetisBoxEdit.value == \'\') {return false};';
    }
    var content = "";
    content += "<div class='thetisbox' id='divThetisBox-"+this.id+"' style='position:absolute; z-index:10000; font-size:8pt; display:none;' onkeypress=\"javascript:return ThetisBox.fireDefaultButton(event, '"+this.id+"', 'thetisBoxOK-"+this.id+"')\">";
    var prog = "";
    if (this.progress) {
      prog = " var __thetisBoxProgress=new ThetisBox; __thetisBoxProgress.show('TOP-RIGHT', '', 'PROGRESS', '', '', '');";
    }
    if (this.form_tag.length > 0) {
      var f = this.form_tag;
      f = f.replace("<form", "<form name='formThetisBox"+this.id+"'");
      reObj = new RegExp("onsubmit=\"(.*)( return false;)\"", "i");
      f = f.replace(reObj, "onsubmit=\""+avoidEmpty+" $1 ThetisBox.remove('"+this.id+"'); "+prog+" $2\"");
      content += f;
    } else {
      content += "<form name=\"formThetisBox"+this.id+"\" method=\"get\" action=\""+action+"\" onsubmit=\""+avoidEmpty+prog+" ThetisBox.hide('"+this.id+"'); \">";
    }
    content += "<table class='thetisbox_input_dialog' id='thetisBoxBase-"+this.id+"' width='100%' height='100%' style='border:solid 2px; border-top-color:whitesmoke; border-left-color:whitesmoke; border-bottom-color:dimgray; border-right-color:dimgray; background-color:"+this.bgcolor_body+";' cellspacing='7' cellpadding='0'>";
    if (hasTitlebar) {
      content += "  <tr height='25'>";
      if (this.close_by_icon_button) {
        content += "  <td colspan='2' style='background-color:"+this.bgcolor_title+";'>";
        content += "    <table cellspacing='0' cellpadding='0' width='100%'>";
        content += "      <tr>";
        content += "        <td class='thetisbox_input_title' style='color:white; text-indent:5px;'>";
        content += "          <b>"+this.title+"</b>";
        content += "        </td>";
        content += "        <td align='right' valign='middle' style='padding-right:5px; width:20px;'>";
        content += "          <img src='"+this.button_close_img+"' style='cursor:pointer; vertical-align:middle;' onClick=\"ThetisBox.remove('"+this.id+"');\">";
        content += "        </td>";
        content += "      </tr>";
        content += "    </table>";
        content += "  </td>";
      } else {
        content += "  <td class='thetisbox_input_title' colspan='2' style='color:white; background-color:"+this.bgcolor_title+"; text-indent:5px;'><b>"+this.title+"</b></td>";
      }
      content += "  </tr>";
    }
    content += "  <tr>";
    content += "    <td style='font-size:10pt; cursor:default; padding-left:3px;'>";
    content += "      <div id='thetisBoxCaption-"+this.id+"'>" + cap + "</div>";
    content += "    </td>";
    content += "    <td width='100'>";
    content += "      <table width='100%' style='height:100%;'>";
    content += "        <tr>";
    content += "          <td>";
    content += "            <input type='submit' id='thetisBoxOK-"+this.id+"' value='"+this.button_ok+"' tabindex='2' style='width:90px; height:25px'>";
    content += "          </td>";
    content += "        </tr>";
    content += "        <tr>";
    content += "          <td>";
    content += "            <input type='button' id='thetisBoxCancel-"+this.id+"' value='"+this.button_cancel+"' tabindex='3' style='width:90px; height:25px' onkeypress=\"ThetisBox.remove('"+this.id+"'); return true;\" onClick=\"ThetisBox.remove('"+this.id+"');\">";
    content += "          </td>";
    content += "        </tr>";
    content += "      </table>";
    content += "    </td>";
    content += "  </tr>";
    content += "  <tr>";
    content += "    <td colspan='2'>";
    content += "      <input type='text' id='thetisBoxEdit-"+this.id+"' name='thetisBoxEdit' value='' tabindex='1' style='width:99%'>";
    content += "    </td>";
    content += "  </tr>";
    content += "</table>";
    for (i=0; this.additionalParams != null && i<this.additionalParams.length; i++) {
      var param = this.additionalParams[i].split("=");
      var eqidx = this.additionalParams[i].indexOf("=");
      var val = this.additionalParams[i].substring(eqidx+1);
      content += "<input type='hidden' name='"+param[0]+"' value='"+val+"'>";
    }
    content += "</form>";
    content += "</div>";
    var d = document.createElement("div");
    d.innerHTML = content;
    this.parent_elem.appendChild(d);
  },
  // TEXTAREA
  drawTextArea: function(action, hasTitlebar, allowEmpty, cap)
  {
    avoidEmpty = '';
    if (!allowEmpty) {
      avoidEmpty = 'if (ThetisBox.trim(document.formThetisBox'+this.id+'.thetisBoxEdit.value, true).length <= 0) {return false};';
    }
    var content = "";
    content += "<div class='thetisbox' id='divThetisBox-"+this.id+"' style='position:absolute; z-index:10000; font-size:8pt; display:none;'>";
    var prog = "";
    if (this.progress) {
      prog = " var __thetisBoxProgress=new ThetisBox; __thetisBoxProgress.show('TOP-RIGHT', '', 'PROGRESS', '', '', '');";
    }
    if (this.form_tag.length > 0) {
      var f = this.form_tag;
      f = f.replace("<form", "<form name='formThetisBox"+this.id+"'");
      reObj = new RegExp("onsubmit=\"(.*)( return false;)\"", "i");
      f = f.replace(reObj, "onsubmit=\""+avoidEmpty+" $1 ThetisBox.remove('"+this.id+"'); "+prog+" $2\"");
      content += f;
    } else {
      content += "<form name=\"formThetisBox"+this.id+"\" method=\"get\" action=\""+action+"\" onsubmit=\""+avoidEmpty+prog+" ThetisBox.hide('"+this.id+"'); \">";
    }
    content += "<table class='thetisbox_textarea_dialog' id='thetisBoxBase-"+this.id+"' width='100%' style='height:100%; border:solid 2px; border-top-color:whitesmoke; border-left-color:whitesmoke; border-bottom-color:dimgray; border-right-color:dimgray; background-color:"+this.bgcolor_body+";' cellspacing='7' cellpadding='0'>";
    if (hasTitlebar) {
      content += "  <tr height='25'>";
      if (this.close_by_icon_button) {
        content += "  <td style='background-color:"+this.bgcolor_title+";'>";
        content += "    <table cellspacing='0' cellpadding='0' width='100%'>";
        content += "      <tr>";
        content += "        <td class='thetisbox_textarea_title' style='color:white; text-indent:5px;'>";
        content += "          <b>"+this.title+"</b>";
        content += "        </td>";
        content += "        <td align='right' valign='middle' style='padding-right:5px; width:20px;'>";
        content += "          <img src='"+this.button_close_img+"' style='cursor:pointer; vertical-align:middle;' onClick=\"ThetisBox.remove('"+this.id+"');\">";
        content += "        </td>";
        content += "      </tr>";
        content += "    </table>";
        content += "  </td>";
      } else {
        content += "  <td class='thetisbox_textarea_title' style='color:white; background-color:"+this.bgcolor_title+"; text-indent:5px;'><b>"+this.title+"</b></td>";
      }
      content += "  </tr>";
    }
    if (cap != null && cap.length > 0) {
      content += "  <tr>";
      content += "    <td style='font-size:10pt; cursor:default; padding-left:3px;'>";
      content += "      <div id='thetisBoxCaption-"+this.id+"'>" + cap + "</div>";
      content += "    </td>";
      content += "  </tr>";
    }
    content += "  <tr>";
    content += "    <td>";
    content += "      <textarea id='thetisBoxEdit-"+this.id+"' name='thetisBoxEdit' wrap='off' tabindex='1' style='width:99%; height:170px;'></textarea>";
    content += "    </td>";
    content += "  </tr>";
    content += "  <tr height='40'>";
    content += "    <td>";
    content += "      <table width='10%' border='0' align='center'>";
    content += "        <tr>";
    content += "          <td>";
    content += "            <input type='submit' id='thetisBoxOK-"+this.id+"' value='"+this.button_ok+"' tabindex='2' style='width:90px; height:25px'>";
    content += "          </td>";
    content += "          <td width='30'>&nbsp;</td>";
    content += "          <td>";
    content += "            <input type='button' id='thetisBoxCancel-"+this.id+"' value='"+this.button_cancel+"' tabindex='3' style='width:90px; height:25px' onkeypress=\"ThetisBox.remove('"+this.id+"'); return true;\" onClick=\"ThetisBox.remove('"+this.id+"');\">";
    content += "          </td>";
    content += "        </tr>";
    content += "      </table>";
    content += "    </td>";
    content += "  </tr>";
    content += "</table>";
    for (i=0; this.additionalParams != null && i<this.additionalParams.length; i++) {
      var param = this.additionalParams[i].split("=");
      var eqidx = this.additionalParams[i].indexOf("=");
      var val = this.additionalParams[i].substring(eqidx+1);
      content += "<input type='hidden' name='"+param[0]+"' value='"+val+"'>";
    }
    content += "</form>";
    content += "</div>";
    var d = document.createElement("div");
    d.innerHTML = content;
    this.parent_elem.appendChild(d);
  },
  // TREE
  drawTree: function(action, hasTitlebar, cap)
  {
    var content = "";
    content += "<div class='thetisbox' id='divThetisBox-"+this.id+"' style='position:absolute; z-index:10000; font-size:8pt; display:none;'>";
    var prog = "";
    if (this.progress) {
      prog = " var __thetisBoxProgress=new ThetisBox; __thetisBoxProgress.show('TOP-RIGHT', '', 'PROGRESS', '', '', '');";
    }
    if (this.form_tag.length > 0) {
      var f = this.form_tag;
      f = f.replace("<form", "<form name='formThetisBox"+this.id+"'");
      reObj = new RegExp("onsubmit=\"(.*)( return false;)\"", "i");
      f = f.replace(reObj, "onsubmit=\"if(this.thetisBoxSelKeeper.value.length <= 0 || this.action.length <= 0) { return false }; $1 ThetisBox.remove('"+this.id+"'); "+prog+" $2\"");
      content += f;
    } else {
      content += "<form name=\"formThetisBox"+this.id+"\" method=\"get\" action=\""+action+"\" onsubmit=\"if (this.thetisBoxSelKeeper.value.length <= 0){return false;}"+prog+" ThetisBox.hide('"+this.id+"'); \">";
    }
    content += "<table class='thetisbox_tree_dialog' id='thetisBoxBase-"+this.id+"' width='100%' style='height:100%; border:solid 2px; border-top-color:whitesmoke; border-left-color:whitesmoke; border-bottom-color:dimgray; border-right-color:dimgray; background-color:"+this.bgcolor_body+";' cellspacing='7' cellpadding='0'>";
    if (hasTitlebar) {
      content += "  <tr height='25'>";
      if (this.close_by_icon_button) {
        content += "  <td style='background-color:"+this.bgcolor_title+";'>";
        content += "    <table cellspacing='0' cellpadding='0' width='100%'>";
        content += "      <tr>";
        content += "        <td class='thetisbox_tree_title' style='color:white; text-indent:5px;'>";
        content += "          <b>"+this.title+"</b>";
        content += "        </td>";
        content += "        <td align='right' valign='middle' style='padding-right:5px; width:20px;'>";
        content += "          <img src='"+this.button_close_img+"' style='cursor:pointer; vertical-align:middle;' onClick=\"ThetisBox.remove('"+this.id+"');\">";
        content += "        </td>";
        content += "      </tr>";
        content += "    </table>";
        content += "  </td>";
      } else {
        content += "  <td class='thetisbox_tree_title' style='color:white; background-color:"+this.bgcolor_title+"; text-indent:5px;'><b>"+this.title+"</b></td>";
      }
      content += "  </tr>";
    }
    if (cap != null && cap.length > 0) {
      content += "  <tr>";
      content += "    <td style='font-size:10pt; cursor:default; padding-left:15px;'>";
      content += "      <div id='thetisBoxCaption-"+this.id+"'>" + cap + "</div>";
      content += "    </td>";
      content += "  </tr>";
    }
    content += "  <tr>";
    content += "    <td align='center' valign='top'>";
    content += "      <div id='thetisBoxTree-"+this.id+"' align='left' style='padding-left:10px; padding-top:5px; width:350px; height:280px; overflow:auto; background-color:floralwhite;'></div>";
    content += "    </td>";
    content += "  </tr>";
    content += "  <tr height='40'>";
    content += "    <td valign='top'>";
    content += "      <table width='10%' border='0' align='center'>";
    content += "        <tr>";
    content += "          <td>";
    content += "            <input type='submit' id='thetisBoxOK-"+this.id+"' value='"+this.button_ok+"' tabindex='2' style='width:90px; height:25px'>";
    content += "          </td>";
    content += "          <td width='30'>&nbsp;</td>";
    content += "          <td>";
    content += "            <input type='button' id='thetisBoxCancel-"+this.id+"' value='"+this.button_cancel+"' tabindex='3' style='width:90px; height:25px' onkeypress=\"ThetisBox.remove('"+this.id+"'); return true;\" onClick=\"ThetisBox.remove('"+this.id+"');\">";
    content += "          </td>";
    content += "        </tr>";
    content += "      </table>";
    content += "    </td>";
    content += "  </tr>";
    content += "</table>";
    content += "<input type='hidden' id='thetisBoxSelKeeper-"+this.id+"' name='thetisBoxSelKeeper' value='' />";
    for (i=0; this.additionalParams != null && i<this.additionalParams.length; i++) {
      var param = this.additionalParams[i].split("=");
      var eqidx = this.additionalParams[i].indexOf("=");
      var val = this.additionalParams[i].substring(eqidx+1);
      content += "<input type='hidden' name='"+param[0]+"' value='"+val+"'>";
    }
    content += "</form>";
    if (this.resizable) {
      content += "  <div class=\"thetisbox_resize_handle\" id=\"thetisBoxResizeHandle-"+this.id+"\" style=\"position:absolute; width:20px; height:20px; cursor:move;\"></div>";
    }
    content += "</div>";
    var d = document.createElement("div");
    d.innerHTML = content;
    this.parent_elem.appendChild(d);
  },
  // MINI-TREE
  drawMiniTree: function()
  {
    var content = "";
    content += "<div class='thetisbox' id='divThetisBox-"+this.id+"' style='position:absolute; z-index:10000; font-size:8pt; display:none;'>";
    content += "<table class='thetisbox_minitree_dialog' id='thetisBoxBase-"+this.id+"' width='100%' style='height:100%; border:solid 2px; border-top-color:whitesmoke; border-left-color:whitesmoke; border-bottom-color:dimgray; border-right-color:dimgray; background-color:"+this.bgcolor_body+";' cellspacing='7' cellpadding='0'>";
    content += "  <tr height='25'>";
    content += "    <td style='background-color:"+this.bgcolor_title+";'>";
    content += "      <table cellspacing='0' cellpadding='0' width='100%'>";
    content += "        <tr>";
    content += "          <td class='thetisbox_minitree_title' style='color:white; text-indent:5px;'>";
    content += "            <b>"+this.title+"</b>";
    content += "          </td>";
    content += "          <td align='right' valign='middle' style='padding-right:5px; width:20px;'>";
    content += "            <img src='"+this.button_close_img+"' style='cursor:pointer; vertical-align:middle;' onClick=\"ThetisBox.remove('"+this.id+"');\">";
    content += "          </td>";
    content += "        </tr>";
    content += "      </table>";
    content += "    </td>";
    content += "  </tr>";
    content += "  <tr>";
    content += "    <td align='center' valign='top'>";
    content += "      <div id='thetisBoxTree-"+this.id+"' align='left' style='padding-left:10px; padding-top:5px; width:260px; height:210px; overflow:auto; background-color:floralwhite;'></div>";
    content += "    </td>";
    content += "  </tr>";
    content += "</table>";
    content += "<input type='hidden' id='thetisBoxSelKeeper-"+this.id+"' name='thetisBoxSelKeeper' value='' />";
    for (i=0; this.additionalParams != null && i<this.additionalParams.length; i++) {
      var param = this.additionalParams[i].split("=");
      var eqidx = this.additionalParams[i].indexOf("=");
      var val = this.additionalParams[i].substring(eqidx+1);
      content += "<input type='hidden' name='"+param[0]+"' value='"+val+"'>";
    }
    if (this.resizable) {
      content += "  <div class=\"thetisbox_resize_handle\" id=\"thetisBoxResizeHandle-"+this.id+"\" style=\"position:absolute; width:20px; height:20px; cursor:move;\"></div>";
    }
    content += "</div>";
    var d = document.createElement("div");
    d.innerHTML = content;
    this.parent_elem.appendChild(d);
  },
  // CONFIRM
  drawConfirm: function(ok_act, cancel_act, hasTitlebar, cap)
  {
    var content = "";
    content += "<div class='thetisbox' id='divThetisBox-"+this.id+"' style='position:absolute; z-index:10000; font-size:8pt; display:none;' onkeypress=\"javascript:return ThetisBox.fireDefaultButton(event, '"+this.id+"', 'thetisBoxOK-"+this.id+"')\">";
    content += "<table class='thetisbox_confirm_dialog' id='thetisBoxBase-"+this.id+"' width='100%' style='height:100%; border:solid 2px; border-top-color:whitesmoke; border-left-color:whitesmoke; border-bottom-color:dimgray; border-right-color:dimgray; background-color:"+this.bgcolor_body+";' cellspacing='7' cellpadding='0'>";
    if (hasTitlebar) {
      content += "  <tr height='25'>";
      if (this.close_by_icon_button) {
        content += "  <td style='background-color:"+this.bgcolor_title+";'>";
        content += "    <table cellspacing='0' cellpadding='0' width='100%'>";
        content += "      <tr>";
        content += "        <td class='thetisbox_confirm_title' style='color:white; text-indent:5px;'>";
        content += "          <b>"+this.title+"</b>";
        content += "        </td>";
        content += "        <td align='right' valign='middle' style='padding-right:5px; width:20px;'>";
        content += "          <img src='"+this.button_close_img+"' style='cursor:pointer; vertical-align:middle;' onClick=\"ThetisBox.remove('"+this.id+"');\">";
        content += "        </td>";
        content += "      </tr>";
        content += "    </table>";
        content += "  </td>";
      } else {
        content += "  <td class='thetisbox_confirm_title' style='color:white; background-color:"+this.bgcolor_title+"; text-indent:5px;'><b>"+this.title+"</b></td>";
      }
      content += "  </tr>";
    }
    if (cap != null && cap.length > 0) {
      content += "  <tr>";
      content += "    <td style='font-size:10pt; cursor:default; padding-left:3px;'>";
      content += "      <div id='thetisBoxCaption-"+this.id+"'>" + cap + "</div>";
      content += "    </td>";
      content += "  </tr>";
    }
    content += "  <tr height='40'>";
    content += "    <td width='100%'>";
    content += "      <table width='100%' style='height:100%;'>";
    content += "        <tr>";
    content += "          <td align='right'>";
    content += "            <input type='button' id='thetisBoxOK-"+this.id+"' value='"+this.button_ok+"' onclick=\""+ok_act +"; ThetisBox.remove('"+this.id+"');\" tabindex='2' style='width:90px; height:25px'>";
    content += "          </td>";
    content += "          <td align='left'>";
    content += "            <input type='button' id='thetisBoxCancel-"+this.id+"' value='"+this.button_cancel+"' onclick=\""+cancel_act +"; ThetisBox.remove('"+this.id+"');\" tabindex='3' style='width:90px; height:25px' onkeypress=\"ThetisBox.remove('"+this.id+"'); return true;\" onClick=\"ThetisBox.remove('"+this.id+"');\">";
    content += "          </td>";
    content += "        </tr>";
    content += "      </table>";
    content += "    </td>";
    content += "  </tr>";
    content += "</table>";
    content += "</div>";
    var d = document.createElement("div");
    d.innerHTML = content;
    this.parent_elem.appendChild(d);
  },
  // MESSAGE
  drawMessage: function(hasTitlebar, cap)
  {
    var content = "";
    content += "<div class='thetisbox' id='divThetisBox-"+this.id+"' style='position:absolute; z-index:10000; font-size:8pt; display:none;' onkeypress=\"javascript:return ThetisBox.fireDefaultButton(event, '"+this.id+"', 'thetisBoxOK-"+this.id+"')\">";
    content += "<table class='thetisbox_message_dialog' id='thetisBoxBase-"+this.id+"' width='100%' style='height:100%; border:solid 2px; border-top-color:whitesmoke; border-left-color:whitesmoke; border-bottom-color:dimgray; border-right-color:dimgray; background-color:"+this.bgcolor_body+";' cellspacing='7' cellpadding='0'>";
    if (hasTitlebar) {
      content += "  <tr height='25'>";
      if (this.close_by_icon_button) {
        content += "  <td style='background-color:"+this.bgcolor_title+";'>";
        content += "    <table cellspacing='0' cellpadding='0' width='100%'>";
        content += "      <tr>";
        content += "        <td class='thetisbox_message_title' style='color:white; text-indent:5px;'>";
        content += "          <b>"+this.title+"</b>";
        content += "        </td>";
        content += "        <td align='right' valign='middle' style='padding-right:5px; width:20px;'>";
        content += "          <img src='"+this.button_close_img+"' style='cursor:pointer; vertical-align:middle;' onClick=\"ThetisBox.remove('"+this.id+"');\">";
        content += "        </td>";
        content += "      </tr>";
        content += "    </table>";
        content += "  </td>";
      } else {
        content += "  <td class='thetisbox_message_title' style='color:white; background-color:"+this.bgcolor_title+"; text-indent:5px;'><b>"+this.title+"</b></td>";
      }
      content += "  </tr>";
    }
    if (cap != null && cap.length > 0) {
      content += "  <tr>";
      content += "    <td style='font-size:10pt; cursor:default; padding-left:3px;'>";
      content += "      <div id='thetisBoxCaption-"+this.id+"'>" + cap + "</div>";
      content += "    </td>";
      content += "  </tr>";
    }
//    if (!this.close_by_icon_button) {
      content += "  <tr height='40'>";
      content += "    <td width='100%' align='center'>";
      content += "      <table width='100%' style='height:100%;' align='center'>";
      content += "        <tr>";
      content += "          <td align='center'>";
      content += "            <input type='button' id='thetisBoxOK-"+this.id+"' value='"+this.button_ok+"' tabindex='2' style='width:90px; height:25px' onClick=\"ThetisBox.remove('"+this.id+"');\">";
      content += "          </td>";
      content += "        </tr>";
      content += "      </table>";
      content += "    </td>";
      content += "  </tr>";
//    }
    content += "</table>";
    content += "</div>";
    var d = document.createElement("div");
    d.innerHTML = content;
    this.parent_elem.appendChild(d);
  },
  // PROGRESS
  drawProgress: function(hasTitlebar, cap)
  {
    var content = "";
    content += "<div class='thetisbox' id='divThetisBox-"+this.id+"' style='position:absolute; z-index:10000; font-size:8pt; display:none;' onkeypress=\"javascript:return ThetisBox.fireDefaultButton(event, '"+this.id+"', 'thetisBoxOK-"+this.id+"')\">";
    content += "<table class='thetisbox_progress_dialog' id='thetisBoxBase-"+this.id+"' width='100%' style='height:100%; border:solid 2px; border-top-color:whitesmoke; border-left-color:whitesmoke; border-bottom-color:dimgray; border-right-color:dimgray; background-color:"+this.bgcolor_body+";' cellspacing='7' cellpadding='0'>";
    if (hasTitlebar) {
      content += "  <tr height='25'>";
      content += "    <td class='thetisbox_progress_title' style='color:white; background-color:"+this.bgcolor_title+"; text-indent:5px;'><b>"+this.title+"</b></td>";
      content += "  </tr>";
    }
    if (cap != null && cap.length > 0) {
      content += "  <tr>";
      content += "    <td align='center' style='font-size:10pt; cursor:default; padding-left:3px;'>";
      content += "      <div id='thetisBoxCaption-"+this.id+"'>" + cap + "</div>";
      content += "    </td>";
      content += "  </tr>";
    }
    content += "  <tr>";
    content += "    <td align='center' style='cursor:default;'>";
    content += "      <table cellpadding='0' cellspacing='2' align='center' style='border:solid limegreen 1px;padding:0px;background-color:#fff'>";
    content += "        <tr>";
    for (i=1; i<=20; i++) {
      content += "          <td width=10 height=16 id='thetisBoxProgress-"+this.id+"_"+i+"'>&nbsp;</td>";
    }
    content += "        </tr>";
    content += "      </table>";
    content += "    </td>";
    content += "  </tr>";
    content += "</table>";
    content += "</div>";
    var d = document.createElement("div");
    d.innerHTML = content;
    this.parent_elem.appendChild(d);

    var progressor = new ThetisBoxProgressor(this.id);
    ThetisBoxProgressors.push(progressor);
    progressor.update();
  },
  // TIPS
  drawTips: function(hasTitlebar, cap)
  {
    var content = "";
    content += "<div class='thetisbox' id='divThetisBox-"+this.id+"' style='position:absolute; z-index:10000; font-size:8pt; display:none;' onkeypress=\"javascript:return ThetisBox.fireDefaultButton(event, '"+this.id+"', 'thetisBoxOK-"+this.id+"')\">";
    content += "<table class='thetisbox_tips_dialog' id='thetisBoxBase-"+this.id+"' width='100%' style='height:100%; border:solid 2px; border-top-color:whitesmoke; border-left-color:whitesmoke; border-bottom-color:dimgray; border-right-color:dimgray; background-color:"+this.bgcolor_body+";' cellspacing='7' cellpadding='0'>";
    if (hasTitlebar) {
      content += "  <tr height='25'>";
      content += "    <td class='thetisbox_tips_title' style='color:white; background-color:"+this.bgcolor_title+"; text-indent:5px;'><b>"+this.title+"</b></td>";
      content += "  </tr>";
    }
    content += "  <tr>";
    content += "    <td align='left' style='font-size:10.5pt; cursor:move; padding-left:20px; padding-right:20px;'>";
    content += "      <div id='thetisBoxCaption-"+this.id+"'>" + cap + "</div>";
    content += "    </td>";
    content += "  </tr>";
    content += "</table>";
    content += "</div>";
    var d = document.createElement("div");
    d.innerHTML = content;
    this.parent_elem.appendChild(d);

    setTimeout("ThetisBox.remove("+this.id+");", 4000)
  },
  // IFRAME
  drawIFrame: function(hasTitlebar, src, cap)
  {
    var content = "";
    content += "<div class='thetisbox' id='divThetisBox-"+this.id+"' style='position:absolute; z-index:10000; font-size:8pt; display:none;' onkeypress=\"javascript:return ThetisBox.fireDefaultButton(event, '"+this.id+"', 'thetisBoxClose-"+this.id+"')\">";
    content += "<table class='thetisbox_iframe_dialog' id='thetisBoxBase-"+this.id+"' style='width:100%; border:solid 2px; border-top-color:whitesmoke; border-left-color:whitesmoke; border-bottom-color:dimgray; border-right-color:dimgray; background-color:"+this.bgcolor_body+";' cellspacing='10' cellpadding='0'>";
    if (hasTitlebar) {
      content += "  <tr>";
      if (this.button_close_img == null) {
        content += "  <td class='thetisbox_iframe_title' colspan='2' style='color:white; background-color:"+this.bgcolor_title+"; text-indent:5px;'>";
        content += "    <b>"+this.title+"</b>";
        content += "  </td>";
      } else {
        content += "  <td colspan='2' style='background-color:"+this.bgcolor_title+";'>";
        content += "    <table cellspacing='0' cellpadding='0' width='100%'>";
        content += "      <tr>";
        content += "        <td class='thetisbox_iframe_title' style='color:white; text-indent:5px;'>";
        content += "          <b>"+this.title+"</b>";
        content += "        </td>";
        content += "        <td align='right' valign='middle' style='padding-right:5px; width:20px;'>";
        content += "          <img src='"+this.button_close_img+"' style='cursor:pointer; vertical-align:middle;' onClick=\"ThetisBox.remove('"+this.id+"');\">";
        content += "        </td>";
        content += "      </tr>";
        content += "    </table>";
        content += "  </td>";
      }
      content += "  </tr>";
    }
    if (cap != null && cap.length > 0) {
      content += "  <tr>";
      content += "    <td width='95%' style='font-size:10pt; cursor:default; padding-left:3px;'>";
      content += "      <div id='thetisBoxCaption-"+this.id+"'>" + cap + "</div>";
      content += "    </td>";
      content += "    <td width='100' align='center'>";
      if (this.button_close_img == null) {
        content += "      <table width='100%' style='height:100%;' align='center'>";
        content += "        <tr>";
        content += "          <td align='center'>";
        content += "            <input type='button' id='thetisBoxClose-"+this.id+"' value='"+this.button_close+"' tabindex='2' style='width:90px; height:25px' onClick=\"ThetisBox.remove('"+this.id+"');\">";
        content += "          </td>";
        content += "        </tr>";
        content += "      </table>";
      }
      content += "    </td>";
      content += "  </tr>";
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
    content += "  <tr>";
    content += "    <td colspan='2' align='center'>";
    content += "      <iframe id='thetisBoxContent-"+this.id+"' src='"+src+"' width='100%' "+frameborder+" style='height:240px; "+border_style+" background-color:white;'></iframe>";
    content += "    </td>";
    content += "  </tr>";
    content += "</table>";
    if (this.resizable) {
      content += "  <div class=\"thetisbox_resize_handle\" id=\"thetisBoxResizeHandle-"+this.id+"\" style=\"position:absolute; width:20px; height:20px; cursor:move;\"></div>";
    }
    content += "</div>";
    var d = document.createElement('div');
    d.innerHTML = content;
    this.parent_elem.appendChild(d);
  },
  // TRAY
  drawTray: function(hasTitlebar, cap)
  {
    var content = "";
    content += "<div class='thetisbox' id='divThetisBox-"+this.id+"' style='position:absolute; z-index:10000; font-size:8pt; display:none;' onkeypress=\"javascript:return ThetisBox.fireDefaultButton(event, '"+this.id+"', 'thetisBoxClose-"+this.id+"')\">";
    content += "<table class='thetisbox_tray_dialog' id='thetisBoxBase-"+this.id+"' style='width:100%; border:solid 2px; border-top-color:whitesmoke; border-left-color:whitesmoke; border-bottom-color:dimgray; border-right-color:dimgray; background-color:"+this.bgcolor_body+";' cellspacing='7' cellpadding='0'>";
    if (hasTitlebar) {
      content += "  <tr height='25'>";
      if (this.button_close_img == null) {
        content += "  <td class='thetisbox_tray_title' colspan='2' style='color:white; background-color:"+this.bgcolor_title+"; text-indent:5px;'>";
        content += "    <b>"+this.title+"</b>";
        content += "  </td>";
      } else {
        content += "  <td colspan='2' style='background-color:"+this.bgcolor_title+";'>";
        content += "    <table cellspacing='0' cellpadding='0' width='100%'>";
        content += "      <tr>";
        content += "        <td class='thetisbox_tray_title' style='color:white; text-indent:5px;'>";
        content += "          <b>"+this.title+"</b>";
        content += "        </td>";
        content += "        <td align='right' valign='middle' style='padding-right:5px; width:20px;'>";
        content += "          <img src='"+this.button_close_img+"' style='cursor:pointer; vertical-align:middle;' onClick=\"ThetisBox.remove('"+this.id+"');\">";
        content += "        </td>";
        content += "      </tr>";
        content += "    </table>";
        content += "  </td>";
      }
      content += "  </tr>";
    }
    if (cap != null && cap.length > 0) {
      content += "  <tr>";
      content += "    <td width='95%' style='font-size:10pt; cursor:default; padding-left:3px;'>";
      content += "      <div id='thetisBoxCaption-"+this.id+"'>" + cap + "</div>";
      content += "    </td>";
      if (this.button_close_img == null) {
        content += "    <td width='100' align='center'>";
        content += "      <table width='100%' style='height:100%;' align='center'>";
        content += "        <tr>";
        content += "          <td align='center'>";
        content += "            <input type='button' id='thetisBoxClose-"+this.id+"' value='"+this.button_close+"' tabindex='2' style='width:90px; height:25px' onClick=\"ThetisBox.remove('"+this.id+"');\">";
        content += "          </td>";
        content += "        </tr>";
        content += "      </table>";
        content += "    </td>";
      }
      content += "  </tr>";
    }
    content += "  <tr>";
    content += "    <td colspan='2' align='center'>";
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
    content += "      <div id='thetisBoxContent-"+this.id+"' width='100%' style='"+border_style+" background-color:"+bgcolor+"; overflow:"+this.overflow+";'></div>";
    content += "    </td>";
    content += "  </tr>";
    content += "</table>";
    if (this.resizable) {
      content += "  <div class=\"thetisbox_resize_handle\" id=\"thetisBoxResizeHandle-"+this.id+"\" style=\"position:absolute; width:20px; height:20px; cursor:move;\"></div>";
    }
    content += "</div>";
    var d = document.createElement('div');
    d.innerHTML = content;
    this.parent_elem.appendChild(d);
  },
  // Show
  show: function(p_position, p_size, p_type, p_action, p_caption, p_def)
  {
    this.box_type = p_type;

    this.button_ok = __thetisbox_OK;
    this.button_cancel = __thetisbox_Cancel;
    this.button_close = __thetisbox_Close;
    this.button_close_img = __thetisbox_close_img;

    if (!this.parent_elem) {
      this.parent_elem = document.body;
    }

    if (p_type == "INPUT") {
      if (this.bgcolor_title == null) this.bgcolor_title = "fuchsia";
      if (this.bgcolor_body == null) this.bgcolor_body = "peachpuff";
      this.drawInput(p_action, true, false, p_caption);

    } else if (p_type == "TEXTAREA") {
      if (this.bgcolor_title == null) this.bgcolor_title = "dodgerblue";
      if (this.bgcolor_body == null) this.bgcolor_body = "skyblue";
      this.drawTextArea(p_action, true, false, p_caption);

    } else if (p_type == "TREE" || p_type == "MINI-TREE") {
      if (this.resizable == null) {
        this.resizable = true;
      }
      if (this.bgcolor_title == null) this.bgcolor_title = "darkgoldenrod";
      if (this.bgcolor_body == null) this.bgcolor_body = "moccasin";
      if (p_type == "TREE") {
        this.drawTree(p_action, true, p_caption);
      } else {
        this.drawMiniTree();
      }

    } else if (p_type == "CONFIRM") {
      if (this.bgcolor_title == null) this.bgcolor_title = "fuchsia";
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
      this.drawConfirm(ok_act, cancel_act, true, p_caption);

    } else if (p_type == "MESSAGE") {
      if (this.bgcolor_title == null) this.bgcolor_title = "fuchsia";
      if (this.bgcolor_body == null) this.bgcolor_body = "peachpuff";
      this.drawMessage(true, p_caption);

    } else if (p_type == "PROGRESS") {
      if (this.bgcolor_title == null) this.bgcolor_title = "fuchsia";
      if (this.bgcolor_body == null) this.bgcolor_body = "palegreen";
      this.drawProgress(false, p_caption);

    } else if (p_type == "TIPS") {
      if (this.bgcolor_title == null) this.bgcolor_title = "fuchsia";
      if (this.bgcolor_body == null) this.bgcolor_body = "yellow";
      this.drawTips(false, p_caption);

    } else if (p_type == "IFRAME") {
      if (this.bgcolor_title == null) this.bgcolor_title = "royalblue";
      if (this.bgcolor_body == null) this.bgcolor_body = "#7FD6FF";   // "skyblue"
      this.drawIFrame(true, p_def, p_caption);

    } else if (p_type == "TRAY") {
      if (this.bgcolor_title == null) this.bgcolor_title = "royalblue";
      if (this.bgcolor_body == null) this.bgcolor_body = "#7FD6FF";   // "skyblue"
      this.drawTray(true, p_caption);
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
    if (size.length >= 2) {
      if (parseInt(size[0]) > 0) {
        width = parseInt(size[0]);
      }
      height = parseInt(size[1]);
    }

    if (width > 0) {
      box.style.width = width + "px";
      box.style.minWidth = width + "px";
    } else {
      width = 350;
    }
    if (height > 0) {
      box.style.height = height + "px";

      var chg_h = content;
      if (chg_h != null) {
        var cap_height = 0;
        if (cap != null) {
          box.style.display = "inline";   // to get cap_height
          cap_height = cap.offsetHeight + 8;
        }
        var h = height - cap_height - 56;
        if (h < 0) {
          h = 0;
        }
        chg_h.style.height = h + "px";
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
        case "TIPS":
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
          x = bodyScroll.left + clientRegion.width - width;
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
    box.style.visibility = "visible";
    box.style.display = "inline";

    // DRAG BY PROTOTYPE.JS >>>
    var resizeHandle = _z("thetisBoxResizeHandle-" + this.id);
    if (resizeHandle) {
      var base = this.getBase();
      resizeHandle.style.left = (base.offsetWidth - resizeHandle.offsetWidth) + "px";
      resizeHandle.style.top = (base.offsetHeight - resizeHandle.offsetHeight) + "px";
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

    this.defaultFired = false;
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
  // Form Tag
  setFormTag: function(f)
  {
    this.form_tag = f;
  },
  // Additional Parameters
  setAdditionalParams: function(params)
  {
    this.additionalParams = params;
  },
  // Tree
  buildTree: function(parentTreeId, array)
  {
    return ThetisBox.buildTree(parentTreeId, array, "document.formThetisBox"+this.id, "thetisBoxTree-"+this.id, "thetisBoxSelKeeper-"+this.id, this.folderImg);
  },
  selectTree: function(menuId)
  {
    ThetisBox.selectTree("thetisBoxSelKeeper-"+this.id, "a_thetisBoxTree-"+this.id+":"+menuId, "document.formThetisBox"+this.id);
  },
  getTreeSelect: function()
  {
    return ThetisBox.getTreeSelect(this.id);
  },
  setTree: function(url, selectId, onComplete)
  {
    var d = document.createElement("div");
    d.innerHTML = "<form method='get' name='form_ajax_thetisBoxTree'>"
        + "<input type='hidden' name='rootDiv' value='thetisBoxTree-"+this.id+"' />"
        + "<input type='hidden' name='selKeeper' value='thetisBoxSelKeeper-"+this.id+"' />"
        + "<input type='hidden' name='selId' value='a_thetisBoxTree-"+this.id+":"+selectId+"' />"
        + "</form>";
    this.parent_elem.appendChild(d);

    var thetisBox = new ThetisBox;
    thetisBox.show("CENTER", "", "PROGRESS", "", "", "");
    var updater = new Ajax.Updater(
                            "thetisBoxTree-"+this.id,
                            url,
                            {
                              method:"get",
                              parameters: Form.serialize(document.form_ajax_thetisBoxTree),
                              asynchronous: true,
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
  onMouseDown: function(e)
  {
    var id = this.id.split("-")[1];

    // Excluded Control Area
    var excludeArray = new Array(
        "thetisBoxOK-"+id,
        "thetisBoxCancel-"+id,
        "thetisBoxClose-"+id,
        "thetisBoxEdit-"+id,
        "thetisBoxTree-"+id,
        "thetisBoxContent-"+id
      );

    var bodyScroll = ThetisBox.getBodyScroll();

    for (var i=0; i < excludeArray.length; i++) {
      var excludeCtrl = _z(excludeArray[i]);
      if (excludeCtrl == null) {
        //alert(excludeArray[i] + "is null!!");
        continue;
      }
      var isWithin = false;
      if (document.all) {
         isWithin = Position.within(excludeCtrl, bodyScroll.left+event.clientX, bodyScroll.top+event.clientY);
      } else if (document.getElementById) {
         isWithin = Position.within(excludeCtrl, bodyScroll.left+e.clientX, bodyScroll.top+e.clientY);
      }
        if (isWithin == true) {
        return true;
      }
    }

    // Starting to Drag
    this.selected = true;
    if (document.all) {
      this.offsetX = event.clientX + bodyScroll.left - parseInt(this.style.left);
      this.offsetY = event.clientY + bodyScroll.top - parseInt(this.style.top);
    } else if (document.getElementById) {
      this.offsetX = e.pageX - parseInt(this.style.left);
      this.offsetY = e.pageY - parseInt(this.style.top);
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
  box_type: null,
  close_by_icon_button: true,
  defaultFired: false,
  offsetX: 0,
  offsetY: 0,
  additionalParams: null,
  title: __thetisbox_title,
  button_ok: __thetisbox_OK,
  button_cancel: __thetisbox_Cancel,
  button_close: __thetisbox_Close,
  button_close_img: __thetisbox_close_img,
  form_tag: "",
  bgcolor_title: null,
  bgcolor_body: null,
  bgcolor_content: null,
  border_content: null,
  resizable: null,
  progress: false,
  overflow: "auto",
  parent_elem: null,
  addChildBox: function(childBox) {
    if (!this.child_boxes) {
      this.child_boxes = new Array();
    }
    this.child_boxes.push(childBox);
  },
  child_boxes: null
});

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
  for (var i=0; i < ThetisBox.array.length; i++) {
    var instance = ThetisBox.array[i];
    if (instance.id == id) {
      return instance;
    }
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

  var ary = ThetisBoxEventHandlers;
  var onClose = null;
  for (var i=0; i < ary.length; i++) {
    if (ary[i][0] == id) {
      onClose = ary[i][1];
      ary.splice(i, 1);
      break;
    }
  }

  ary = ThetisBoxProgressors;
  for (var i=0; i < ary.length; i++) {
    if (ary[i].id == id) {
      ary.splice(i, 1);
      break;
    }
  }

  box.style.display = "none";
  box.parentNode.removeChild(box);

  if (onClose != null) {
    setTimeout(onClose, 0);
  }
}

ThetisBox.isAlive = function()
{
  return (_z("divThetisBox-"+id) != null);
}

ThetisBox.clear = function(box_type)
{
  for (var i=__thetisbox_id; i >= 0; i--) {
    if (box_type) {
      var instance = ThetisBox.getInstance(i);
      if (!instance || instance.box_type != box_type) {
        continue;
      }
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

ThetisBox.setOnClose = function(id, func)
{
  var ary = ThetisBoxEventHandlers;
  for (var i=0; i < ary.length; i++) {
    if (ary[i][0] == id) {
      ary.splice(i, 1);
    }
  }
  ary.push(new Array(id, func));
}

// Default Buttons
ThetisBox.fireDefaultButton = function(event, id, target)
{
  var box = _z("divThetisBox-"+id);

  if (event.keyCode == 13) {    // [Enter]
    if (box.defaultFired) {
      return false;
    } else {
      var defaultButton = _z(target);

      if (defaultButton != null && defaultButton.click != "undefined") {
        box.defaultFired = true;
        defaultButton.click();
        event.cancelBubble = true;
        return false;
      }
    }
  } else if (event.keyCode == 27) {  // [ESC]
    if (!box.defaultFired) {
      ThetisBox.remove(id);
    }
  }
  return true;
}

var ThetisBoxEventHandlers = new Array();

/**----------------**----------------**----------------**----------------**/

var ThetisBoxProgressors = new Array();

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

  content = "<form name='form_span'>";
  content += "<table align='center' valign='top' width='100%' style='height:180px' cellspacing='0' cellpadding='0'>";
  content += "  <tr style='height:70px;'>";
  content += "    <td align='center' valign='middle'>";

  content += "      <select name='start_hour'>";
  for (var i=0; i<hours.length; i++) {
    var selected = "";
    if (start_hour == hours[i]) {
      selected = "selected";
    }
    content += "        <option value='" + hours[i] + "' " + selected + ">" + hours[i] + "</option>";
  }
  content += "      </select>";
  content += "      <select name='start_min'>";
  for (var i=0; i<mins.length; i++) {
    var selected = "";
    if (start_min == mins[i]) {
      selected = "selected";
    }
    content += "        <option value='" + mins[i] + "' " + selected + ">" + ((mins[i]<10)?('0'+mins[i]):mins[i]) + "</option>";
  }
  content += "      </select>";
  content += " ~ ";
  content += "      <select name='end_hour'>";
  var selected = "";
  for (var i=0; i<hours.length; i++) {
    var selected = "";
    if (end_hour == hours[i]) {
      selected = "selected";
    }
    content += "        <option value='" + hours[i] + "' " + selected + ">" + hours[i] + "</option>";
  }
  content += "      </select>";
  content += "      <select name='end_min'>";
  for (var i=0; i<mins.length; i++) {
    var selected = "";
    if (end_min == mins[i]) {
      selected = "selected";
    }
    content += "        <option value='" + mins[i] + "' " + selected + ">" + ((mins[i]<10)?('0'+mins[i]):mins[i]) + "</option>";
  }
  content += "      </select>";

  content += "    </td>";
  content += "  </tr>";
  content += "  <tr>";
  content += "    <td align='center' valign='top'>";
  content += "      <input type='button' value='"+__thetisbox_OK+"' onclick='"+onOk+"' style='width:80px' />";
  content += "      &nbsp;<input type='button' value='"+__thetisbox_Cancel+"' onclick='"+onCancel+"' style='width:80px' />";
  content += "    </td>";
  content += "  </tr>";
  content += "  <tr height='100%'>";
  content += "    <td></td>";
  content += "  </tr>";
  content += "</table>";
  if (org_start) {
    content += "<input type='hidden' name='org_start' value='"+org_start+"' />";
  }
  if (org_end) {
    content += "<input type='hidden' name='org_end' value='"+org_end+"' />";
  }
  content += "</form>";
  return content;
}

/**----------------**----------------**----------------**----------------**/

ThetisBox.buildTree = function(parentTreeId, array, frm, rootDiv, selKeeperId, folderImg, open)
{
  var parent = null;
  if (parentTreeId == "") {
    parent = _z(rootDiv);
  } else {
    parent = _z(rootDiv+":"+parentTreeId);
    if (parent == null) {
      alert("No parentTree found! "+parentTreeId);
      return null;
    }
  }

  var firstMenuId = null;
  for (var i=0; i < array.length; i++) {

    var div_id = rootDiv + ":" + array[i][0]

    var base = document.createElement("div");
    base.id = "base_" + div_id;

    var appName = window.navigator.appName;
    var is_MS = (appName.toLowerCase().indexOf('explorer') >= 0); // MSIE, Sleipnir
    var is_dtdStandard = (document.compatMode == 'CSS1Compat');

    if (is_MS) {
      if (is_dtdStandard) {
        base.style.padding = "0px";
        base.style.display = "inline";
      } else {
        base.style.padding = "0px";
        base.style.paddingTop = "2px";
        base.style.paddingBottom = "2px";
        base.style.display = "block";
      }
    } else {
      base.style.padding = "0px";
      base.style.display = "block";
    }
    base.noWrap = true;
    parent.appendChild(base);

    var menu = document.createElement("a");
    menu.id = ThetisBox.getMenuIdFromDivId(div_id);
    if (firstMenuId == null) {
      firstMenuId = menu.id;
    }
    base.appendChild(menu);
    base.appendChild(document.createElement("br"));

    menu.innerHTML = "";
    if (folderImg != null) {
      if (ThetisBox.isArray(folderImg) && folderImg.length > 0) {
        try {
          var display_open = "";
          var display_close = "display:none;";
          if (open == false) {
            display_open = "display:none;";
            display_close = "";
          }
          menu.innerHTML += "<img id='"+div_id+"_open' src='"+folderImg[array[i][4]][0]+"' border='0' style='vertical-align:middle;"+display_open+"'>";
          menu.innerHTML += "<img id='"+div_id+"_close' src='"+folderImg[array[i][4]][1]+"' border='0' style='vertical-align:middle;"+display_close+"'>";
          menu.innerHTML += " ";
        } catch (e) {}
      } else if (folderImg != "") {
        menu.innerHTML += "<img src='"+folderImg+"' border='0' style='vertical-align:middle;'>";
        menu.innerHTML += " ";
      }
    }
    menu.innerHTML += "<span id='"+div_id+"_name'>"+array[i][1]+"</span>";
    menu.value = array[i][2];  // action
    var onclick = "";
    if (array[i].length > 3) {
      onclick = array[i][3];
    }
    if (menu.value == "") {    // Folder
      var d = document.createElement("div");
      d.id = div_id;
      d.className = "thetisBoxTreeBlock";
      d.style.paddingLeft = "30px";
      d.style.borderLeft = "1px dotted navy";
      if (open == false) {
        d.style.display = "none";
      }
      base.appendChild(d);

      menu.href = "javaScript:"+onclick+" var selKeeper=_z('"+selKeeperId+"'); if (selKeeper != null) { if (selKeeper.value == '"+menu.id+"') { ThetisBox.toggleTree('"+d.id+"'); } else { ThetisBox.openTree('"+d.id+"', true); } ThetisBox.selectTree('"+selKeeperId+"', '"+menu.id+"', "+frm+"); }";

    } else {
      menu.href = "javaScript:"+onclick+" var selKeeper=_z('"+selKeeperId+"'); if (selKeeper != null) { ThetisBox.selectTree('"+selKeeperId+"', '"+menu.id+"', "+frm+"); }";
    }
  }
  return firstMenuId;
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

ThetisBox.toggleTree = function(divId)
{
  var tree = document.getElementById(divId);
  if (tree == null) {
    return;
  }

  ThetisBox._openTree(tree, (tree.style.display == "none"));
}

ThetisBox.openTree = function(divId, open)
{
  var tree = document.getElementById(divId);
  if (tree == null) {
    return;
  }
  ThetisBox._openTree(tree, open);
}

ThetisBox._openTree = function(tree, open)
{
  var openImg = document.getElementById(tree.id + "_open");
  var closeImg = document.getElementById(tree.id + "_close");

  if (open == true) {
    tree.style.display = "block";
    if (openImg != null) {
      openImg.style.display = "inline";
    }
    if (closeImg != null) {
      closeImg.style.display = "none";
    }
  } else {
    tree.style.display = "none";
    if (openImg != null) {
      openImg.style.display = "none";
    }
    if (closeImg != null) {
      closeImg.style.display = "inline";
    }
  }
}

ThetisBox.selectTree = function(selKeeperId, menuId, frm, forceOpen)
{
  var lastSelected = _z(selKeeperId).value;
  if (lastSelected != "") {
    _z(lastSelected).style.backgroundColor = "";
  }
  var menuItem = _z(menuId);
  if (menuItem == null) {
    return;
  }
  var action = menuItem.value;
  if (action != null && action.length > 0) {
    menuItem.style.backgroundColor = "magenta";
  } else {
    menuItem.style.backgroundColor = "aquamarine";
  }
  _z(selKeeperId).value = menuId;

  if (forceOpen == true)
  {
    var e = menuItem;
    ThetisBox.openTree(ThetisBox.getDivIdFromMenuId(menuId), true);

    while (e = e.parentNode) {
      if (e.className == "thetisBoxTreeBlock") {
        ThetisBox.openTree(e.id, true);
      }
    }
  }

  if (frm != null && action != null) {
    frm.action = action;
  }
}

ThetisBox.isSelectedTree = function(selKeeperId, menuId)
{
  return (_z(selKeeperId).value == menuId);
}

ThetisBox.getDivIdFromMenuId = function(menuId)
{
  return menuId.substring(2, menuId.length);
}

ThetisBox.getMenuIdFromDivId = function(divId)
{
  return "a_" + divId;
}

ThetisBox.getTreeSelect = function(id)
{
  var selKeeper = _z("thetisBoxSelKeeper-"+id);
  if (selKeeper == null) {
    return null;
  }
  var val = selKeeper.value;
  if (val == null) {
    return null;
  }
  var tokens = val.split(":");
  return tokens[tokens.length-1];
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
  obj.width = window.innerWidth;
  obj.height = window.innerHeight;

  if (isNaN(obj.width))  {
    obj.width = document.documentElement.clientWidth;
    if ((isNaN(obj.width) || obj.width == 0) && document.body != null)  {
      obj.width = document.body.clientWidth;
    }
  }
  if (isNaN(obj.height))  {
    obj.height = document.documentElement.clientHeight;
    if ((isNaN(obj.height) || obj.height == 0) && document.body != null)  {
      obj.height = document.body.clientHeight;
    }
  }
  return obj;
}
