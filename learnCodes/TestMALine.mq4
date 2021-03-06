//+------------------------------------------------------------------+
//|                                                    TestMALine.mq4|
//|                                                        Balkey151 |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Balkey151"
#property link      ""
#property version   "1.00"
#property strict
#property indicator_chart_window

// インジケータの表示におけるプロパティ定義
#property indicator_buffers 1 // インジケータのバッファ数
#property indicator_color1 clrWhite //インジケータの色
#property indicator_width1 2 //インジケータの太さ

// 更新対象バー数の定義
#define IND_TARGET_BARS 2

// 移動平均期間をinput変数にて定義
input int INPUT_PERIOD_PARAM = 25;// 移動平均期間

// インジケータ表示用の動的配列を定義
double IndBuffrer1[]; // インジケータ1の表示用動的配列

//+------------------------------------------------------------------+
//| 初期化時に1度起動するファンクション
//+------------------------------------------------------------------+
int OnInit()
  {
   //インジケータ1の動的配列をバインド
   SetIndexBuffer(0,IndBuffrer1);
   
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
   if(Bars <= IND_TARGET_BARS){
       return 0;
   }
   
   for(int count = 0 ; count < endIndex ; count++ ){
       double getMa = iMA(
                           Symbol(),// 通貨ペア
                           Period(),// 時間軸
                           INPUT_PERIOD_PARAM,// 移動平均期間
                           0,// シフトの値
                           MODE_EMA,// MAの平均化メソッド
                           PRICE_CLOSE,// 適用価格
                           count// シフト
                         );
       IndBuffrer1[count] = getMa;      // インジケータ1に、取得した移動平均線を格納
   }
   
   return(rates_total); // 戻り値設定：次回OnCalculate関数が呼ばれた時のprev_calculatedの値に渡される
  }

