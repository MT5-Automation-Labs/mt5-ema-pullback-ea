//+------------------------------------------------------------------+
//| Risk.mqh - position sizing and trading filters                   |
//| MIT License, Copyright (c) 2026 StanleyDaniels                   |
//+------------------------------------------------------------------+
#ifndef EMAPB_RISK_MQH
#define EMAPB_RISK_MQH

class CRiskManager
  {
private:
   string            m_sym;
   double            m_riskPct;
   double            m_fixedLots;    // > 0 overrides risk sizing
   double            m_maxLots;

public:
   void              Init(string sym, double riskPct, double fixedLots, double maxLots)
     {
      m_sym = sym; m_riskPct = riskPct; m_fixedLots = fixedLots; m_maxLots = maxLots;
     }

   double            NormalizeLots(double lots)
     {
      double step = SymbolInfoDouble(m_sym, SYMBOL_VOLUME_STEP);
      double vmin = SymbolInfoDouble(m_sym, SYMBOL_VOLUME_MIN);
      double vmax = SymbolInfoDouble(m_sym, SYMBOL_VOLUME_MAX);
      if(step <= 0) return 0;
      if(m_maxLots > 0) vmax = MathMin(vmax, m_maxLots);
      lots = MathFloor(lots / step + 1e-9) * step;
      lots = MathMin(lots, vmax);
      if(lots < vmin) return 0;
      int digits = (int)MathMax(0, MathCeil(-MathLog10(step)));
      return NormalizeDouble(lots, digits);
     }

   // lots so that a stop-out at slDistance (price units) loses riskPct of balance
   double            Lots(double slDistance)
     {
      if(m_fixedLots > 0) return NormalizeLots(m_fixedLots);
      double tsz = SymbolInfoDouble(m_sym, SYMBOL_TRADE_TICK_SIZE);
      double tvl = SymbolInfoDouble(m_sym, SYMBOL_TRADE_TICK_VALUE);
      if(slDistance <= 0 || tsz <= 0 || tvl <= 0) return 0;
      double money = AccountInfoDouble(ACCOUNT_BALANCE) * m_riskPct / 100.0;
      return NormalizeLots(money / (slDistance / tsz * tvl));
     }

   bool              SpreadOk(int maxPoints)
     {
      if(maxPoints <= 0) return true;
      return SymbolInfoInteger(m_sym, SYMBOL_SPREAD) <= maxPoints;
     }

   // startHour == endHour means all day; supports overnight windows (e.g. 22 -> 6)
   static bool       InSession(int startHour, int endHour, datetime t)
     {
      if(startHour == endHour) return true;
      MqlDateTime d;
      TimeToStruct(t, d);
      if(startHour < endHour) return d.hour >= startHour && d.hour < endHour;
      return d.hour >= startHour || d.hour < endHour;
     }
  };

#endif
