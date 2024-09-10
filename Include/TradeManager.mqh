#ifndef __TRADEMANAGER__H
#define __TRADEMANAGER__H

class TradeManager
{
public:
    int emaHandle1, emaHandle2;
    double emaBuffer1[], emaBuffer2[];
    bool orderSent;
    datetime lastSignalTime;
    datetime lastOrderTime;
    string currentSymbol;
    int currentPeriod;

    TradeManager()
    {
        orderSent = false;
        lastSignalTime = 0;
        lastOrderTime = 0;
        currentSymbol = "";
        currentPeriod = 0;
    }

    int OnInit()
    {
        currentSymbol = Symbol();
        currentPeriod = Period();
        emaHandle1 = iMA(currentSymbol, 0, 20, 0, MODE_EMA, PRICE_CLOSE);
        emaHandle2 = iMA(currentSymbol, 0, 50, 0, MODE_EMA, PRICE_CLOSE);
        Print("TradeManager initialized.");
        return(INIT_SUCCEEDED);
    }

    void OnDeinit(const int reason)
    {
        if (emaHandle1 != INVALID_HANDLE)
        {
            IndicatorRelease(emaHandle1);
            emaHandle1 = INVALID_HANDLE;
        }
        if (emaHandle2 != INVALID_HANDLE)
        {
            IndicatorRelease(emaHandle2);
            emaHandle2 = INVALID_HANDLE;
        }
        Print("TradeManager deinitialized.");
    }

};

#endif
