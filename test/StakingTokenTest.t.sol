// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
//importamos la librería de test de Foundry
import "forge-std/Test.sol";
//importamos nuestro contrato de Staking Token
import "../src/StakingToken.sol";
//IERC20 library
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract StakingTokenTest is Test {

    StakingToken stakingToken;
    string name_ = "Staking Token";
    string symbol_ = "STK";
    address randomUser = vm.addr(1);

    //Los test de Solidity tienen 2 partes:
    //1._ setUp: el contrato stakingToken.t.sol va a crear un nuevo smart contract que va a ser
    //el smart contract de StakingToken. Lo que tengamos dentro del setUp se ejecuta siempre antes de cada test
    function setUp() public{
        stakingToken = new StakingToken(name_, symbol_);
    }
    //2._ test: los test como tal, es decir funciones de un smart contract
    //Queremos chequear que se ha minteado correctamente
    function testStakingTokenMintsCorrectly() public{
        //La dirección que estoy impersonando tiene que ser la misma que la del minteo
        vm.startPrank(randomUser);
        uint256 amount_ = 1 ether; // 1x10^8 (esta es la unidad de ether, no confundir con la moneda)
        //Para que el test este correcto debería restar la cantidad de tokens después de mintear
        //menos la cantidad de tokens antes de mintear, y ese resultado debería ser igual a la cantidad 
        //que estoy minteando
        //Token Balance Previous
        //Obtendremos el balance usando IERC20 porque ahora tenemos que inicializar el token como tal
        //siendo un objeto y llamando a una de sus funciones que es balanceOf()
        //Creamos el objeto: interfaz + address
        uint256 balanceBefore_ = IERC20(address(stakingToken)).balanceOf(randomUser); //Ej: UserA = 50 tokens
        stakingToken.mint(amount_); //Ej: Mintea 1 token
        //Token balance after
        uint256 balanceAfter_ = IERC20(address(stakingToken)).balanceOf(randomUser); //Ej: UserA = 51 tokens
        //Validamos que la condición se cumple
        assert(balanceAfter_ - balanceBefore_ == amount_); // 51 tokens - 50 tokens = 1 token
        vm.stopPrank();
    }
}