const fs = require("fs");

const AMMAggregate = artifacts.require("AMMAggregate");

const Dispatcher = artifacts.require("Dispatcher");
const CommandHandlersRegistery = artifacts.require("CommandHandlersRegistery");
const EventStore = artifacts.require("EventStore");
const AggregateRepository = artifacts.require("AggregateRepository");

const AddLiquidityHandler = artifacts.require("AddLiquidityHandler");
const SwapTokensHandler = artifacts.require("SwapTokensHandler");
const CreateAMMHandler = artifacts.require("CreateAMMHandler");
const RemoveLiquidityHandler = artifacts.require("RemoveLiquidityHandler");
const WithdrawFundsHandler = artifacts.require("WithdrawFundsHandler");
const DepositFundsHandler = artifacts.require("DepositFundsHandler");



module.exports = async function(deployer) {
  let output = "";

  await deployer.deploy(CommandHandlersRegistery);
  const registery = await CommandHandlersRegistery.deployed();
  output += "CommandHandlersRegistery: " + CommandHandlersRegistery.address + "\n";

  await deployer.deploy(Dispatcher);
  const dispatcher = await Dispatcher.deployed();
  output += "Dispatcher: " + Dispatcher.address + "\n";

  await dispatcher.addRouter("0xCf1c39D9Bd5768C853337005Cf6A4499e585d94b");
  await dispatcher.setRegistery(CommandHandlersRegistery.address);

  await deployer.deploy(EventStore, "0xCf1c39D9Bd5768C853337005Cf6A4499e585d94b");
  const eventStore = await EventStore.deployed();
  output += "EventStore: " + EventStore.address + "\n";

  await deployer.deploy(AggregateRepository, EventStore.address, Dispatcher.address);
  const aggregateRepository = await AggregateRepository.deployed();
  output += "AggregateRepostory: " + AggregateRepository.address + "\n";

  // await deployer.deploy(AMMAggregate, "8863F36E552Fd66296C0b3a3D2e402810522AMM1");
  // const aggreagate = await AMMAggregate.deployed();

  // await aggregateRepository.addAggregate("8863F36E552Fd66296C0b3a3D2e402810522AMM1", AMMAggregate.address);
  // console.log(await aggreagateRepository.get("8863F36E552Fd66296C0b3a3D2e402810522AMM1"));

  await deployer.deploy(CreateAMMHandler, AggregateRepository.address);
  const createAMMHandler = await CreateAMMHandler.deployed();
  output += "CreateAMMHandler: " + CreateAMMHandler.address + "\n";

  await deployer.deploy(AddLiquidityHandler, AggregateRepository.address);
  const addLiquidityHandler = await AddLiquidityHandler.deployed();
  output += "AddLiquidityHandler: " + AddLiquidityHandler.address + "\n";

  await deployer.deploy(RemoveLiquidityHandler, AggregateRepository.address);
  const removeLiquidityHandler = await RemoveLiquidityHandler.deployed();
  output += "RemoveLiquidityHandler: " + RemoveLiquidityHandler.address + "\n";

  await deployer.deploy(SwapTokensHandler, AggregateRepository.address);
  const swapTokensHandler = await SwapTokensHandler.deployed();
  output += "SwapTokensHandler: " + SwapTokensHandler.address + "\n";

  await deployer.deploy(DepositFundsHandler, AggregateRepository.address);
  const depositFundsHandler = await DepositFundsHandler.deployed();
  output += "DepositFundsHandler: " + DepositFundsHandler.address + "\n";

  await deployer.deploy(WithdrawFundsHandler, AggregateRepository.address);
  const withdrawFundsHandler = await WithdrawFundsHandler.deployed();
  output += "WithdrawFundsHandler: " + WithdrawFundsHandler.address + "\n";

  await registery.setHandler(3, CreateAMMHandler.address);
  await registery.setHandler(4, AddLiquidityHandler.address);
  await registery.setHandler(5, RemoveLiquidityHandler.address);
  await registery.setHandler(6, SwapTokensHandler.address);
  await registery.setHandler(7, DepositFundsHandler.address);
  await registery.setHandler(8, WithdrawFundsHandler.address);

  try {
    const fileName = "./" + deployer.network + ".log";
    fs.writeFileSync(fileName, output);
  } catch (err) {
    console.log(err);
  }
};