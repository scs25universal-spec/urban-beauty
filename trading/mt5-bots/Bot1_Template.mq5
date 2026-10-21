//+------------------------------------------------------------------+
//| Bot1_Template.mq5                                                  |
//| Plantilla de Expert Advisor para MetaTrader 5.                     |
//|                                                                     |
//| Trae armada toda la parte de automatización: ejecución de          |
//| órdenes, tamaño de posición por riesgo % del balance, SL/TP y      |
//| control de operaciones abiertas / spread. Queda UN SOLO punto      |
//| para completar: la función GetSignal() de más abajo.               |
//|                                                                     |
//| NO abre operaciones reales todavía: GetSignal() siempre devuelve   |
//| SIGNAL_NONE hasta que reemplaces el TODO con tu estrategia.         |
//|                                                                     |
//| Usa un MagicNumber propio (100001) para poder correr este bot y    |
//| Bot2_Template.mq5 al mismo tiempo, en el mismo o distinto símbolo,  |
//| sin que se pisen las posiciones de uno con las del otro.            |
//+------------------------------------------------------------------+
#property copyright "Bot1"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
#include "Include/RiskEngine.mqh"

//--- Inputs
input double RiskPercent             = 1.0;   // % del balance a arriesgar por operación
input ulong  MagicNumber              = 100001; // identificador único de este bot
input int    MaxOpenPositions         = 1;    // operaciones simultáneas permitidas de este bot
input int    MaxSpreadPoints          = 30;   // no operar si el spread supera esto (en puntos)
input int    DefaultStopLossPoints    = 300;  // SL por defecto si la señal no trae uno propio
input double DefaultRiskReward        = 2.0;  // TP = distancia del SL * este múltiplo, si la señal no trae uno propio

CTrade trade;

enum ENUM_SIGNAL_DIRECTION
  {
   SIGNAL_NONE,
   SIGNAL_BUY,
   SIGNAL_SELL
  };

struct SignalResult
  {
   ENUM_SIGNAL_DIRECTION direction;
   double                stopLossPrice;   // precio exacto de SL, o 0.0 = usar DefaultStopLossPoints
   double                takeProfitPrice; // precio exacto de TP, o 0.0 = usar DefaultRiskReward
  };

//+------------------------------------------------------------------+
//| ACÁ VA TU ESTRATEGIA.                                              |
//|                                                                     |
//| Devolvé SIGNAL_BUY o SIGNAL_SELL cuando se cumplan tus condiciones  |
//| de entrada (lectura de indicadores, estructura de precio, horario, |
//| etc). Si tu SL va en un nivel concreto (debajo de un swing, de un   |
//| FVG, de un NWOG...) devolvelo en stopLossPrice; si dejás 0.0, se    |
//| usa la distancia fija DefaultStopLossPoints.                       |
//+------------------------------------------------------------------+
SignalResult GetSignal()
  {
   SignalResult result;
   result.direction       = SIGNAL_NONE;
   result.stopLossPrice   = 0.0;
   result.takeProfitPrice = 0.0;

   // TODO: reemplazar por la lógica real de la estrategia de este bot.

   return result;
  }

int OnInit()
  {
   trade.SetExpertMagicNumber(MagicNumber);
   return(INIT_SUCCEEDED);
  }

void OnTick()
  {
   if(CountOpenPositions() >= MaxOpenPositions)
      return;

   if(GetSpreadPoints() > MaxSpreadPoints)
      return;

   SignalResult signal = GetSignal();
   if(signal.direction == SIGNAL_NONE)
      return;

   ExecuteSignal(signal);
  }

//--- Posiciones abiertas de ESTE bot (por magic number) en este símbolo.
int CountOpenPositions()
  {
   int count = 0;
   for(int i = 0; i < PositionsTotal(); i++)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(PositionGetInteger(POSITION_MAGIC) == (long)MagicNumber &&
         PositionGetString(POSITION_SYMBOL) == _Symbol)
         count++;
     }
   return count;
  }

double GetSpreadPoints()
  {
   double ask   = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid   = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(point <= 0.0)
      return 0.0;
   return (ask - bid) / point;
  }

void ExecuteSignal(const SignalResult &signal)
  {
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double price = (signal.direction == SIGNAL_BUY)
                     ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                     : SymbolInfoDouble(_Symbol, SYMBOL_BID);

   double slPrice = signal.stopLossPrice;
   if(slPrice == 0.0)
      slPrice = (signal.direction == SIGNAL_BUY)
                   ? price - DefaultStopLossPoints * point
                   : price + DefaultStopLossPoints * point;

   double slDistancePoints = MathAbs(price - slPrice) / point;
   if(slDistancePoints <= 0.0)
     {
      Print("SL inválido, no se envía la orden.");
      return;
     }

   double tpPrice = signal.takeProfitPrice;
   if(tpPrice == 0.0)
     {
      double tpDistance = slDistancePoints * DefaultRiskReward * point;
      tpPrice = (signal.direction == SIGNAL_BUY) ? price + tpDistance : price - tpDistance;
     }

   double lots = CalculateLotByRisk(_Symbol, RiskPercent, slDistancePoints);
   if(lots <= 0.0)
     {
      Print("Lote calculado inválido (revisá RiskPercent y el SL), no se envía la orden.");
      return;
     }

   if(signal.direction == SIGNAL_BUY)
      trade.Buy(lots, _Symbol, price, slPrice, tpPrice, "Bot1");
   else
      trade.Sell(lots, _Symbol, price, slPrice, tpPrice, "Bot1");
  }
