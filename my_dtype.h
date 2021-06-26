//
// Created by fahim_hakim_15 on 26/04/2021.
//

#ifndef MINE_MY_DTYPE_H

typedef enum dt_and_other_consts {
    _INT = 0,
    _FLOAT = 1,
    _BOOLEAN = 2,
    _STRING = 3,
    _VOID = 4,
    _UNKNOWN = 5005,
    _ERRONEOUS = 5001,
    _ARR_OFFSET = 100,
    _FUNC_OFFSET = 1000,
    _SIZE_MISMATCH = 5020,
    _TYPE_MISMATCH = 5201,
    _MATCH = 4555,
    _TBdef = 6000

} my_dtype;

typedef enum flag_pos {
    CF = 0,
    PF = 2,
    ZF = 6,
    SF = 7,
    OF = 11
} fpos;

#define MINE_MY_DTYPE_H

#endif //MINE_MY_DTYPE_H
