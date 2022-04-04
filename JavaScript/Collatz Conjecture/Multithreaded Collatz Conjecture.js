const prompt = require('prompt-sync')();
const { clear } = require('console');
const { Worker, isMainThread, parentPort, workerData } = require('worker_threads');

// Processes the Collatz Sequence and returns the number of operations
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

// Returns Each Number in the Collatz Sequence
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

let operationList = [];
let numberList = [];
const threadCount = 24;// Number of threads to create

if (isMainThread) {
    // This code is executed in the main thread and not in the worker.
    let number = prompt('Please enter end number:');
    const threads = new Set();;
    const range = Math.ceil(number / threadCount);// Quantity of numbers processed per thread
    let start = 1;
    let min = start;

    // Create the worker.
    for (let i = 0; i < threadCount - 1; i++) {
        const myStart = start;
        threads.add(new Worker(__filename, { workerData: { start: myStart, range}}));
        start += range;
    }
    threads.add(new Worker(__filename, { workerData: { start, range: range + ((number - min + 1) % threadCount)}}));

    for (let worker of threads) {
        worker.on('exit', () => {
            threads.delete(worker);// Delete worker on exit
            //let percentCompletion = Math.round((100 / threadCount) * operationList.length);
            //console.log(`${percentCompletion}% complete`);
            if(operationList.length == threadCount){
                let topOperations = 0;
                let topNumber = 0;
                for(let i = 0; i < numberList.length - 1; i++){
                    if(operationList[i] > topOperations){
                        topOperations = operationList[i];
                        topNumber = numberList[i];
                    }
                }
                console.log(`The longest chain is ${topNumber} with ${topOperations} operations`);
            }
        })
        worker.on('message', (msg) => {
            operationList.push(msg[0]);
            numberList.push(msg[1]);
        });
    }
    
} else {
    // This code is executed in the worker and not in the main thread.
    let operations;
    let topOps = 0;
    let topOpNum = 0;
    let num = workerData.start;
    let max = workerData.start + workerData.range;
    while(num != max){
        operations = processNum(num);
        if(operations > topOps){
            topOps = operations;
            topOpNum = num;
        }
        num++;
        if(Math.floor(num % (workerData.range / 100)) == 0){
            console.log(((num - workerData.start) / workerData.range) * 100 + '% complete');
        }
    }

    // Send a message to the main thread.
    parentPort.postMessage([topOps,topOpNum]);
}