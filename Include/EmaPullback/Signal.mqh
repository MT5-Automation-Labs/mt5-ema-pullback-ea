//+------------------------------------------------------------------+
//| Signal.mqh - EMA trend + pullback entry logic                    |
//| MIT License, Copyright (c) 2026 StanleyDaniels                   |
//+------------------------------------------------------------------+
#ifndef EMAPB_SIGNAL_MQH
#define EMAPB_SIGNAL_MQH

enum ENUM_EP_SIGNAL { EP_NONE = 0, EP_BUY = 1, EP_SELL = -1 };

class CPullbackSignal
  {
private:
   string            m_sym;
   ENUM_TIMEFRAMES   m_tf;
   int               m_hFast, m_hSlow, m_hAtr;
   double            m_touchAtr;      // how close (in ATR) price must come to the fast EMA
   double            m_minSlopeAtr;   // min slow-EMA slope over m_slopeBars, in ATR
   int               m_slopeBars;

   bool              Copy(int h, int count, double &buf[])
     {
      ArraySetAsSeries(buf, true);
      return CopyBuffer(h, 0, 0, count, buf) == count;
     }

public:
                     CPullbackSignal() : m_hFast(INVALID_HANDLE), m_hSlow(INVALID_HANDLE), m_hAtr(INVALID_HANDLE) {}
                    ~CPullbackSignal() { Release(); }

   bool              Init(string sym, ENUM_TIMEFRAMES tf, int fast, int slow, int atr,
                          double touchAtr, double minSlopeAtr, int slopeBars)
     {
      m_sym = sym; m_tf = tf; m_touchAtr = touchAtr; m_minSlopeAtr = minSlopeAtr;
      m_slopeBars = MathMax(1, slopeBars);
      m_hFast = iMA(sym, tf, fast, 0, MODE_EMA, PRICE_CLOSE);
      m_hSlow = iMA(sym, tf, slow, 0, MODE_EMA, PRICE_CLOSE);
      m_hAtr  = iATR(sym, tf, atr);
      return m_hFast != INVALID_HANDLE && m_hSlow != INVALID_HANDLE && m_hAtr != INVALID_HANDLE;
     }

   void              Release()
     {
      if(m_hFast != INVALID_HANDLE) { IndicatorRelease(m_hFast); m_hFast = INVALID_HANDLE; }
      if(m_hSlow != INVALID_HANDLE) { IndicatorRelease(m_hSlow); m_hSlow = INVALID_HANDLE; }
      if(m_hAtr  != INVALID_HANDLE) { IndicatorRelease(m_hAtr);  m_hAtr  = INVALID_HANDLE; }
     }

   double            Atr(int shift = 1)
     {
      double b[];
      if(!Copy(m_hAtr, shift + 1, b)) return 0;
      return b[shift];
     }

   // Evaluated on the last closed bar (shift 1):
   //  BUY : fast > slow, slow rising, bar 1 low dipped to within touchAtr of fast EMA,
   //        and bar 1 closed back above fast EMA as a bullish candle.
   //  SELL: mirror image.
   ENUM_EP_SIGNAL    Check()
     {
      int need = m_slopeBars + 2;
      double f[], s[], a[];
      if(!Copy(m_hFast, need, f) || !Copy(m_hSlow, need, s) || !Copy(m_hAtr, 2, a)) return EP_NONE;
      double atr = a[1];
      if(atr <= 0) return EP_NONE;
      double o = iOpen(m_sym, m_tf, 1), c = iClose(m_sym, m_tf, 1);
      double h = iHigh(m_sym, m_tf, 1), l = iLow(m_sym, m_tf, 1);
      double slope = (s[1] - s[1 + m_slopeBars]) / atr;

      if(f[1] > s[1] && slope >= m_minSlopeAtr)
        {
         bool touched = (l <= f[1] + m_touchAtr * atr);
         bool notBroken = (l > s[1]);
         if(touched && notBroken && c > f[1] && c > o) return EP_BUY;
        }
      if(f[1] < s[1] && slope <= -m_minSlopeAtr)
        {
         bool touched = (h >= f[1] - m_touchAtr * atr);
         bool notBroken = (h < s[1]);
         if(touched && notBroken && c < f[1] && c < o) return EP_SELL;
        }
      return EP_NONE;
     }
  };

#endif
