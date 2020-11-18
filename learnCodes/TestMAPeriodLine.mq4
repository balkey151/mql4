//+------------------------------------------------------------------+
//|                                              TestMAPeriodLine.mq4|
//|                                                        Balkey151 |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Balkey151"
#property link      ""
#property version   "1.00"
#property strict
#property indicator_chart_window

// インジケータの表示におけるプロパティ定義
#property indicator_buffers 3 // インジケータのバッファ数

// 1本目(移動平均線)の設定
#property indicator_color1 clrWhite //インジケータの色
#property indicator_width1 2 //インジケータの太さ

// 2本目(エンベロープ線(+))の設定
#property indicator_color2 clrLightBlue //インジケータの色
#property indicator_width2 2 //インジケータの太さ

// 3本目(エンベロープ線(-))の設定
#property indicator_color3 clrLightBlue //インジケータの色
#property indicator_width3 2 //インジケータの太さ

// 更新対象バー数の定義
#define IND_TARGET_BARS 2

// inputパラメータ（各種デフォルト値は予めセット）
input int INPUT_PERIOD_PARAM = 25; // 移動平均期間
input double INPUT_ENV_PLUS_PARAM = 50; // エンベロープ(+)の乖離幅（単位：1pips）
input double INPUT_ENV_MINUS_PARAM = 50; // エンベロープ(-)の乖離幅（単位：1pips）
input ENUM_TIMEFRAMES INPUT_TIME_PERIOD = PERIOD_CURRENT; // 移動平均の時間軸をENUMで列挙

// インジケータ表示用の動的配列を定義
double IndBuffrer1[]; // 移動平均線の表示用動的配列
double IndBuffrer2[]; // エンベロープ線(+)の表示用動的配列
double IndBuffrer3[]; // エンベロープ線(-)の表示用動的配列

//+------------------------------------------------------------------+
//| 初期化時に1度起動するファンクション
//+------------------------------------------------------------------+
int OnInit()
  {
   // 各動的配列をバインド
   // 移動平均線の動的配列をバインド
   SetIndexBuffer(0,IndBuffrer1);
   // エンベロープ線（+）の動的配列をバインド
   SetIndexBuffer(1,IndBuffrer2);
   // エンベロープ線(-)の動的配列をバインド
   SetIndexBuffer(2,IndBuffrer3);
   
   // 各インジケータのラベル名を定義
   // 移動平均線
   SetIndexLabel(0, "移動平均線");
   SetIndexLabel(1, "エンベロープ線(+)");
   SetIndexLabel(2, "エンベロープ線(-)");
   
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
   int minIndex = GetMinIndex();
   int endIndex = Bars - prev_calculated;// バーの数(未計算分)を取得
   if(endIndex <= minIndex){ // 直近の2本を更新対象とする
       endIndex = minIndex;
   }
   
   // バッファオーバーフロー対策
   // ヒストリカルデータが不足していた場合、全てのバーに対して再計算が必要なため、0を返す。
   if(Bars <= minIndex){
       return 0;
   }
   
   for(int count = 0 ; count < endIndex ; count++ ){
       double getMa = calOtherPeriodMA(
                           INPUT_TIME_PERIOD , // 指定した時間軸
                           INPUT_PERIOD_PARAM , // 指定した移動平均期間
                           count // インデックス
                         );
       
       double getOnePipsRate = Point() * 10; // 1pipsあたりのレートを取得
       double envPlusRate = INPUT_ENV_PLUS_PARAM * getOnePipsRate; //乖離オフセットのプラスレートに換算
       double envMinusRate = INPUT_ENV_MINUS_PARAM * getOnePipsRate; //乖離オフセットのマイナスレートに換算
       
       IndBuffrer1[count] = getMa;      // インジケータ1に、取得した移動平均線を格納
       IndBuffrer2[count] = getMa + envPlusRate; // インジケータ2に、取得した移動平均+乖離幅を格納
       IndBuffrer3[count] = getMa - envMinusRate; // インジケータ3に、取得した移動平均-乖離幅を格納
   }
   
   return(rates_total); // 戻り値設定：次回OnCalculate関数が呼ばれた時のprev_calculatedの値に渡される

  }

//+------------------------------------------------------------------+
//| 指定した時間軸で移動平均を算出するファンクション
//+------------------------------------------------------------------+
double calOtherPeriodMA(
                        ENUM_TIMEFRAMES inputTimePeriod , // 指定した時間軸
                        int inputPeriod , // 指定した移動平均期間
                        int MAIndex // インデックス
                        )
    {
        double ret = 0; // 戻り値のローカル変数
        double getOtherMa = 0; // 他時間軸の移動平均値
        int otherIndex = 0; // 指定した時間軸のインデックス
        datetime otherTime = 0; // 指定した時間軸の日時
        
        // 現在の時間軸のインデックスから日時取得
        otherTime = Time[MAIndex];
        
        // 日時から指定した時間軸のインデックスを取得
        otherIndex = iBarShift(
                              Symbol() , // 現在のチャートの通貨ペア
                              inputTimePeriod , // 指定した時間軸
                              otherTime , // 日時
                              false // 検索モード（指定時間のインデックスがない場合、指定時間に近いインデックスの取得）
                              );
        
        // 指定時間軸のインデックスが取得できた場合、取得したインデックスから移動平均値を算出
        if(otherIndex >= 0){
            
            getOtherMa = iMA(
                                Symbol() , // 通貨ペア
                                inputTimePeriod , // 時間軸
                                inputPeriod , // MAの移動平均期間
                                0 , // MAのシフト
                                MODE_EMA , // MAの平均化メソッド
                                PRICE_CLOSE , // 適用価格
                                otherIndex // シフト
                            );
            
            // 算出した移動平均値を、戻り値に格納
            ret = getOtherMa;
        };
        
        return ret;
    
    }

//+------------------------------------------------------------------+
//| 最小更新対象のバー数を決定するファンクション
//+------------------------------------------------------------------+
int GetMinIndex(){
    // デフォルトの最小更新対象バー数
    int ret = IND_TARGET_BARS;
    
    // 指定した時間軸が、現在のチャートの時間軸より大きい場合、最小更新対象バー数を変更
    if(INPUT_TIME_PERIOD > Period()){
        ret = IND_TARGET_BARS + INPUT_TIME_PERIOD / Period();
    };
    
    return ret;
}
