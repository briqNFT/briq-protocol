# Sha256 computation

This lib depends on bits.cairo from ``cairopen/binary/``. 

## sha256

### ``sha256``

This allows to calculate the sha256 hash of an input of any bit length.

Arguments

- `input (felt*)`: bits array of 32-bit words
- `n_bits (felt)`: The bit length of input

Implicit arguments

- `bitwise_ptr (BitwiseBuiltin*)`
- `range_check_ptr (felt)`

Returns

- `output (felt*)`: Hashed input as an array of 8 32-bit words (big endian)

Import

```cairo
from cairopen.math.array import concat_arr
```

Usage example

``sha256("hey guys")`` = ``"be83351937c9a13e0d0e16ae97ee46915e790cf9a5d55fa317014539009f2101"``
Which if broken down into 32-bit words, gives :
- 3196269849
- 935960894
- 219027118
- 2548975249
- 1584991481
- 2782224291
- 385959225
- 10428673

```cairo
@view
func test_sha256{bitwise_ptr : BitwiseBuiltin*, range_check_ptr}():

    # let's hash "hey guys"
    let (hash) = sha256(new ('hey ', 'guys'), 64)
    let a = hash[0]
    assert a = 3196269849
    let b = hash[1]
    assert b = 935960894
    let c = hash[2]
    assert c = 219027118
    let d = hash[3]
    assert d = 2548975249
    let e = hash[4]
    assert e = 1584991481
    let f = hash[5]
    assert f = 2782224291
    let g = hash[6]
    assert g = 385959225
    let h = hash[7]
    assert h = 10428673

    return ()
end
```
