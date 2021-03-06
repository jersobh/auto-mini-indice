//+------------------------------------------------------------------+
//|                                               Auto_Indice_01.mq5 |
//|                                            Mateus Salmazo Takaki |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mateus Salmazo Takaki"
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

CPositionInfo  m_position;                   // trade position object

//const ENUM_POSITION_TYPE pos_type;

input ulong INP_VOLUME           = 1;
//input double INP_TAKEPROFIT    = 100.0;
//input double INP_STOPLOSS        = 100.0;
//input double INP_BRACKEVEN     = 0.0;

double breakeven  = 0.0;
double preco      = 0.0;
double precoStop  = 0.0;
double ask, bid, last;
bool range = true;
bool position_buy = true; 
bool position_sell = true;
long type_position = 5;

CTrade Trade;
MqlRates    rates[];
MqlTick     tick;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
      
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
      // Para padronizar os preenchimentos de funções em diferentes corretoras.
      Trade.SetTypeFilling(ORDER_FILLING_RETURN);      

      int copied = CopyRates(_Symbol, _Period, 0, 3, rates);
      int BBHandle = iBands(_Symbol, _Period, 20, 0, 2, PRICE_CLOSE);
      bool posicao = true;      
      double banda_sup[];     // Buffer que armazena os valores da banda superior da Banda de Bollinger.
      double banda_inf[];     // Buffer que armazena os valores da banda inferior da Banda de Bollinger.
      double media[];         // Buffer que armazena a média da Banda de Bollinger.
      double MMeRed[];        // Buffer que armazena os valores da média que representa o hilo vermelho. 
      double MMeBlue[];       // Buffer que armazena os valores da media que representa o hilo azul.      

      // Define as propriedades da média móvel exponencial de 9 periodos e deslocamento de 1.
      int movingAverageRed = iMA(_Symbol, _Period, 9, 1, MODE_EMA, PRICE_HIGH);
      // Define as propriedades da média móvel exponencial de 9 periodos sem o deslocamento.
      int movingAverageBlue = iMA(_Symbol, _Period, 9, 1, MODE_EMA, PRICE_LOW);
      
      // Inverte a posição do Array para o preço mais recente ficar na posição 0.
      ArraySetAsSeries(rates, true);
      ArraySetAsSeries(banda_sup, true);
      ArraySetAsSeries(banda_inf, true);
      ArraySetAsSeries(media, true);      
      ArraySetAsSeries(MMeRed, true);
      ArraySetAsSeries(MMeBlue, true);

      CopyBuffer(BBHandle, 0, 0, 3, media);        // 0 indica a média.
      CopyBuffer(BBHandle, 1, 0, 3, banda_sup);    // 1 indica a banda superior.
      CopyBuffer(BBHandle, 2, 0, 3, banda_inf);    // 2 indica a banda iferior.
      CopyBuffer(movingAverageRed, 0, 0, 3, MMeRed);
      CopyBuffer(movingAverageBlue, 0, 0, 3, MMeBlue);
      
      if(PositionsTotal() > 0){
         //Print("Tem posição aberta...");
         PositionSelect(_Symbol);
         type_position  = PositionGetInteger(POSITION_TYPE);          //type 0: Comprado | 1: Vendido.
         
         /*
         if(type == 0){
            position_buy = true;
            position_sell = false;
         }
         else{
            position_buy = false;
            position_sell = true;
         }
         */
       }

      //Print("type: ", type);
      
      // Recupera a hora local.
      datetime time = TimeCurrent();
      string hora = TimeToString(time, TIME_MINUTES);
      //Print(StringSubstr(hora,0,5));
      if((StringSubstr(hora,0,5) == "09:30") || (StringSubstr(hora,0,5) == "09:45") || (StringSubstr(hora,0,5) == "10:00") ){
         range = true;
      }
      if((StringSubstr(hora,0,5) == "16:00") || (StringSubstr(hora,0,5) == "16:15") || (StringSubstr(hora,0,5) == "16:30") ){
         range = false;
      }
     // Print("range: ", range);
      // Recupera os valores dos preços de ask, bid e last:
      ask   = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      bid   = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      last  = SymbolInfoDouble(_Symbol, SYMBOL_LAST);
      //Print("range: ", range);
      if(banda_inf[1] > banda_inf[0] && banda_sup[1] < banda_sup[0] && range )   
      {
      /*
         Comment("type_position: ", type_position, "\n");
         Comment("banda_inf[1]: ", banda_inf[1], "\n");
         Comment("banda_inf[0]: ", banda_inf[0], "\n");
         Comment("banda_sup[1]: ", banda_sup[1], "\n");
         Comment("banda_sup[0]: ", banda_sup[0], "\n");
         Comment("range: ", range, "\n");
         Comment("------------------", "\n");
         Print("rates[1].close: ", rates[1].close);
         Print("tick.last: ", tick.last);
         Print("MMeRed[1]: ", MMeRed[1]);
         Print("rates[0].high: ", rates[0].high);
         Print("type_position: ", type_position);
         Print("------------------");
      */
         /*//////////////////////////////////////////////////////////////////////////////
         /                           ENTRADA NA COMPRA                                 //
         *///////////////////////////////////////////////////////////////////////////////
         
         if(rates[1].close > MMeRed[1] && ask > rates[1].high && type_position != 0 ){  // Versão 02
         //if(rates[0].close > MMeRed[0] && type != 0){  // Versão 01
         /*
         Comment("rates[1].close: ", rates[1].close, "\n");
         Comment("MMeRed[1]: ", MMeRed[1],"\n");
         Comment("rates[0].high: ", rates[0].high,"\n");
         Comment("type_position: ", type_position,"\n");
         Comment("------------------", "\n");
         */
            if(PositionsTotal() >= 1){
               posicao   = EliminaPosicao();
            }
            bool ordem     = EliminaOrdem();
   
            if(posicao && ordem){
               BuyMarket();
            }
            else{
               Print("Erro: Problema na Posição ou na Ordem !", GetLastError());
               return;
            }
         }
         
         /*//////////////////////////////////////////////////////////////////////////////
         /                           ENTRADA NA VENDA                                  //
         *///////////////////////////////////////////////////////////////////////////////
               
         if(rates[1].close < MMeBlue[1] && bid < rates[1].low && type_position != 1){  // Versão 02
         //if(rates[1].close < MMeBlue[1] && type != 1){  // Versão 01
         /*
         Comment(rates[1].close,"\n");
         Comment(MMeBlue[1],"\n");
         Comment(rates[0].low,"\n");
         Comment(type_position,"\n");
         Comment("------------------", "\n");
         */
            if(PositionsTotal() >= 1){
               posicao   = EliminaPosicao();
            }   
            bool ordem     = EliminaOrdem();
   
            if(posicao && ordem){
               SellMarket();
            }
            else{
               Print("Erro: Problema na Posição ou na Ordem !", GetLastError());
               return;
            }
            
         }
         
     }  
  }
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//| Expert Buy function                                              |
//+------------------------------------------------------------------+
bool BuyMarket(){
   Print("Compra em ask: ", ask);
   Print("Ask - stoploss: ", ask - 300 );
   bool ok = Trade.Buy(INP_VOLUME, _Symbol, ask, ask - 300, ask + 300);
   if(!ok){
      int errorCode = GetLastError();
      Print("BuyMarket: ", errorCode);
      ResetLastError();
   }
   return ok;
}
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Expert Sell function                                             |
//+------------------------------------------------------------------+
bool SellMarket(){
   Print("Venda em bid: ", bid);
   Print("Bid + stoploss: ", bid + 300);
   bool ok = Trade.Sell(INP_VOLUME, _Symbol, bid, bid + 300, bid - 300);
   if(!ok){
      int errorCode = GetLastError();
      Print("SellMarket: ", errorCode);
      ResetLastError();
   }
   return ok;
}
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Expert BuyStop function                                          |
//+------------------------------------------------------------------+
bool BuyStop(double _price_stop){
   
   bool ok = Trade.BuyStop(INP_VOLUME, _price_stop,_Symbol );
   if(!ok){
      int errorCode = GetLastError();
      Print("BuyStop: ", errorCode);
      ResetLastError();
   }
   return ok;
}
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//| Expert SellStop function                                         |
//+------------------------------------------------------------------+
bool SellStop(double _price_stop){
   
   bool ok = Trade.SellStop(INP_VOLUME, _price_stop,_Symbol );
   if(!ok){
      int errorCode = GetLastError();
      Print("SellStop: ", errorCode);
      ResetLastError();
   }
   return ok;
}
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//| Expert Elimina Posição function                                  |
//+------------------------------------------------------------------+
bool EliminaPosicao(){
   //Verifica se está em alguma posição. Em caso positivo elimina a posição
      Print("Remove todas posição !");
      return Trade.PositionClose(_Symbol);
}
//+------------------------------------------------------------------+




//+------------------------------------------------------------------+
//| Expert Elimina Posição function                                  |
//+------------------------------------------------------------------+
bool EliminaOrdem(){
   
   ulong orderTicket = 0;
   int index = 0;
   int flagOrdem = 0;
   bool boolOrder = true;
   
   //Verifica se existe alguma ordem pendente. Em caso positivo elimina a ordem.
   while(OrdersTotal() != 0){
      orderTicket = OrderGetTicket(0);
      boolOrder = Trade.OrderDelete(orderTicket);
      if(boolOrder == false)
         flagOrdem++;
   }
  
   if(flagOrdem > 0)
      return false;
   else
      return true;

}
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//| Expert SellLimit function                                        |
//+------------------------------------------------------------------+
bool SellLimit(double _price_limit){
   
   bool ok = Trade.SellLimit(INP_VOLUME, _price_limit, _Symbol );
   if(!ok){
      int errorCode = GetLastError();
      Print("SellLimit: ", errorCode);
      ResetLastError();
   }
   return ok;
}
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//| Expert BuyLimit function                                         |
//+------------------------------------------------------------------+
bool BuyLimit(double _price_limit){
   
   bool ok = Trade.BuyLimit(INP_VOLUME, _price_limit, _Symbol );
   if(!ok){
      int errorCode = GetLastError();
      Print("BuyLimit: ", errorCode);
      ResetLastError();
   }
   return ok;
}
//+------------------------------------------------------------------+




//+------------------------------------------------------------------+
//| Expert Evolui Stop function                                      |
//+------------------------------------------------------------------+
void EvoluiStop(){
   //Essa função é responsável por elevar o stop para garantir a gestão de risco da estratégia.
   Print("Função EvoluiStop Ativada !");
   
      
}
//+------------------------------------------------------------------+


