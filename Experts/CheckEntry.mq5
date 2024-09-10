//+------------------------------------------------------------------+
//|                                                   CheckEntry.mq5 |
//|                Displays EMA20 and EMA50 Indicators               |
//|              and generates buy signals on crossovers             |
//|          Handles changes in symbol and timeframe automatically   |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 2

#include <TradeManager.mqh>
#include <EMAHandler.mqh>
#include <SymbolTimeframeManager.mqh>

// Indicator buffers
double EMA20Buffer[];
double EMA50Buffer[];

// Instances of handler classes
EMAHandler emaHandler;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                        |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize EMA handles for the current symbol and period
    emaHandler.Initialize(Symbol(), Period());

    // Set indicator buffers
    SetIndexBuffer(0, EMA20Buffer);
    SetIndexBuffer(1, EMA50Buffer);


    // Set properties for EMA plots
    PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_LINE);
    PlotIndexSetInteger(0, PLOT_LINE_STYLE, STYLE_SOLID);
    PlotIndexSetInteger(0, PLOT_LINE_COLOR, clrBlue);
    PlotIndexSetInteger(0, PLOT_LINE_WIDTH, 2);
    PlotIndexSetString(0, PLOT_LABEL, "EMA20");

    PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_LINE);
    PlotIndexSetInteger(1, PLOT_LINE_STYLE, STYLE_DOT);
    PlotIndexSetInteger(1, PLOT_LINE_COLOR, clrRed);
    PlotIndexSetInteger(1, PLOT_LINE_WIDTH, 2);
    PlotIndexSetString(1, PLOT_LABEL, "EMA50");
   

    Print("EMA Indicator initialized.");
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                             |
//+------------------------------------------------------------------+

datetime lastOrderTime = 0;
int minIntervalBetweenOrders = 500; 

bool lastCrossoverWasBullish = false;
bool lastCrossoverWasBearish = false;

void OnTick()
{
    // Update EMA buffers
    if (CopyBuffer(emaHandler.handleEMA20, 0, 0, 2, EMA20Buffer) <= 0 ||
        CopyBuffer(emaHandler.handleEMA50, 0, 0, 2, EMA50Buffer) <= 0)
    {
        Print("Failed to copy EMA buffers. Error code: ", GetLastError());
        return;
    }

    // Get the latest EMA values
    double emaValue20Current = EMA20Buffer[0];
    double emaValue50Current = EMA50Buffer[0];
    double emaValue20Previous = EMA20Buffer[1];
    double emaValue50Previous = EMA50Buffer[1];

    // Get current prices
    double askPrice = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    double bidPrice = SymbolInfoDouble(Symbol(), SYMBOL_BID);

    // Check existing positions
    long totalPositions = PositionsTotal();
    bool hasLongPosition = false;
    bool hasShortPosition = false;

    for (int i = 0; i < totalPositions; i++)
    {
        if (PositionSelect(i))  // Correct position selection
        {
            int posType = PositionGetInteger(POSITION_TYPE);
            if (posType == POSITION_TYPE_BUY)
                hasLongPosition = true;
            if (posType == POSITION_TYPE_SELL)
                hasShortPosition = true;
        }
    }

    // Check if there is enough time between orders
    if (TimeCurrent() - lastOrderTime < minIntervalBetweenOrders)
    {
        return; // Skip this tick if not enough time has passed
    }

    // Determine crossovers
    bool isBearishCrossover = emaValue20Previous < emaValue50Previous && emaValue20Current > emaValue50Current; 
    bool isBullishCrossover = emaValue20Previous > emaValue50Previous && emaValue20Current < emaValue50Current; 

    // Handle bearish crossover (SELL)
    if (isBearishCrossover)
    {
        if (!hasShortPosition && CheckMoney(ORDER_TYPE_SELL, 1.0, bidPrice))
        {
            Print("Bearish crossover detected. Closing all positions and opening a SELL order.");
            CloseAllPositions(); // Close all positions before opening a new one
            OpenPosition(ORDER_TYPE_SELL, 1.0, bidPrice, "EMA Bearish Crossover Sell");
            lastOrderTime = TimeCurrent();  // Update last order time
        }
    }

    // Handle bullish crossover (BUY)
    if (isBullishCrossover)
    {
        if (!hasLongPosition && CheckMoney(ORDER_TYPE_BUY, 1.0, askPrice))
        {
            Print("Bullish crossover detected. Closing all positions and opening a BUY order.");
            CloseAllPositions(); // Close all positions before opening a new one
            OpenPosition(ORDER_TYPE_BUY, 1.0, askPrice, "EMA Bullish Crossover Buy");
            lastOrderTime = TimeCurrent();  // Update last order time
        }
    }
}



// Function to close all positions
void CloseAllPositions()
{
    long totalPositions = PositionsTotal();
    for (int i = totalPositions - 1; i >= 0; i--)
    {
        if (PositionSelect(i))
        {
            int posType = PositionGetInteger(POSITION_TYPE);
            double volume = PositionGetDouble(POSITION_VOLUME);
            double price = posType == POSITION_TYPE_BUY ? SymbolInfoDouble(Symbol(), SYMBOL_BID) : SymbolInfoDouble(Symbol(), SYMBOL_ASK);
            
            // Variable to store the order number
            ulong orderNumber = 0;

            // Close the position
            bool result = ClosePosition(posType, volume, price, posType == POSITION_TYPE_BUY ? "Close Long Position" : "Close Short Position", orderNumber);

            if (!result)
            {
                Print("Failed to close position. Error code: ", GetLastError());
            }
            else
            {
                Print("Closed position with order number: ", orderNumber);
            }
        }
    }
}



// Function to open a position
void OpenPosition(int orderType, double volume, double price, string comment)
{
    MqlTradeRequest tradeRequest = {};
    MqlTradeResult tradeResult = {};

    tradeRequest.action = TRADE_ACTION_DEAL;
    tradeRequest.symbol = Symbol();
    tradeRequest.volume = volume;
    tradeRequest.type = orderType;
    tradeRequest.price = price;
    tradeRequest.deviation = 10;
    tradeRequest.comment = comment;

    if (OrderSend(tradeRequest, tradeResult))
    {
        Print(comment, ". Order #", tradeResult.order);
    }
    else
    {
        Print("Error during ", comment, ": ", GetLastError());
    }
}

// Function to close a position
bool ClosePosition(int posType, double volume, double price, string comment, ulong &orderNumber)
{
    MqlTradeRequest closeRequest = {};
    MqlTradeResult closeResult = {};

    // Fill the trade request structure
    closeRequest.action = TRADE_ACTION_DEAL;
    closeRequest.symbol = Symbol();
    closeRequest.volume = volume;
    closeRequest.type = posType == POSITION_TYPE_BUY ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
    closeRequest.price = price;
    closeRequest.deviation = 10;
    closeRequest.comment = comment;

    // Send the trade request
    if (OrderSend(closeRequest, closeResult))
    {
        orderNumber = closeResult.order;  // Get the order number
        double profit = CalculateProfit(PositionGetDouble(POSITION_PRICE_OPEN), price, volume, posType);
        string profitString = StringFormat("%.2f", profit);
        Print(comment, ". Order #", orderNumber, ". Profit: ", profitString);
        return true;
    }
    else
    {
        Print("Error closing position: ", GetLastError());
        return false;
    }
}


// Function to calculate profit
double CalculateProfit(double openPrice, double closePrice, double volume, int posType)
{
    double profit = 0.0;
    double pointSize = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
    double contractSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
    
    if (posType == POSITION_TYPE_BUY)
    {
        profit = (closePrice - openPrice) / pointSize * volume * contractSize;
    }
    else if (posType == POSITION_TYPE_SELL)
    {
        profit = (openPrice - closePrice) / pointSize * volume * contractSize;
    }
    
    return profit;
}


// Function to check if there's enough money for a trade
bool CheckMoney(int orderType, double volume, double price)
{
    double margin;
    if (!OrderCalcMargin(ENUM_ORDER_TYPE(), Symbol(), volume, price, margin))
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
