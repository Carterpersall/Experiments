Add-Type -AssemblyName "$env:USERPROFILE\Downloads\ExtendedNumerics.BigRational.2022.195.942\net6.0-windows7.0\ExtendedNumerics.BigRational.dll"

Function Factorial($Num){
  $Output = [ExtendedNumerics.BigRational]::One
  for (<#$i = 1; $i -lt 10; $i++#>$i = [ExtendedNumerics.BigRational]::One; ![ExtendedNumerics.BigRational]::Equals($i, [ExtendedNumerics.BigRational]::Add($Num, 1));$i = [ExtendedNumerics.BigRational]::Add([ExtendedNumerics.BigRational]::One, $i)) {
    $Output = [ExtendedNumerics.BigRational]::Multiply($Output, $i)
  }
  $Output
}

(3..100) | ForEach-Object {
  [ExtendedNumerics.BigRational]::Divide(
    ([ExtendedNumerics.BigRational]::Multiply(
      ([ExtendedNumerics.BigRational]::Multiply(
        [ExtendedNumerics.BigRational]::new([System.Math]::Pow(-1, $_)),
        (Factorial ([ExtendedNumerics.BigRational]::Multiply(
          [ExtendedNumerics.BigRational]::new(6),
          [ExtendedNumerics.BigRational]::new($_)
        )))
      )),
      ([ExtendedNumerics.BigRational]::Add(
        ([ExtendedNumerics.BigRational]::Multiply(
          ([ExtendedNumerics.BigRational]::new(545140134)),
          ([ExtendedNumerics.BigRational]::new($_))
        )),
        ([ExtendedNumerics.BigRational]::new(13591409))
      ))
    )),
    [ExtendedNumerics.BigRational]::Multiply(
      [ExtendedNumerics.BigRational]::Multiply(
        (Factorial ([ExtendedNumerics.BigRational]::Multiply(
          [ExtendedNumerics.BigRational]::new(3),
          [ExtendedNumerics.BigRational]::new($_)
        ))),
        ([ExtendedNumerics.BigRational]::Pow((Factorial ($_)), 3))
      ),
      ([ExtendedNumerics.BigRational]::Pow(
        ([ExtendedNumerics.BigRational]::new(640320)),
        [ExtendedNumerics.BigRational]::Add(
          ([ExtendedNumerics.BigRational]::Multiply(
            [ExtendedNumerics.BigRational]::new(3),
            [ExtendedNumerics.BigRational]::new($_)
          )),
          ([ExtendedNumerics.BigRational]::new(1.5))
        )
      ))
    )
  )
}