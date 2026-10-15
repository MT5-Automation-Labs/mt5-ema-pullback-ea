# MT5 EMA Pullback EA

A MetaTrader 5 Expert Advisor that trades pullbacks to a fast EMA in the direction of a slow-EMA trend, with ATR-based stops, risk-percentage sizing and trading filters.

## Strategy
- **Trend**: fast EMA above slow EMA and slow EMA sloping up (minimum slope measured in ATR) = uptrend; mirror for downtrend.
- **Pullback**: the last closed bar touched the fast EMA (within a tolerance of x ATR) without breaking the slow EMA.
- **Trigger**: that bar closed back on the trend side of the fast EMA as a candle in the trend direction.
- **Exits**: SL = x ATR, TP = x ATR (optional), ATR trailing stop after a profit threshold.

## Features
- Modular includes: `Signal.mqh` (indicators + entry rules), `Risk.mqh` (lot sizing, spread and session filters), `Trade.mqh` (execution, position count, trailing).
- Risk % of balance sizing using tick value, or fixed lots.
- Session filter (server hours, overnight windows supported) and max spread filter.
- Max open positions per symbol + magic number.
- Respects broker minimum stop distance; evaluates entries once per bar.

## Install
1. Copy `Include/EmaPullback/` to `MQL5/Include/EmaPullback/`.
2. Copy `Experts/EmaPullbackEA.mq5` to `MQL5/Experts/`.
3. Compile in MetaEditor (F7), then attach to a chart or run it in the Strategy Tester.

## Inputs
| Input | Default | Description |
|---|---|---|
| InpTF | M15 | Signal timeframe |
| InpFastEMA / InpSlowEMA | 21 / 100 | EMA periods |
| InpATRPeriod | 14 | ATR period |
| InpTouchATR | 0.2 | How close to the fast EMA counts as a pullback (x ATR) |
| InpMinSlopeATR / InpSlopeBars | 0.1 / 5 | Minimum slow-EMA slope over N bars (x ATR) |
| InpSL_ATR / InpTP_ATR | 1.5 / 3.0 | Stop loss / take profit (x ATR, TP 0 = none) |
| InpUseTrailing | true | Enable ATR trailing stop |
| InpTrailStartATR / InpTrailATR / InpTrailStepATR | 1.0 / 1.0 / 0.1 | Trailing start, distance and min step (x ATR) |
| InpRiskPct | 1.0 | Risk per trade, % of balance |
| InpFixedLots | 0 | Fixed lot size (>0 disables risk sizing) |
| InpMaxLots | 10 | Lot cap |
| InpMaxPositions | 1 | Max open positions |
| InpStartHour / InpEndHour | 7 / 20 | Session in server hours (equal = 24h) |
| InpMaxSpread | 30 | Max spread in points (0 = off) |
| InpMagic | 21100 | Magic number |
| InpSlippage | 20 | Max slippage in points |
| InpComment | ema-pullback | Order comment |

## Tips
- Backtest with "Every tick based on real ticks" and realistic spreads before going live.
- Optimise EMA periods, SL/TP multipliers and session per symbol; avoid over-fitting.

## Disclaimer

Trading forex, metals, indices and CFDs on margin carries a high level of risk and can result in losses greater than your deposit. This software is provided for educational purposes, without any warranty, and is not financial advice. Past or backtested performance does not guarantee future results. Always test on a demo account first and use it at your own risk.

## License
MIT © 2026 StanleyDaniels

## Contact

Telegram: [t.me/teraus111](https://t.me/teraus111)
