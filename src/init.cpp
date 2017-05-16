#include <R_ext/Rdynload.h>
#include "matter.h"

extern "C" {

    static const R_CallMethodDef callMethods[] = {
        {"C_createAtoms", (DL_FUNC) &createAtoms, 5},
        {"C_getArray", (DL_FUNC) &getArray, 1},
        {"C_setArray", (DL_FUNC) &setArray, 2},
        {"C_getArrayElements", (DL_FUNC) &getArrayElements, 2},
        {"C_setArrayElements", (DL_FUNC) &setArrayElements, 3},
        {"C_getList", (DL_FUNC) &getList, 1},
        {"C_setList", (DL_FUNC) &setList, 2},
        {"C_getListElements", (DL_FUNC) &getListElements, 3},
        {"C_setListElements", (DL_FUNC) &setListElements, 4},
        {"C_getMatrix", (DL_FUNC) &getMatrix, 1},
        {"C_setMatrix", (DL_FUNC) &setMatrix, 2},
        {"C_getMatrixRows", (DL_FUNC) &getMatrixRows, 2},
        {"C_setMatrixRows", (DL_FUNC) &setMatrixRows, 3},
        {"C_getMatrixCols", (DL_FUNC) &getMatrixCols, 2},
        {"C_setMatrixCols", (DL_FUNC) &setMatrixCols, 3},
        {"C_getMatrixElements", (DL_FUNC) &getMatrixElements, 3},
        {"C_setMatrixElements", (DL_FUNC) &setMatrixElements, 4},
        {"C_getSum", (DL_FUNC) &getSum, 2},
        {"C_getMean", (DL_FUNC) &getMean, 2},
        {"C_getVar", (DL_FUNC) &getVar, 2},
        {"C_getColSums", (DL_FUNC) &getColSums, 2},
        {"C_getColMeans", (DL_FUNC) &getColMeans, 2},
        {"C_getColVars", (DL_FUNC) &getColVars, 2},
        {"C_getRowSums", (DL_FUNC) &getRowSums, 2},
        {"C_getRowMeans", (DL_FUNC) &getRowMeans, 2},
        {"C_getRowVars", (DL_FUNC) &getRowVars, 2},
        {"C_rightMatrixMult", (DL_FUNC) &rightMatrixMult, 2},
        {"C_leftMatrixMult", (DL_FUNC) &leftMatrixMult, 2},
        {"C_getWhich", (DL_FUNC) &getWhich, 1},
        {"C_countRuns", (DL_FUNC) &countRuns, 1},
        {"C_createDRLE", (DL_FUNC) &createDRLE, 2},
        {"C_getDRLE", (DL_FUNC) &getDRLE, 1},
        {"C_getDRLEElements", (DL_FUNC) &getDRLEElements, 2},
        {NULL, NULL, 0}
    };

    void R_init_matter(DllInfo * info)
    {
        R_registerRoutines(info, NULL, callMethods, NULL, NULL);
    }

}
