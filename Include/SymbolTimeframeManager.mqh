#ifndef __SYMBOLTIMEFRAMEMANAGER__H
#define __SYMBOLTIMEFRAMEMANAGER__H

class SymbolTimeframeManager
{
private:
    string lastSymbol;
    ENUM_TIMEFRAMES lastTimeframe;

public:
    SymbolTimeframeManager() : lastSymbol(""), lastTimeframe(0)
    {
    }

    void Initialize()
    {
        lastSymbol = Symbol();
        lastTimeframe = Period();
    }

    void CheckSymbolOrTimeframeChange()
    {
        if (lastSymbol != Symbol() || lastTimeframe != Period())
        {
            lastSymbol = Symbol();
            lastTimeframe = Period();
            
            Print("Symbol or Timeframe changed to ", lastSymbol, " and ", lastTimeframe);
        }
    }
};

#endif
