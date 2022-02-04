const { BigNumber } = require('ethers');
const { clone } = require('lodash');

// helpers

const BN = BigNumber.from;
BigNumber.prototype.toJSON = function () {
  return `BN( ${this.toString()} )`;
};

const zip = (rows) => rows[0].map((_, c) => rows.map((row) => row[c]));

const objectMap = (obj, fn) => Object.fromEntries(Object.entries(obj).map(([k, v], i) => [k, fn(k, v, i)]));

const promiseAllObj = async (obj) => Object.fromEntries(zip([Object.keys(obj), await Promise.all(Object.values(obj))]));

const BNArray = (array) => array.map((i) => BN(i));

const filterFirstEventArgs = (receipt, event) => receipt.events.filter((logs) => logs.event == event)[0].args;

const shuffleArray = (arr) => {
  arr = [...arr];
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  return arr;
};

const randomElement = (arr, { filter } = {}) => {
  if (arr.constructor == Object) arr = Object.entries(arr);
  if (filter) arr = arr.filter((el) => filter(el));
  return arr[Math.floor(Math.random() * arr.length)] || [];
};

const randomElements = (arr, { min = 0, max, filter } = {}) => {
  if (arr.constructor == Object) arr = Object.entries(arr);
  if (filter) arr = arr.filter((el) => filter(el));
  let num = randInt(min, max && max < arr.length ? max : arr.length);
  return shuffleArray(arr).slice(0, num);
};

const randInt = (min, max) => {
  // console.log('call randi', min, max);
  if (max == undefined) [min, max] = [0, min];
  const rand = Math.floor(Math.random() * max) + min;
  // console.log('randint', min, max, rand);
  return rand;
};

const removeElement = (arr, el) => arr.splice(arr.indexOf(el), 1);
const removeElements = (arr, els) => {
  for (let el of els) removeElement(arr, el);
};

const range = (len) => [...Array(len)].map((_, i) => i);

function centerTime(time) {
  const start = parseInt(time || new Date().getTime() / 1000);

  var time = { start: BN(start) };

  const delta1s = 1;
  const delta1m = 1 * 60;
  const delta1h = 1 * 60 * 60;
  const delta1d = 24 * 60 * 60;

  for (let i = 0; i < 60; i++) {
    time[`delta${i}s`] = BN(i * delta1s);
    time[`delta${i}m`] = BN(i * delta1m);
    time[`delta${i}h`] = BN(i * delta1h);
    time[`delta${i}d`] = BN(i * delta1d);
    time[`delta${i}y`] = BN(i * 365 * delta1d);
    time[`future${i}s`] = BN(start + i * delta1s);
    time[`future${i}m`] = BN(start + i * delta1m);
    time[`future${i}h`] = BN(start + i * delta1h);
    time[`future${i}d`] = BN(start + i * delta1d);
    time[`future${i}y`] = BN(start + i * 365 * delta1d);
  }

  time.now = async () => BN(await getBlockTimestamp());
  time.elapsed = async (t) => BN(await getBlockTimestamp()).sub(t || time.start);
  time.future = (t) => time.start.add(t);

  time.centerTime = centerTime;
  time.jumpToTime = jumpToTime;
  time.advance = advanceTime;
  time.timestamp = getBlockTimestamp;

  if (Object.keys(this).length !== 0) return Object.assign(this, time);

  return time;
}

const jumpToTime = async (t) => {
  await network.provider.send('evm_mine', [t.toNumber()]);
  return centerTime(t);
};

const advanceTime = async (t) => {
  let current = await getBlockTimestamp();
  let time = centerTime(current);
  // console.log('calling advance', current.toString(), '->', time.future(t).toString());
  return await jumpToTime(time.future(t));
};

const getBlockTimestamp = async () => {
  let blocknum = await network.provider.request({ method: 'eth_blockNumber' });
  let block = await network.provider.request({
    method: 'eth_getBlockByNumber',
    params: [blocknum, true],
  });
  return BN(block.timestamp).toString();
};

const time = centerTime();

// misc

const signWhitelist = async (signer, contractAddress, userAccount, data) => {
  userAccount = ethers.utils.getAddress(userAccount);
  contractAddress = ethers.utils.getAddress(contractAddress);

  return await signer.signMessage(
    ethers.utils.arrayify(
      ethers.utils.keccak256(
        ethers.utils.defaultAbiCoder.encode(['address', 'uint256', 'address'], [contractAddress, data, userAccount])
      )
    )
  );
};

const verify = async function (address, constructorArguments) {
  console.log(
    'verifying',
    address,
    (constructorArguments && `with arguments ${constructorArguments.join(', ')}`) || ''
  );
  await hre.run('verify:verify', {
    address,
    constructorArguments,
  });
};

module.exports = Object.freeze({
  time,
  centerTime,
  jumpToTime,
  advanceTime,
  getBlockTimestamp,
  signWhitelist,
  verify,
  BN,
  BNArray,
  zip,
  objectMap,
  promiseAllObj,
  filterFirstEventArgs,
  shuffleArray,
  randomElement,
  randomElements,
  removeElement,
  removeElements,
  range,
  randInt,
});
