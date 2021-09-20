import * as Witnet from "witnet-requests";

//witnet-requests/dist/radon/types
//Ha sztringeket akarunk lekérni akkor mode kell nem averageMean
//A filter is mode legyen ha sztring van

const tweet = new Witnet.Source(
  "https://api-middlewares.vercel.app/api/twitter/tweets/0000000000000000000"
)
  .parseJSONMap()
  .getInteger("likes");

// Filters out any value that is more than 1.1 times the standard
// deviation away from the average, then computes the average mean of the
// values that pass the filter.
const aggregator = new Witnet.Aggregator({
  filters: [[Witnet.Types.FILTERS.deviationStandard, 1.1]],
  reducer: Witnet.Types.REDUCERS.averageMean
});

// Filters out any value that is more than 1.1 times the standard
// deviationaway from the average, then computes the average mean of the
// values that pass the filter.
const tally = new Witnet.Tally({
  filters: [[Witnet.Types.FILTERS.deviationStandard, 1.1]],
  reducer: Witnet.Types.REDUCERS.averageMean
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
