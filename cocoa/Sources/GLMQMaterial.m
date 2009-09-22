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
//  GLMQMaterial.m
//  MQOReader
//
//  Created by hkrn on 09/07/14.
//  Copyright 2009 hkrn. All rights reserved.
//

#import "GLMQMaterial.h"
#import "GLMQMaterial+Private.h"

@implementation GLMQMaterial

@synthesize textureName;
@synthesize projectionType;
@synthesize power;

- (const GLfloat *)color
{
    return (const GLfloat *)color;
}

- (const GLfloat *)diffuse
{
    return (const GLfloat *)diffuse;
}

- (const GLfloat *)ambient
{
    return (const GLfloat *)ambient;
}

- (const GLfloat *)emission
{
    return (const GLfloat *)emission;
}

- (const GLfloat *)specular
{
    return (const GLfloat *)specular;
}

- (const GLfloat *)projectionPosition
{
    return (const GLfloat *)projectionPosition;
}

- (const GLfloat *)projectionScale
{
    return (const GLfloat *)projectionScale;
}

- (const GLfloat *)projectionAngle
{
    return (const GLfloat *)projectionAngle;
}

- (const char *)texturePath
{
    return (const char *)texturePath;
}

- (const char *)alphaTexturePath
{
    return (const char *)alphaTexturePath;
}

- (const char *)bumpTexturePath
{
    return (const char *)bumpTexturePath;
}

@end
