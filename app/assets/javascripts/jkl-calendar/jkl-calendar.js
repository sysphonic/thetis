//  ========================================================
//  jkl-calendar.js ---- ポップアップカレンダー表示クラス
//  Copyright 2005-2006 Kawasaki Yusuke <u-suke [at] kawa.net>
//  Thanks to 2tak <info [at] code-hour.com>
//  http://www.kawa.net/works/js/jkl/calender.html
//  2005/04/06 - 最初のバージョン
//  2005/04/10 - 外部スタイルシートを使用しない、JKL.Opacity はオプション
//  2006/10/22 - typo修正、spliter/min_date/max_dateプロパティ、×ボタン追加
//  2006/10/23 - prototype.js併用時は、Event.observe()でイベント登録
//  2006/10/24 - max_date 範囲バグ修正
//  2006/10/25 - フォームに初期値があれば、カレンダーの初期値に採用する
//  2006/11/15 - MOM Update 週の初めの曜日を変更できるように修正
//  2006/11/23 - MOM Update 今日日付の文字色を指定できるように修正、あと枠線も描画してみる
//               邪魔な<select>への応急処置を書いてみた
//  2006/11/27 - MOM Update 邪魔な<select>への応急処置を修正、描画領域の高さを取得する
//  2006/11/30 - MOM Update 選択可能な曜日をプロパティに追加、今日日付と選択不可能な日付の背景色をスタイルに追加
//               カレンダーのz-indexをプロパティに追加
//  2006/12/04 - ksuzu Update 選択可能日がない月には移動できないように変更
//               カレンダーの表示月をクリックすると現在の月に移動できるよう変更
//               閉じるボタンにてカレンダーを閉じたとき、カレンダーの初期表示を戻すよう変更
//  2006/12/30 - MOM IFRAMEのSRC属性にdummy.htmlを挿入
//  2007/02/04 - MOM setDateYMDのバグを修正
//               TDタグのスタイルに背景色を指定するよう修正
//  2007/02/25 - Shin 次のメソッド追加
//                ・日付選択時に実行されるファンクション指定
//                ・【国際化対応】曜日名セット
//                ・【国際化対応】月名セット
//                ・【国際化対応】キャプション文言セット
//  2007/10/09 - Shin ドラッグ対応 ＋ 型崩れ修正
//  2007/10/16 - Shin
//                ・月の移動でドラッグ前の位置に戻っていた不具合修正
//                ・DTD標準モードでdocument.bodyがスクロールする場合の位置計算ロジック修正
//  2007/11/20 - Shin
//                ・FireFoxで<input type="hidden" ... >への入力時、画面の左上に表示されてしまうバグ修正。
//                ・IE6以前用ダミーフレームのSSL対策での不具合修正（MOMさん指摘）。
//  2007/11/24 - Shin 休日指定追加
//  2011/11/16 - Shin コンストラクタ第２引数で $(fid).valname のIDを指定可能に
//  2011/12/16 - Shin 入力欄クリアボタン追加
//  2012/01/09 - Shin 入力欄からフォーカスが外れたら自動非表示
//  2012/02/06 - Shin
//                ・日のtitle属性が引用符で囲まれていなかった不具合修正
//                ・z-index適用対策：コントロールを指定要素内ではなくbodyに追加するよう修正
//  ========================================================

/***********************************************************
//  （サンプル）ポップアップするカレンダー

  <html>
    <head>
      <script type="text/javascript" src="jkl-calendar_IF.js" charset="Shift_JIS"></script>
      <script>
        var cal1 = new JKL.Calendar("calid","formid","colname");
       </script>
    </head>
    <body>
      <form id="formid" action="">
        <input type="text" name="colname" onClick="cal1.write();" onChange="cal1.getFormValue(); cal1.hide();"><br>
        <div id="calid"></div>
      </form>
    </body>
  </html>

 **********************************************************/

// 親クラス

if ( typeof(JKL) == 'undefined' ) JKL = function() {};

// JKL.Calendar コンストラクタの定義

JKL.Calendar = function ( eid, fid ) {
    this.func = null;        // 日付選択時に実行されるファンクション 2007.02.25 Shin
    this.eid = eid;
  // 2011.11.16 Shin 第２引数で $(fid).valname のIDを指定可能に
    if (arguments.length >= 3) {
      this.formid = fid;
      this.valname = arguments[2];
    } else {
      this.textelem_id = fid;
    }
    this.__textelem = null;  // テキスト入力欄エレメント
    this.__dispelem = null;  // カレンダー表示欄エレメント
    this.__opaciobj = null;  // JKL.Opacity オブジェクト
    this.style = new JKL.Calendar.Style();

    // 2012.01.09 Shin 入力欄からフォーカスが外れたら自動非表示
    JKL.Calendar.cal_h[this.eid] = this;

    var dispElem = this.getFormElement();
    if (dispElem) {
      this.addEvent(dispElem, "keydown",
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

// 2007.11.24 Shin 休日指定
JKL.Calendar.holidays = null;
JKL.Calendar.setHolidays = function(array) {
  JKL.Calendar.holidays = array;
}

// 2007.02.25 Shin 日付選択時に実行されるファンクション
JKL.Calendar.prototype.setFunc = function(f) {
  this.func = f;
}

// 2007.02.25 Shin 【国際化対応】曜日名
JKL.Calendar.wdayNames = new Array('Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa');
JKL.Calendar.setWdayNames = function(array) {
  JKL.Calendar.wdayNames = array;
}

// 2007.02.25 Shin 【国際化対応】月名
JKL.Calendar.monthNames = new Array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
JKL.Calendar.setMonthNames = function(array) {
  JKL.Calendar.monthNames = array;
}

// 2007.02.25 Shin 【国際化対応】キャプション文言
JKL.Calendar.captions = new Array('Prev.', 'Move to the current month', 'Next', 'Close', 'Clear');
JKL.Calendar.setCaptions = function(array) {
  JKL.Calendar.captions = array;
}

// 2011.12.16 Shin 入力欄クリアボタン追加
JKL.Calendar.buttons = {};
JKL.Calendar.setButtons = function(hash) {
  JKL.Calendar.buttons = hash;
}


// バージョン番号

JKL.Calendar.VERSION = "0.13";

// デフォルトのプロパティ

JKL.Calendar.prototype.spliter = "-";
JKL.Calendar.prototype.date = null;
JKL.Calendar.prototype.min_date = null;
JKL.Calendar.prototype.max_date = null;

// 2006.11.15 MOM 表示開始曜日をプロパティに追加(デフォルトは日曜日=0)
JKL.Calendar.prototype.start_day = 0;

// 2006.11.23 MOM カレンダー内の日付を枠線で区切るかどうかのプロパティ(デフォルトはtrue)
JKL.Calendar.prototype.draw_border = true;

// 2006.11.30 MOM 各曜日の選択可否をプロパティに追加(デフォルトは全てtrue)
// 配列の添え字で曜日を指定(0～6 = 日曜～土曜)、選択可否をboolean値で代入する、という使い方
JKL.Calendar.prototype.selectable_days = new Array(true,true,true,true,true,true,true);

// 2006.11.30 MOM カレンダーのz-indexをプロパティに追加
JKL.Calendar.prototype.zindex = 30000;

// 2011.12.16 Shin 入力欄クリアボタン追加
JKL.Calendar.prototype.show_clear = false;

// 2012.01.09 Shin 入力欄からフォーカスが外れたら自動非表示
JKL.Calendar.cal_h = new Array();
JKL.Calendar.restoreFocus = function(eid)
{
  var cal_obj = JKL.Calendar.cal_h[eid];
  if (cal_obj && cal_obj.is_set_blur) {
    var form1 = cal_obj.getFormElement();
    if (form1) {
      try {
        form1.focus();
      } catch (e) {
      }
    }
  }
}
JKL.Calendar.clear_blur_timer = function(eid)
{
  if (JKL.Calendar.cal_h[eid]) {
    JKL.Calendar.cal_h[eid].clear_blur_timer(true);
  }
}
JKL.Calendar.prototype.is_set_blur = false;
JKL.Calendar.prototype.blur_timer_id = null;
JKL.Calendar.prototype.set_blur_timer = function()
{
  if (this.blur_timer_id == "xxxx") { // Prohibitted
    this.blur_timer_id = null;
  } else {
    this.blur_timer_id = setTimeout("JKL.Calendar.on_blur_timer(\""+this.eid+"\");", 200);
  }
}

JKL.Calendar.on_blur_timer = function(eid)
{
  var cal_obj = JKL.Calendar.cal_h[eid];

  if (cal_obj && !cal_obj.blur_timer_id) {
    return;
  }

  if (cal_obj) {
    cal_obj.hide();
  }
/*
  var elem = document.getElementById(eid+"_clone");
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
    var form1 = this.getFormElement();
    if (form1) {
      debug = document.createElement("span");
      debug.id = "debug_clear_blur_timer";
      form1.parentNode.appendChild(debug);
    }
  }
  if (debug) {
    debug.innerHTML = "LAST:" + last + " CURRENT:" + cur;
  }
// DEBUG <<< */
}

// JKL.Calendar.Style

JKL.Calendar.Style = function() {
    return this;
};

// デフォルトのスタイル

JKL.Calendar.Style.prototype.frame_width        = "150px";      // フレーム横幅
JKL.Calendar.Style.prototype.frame_color        = "#006000";    // フレーム枠の色
JKL.Calendar.Style.prototype.font_size          = "12px";       // 文字サイズ
JKL.Calendar.Style.prototype.day_bgcolor        = "#F0F0F0";    // カレンダーの背景色
JKL.Calendar.Style.prototype.month_color        = "#FFFFFF";    // ○年○月部分の背景色
JKL.Calendar.Style.prototype.month_hover_color  = "#009900";    // マウスオーバー時の≪≫文字色
JKL.Calendar.Style.prototype.month_hover_bgcolor= "#FFFFCC";   // マウスオーバー時の≪≫背景色
JKL.Calendar.Style.prototype.weekday_color      = "#404040";    // 月曜～金曜日セルの文字色
JKL.Calendar.Style.prototype.saturday_color     = "#0040D0";    // 土曜日セルの文字色
JKL.Calendar.Style.prototype.sunday_color       = "#D00000";    // 日曜日セルの文字色
JKL.Calendar.Style.prototype.others_color       = "#999999";    // 他の月の日セルの文字色
JKL.Calendar.Style.prototype.day_hover_bgcolor  = "#FF9933";    // マウスオーバー時の日セルの背景
JKL.Calendar.Style.prototype.cursor             = "pointer";    // マウスオーバー時のカーソル形状

// 2006.11.23 MOM 今日日付の文字色をプロパティに追加
JKL.Calendar.Style.prototype.today_color        = "#008000";    // 今日日付セルの文字色
// 2006.11.23 MOM 枠線もつけてみる
JKL.Calendar.Style.prototype.today_border_color = "#00A000";    // 今日日付セルの枠線の色
JKL.Calendar.Style.prototype.others_border_color= "#E0E0E0";    // 他の日セルの枠線の色

// 2006.11.30 MOM 今日日付の背景色を忘れてたので追加してみる
JKL.Calendar.Style.prototype.today_bgcolor      = "#D0FFD0";    // 今日日付セルの背景色
// 2006.11.30 MOM 選択不可能な日付の背景色を追加
JKL.Calendar.Style.prototype.unselectable_day_bgcolor = "#D0D0D0";    // 選択不可能な日付の背景色

//  メソッド

JKL.Calendar.Style.prototype.set = function(key,val) { this[key] = val; }
JKL.Calendar.Style.prototype.get = function(key) { return this[key]; }
JKL.Calendar.prototype.setStyle = function(key,val) { this.style.set(key,val); };
JKL.Calendar.prototype.getStyle = function(key) { return this.style.get(key); };

// 日付を初期化する

JKL.Calendar.prototype.initDate = function ( dd ) {
    if ( ! dd ) dd = new Date();
    var year = dd.getFullYear();
    var mon  = dd.getMonth();
    var date = dd.getDate();
    this.date = new Date( year, mon, date );
    this.getFormValue();
    return this.date;
}

// 透明度設定のオブジェクトを返す

JKL.Calendar.prototype.getOpacityObject = function () {
    if ( this.__opaciobj ) return this.__opaciobj;
    var cal = this.getCalendarElement();
    if ( ! JKL.Opacity ) return;
    this.__opaciobj = new JKL.Opacity( cal );
    return this.__opaciobj;
};

// カレンダー表示欄のエレメントを返す

JKL.Calendar.prototype.getCalendarElement = function () {
    if ( this.__dispelem ) return this.__dispelem;

    this.__dispelem = document.createElement('div');
    this.__dispelem.id = this.eid + "_clone";
    this.__dispelem.style.zIndex = this.zindex;
    document.body.appendChild(this.__dispelem);
//    this.__dispelem = document.getElementById( this.eid );

    return this.__dispelem;
};

// テキスト入力欄のエレメントを返す

JKL.Calendar.prototype.getFormElement = function () {
    if ( this.__textelem ) return this.__textelem;

    if (this.textelem_id) {
      this.__textelem = document.getElementById(this.textelem_id);
    } else {
      var frmelms = document.getElementById( this.formid );
      if ( ! frmelms ) return;
      for( var i=0; i < frmelms.elements.length; i++ ) {
        if ( frmelms.elements[i].name == this.valname ) {
          this.__textelem = frmelms.elements[i];
        }
      }
    }
    return this.__textelem;
};

// オブジェクトに日付を記憶する（YYYY/MM/DD形式で指定する）

JKL.Calendar.prototype.setDateYMD = function (ymd) {
    var splt = ymd.split( this.spliter );
    if ( splt[0]-0 > 0 &&
         splt[1]-0 >= 1 && splt[1]-0 <= 12 &&       // bug fix 2006/03/03 thanks to ucb
         splt[2]-0 >= 1 && splt[2]-0 <= 31 ) {
        if ( ! this.date ) this.initDate();
/* 2007.02.04 MOM 画面表示時、既に日付がセットされている場合に発生するバグを修正
            this.date.setFullYear( splt[0] );
            this.date.setMonth( splt[1]-1 );
            this.date.setDate( splt[2] );
*/
            this.date.setDate( splt[2] );
            this.date.setMonth( splt[1]-1 );
            this.date.setFullYear( splt[0] );
    } else {
        ymd = "";
    }
    return ymd;
};

// オブジェクトから日付を取り出す（YYYY/MM/DD形式で返る）
// 引数に Date オブジェクトの指定があれば、
// オブジェクトは無視して、引数の日付を使用する（単なるfprint機能）

JKL.Calendar.prototype.getDateYMD = function ( dd ) {
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

// テキスト入力欄の値を返す（ついでにオブジェクトも更新する）

JKL.Calendar.prototype.getFormValue = function () {
    var form1 = this.getFormElement();
    if ( ! form1 ) return "";
    var date1 = this.setDateYMD( form1.value );
    return date1;
};

// フォーム入力欄に指定した値を書き込む

JKL.Calendar.prototype.setFormValue = function (ymd) {
    if ( ymd == null ) ymd = this.getDateYMD();   // 無指定時はオブジェクトから？
    var form1 = this.getFormElement();
    if ( form1 ) form1.value = ymd;
};

//  カレンダー表示欄を表示する

JKL.Calendar.prototype.show = function () {
    this.getCalendarElement().style.display = "";

    // 2012.01.09 Shin 入力欄からフォーカスが外れたら自動非表示
    if (this.is_set_blur) {
      var form1 = this.getFormElement();
      if (form1) {
        form1.focus();
      }
    }
};

//  カレンダー表示欄を即座に隠す

JKL.Calendar.prototype.hide = function () {
  var cal1 = this.getCalendarElement();
  if (cal1) {
    cal1.parentNode.removeChild(cal1);
  }
  this.__dispelem = null;
//    this.getCalendarElement().style.display = "none";
};

//  カレンダー表示欄をフェードアウトする

JKL.Calendar.prototype.fadeOut = function (s) {
    if ( JKL.Opacity ) {
        this.getOpacityObject().fadeOut(s);
    } else {
        this.hide();
    }
};

// 月単位で移動する

JKL.Calendar.prototype.moveMonth = function ( mon ) {
    // 前へ移動
    if ( ! this.date ) this.initDate();
    for( ; mon<0; mon++ ) {
        this.date.setDate(1);   // 毎月1日の1日前は必ず前の月
        this.date.setTime( this.date.getTime() - (24*3600*1000) );
    }
    // 後へ移動
    for( ; mon>0; mon-- ) {
        this.date.setDate(1);   // 毎月1日の32日後は必ず次の月
        this.date.setTime( this.date.getTime() + (24*3600*1000)*32 );
    }
    this.date.setDate(1);       // 当月の1日に戻す

// 2007.10.16 Shin 月の移動でドラッグ前の位置に戻っていた不具合対応でwrite()に引数追加
    var cal1 = this.getCalendarElement();
    this.write(parseInt(cal1.style.left), parseInt(cal1.style.top));    // 描画する
};

// イベントを登録する

JKL.Calendar.prototype.addEvent = function ( elem, ev, func ) {
//  prototype.js があれば利用する(IEメモリリーク回避)
    if ( window.Event && Event.observe ) {
        Event.observe( elem, ev, func, false );
    } else {
        elem["on"+ev] = func;
    }
}

// カレンダーを描画する

/*
 * 2007.10.16 Shin 月の移動でドラッグ前の位置に戻っていた不具合対応でwrite()に引数追加
 * （外からは従来どおり引数なしで呼んでOK）
 */
JKL.Calendar.prototype.write = function (x, y) {
    var date = new Date();
    if ( ! this.date ) this.initDate();
    date.setTime( this.date.getTime() );

    var year = date.getFullYear();          // 指定年
    var mon  = date.getMonth();             // 指定月
    var today = date.getDate();             // 指定日
    var form1 = this.getFormElement();

    // 選択可能な日付範囲
    var min;
    if ( this.min_date ) {
        var tmp = new Date( this.min_date.getFullYear(), 
            this.min_date.getMonth(), this.min_date.getDate() );
        min = tmp.getTime();
    }
    var max;
    if ( this.max_date ) {
        var tmp = new Date( this.max_date.getFullYear(), 
            this.max_date.getMonth(), this.max_date.getDate() );
        max = tmp.getTime();
    }

    // 直前の月曜日まで戻す
    date.setDate(1);                        // 1日に戻す
    var wday = date.getDay();               // 曜日 日曜(0)～土曜(6)

// 2006.11.15 MOM 表示開始曜日を可変にしたので、ロジックちょっといじりますよ
    if ( wday != this.start_day ) {
        date.setTime( date.getTime() - (24*3600*1000)*((wday-this.start_day+7)%7) );
    }
/*
    if ( wday != 1 ) {
        if ( wday == 0 ) wday = 7;
        date.setTime( date.getTime() - (24*3600*1000)*(wday-1) );
    }
*/

    // 最大で7日×6週間＝42日分のループ
    var list = new Array();
    for( var i=0; i<42; i++ ) {
        var tmp = new Date();
        tmp.setTime( date.getTime() + (24*3600*1000)*i );
        if ( i && i%7==0 && tmp.getMonth() != mon ) break;
        list[list.length] = tmp;
    }

    // スタイルシートを生成する
    var month_table_style = 'width: 100%; ';
    month_table_style += 'background: '+this.style.frame_color+'; ';
    month_table_style += 'border: 1px solid '+this.style.frame_color+';';

/* 2007.10.09 Shin テーブル整形時に不要に
    var week_table_style = 'width: 100%; ';
    week_table_style += 'background: '+this.style.day_bgcolor+'; ';
    week_table_style += 'border-left: 1px solid '+this.style.frame_color+'; ';
    week_table_style += 'border-right: 1px solid '+this.style.frame_color+'; ';

    var days_table_style = 'width: 100%; ';
    days_table_style += 'background: '+this.style.day_bgcolor+'; ';
    days_table_style += 'border: 1px solid '+this.style.frame_color+'; ';
*/

    var month_td_style = "";
// 2007.02.04 MOM TDタグも背景色のスタイルを明示的に指定する
    month_td_style += 'background: '+this.style.frame_color+'; ';
    month_td_style += 'font-size: '+this.style.font_size+'; ';
    month_td_style += 'color: '+this.style.month_color+'; ';
    month_td_style += 'padding: 4px 0px 2px 0px; ';
    month_td_style += 'text-align: center; ';
    month_td_style += 'font-weight: bold;';

    var week_td_style = "";
// 2007.02.04 MOM TDタグも背景色のスタイルを明示的に指定する
    week_td_style += 'background: '+this.style.day_bgcolor+'; ';
    week_td_style += 'font-size: '+this.style.font_size+'; ';
    week_td_style += 'padding: 2px 0px 2px 0px; ';
    week_td_style += 'font-weight: bold;';
    week_td_style += 'text-align: center;';

    var days_td_style = "";
// 2007.02.04 MOM TDタグも背景色のスタイルを明示的に指定する
    days_td_style += 'background: '+this.style.day_bgcolor+'; ';
    days_td_style += 'font-size: '+this.style.font_size+'; ';
    days_td_style += 'padding: 1px; ';
    days_td_style += 'text-align: center; ';
    days_td_style += 'font-weight: bold;';

    var days_unselectable = "font-weight: normal;";

    // HTMLソースを生成する
    var src1 = "";

// 2006.11.23 MOM 邪魔な<select>への応急処置その１
// テーブルをdivで囲んで上位レイヤに設定(z-indexの値を大きくしておく)
// 2006.11.27 MOM 描画フィールドの高さを取得するため、idをセットしておく
    src1 += '<div id="'+this.eid+'_screen" style="position:relative; z-index:'+(this.zindex+1)+';">\n';

    src1 += '<table style="'+month_table_style+'">\n';
    src1 += '  <tr style="height:10px;">\n';
    src1 += '    <td id="'+this.eid+'_handle" colspan="7" style="padding:0px; background-color:'+this.style.day_bgcolor+'; cursor:move;" onmousedown="JKL.Calendar.clear_blur_timer(\''+this.eid+'\');" onmouseup="JKL.Calendar.restoreFocus(\''+this.eid+'\');">\n';
    src1 += '      <table style="width:100%; height:5px; border:ridge 5px '+this.style.frame_color+';"><tr><td></td></tr></table>\n\n';
    src1 += '    </td>\n';
    src1 += '  </tr>\n';
    src1 += '  <tr>\n';
    src1 += '    <td colspan="7">\n';
    src1 += '      <table style="'+month_table_style+'">\n';
    src1 += '        <tr>\n';
    src1 += '          <td id="__'+this.eid+'_btn_prev" title="'+JKL.Calendar.captions[0]+'" style="'+month_td_style+'">&nbsp;&laquo;</td>\n';
    src1 += '          <td style="'+month_td_style+'">&nbsp;</td>\n';
// 2011.12.16 Shin 入力欄クリアボタン追加
    if (this.show_clear) {
      src1 += '          <td id="__'+this.eid+'_btn_clear" title="'+JKL.Calendar.captions[4]+'" style="'+month_td_style+'; padding:0px 5px;"><img src="'+JKL.Calendar.buttons['clear']+'" /></td>\n';
    }
// 2006.12.04 ksuzu 表示月をクリックすると現在の月に移動
    src1 += '          <td id="__'+this.eid+'_btn_today" style="'+month_td_style+'"><nobr>'+JKL.Calendar.monthNames[mon]+'&nbsp;&nbsp;'+(year)+'</nobr></td>\n';
//    src1 += '<td style="'+month_td_style+'">'+(year)+'年 '+(mon+1)+'月</td>';
    src1 += '          <td id="__'+this.eid+'_btn_close" title="'+JKL.Calendar.captions[3]+'" style="'+month_td_style+'"><b style="font-size:10.5pt; padding:0px 5px;">&times;</b></td>\n';
    src1 += '          <td id="__'+this.eid+'_btn_next" title="'+JKL.Calendar.captions[2]+'" style="'+month_td_style+'">&raquo;&nbsp;</td>\n';
    src1 += "        </tr>\n";
    src1 += "      </table>\n";
    src1 += '    </td>\n';
    src1 += '  </tr>\n';
    src1 += '  <tr>\n';

// 2006.11.15 MOM 表示開始曜日start_dayから順に一週間分表示する
    for (var i = this.start_day; i < this.start_day + 7; i++) {
      var _wday = i%7;
      if(_wday == 0) {
        src1 += '<td style="color: '+this.style.sunday_color+'; '+week_td_style+'">'+JKL.Calendar.wdayNames[0]+'</td>';
      } else if(_wday == 6) {
        src1 += '<td style="color: '+this.style.saturday_color+'; '+week_td_style+'">'+JKL.Calendar.wdayNames[6]+'</td>';
      } else {
        src1 += '<td style="color: '+this.style.weekday_color+'; '+week_td_style+'">';
        src1 += JKL.Calendar.wdayNames[_wday]+'</td>';
      }
    }

    src1 += "</tr>\n";

    var curutc;
    if ( form1 && form1.value ) {
        var splt = form1.value.split(this.spliter);
        if ( splt[0] > 0 && splt[2] > 0 ) {
            var curdd = new Date( splt[0]-0, splt[1]-1, splt[2]-0 );
            curutc = curdd.getTime();                           // フォーム上の当日
        }
    }

//2006.11.23 MOM 今日日付を取得し、時分秒を切り捨てる
    var realdd = new Date();
    var realutc = (new Date(realdd.getFullYear(),realdd.getMonth(),realdd.getDate())).getTime();
    var holidays = JKL.Calendar.holidays;

    for ( var i=0; i<list.length; i++ ) {
        var dd = list[i];
        var ww = dd.getDay();
        var mm = dd.getMonth();

        //2007.11.24 Shin 休日判定
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

        if ( ww == this.start_day ) {
            src1 += "<tr>";                                     // 表示開始曜日の前に行頭
        }
/*
        if ( ww == 1 ) {
            src1 += "<tr>";                                     // 月曜日の前に行頭
        }
*/

        var cc = days_td_style;
        var utc = dd.getTime();

        if ( mon == mm ) {

//2006.11.23 MOM 最初に今日日付かどうかをチェックする
//※当月でない場合にも色変えると選択できそうに見えて紛らわしいので、当月かつ今日日付の場合のみ色を変える
            if (holiday_name != null) {
                cc += "color: "+this.style.sunday_color+";";    // 当月の日曜日
            } else if ( ww == 0 ) {
                cc += "color: "+this.style.sunday_color+";";    // 当月の日曜日
            } else if ( ww == 6 ) {
                cc += "color: "+this.style.saturday_color+";";  // 当月の土曜日
            } else if ( utc == realutc ){
                cc += "color: "+this.style.today_color+";";     // 今日日付
            } else {
                cc += "color: "+this.style.weekday_color+";";   // 当月の平日
            }
        } else {
            cc += "color: "+this.style.others_color+";";        // 前月末と翌月初の日付
        }

//2006.11.23 MOM utcの変数宣言を↑に移動
//      var utc = dd.getTime();

// 2006.11.30 MOM 選択可能な曜日指定の条件追加
//        if (( min && min > utc ) || ( max && max < utc )) {
        if (( min && min > utc ) || ( max && max < utc ) || ( !this.selectable_days[dd.getDay()] )) {
            cc += days_unselectable;
        }
        if ( utc == curutc ) {                                  // フォーム上の当日
            cc += "background: "+this.style.day_hover_bgcolor+";";
        }
// 2006.11.30 MOM 今日日付の背景色
        else if ( mon == mm && utc == realutc ) {
            cc += "background: "+this.style.today_bgcolor+";";
        }
// 2006.11.30 MOM 選択不可能な日付の背景色
        else if (( min && min > utc ) || ( max && max < utc ) || ( !this.selectable_days[dd.getDay()] )) {
            cc += 'background: '+this.style.unselectable_day_bgcolor+';';
        }

//2006.11.23 MOM 枠線描画を追加
        if ( this.draw_border ){
            if ( mon == mm && utc == realutc ){
                cc += "border:solid 1px "+this.style.today_border_color+";";    // 当月かつ今日日付
            } else {
                cc += "border:solid 1px "+this.style.others_border_color+";";    // その他
            }
        }

        var ss = this.getDateYMD(dd);
        var day_title = ss;
        if (holiday_name != null) {
          day_title += "&nbsp;" + holiday_name.replace(/[ \t]/g, "&nbsp;");
        }
        var tt = dd.getDate();

        src1 += '<td style="'+cc+'" title="'+day_title+'" id="__'+this.eid+'_td_'+ss+'">'+tt+'</td>';

        if ( ww == (this.start_day+6)%7 ) {
            src1 += "</tr>\n";                                  // 表示開始曜日の１つ手前で行末
        }
/*
        if ( ww == 7 ) {
            src1 += "</tr>\n";                                  // 土曜日の後に行末
        }
*/
    }
    src1 += "</table>\n";

    src1 += '</div>\n';

    // カレンダーを書き換える
    var cal1 = this.getCalendarElement();
    if ( ! cal1 ) return;
    cal1.style.width = this.style.frame_width;
    cal1.style.position = "absolute";
    cal1.innerHTML = src1;


// 2006.11.23 MOM 邪魔な<select>への応急処置その２
// カレンダーと全く同じサイズのIFRAMEを生成し、座標を一致させて下位レイヤに描画する

// IFRAME対応が可能なバージョンのみ処置を施す
    var ua = navigator.userAgent;
    if( ua.indexOf("MSIE 5.5") >= 0 || ua.indexOf("MSIE 6") >= 0 ){

// 2006.11.27 MOM 先にinnerHTMLにカレンダーの実体を渡しておいて、描画フィールドの高さを取得する
// ※hide()が呼ばれた直後だと、offsetHeightが0になってしまうので、一時的にshowを呼ぶ
        this.show();
        var screenHeight = cal1.document.getElementById(this.eid+"_screen").offsetHeight;
        this.hide();

        src1 += '<div style="position:absolute;z-index:'+this.zindex+';top:0px;left:0px;">';
        src1 += '<iframe /?scid="dummy.htm" frameborder=0 scrolling=no width='+this.style.frame_width+' height='+screenHeight+'></iframe>';
        src1 += '</div>\n';

//改めてinnerHTMLにセット
        cal1.innerHTML = src1;
    }

    // イベントを登録する
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
// 2006.11.30 MOM 当月かつ今日日付であれば、今日日付用の背景色を適用
        var today = new Date();
        if( today.getMonth() == __this.date.getMonth() && src.id == '__'+__this.eid+'_td_'+__this.getDateYMD(today) ){
            src.style.background = __this.style.today_bgcolor;
        }else{
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

//
// 2006.12.04 ksuzu 選択できない月へのリンクは作成しない
//
    // 前の月へボタン
    var tdprev = document.getElementById( "__"+this.eid+"_btn_prev" );
    //前の月の最終日
    var tmpDate = new Date(year,mon,1);
    tmpDate.setTime( tmpDate.getTime() - (24*3600*1000) );
    //選択可能な日がある？
    if ( !min || this.min_date <= tmpDate ){
        tdprev.style.cursor = this.style.cursor;
        this.addEvent( tdprev, "mouseover", month_onmouseover );
        this.addEvent( tdprev, "mouseout", month_onmouseout );
        this.addEvent( tdprev, "mousedown", function(){ __this.clear_blur_timer(true); });
        this.addEvent( tdprev, "click", function(){ __this.moveMonth( -1 ); });
    }
    //選択不可能
    else{
        tdprev.title = "Can\'t move to last month.";
    }
/*
    tdprev.style.cursor = this.style.cursor;
    this.addEvent( tdprev, "mouseover", month_onmouseover );
    this.addEvent( tdprev, "mouseout", month_onmouseout );
    this.addEvent( tdprev, "click", function(){ __this.moveMonth( -1 ); });
2006.12.04 ksuzu */

//
// 2006.12.04 ksuzu 表示月をクリックすると現在の月に移動
//
    var nMov = (realdd.getFullYear() - year) * 12 + (realdd.getMonth() - mon);
    if ( nMov != 0 ){
        // 現在の月へボタン
        var tdtoday = document.getElementById( "__"+this.eid+"_btn_today" );
        tdtoday.style.cursor = this.style.cursor;
        tdtoday.title = JKL.Calendar.captions[1];
        this.addEvent( tdtoday, "mouseover", month_onmouseover );
        this.addEvent( tdtoday, "mouseout", month_onmouseout );
        this.addEvent( tdtoday, "mousedown", function(){ __this.clear_blur_timer(true); });
        this.addEvent( tdtoday, "click", function(){ __this.moveMonth( nMov ); });
    }

    // 入力欄クリアボタン
    var tdclear = document.getElementById( "__"+this.eid+"_btn_clear" );
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

    // 閉じるボタン
    var tdclose = document.getElementById( "__"+this.eid+"_btn_close" );
    tdclose.style.cursor = this.style.cursor;
    this.addEvent( tdclose, "mouseover", month_onmouseover );
    this.addEvent( tdclose, "mouseout", month_onmouseout );

//
// 2006.12.04 ksuzu カレンダーの初期表示を戻す
//
    this.addEvent( tdclose, "click", function(){ __this.getFormValue(); __this.hide(); });
//    this.addEvent( tdclose, "click", function(){ __this.hide(); });

//
// 2006.12.04 ksuzu 選択できない月へのリンクは作成しない
//
    // 次の月へボタン
    var tdnext = document.getElementById( "__"+this.eid+"_btn_next" );
    //次の月の初日
    var tmpDate = new Date(year,mon,1);
    tmpDate.setTime( tmpDate.getTime() + (24*3600*1000)*32 );
    tmpDate.setDate(1);
    //選択可能な日がある？
    if ( !max || this.max_date >= tmpDate ){
        tdnext.style.cursor = this.style.cursor;
        this.addEvent( tdnext, "mouseover", month_onmouseover );
        this.addEvent( tdnext, "mouseout", month_onmouseout );
        this.addEvent( tdnext, "mousedown", function(){ __this.clear_blur_timer(true); });
        this.addEvent( tdnext, "click", function(){ __this.moveMonth( +1 ); });
    }
    //選択不可能
    else{
        tdnext.title = "Can\'t move to next month.";
    }
/*
    tdnext.style.cursor = this.style.cursor;
    this.addEvent( tdnext, "mouseover", month_onmouseover );
    this.addEvent( tdnext, "mouseout", month_onmouseout );
    this.addEvent( tdnext, "click", function(){ __this.moveMonth( +1 ); });
2006.12.04 ksuzu */

    // セルごとのイベントを登録する
    for ( var i=0; i<list.length; i++ ) {
        var dd = list[i];
        if ( mon != dd.getMonth() ) continue;       // 今月のセルにのみ設定する

        var utc = dd.getTime();
        if ( min && min > utc ) continue;           // 昔過ぎる
        if ( max && max < utc ) continue;           // 未来過ぎる
        if ( utc == curutc ) continue;              // フォーム上の当日
// 2006.11.30 MOM 選択可能な曜日指定対応
        if ( !this.selectable_days[dd.getDay()] ) continue;

        var ss = this.getDateYMD(dd);
        var cc = document.getElementById( "__"+this.eid+"_td_"+ss );
        if ( ! cc ) continue;

        cc.style.cursor = this.style.cursor;
        this.addEvent( cc, "mouseover", day_onmouseover );
        this.addEvent( cc, "mouseout", day_onmouseout );
        this.addEvent( cc, "mousedown", function(){ __this.clear_blur_timer(true); });
        this.addEvent( cc, "click", day_onclick );
    }

    // 2012.01.09 Shin 入力欄からフォーカスが外れたら自動非表示
    if (!this.is_set_blur
        && form1.type != "hidden"
        && form1.style.display != "none") {
      this.addEvent(form1, "blur", function(){ __this.set_blur_timer(); });
      this.is_set_blur = true;
    }

// 2007.10.09 Shin ドラッグ対応
    cal1.onmousedown = this.onMouseDown;
    cal1.onmousemove = this.onMouseMove;
    cal1.onmouseup = this.onMouseUp;

    if (isNaN(x) || isNaN(y)) {
      var pos = JKL.Calendar._getPos(form1, true);

      // for <input type="hidden" ... > on FireFox
      if (pos.x == 0 && pos.y == 0 && form1.clientWidth == 0) {
        pos = JKL.Calendar._getPos(document.getElementById(this.eid), true);
      }

      if (!is_Opera) {
        if (is_dtdStandard || !is_MS) {
          var scroll = JKL.Calendar._getScroll(form1)
          pos.x -= scroll.left;
          pos.y -= scroll.top;
        }
      }

      cal1.style.left = (pos.x + form1.clientWidth) + "px";
      cal1.style.top = pos.y + "px";

      this.clear_blur_timer(false);

    } else {
      cal1.style.left = x + "px";
      cal1.style.top = y + "px";
    }

    // 表示する
    this.show();
};

// 2007.10.09 Shin ドラッグ対応（ThetisBoxから移植） ▽
var _appName = window.navigator.appName;
var is_MS = (_appName.toLowerCase().indexOf('explorer') >= 0);       // MSIE, Sleipnir
//var is_Netscape = (_appName.toLowerCase().indexOf('netscape') >= 0); // Firefox, Safari
var is_Opera = (_appName.toLowerCase().indexOf('opera') >= 0);       // Opera

var is_dtdStandard = (document.compatMode == 'CSS1Compat');

JKL.Calendar._within = function(elem, x, y) {
  var elemPos = JKL.Calendar._getPos(elem);
  var eX = elemPos.x;
  var eY = elemPos.y;
  var eWidth = elem.offsetWidth;
  var eHeight = elem.offsetHeight;

  if (is_Opera || (is_MS && !is_dtdStandard)) {
    var scroll = JKL.Calendar._getScroll(elem);
    eX -= scroll.left;
    eY -= scroll.top;
  }
//alert("x="+x+", y="+y+"\neX="+eX+", eY="+eY+", eWidth="+eWidth+", eHeight="+eHeight);

  return(x >= eX && x <= eX + eWidth && y >= eY && y <= eY + eHeight);
}

JKL.Calendar._getPos = function (elem, flag) {

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

JKL.Calendar._getScroll = function (elem) {
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

JKL.Calendar.prototype.onMouseDown = function ( e ) {
  var acceptArray = new Array(
        this.id+"_handle"
    );

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

JKL.Calendar.prototype.onMouseMove = function(e) {
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

JKL.Calendar.prototype.onMouseUp = function(e) {
  this.selected = false;
}
// 2007.10.09 Shin ドラッグ対応（ThetisBoxから移植） △

// 旧バージョン互換（typo）
JKL.Calendar.prototype.getCalenderElement = JKL.Calendar.prototype.getCalendarElement;
JKL.Calender = JKL.Calendar;
