/*
 The MIT License
 
 Copyright (c) 2009 hkrn
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

//
//  GLMQDocument+Private.h
//  MQOReader
//
//  Created by hkrn on 09/07/13.
//  Copyright 2009 hkrn. All rights reserved.
//

#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>

#define GLMQSetNSPOSIXErrorAndReturnNo(error) \
if (error != NULL) { \
*error = [NSError errorWithDomain:NSPOSIXErrorDomain \
code:errno \
userInfo:nil]; \
} \
return NO

#define GLMQSetNSPOSIXErrorAndReturnNoIf(cond, error) \
if (cond) { GLMQSetNSPOSIXErrorAndReturnNo(error); }

#define GLMQSetGLMQErrorAndReturnNo(errno, error) \
if (error != NULL) { \
*error = [NSError errorWithDomain:GLMQErrorDomain \
code:(errno) \
userInfo:nil]; \
} \
return NO

#define GLMQSetGLMQErrorAndReturnNoIf(cond, errno, error) \
if (cond) { GLMQSetGLMQErrorAndReturnNo(errno, error); }
