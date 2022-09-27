# Bits manipulation

This allows to represent long lists of bits and to perform common operations on them. This list will be represented by a list of words (felts) each containing up to 32 bits, and a felt containing the total number of bits.

## Bits

Import

```cairo
from cairopen.binary.bits import Bits
```

### ``Bits.extract``
Write len bits from input to output, starting at start.

Arguments

- `input (felt*)`: The input bits as 32-bit integers
- `start (felt)`: The starting bit index (included)
- `len (felt)`: The amount of bits to write
- `output (felt*)`: Where to write the output

Implicit arguments

- `range_check_ptr (felt)`

Usage example

```cairo
@view
func test_extract{range_check_ptr}():
    alloc_locals
    let (input) = alloc()
    # 01001000011001010110110001101100
    assert input[0] = 1214606444
    # 01101111001000000111011101101111
    assert input[1] = 1864398703
    # 01110010011011000110010000000000
    assert input[2] = 1919706112

    # two words, no shift, len = two words
    let (output) = alloc()
    Bits.extract(input, 0, 64, output)
    # 01001000011001010110110001101100
    assert output[0] = 1214606444
    # 01101111001000000111011101101111
    assert output[1] = 1864398703

    return ()
end
```

---

### ``Bits.merge``
Allows to merge two lists of bits into one.

Arguments

- `a (felt*)`: The first bits list
- `a_nb_bits (felt)`: The bit length of a
- `b (felt*)`: The first bits list
- `b_nb_bits (felt)`: The bit length of b

Implicit arguments

- `range_check_ptr (felt)`

Returns

- `merged (felt*)`: The merge bit list a::b
- `merged_nb_bits (felt)`: The bit length of merged

Usage example

```cairo
@view
func test_merge{range_check_ptr}():
    alloc_locals
    let (a) = alloc()
    # 01101111001000000111011101101111
    assert a[0] = 1864398703
    # 01110010011011000110010000000000
    assert a[1] = 1919706112
    # 32+22=54
    let a_nb_bits = 54

    let (b) = alloc()
    # 01101111001000000111011101101110
    assert b[0] = 1864398702
    # 31 (last 0 doesn't count)
    let b_nb_bits = 31

    let (c, c_bits) = Bits.merge(a, a_nb_bits, b, b_nb_bits)

    assert c[0] = 1864398703
    assert c[1] = 1919706556
    assert c[2] = 2178791424

    return ()
end
```

---

### ``Bits.rightshift``
Allows you to apply a binary rightshift to a word.

---

### ``Bits.leftshift``
Allows you to apply a binary leftship to a word.

---

### ``Bits.rightrotate``
Allows you to shift the bits to the right and return by the left to a word.

---

### ``Bits.negate``
Returns the binary negation of a word.
