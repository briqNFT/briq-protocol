use traits::{Into, TryInto, Default, PartialEq};
use array::ArrayTrait;

// TODO : remove when included in corelib

impl PartialEqArray<T, impl TPEq: PartialEq<T>> of PartialEq<Array<T>> {
    fn eq(lhs: @Array<T>, rhs: @Array<T>) -> bool {
        if lhs.len() != rhs.len() {
            return false;
        };

        let mut is_eq = true;
        let mut i = 0;
        loop {
            if lhs.len() == i {
                break;
            };
            if lhs.at(i) != rhs.at(i) {
                is_eq = false;
                break;
            };

            i += 1;
        };

        is_eq
    }

    fn ne(lhs: @Array<T>, rhs: @Array<T>) -> bool {
        !PartialEqArray::eq(lhs, rhs)
    }
}