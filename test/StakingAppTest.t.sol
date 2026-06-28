// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
//importamos la librería de test de Foundry
import "forge-std/Test.sol";
//importamos nuestro contrato de Staking Token
import "../src/StakingToken.sol";
//importamos nuestro contrato de Staking App
import "../src/StakingApp.sol";
//IERC20 library
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract StakingAppTest is Test {
    //Heredamos de la librería Test de Foundry
    //Declaramos los objetos de los contratos como tal
    StakingToken stakingToken;
    StakingApp stakingApp;

    //Staking Token Parameters
    string name_ = "Staking Token";
    string symbol_ = "STK";

    //StakingApp Parameters
    address owner_ = vm.addr(1);
    uint256 stakingPeriod_ = 1000000000000; 
    uint256 fixedStakingAmount_ = 10;
    uint256 rewardPerPeriod_ = 1 ether;

    address randomUser = vm.addr(2);

    //1._ SETUP: necesitamos inicializar los contratos de StakingToken y StakingApp para poder 
    //usarlos en los test
    function setUp() external {
        //setUp: función reservada por Foundry, que se va a ejecutar siempre ante de cada test
        //de esta forma siempre tendremos la inicialización de nuestros smart contracts
        //inicializo el objeto StakingToken:
        stakingToken = new StakingToken(name_, symbol_);
        stakingApp = new StakingApp(address(stakingToken), owner_, stakingPeriod_, fixedStakingAmount_, rewardPerPeriod_);
    }

    //2._ TEST

    //1._test: testear si los smart contract se han deployeado correctamente
    function testStakingTokenCorrectlyDeployed() external view{
        //Testeamos si la address del Staking Token es distinta a la address(0), es decir, si tiene una address real
        assert(address(stakingToken) != address(0));

    }

    function testStakingAppCorrectlyDeployed() external view{
        //Testeamos si la address del Staking Token es distinta a la address(0), es decir, si tiene una address real
        assert(address(stakingApp) != address(0));

    }

    //2._ test: changeStakingPeriod falla ya que la llama alguien que no es el Owner
    function testShouldRevertIfNotOwner() external {
        uint256 newStakingPeriod = 1;
        //Como queremos testear que algo revierte, usamos:
        vm.expectRevert();
        stakingApp.changeStakingPeriod(newStakingPeriod);
    }

    //3._ test: changeStakingPeriod pasa, ya que sí fué llamada por el Owner
    function testShouldChangeStakingPeriod() external {
        //Nos hacemos pasar por el owner (impersonar), ahora no revierte!
        vm.startPrank(owner_);
        uint256 newStakingPeriod = 1;

        //Capturo el valor de stakingPeriod antes y después, para luego verificar la validación 
        //con los assert
        uint256 stakingPeriodBefore = stakingApp.stakingPeriod();
        stakingApp.changeStakingPeriod(newStakingPeriod);
        uint256 stakingPeriodAfter = stakingApp.stakingPeriod();


        assert(stakingPeriodBefore != newStakingPeriod);
        assert(stakingPeriodAfter == newStakingPeriod);
        vm.stopPrank();

    }

    //4._ test: Vamos a testear que el smart contract pueda recibir ether, es decir la funcón receive:
    function testContractReceivesEtherCorrectly() external {
        vm.startPrank(owner_); //impersonamos al owner
        vm.deal(owner_, 1 ether); //"llenamos" la cuenta con 1 ether (red local)
        //Recibimos Ether con la función call
        uint256 etherValue = 1 ether;
        
        //capturo la cantidad de Ether que tiene mi Smart Contract: address(this).balance;
        uint256 balanceBefore = address(stakingApp).balance; 
        (bool success, ) = address(stakingApp).call{value: etherValue}("");
        uint256 balanceAfter = address(stakingApp).balance;
        require(success, "Transfer Failed");

        assert(balanceAfter - balanceBefore == etherValue);
        vm.stopPrank();
    }

    //Deposit Function Testing
    //Vamos a testear uno a uno los require

    //5._ test: Verificamos que la cantidad a depositar sea diez (primer require de la función deposit):
    //require(tokenAmountToDeposit_ == fixedStakingAmount, "Incorrect amount");
    function testIncorrectAmountShouldRevert() external {
        vm.startPrank(randomUser);

        uint256 depositAmount = 1;
        vm.expectRevert("Incorrect amount");
        stakingApp.depositTokens(depositAmount);

        vm.stopPrank();
    }

    //6._ test: Ahora si testeamos la función de deposito como tal
    function testDepositTokensCorrectly() external {
        vm.startPrank(randomUser);

        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        //nos minteamos tokens a nosotros mismos
        stakingToken.mint(tokenAmount);
        //Verificamos el userBalance antes y después de la transacción
        uint256 userBalanceBefore = stakingApp.userBalance(randomUser);
        //Verificamos el elapsePeriod antes y después de la transacción
        uint256 elapsePeriodBefore = stakingApp.elapsePeriod(randomUser);
        //aprobamos la trasacción de un tercero (el smart contract)
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount);
        uint256 userBalanceAfter = stakingApp.userBalance(randomUser);
        uint256 elapsePeriodAfter = stakingApp.elapsePeriod(randomUser);

        assert(userBalanceAfter - userBalanceBefore == tokenAmount);
        assert(elapsePeriodBefore == 0);
        assert(elapsePeriodAfter == block.timestamp);
        

        vm.stopPrank();
    }

    //7._ test: Testeamos que el usuario no pueda depositar dos veces
    //Básicamente repetimos el proceso otra vez, esperando que revierta
    function testUserCanNotDepositMoreThanOnce() external {
        vm.startPrank(randomUser);

        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        //nos minteamos tokens a nosotros mismos
        stakingToken.mint(tokenAmount);
        //Verificamos el userBalance antes y después de la transacción
        uint256 userBalanceBefore = stakingApp.userBalance(randomUser);
        //Verificamos el elapsePeriod antes y después de la transacción
        uint256 elapsePeriodBefore = stakingApp.elapsePeriod(randomUser);
        //aprobamos la trasacción de un tercero (el smart contract)
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount); //depositamos
        uint256 userBalanceAfter = stakingApp.userBalance(randomUser);
        uint256 elapsePeriodAfter = stakingApp.elapsePeriod(randomUser);

        assert(userBalanceAfter - userBalanceBefore == tokenAmount);
        assert(elapsePeriodBefore == 0);
        assert(elapsePeriodAfter == block.timestamp);

        //nos minteamos tokens a nosotros mismos x2
        stakingToken.mint(tokenAmount);
        //aprobamos la trasacción de un tercero (el smart contract) x2
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        vm.expectRevert("User already deposited");
        stakingApp.depositTokens(tokenAmount); //depositamos x2

        vm.stopPrank();
    }

    //Withdraw Function Testing
    //8._ test: Intentar retirar fondos que no tenemos
    function testCanOnlyWithdraw0WithoutDeposit() external {
        vm.startPrank(randomUser);

        uint256 userBalanceBefore = stakingApp.userBalance(randomUser);
        stakingApp.withdrawTokens();
        uint256 userBalanceAfter = stakingApp.userBalance(randomUser);
        //El balance debe ser el mismo, antes y después de retirar fondos que no tenemos
        assert(userBalanceAfter == userBalanceBefore);
        vm.stopPrank();

    }

    //9._ test: Intentamos retirar fondos que si tenemos
    function testWithdrawTokensCorrectly() external {
        vm.startPrank(randomUser);

        //Copiamos lo mismo que el deposit:

        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        //nos minteamos tokens a nosotros mismos
        stakingToken.mint(tokenAmount);
        //Verificamos el userBalance antes y después de la transacción
        uint256 userBalanceBefore = stakingApp.userBalance(randomUser);
        //Verificamos el elapsePeriod antes y después de la transacción
        uint256 elapsePeriodBefore = stakingApp.elapsePeriod(randomUser);
        //aprobamos la trasacción de un tercero (el smart contract)
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount); //depositamos
        uint256 userBalanceAfter = stakingApp.userBalance(randomUser);
        uint256 elapsePeriodAfter = stakingApp.elapsePeriod(randomUser);

        assert(userBalanceAfter - userBalanceBefore == tokenAmount);
        assert(elapsePeriodBefore == 0);
        assert(elapsePeriodAfter == block.timestamp);

        //Ahora hacemos la llamada a withDraw

        //Saco el balance del usuario: 
        uint256 userBalanceBefore2 = IERC20(stakingToken).balanceOf(randomUser);
        //Calculamos cuanto es el balance del usuario antes del retiro
        uint256 userBalanceInMapping = stakingApp.userBalance(randomUser);
        stakingApp.withdrawTokens();
        uint256 userBalanceAfter2 = IERC20(stakingToken).balanceOf(randomUser);

        assert(userBalanceAfter2 == userBalanceBefore2 + userBalanceInMapping);

        vm.stopPrank();

    }
    
    //Claim rewards Function test
    //10._ test://Comprueba que si no estamos haciendo staking, no podemos llamar a Claim Reward
    //require(userBalance[msg.sender] == fixedStakingAmount, "Not staking");
    function testCanNotClaimIfNotStaking() external {
        vm.startPrank(randomUser);


        //Como el usuario randomUser no está stakeando, debería revertir
        vm.expectRevert("Not staking");
        stakingApp.claimRewards();

        vm.stopPrank();
    }

    //11._ test: No ha pasado suficiente periodo de tiempo para recibir rewards
    //require(elapsePeriod_ >= stakingPeriod, "Need to wait");
    //Tenemos que hacer un deposito, y luego esperar menos tiempo que el stakingPeriod
    function testCanNotClaimIfNotElapsedTime() external {
        vm.startPrank(randomUser);

        //Depositamos:
        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        //nos minteamos tokens a nosotros mismos
        stakingToken.mint(tokenAmount);
        //Verificamos el userBalance antes y después de la transacción
        uint256 userBalanceBefore = stakingApp.userBalance(randomUser);
        //Verificamos el elapsePeriod antes y después de la transacción
        uint256 elapsePeriodBefore = stakingApp.elapsePeriod(randomUser);
        //aprobamos la trasacción de un tercero (el smart contract)
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount); //depositamos
        uint256 userBalanceAfter = stakingApp.userBalance(randomUser);
        uint256 elapsePeriodAfter = stakingApp.elapsePeriod(randomUser);

        assert(userBalanceAfter - userBalanceBefore == tokenAmount);
        assert(elapsePeriodBefore == 0);
        assert(elapsePeriodAfter == block.timestamp);

        //Como las funciones se ejecutan todas de golpe (atómicamente), no hay suficiente 
        //tiempo que supere el stakingPeriod, por lo tanto debería revertir
        vm.expectRevert("Need to wait");
        stakingApp.claimRewards();

        vm.stopPrank();
    }

    //12._ Fallará por falta de Ether
    //¿Cómo hacemos que pase el tiempo?
    // vm.warp(el momento en el tiempo al que me quiero mover)
    function testShouldRevertIfNoEther() external {
        vm.startPrank(randomUser);

        //Depositamos:
        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        //nos minteamos tokens a nosotros mismos
        stakingToken.mint(tokenAmount);
        //Verificamos el userBalance antes y después de la transacción
        uint256 userBalanceBefore = stakingApp.userBalance(randomUser);
        //Verificamos el elapsePeriod antes y después de la transacción
        uint256 elapsePeriodBefore = stakingApp.elapsePeriod(randomUser);
        //aprobamos la trasacción de un tercero (el smart contract)
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount); //depositamos
        uint256 userBalanceAfter = stakingApp.userBalance(randomUser);
        uint256 elapsePeriodAfter = stakingApp.elapsePeriod(randomUser);

        assert(userBalanceAfter - userBalanceBefore == tokenAmount);
        assert(elapsePeriodBefore == 0);
        assert(elapsePeriodAfter == block.timestamp);

        vm.warp(block.timestamp + stakingPeriod_);
        vm.expectRevert("Transfer failed");
        stakingApp.claimRewards();

        vm.stopPrank();
    }

    //13._ test: Ahora si que tendremos que dejar que pase el periodo de tiempo de staking
    //para que ahora si pase el test.

    //Explicación:
    //1._randomUser hace un deposit, deposita sus tokens, se queda esperando
    //2._dejamos de impersonar al randomUser
    //3._empezamos a impersonar al owner
    //4._Ahora el owner consigue ether
    //5._El owner le manda ether al smart contract
    //6._El smart contract ya tiene ether
    //7._Dejamos de impersonar al owner
    //8._Impersonamos al randomUser para hacer el claim de sus rewards
    //9._El randomUser deja de ser impersonado
    function testCanClaimRewardsCorrectly() external {
        vm.startPrank(randomUser);

        //Depositamos:
        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        //nos minteamos tokens a nosotros mismos
        stakingToken.mint(tokenAmount);
        //Verificamos el userBalance antes y después de la transacción
        uint256 userBalanceBefore = stakingApp.userBalance(randomUser);
        //Verificamos el elapsePeriod antes y después de la transacción
        uint256 elapsePeriodBefore = stakingApp.elapsePeriod(randomUser);
        //aprobamos la trasacción de un tercero (el smart contract)
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount); //depositamos
        uint256 userBalanceAfter = stakingApp.userBalance(randomUser);
        uint256 elapsePeriodAfter = stakingApp.elapsePeriod(randomUser);

        assert(userBalanceAfter - userBalanceBefore == tokenAmount);
        assert(elapsePeriodBefore == 0);
        assert(elapsePeriodAfter == block.timestamp);

        //¿Quién puede mandar fondos? --> Sólo los puede mandar el owner
        //Justo antes del claimRewards vamos a impersonar al owner, vamos a mandar fondos,
        //y luego vamos a dejar de impersonar al owner
        vm.stopPrank();

        vm.startPrank(owner_);
        //Aquí mandamos el ether
        uint256 etherAmount = 100000 ether;
        vm.deal(owner_, etherAmount);
        (bool success, ) = address(stakingApp).call{value: etherAmount}("");
        require(success, "Test Transfer Failed");
        vm.stopPrank();

        vm.startPrank(randomUser);
        vm.warp(block.timestamp + stakingPeriod_);
        uint256 etherAmountBefore = address(randomUser).balance;
        stakingApp.claimRewards();
        uint256 etherAmountAfter = address(randomUser).balance;
        uint256 elapsedPeriod = stakingApp.elapsePeriod(randomUser);

        assert(etherAmountAfter - etherAmountBefore == rewardPerPeriod_);
        assert(elapsedPeriod == block.timestamp); //Testeamos que el elapsedPeriod se ha modificado


        vm.stopPrank();
    }













}