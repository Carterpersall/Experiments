const prompt = require('prompt-sync')();

let number = prompt('Please enter a number(auto for auto mode):');
let operations = 0;

if(number == 'auto') {
    let max = prompt('Please enter end number:');
    let num = 1;
    let topOps = 0;
    let topOpNum = 0;
    let reportInterval = prompt('Please enter report interval:');
    while(num <= max){
        number = num;
        while(number != '1'){
            if(number % 2 == 0){
                number = number / 2;
            }else{
                number = (number * 3) + 1;
            }
            operations++;
        }
        if(operations > topOps){
            topOps = operations;
            topOpNum = num;
        }
        if(num % reportInterval == 0){console.log(`Number:${num} - Ops:${operations}`);}
        num++;
        operations = 0;
    }
    console.log(`The longest chain is ${topOpNum} with ${topOps} operations`);
}else{
    let num = number;
    while(number != '1'){
        if(number % 2 == 0){
            number = number / 2;
        }else{
            number = (number * 3) + 1;
        }
        operations++;
        console.log(number);
    }
    console.log(`It took ${operations} operations to reach 1 from ${num}.`);
}