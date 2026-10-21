//+------------------------------------------------------------------+
//| RiskEngine.mqh                                                    |
//| Cálculo de tamaño de posición por riesgo % del balance, compartido |
//| entre los Expert Advisors de este repo.                            |
//+------------------------------------------------------------------+
#ifndef __RISK_ENGINE_MQH__
#define __RISK_ENGINE_MQH__

//--- Ajusta un lote al step/min/max que acepta el símbolo.
double NormalizeLots(const string symbol, double lots)
  {
   double minLot  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double maxLot  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   double stepLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);

   if(stepLot <= 0.0)
      stepLot = minLot;

   lots = MathFloor(lots / stepLot) * stepLot;

   if(lots < minLot)
      lots = minLot;
   if(maxLot > 0.0 && lots > maxLot)
      lots = maxLot;

   return NormalizeDouble(lots, 2);
  }

//--- Devuelve el lote correspondiente a arriesgar riskPercent % del
//--- balance de la cuenta, dado el stop loss en puntos. Devuelve 0.0
//--- si no se puede calcular (datos de símbolo inválidos, SL en 0, etc).
double CalculateLotByRisk(const string symbol, double riskPercent, double slPoints)
  {
   if(slPoints <= 0.0 || riskPercent <= 0.0)
      return 0.0;

   double balance   = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskMoney = balance * riskPercent / 100.0;

   double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   double point     = SymbolInfoDouble(symbol, SYMBOL_POINT);

   if(tickValue <= 0.0 || tickSize <= 0.0 || point <= 0.0)
      return 0.0;

   double valuePerPoint = tickValue * (point / tickSize);
   double moneyPerLot    = slPoints * valuePerPoint;

   if(moneyPerLot <= 0.0)
      return 0.0;

   double lots = riskMoney / moneyPerLot;
   return NormalizeLots(symbol, lots);
  }

#endif // __RISK_ENGINE_MQH__
