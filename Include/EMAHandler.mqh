#ifndef __EMA_HANDLER__H
#define __EMA_HANDLER__H

class EMAHandler
{
public:
    int handleEMA20, handleEMA50;

    EMAHandler() : handleEMA20(INVALID_HANDLE), handleEMA50(INVALID_HANDLE) {}

    void Initialize(string symbol, int period)
    {
        handleEMA20 = iMA(symbol, 0, 20, 0, MODE_EMA, PRICE_CLOSE);
        handleEMA50 = iMA(symbol, 0, 50, 0, MODE_EMA, PRICE_CLOSE);
    }

    void UpdateEMABuffers(int rates_total, double &EMA20Buffer[], double &EMA50Buffer[])
    {
        if (CopyBuffer(handleEMA20, 0, 0, rates_total, EMA20Buffer) <= 0 ||
            CopyBuffer(handleEMA50, 0, 0, rates_total, EMA50Buffer) <= 0)
        {
            Print("Error updating EMA buffers: ", GetLastError());
        }
    }

    void ReleaseEMA()
    {
        if (handleEMA20 != INVALID_HANDLE)
            IndicatorRelease(handleEMA20);
        if (handleEMA50 != INVALID_HANDLE)
            IndicatorRelease(handleEMA50);
    }
};

#endif
