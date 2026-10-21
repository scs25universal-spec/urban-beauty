# Bots para MetaTrader 5 (Expert Advisors)

Esta carpeta trae **la infraestructura** para 2 bots totalmente
automáticos en MT5, pero todavía **sin estrategia** — eso lo vamos a
completar cuando la tengas definida.

## Qué incluye cada bot ya armado

- `Bot1_Template.mq5` y `Bot2_Template.mq5` — cada uno es un Expert
  Advisor independiente, con su propio `MagicNumber` (100001 y 100002)
  para poder correr los dos a la vez, en el mismo símbolo o en
  distintos, sin que se pisen entre sí.
- `Include/RiskEngine.mqh` — cálculo del tamaño de posición (lote) según
  **% de riesgo del balance** por operación, ya compartido por los dos
  bots.
- Control de spread máximo, máximo de operaciones simultáneas por bot,
  y SL/TP configurables (en puntos o con un precio exacto si tu
  estrategia lo necesita, por ejemplo debajo de un swing o de un gap).

## Qué falta — un solo punto por bot

En cada archivo `.mq5` hay una función `GetSignal()` marcada con
`// TODO`. Hoy siempre devuelve `SIGNAL_NONE`, así que **los bots no
abren ninguna operación real todavía**. Cuando definas la estrategia de
cada uno, completamos esa función (y listo, el resto ya está
conectado).

## Instalación en MT5

1. Abrí MetaTrader 5 → menú **Herramientas → MetaQuotes Language
   Editor** (o F4).
2. En el panel "Navegador" del editor, buscá la carpeta `Experts`
   dentro de tu `MQL5` (botón derecho → "Abrir carpeta de datos" desde
   el MT5 normal te lleva ahí: `.../MQL5/Experts/`).
3. Copiá ahí dentro:
   - `Bot1_Template.mq5`
   - `Bot2_Template.mq5`
   - la carpeta `Include/` completa (con `RiskEngine.mqh`)
4. Volvé al editor, abrí cada `.mq5` y compilá (`F7`). Debería generar
   el `.ex5` correspondiente sin errores — si tira alguno, pasámelo y
   lo corrijo.
5. En MT5, abrí el gráfico del símbolo que quieras operar y arrastrá el
   Expert Advisor desde el "Navegador" (panel izquierdo, sección
   "Asesores Expertos") al gráfico.
6. Ajustá los inputs (`RiskPercent`, `MaxSpreadPoints`, etc.) en la
   ventana que aparece, y activá **"Permitir Trading algorítmico"**
   (botón "AutoTrading" en la barra superior de MT5, y el checkbox
   dentro de las propiedades del EA).

## Antes de usarlo con dinero real

- Probá primero en una **cuenta demo** o en el **Probador de
  Estrategias** (Strategy Tester, `Ctrl+R`) una vez que `GetSignal()`
  tenga tu lógica.
- `RiskPercent` calcula el lote automáticamente: un valor mal puesto
  (por ejemplo 10% en vez de 1%) puede arriesgar mucho más de lo que
  pensás por operación. Empezá chico.
- Los dos bots son independientes: si corrés ambos sobre el mismo
  símbolo, cada uno gestiona sus propias posiciones (por `MagicNumber`)
  pero el riesgo de cuenta se suma entre los dos.
