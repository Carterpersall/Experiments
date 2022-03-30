const prompt = require('prompt-sync')();

let number = prompt('Please enter a number(auto for auto mode):');
let operations = 0;

if(number == 'auto') {
    let max = prompt('Please enter end number:');
    let num = 1;
    let topOps = 0;
    let topOpNum = 0;
    let reportInterval = prompt('Please enter report interval:');
    while(num != max){
        operations = processNum(num);
        if(num % reportInterval == 0){console.log(`Number:${num} - Ops:${operations}`);}
        if(operations > topOps){
            topOps = operations;
            topOpNum = num;
        }
        num++;
        operations = 0;
    }
    console.log(`The longest chain is ${topOpNum} with ${topOps} operations`);
}else{
    operations = processNumVerbose(number);
    console.log(`It took ${operations} operations to reach 1 from ${number}.`);
}

//Processes the Collatz Sequence and returns the number of operations
function processNum(num){
    let ops = 0;
    while(num != 1){
        if(num % 2 == 0){
            num = num / 2;
        }else{
            num = (num * 3) + 1;
        }
        ops++;
    }
    return ops;
}

//Returns Each Number in the Collatz Sequence
function processNumVerbose(num){
    let ops = 0;
    while(num != 1){
        if(num % 2 == 0){
            num = num / 2;
        }else{
            num = (num * 3) + 1;
        }
        ops++;
        console.log(num);
    }
    return ops;
}