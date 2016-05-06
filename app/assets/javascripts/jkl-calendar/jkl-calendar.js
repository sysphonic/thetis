//  ========================================================
//  jkl-calendar.js
//  Copyright 2005-2006 Kawasaki Yusuke <u-suke [at] kawa.net>
//  Thanks to 2tak <info [at] code-hour.com>
//  http://www.kawa.net/works/js/jkl/calender.html
//  ========================================================

if (typeof(JKL) == "undefined") JKL = function() {};

JKL.Calendar = function (dispId, textId)
{
    this.func = null;
    this.disp_id = dispId;
    this.text_id = textId;

    this.__textelem = null;
    this.__dispelem = null;
    this.__opaciobj = null;
    this.style = new JKL.Calendar.Style();

    JKL.Calendar.cal_h[this.disp_id] = this;

    var textElem = this.getTextElem();
    if (textElem) {
      this.addEvent(textElem, "keydown",
                      function(evt) {
                        evt = evt || window.event;
                        if (evt.keyCode == 13) {
                          var elem = evt.target || evt.srcElement;
                          if (elem.onclick) {
                            elem.onclick();
                          }
                          evt.cancelBubble = true;
                          evt.returnValue = false;
                        }
                        return false;
                      }
                      );
    }
    return this;
};

JKL.Calendar.holidays = null;
JKL.Calendar.setHolidays = function(arr)
{
  JKL.Calendar.holidays = arr;
}

JKL.Calendar.prototype.setFunc = function(f)
{
  this.func = f;
}

JKL.Calendar.wdayNames = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"];
JKL.Calendar.setWdayNames = function(arr)
{
  JKL.Calendar.wdayNames = arr;
}

JKL.Calendar.monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
JKL.Calendar.setMonthNames = function(arr) {
  JKL.Calendar.monthNames = arr;
}

JKL.Calendar.captions = ["Prev.", "Move to the current month", "Next", "Close", "Clear"];
JKL.Calendar.setCaptions = function(arr)
{
  JKL.Calendar.captions = arr;
}

JKL.Calendar.buttons = {};
JKL.Calendar.setButtons = function(hash) {
  JKL.Calendar.buttons = hash;
}

JKL.Calendar.VERSION = "0.13";

JKL.Calendar.prototype.spliter = "-";
JKL.Calendar.prototype.date = null;
JKL.Calendar.prototype.min_date = null;
JKL.Calendar.prototype.max_date = null;
JKL.Calendar.prototype.start_wday = 0;
JKL.Calendar.prototype.draw_border = true;

JKL.Calendar.prototype.selectable_wdays = [true, true, true, true, true, true, true];
JKL.Calendar.prototype.zindex = 30000;
JKL.Calendar.prototype.show_clear = false;

JKL.Calendar.cal_h = [];
JKL.Calendar.restoreFocus = function(dispId)
{
  var cal_obj = JKL.Calendar.cal_h[dispId];
  if (cal_obj && cal_obj.is_set_blur) {
    var textElem = cal_obj.getTextElem();
    if (textElem) {
      try {
        textElem.focus();
      } catch (e) {
      }
    }
  }
}
JKL.Calendar.clear_blur_timer = function(dispId)
{
  if (JKL.Calendar.cal_h[dispId]) {
    JKL.Calendar.cal_h[dispId].clear_blur_timer(true);
  }
}
JKL.Calendar.prototype.is_set_blur = false;
JKL.Calendar.prototype.blur_timer_id = null;
JKL.Calendar.prototype.set_blur_timer = function()
{
  if (this.blur_timer_id == "xxxx") { // Prohibitted
    this.blur_timer_id = null;
  } else {
    this.blur_timer_id = setTimeout("JKL.Calendar.on_blur_timer(\""+this.disp_id+"\");", 200);
  }
}

JKL.Calendar.on_blur_timer = function(dispId)
{
  var cal_obj = JKL.Calendar.cal_h[dispId];

  if (cal_obj && !cal_obj.blur_timer_id) {
    return;
  }

  if (cal_obj) {
    cal_obj.hide();
  }
/*
  var elem = document.getElementById(dispId+"_clone");
  if (elem) {
    elem.style.display = "none";
  }
*/
}

JKL.Calendar.prototype.clear_blur_timer = function(delay_ctl)
{
/* // DEBUG >>>
  var last = this.blur_timer_id;
// DEBUG <<< */
  if (this.blur_timer_id) {
    clearTimeout(this.blur_timer_id);
  }
  this.blur_timer_id = null;

  if (delay_ctl) {
    this.blur_timer_id = "xxxx"; // Prohibit
  }
/* // DEBUG >>>
  var cur = this.blur_timer_id;

  var debug = _z("debug_clear_blur_timer");
  if (!debug) {
    var textElem = this.getTextElem();
    if (textElem) {
      debug = document.createElement("span");
      debug.id = "debug_clear_blur_timer";
      textElem.parentNode.appendChild(debug);
    }
  }
  if (debug) {
    debug.innerHTML = "LAST:" + last + " CURRENT:" + cur;
  }
// DEBUG <<< */
}

JKL.Calendar.Style = function() {
    return this;
};

JKL.Calendar.Style.prototype.frame_width        = "150px";
JKL.Calendar.Style.prototype.frame_color        = "#006000";
JKL.Calendar.Style.prototype.font_size          = "12px";
JKL.Calendar.Style.prototype.day_bgcolor        = "#F0F0F0";
JKL.Calendar.Style.prototype.month_color        = "#FFFFFF";
JKL.Calendar.Style.prototype.month_hover_color  = "#009900";
JKL.Calendar.Style.prototype.month_hover_bgcolor= "#FFFFCC";
JKL.Calendar.Style.prototype.weekday_color      = "#404040";
JKL.Calendar.Style.prototype.saturday_color     = "#0040D0";
JKL.Calendar.Style.prototype.sunday_color       = "#D00000";
JKL.Calendar.Style.prototype.others_color       = "#999999";
JKL.Calendar.Style.prototype.day_hover_bgcolor  = "#FF9933";
JKL.Calendar.Style.prototype.cursor             = "pointer";
JKL.Calendar.Style.prototype.today_color        = "#008000";
JKL.Calendar.Style.prototype.today_border_color = "#00A000";
JKL.Calendar.Style.prototype.others_border_color= "#E0E0E0";
JKL.Calendar.Style.prototype.today_bgcolor      = "#D0FFD0";
JKL.Calendar.Style.prototype.unselectable_day_bgcolor = "#D0D0D0";

JKL.Calendar.Style.prototype.set = function(key,val) { this[key] = val; }
JKL.Calendar.Style.prototype.get = function(key) { return this[key]; }
JKL.Calendar.prototype.setStyle = function(key,val) { this.style.set(key,val); };
JKL.Calendar.prototype.getStyle = function(key) { return this.style.get(key); };

JKL.Calendar.prototype.initDate = function ( dd )
{
  if ( ! dd ) dd = new Date();
  var year = dd.getFullYear();
  var mon  = dd.getMonth();
  var date = dd.getDate();
  this.date = new Date( year, mon, date );
  this.getFormValue();
  return this.date;
}

JKL.Calendar.prototype.getOpacityObject = function()
{
  if ( this.__opaciobj ) return this.__opaciobj;
  var dispElem = this.getDispElem();
  if ( ! JKL.Opacity ) return;
  this.__opaciobj = new JKL.Opacity( dispElem );
  return this.__opaciobj;
};

JKL.Calendar.prototype.getDispElem = function()
{
  if ( this.__dispelem ) return this.__dispelem;

  this.__dispelem = document.createElement("div");
  this.__dispelem.id = this.disp_id + "_clone";
  this.__dispelem.style.zIndex = this.zindex;
  document.body.appendChild(this.__dispelem);
//  this.__dispelem = document.getElementById( this.disp_id );

  return this.__dispelem;
};

JKL.Calendar.prototype.getTextElem = function()
{
  if ( this.__textelem ) return this.__textelem;

  this.__textelem = document.getElementById(this.text_id);
  return this.__textelem;
};

JKL.Calendar.prototype.setDateYMD = function(ymd)
{
  var splt = ymd.split( this.spliter );
  if ( splt[0]-0 > 0 &&
       splt[1]-0 >= 1 && splt[1]-0 <= 12 &&
       splt[2]-0 >= 1 && splt[2]-0 <= 31 ) {
    if ( ! this.date ) this.initDate();
    this.date.setDate( splt[2] );
    this.date.setMonth( splt[1]-1 );
    this.date.setFullYear( splt[0] );
  } else {
    ymd = "";
  }
  return ymd;
};

JKL.Calendar.prototype.getDateYMD = function(dd)
{
  if ( ! dd ) {
      if ( ! this.date ) this.initDate();
      dd = this.date;
  }
  var mm = "" + (dd.getMonth()+1);
  var aa = "" + dd.getDate();
  if ( mm.length == 1 ) mm = "" + "0" + mm;
  if ( aa.length == 1 ) aa = "" + "0" + aa;
  return dd.getFullYear() + this.spliter + mm + this.spliter + aa;
};

JKL.Calendar.prototype.getFormValue = function()
{
  var textElem = this.getTextElem();
  if ( ! textElem ) return "";
  return this.setDateYMD(textElem.value);
};

JKL.Calendar.prototype.setFormValue = function(ymd)
{
  if ( ymd == null ) ymd = this.getDateYMD();
  var textElem = this.getTextElem();
  if ( textElem ) textElem.value = ymd;
};

JKL.Calendar.prototype.show = function()
{
  this.getDispElem().style.display = "";

  if (this.is_set_blur) {
    var textElem = this.getTextElem();
    if (textElem) {
      textElem.focus();
    }
  }
};

JKL.Calendar.prototype.hide = function()
{
  var dispElem = this.getDispElem();
  if (dispElem) {
    dispElem.parentNode.removeChild(dispElem);
  }
  this.__dispelem = null;
};

JKL.Calendar.prototype.fadeOut = function(s)
{
  if (JKL.Opacity) {
    this.getOpacityObject().fadeOut(s);
  } else {
    this.hide();
  }
};

JKL.Calendar.prototype.moveMonth = function(mon)
{
  if ( ! this.date ) this.initDate();
  for( ; mon<0; mon++ ) {
    this.date.setDate(1);
    this.date.setTime( this.date.getTime() - (24*3600*1000) );
  }
  for( ; mon>0; mon-- ) {
    this.date.setDate(1);
    this.date.setTime( this.date.getTime() + (24*3600*1000)*32 );
  }
  this.date.setDate(1);

  var dispElem = this.getDispElem();
  this.write(parseInt(dispElem.style.left), parseInt(dispElem.style.top));
};


JKL.Calendar.prototype.addEvent = function(elem, ev, func)
{
//  prototype.js があれば利用する(IEメモリリーク回避)
  if ( window.Event && Event.observe ) {
    Event.observe( elem, ev, func, false );
  } else {
    elem["on"+ev] = func;
  }
}


/*
 * 2007.10.16 Shin 月の移動でドラッグ前の位置に戻っていた不具合対応でwrite()に引数追加
 * （外からは従来どおり引数なしで呼んでOK）
 */
JKL.Calendar.prototype.write = function (x, y)
{
  var date = new Date();
  if ( ! this.date ) this.initDate();
  date.setTime( this.date.getTime() );

  var year = date.getFullYear();
  var mon  = date.getMonth();
  var today = date.getDate();
  var textElem = this.getTextElem();

  var min;
  if (this.min_date) {
    var tmp = new Date( this.min_date.getFullYear(), 
        this.min_date.getMonth(), this.min_date.getDate() );
    min = tmp.getTime();
  }
  var max;
  if (this.max_date) {
    var tmp = new Date( this.max_date.getFullYear(), 
        this.max_date.getMonth(), this.max_date.getDate() );
    max = tmp.getTime();
  }

  date.setDate(1);
  var wday = date.getDay();

  if (wday != this.start_wday) {
    date.setTime(date.getTime() - (24*3600*1000)*((wday-this.start_wday+7)%7));
  }

  // 42 = 7 days * 6 weeks
  var list = [];
  for( var i=0; i < 42; i++ ) {
      var tmp = new Date();
      tmp.setTime( date.getTime() + (24*3600*1000)*i );
      if ( i && i%7==0 && tmp.getMonth() != mon ) break;
      list[list.length] = tmp;
  }

  var month_table_style = "width: 100%; ";
  month_table_style += "background: "+this.style.frame_color+"; ";
  month_table_style += "border: 1px solid "+this.style.frame_color+";";

  var month_td_style = "";
  month_td_style += "background: "+this.style.frame_color+"; ";
  month_td_style += "font-size: "+this.style.font_size+"; ";
  month_td_style += "color: "+this.style.month_color+"; ";
  month_td_style += "padding: 4px 0px 2px 0px; ";
  month_td_style += "text-align: center; ";
  month_td_style += "font-weight: bold;";

  var week_td_style = "";
  week_td_style += "background: "+this.style.day_bgcolor+"; ";
  week_td_style += "font-size: "+this.style.font_size+"; ";
  week_td_style += "padding: 2px 0px 2px 0px; ";
  week_td_style += "font-weight: bold;";
  week_td_style += "text-align: center;";

  var days_td_style = "";
  days_td_style += "background: "+this.style.day_bgcolor+"; ";
  days_td_style += "font-size: "+this.style.font_size+"; ";
  days_td_style += "padding: 1px; ";
  days_td_style += "text-align: center; ";
  days_td_style += "font-weight: bold;";

  var days_unselectable = "font-weight: normal;";

  var html = "";

// 2006.11.23 MOM 邪魔な<select>への応急処置その１
// テーブルをdivで囲んで上位レイヤに設定(z-indexの値を大きくしておく)
// 2006.11.27 MOM 描画フィールドの高さを取得するため、idをセットしておく
  html += '<div id="'+this.disp_id+'_screen" style="position:relative; z-index:'+(this.zindex+1)+';">\n';

  html += '<table style="'+month_table_style+'">\n';
  html += '  <tr style="height:10px;">\n';
  html += '    <td id="'+this.disp_id+'_handle" colspan="7" style="padding:0px; background-color:'+this.style.day_bgcolor+'; cursor:move;" onmousedown="JKL.Calendar.clear_blur_timer(\''+this.disp_id+'\');" onmouseup="JKL.Calendar.restoreFocus(\''+this.disp_id+'\');">\n';
  html += '      <table style="width:100%; height:5px; border:ridge 5px '+this.style.frame_color+';"><tr><td></td></tr></table>\n\n';
  html += '    </td>\n';
  html += '  </tr>\n';
  html += '  <tr>\n';
  html += '    <td colspan="7">\n';
  html += '      <table style="'+month_table_style+'">\n';
  html += '        <tr>\n';
  html += '          <td id="__'+this.disp_id+'_btn_prev" title="'+JKL.Calendar.captions[0]+'" style="'+month_td_style+'">&nbsp;&laquo;</td>\n';
  html += '          <td style="'+month_td_style+'">&nbsp;</td>\n';
  if (this.show_clear) {
    html += '          <td id="__'+this.disp_id+'_btn_clear" title="'+JKL.Calendar.captions[4]+'" style="'+month_td_style+'; padding:0px 5px;"><img src="'+JKL.Calendar.buttons['clear']+'" /></td>\n';
  }
  html += '          <td id="__'+this.disp_id+'_btn_today" style="'+month_td_style+'"><nobr>'+JKL.Calendar.monthNames[mon]+'&nbsp;&nbsp;'+(year)+'</nobr></td>\n';
  html += '          <td id="__'+this.disp_id+'_btn_close" title="'+JKL.Calendar.captions[3]+'" style="'+month_td_style+'"><b style="font-size:10.5pt; padding:0px 5px;">&times;</b></td>\n';
  html += '          <td id="__'+this.disp_id+'_btn_next" title="'+JKL.Calendar.captions[2]+'" style="'+month_td_style+'">&raquo;&nbsp;</td>\n';
  html += "        </tr>\n";
  html += "      </table>\n";
  html += '    </td>\n';
  html += '  </tr>\n';
  html += '  <tr>\n';

  for (var i = this.start_wday; i < this.start_wday + 7; i++) {
    var _wday = i%7;
    if(_wday == 0) {
      html += '<td style="color: '+this.style.sunday_color+'; '+week_td_style+'">'+JKL.Calendar.wdayNames[0]+'</td>';
    } else if(_wday == 6) {
      html += '<td style="color: '+this.style.saturday_color+'; '+week_td_style+'">'+JKL.Calendar.wdayNames[6]+'</td>';
    } else {
      html += '<td style="color: '+this.style.weekday_color+'; '+week_td_style+'">';
      html += JKL.Calendar.wdayNames[_wday]+'</td>';
    }
  }

  html += "</tr>\n";

  var curutc;
  if (textElem && textElem.value) {
    var splt = textElem.value.split(this.spliter);
    if ( splt[0] > 0 && splt[2] > 0 ) {
      var curdd = new Date(splt[0]-0, splt[1]-1, splt[2]-0);
      curutc = curdd.getTime();
    }
  }

  var realdd = new Date();
  var realutc = (new Date(realdd.getFullYear(),realdd.getMonth(),realdd.getDate())).getTime();
  var holidays = JKL.Calendar.holidays;

  for ( var i=0; i<list.length; i++ ) {
    var dd = list[i];
    var ww = dd.getDay();
    var mm = dd.getMonth();

    var holiday_name = null;
    for (var j=0; holidays != null && j < holidays.length; j++) {
      var holiday = holidays[j][0];
      if (holiday.getYear() == dd.getYear()
          && holiday.getMonth() == dd.getMonth()
          && holiday.getDate() == dd.getDate()) {
        holiday_name = holidays[j][1];
        if (holiday_name == null) {
          holiday_name = "";
        }
        break;
      }
    }

    if (ww == this.start_wday) {
      html += "<tr>";
    }

    var cc = days_td_style;
    var utc = dd.getTime();

    if ( mon == mm ) {
      if (holiday_name != null) {
        cc += "color: "+this.style.sunday_color+";";
      } else if ( ww == 0 ) {
        cc += "color: "+this.style.sunday_color+";";
      } else if ( ww == 6 ) {
        cc += "color: "+this.style.saturday_color+";";
      } else if ( utc == realutc ){
        cc += "color: "+this.style.today_color+";";
      } else {
        cc += "color: "+this.style.weekday_color+";";
      }
    } else {
      cc += "color: "+this.style.others_color+";";
    }

    if (( min && min > utc ) || ( max && max < utc ) || ( !this.selectable_wdays[dd.getDay()] )) {
      cc += days_unselectable;
    }
    if ( utc == curutc ) {
      cc += "background: "+this.style.day_hover_bgcolor+";";
    } else if ( mon == mm && utc == realutc ) {
      cc += "background: "+this.style.today_bgcolor+";";
    } else if (( min && min > utc ) || ( max && max < utc ) || ( !this.selectable_wdays[dd.getDay()] )) {
      cc += 'background: '+this.style.unselectable_day_bgcolor+';';
    }

    if (this.draw_border) {
      if (mon == mm && utc == realutc) {
        cc += "border:solid 1px "+this.style.today_border_color+";";
      } else {
        cc += "border:solid 1px "+this.style.others_border_color+";";
      }
    }

    var ss = this.getDateYMD(dd);
    var day_title = ss;
    if (holiday_name != null) {
      day_title += "&nbsp;" + holiday_name.replace(/[ \t]/g, "&nbsp;");
    }
    var tt = dd.getDate();

    html += '<td style="'+cc+'" title="'+day_title+'" id="__'+this.disp_id+'_td_'+ss+'">'+tt+'</td>';

    if (ww == (this.start_wday+6)%7) {
      html += "</tr>\n";
    }
  }
  html += "</table>\n";

  html += '</div>\n';

  var dispElem = this.getDispElem();
  if ( ! dispElem ) return;
  dispElem.style.width = this.style.frame_width;
  dispElem.style.position = "absolute";
  dispElem.innerHTML = html;

// 2006.11.23 MOM 邪魔な<select>への応急処置その２
// カレンダーと全く同じサイズのIFRAMEを生成し、座標を一致させて下位レイヤに描画する

// IFRAME対応が可能なバージョンのみ処置を施す
  var ua = navigator.userAgent;
  if( ua.indexOf("MSIE 5.5") >= 0 || ua.indexOf("MSIE 6") >= 0 ){

// 2006.11.27 MOM 先にinnerHTMLにカレンダーの実体を渡しておいて、描画フィールドの高さを取得する
// ※hide()が呼ばれた直後だと、offsetHeightが0になってしまうので、一時的にshowを呼ぶ
    this.show();
    var screenHeight = dispElem.document.getElementById(this.disp_id+"_screen").offsetHeight;
    this.hide();

    html += '<div style="position:absolute;z-index:'+this.zindex+';top:0px;left:0px;">';
    html += '<iframe /?scid="dummy.htm" frameborder=0 scrolling=no width='+this.style.frame_width+' height='+screenHeight+'></iframe>';
    html += '</div>\n';

//改めてinnerHTMLにセット
    dispElem.innerHTML = html;
  }

  /*
   * Events
   */
  var __this = this;
  var get_src = function (ev) {
    ev  = ev || window.event;
    var src = ev.target || ev.srcElement;
    return src;
  };
  var month_onmouseover = function (ev) {
    var src = get_src(ev);
    src.style.color = __this.style.month_hover_color;
    src.style.background = __this.style.month_hover_bgcolor;
  };
  var month_onmouseout = function (ev) {
    var src = get_src(ev);
    src.style.color = __this.style.month_color;
    src.style.background = __this.style.frame_color;
  };
  var day_onmouseover = function (ev) {
    var src = get_src(ev);
    src.style.background = __this.style.day_hover_bgcolor;
  };
  var day_onmouseout = function (ev) {
    var src = get_src(ev);
    var today = new Date();
    if (today.getMonth() == __this.date.getMonth() && src.id == '__'+__this.disp_id+'_td_'+__this.getDateYMD(today)) {
      src.style.background = __this.style.today_bgcolor;
    } else {
      src.style.background = __this.style.day_bgcolor;
    }
  };
  var day_onclick = function (ev) {
    var src = get_src(ev);
    var srcday = src.id.substr(src.id.length-10);
    __this.setFormValue( srcday );
    __this.fadeOut( 1.0 );
    if (__this.func) {
      __this.func();
    }
  };

  var tdprev = document.getElementById( "__"+this.disp_id+"_btn_prev" );
  var tmpDate = new Date(year,mon,1);
  tmpDate.setTime( tmpDate.getTime() - (24*3600*1000) );
  if (!min || this.min_date <= tmpDate) {
    tdprev.style.cursor = this.style.cursor;
    this.addEvent( tdprev, "mouseover", month_onmouseover );
    this.addEvent( tdprev, "mouseout", month_onmouseout );
    this.addEvent( tdprev, "mousedown", function(){ __this.clear_blur_timer(true); });
    this.addEvent( tdprev, "click", function(){ __this.moveMonth( -1 ); });
  } else {
    tdprev.title = "Can\'t move to last month.";
  }

  var nMov = (realdd.getFullYear() - year) * 12 + (realdd.getMonth() - mon);
  if ( nMov != 0 ){
    var tdtoday = document.getElementById( "__"+this.disp_id+"_btn_today" );
    tdtoday.style.cursor = this.style.cursor;
    tdtoday.title = JKL.Calendar.captions[1];
    this.addEvent( tdtoday, "mouseover", month_onmouseover );
    this.addEvent( tdtoday, "mouseout", month_onmouseout );
    this.addEvent( tdtoday, "mousedown", function(){ __this.clear_blur_timer(true); });
    this.addEvent( tdtoday, "click", function(){ __this.moveMonth( nMov ); });
  }

  var tdclear = document.getElementById( "__"+this.disp_id+"_btn_clear" );
  if (tdclear) {
    tdclear.style.cursor = this.style.cursor;
    this.addEvent( tdclear, "mouseover", month_onmouseover );
    this.addEvent( tdclear, "mouseout", month_onmouseout );
    this.addEvent( tdclear, "mousedown", function(){ __this.clear_blur_timer(true); });
    this.addEvent( tdclear, "click", function(){
                  __this.setFormValue("");
                  if (__this.func) {
                    __this.func();
                  }
                  __this.hide();
                }
              );
  }

  var tdclose = document.getElementById( "__"+this.disp_id+"_btn_close" );
  tdclose.style.cursor = this.style.cursor;
  this.addEvent( tdclose, "mouseover", month_onmouseover );
  this.addEvent( tdclose, "mouseout", month_onmouseout );

  this.addEvent( tdclose, "click", function(){ __this.getFormValue(); __this.hide(); });

  var tdnext = document.getElementById( "__"+this.disp_id+"_btn_next" );
  var tmpDate = new Date(year,mon,1);
  tmpDate.setTime( tmpDate.getTime() + (24*3600*1000)*32 );
  tmpDate.setDate(1);
  if (!max || this.max_date >= tmpDate) {
    tdnext.style.cursor = this.style.cursor;
    this.addEvent( tdnext, "mouseover", month_onmouseover );
    this.addEvent( tdnext, "mouseout", month_onmouseout );
    this.addEvent( tdnext, "mousedown", function(){ __this.clear_blur_timer(true); });
    this.addEvent( tdnext, "click", function(){ __this.moveMonth( +1 ); });
  } else {
    tdnext.title = "Can\'t move to next month.";
  }

  for (var i=0; i < list.length; i++) {
    var dd = list[i];
    if ( mon != dd.getMonth() ) continue;

    var utc = dd.getTime();
    if ( min && min > utc ) continue;
    if ( max && max < utc ) continue;
    if ( utc == curutc ) continue;
    if ( !this.selectable_wdays[dd.getDay()] ) continue;

    var ss = this.getDateYMD(dd);
    var cc = document.getElementById( "__"+this.disp_id+"_td_"+ss );
    if ( ! cc ) continue;

    cc.style.cursor = this.style.cursor;
    this.addEvent( cc, "mouseover", day_onmouseover );
    this.addEvent( cc, "mouseout", day_onmouseout );
    this.addEvent( cc, "mousedown", function(){ __this.clear_blur_timer(true); });
    this.addEvent( cc, "click", day_onclick );
  }

  if (!this.is_set_blur
      && textElem.type != "hidden"
      && textElem.style.display != "none") {
    this.addEvent(textElem, "blur", function(){ __this.set_blur_timer(); });
    this.is_set_blur = true;
  }

  dispElem.onmousedown = this.onMouseDown;
  dispElem.onmousemove = this.onMouseMove;
  dispElem.onmouseup = this.onMouseUp;

  if (isNaN(x) || isNaN(y)) {
    var pos = JKL.Calendar._getPos(textElem, true);

    // for <input type="hidden" ... > on FireFox
    if (pos.x == 0 && pos.y == 0 && textElem.clientWidth == 0) {
      pos = JKL.Calendar._getPos(document.getElementById(this.disp_id), true);
    }

    var scroll = JKL.Calendar._getScroll(textElem)
    pos.x -= scroll.left;
    pos.y -= scroll.top;

    dispElem.style.left = (pos.x + textElem.clientWidth) + "px";
    dispElem.style.top = pos.y + "px";

    this.clear_blur_timer(false);

  } else {
    dispElem.style.left = x + "px";
    dispElem.style.top = y + "px";
  }

  this.show();
};

var is_dtdStandard = (document.compatMode == 'CSS1Compat');

JKL.Calendar._within = function(elem, x, y)
{
  var elemPos = JKL.Calendar._getPos(elem);
  var eX = elemPos.x;
  var eY = elemPos.y;
  var eWidth = elem.offsetWidth;
  var eHeight = elem.offsetHeight;

//alert("x="+x+", y="+y+"\neX="+eX+", eY="+eY+", eWidth="+eWidth+", eHeight="+eHeight);

  return(x >= eX && x <= eX + eWidth && y >= eY && y <= eY + eHeight);
}

JKL.Calendar._getPos = function (elem, flag)
{
  var change_display = false;
  try {
    if (elem.style.display == "none") {
      elem.style.display = "block";
      change_display = true;
    }
  } catch (e) {}

  var obj = new Object();
  obj.x = elem.offsetLeft;
  obj.y = elem.offsetTop;

  var e = elem;
  while (e.offsetParent && (flag || e.offsetParent.style.position != "absolute")) {
    e = e.offsetParent;
    obj.x += e.offsetLeft;
    obj.y += e.offsetTop;
  }

  if (change_display) {
    elem.style.display = "none";
  }
  return obj;
}

JKL.Calendar._getScroll = function (elem)
{
  var obj = new Object();
  obj.left = 0;
  obj.top = 0;

  // Netscape: offsetParentで取りこぼしが出る。<div style="overflow:auto;">
  while (elem.parentNode.tagName.toLowerCase() != "html") {
    elem = elem.parentNode;
    if (elem.style != null && 
            (elem.style.overflow=="scroll") || (elem.style.overflow=="auto")) {
      obj.left += elem.scrollLeft;
      obj.top += elem.scrollTop;
    }
  }
  return obj;
}

JKL.Calendar._getBodyScroll = function()
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

JKL.Calendar.prototype.onMouseDown = function(e)
{
  var acceptArray = [
    this.id+"_handle"
  ];

  var bodyScroll = JKL.Calendar._getBodyScroll();

  for (var i=0; i < acceptArray.length; i++) {
    var acceptCtrl = document.getElementById(acceptArray[i]);
    if (acceptCtrl == null) {
      continue;
    }
    var within = false;
    if (document.all) {
      within = JKL.Calendar._within(acceptCtrl, bodyScroll.left+event.clientX, bodyScroll.top+event.clientY);
    } else if (document.getElementById) {
      within = JKL.Calendar._within(acceptCtrl, bodyScroll.left+e.clientX, bodyScroll.top+e.clientY);
    }
    if (within != true) {
      return true;
    }
  }

  this.selected = true;
  if (document.all) {
    this.offsetX = event.clientX + bodyScroll.left - parseInt(this.style.left);
    this.offsetY = event.clientY + bodyScroll.top - parseInt(this.style.top);
  } else if (document.getElementById) {
    this.offsetX = e.pageX - parseInt(this.style.left);
    this.offsetY = e.pageY - parseInt(this.style.top);
  }
  return false;
}

JKL.Calendar.prototype.onMouseMove = function(e)
{
  if (!this.selected) {
    return true;
  }

  var l, t;
  if (document.all) {
    var bodyScroll = JKL.Calendar._getBodyScroll();
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
}

JKL.Calendar.prototype.onMouseUp = function(e)
{
  this.selected = false;
}
// 2007.10.09 Shin ドラッグ対応（ThetisBoxから移植） △

