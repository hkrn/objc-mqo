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
//  GLMQObject.h
//  MQOReader
//
//  Created by hkrn on 09/07/14.
//  Copyright 2009 hkrn. All rights reserved.
//

#import "GLMQDocument+Common.h"

@interface GLMQObject : NSObject {
@public
    GLMQPoint3D minVertex;
    GLMQPoint3D maxVertex;
    GLMQPoint3D *vertexes;
    GLMQVertexMaterial *materialVertexes;
    GLMQFace *faces;
    int vertexSize;
    int faceSize;
    int depth;
    int folding;
    GLfloat scale[3];
    GLfloat rotation[3];
    GLfloat translation[3];
    int patch;
    int segment;
    int visible;
    int locking;
    int shading;
    GLfloat facet;
    GLfloat color[3];
    int colorType;
    int mirror;
    int mirrorAxis;
    GLfloat mirrorDistance;
    int lathe;
    int latheAxis;
    int latheSegment;
}

@property(readonly) GLMQPoint3D minVertex;
@property(readonly) GLMQPoint3D maxVertex;
@property(readonly) int vertexSize;
@property(readonly) int faceSize;
@property(readonly) int depth;
@property(readonly) int folding;
@property(readonly) const GLfloat *scale;
@property(readonly) const GLfloat *rotation;
@property(readonly) const GLfloat *translation;
@property(readonly) int patch;
@property(readonly) int segment;
@property(readonly) int visible;
@property(readonly) int locking;
@property(readonly) int shading;
@property(readonly) GLfloat facet;
@property(readonly) const GLfloat *color;
@property(readonly) int colorType;
@property(readonly) int mirror;
@property(readonly) int mirrorAxis;
@property(readonly) GLfloat mirrorDistance;
@property(readonly) int lathe;
@property(readonly) int latheAxis;
@property(readonly) int latheSegment;

@end
