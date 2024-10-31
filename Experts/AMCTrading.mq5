//+------------------------------------------------------------------+
//|                                                  AMCTrading.mq5  | 
//|                        Copyright 2024, Your Name                | 
//|                                      https://www.yourwebsite.com | 
//+------------------------------------------------------------------+ 

#include <Symbole.mqh>

#define EMA_PERIOD 21 
#define HA_PERIOD 5 

#property indicator_separate_window
#property indicator_buffers 6
#property indicator_plots   2
#property indicator_type1   DRAW_COLOR_CANDLES
#property indicator_color1  clrBlue, clrRed
#property indicator_width1  2
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrGold
#property indicator_width2  1
#property indicator_label2  "EMA 21"

datetime lastOpenTime = 0; 
ulong positionTicket = 0; 
datetime lastStartTime; 
int totalCandleCount = 0; 

double lastPositionClosePrice = 0; 
int candleCounter = 0; 
double candle0High = 0; 
bool hasRedArrowBeenCreated = false; 
datetime lastCandleTime = 0; 
bool positionOpened = false; 
bool hasClosedPosition = false; 

color buyArrowColor = clrBlue; 
color sellArrowColor = clrRed;  
double haOpen[];
double haHigh[];
double haLow[];
double haClose[];
double haColor[];
double ema21[];

// Opret indikatorer som #indicator arrows
void CreateIndicatorArrows() {
    string symbol = Symbol();
    ENUM_TIMEFRAMES timeframe = Period();
    int bars = iBars(symbol, timeframe);

    for (int i = 1; i < bars; i++) {
        datetime barTime = iTime(symbol, timeframe, i);

        if (IsBullishEngulfing(symbol, timeframe, i)) {
            string buyArrowName = "buy_arrow_" + IntegerToString(barTime);
            CreateArrow(buyArrowName, barTime, iHigh(symbol, timeframe, i) + (0.01 * _Point), buyArrowColor, 233);
            Print("Buy arrow created at ", TimeToString(barTime, TIME_DATE | TIME_MINUTES));
        }

        if (IsBearishEngulfing(symbol, timeframe, i)) {
            string sellArrowName = "sell_arrow_" + IntegerToString(barTime);
            CreateArrow(sellArrowName, barTime, iLow(symbol, timeframe, i) - (0.01 * _Point), sellArrowColor, 234);
            Print("Sell arrow created at ", TimeToString(barTime, TIME_DATE | TIME_MINUTES));
        }
    }
}

// OnInit function til at sætte flags i hele perioden
int OnInit() {
    CreateIndicatorArrows(); 
    ScanForEngulfingPatterns();
    FlagCandlesWithArrows();
    return INIT_SUCCEEDED;
}

// Update the last open time for tracking positions
void UpdateLastOpenTime() { 
    positionOpened = IsPositionOpen(); 
    if (positionOpened) {
        lastOpenTime = TimeCurrent(); 
    }
}

// Create an arrow on the chart
void CreateArrow(string name, datetime time, double price, color clr, int arrowCode) { 
    if (ObjectCreate(0, name, OBJ_ARROW, 0, time, price)) { 
        ObjectSetInteger(0, name, OBJPROP_COLOR, clr); 
        ObjectSetInteger(0, name, OBJPROP_ARROWCODE, arrowCode);  
        ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);  
    } else { 
        Print("Error creating arrow on chart: ", name); 
    } 
}

// Calculate EMA 21 for specified symbol and timeframe
double GetEMA21(string symbol, ENUM_TIMEFRAMES timeframe) { 
    double emaBuffer[]; 
    if (CopyBuffer(iMA(symbol, timeframe, EMA_PERIOD, 0, MODE_EMA, PRICE_CLOSE), 0, 0, 1, emaBuffer) < 0) { 
        Print("Error copying EMA buffer: ", GetLastError()); 
        return 0.0; 
    } 
    return emaBuffer[0]; 
}

// Check if there is an open position 
bool IsPositionOpen() { 
    for (int i = 0; i < PositionsTotal(); i++) { 
        if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) { 
            return true; 
        } 
    } 
    return false; 
}

// Check for bullish engulfing pattern
bool IsBullishEngulfing(string symbol, ENUM_TIMEFRAMES timeframe, int index) { 
    double prevOpen = iOpen(symbol, timeframe, index + 1); 
    double prevClose = iClose(symbol, timeframe, index + 1); 
    double currentOpen = iOpen(symbol, timeframe, index); 
    double currentClose = iClose(symbol, timeframe, index); 
    return (prevClose < prevOpen && currentClose > currentOpen && 
            currentOpen < prevClose && currentClose > prevOpen); 
}

// Check for bearish engulfing pattern
bool IsBearishEngulfing(string symbol, ENUM_TIMEFRAMES timeframe, int index) { 
    double prevOpen = iOpen(symbol, timeframe, index + 1); 
    double prevClose = iClose(symbol, timeframe, index + 1); 
    double currentOpen = iOpen(symbol, timeframe, index); 
    double currentClose = iClose(symbol, timeframe, index); 
    return (prevClose > prevOpen && currentClose < currentOpen && 
            currentOpen > prevClose && currentClose < prevOpen); 
}

// Function to calculate the average body length of the last five Heikin Ashi candles
double CalculateAverageHABodyLength(string symbol, ENUM_TIMEFRAMES timeframe) {
    double sumBodyLength = 0.0;

    for (int i = 1; i <= 5; i++) {
        double haClose = (iOpen(symbol, timeframe, i) + iClose(symbol, timeframe, i) + 
                          iHigh(symbol, timeframe, i) + iLow(symbol, timeframe, i)) / 4;
        double haOpen = (iOpen(symbol, timeframe, i + 1) + haClose) / 2;
        sumBodyLength += MathAbs(haClose - haOpen);
    }
    
    return sumBodyLength / 5;
}


void ScanForEngulfingPatterns() {
    string symbol = Symbol();
    ENUM_TIMEFRAMES timeframe = Period();
    double ema21 = GetEMA21(symbol, timeframe);
    int bars = iBars(symbol, timeframe);

    for (int i = 1; i < bars - 1; i++) {
        datetime barTime = iTime(symbol, timeframe, i);

        if (IsBullishEngulfing(symbol, timeframe, i)) {
            Print("Bullish engulfing pattern detected for ", symbol, " at ", TimeToString(barTime, TIME_DATE | TIME_MINUTES));
        }

        if (IsBearishEngulfing(symbol, timeframe, i)) {
            Print("Bearish engulfing pattern detected for ", symbol, " at ", TimeToString(barTime, TIME_DATE | TIME_MINUTES));
        }
    }
}

bool AreLastFiveCandlesBullish(string symbol, ENUM_TIMEFRAMES timeframe) {
    for (int i = 1; i <= 5; i++) {
        if (iClose(symbol, timeframe, i) <= iOpen(symbol, timeframe, i)) {
            return false;
        }
    }
    return true;
}


void FlagCandlesWithArrows() {
    string symbol = Symbol();
    ENUM_TIMEFRAMES timeframe = Period();
    double ema21 = GetEMA21(symbol, timeframe);
    int bars = iBars(symbol, timeframe);
    UpdateLastOpenTime();

    int addOnCounter = 0;
    double lastHeikinHigh = 0.0;

    for (int i = 5; i < bars; i++) { 
        double closePrice = iClose(symbol, timeframe, i);
        double openPrice = iOpen(symbol, timeframe, i);
        datetime barTime = iTime(symbol, timeframe, i);

        double haClose = (openPrice + closePrice + iHigh(symbol, timeframe, i) + iLow(symbol, timeframe, i)) / 4;
        double haOpen = (iOpen(symbol, timeframe, i + 1) + haClose) / 2;
        double haLength = MathAbs(haClose - haOpen);

        double avgHABodyLength = CalculateAverageHABodyLength(symbol, timeframe);

        Print("Current Candle Index: ", i, " HA Body Length: ", haLength, " Avg HA Body Length: ", avgHABodyLength);

        if (barTime > lastStartTime && closePrice > openPrice &&
            closePrice > ema21 && haLength > 2 * avgHABodyLength &&
            haClose > ema21 && AreLastFiveCandlesBullish(symbol, timeframe) &&
            !IsPositionOpen()) {
            Print("Position opened at ", TimeToString(barTime, TIME_DATE | TIME_MINUTES));
            UpdateLastOpenTime();
            addOnCounter = 0;
        }

        if (IsPositionOpen() && haClose > lastHeikinHigh && closePrice > lastPositionClosePrice) {
            addOnCounter++;
            Print("Add-on position opened at ", TimeToString(barTime, TIME_DATE | TIME_MINUTES));
            lastPositionClosePrice = closePrice;
        }

        lastHeikinHigh = haClose;

        if (addOnCounter >= 5 || haClose < ema21 || closePrice < ema21 || haClose < haOpen) {
            Print("Exit triggered at ", TimeToString(barTime, TIME_DATE | TIME_MINUTES));
            CloseAllPositions();
            hasClosedPosition = true;
            break;
        }
    }
}




void OnTick() { 
    string symbol = Symbol();
    ENUM_TIMEFRAMES timeframe = Period();
    int bars = iBars(symbol, timeframe);
    
    for (int i = 5; i < bars; i++) { 
       
        lastCandleTime = iTime(symbol, timeframe, i);  
        ScanForEngulfingPatterns();
        FlagCandlesWithArrows();
    }
}

// Close all positions function
void CloseAllPositions() { 
    MqlTradeRequest closeRequest = {}; 
    MqlTradeResult closeResult = {}; 

    for (int i = 0; i < PositionsTotal(); i++) { 
        if (PositionSelectByTicket(PositionGetTicket(i))) { 
            // Close the position
            closeRequest.action = TRADE_ACTION_DEAL; 
            closeRequest.symbol = PositionGetString(POSITION_SYMBOL); 
            closeRequest.volume = PositionGetDouble(POSITION_VOLUME); 
            closeRequest.type = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? ORDER_TYPE_SELL : ORDER_TYPE_BUY; 
            closeRequest.price = SymbolInfoDouble(closeRequest.symbol, closeRequest.type == ORDER_TYPE_SELL ? SYMBOL_BID : SYMBOL_ASK); 
            closeRequest.deviation = 10; 
            closeRequest.type_filling = ORDER_FILLING_FOK; 
            closeRequest.comment = "Close Position"; 

            if (OrderSend(closeRequest, closeResult)) { 
                Print("Position closed. Order number: ", closeResult.order); 
            } else { 
                Print("Failed to close position. Error code: ", GetLastError()); 
            } 
        } 
    } 
}
