let twitterAuth;
let pointCounter;
let pointCounterFactory;
let signer;
let account;
let localStorage;

// Addresses of the Twitter Auth and the Point Counter Factory contracts
const AUTH_ADDRESS = '0x844383dFB922026B8637266a9369dAC64a56A678';
const FACTORY_ADDRESS = '0xe7BBB2E52dc6528aAb6FDCcCF43ADF67cD170aC3';

const WITNET_ADDRESS = '0xb58D05247d16b3F1BD6B59c52f7f61fFef02BeC8';

// Helper function for getting value of input fields
const parseInput = (id) => document.getElementById(id).value;
const setValue = (id, value) => (document.getElementById(id).value = value);

const init = async () => {
  localStorage = window.localStorage;

  if (typeof window.ethereum === 'undefined') {
    alert('MetaMask is not installed!');
    throw new Error('MetaMask is not installed!');
  } else {
    const accounts = await ethereum.request({ method: 'eth_requestAccounts' });
    account = accounts[0];

    const provider = new ethers.providers.Web3Provider(window.ethereum);
    signer = provider.getSigner();

    let response = await fetch('./TwitterAuth.json');
    let data = await response.json();
    twitterAuth = new ethers.Contract(AUTH_ADDRESS, data.abi, signer);

    response = await fetch('./TwitterPointCounterFactory.json');
    data = await response.json();
    pointCounterFactory = new ethers.Contract(
      FACTORY_ADDRESS,
      data.abi,
      signer,
    );
  }
};

const queryId = async () => {
  const tweetId = parseInput('tweet-id');
  try {
    await twitterAuth.checkTwitterID(tweetId, {
      gasLimit: 3000000,
      value: ethers.utils.parseEther('0.00102496'),
    });
  } catch (e) {
    alert(e);
  }
};

const link = async () => {
  try {
    await twitterAuth.extractTwitterId();
  } catch (e) {
    alert(e);
  }
};

const create = async () => {
  const tweetId = parseInput('tweet-id-for-contract');
  const reward = parseInput('reward-for-likes');
  try {
    await pointCounterFactory.createTwitterPointCounter(
      WITNET_ADDRESS,
      AUTH_ADDRESS,
      tweetId,
      ethers.utils.parseEther(reward),
    );
  } catch (e) {
    alert(e);
  }
};

const getCounterAddressFromId = async (id) => {
  let address = '';
  try {
    address = await pointCounterFactory.pointCounterOfTweet(id);
  } catch (e) {
    alert(e);
  }
  return address;
};

const displayCounterAddress = async () => {
  let address = await getCounterAddressFromId(
    parseInput('tweet-id-for-contract'),
  );
  document.getElementById('counter-address').innerHTML = address;
};

const queryLikers = async () => {
  let counterAddress = await getCounterAddressFromId(
    parseInput('tweet-id-for-contract'),
  );
  let response = await fetch('./TwitterPointCounter.json');
  let data = await response.json();
  pointCounter = new ethers.Contract(counterAddress, data.abi, signer);
  try {
    await pointCounter.requestPoints({
      gasLimit: 3000000,
      value: ethers.utils.parseEther('0.00102496'),
    });
  } catch (e) {
    alert(e);
  }
};

const refreshLikers = async () => {
  let counterAddress = await getCounterAddressFromId(
    parseInput('tweet-id-for-contract'),
  );
  let response = await fetch('./TwitterPointCounter.json');
  let data = await response.json();
  pointCounter = new ethers.Contract(counterAddress, data.abi, signer);
  try {
    await pointCounter.getPoints({
      gasLimit: 3000000,
    });
  } catch (e) {
    alert(e);
  }
};

const newLikers = async () => {
  let counterAddress = await getCounterAddressFromId(
    parseInput('tweet-id-for-contract'),
  );
  let newLikesArray = (
    await axios.get(
      `https://api-middlewares.vercel.app/api/twitter/stats/${counterAddress.toLowerCase()}`,
    )
  ).data.likers;
  document.getElementById('num-of-new-likes').innerHTML = newLikesArray.length;
};

const getReward = async () => {
  let counterAddress = await getCounterAddressFromId(
    parseInput('tweet-id-for-user'),
  );
  let response = await fetch('./TwitterPointCounter.json');
  let data = await response.json();
  pointCounter = new ethers.Contract(counterAddress, data.abi, signer);
  try {
    await pointCounter.withdrawReward({
      gasLimit: 3000000,
    });
  } catch (e) {
    alert(e);
  }
};

const setReward = async () => {
  const reward = parseInput('reward-for-likes');
  let counterAddress = await getCounterAddressFromId(
    parseInput('tweet-id-for-contract'),
  );
  let response = await fetch('./TwitterPointCounter.json');
  let data = await response.json();
  pointCounter = new ethers.Contract(counterAddress, data.abi, signer);
  try {
    await pointCounter.setReward(ethers.utils.parseEther(reward));
  } catch (e) {
    alert(e);
  }
};

const destroy = async () => {
  let counterAddress = await getCounterAddressFromId(
    parseInput('tweet-id-for-contract'),
  );
  let response = await fetch('./TwitterPointCounter.json');
  let data = await response.json();
  pointCounter = new ethers.Contract(counterAddress, data.abi, signer);
  try {
    await pointCounter.removeFunds({
      gasLimit: 3000000,
    });
  } catch (e) {
    alert(e);
  }
};
