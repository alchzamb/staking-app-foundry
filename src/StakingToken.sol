// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
//Uso las herramientas del contrato ERC20.sol para crear mi token
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract StakingToken is ERC20{
    //inicializo el constructor de ERC20 y luego mi constructor
    //le paso los mismos parámetros a ambos constructores
    //inicializa el constructor del "PADRE" y luego el del contrato "HIJO"
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    //la función mint del contrato ERC20 es internal por defecto, es decir solo se puede
    //llamar desde dentro del contrato, pero como nosotros queremos que el usuario mintee los 
    //tokens crearemos una función de minteo que sea external, que llame a la función mint de ERC20
    //amount: la cantidad que queremos mintear
    function mint(uint256 amount_) external {
        _mint(msg.sender, amount_);
        //para mintear tokens, solo necesito llamar a la función _mint de ERC20, y pasarle por 
        //parámetros la dirección de nuestra cuenta(quien va a recibir los tokens),
        //y la cantidad de tokens a mintear
    }
}