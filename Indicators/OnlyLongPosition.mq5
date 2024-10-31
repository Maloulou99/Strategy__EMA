//+------------------------------------------------------------------------+
//|                                                   OnlyLongPosition.mq5 |
//|                Displays EMA20 and EMA50 Indicators                     |
//|              and generates buy signals on crossovers                   |
//|          Handles changes in symbol and timeframe automatically         |
//+------------------------------------------------------------------------+

#include <Symbole.mqh>

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 2

#property indicator_label1 "EMA20"
#property indicator_type1 DRAW_LINE
#property indicator_color1 clrRed
#property indicator_width1 2

#property indicator_label2 "EMA50"
#property indicator_type2 DRAW_LINE
#property indicator_color2 clrBlue
#property indicator_width2 2

// Indicator buffers
double EMA20Buffer[];
double EMA50Buffer[];

int handleEMA20, handleEMA50;
datetime lastOrderTime = 0;
int minIntervalBetweenOrders = 100;
double tolerance = 0.01;  // Tolerance for crossover detection (adjust as needed)

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize EMA handles for the current symbol and period
    handleEMA20 = iMA(Symbol(), 0, 20, 0, MODE_EMA, PRICE_CLOSE);
    handleEMA50 = iMA(Symbol(), 0, 50, 0, MODE_EMA, PRICE_CLOSE);

    if (handleEMA20 == INVALID_HANDLE || handleEMA50 == INVALID_HANDLE)
    {
        Print("Failed to initialize EMA handles. Error code: ", GetLastError());
        return(INIT_FAILED);
    }

    // Set indicator buffers
    SetIndexBuffer(0, EMA20Buffer);
    SetIndexBuffer(1, EMA50Buffer);

    Print("EMA Indicator initialized.");
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated,
                const datetime &time[], const double &open[], const double &high[],
                const double &low[], const double &close[], const long &tick_volume[],
                const long &volume[], const int &spread[])
{
    // Ensure there's enough data
    if (rates_total < 50)  // Ensure at least 50 bars for EMA50
    {
        Print("Not enough data. Total rates: ", rates_total);
        return 0;
    }

    // Update EMA buffers
    if (CopyBuffer(handleEMA20, 0, 0, rates_total, EMA20Buffer) <= 0 ||
        CopyBuffer(handleEMA50, 0, 0, rates_total, EMA50Buffer) <= 0)
    {
        Print("Failed to copy EMA buffers. Error code: ", GetLastError());
        return 0;
    }

    // Ensure buffers have data
    if (ArraySize(EMA20Buffer) < rates_total || ArraySize(EMA50Buffer) < rates_total)
    {
        Print("Buffer size mismatch. EMA20Buffer size: ", ArraySize(EMA20Buffer), ", EMA50Buffer size: ", ArraySize(EMA50Buffer));
        return 0;
    }

    return rates_total;
}

//+------------------------------------------------------------------+
//| OnTick function to handle trading logic                          |
//+------------------------------------------------------------------+
void OnTick()
{
    // Update tolerance and minIntervalBetweenOrders based on timeframe
    tolerance = GetAdjustedTolerance();
    minIntervalBetweenOrders = GetAdjustedInterval();

    // Update EMA buffers for the current and previous values
    if (CopyBuffer(handleEMA20, 0, 0, 2, EMA20Buffer) <= 0 ||
        CopyBuffer(handleEMA50, 0, 0, 2, EMA50Buffer) <= 0)
    {
        Print("Failed to copy EMA buffers. Error code: ", GetLastError());
        return;
    }

    // Get the latest EMA values
    double emaValue20Current = EMA20Buffer[0];
    double emaValue50Current = EMA50Buffer[0];
    double emaValue20Previous = EMA20Buffer[1];
    double emaValue50Previous = EMA50Buffer[1];

    // Check for approximate bullish crossover using tolerance
    bool isBullishCrossover = (MathAbs(emaValue20Current - emaValue50Current) <= tolerance) && 
                              (emaValue20Previous > emaValue50Previous) && 
                              (emaValue20Current < emaValue50Current);


    // Get current prices for trading logic
    double askPrice = SymbolInfoDouble(Symbol(), SYMBOL_ASK);

    // Check existing positions
    long totalPositions = PositionsTotal();
    bool hasLongPosition = false;

    for (int i = 0; i < totalPositions; i++)
    {
        if (PositionSelect(i))
        {
            int posType = (int)PositionGetInteger(POSITION_TYPE);
            if (posType == POSITION_TYPE_BUY)
                hasLongPosition = true;
        }
    }

    // Check if there is enough time between orders
    if (TimeCurrent() - lastOrderTime < minIntervalBetweenOrders)
    {
        return; // Skip this tick if not enough time has passed
    }

    // Handle bullish crossover (BUY)
    if (isBullishCrossover)
    {
        if (!hasLongPosition && CheckMoney(ORDER_TYPE_BUY, 1.0, askPrice))
        {
            Print("Bullish crossover detected. Opening a BUY order.");
            OpenPosition(ORDER_TYPE_BUY, 1.0, askPrice, "EMA Bullish Crossover Buy");
            lastOrderTime = TimeCurrent();
        }
    }
}

// Function to check if there's enough money for a trade
bool CheckMoney(ENUM_ORDER_TYPE orderType, double volume, double price)
{
    double margin = 0.0;  // Initialize margin
    if (!OrderCalcMargin(orderType, Symbol(), volume, price, margin))
    {
        Print("Error calculating margin: ", GetLastError());
        return false;
    }

    if (AccountInfoDouble(ACCOUNT_FREEMARGIN) >= margin)
    {
        return true;
    }
    else
    {
        Print("Not enough margin.");
        return false;
    }
}

// Function to open a position
void OpenPosition(ENUM_ORDER_TYPE orderType, double volume, double price, string comment)
{
    MqlTradeRequest tradeRequest = {};
    MqlTradeResult tradeResult = {};

    tradeRequest.action = TRADE_ACTION_DEAL;
    tradeRequest.symbol = Symbol();
    tradeRequest.volume = volume;
    tradeRequest.type = orderType;
    tradeRequest.price = price;
    tradeRequest.deviation = 10;
    tradeRequest.comment = "";

    if (OrderSend(tradeRequest, tradeResult))
    {
        Print(comment, ". Order #", IntegerToString(tradeResult.order));
    }
    else
    {
        Print("Error during ", comment, ": ", GetLastError());
    }
}

// Function to close a position (only for long positions)
bool ClosePosition(int posType, double volume, double price, string comment, ulong &orderNumber)
{
    MqlTradeRequest closeRequest = {};
    MqlTradeResult closeResult = {};

    closeRequest.action = TRADE_ACTION_DEAL;
    closeRequest.symbol = Symbol();
    closeRequest.volume = volume;
    closeRequest.type = ORDER_TYPE_BUY;  // Only buy positions are closed
    closeRequest.price = price;
    closeRequest.deviation = 10;
    closeRequest.comment = comment;

    if (OrderSend(closeRequest, closeResult))
    {
        orderNumber = closeResult.order;
        Print(comment, ". Closed order #", IntegerToString(closeResult.order));
        return true;
    }
    else
    {
        Print("Error closing position: ", GetLastError());
        return false;
    }
}

// Function to close all open long positions
void CloseAllPositions()
{
    int totalPositions = PositionsTotal();
    for (int i = totalPositions - 1; i >= 0; i--)
    {
        if (PositionSelect(i))
        {
            int posType = (int)PositionGetInteger(POSITION_TYPE);
            if (posType == POSITION_TYPE_BUY)  // Only close long positions
            {
                double volume = PositionGetDouble(POSITION_VOLUME);
                double price = SymbolInfoDouble(Symbol(), SYMBOL_BID); // Always sell at bid price

                ulong orderNumber = 0;
                bool result = ClosePosition(posType, volume, price, "Close Long Position", orderNumber);

                if (!result)
                {
                    Print("Failed to close position. Error code: ", GetLastError());
                }
            }
        }
    }
}
