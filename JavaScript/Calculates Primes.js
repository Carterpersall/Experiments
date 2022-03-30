//Calculate every prime number to 100000
 let primeArray = [];
 let prime = 2;

 while(prime < 1000000){
     let isPrime = true;
        for(let i = 2; i < prime; i++){
            if(prime % i === 0){
                isPrime = false;
            }
        }
        if(isPrime){
            primeArray.push(prime);
            console.log(prime);
        }
        prime++;
    }
    console.log(primeArray);
    console.log('Length:'+primeArray.length);

    //Validate the prime numbers using the length of the array
    let knownPrimeCount = 78498;
    if(knownPrimeCount == primeArray.length){
        console.log('The prime numbers are correct');
    }else{
        console.log('The prime numbers are incorrect');
    }
    
    //Calculate the sum of all prime numbers
    let sum = 0;
    for(let i = 0; i < primeArray.length; i++){
        sum += primeArray[i];
    }
    console.log('Sum: '+sum);

    //Calculate the average of all prime numbers
    let average = sum / primeArray.length;
    console.log('Average: '+average);