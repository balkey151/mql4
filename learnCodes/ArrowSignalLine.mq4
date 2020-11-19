//+------------------------------------------------------------------+
//|                                               ArrowSignalLine.mq4|
//|                                                        Balkey151 |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Balkey151"
#property link      ""
#property version   "1.00"
#property strict
#property indicator_chart_window

// インジケータの表示におけるプロパティ定義
#property indicator_buffers 2 // インジケータのバッファ数

// 1本目(上昇トレンド)の設定
#property indicator_color1 clrRed //インジケータの色
#property indicator_width1 2 //インジケータの太さ
#property indicator_type1 DRAW_ARROW // インジケータの描画タイプをアローに設定

// 2本目(下降トレンド)の設定
#property indicator_color2 clrRed //インジケータの色
#property indicator_width2 2 //インジケータの太さ
#property indicator_type2 DRAW_ARROW // インジケータの描画タイプをアローに設定

// 更新対象バー数の定義
#define IND_TARGET_BARS 3

// インジケータ表示用の動的配列を定義
double IndBuffrer1[]; // 1本目の表示用動的配列
double IndBuffrer2[]; // 2本目の表示用動的配列

//+------------------------------------------------------------------+
//| 初期化時に1度起動するファンクション
//+------------------------------------------------------------------+
int OnInit()
  {
   // 各動的配列をバインド
   // アッパーシグナルの動的配列をバインド
   SetIndexBuffer(0,IndBuffrer1);
   // ロワーシグナルの動的配列をバインド
   SetIndexBuffer(1,IndBuffrer2);
      
   // 各インジケータのアローシンボルを定義
   // アッパーシグナルのアローシンボル
   SetIndexArrow(0 ,233);
   // ロワーシグナルのアローシンボル
   SetIndexArrow(1 ,234);
   
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| OnInit実行時またはtick受信時に実行するファンクション
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, //バーの総数
                const int prev_calculated, //計算済み（前回実行時）のバーの総数
                const datetime &time[], //時間
                const double &open[], //始値
                const double &high[], //高値
                const double &low[], //低値
                const double &close[], //終値
                const long &tick_volume[], //tick出来高
                const long &volume[], //Real出来高
                const int &spread[]) //スプレッド
  {
   
   // 終値を取得
   int endIndex = Bars - prev_calculated;// バーの数(未計算分)を取得
   if(endIndex <= IND_TARGET_BARS){ // 直近の2本を更新対象とする
       endIndex = IND_TARGET_BARS;
   }
   
   // バッファオーバーフロー対策
   // ヒストリカルデータが不足していた場合、全てのバーに対して再計算が必要なため、0を返す。
   if(Bars <= IND_TARGET_BARS){
       return 0;
   }
   
   // 転換時にアローシグナルを表示するインジケータを算出
   for(int count = 0 ; count < endIndex ; count++ ){
       
       double getLower = iFractals(
                                   Symbol() , // 通貨ペア
                                   Period() , // 時間軸
                                   MODE_LOWER , // ラインインデックス
                                   count // シフト
                                  );

       double getUpper = iFractals(
                                   Symbol() , // 通貨ペア
                                   Period() , // 時間軸
                                   MODE_UPPER , // ラインインデックス
                                   count // シフト
                                  );
       
       if( getLower > 0 ){
           // 価格を10ピクセル単位でオフセット
           getLower = getOffsetRate(getLower ,30);
           // インジケータ1に、ロワーシグナル表示を設定
           IndBuffrer1[count] = getLower;
       }
       
       if( getUpper > 0 ){
           // 価格を10ピクセル単位でオフセット
           getUpper = getOffsetRate(getUpper ,-30);
           // インジケータ1に、ロワーシグナル表示を設定
           IndBuffrer2[count] = getUpper;
       }
   }
   
   return(rates_total); // 戻り値設定：次回OnCalculate関数が呼ばれた時のprev_calculatedの値に渡される
  }

//+------------------------------------------------------------------+
//| 価格のレートを、ピクセル単位でオフセットするファンクション
//+------------------------------------------------------------------+
double getOffsetRate(
                     double rate , // 価格のレート
                     int offsetPixel // オフセットの指定値
                    )
{
    double ret = rate; // 戻り値
    double moveRate; // オフセットしたレート
    datetime dummyTime; // ダミー時間
    int baseAxisX; // 取得したX座標（時間）
    int baseAxisY; // 取得したY座標（価格）
    int getWIndowNum; // 取得したサブウィンドウのNo
    int dispPixel; // オフセットした座標
    bool getBoolean; // 判定結果

    // 時間、価格値をXY座標に変換
    getBoolean = ChartTimePriceToXY(
                                    0 , // チャートID
                                    0 , // サブウィンドウNo
                                    Time[0] , // チャート上の時間
                                    rate , // チャート上の価格レート
                                    baseAxisX , // X座標（時間）
                                    baseAxisY  // Y座標（価格）
                                   );
    
    // XY座標に変換できた場合
    if( getBoolean == true ){
        // Y座標をオフセット
        dispPixel = baseAxisY + offsetPixel;
        
        // XY座標を時間、価格値に再変換
        getBoolean = ChartXYToTimePrice(
                                       0 , // チャートID 
                                       baseAxisX , // X座標（時間）
                                       dispPixel , // Y座標（価格）
                                       getWIndowNum , // サブウィンドウのNo
                                       dummyTime , // ダミー時間
                                       moveRate // オフセットしたレート
                                      );
       
       // 戻り値に変換後の価格（Y座標）を設定
       if( getBoolean == true ){
           ret = moveRate;
       }
    }
    
    return ret;
}