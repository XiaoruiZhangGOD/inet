//
// (C) 2005 Vojtech Janota
// (C) 2010 Zoltan Bojthe
//
// This library is free software, you can redistribute it
// and/or modify
// it under  the terms of the GNU Lesser General Public License
// as published by the Free Software Foundation;
// either version 2 of the License, or any later version.
// The library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
// See the GNU Lesser General Public License for more details.
//

#ifndef __INET_BYTEARRAY_H
#define __INET_BYTEARRAY_H

#include "ByteArray_m.h"

/**
 * Class that carries raw bytes.
 */
class ByteArray : public ByteArray_Base
{
  public:
    /**
     * Constructor
     */
    ByteArray() : ByteArray_Base() {}

    /**
     * Copy constructor
     */
    ByteArray(const ByteArray& other) : ByteArray_Base(other) { }

    /**
     * operator =
     */
    ByteArray& operator=(const ByteArray& other) {ByteArray_Base::operator=(other); return *this;}

    /**
     * Creates and returns an exact copy of this object.
     */
    virtual ByteArray *dup() const {return new ByteArray(*this);}

    /**
     * Copy data from buffer
     * @param ptr: pointer to buffer
     * @param length: length of data
     */
    virtual void setDataFromBuffer(const void *ptr, unsigned int length);

    /**
     * Copy data from other ByteArray
     * @param other: reference to other ByteArray
     * @param offset: skipped first bytes from other
     * @param length: length of data
     */
    virtual void setDataFromByteArray(const ByteArray& other, unsigned int offset, unsigned int length);

    /**
     * Add data from buffer to the end of existing content
     * @param ptr: pointer to input buffer
     * @param length: length of data
     */
    virtual void addDataFromBuffer(const void *ptr, unsigned int length);

    /**
     * Copy data content to buffer
     * @param ptr: pointer to output buffer
     * @param length: length of buffer, maximum of copied bytes
     * @param srcOffs: number of skipped bytes from source
     * @return: length of copied data
     */
    virtual unsigned int copyDataToBuffer(void *ptr, unsigned int length, unsigned int srcOffs = 0) const;

    /**
     * Set buffer pointer and buffer length
     * @param ptr: pointer to new buffer, must created by `buffer = new char[length1];` where length1>=length
     * @param length: length of buffer
     */
    virtual void assignBuffer(void *ptr, unsigned int length);

    /**
     * Truncate data content
     * @param truncleft: The number of bytes from the beginning of the content be remove
     * @param truncright: The number of bytes from the end of the content be remove
     * Generate assert when not have enough bytes for truncation
     */
    virtual void truncateData(unsigned int truncleft, unsigned int truncright = 0);

    /**
     * Returns pointer of stored data
     */
    virtual const char *getDataArrayPointer() const { return data_var; }
};

#endif //  __INET_BYTEARRAY_H
