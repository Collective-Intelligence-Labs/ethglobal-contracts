const fs = require("fs");

const Dispatcher = artifacts.require("Dispatcher");
const CommandHandlersRegistery = artifacts.require("AggregateRepository")
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

  const registery = await deployer.deploy(CommandHandlersRegistery);
  output += "CommandHandlersRegistery: " + CommandHandlersRegistery.address + "\n";

  const dispatcher = await deployer.deploy(Dispatcher);
  output += "Dispatcher: " + Dispatcher.address + "\n";

  dispatcher.setRegistery(CommandHandlersRegistery.address)

  const eventStore = await deployer.deploy(EventStore, "0xCf1c39D9Bd5768C853337005Cf6A4499e585d94b");
  output += "EventStore: " + EventStore.address + "\n";

  const aggregateRepository = await deployer.deploy(AggregateRepository, eventStore.address, dispatcher.address);
  output += "AggregateRepostory: " + AggregateRepository.address + "\n";

  await deployer.deploy(AddLiquidityHandler, AggregateRepository.address )

  try {
    const fileName = "./" + deployer.network + ".log";
    fs.writeFileSync(fileName, output);
  } catch (err) {
    console.log(err);
  }
};