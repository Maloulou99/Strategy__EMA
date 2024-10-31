//+------------------------------------------------------------------+
//|                                             simpleHeikenAshi.mq5 | 
//|                                  Copyright 2023, MetaQuotes Ltd. | 
//|                                             https://www.mql5.com | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
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

double haOpen[];
double haHigh[];
double haLow[];
double haClose[];
double haColor[];
double ema21[]; 

int OnInit()
{
    SetIndexBuffer(0, haOpen, INDICATOR_DATA);
    SetIndexBuffer(1, haHigh, INDICATOR_DATA);
    SetIndexBuffer(2, haLow, INDICATOR_DATA);
    SetIndexBuffer(3, haClose, INDICATOR_DATA);
    SetIndexBuffer(4, haColor, INDICATOR_COLOR_INDEX);
    SetIndexBuffer(5, ema21, INDICATOR_DATA); 
    IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
    IndicatorSetString(INDICATOR_SHORTNAME, "Simple Heiken Ashi with EMA 21");
    PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
    return(INIT_SUCCEEDED);
}

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
    int start;
    if (prev_calculated == 0)
    {
        haLow[0] = low[0];
        haHigh[0] = high[0];
        haOpen[0] = open[0];
        haClose[0] = close[0];
        ema21[0] = close[0]; 
        start = 1;
    }
    else
        start = prev_calculated - 1;

    for (int i = start; i < rates_total && !IsStopped(); i++)
    {
        double haOpenVal = (haOpen[i - 1] + haClose[i - 1]) / 2;
        double haCloseVal = (open[i] + high[i] + low[i] + close[i]) / 4;
        double haHighVal = MathMax(high[i], MathMax(haOpenVal, haCloseVal));
        double haLowVal = MathMin(low[i], MathMin(haOpenVal, haCloseVal));

        haLow[i] = haLowVal;
        haHigh[i] = haHighVal;
        haOpen[i] = haOpenVal;
        haClose[i] = haCloseVal;
        haColor[i] = (haOpenVal < haCloseVal) ? 0.0 : 1.0;

        if (i == 1) 
        {
            ema21[i] = close[i]; 
        }
        else
        {
            double alpha = 2.0 / (21 + 1); 
            ema21[i] = (close[i] * alpha) + (ema21[i - 1] * (1 - alpha));
        }
    }

    // Call the average body length function here if needed
    double avgBodyLength = CalculateAverageHAHBodyLength(rates_total);
    Print("Average Body Length of last 5 Heikin Ashi candles: ", avgBodyLength);

    return (rates_total);
}

// Calculate the average body length of the last five Heikin Ashi candles
double CalculateAverageHAHBodyLength(int rates_total) {
    if (rates_total < 6) return 0.0;

    double sumBodyLength = 0.0;

    for (int i = 1; i <= 5; i++) {
        double haOpen = (haOpen[rates_total - i - 1] + haClose[rates_total - i - 1]) / 2; 
        double haClose = (haClose[rates_total - i - 1]); 
        sumBodyLength += MathAbs(haClose - haOpen);
    }

    return sumBodyLength / 5; 
}
