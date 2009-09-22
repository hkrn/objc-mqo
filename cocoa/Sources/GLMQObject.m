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
//  GLMQObject.m
//  MQOReader
//
//  Created by hkrn on 09/07/14.
//  Copyright 2009 hkrn. All rights reserved.
//

#import "GLMQObject.h"
#import "GLMQObject+Private.h"

@implementation GLMQObject

@synthesize minVertex;
@synthesize maxVertex;
@synthesize vertexSize;
@synthesize faceSize;
@synthesize depth;
@synthesize folding;
@synthesize patch;
@synthesize segment;
@synthesize visible;
@synthesize locking;
@synthesize shading;
@synthesize facet;
@synthesize colorType;
@synthesize mirror;
@synthesize mirrorAxis;
@synthesize mirrorDistance;
@synthesize lathe;
@synthesize latheAxis;
@synthesize latheSegment;

- (const GLMQPoint3D *)vertexes
{
    return (const GLMQPoint3D *)vertexes;
}

- (const GLMQVertexMaterial *)materialVertexes
{
    return (const GLMQVertexMaterial *)materialVertexes;
}

- (const GLMQFace *)faces
{
    return (const GLMQFace *)faces;
}

- (const GLfloat *)scale
{
    return (GLfloat *)scale;
}

- (const GLfloat *)rotation
{
    return (const GLfloat *)rotation;
}

- (const GLfloat *)translation
{
    return (const GLfloat *)translation;
}

- (const GLfloat *)color
{
    return (const GLfloat *)color;
}

@end
