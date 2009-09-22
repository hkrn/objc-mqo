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
//  GLMQMaterial.h
//  MQOReader
//
//  Created by hkrn on 09/07/14.
//  Copyright 2009 hkrn. All rights reserved.
//

#import "GLMQDocument+Common.h"

@interface GLMQMaterial : NSObject {
@public
    GLfloat color[4];
    GLfloat diffuse[4];
    GLfloat ambient[4];
    GLfloat emission[4];
    GLfloat specular[4];
    GLfloat projectionPosition[3];
    GLfloat projectionScale[3];
    GLfloat projectionAngle[3];
    GLfloat power;
    GLuint textureName;
    int projectionType;
    char texturePath[64];
    char alphaTexturePath[64];
    char bumpTexturePath[64];
}

@property(readonly) const GLfloat *color;
@property(readonly) const GLfloat *diffuse;
@property(readonly) const GLfloat *ambient;
@property(readonly) const GLfloat *emission;
@property(readonly) const GLfloat *specular;
@property(readonly) const GLfloat *projectionPosition;
@property(readonly) const GLfloat *projectionScale;
@property(readonly) const GLfloat *projectionAngle;
@property(readonly) int projectionType;
@property(readonly) GLfloat power;
@property(readonly) const char *texturePath;
@property(readonly) const char *alphaTexturePath;
@property(readonly) const char *bumpTexturePath;

@end
