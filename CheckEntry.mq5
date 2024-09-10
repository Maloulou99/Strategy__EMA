//+------------------------------------------------------------------+
//|                                       CheckEntry.mq5           |
//|                      Displays EMA20 and EMA50 Indicators          |
//|                and generates buy signals on crossovers          |
//|                 and ignores signals when EMA50 crosses EMA20    |
//+------------------------------------------------------------------+
#property indicator_chart_window // Display the indicator in the main chart window
#property indicator_buffers 2    // Number of indicator buffers
#property indicator_plots 2      // Number of indicator plots

//--- indicator buffers
double EMA20Buffer[];
double EMA50Buffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                        |
//+------------------------------------------------------------------+
void OnInit()
{
    // Set the buffers to the indicators
    SetIndexBuffer(0, EMA20Buffer);
    SetIndexBuffer(1, EMA50Buffer);

    // Set properties for EMA20 plot
    PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_LINE);     // Draw as a line
    PlotIndexSetInteger(0, PLOT_LINE_STYLE, STYLE_SOLID);   // Solid line style
    PlotIndexSetInteger(0, PLOT_LINE_COLOR, clrBlue);        // Blue color for EMA20
    PlotIndexSetInteger(0, PLOT_LINE_WIDTH, 2);             // Line width: 2 pixels
    PlotIndexSetString(0, PLOT_LABEL, "EMA20");              // Label for EMA20

    // Set properties for EMA50 plot
    PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_LINE);     // Draw as a line
    PlotIndexSetInteger(1, PLOT_LINE_STYLE, STYLE_DOT);     // Dotted line style for EMA50
    PlotIndexSetInteger(1, PLOT_LINE_COLOR, clrRed);        // Red color for EMA50
    PlotIndexSetInteger(1, PLOT_LINE_WIDTH, 2);             // Line width: 2 pixels
    PlotIndexSetString(1, PLOT_LABEL, "EMA50");              // Label for EMA50

    // Initialization complete
    Print("EMA Indicator initialized.");
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                             |
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
    // Ensure there are enough bars to perform calculations
    if (rates_total < 50)
        return 0;

    // Calculate EMA20 and EMA50 using CopyBuffer for more accurate results
    int handleEMA20 = iMA(NULL,                // Current symbol
                          PERIOD_H1,          // Timeframe (H1)
                          20,                 // EMA period (20)
                          0,                  // No shift
                          MODE_EMA,           // Exponential Moving Average
                          PRICE_CLOSE);       // Apply to close price

    int handleEMA50 = iMA(NULL,                // Current symbol
                          PERIOD_H1,          // Timeframe (H1)
                          50,                 // EMA period (50)
                          0,                  // No shift
                          MODE_EMA,           // Exponential Moving Average
                          PRICE_CLOSE);       // Apply to close price

    // Check if handles are valid
    if (handleEMA20 == INVALID_HANDLE || handleEMA50 == INVALID_HANDLE)
    {
        Print("Failed to create indicator handles.");
        return 0;
    }

    // Copy EMA values into buffers
    if (CopyBuffer(handleEMA20, 0, 0, rates_total, EMA20Buffer) == -1 ||
        CopyBuffer(handleEMA50, 0, 0, rates_total, EMA50Buffer) == -1)
    {
        Print("Failed to copy buffer data.");
        return 0;
    }

    // Release the handles
    IndicatorRelease(handleEMA20);
    IndicatorRelease(handleEMA50);

    // Check for crossovers and generate signals
    for (int i = 1; i < rates_total; i++)
    {
        // Check for crossover between EMA20 and EMA50
        if (EMA20Buffer[i] > EMA50Buffer[i] && EMA20Buffer[i - 1] <= EMA50Buffer[i - 1])
        {
            // EMA20 crossed above EMA50 (buy signal)
            Print("Buy signal (EMA20 crossed above EMA50) at bar ", i);
            // Add your custom logic to handle buy signal here (e.g., send alert, log, etc.)
        }
        else if (EMA20Buffer[i] < EMA50Buffer[i] && EMA20Buffer[i - 1] >= EMA50Buffer[i - 1])
        {
            // EMA50 crossed above EMA20 (ignored)
            Print("Ignored signal (EMA50 crossed above EMA20) at bar ", i);
            // No action needed for this case
        }
    }

    // Return the number of bars processed
    return rates_total;
}
