const TwitterPointCounterFactory = artifacts.require(
  "TwitterPointCounterFactory"
);

module.exports = async function (deployer) {
  await deployer.deploy(TwitterPointCounterFactory);
};
