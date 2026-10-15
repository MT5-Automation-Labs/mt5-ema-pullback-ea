//+------------------------------------------------------------------+
//| EmaPullbackEA.mq5 - trend pullback EA (fast EMA vs slow EMA)     |
//| MIT License, Copyright (c) 2026 StanleyDaniels                   |
//+------------------------------------------------------------------+
#property copyright "Copyright (c) 2026 StanleyDaniels"
#property version   "1.00"
#property description "Buys pullbacks to the fast EMA in an up-trend (and sells in a down-trend), ATR stops, risk % sizing."

#include <EmaPullback/Signal.mqh>
#include <EmaPullback/Risk.mqh>
#include <EmaPullback/Trade.mqh>

input group "=== Signal ==="
input ENUM_TIMEFRAMES InpTF            = PERIOD_M15; // Signal timeframe
input int             InpFastEMA       = 21;         // Fast EMA period
input int             InpSlowEMA       = 100;        // Slow EMA period (trend)
input int             InpATRPeriod     = 14;         // ATR period
input double          InpTouchATR      = 0.2;        // Pullback tolerance (x ATR from fast EMA)
input double          InpMinSlopeATR   = 0.1;        // Min slow-EMA slope (x ATR)
input int             InpSlopeBars     = 5;          // Bars used to measure slope
input group "=== Stops ==="
input double          InpSL_ATR        = 1.5;        // Stop loss (x ATR)
input double          InpTP_ATR        = 3.0;        // Take profit (x ATR, 0 = none)
input bool            InpUseTrailing   = true;       // Use ATR trailing stop
input double          InpTrailStartATR = 1.0;        // Start trailing after profit (x ATR)
input double          InpTrailATR      = 1.0;        // Trailing distance (x ATR)
input double          InpTrailStepATR  = 0.1;        // Minimum SL step (x ATR)
input group "=== Risk ==="
input double          InpRiskPct       = 1.0;        // Risk per trade (% balance)
input double          InpFixedLots     = 0.0;        // Fixed lots (>0 disables risk sizing)
input double          InpMaxLots       = 10.0;       // Max lots per trade
input int             InpMaxPositions  = 1;          // Max open positions (this symbol + magic)
input group "=== Filters ==="
input int             InpStartHour     = 7;          // Session start hour (server)
input int             InpEndHour       = 20;         // Session end hour (server, = start for 24h)
input int             InpMaxSpread     = 30;         // Max spread in points (0 = off)
input group "=== Execution ==="
input long            InpMagic         = 21100;      // Magic number
input int             InpSlippage      = 20;         // Max slippage (points)
input string          InpComment       = "ema-pullback"; // Order comment

CPullbackSignal g_signal;
CRiskManager    g_risk;
CTradeExecutor  g_exec;
datetime        g_lastBar = 0;

int OnInit()
  {
   if(InpFastEMA >= InpSlowEMA)
     {
      Print("Fast EMA period must be smaller than slow EMA period");
      return INIT_PARAMETERS_INCORRECT;
     }
   if(InpSL_ATR <= 0 || InpRiskPct < 0)
      return INIT_PARAMETERS_INCORRECT;
   if(!g_signal.Init(_Symbol, InpTF, InpFastEMA, InpSlowEMA, InpATRPeriod, InpTouchATR, InpMinSlopeATR, InpSlopeBars))
     {
      Print("Indicator init failed: ", GetLastError());
      return INIT_FAILED;
     }
   g_risk.Init(_Symbol, InpRiskPct, InpFixedLots, InpMaxLots);
   g_exec.Init(_Symbol, InpMagic, InpSlippage);
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason) { g_signal.Release(); }

void OnTick()
  {
   double atr = g_signal.Atr(1);

   if(InpUseTrailing && atr > 0)
      g_exec.Trail(InpTrailStartATR * atr, InpTrailATR * atr, InpTrailStepATR * atr);

   datetime bar = iTime(_Symbol, InpTF, 0);
   if(bar == 0 || bar == g_lastBar) return;   // evaluate once per new bar
   g_lastBar = bar;

   if(atr <= 0) return;
   if(g_exec.CountPositions() >= InpMaxPositions) return;
   if(!CRiskManager::InSession(InpStartHour, InpEndHour, TimeCurrent())) return;
   if(!g_risk.SpreadOk(InpMaxSpread)) return;

   ENUM_EP_SIGNAL sig = g_signal.Check();
   if(sig == EP_NONE) return;

   double slDist = InpSL_ATR * atr;
   double tpDist = InpTP_ATR * atr;
   double lots = g_risk.Lots(slDist);
   if(lots <= 0)
     {
      Print("Lot size below broker minimum for current risk settings");
      return;
     }
   g_exec.Open(sig == EP_BUY, lots, slDist, tpDist, InpComment);
  }
