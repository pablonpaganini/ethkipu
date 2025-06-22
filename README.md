# EthKipu
Este repositorio de github contiene ejercicios para los trabajos del curso  
___  
## Modulo 3  
#### Datos para entrega  
> Wallet address 0x88ABc9E5b8e6cB3728E4469Be2249FF33DBb43cf  
> M1 Creation https://sepolia.etherscan.io/tx/0xbb1bb6836e3e765a6629a9fcfcc35062f18b40da039db64ced26175f48f4c3e8  
> M1 address 0x97476Fe25C170BD72945AfC34F078F7f50124572  
> M2 Creation https://sepolia.etherscan.io/tx/0xe95a29abb60a8c603e4c0a5c9259d967ff503854c40cdac8bcccb144640726ae  
> M2 address 0x9e2f2d7502929b7b9cd12a9eb452f3402289dfc2  
> SimpleSwapFactory Creation https://sepolia.etherscan.io/tx/0x06a169261f541240cb50e757c720b9c3ded7e2675eae644b9123d1e583f4340b  
> SimpleSwapFactory address 0xeE8A569897BA2D11E8e039Cc330Aeb61aedf6aBb  
> SimpleSwap Creation https://sepolia.etherscan.io/tx/0x00599f6de349145bb22940482babab7f53287745201af027eaacf657bc649ec7  
> SimpleSwap address 0x5236Ad9BA5eE52F22C3fb6E770F146e36A5c82Dc

### Contratos de SimpleSwap DEX  
Este repositorio contiene los contratos inteligentes principales para un DEX (Exchange Descentralizado) simple, inspirado en Uniswap v2.  
Incluye:  
- `SimpleSwap`: Contrato principal para agregar/quitar liquidez y realizar intercambios de tokens.  
- `SimpleSwapFactory`: Contrato fábrica para crear y administrar los pares de tokens.  
- `SimpleSwapPair`: Contrato que representa un par de tokens con funciones de liquidez y swaps. También actúa como token LP (liquidity provider).  
### 📦 Descripción de Contratos  
#### 🔧 SimpleSwapFactory  
Contrato encargado de crear y registrar pares de tokens.  
##### Funciones  
- `createPair(address tokenA, address tokenB) returns (address pair)`
  - Crea un nuevo contrato `SimpleSwapPair` si no existe para ese par.
  - Utiliza `sortTokens` para asegurar que el orden de los tokens sea consistente.
  - Genera el nombre y símbolo del token LP automáticamente.
- `getPair(address tokenA, address tokenB) view returns (address)`
  - Devuelve la dirección del par creado para `tokenA` y `tokenB`.
- `allPairsLength() view returns (uint)`
  - Devuelve la cantidad total de pares creados.
#### 🔄 SimpleSwapPair  
Contrato que representa un par de tokens. Maneja las reservas y permite realizar swaps y operaciones de liquidez.  
##### Funciones  
- `initialize(address token0, address token1)`
  - Inicializa los tokens del par. Solo puede ser llamado por el factory.
- `getReserves() view returns (uint reserve0, uint reserve1)`
  - Devuelve las reservas actuales de ambos tokens.
- `mint(address to) returns (uint liquidity)`
  - Mide cuánto se agregó al par y emite tokens LP proporcionales.
  - Se usa al agregar liquidez.
- `burn(address to) returns (uint amount0, uint amount1)`
  - Quita liquidez destruyendo los LP tokens y transfiriendo los tokens subyacentes al usuario.
- `swap(address tokenOut, uint amount, address to)`
  - Realiza un swap, transfiriendo `amount` del token especificado a `to`.
  - Verifica que la invariante `K` no se rompa (`reserve0 * reserve1`).
#### 🔁 SimpleSwap  
Contrato interfaz de usuario que se comunica con `SimpleSwapFactory` y `SimpleSwapPair`.  
##### Funciones  
- `addLiquidity(...) returns (uint amountA, uint amountB, uint liquidity)`
  - Agrega liquidez a un par. Si no existe, lo crea.
  - Calcula las proporciones ideales y transfiere tokens al par.
- `removeLiquidity(...) returns (uint amountA, uint amountB)`
  - Quita liquidez destruyendo LP tokens y devolviendo los tokens al usuario.
- `swapExactTokensForTokens(...) returns (uint[] amounts)`
  - Permite intercambiar tokens, asegurando una cantidad mínima de salida.
  - Utiliza `getAmountOut` para calcular la salida estimada.
- `getPrice(address tokenA, address tokenB) view returns (uint price)`
  - Calcula el precio del tokenB en términos de tokenA a partir de las reservas.
- `getPair(address tokenA, address tokenB) view returns (address)`
  - Devuelve la dirección del contrato `SimpleSwapPair` asociado.
#### 🧮 Utilidades internas  
- `_addLiquidity(...)`: Lógica interna usada por `addLiquidity` para determinar montos óptimos.
- `_quote(...)`: Calcula cuánto se debería recibir de un token dado un monto del otro.
- `getAmountOut(...)`: Calcula cuántos tokens se pueden recibir en un swap (sin fee en este caso).
#### 🧪 Requisitos y Consideraciones  
- Los tokens utilizados deben ser compatibles con el estándar ERC20.
- Los swaps y la provisión de liquidez requieren aprobación previa (`approve`).
- No se aplican fees ni funciones de flash swap para simplificación.
___  
## Modulo 2  
#### Datos para entrega  
> Wallet address: 0x88ABc9E5b8e6cB3728E4469Be2249FF33DBb43cf  
> Tx Hash: https://sepolia.etherscan.io/tx/0x97229db5878cb919426cd117466f2da9002a62496868dcb036bc8ed1bc406982  
> Contract address: 0xf9046c6790aace118d19adf9bb8341d01ce0db2b  
#### Resumen  
Este contrato sirve para manejar subastas.  
Para los ejemplos se utiliza *javascript*  
En la carpeta **modulo 2** se encuentran los contratos y tests usados  
##### Funciones  
Para iniciar la subasta se llama al método **openAuction** que recibe 2 parámetros
```js
// Indica el mínimo con el que se inicia la subasta
// No se puede ofertar por debajo de eso
const minBid = ethers.utils.parseEther("0.1");
// Indica la duración inicial que tiene la subasta
const duration = 3600
await auction.openAuction(minBid, duration); // 0.1 ETH, 1 hora
```
Para realizar una oferta se llama al método **bid** que recibe un parámetro  
Es necesario que:  
1. La subasta debe estar abierta
2. La oferta supere en un 5% a la oferta ganadora actual
3. La oferta supere el mínimo  
```js
await auction.bid({ value: ethers.utils.parseEther("0.2") }); // Bid de 0.2 ETH
```
Para obtener información del ganador actual se llama al método **winner**
```js
const [winnerAddress, winnerBid] = await auction.winner();
console.log("Ganador:", winnerAddress);
console.log("Oferta:", ethers.utils.formatEther(winnerBid));
```  
Para terminar una subasta se llama al método **closeAuction**
```js
await auction.closeAuction();
```
*No es necesario el uso de este método ya que la subasta finalizará por tiempos, pero sirve para acelerar el proceso*  
Para obtener el balance de un oferente que está en el contrato se utiliza el método **getBidderBalance**
```js
const balance = await auction.getBidderBalance();
console.log("Balance del postor:", ethers.utils.formatEther(balance));
```
Para retirar el saldo sobrante de un oferente se utiliza el método **claims**
Es necesario que:  
1. La subasta debe estar abierta
```js
await auction.claims();
```
Para reembolsar a los no ganadores se utiliza el método **refund** que recibe como párametro el address a reembolzar
Es necesario que:  
1. La subasta este cerrada
2. Solo el owber del contrato puede realizar esta operación
3. Se cobra un 2% en concepto de comisión  
```js
await auction.refund(bidderAddress);
```
Para retirar el total del balance del contrato se llama al método **withdraw**
Es necesario que:  
1. La subasta este cerrada
2. Solo el owber del contrato puede realizar esta operación
```js
await auction.withdraw();
```
##### Eventos  
El contrato emite 2 eventos  
1. EventNewBid: Que se emite cada vez que se acepta una nueva oferta
2. EventAuctionClosed: Que se emite cuando se finaliza la subasta

