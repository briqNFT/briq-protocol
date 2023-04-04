# CairOpen Starknet Libs - Math

A library to manage arrays.

## Array

### `concat_arr`

Concatenates two arrays **of the same type** together. The type can be any `felt` or `struct` which does not include pointers.

Arguments

- `arr1_len (felt)`: The first array's length
- `arr1 (felt* | struct*)`: The first array
- `arr2_len (felt)`: The second array's length
- `arr2 (felt* | struct*)`: The second array
- `size (felt)`: The size of the struct

Implicit arguments

- `range_check_ptr (felt)`

Returns

- `concat_len (felt)`: The concatenated array's length, i.e. `arr1_len + arr2_len`
- `concat (felt*)`: The concatenated array (for structures see Usage example)

Import

```cairo
from cairopen.math.array import concat_arr
```

Usage example

```cairo
struct Structure:
    member m1 : felt
    member m2 : felt
end

func example{range_check_ptr}() -> (concat_len : felt, concat : Structure*):
  alloc_locals

  const arr1_len = 2
  let (local arr1 : Structure*) = alloc()
  assert arr1[0] = Structure(m1=1, m2=2)
  assert arr1[1] = Structure(m1=3, m2=4)

  const arr2_len = 2
  let (local arr2 : Structure*) = alloc()
  assert arr2[0] = Structure(m1=5, m2=6)
  assert arr2[1] = Structure(m1=7, m2=8)

  let (concat_len, felt_arr) = concat_arr(arr1_len, arr1, arr2_len, arr2, Structure.SIZE)
  let concat = cast(felt_arr, Structure*) # Important for struct usage

  return (concat_len, concat)
end

# res_len = 4
# res = [
#   Structure(m1=1, m2=2),
#   Structure(m1=3, m2=4),
#   Structure(m1=5, m2=6),
#   Structure(m1=7, m2=8),
# ]
```

---

### `concat_felt_arr`

Concatenates two **felt** arrays together (same as `concat_arr` but with the implicit size of 1).

Arguments

- `arr1_len (felt)`: The first array's length
- `arr1 (felt*)`: The first array
- `arr2_len (felt)`: The second array's length
- `arr2 (felt*)`: The second array

Implicit arguments

- `range_check_ptr (felt)`

Returns

- `concat_len (felt)`: The concatenated array's length, i.e. `arr1_len + arr2_len`
- `concat (felt*)`: The concatenated array

Import

```cairo
from cairopen.math.array import concat_felt_arr
```

Usage example

```cairo
func example{range_check_ptr}() -> (concat_len : felt, concat : felt*):
  alloc_locals

  const arr1_len = 2
  let (local arr1 : felt*) = alloc()
  assert arr1[0] = 1
  assert arr1[1] = 2

  const arr2_len = 2
  let (local arr2 : felt*) = alloc()
  assert arr2[0] = 3
  assert arr2[1] = 4

  let (concat_len, concat) = concat_arr(arr1_len, arr1, arr2_len, arr2)
  return (concat_len, concat)
end

# res_len = 4
# res = [1, 2, 3, 4]
```

---

### `invert_arr`

Inverts an array. The type can be any `felt` or `struct` which does not include pointers.

Arguments

- `arr_len (felt)` : The array's length
- `arr (felt* | struct*)` : The array
- `size (felt)` : The size of the struct

Implicit arguments

- `range_check_ptr (felt)`

Returns

- `inv_arr_len (felt)` : The inverted array's length, i.e. `arr_len`
- `inv_arr (felt*)` : The inverted array (for structures see Usage example)

Import

```cairo
from cairopen.math.array import invert_arr
```

Usage example

```cairo
struct Structure:
    member m1 : felt
    member m2 : felt
end

func example{range_check_ptr}() -> (inv_arr_len : felt, inv_arr : Structure*):
  arr_size = 3
  let (arr : Structre*) = alloc()
  assert arr[0] = Structure(m1=1, m2=2)
  assert arr[1] = Structure(m1=3, m2=4)
  assert arr[2] = Structure(m1=5, m2=6)

  let (inv_arr_len, felt_arr) = invert_arr(arr_size, arr)
  let inv_arr = cast(felt_arr, Structure*) # Important for struct usage

  return (inv_arr_len, inv_arr)
end

# res_len = 3
# res = [
#   Structure(m1=5, m2=6)
#   Structure(m1=3, m2=4),
#   Structure(m1=1, m2=2),
# ]
```

---

### `invert_felt_arr`

Inverts a **felt** array (same as `invert_arr` but with the implicit size of 1).

Arguments

- `arr_len (felt)` : The array's length
- `arr (felt*)` : The array

Implicit arguments

- `range_check_ptr (felt)`

Returns

- `inv_arr_len (felt)` : The inverted array's length, i.e. `arr_len`
- `inv_arr (felt*)` : The inverted array

Import

```cairo
from cairopen.math.array import invert_felt_arr
```

Usage example

```cairo
func example{range_check_ptr}() -> (inv_arr_len : felt, inv_arr : felt*):
  arr_size = 3
  let (arr : felt*) = alloc()
  arr[0] = 1
  arr[1] = 2
  arr[2] = 3

  let (inv_arr_len, inv_arr) = invert_arr(arr_size, arr)
  return (inv_arr_len, inv_arr)
end

# res_len = 3
# res = [3, 2, 1]
```

---

### `assert_felt_arr_unique`

Checks if an array is only composed of unique **felt** elements.

⚠️ This function reverts if the array is not unique ⚠️

Arguments

- `arr_len (felt)` : The array's length
- `arr (felt*)` : The array

Implicit arguments

- `range_check_ptr (felt)`

Error message

`assert_felt_arr_unique: array is not unique`

Import

```cairo
from cairopen.math.array import assert_felt_arr_unique
```

Usage example

```cairo
func example{range_check_ptr}():
  arr1_size = 3
  let (arr1 : felt*) = alloc()
  arr1[0] = 1
  arr1[1] = 2
  arr1[2] = 3
  assert_felt_arr_unique(arr1_size, arr1) # Success

  arr2_size = 3
  let (arr1 : felt*) = alloc()
  arr2[0] = 1
  arr2[1] = 2
  arr2[2] = 2
  assert_felt_arr_unique(arr2_size, arr2) # Reverts

  return ()
end
```
