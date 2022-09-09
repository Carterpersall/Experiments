const prompt = require('prompt-sync')();

//Functions

//Takes in two input strings and returns a properly formatted array of the two numbers and the input's lengths
function parseInput(a, b) {
    //Split the strings into arrays
    let array1 = a.split('');
    let array2 = b.split('');

    //Get the lengths of the inputs
    let aLength = array1.length;
    let bLength = array2.length;

    //Pad the shorter array with zeros
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

function add(a, b) {
    //Detect if either input is negative
    let aNegative = 1;
    let bNegative = 1;
    if (a.charAt(0) == '-') {
        aNegative = -1;
        a = a.substring(1);
    }
    if (b.charAt(0) == '-') {
        bNegative = -1;
        b = b.substring(1);
    }

    //Parse the input and set values to the output values
    parsed = parseInput(a, b);
    let array1 = parsed[0];
    let array2 = parsed[1];
    let Length1 = parsed[2];
    let Length2 = parsed[3];

    //Run certain negative-specific cases
    let isNegative = false;
    if (bNegative == -1 && aNegative == 1) {
        return subtract(a, b);
    }
    if (aNegative == -1 && bNegative == -1) {
        isNegative = true;
    }
    if (aNegative == -1 && bNegative == 1) {
        return subtract(b, a);
    }

    let sum = new Array(array1.length).fill(0);
    let carry = 0;

    for(i = array1.length - 1; i >= 0; i--){
        product = parseInt(array1[i]) + parseInt(array2[i]) + carry;
        if (product > 9) {
            carry = 1;
            product = product - 10;
        } else {
            carry = 0;
        }
        sum[i] = product;
    }
    if(carry == 1){
        sum.unshift(1);
    }
    if (isNegative) {
        sum.unshift('-');
    }

    return sum.join('');
}

function subtract(a, b) {
    let aNegative = 1;
    let bNegative = 1;
    if (a.charAt(0) == '-') {
        aNegative = -1;
        a = a.substring(1);
    }
    if (b.charAt(0) == '-') {
        bNegative = -1;
        b = b.substring(1);
    }
    
    parsed = parseInput(a, b);
    
    let array1 = parsed[0];
    let array2 = parsed[1];
    let Length1 = parsed[2];
    let Length2 = parsed[3];
    
    let difference = new Array(array1.length).fill(0);
    let carry = 0;
    
    const operationLookup = ['0', '9', '8', '7', '6', '5', '4', '3', '2', '1'];

    let isNegative = false
    if (Length1 > Length2) {
        isNegative = false;
    } else {
        isNegative = true;
        let temp = array1;
        array1 = array2;
        array2 = temp;
        
        temp = aNegative;
        aNegative = bNegative;
        bNegative = temp;
    }

    for (i = array1.length - 1; i >= 0; i--){
        product = (aNegative * parseInt(array1[i])) - (bNegative * parseInt(array2[i])) - carry;

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

console.log(subtract("1234567890", "1111111111"));