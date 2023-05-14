const fs = require("fs");

const Dispatcher = artifacts.require("Dispatcher");
const EventStore = artifacts.require("EventStore");
const AggregateRepository = artifacts.require("AggregateRepository");

module.exports = function(deployer) {
    var output = "";
    deployer.deploy(Dispatcher).then(() => {
        try {
            output += "Dispatcher: " + Dispatcher.address + "\n";
            var fileName = "./" + deployer.network + ".log";
            fs.writeFileSync(fileName, output);
        } catch (err) {
            console.log(err);
        } 
    });
    
    // deployer.deploy(EventStore, "0xCf1c39D9Bd5768C853337005Cf6A4499e585d94b").then(() => {
    //     deployer.deploy(AggregateRepository, EventStore.address);
    // });
    // Additional contracts can be deployed here
};