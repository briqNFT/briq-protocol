# CairOpen Contracts - String

A library to store & manipulate strings in Cairo on StarkNet.

## Type `String`

The type `String` is a struct used to simplify the use of strings in Cairo. Further mentions of the type `String` will infer a value of this type.

Members

- `len (felt)`: The length of the string
- `data (felt*)`: The string as a char array

Import

```cairo
from cairopen.string.string import String
```

Usage example

```cairo
from starkware.cairo.common.alloc import alloc

from cairopen.string.string import String

func example{range_check_ptr}() -> (str : String):
  let str_len = 5
  let (str_data) = alloc()
  assert str_data[0] = 'H'
  assert str_data[1] = 'e'
  assert str_data[2] = 'l'
  assert str_data[3] = 'l'
  assert str_data[4] = 'o'

  return (String(str_len, str_data))
end

# str = "Hello"
#
# In reality:
#   str.len = 5
#   str.data = ['H', 'e', 'l', 'l', 'o']
```

---

## Codecs & Namespace `StringCodec`

To manage different string encodings, codec-dependent functions are defined under the namespace `StringCodec`.

The codec can be selected when imported using `from cairopen.string.<codec> import StringCodec`, e.g. for ASCII: `from cairopen.string.ASCII import StringCodec`.

By default, Cairo uses ASCII for short strings.

If several codecs are required in the same contract, you can rename the import to avoid name collisions, e.g. `from cairopen.string.ASCII import StringCodec as ASCII`.

Available codecs are:

- ASCII (`cairopen.string.ASCII`)

---

## Storage

### `StringCodec.read`

Reads a string from storage based on its ID.

Arguments

- `str_id (felt)`: The ID of the string to read

Implicit arguments

- `syscal_ptr (felt*)`
- `bitwise_ptr (BitwiseBuiltin*)`
- `pedersen_ptr (HashBuiltin*)`
- `range_check_ptr (felt)`

Returns

- `str (String)`: The string

Import

```cairo
from cairopen.string.<codec> import StringCodec
# then StringCodec.read
```

Usage example

```cairo
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin

from cairopen.string.string import String
from cairopen.string.ASCII import StringCodec

func example{
  syscall_ptr : felt*,
  bitwise_ptr : BitwiseBuiltin*,
  pedersen_ptr : HashBuiltin*,
  range_check_ptr,
}() -> (str : String):
  let (str) = StringCodec.read('my_string')
  return (str)
end
```

---

### `StringCodec.write`

Writes a string in storage, using an ID to identify it.

Arguments

- `str_id (felt)`: The ID of the string to write
- `str (String)`: The string

Implicit arguments

- `syscal_ptr (felt*)`
- `pedersen_ptr (HashBuiltin*)`
- `range_check_ptr (felt)`

Import

```cairo
from cairopen.string.<codec> import StringCodec
# then String.write
```

Usage example

```cairo
from starkware.cairo.common.cairo_builtins import HashBuiltin

from cairopen.string.string import String
from cairopen.string.ASCII import StringCodec

func example{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
  let str_len = 5
  let (str_data) = alloc()
  assert str_data[0] = 'H'
  assert str_data[1] = 'e'
  assert str_data[2] = 'l'
  assert str_data[3] = 'l'
  assert str_data[4] = 'o'

  let str = String(str_len, str_data)
  StringCodec.write('my_string', str)

  return ()
end
```

---

### `StringCodec.write_from_char_arr`

Writes a string from a char array in storage, using an ID to identify it.

Arguments

- `str_id (felt)`: The ID of the string to write
- `str_len (felt)`: The length of the string
- `str_data (felt*)`: The string

Implicit arguments

- `syscal_ptr (felt*)`
- `pedersen_ptr (HashBuiltin*)`
- `range_check_ptr (felt)`

Import

```cairo
from cairopen.string.<codec> import StringCodec
# then StringCodec.write_from_char_arr
```

Usage example

```cairo
from starkware.cairo.common.cairo_builtins import HashBuiltin

from cairopen.string.ASCII import StringCodec

func example{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
  let str_len = 5
  let (str_data) = alloc()
  assert str_data[0] = 'H'
  assert str_data[1] = 'e'
  assert str_data[2] = 'l'
  assert str_data[3] = 'l'
  assert str_data[4] = 'o'

  StringCodec.write_from_char_arr('my_string', str_len, str_data)

  return ()
end
```

---

### `StringCodec.delete`

Deletes a string from storage, using an ID to identify it.

Arguments

- `str_id (felt)`: The ID of the string to delete

Implicit arguments

- `syscal_ptr (felt*)`
- `pedersen_ptr (HashBuiltin*)`
- `range_check_ptr (felt)`

Import

```cairo
from cairopen.string.<codec> import StringCodec
# then StringCodec.delete
```

Usage example

```cairo
from starkware.cairo.common.cairo_builtins import HashBuiltin

from cairopen.string.ASCII import StringCodec

func example{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
  StringCodec.delete('my_string')

  return ()
end
```

---

## Conversion

### `StringCodec.felt_to_string`

Converts a felt to a String.

e.g. 12345 &rarr; String("12345")

Arguments

- `elem (felt)`: The felt value to convert

Implicit arguments

- `range_check_ptr (felt)`

Returns

- `str (String)`: The string

Import

```cairo
from cairopen.string.<codec> import StringCodec
# then StringCodec.felt_to_string
```

Usage example

```cairo
from cairopen.string.string import String
from cairopen.string.ASCII import StringCodec

func example{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (str : String):
  let _felt = 12345

  let (str) = StringCodec.felt_to_str(_felt)

  return (str)
end

# str = "12345"
#
# In reality:
#   str.len = 5
#   str.data = ['1', '2', '3', '4', '5']
```

---

### `StringCodec.ss_to_string`

Converts a short string to a string.

e.g. 'Hello' &rarr; String("Hello")

Arguments

- `ss (felt)`: The short string to convert

Implicit arguments

- `bitwise_ptr (BitwiseBuiltin*)`
- `range_check_ptr (felt)`

Returns

- `str (String)`: The string

Import

```cairo
from cairopen.string.<codec> import StringCodec
# then StringCodec.ss_to_string
```

Usage example

```cairo
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin

from cairopen.string.string import String
from cairopen.string.ASCII import StringCodec

func example{syscall_ptr : felt*, bitwise_ptr : BitwiseBuiltin*, range_check_ptr}() -> (str : String):
  let ss = 'Hello'

  let (str) = StringCodec.ss_to_string(ss)

  return (str)
end

# str = "Hello"
#
# In reality:
#   str.len = 5
#   str.data = ['H', 'e', 'l', 'l', 'o']
```

---

### `StringCodec.ss_arr_to_string`

Converts an array of short strings to a string.

e.g. ['Hello', 'World'] &rarr; String("HelloWorld")

Arguments

- `ss_arr_len (felt)`: The length of the short string array
- `ss_arr (felt*)`: The short string array

Implicit arguments

- `bitwise_ptr (BitwiseBuiltin*)`
- `range_check_ptr (felt)`

Returns

- `str (String)`: The string

Import

```cairo
from cairopen.string.<codec> import StringCodec
# then StringCodec.ss_arr_to_string
```

Usage example

```cairo
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.alloc import alloc

from cairopen.string.string import String
from cairopen.string.ASCII import StringCodec

func example{syscall_ptr : felt*, bitwise_ptr : BitwiseBuiltin*, range_check_ptr}() -> (str : String):
  let ss_arr_len = 2
  let (ss_arr) = alloc()
  assert ss_arr[0] = 'Hello'
  assert ss_arr[1] = 'World'

  let (str) = StringCodec.ss_arr_to_string(ss_arr_len, ss_arr)

  return (str)
end

# str = "HelloWorld"
#
# In reality:
#   str.len = 10
#   str.data = ['H', 'e', 'l', 'l', 'o', 'W', 'o', 'r', 'l', 'd']
```

---

### `StringCodec.extract_last_char_from_ss`

Extracts the last character from a short string and returns the remaining characters as a short string.

Manages felt up to [SHORT_STRING_MAX_VALUE](#short_string_max_value) (instead of `unsigned_div_rem` which is limited by `rc_bound = 2 ** 148`). _On the down side it requires BitwiseBuiltin for the whole call chain_

Arguments

- `ss (felt)`: The short string

Implicit arguments

- `bitwise_ptr (BitwiseBuiltin*)`
- `range_check_ptr (felt)`

Returns

- `ss_rem (felt)`: The remaining short string
- `char (felt)`: The character

Import

```cairo
from cairopen.string.<codec> import StringCodec
# then StringCodec.extract_last_char_from_ss
```

Usage example

```cairo
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin

from cairopen.string.ASCII import StringCodec

func example{syscall_ptr : felt*, bitwise_ptr : BitwiseBuiltin*, range_check_ptr}() -> (ss_rem : felt, char : felt):
  let (ss) = 'Hello!'

  let (ss_rem, char) = StringCodec.extract_last_char_from_ss(ss)

  return (ss_rem, char)
end

# ss_rem = 'Hello'
# char = '!'
```

---

### `StringCodec.assert_char_encoding`

Checks whether a character is correct (char < [StringCodec.CHAR_SIZE](#stringcodecchar_size)).

⚠️ This function reverts if the character is not correct ⚠️

Arguments

- `char (felt)`: The character to check

Implicit arguments

- `range_check_ptr (felt)`

Error message

`assert_char_encoding: char is not a single character`

Import

```cairo
from cairopen.string.<codec> import StringCodec
# then StringCodec.assert_char_encoding
```

Usage example

```cairo
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin

from cairopen.string.ASCII import StringCodec

func example{range_check_ptr}():
  StringCodec.assert_char_encoding('a') # Success

  StringCodec.assert_char_encoding('aa') # Error

  return ()
end
```

---

## Codec constants

### `StringCodec.CHAR_SIZE`

The size of a character in the specified encoding.

```cairo
from cairopen.string.<codec> import StringCodec
# then StringCodec.CHAR_SIZE
```

### `StringCodec.LAST_CHAR_MASK`

Bitmask to retrieve the last character from a short string.

```cairo
from cairopen.string.<codec> import StringCodec
# then StringCodec.LAST_CHAR_MASK
```

### `StringCodec.NUMERICAL_OFFSET`

The offset to transform a number into its encoded character. (e.g. in ASCII `0 + 48 = 48 = 0x30` &rarr; `0x30 -> '0'` or `8 + 48 = 56 = 0x38` &rarr; `0x38 -> '8'`)

```cairo
from cairopen.string.<codec> import StringCodec
# then StringCodec.NUMERICAL_OFFSET
```

## Namespace `StringUtil`

All codec-agnostic string utility functions are accessible under the `StringUtil` namespace.

Import

```cairo
from cairopen.string.utils import StringUtil
```

---

## Manipulation

### `StringUtil.concat`

Concatenates two strings together.

e.g. String("Hello") + String("World") &rarr; String("HelloWorld")

Arguments

- `str1 (String)`: The first string
- `str2 (String)`: The second string

Implicit arguments

- `range_check_ptr (felt)`

Returns

- `str (String)`: The concatenated string

Import

```cairo
from cairopen.string.utils import StringUtil
# then StringUtil.concat
```

Usage example

```cairo
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin

from cairopen.string.string import String
from cairopen.string.ASCII import StringCodec
from cairopen.string.utils import StringUtil

func example{syscall_ptr : felt*, bitwise_ptr : BitwiseBuiltin*, range_check_ptr}() -> (str : String):
  let (str1) = StringCodec.ss_to_string('Hello')
  let (str2) = StringCodec.ss_to_string('World')

  let (str) = StringUtil.concat(str1, str2)

  return (str)
end

# str = "HelloWorld"
#
# In reality:
#   str.len = 10
#   str.data = ['H', 'e', 'l', 'l', 'o', 'W', 'o', 'r', 'l', 'd']
```

---

### `StringUtil.append_char`

Appends a character (represented as a single character short string) to a string.

_It is advised to check whether the character is valid with `StringCodec.assert_char_encoding` before calling this function_

e.g. String("Hello") + '!' &rarr; String("Hello!")

Arguments

- `base (String)`: The base string
- `char (felt)`: The character to append

Implicit arguments

- `range_check_ptr (felt)`

Returns

- `str (String)`: The appended string

Import

```cairo
from cairopen.string.utils import StringUtil
# then String.append_char
```

Usage example

```cairo
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin

from cairopen.string.string import String
from cairopen.string.ASCII import StringCodec
from cairopen.string.utils import StringUtil

func example{syscall_ptr : felt*, bitwise_ptr : BitwiseBuiltin*, range_check_ptr}() -> (str : String):
  let (base) = StringCodec.ss_to_string('Hello')
  let char = '!'

  StringCodec.assert_char_encoding(char)

  let (str) = StringUtil.append_char(base, char)

  return (str)
end

# str = "Hello!"
#
# In reality:
#   str.len = 6
#   str.data = ['H', 'e', 'l', 'l', 'o', '!']
```

---

### `StringUtil.path_join`

Joins two paths together, adding a '/' in between if not already present at the end of the first path.

_For now this function is only optimised for ASCII strings, it may be moved to `StringCodec` in the future_

e.g. String("Hello") + String("World") &rarr; String("Hello/World")

e.g. String("Hello/") + String("World") &rarr; String("Hello/World")

Arguments

- `path1 (String)`: The first path
- `path2 (String)`: The second path

Implicit arguments

- `range_check_ptr (felt)`

Returns

- `path (String)`: The full path

Import

```cairo
from cairopen.string.utils import StringUtil
# then StringUtil.path_join
```

Usage example

```cairo
from cairopen.string.string import String
from cairopen.string.ASCII import StringCodec
from cairopen.string.utils import StringUtil

func example{syscall_ptr : felt*, bitwise_ptr : BitwiseBuiltin*, range_check_ptr}() -> (path : String):
  let (path1) = StringCodec.ss_to_string('https://cairopen.org')
  let (path2) = StringCodec.ss_to_string('docs')

  let (path) = StringUtil.path_join(path1, path2)

  return (path)
end

# path = "https://cairopen.org/docs"
#
# In reality:
#   path.len = 23
#   path.data = ['h', 't', 't', 'p', 's', ':', '/', '/', 'c', 'a', 'i', 'r', 'o', 'p', 'e', 'n', '.', 'o', 'r', 'g', '/', 'd', 'o', 'c', 's']
```

---

## Common constants

### SHORT_STRING_MAX_LEN

The maximum length of a short string, i.e. 31 characters.

```cairo
const SHORT_STRING_MAX_LEN = 31
```

### SHORT_STRING_MAX_VALUE

The maximum numerical value allowed for a short string, each character being enconded on an 8-bit value, i.e. `0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF` or `(2 ** 8) ** 31 - 1 = 2 ** 248 - 1`.

```cairo
const SHORT_STRING_MAX_VALUE = 2 ** 248 - 1
```

### STRING_MAX_LEN

The maximum length of a string, based on the maximum index for `felt*` in one direction, i.e. str[i] for i in [-2 ** 15, 2 ** 15) or 32,768 characters.

```cairo
const STRING_MAX_LEN = 2 ** 15
```
