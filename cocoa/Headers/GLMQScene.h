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
//  GLMQScene.h
//  MQOReader
//
//  Created by hkrn on 09/08/02.
//  Copyright 2009 hkrn. All rights reserved.
//

#import "GLMQDocument+Common.h"

@interface GLMQScene : NSObject {
@public
    GLfloat ambient[3];
    GLfloat position[3];
    GLfloat lookAt[3];
    GLfloat head;
    GLfloat pich;
    GLfloat ortho;
    GLfloat zoom2;
}

@property(readonly) const GLfloat *ambient;
@property(readonly) const GLfloat *position;
@property(readonly) const GLfloat *lookAt;
@property(readonly) GLfloat head;
@property(readonly) GLfloat pich;
@property(readonly) GLfloat ortho;
@property(readonly) GLfloat zoom2;

@end
