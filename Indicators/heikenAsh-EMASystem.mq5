//+------------------------------------------------------------------+
//|                                          heikenAsh-EMASystem.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com | 
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots 1

#property indicator_label1 "EMA21"
#property indicator_type1 DRAW_LINE
#property indicator_color1 clrBlue    
#property indicator_width1 1

input int EMA_Period = 21; 
double EMA21Buffer[];  // Buffer for EMA values
int handleEMA21;  // Handle for EMA
int heikenAshi;   // Handle for Heiken Ashi

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    heikenAshi = iCustom(_Symbol, _Period, "Indicators\\simpleHeikenAshi");
    handleEMA21 = iMA(Symbol(), 0, EMA_Period, 0, MODE_EMA, PRICE_CLOSE);
    
    if (handleEMA21 == INVALID_HANDLE)
    {
        Print("Failed to initialize EMA handle. Error code: ", GetLastError());
        return(INIT_FAILED);
    }

    SetIndexBuffer(0, EMA21Buffer);
    ArraySetAsSeries(EMA21Buffer, true);  // Set buffer as series
    Print("Heiken Ashi-EMA System initialized successfully.");
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Release handles to avoid memory leaks
    if (handleEMA21 != INVALID_HANDLE)
        IndicatorRelease(handleEMA21);

    if (heikenAshi != INVALID_HANDLE)
        IndicatorRelease(heikenAshi);
    
    Print("Heiken Ashi-EMA System Removed");
}

//+------------------------------------------------------------------+
//| Indicator calculate function                                      |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    int copied = CopyBuffer(handleEMA21, 0, 0, rates_total, EMA21Buffer);
    if (copied < 0)
    {
        Print("Failed to copy EMA buffer. Error code: ", GetLastError());
    }

    // Retrieve Heiken Ashi values
    double heikenAshiOpen[], heikenAshiHigh[], heikenAshiLow[], heikenAshiClose[];
    CopyBuffer(heikenAshi, 0, 0, rates_total, heikenAshiOpen);
    CopyBuffer(heikenAshi, 1, 0, rates_total, heikenAshiHigh);
    CopyBuffer(heikenAshi, 2, 0, rates_total, heikenAshiLow);
    CopyBuffer(heikenAshi, 3, 0, rates_total, heikenAshiClose);
    
    // You can implement any additional logic using the Heiken Ashi values here

    return rates_total; // Return the number of processed bars
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Logic for OnTick if needed
    // For now, you can keep it empty or implement trading logic
}

//+------------------------------------------------------------------+
//| Get Heiken Ashi Open                                            |
//+------------------------------------------------------------------+
double GetHAOpen(int shift) {
    // Implement your logic for Heiken Ashi Open
    return 0; // Placeholder
}

//+------------------------------------------------------------------+
//| Get Heiken Ashi Close                                           |
//+------------------------------------------------------------------+
double GetHAClose(int shift) {
    // Implement your logic for Heiken Ashi Close
    return 0; // Placeholder
}

//+------------------------------------------------------------------+
//| Get EMA Value                                                   |
//+------------------------------------------------------------------+
double GetEMA(int shift) {
    if (shift < ArraySize(EMA21Buffer)) {
        return EMA21Buffer[shift];
    }
    return 0;
}
