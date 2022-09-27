%lang starknet

// @dev The maximum character length of a short string
const SHORT_STRING_MAX_LEN = 31;

// @dev The maximum value for a short string of 31 characters (= 0b11...11 = 0xff...ff)
const SHORT_STRING_MAX_VALUE = 2 ** 248 - 1;

// @dev The maximum index for felt* in one direction given str[i] for i in [-2**15, 2**15)
const STRING_MAX_LEN = 2 ** 15;
