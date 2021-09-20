import * as Witnet from "witnet-requests";

const tweet = new Witnet.Source(
  "https://api-middlewares.vercel.app/api/twitter/tweets/0000000000000000000"
)
  .parseJSONMap()
  .getArray("auth");

const aggregator = new Witnet.Aggregator({
  filters: [[Witnet.Types.FILTERS.mode]],
  reducer: Witnet.Types.REDUCERS.mode
});

const tally = new Witnet.Tally({
  filters: [[Witnet.Types.FILTERS.mode]],
  reducer: Witnet.Types.REDUCERS.mode
});

// prettier-ignore
const request = new Witnet.Request()
  .addSource(tweet) // Use the source
  .setQuorum(10) // Set witness count
  .setAggregator(aggregator) // Set the aggregation script
  .setTally(tally) // Set the tally script
  .setFees(1000000, 1000) // Set economic incentives (e.g. reward: 1 mWit, fee: 1 uWit)
  .setCollateral(10000000000) // Set collateral (e.g. 10 Wit)

export { request as default };
