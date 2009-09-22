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
//  GLMQDocument.m
//  MQOReader
//
//  Created by hkrn on 09/07/13.
//  Copyright 2009 hkrn. All rights reserved.
//

#import "GLMQDocument.h"
#import "GLMQDocument+Private.h"
#import "GLMQMaterial.h"
#import "GLMQMaterial+Private.h"
#import "GLMQObject.h"
#import "GLMQObject+Private.h"

@implementation GLMQDocument

NSString *const GLMQErrorDomain = @"GLMQErrorDomain";

- (id)init
{
    self = [super init];
    if (self != nil) {
        images = [[NSMutableDictionary alloc] init];
        dir = nil;
        ptr = NULL;
        model = NULL;
        pos = 0;
        version = 0;
        chunk = kGLMQRootChunk;
        s.type = kGLMQNotLoaded;
    }
    return self;
}

- (void)dealloc
{
    if (s.type == kGLMQLoadFromFile) {
        munmap((void *)ptr, (size_t)length);
        close(s.u.fd);
    }
    else if (s.type == kGLMQLoadFromMemory) {
        [s.u.data release];
    }
    ptr = NULL;
    if (model != NULL) {
        int objectSize = (int)[model->objects count], materialSize = (int)[model->materials count];
        for (int i = 0; i < objectSize; i++) {
            GLMQObject *object = [model->objects objectAtIndex:i];
            free(object->vertexes);
            free(object->faces);
            object->vertexes = NULL;
            object->faces = NULL;
            if (object->materialVertexes != NULL) {
                for (int j = 0; j < materialSize; j++) {
                    GLMQVertexMaterial *vertex = &object->materialVertexes[j];
                    free(vertex->texture);
                    free(vertex->polygon);
                    vertex->texture = NULL;
                    vertex->polygon = NULL;
#if GL_ARB_vertex_buffer_object
                    glDeleteBuffersARB(1, &vertex->vboName);
#endif
                }
            }
            free(object->materialVertexes);
            object->materialVertexes = NULL;
        }
        for (int i = 0; i < materialSize; i++) {
            GLMQMaterial *material = [model->materials objectAtIndex:i];
            if (material->textureName != 0)
                glDeleteTextures(1, &material->textureName);
        }
        [model->scene release];
        [model->materials release];
        [model->objects release];
        model->materials = nil;
        model->objects = nil;
    }
    free(model);
    model = NULL;
    [images release];
    [super dealloc];
}

- (NSUInteger)objectCount
{
    return [model->objects count];
}

- (GLMQObject *)objectAtIndex:(NSUInteger)i
{
    GLMQObject *object = [model->objects objectAtIndex:i];
    return object;
}

- (NSUInteger)materialCount
{
    return [model->materials count];
}

- (GLMQMaterial *)materialAtIndex:(NSUInteger)i
{
    GLMQMaterial *material = [model->materials objectAtIndex:i];
    return material;
}

- (const GLMQPoint3D *)minVertex
{
    return &model->minVertex;
}

- (const GLMQPoint3D *)maxVertex
{
    return &model->maxVertex;
}

- (GLMQScene *)scene
{
    return model->scene;
}

- (NSArray *)keysForImage
{
    return [images allKeys];
}

- (void)setImageData:(NSData *)data
              forKey:(NSString *)key
{
    [images setValue:data
              forKey:key];
    [data release];
}

@end
