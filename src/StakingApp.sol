// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

//Reglas del staking:
//staking fixed amount. Ejemplo: solo puedo stakear exactamente 10 tokens
//staking reward period: el tiempo necesario en que debo mantener mis monedas para recibir rewards
//Ejemplo: si sr = 1 día, el usuario debería esperar 1 día para poder recoger rewards

contract StakingApp is Ownable {
    //1._ StakingToken address: queremos que cuando inicialicemos nuestra StakingApp recibir por 
    //parámetro la address del token que vamos a utilizar para hacer Staking
    //2._ Un admin: para hacer el access control, meter fees. Es decir como si fuera un protocolo 
    //real de Staking.

    //Variables
    address public stakingToken;
    uint256 public stakingPeriod;
    uint256 public fixedStakingAmount;
    uint256 public rewardPerPeriod;
    //Para comprobar y actualizar los balances de cada usuario hacemos un mapping
    mapping (address => uint256) public userBalance;
    //Queremos saber cuando el usuario empezó a stakear, para calcular su tiempo de stakeo
    //y con ello definir si puede o no acceder a sus reward. Usaremos otro mapping:
    mapping (address => uint256) public elapsePeriod;

    //Events

    //emito el evento con mi nuevo staking period
    event ChangeStakingPeriod(uint256 newStakingPeriod_);
    //evento de deposito
    event DepositTokens(address userAddress_, uint256 depositAmount_);
    //evento de retiro
    event WithdrawTokens(address userAddress_, uint256 withdrawAmount_);
    event EtherSent(uint256 amount_);
    
    //cuando escribes Ownable(owner_) en la firma de tu constructor, le estás diciendo a Solidity: 
    //"antes de ejecutar el cuerpo de mi constructor, ejecuta primero el constructor del 
    //padre (Ownable) y pásale este valor".

    //stakingToken_: token que vamos a usar para depositar el staking
    //owner_: el admin como tal
    constructor(address stakingToken_, address owner_, uint256 stakingPeriod_, uint256 fixedStakingAmount_, uint256 rewardPerPeriod_) Ownable(owner_) {
        stakingToken = stakingToken_;
        stakingPeriod = stakingPeriod_;
        fixedStakingAmount = fixedStakingAmount_; //regla de mi staking: solo 10 tokens
        rewardPerPeriod = rewardPerPeriod_;
    }

    //functions

    //External functions
    //1._ Deposit
    //Vamos a usar transferFrom() ya que mi smart contract usando la función de "deposit" 
    //va a coger los tokens y además, actualizar los datos del contrato
    //ese es el motivo por el cual usaremos transferFrom() en vez de transfer()
    //Y nuestro usario va a tener que hacer un approve antes de ello
    function depositTokens(uint256 tokenAmountToDeposit_) external {
        //validamos que solo puede stakear 10 tokens (regla de mi staking)
        require(tokenAmountToDeposit_ == fixedStakingAmount, "Incorrect amount");
        //Como en nuestras reglas el usuario solo puede stakear 10 tokens, antes de la transacción
        //debemos verificar que su balance sea 0. Así 0 + 10 = 10
        // userBalance[msg.sender] es el balance del usuario (uint256)
        require(userBalance[msg.sender] == 0, "User already deposited");

        //interfaz + address
        //transferFrom(from, to, amount)
        //from: la cartera de la que sacamos el dinero, que es quien está llamando a la función msg.sender
        //to: a que dirección queremos mandar los tokens, en este caso la dirección de mi smart contract 
        //StakingApp.sol ¿Cómo obtenemos ésta dirección? --> address(this)
        IERC20(stakingToken).transferFrom(msg.sender, address(this), tokenAmountToDeposit_);
        //accedemos a la cartera del usuario que está llamando
        userBalance[msg.sender] += tokenAmountToDeposit_; //actualizamos su balance
        elapsePeriod[msg.sender] = block.timestamp;

        emit DepositTokens(msg.sender, tokenAmountToDeposit_);
    }


    //2._ Withdraw
    //Dada la lógica de nuestro contrato, si permitimos que el usuario retire algo de sus tokens,
    //cuando quiera depositar, no lo podría hacer dado que su balance debe ser cero
    //Por lo tanto en esta función haremos que el usuario retire todos sus fondos de golpe
    function withdrawTokens() external {
        //IMPORTANTE: antes de actualizar el balance a cero, primero lo guardamos en una variable
        //porque sino, estaríamos transfiriendo cero tokens, me refiero a la variable "userBalance_"
        //1._ Guardo su balance en una variable
        //2._ Le actualizo su balance a cero en su cuenta
        //3._ Le transfiero los fondos

        uint256 userBalance_ = userBalance[msg.sender]; //primero guardo aquí su balance
        //CEI PATTERN: primero actualizo su saldo, y luego le transfiero los fondos
        //En este caso, como estamos usando las librerías de openzeppelin, no se triggea
        //ninguna función, sin embargo, como buena práctica, mantendremos la filosofía de 
        //trabajo CEI PATTERN --> 1._ Checks 2._ Effects 3._ Interactions
        userBalance[msg.sender] = 0; //como ya retiró sus 10 tokens, actualizo que su saldo es cero
        IERC20(stakingToken).transfer(msg.sender, userBalance_);
        //transfer(a quien enviamos, que cantidad)

        emit WithdrawTokens(msg.sender, userBalance_);
    }


    //3._ Claim Rewards
    function claimRewards() external {
        //CEI PATTERN:

        //1._Check Balance: revisar que el usuario esté stakeando tokens
        require(userBalance[msg.sender] == fixedStakingAmount, "Not staking");

        //2._ Calculate reward amount: calcular la cantidad de reward que el usuario va a poder retirar
        //Ej: Si mi stakingPeriod = 24h, pero mi elapsePeriod = 22h, no he cumplido el tiempo suficiente
        //para retirar mi recompensa. Pero ¿Cómo se calcula el elapsePeriod?
        //Resto el tiempo actual - el tiempo en el que hice mi depósito
        uint256 elapsePeriod_ = block.timestamp - elapsePeriod[msg.sender];
        require(elapsePeriod_ >= stakingPeriod, "Need to wait");

        //3._ Update state
        //Reiniciamos el reloj 
        elapsePeriod[msg.sender] = block.timestamp;

        //4._ Transfer rewards
        //Definimos la recompensa retirable por cada periodo, y transferimos
        (bool success, ) = msg.sender.call{value: rewardPerPeriod}("");
        //IMPORTANTE: ponemos un require, para asegurarnos que se ha transferido con éxito
        //La función .call nos devuelve si el dinero se ha transferido con éxito o no, 
        // pero no revierte la transacción, he aquí la importancia de validar con el require
        require(success, "Transfer failed");
    }

    //FEED CONTRACT
    //feed: vamos a hacer que el owner sea el que alimente el smart contract con ether
    //OJO: debe ser "payable" para que el smart contract pueda recibir ether
    //Vamos a esperar que sea el Owner como tal quien mande Ether cuando haga falta

    //function feedContract() external payable onlyOwner {}
    //Podríamos usar la linea de arriba, pero, para estudiar más cosas, vamos a usar receive, 
    //que hace exactamente lo mismo.
    receive() external payable onlyOwner {
        emit EtherSent(msg.value);
    }

    //Internal functions: no hay.

    //Luego de deployeado el contrato, el staking period quedaría fijo.
    //Vamos a crear una función para modificar el staking period, y que solo la pueda ejecutar el admin
    function changeStakingPeriod(uint256 newStakingPeriod_) external onlyOwner{
        stakingPeriod = newStakingPeriod_;
        emit ChangeStakingPeriod(newStakingPeriod_);
    }

}