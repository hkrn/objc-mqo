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
//  GLMQDocument.h
//  MQOReader
//
//  Created by hkrn on 09/07/13.
//  Copyright 2009 hkrn. All rights reserved.
//

#import "GLMQDocument+Common.h"

@class GLMQMaterial;
@class GLMQObject;
@class GLMQScene;

@interface GLMQDocument : NSObject
{
@private
    GLMQModel *model;
    NSDictionary *images;
    const NSString *dir;
    enum GLMQChunkType chunk;
    struct _s {
        enum GLMQLoadType type;
        union _u {
            int fd;
            const NSData *data;
        } u;
    } s;
    const char *ptr;
    off_t length;
    off_t pos;
    GLfloat version;
}

- (NSUInteger)objectCount;
- (GLMQObject *)objectAtIndex:(NSUInteger)i;
- (NSUInteger)materialCount;
- (GLMQMaterial *)materialAtIndex:(NSUInteger)i;
- (void)setImageData:(NSData *)data
              forKey:(NSString *)key;

@property(nonatomic, readonly) const GLMQPoint3D *minVertex;
@property(nonatomic, readonly) const GLMQPoint3D *maxVertex;
@property(nonatomic, readonly) GLMQScene *scene;
@property(nonatomic, readonly) NSArray *keysForImage;

@end
