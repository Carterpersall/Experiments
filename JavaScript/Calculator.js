const prompt = require('prompt-sync')();

//Functions

function parseInput(a, b){
    let array1 = a.split('');
    let array2 = b.split('');

    let aLength = array1.length;
    let bLength = array2.length;
    
    if(b.length < a.length){
        for (i = array1.length - array2.length; i > 0; i--){
            array2.unshift('0');
        }
    }else{
        for (i = array2.length - array1.length; i > 0; i--){
            array1.unshift('0');
        }
    }
    return [array1, array2, aLength, bLength];
}

function add(a, b){
    parsed = parseInput(a, b);
    let array1 = parsed[0];
    let array2 = parsed[1];

    let sum = new Array(array1.length).fill(0);
    let carry = 0;

    for(i = array1.length - 1; i >= 0; i--){
        product = parseInt(array1[i]) + parseInt(array2[i]) + carry;
        if(product > 9){
            carry = 1;
            product = product - 10;
        }else{
            carry = 0;
        }
        sum[i] = product;
    }
    if(carry == 1){
        sum.unshift(1);
    }

    return sum.join('');
}

function subtract(a, b){
    parsed = parseInput(a, b);
    
    let array1 = parsed[0];
    let array2 = parsed[1];
    let Length1 = parsed[2];
    let Length2 = parsed[3];
    
    let difference = new Array(array1.length).fill(0);
    let carry = 0;
    
    let operationLookup = ['0', '9', '8', '7', '6', '5', '4', '3', '2', '1'];

    let isNegative = false
    if (Length1 > Length2) {
        isNegative = false;
    } else {
        isNegative = true;
        let temp = array1;
        array1 = array2;
        array2 = temp;
    }

    for (i = array1.length - 1; i >= 0; i--){
        product = parseInt(array1[i]) - parseInt(array2[i]) - carry;

        if(product < 0) {
            product = operationLookup[-product];
            carry = 1;
        }else{
            carry = 0;
        }
        difference[i] = product;
    }
    if(isNegative){
        difference.unshift('-');
        carry = 0;
    }

    return difference.join('');
}


//Main

console.log(subtract("56456465432154432135446541", "65465153214564132145643215645"));