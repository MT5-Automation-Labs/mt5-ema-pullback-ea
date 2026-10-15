//+------------------------------------------------------------------+
//| Trade.mqh - order execution, position counting, trailing stop    |
//| MIT License, Copyright (c) 2026 StanleyDaniels                   |
//+------------------------------------------------------------------+
#ifndef EMAPB_TRADE_MQH
#define EMAPB_TRADE_MQH

#include <Trade/Trade.mqh>

class CTradeExecutor
  {
private:
   CTrade            m_trade;
   string            m_sym;
   long              m_magic;
   int               m_digits;

   double            MinStopDistance()
     {
      long lvl = SymbolInfoInteger(m_sym, SYMBOL_TRADE_STOPS_LEVEL);
      return (lvl + 1) * SymbolInfoDouble(m_sym, SYMBOL_POINT);
     }

public:
   void              Init(string sym, long magic, int slippagePoints)
     {
      m_sym = sym; m_magic = magic;
      m_digits = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
      m_trade.SetExpertMagicNumber(magic);
      m_trade.SetDeviationInPoints(slippagePoints);
      m_trade.SetTypeFillingBySymbol(sym);
     }

   int               CountPositions()
     {
      int n = 0;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         ulong tk = PositionGetTicket(i);
         if(tk == 0) continue;
         if(PositionGetString(POSITION_SYMBOL) == m_sym && PositionGetInteger(POSITION_MAGIC) == m_magic) n++;
        }
      return n;
     }

   bool              Open(bool isBuy, double lots, double slDist, double tpDist, string comment)
     {
      double price = isBuy ? SymbolInfoDouble(m_sym, SYMBOL_ASK) : SymbolInfoDouble(m_sym, SYMBOL_BID);
      double minD = MinStopDistance();
      slDist = MathMax(slDist, minD);
      if(tpDist > 0) tpDist = MathMax(tpDist, minD);
      double sl = NormalizeDouble(isBuy ? price - slDist : price + slDist, m_digits);
      double tp = (tpDist > 0) ? NormalizeDouble(isBuy ? price + tpDist : price - tpDist, m_digits) : 0.0;
      bool ok = isBuy ? m_trade.Buy(lots, m_sym, price, sl, tp, comment)
                      : m_trade.Sell(lots, m_sym, price, sl, tp, comment);
      if(!ok || (m_trade.ResultRetcode() != TRADE_RETCODE_DONE && m_trade.ResultRetcode() != TRADE_RETCODE_PLACED))
        {
         PrintFormat("Order failed: rc=%u %s", m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription());
         return false;
        }
      return true;
     }

   // ATR trailing: starts after profit >= startDist, keeps SL trailDist behind price,
   // only moves in the profitable direction and by at least stepDist.
   void              Trail(double startDist, double trailDist, double stepDist)
     {
      if(trailDist <= 0) return;
      double minD = MinStopDistance();
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         ulong tk = PositionGetTicket(i);
         if(tk == 0) continue;
         if(PositionGetString(POSITION_SYMBOL) != m_sym || PositionGetInteger(POSITION_MAGIC) != m_magic) continue;
         long   type = PositionGetInteger(POSITION_TYPE);
         double op   = PositionGetDouble(POSITION_PRICE_OPEN);
         double sl   = PositionGetDouble(POSITION_SL);
         double tp   = PositionGetDouble(POSITION_TP);
         double dist = MathMax(trailDist, minD);
         if(type == POSITION_TYPE_BUY)
           {
            double bid = SymbolInfoDouble(m_sym, SYMBOL_BID);
            if(bid - op < startDist) continue;
            double nsl = NormalizeDouble(bid - dist, m_digits);
            if(nsl > sl + stepDist || sl == 0) m_trade.PositionModify(tk, nsl, tp);
           }
         else if(type == POSITION_TYPE_SELL)
           {
            double ask = SymbolInfoDouble(m_sym, SYMBOL_ASK);
            if(op - ask < startDist) continue;
            double nsl = NormalizeDouble(ask + dist, m_digits);
            if(sl == 0 || nsl < sl - stepDist) m_trade.PositionModify(tk, nsl, tp);
           }
        }
     }
  };

#endif
