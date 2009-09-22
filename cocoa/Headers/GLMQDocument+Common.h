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
//  GLMQDocument+Common.h
//  MQOReader
//
//  Created by hkrn on 09/07/20.
//  Copyright 2009 hkrn. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#else
#import <OpenGL/OpenGL.h>
#endif

@class GLMQScene;

typedef struct GLMQPoint2D GLMQPoint2D;
typedef struct GLMQPoint3D GLMQPoint3D;
typedef struct GLMQFace GLMQFace;
typedef struct GLMQVertexTexture GLMQVertexTexture;
typedef struct GLMQVertexPolygon GLMQVertexPolygon;
typedef struct GLMQVertexMaterial GLMQVertexMaterial;
typedef struct GLMQModel GLMQModel;
typedef GLMQPoint3D GLMQVector;

extern NSString *const GLMQErrorDomain;

struct GLMQPoint2D {
    GLfloat x;
    GLfloat y;
};

struct GLMQPoint3D {
    GLfloat x;
    GLfloat y;
    GLfloat z;
};

struct GLMQFace {
    GLMQPoint2D uv[4];
    int vertexIndexSize;
    int vertexIndexes[4];
    int materialIndex;
    uint32_t color;
};

struct GLMQVertexTexture {
    GLMQVector point;
    GLMQVector normal;
    GLfloat uv[2];
};

struct GLMQVertexPolygon {
    GLMQVector point;
    GLMQVector normal;
};

struct GLMQVertexMaterial {
    GLMQVertexTexture *texture;
    GLMQVertexPolygon *polygon;
    GLuint vboName;
    int vertexCount;
};

struct GLMQModel {
    GLMQPoint3D minVertex;
    GLMQPoint3D maxVertex;
    GLMQScene *scene;
    NSArray *materials;
    NSArray *objects;
    int materialIndex;
    int objectIndex;
};

enum GLMQChunkType {
    kGLMQRootChunk,
    kGLMQSceneChunk,
    kGLMQMaterialChunk,
    kGLMQObjectChunk
};

enum GLMQErrorType {
    kGLMQMemoryExhaustionError = 100,
    kGLMQParseError = 200,
    kGLMQInvalidHeaderError,
    kGLMQInvalidMaterialSizeError,
    kGLMQInvalidObjectSizeError,
    kGLMQInvalidNestError,
    kGLMQUnknownChunkError = 300,
    kGLMQUnknownSceneParameterError,
    kGLMQUnknownMaterialParameterError,
    kGLMQUnknownObjectParameterError,
    kGLMQInvalidTextureSizeError = 400,
    kGLMQInvalidTextureDataError
};

enum GLMQLoadType {
    kGLMQNotLoaded,
    kGLMQLoadFromFile,
    kGLMQLoadFromMemory
};
