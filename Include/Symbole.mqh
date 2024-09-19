#ifndef __SYMBOLE__H
#define __SYMBOLE__H

class Symbole
{
private:
    string lastSymbol;
    ENUM_TIMEFRAMES lastTimeframe;

public:
    Symbole() : lastSymbol(""), lastTimeframe(PERIOD_CURRENT) 
    {
    }

    void Initialize()
    {
        lastSymbol = Symbol();
        lastTimeframe = Period();

        Print("Initialization complete: Symbol = ", lastSymbol, ", Timeframe = ", lastTimeframe);
    }

    bool CheckSymbolOrTimeframeChange()
    {
        string currentSymbol = Symbol();
        ENUM_TIMEFRAMES currentTimeframe = Period();

        if (lastSymbol != currentSymbol || lastTimeframe != currentTimeframe)
        {
            lastSymbol = currentSymbol;
            lastTimeframe = currentTimeframe;

            Print("Symbol or Timeframe changed to ", lastSymbol, " and timeframe ", EnumToString(lastTimeframe));

            return true;
        }

        return false;
    }

    void HandleNewSymbolOrTimeframe()
    {
        if (CheckSymbolOrTimeframeChange())
        {
            Print("Handling new symbol or timeframe: ", lastSymbol, ", Timeframe: ", EnumToString(lastTimeframe));
        }
    }
};

// Function to get adjusted tolerance based on timeframe
double GetAdjustedTolerance()
{
    ENUM_TIMEFRAMES timeframe = Period();
    double tolerance;

    switch (timeframe)
    {
        case PERIOD_M1:   tolerance = 0.01; break;
        case PERIOD_M2:   tolerance = 0.025; break;
        case PERIOD_M5:   tolerance = 0.05; break;
        case PERIOD_M15:  tolerance = 0.1; break;
        case PERIOD_M30:  tolerance = 0.2; break;
        case PERIOD_H1:   tolerance = 0.5; break;
        case PERIOD_H2:   tolerance = 0.8; break;
        case PERIOD_H4:   tolerance = 1.0; break;
        case PERIOD_D1:   tolerance = 2.0; break;
        case PERIOD_W1:   tolerance = 5.0; break;
        default:          tolerance = 0.01; break;
    }

    return tolerance;
}

// Function to get adjusted interval based on timeframe
int GetAdjustedInterval()
{
    ENUM_TIMEFRAMES timeframe = Period();
    int interval;

    switch (timeframe)
    {
        case PERIOD_M1:   interval = 1000;   break;
        case PERIOD_M5:   interval = 5000;   break;
        case PERIOD_M15:  interval = 15000;  break;
        case PERIOD_M30:  interval = 20000;  break;
        case PERIOD_H1:   interval = 40000;  break;
        case PERIOD_H2:   interval = 50000; break;
        case PERIOD_H4:   interval = 60000;  break;
        case PERIOD_D1:   interval = 1440000; break;
        case PERIOD_W1:   interval = 10080000; break;
        default:          interval = 1000;  break;
    }

    return interval;
}

#endif
