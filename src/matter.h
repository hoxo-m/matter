
#ifndef MATTER_H
#define MATTER_H

#include <R.h>
#include <Rdefines.h>

#include <cstdio>
#include <cstdlib>

#include "utils.h"

#define within_bounds(x, a, b) ((a) <= (x) && (x) < (b))

#define out_of_bounds(x, a, b) ((x) < (a) && (b) <= (x))

typedef long index_type;

typedef double dbl_index_type;

//// Low-level read/write functions
//----------------------------------

template<typename T1, typename T2>
T2 coerce_cast(T1 x);

template<typename CType, typename RType>
size_t convert_read(RType * ptr, size_t count, FILE * stream, size_t skip = 1) {
    size_t numRead;
    CType * tmp = (CType *) Calloc(count, CType);
    numRead = fread(tmp, sizeof(CType), count, stream);
    for ( size_t i = 0; i < numRead; i++ ) {
        *ptr = coerce_cast<CType,RType>(tmp[i]);
        ptr += skip;
    }
    Free(tmp);
    return numRead;
}

template<typename CType, typename RType>
size_t convert_write(RType * ptr, size_t count, FILE * stream, size_t skip = 1) {
    size_t numWrote;
    CType * tmp = (CType *) Calloc(count, CType);
    for ( size_t i = 0; i < count; i++ ) {
        tmp[i] = coerce_cast<RType,CType>(*ptr);
        ptr += skip;
    }
    numWrote = fwrite(tmp, sizeof(CType), count, stream);
    Free(tmp);
    return numWrote;
}

template<typename RType>
void fillNA(RType * ptr, size_t count, size_t skip = 1) {
    for ( size_t i = 0; i < count; i ++ ) {
        *ptr = DataNA<RType>();
        ptr += skip;
    }
}

//// Count # of consecutive indices after current one (for faster reads)
//----------------------------------------------------------------------

index_type num_consecutive(double * pindex, long i, long length);

//// Files class
//----------------

class Files {

    public:

        Files(SEXP x)
        {
            _paths = GET_SLOT(x, mkString("filepaths"));
            _mode = GET_SLOT(x, mkString("filemode"));
            if ( LENGTH(_paths) == 0 )
                error("empty 'filepaths'");
            _length = LENGTH(_paths);
            _streams = (FILE **) Calloc(_length, FILE*);
            for ( int i = 0; i < _length; i++ )
                _streams[i] = NULL;
        }

        ~Files()
        {
            for ( int i = 0; i < _length; i++ )
                if ( _streams[i] != NULL )
                    fclose(_streams[i]);
            Free(_streams);
        }

        FILE * require(int file_id) {
            if ( file_id == NA_INTEGER )
                error("missing 'file_id'");
            if ( _streams[file_id] == NULL ) {
                const char * filename = CHARACTER_VALUE(STRING_ELT(_paths, file_id));
                _streams[file_id] = fopen(filename, CHARACTER_VALUE(_mode));
                if ( _streams[file_id] == NULL )
                  error("could not open file '%s'", filename);
            }
            return _streams[file_id];
        }

    protected:

        SEXP _paths;
        SEXP _mode;
        FILE ** _streams;
        int _length;

};


//// Atoms class
//-----------------------

class Atoms {

    public:

        Atoms(SEXP x, )
        {
            _length = INTEGER_VALUE(GET_SLOT(x, mkString("length")));
            _file_id = INTEGER(GET_SLOT(x, mkString("file_id")));
            _datamode = INTEGER(GET_SLOT(x, mkString("datamode")));
            _offset = REAL(GET_SLOT(x, mkString("offset")));
            _extent = REAL(GET_SLOT(x, mkString("extent")));
            _index_offset = REAL(GET_SLOT(x, mkString("index_offset")));
            _index_extent = REAL(GET_SLOT(x, mkString("index_extent")));
        }

        ~Atoms(){}

        int file_id(int i) {
            int retId = _file_id[i] - 1;
            if ( retId == NA_INTEGER )
                error("missing 'file_id'");
            return retId;
        }

        int datamode(int i) {
            return _datamode[i];
        }

        index_type offset(int i) {
            return static_cast<index_type>(_offset[i]);
        }

        index_type extent(int i) {
            return static_cast<index_type>(_extent[i]);
        }

        index_type index_offset(int i) {
            return static_cast<index_type>(_index_offset[i]);
        }

        index_type index_extent(int i) {
            return static_cast<index_type>(_index_extent[i]);
        }

        int length() {
            return _length;
        }

        index_type max_extent() {
            return(index_extent(length() - 1));
        }

        index_type file_offset(int i, index_type offset) {
            index_type byte_offset, file_offset;
            switch(datamode(i)) {
                case 1:
                    byte_offset = sizeof(short) * (offset - index_offset(i));
                    break;
                case 2:
                    byte_offset = sizeof(int) * (offset - index_offset(i));
                    break;
                case 3:
                    byte_offset = sizeof(long) * (offset - index_offset(i));
                    break;
                case 4:
                    byte_offset = sizeof(float) * (offset - index_offset(i));
                    break;
                case 5:
                    byte_offset = sizeof(double) * (offset - index_offset(i));
                    break;
                default:
                    error("unsupported datamode");
            }
            file_offset = this->offset(i) + byte_offset;
            return file_offset;
        }

        int find_atom(index_type offset) {
            for ( int retIdx = 0; retIdx < length(); retIdx++ )
                if ( within_bounds(offset, index_offset(retIdx), index_extent(retIdx)) )
                    return retIdx;
            error("subscript out of bounds");
        }

        template<typename RType>
        index_type read(RType * ptr, index_type offset, index_type count, Files * pfiles, size_t skip = 1) {
            index_type toRead, numRead, totLength;
            toRead = count;
            numRead = 0;
            totLength = index_extent(length() - 1);
            if ( offset < 0 || offset + count > totLength )
                error("subscript out of bounds");
            while ( numRead < count && offset < totLength ) {
                int i = find_atom(offset);
                index_type n = toRead < extent(i) ? toRead : extent(i);
                FILE * stream = pfiles->require(file_id(i));
                fseek(stream, file_offset(i, offset), SEEK_SET);
                switch(datamode(i)) {
                    case 1:
                        n = convert_read<short,RType>(ptr, n, stream, skip);
                        break;
                    case 2:
                        n = convert_read<int,RType>(ptr, n, stream, skip);
                        break;
                    case 3:
                        n = convert_read<long,RType>(ptr, n, stream, skip);
                        break;
                    case 4:
                        n = convert_read<float,RType>(ptr, n, stream, skip);
                        break;
                    case 5:
                        n = convert_read<double,RType>(ptr, n, stream, skip);
                        break;
                    default:
                        error("unsupported datamode");
                }
                toRead -= n;
                numRead += n;
                ptr += n;
                offset += n;
            }
            return numRead;
        }

        template<typename RType>
        index_type write(RType * ptr, index_type offset, index_type count, Files * pfiles, size_t skip = 1) {
            index_type toWrite, numWrote, totLength;
            toWrite = count;
            numWrote = 0;
            totLength = index_extent(length() - 1);
            if ( offset < 0 || offset + count > totLength )
                error("subscript out of bounds");
            while ( numWrote < count && offset < totLength ) {
                int i = find_atom(offset);
                index_type n = toWrite < extent(i) ? toWrite : extent(i);
                FILE * stream = pfiles->require(file_id(i));
                fseek(stream, file_offset(i, offset), SEEK_SET);
                switch(datamode(i)) {
                    case 1:
                        n = convert_write<short,RType>(ptr, n, stream, skip);
                        break;
                    case 2:
                        n = convert_write<int,RType>(ptr, n, stream, skip);
                        break;
                    case 3:
                        n = convert_write<long,RType>(ptr, n, stream, skip);
                        break;
                    case 4:
                        n = convert_write<float,RType>(ptr, n, stream, skip);
                        break;
                    case 5:
                        n = convert_write<double,RType>(ptr, n, stream, skip);
                        break;
                    default:
                        error("unsupported datamode");
                }
                toWrite -= n;
                numWrote += n;
                ptr += n;
                offset += n;
            }
            return numWrote;
        }

        template<typename RType>
        index_type readAt(RType * ptr, dbl_index_type * pindex, long length, Files * pfiles, size_t skip = 1) {
            index_type numRead;
            for ( long i = 0; i < length; i++ ) {
                if ( ISNA(pindex[i]) ) {
                    ptr[skip * i] = DataNA<RType>();
                    continue;
                }
                index_type nx = num_consecutive(pindex, i, length);
                if ( nx >= 0 ) {
                    index_type count = nx + 1;
                    index_type offset = static_cast<index_type>(pindex[i]);
                    numRead = read<RType>(ptr + (skip * i), offset, count, pfiles, skip);
                }
                else {
                    index_type count = (-nx) + 1;
                    index_type offset = static_cast<index_type>(pindex[i + (-nx)]);
                    numRead = read<RType>(ptr + skip * (i + (-nx)), offset, count, pfiles, -skip);
                }
                i += labs(nx);
            }
            return numRead;
        }

        template<typename RType>
        index_type writeAt(RType * ptr, dbl_index_type * pindex, long length, Files * pfiles, size_t skip = 1) {
            index_type numWrote;
            for ( long i = 0; i < length; i++ ) {
                if ( ISNA(pindex[i]) ) {
                    continue;
                }
                index_type nx = num_consecutive(pindex, i, length);
                if ( nx >= 0 ) {
                    index_type count = nx + 1;
                    index_type offset = static_cast<index_type>(pindex[i]);
                    numWrote = write<RType>(ptr + (skip * i), offset, count, pfiles, skip);
                }
                else {
                    index_type count = (-nx) + 1;
                    index_type offset = static_cast<index_type>(pindex[i + (-nx)]);
                    numWrote = write<RType>(ptr + skip * (i + (-nx)), offset, count, pfiles, -skip);
                }
                i += labs(nx);
            }
            return numWrote;
        }

    protected:

        int * _file_id;    // index from 1
        int * _datamode;   // 1 = short, 2 = int, 3 = index_type, 4 = float, 5 = double
        double * _offset;
        double * _extent;
        double * _index_offset; // index from 0
        double * _index_extent; // index from 0
        int _length;

};


//// Matter class
//----------------

class Matter
{

    public:

        Matter(SEXP x) : _files(x)
        {
            _data = GET_SLOT(x, mkString("data"));
            _datamode = INTEGER_VALUE(GET_SLOT(x, mkString("datamode")));
            _chunksize = INTEGER_VALUE(GET_SLOT(x, mkString("chunksize")));
            _length = static_cast<index_type>(NUMERIC_VALUE(GET_SLOT(x, mkString("length"))));
            _dim = GET_SLOT(x, mkString("dim"));
            const char * S4class = CHARACTER_VALUE(GET_CLASS(x));
            if ( strcmp(S4class, "matter_vec") == 0 )
                _S4class = 1;
            else if ( strcmp(S4class, "matter_matc") == 0 )
                _S4class = 2;
            else if ( strcmp(S4class, "matter_matr") == 0 )
                _S4class = 3;
        }

        ~Matter(){}

        SEXP data() {
            return _data;
        }

        SEXP data(int i) {
            if ( i < 0 || LENGTH(_data) <= i )
                error("subscript out of bounds");
            return VECTOR_ELT(_data, i);
        }

        int data_n() {
            switch(S4class()) {
                case 2:
                    return ncols();
                case 3:
                    return nrows();
            }
            return 0;
        }

        int datamode() {
            return _datamode;
        }

        Files * files() {
            return &_files;
        }

        int chunksize() {
            return _chunksize;
        }

        index_type length() {
            return _length;
        }

        int dim(int i) {
            return INTEGER(_dim)[i];
        }

        int dim_n() {
            return LENGTH(_dim);
        }

        int nrows() {
            if ( dim_n() == 2 )
                return dim(0);
            else
                return 0;
        }

        int ncols() {
            if ( dim_n() == 2 )
                return dim(1);
            else
                return 0;
        }

        int S4class() {
            return _S4class;
        }

        template<typename RType>
        SEXP readVector();

        template<typename RType>
        void writeVector(SEXP value);

        template<typename RType>
        SEXP readVectorElements(SEXP i);

        template<typename RType>
        void writeVectorElements(SEXP i, SEXP value);

        template<typename RType>
        SEXP readMatrix();

        template<typename RType>
        void writeMatrix(SEXP value);

        template<typename RType>
        SEXP readMatrixRows(SEXP i);

        template<typename RType>
        void writeMatrixRows(SEXP i, SEXP value);

        template<typename RType>
        SEXP readMatrixCols(SEXP j);

        template<typename RType>
        void writeMatrixCols(SEXP j, SEXP value);

        template<typename RType>
        SEXP readMatrixElements(SEXP i, SEXP j);

        template<typename RType>
        void writeMatrixElements(SEXP i, SEXP j, SEXP value);

        template<typename RType>
        SEXP rmult(SEXP y);

        template<typename RType>
        SEXP lmult(SEXP x);

        SEXP sum(bool na_rm = false);

        SEXP mean(bool na_rm = false);

        SEXP var(bool na_rm = false);

        SEXP colsums(bool na_rm = false);

        SEXP rowsums(bool na_rm = false);

        SEXP colmeans(bool na_rm = false);

        SEXP rowmeans(bool na_rm = false);

        SEXP colvar(bool na_rm = false);

        SEXP rowvar(bool na_rm = false);

    protected:

        SEXP _data;     // EITHER "atoms" OR a *list* or "atoms"
        int _datamode;  // 1 = integer, 2 = numeric
        Files _files;
        int _chunksize;
        index_type _length;
        SEXP _dim;
        int _S4class;      // 1 = vector, 2 = col-matrix, 3 = row-matrix

};


//// MatterAccessor class
//-----------------------

template<typename RType>
class MatterAccessor
{

    public:

        MatterAccessor(Matter & x) : _matter(x)
        {
            switch(x.S4class()) {
                case 1:
                    _atoms = new Atoms(x.data());
                    _next = -99;
                    break;
                default:
                    _atoms = new Atoms(x.data(0));
                    _next = 1;
                    break;
            }
            init();
        }

        MatterAccessor(Matter & x, int i) : _matter(x)
        {
            _atoms = new Atoms(x.data(i));
            _next = -99;
            init();
        }

        int init() {
            _chunksize = _atoms->max_extent() < _matter.chunksize() ? 
                _atoms->max_extent() : _matter.chunksize();
            _current = 0;
            _lower = 0;
            _upper = _chunksize - 1;
            _buffer = (RType *) Calloc(_chunksize, RType);
            return next_chunk();
        }

        ~MatterAccessor()
        {
            delete _atoms;
            Free(_buffer);
        }

        int next_chunk() {
            if ( _current < _atoms->max_extent() )
            {
                int count;
                if ( _current + _chunksize > _atoms->max_extent() )
                    count = _atoms->max_extent() - _current;
                else
                    count = _chunksize;
                if ( count > 0 )
                {
                    _lower = _current;
                    _upper = _current + count - 1;
                    return _atoms->read<RType>(_buffer, _current, count, _matter.files());
                }    
            }
            else if ( 0 <= _next && _next < _matter.data_n() )
            {
                delete _atoms;
                _atoms = new Atoms(_matter.data(_next));
                _next++;
                return init();
            }
            return 0;
        }

        RType operator*() { 
            return _buffer[_current % _chunksize];
        }

        MatterAccessor<RType> & operator++() {
            _current++;
            if ( _current > _upper )
                next_chunk();
            return *this;
        }

        operator bool() {
            return (0 <= _current && _current < _atoms->max_extent() && 
                _lower <= _current && _current <= _upper);
        }

        bool operator !() {
            return !(0 <= _current && _current < _atoms->max_extent() && 
                _lower <= _current && _current <= _upper);
        }

    protected:
        Matter & _matter;
        Atoms * _atoms;
        int _next;
        int _chunksize;
        index_type _current;
        index_type _lower;
        index_type _upper;
        RType * _buffer;
};

double sum(MatterAccessor<double> & x, bool na_rm = false);

double mean(MatterAccessor<double> & x, bool na_rm = false);

double var(MatterAccessor<double> & x, bool na_rm = false);

//// Exported C functions
//-----------------------

extern "C" {

    SEXP getVector(SEXP x);

    void setVector(SEXP x, SEXP value);

    SEXP getVectorElements(SEXP x, SEXP i);

    void setVectorElements(SEXP x, SEXP i, SEXP value);

    SEXP getMatrix(SEXP x);

    void setMatrix(SEXP x, SEXP value);

    SEXP getMatrixRows(SEXP x, SEXP i);

    void setMatrixRows(SEXP x, SEXP i, SEXP value);

    SEXP getMatrixCols(SEXP x, SEXP j);

    void setMatrixCols(SEXP x, SEXP j, SEXP value);

    SEXP getMatrixElements(SEXP x, SEXP i, SEXP j);

    void setMatrixElements(SEXP x, SEXP i, SEXP j, SEXP value);

    SEXP getSum(SEXP x, SEXP na_rm);

    SEXP getMean(SEXP x, SEXP na_rm);

    SEXP getVar(SEXP x, SEXP na_rm);

    SEXP getColSums(SEXP x, SEXP na_rm);

    SEXP getColMeans(SEXP x, SEXP na_rm);

    SEXP getColVar(SEXP x, SEXP na_rm);

    SEXP getRowSums(SEXP x, SEXP na_rm);

    SEXP getRowMeans(SEXP x, SEXP na_rm);

    SEXP getRowVar(SEXP x, SEXP na_rm);

    SEXP rightMultRMatrix(SEXP x, SEXP y);

    SEXP leftMultRMatrix(SEXP x, SEXP y);

}

#endif

