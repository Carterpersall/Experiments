const prompt = require('prompt-sync')();

let number = prompt('Please enter a number:');

let operations = 0;
let maxOps = prompt('Please enter max operations:');

let floor = Math.floor(number);
let floorDen = 1;
let ceil = Math.ceil(number);
let ceilDen = 1;
let currentNum = 0;
let currentDen = 0;

let endEarly = false;

while(operations < maxOps){
    currentNum = floor + ceil;
    currentDen = floorDen + ceilDen;
    if(number < (currentNum / currentDen)){
        ceil = currentNum;
        ceilDen = currentDen;
    }else if(number > (currentNum / currentDen)){
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
