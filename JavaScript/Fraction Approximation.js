const prompt = require('prompt-sync')();
const { create, all } = require('mathjs')

let number = prompt('Please enter a number:');

let prec = number.length + 3;
const config = {
    // Default type of number
    // Available options: 'number' (default), 'BigNumber', or 'Fraction'
    number: 'BigNumber',
  
    // Number of significant digits for BigNumbers
    precision: prec
}
const math = create(all, config)

number = math.bignumber(number);
let operations = 0;
let maxOps = prompt('Please enter max operations:');

let floor = math.bignumber(Math.floor(number));
let floorDen = math.bignumber(1);
let ceil = math.bignumber(Math.ceil(number));
let ceilDen = math.bignumber(1);
let currentNum = 0;
let currentDen = 0;

let endEarly = false;

while(operations < maxOps){
    currentNum = floor + ceil;
    currentDen = floorDen + ceilDen;
    if(number < math.evaluate(currentNum / currentDen)){
        ceil = currentNum;
        ceilDen = currentDen;
    }else if(number > math.evaluate(currentNum / currentDen)){
        floor = currentNum;
        floorDen = currentDen;
    }else{
        console.log(`The fraction ${currentNum}/${currentDen} is equal to ${number}.`);
        endEarly = true;
        break;
    }
    operations++;
}

if(!endEarly){
    console.log(`The fraction ${currentNum}/${currentDen} is the closest approximation to ${number}.`);
}
