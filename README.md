# EthKipu
Este repositorio de github contiene ejercicios para los trabajos del curso  
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

