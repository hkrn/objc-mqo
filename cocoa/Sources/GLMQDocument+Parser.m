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
//  GLMQDocument+Parser.m
//  MQOReader
//
//  Created by hkrn on 09/07/13.
//  Copyright 2009 hkrn. All rights reserved.
//

#import "GLMQDocument+Parser.h"
#import "GLMQDocument+Private.h"
#import "GLMQMaterial.h"
#import "GLMQMaterial+Private.h"
#import "GLMQObject.h"
#import "GLMQObject+Private.h"
#import "GLMQScene.h"

@implementation GLMQDocument (Parser)

#define GLMQSkipBytesWhile(cond) do { \
char c = *(ptr + pos);\
while (pos < length && (cond)) { ++pos; c = *(ptr + pos); } \
} while(0)

- (void)skipSpaces
{
    // skip spaces but NOT Line Feed
    GLMQSkipBytesWhile(isspace(c) && c != 012);
}

- (void)skipToNextLine
{
    // skip until Line Feed finds
    GLMQSkipBytesWhile(c != 012);
    ++pos;
    [self skipSpaces];
}

- (int)countWordLength
{
    off_t from = pos;
    // count characters except spaces, Line Feed and Carriage Return
    GLMQSkipBytesWhile(!isspace(c) && c != 012 && c != 015);
    off_t to = pos;
    pos = from;
    return (int)(to - from);
}

#undef GLMQSkipBytesWhile

- (void)getQuotedString:(char **)str
                 length:(int *)len
                  limit:(int)limit
{
    int l = 0;
    char c = *(ptr + pos);
    if (c == '"') {
        ++pos;
        c = *(ptr + pos);
        off_t from = pos;
        // count characters except double quote, but NOT '\"'
        while (pos < length && c != '"' && *(ptr + pos - 1) != '\\') {
            ++pos;
            c = *(ptr + pos);
        }
        l = (int)(pos - from);
        // ensure to input the null terminator
        l = MIN(limit - 1, l);
        pos = from;
    }
    memset(*str, 0, limit);
    memcpy(*str, ptr + pos, l);
    *len = l;
}

- (int)countWordLengthAndSkipSpaces
{
    // get the length of the word and forward to the next word
    int len = [self countWordLength];
    pos += len;
    [self skipSpaces];
    return len;
}

#define GLMQ_S2N_BUFSIZ 32

static inline void GLMQGetInt(int *n, const void *p, int len)
{
    char s2n[GLMQ_S2N_BUFSIZ];
    // ensure to input the null terminator
    len = MIN(len, GLMQ_S2N_BUFSIZ - 1);
    memcpy(s2n, p, len);
    s2n[len] = '\0';
    *n = (int)strtol(s2n, NULL, 10);
}

static inline void GLMQGetFloat(GLfloat *n, const void *p, int len)
{
    char s2n[GLMQ_S2N_BUFSIZ];
    // ensure to input the null terminator
    len = MIN(len, GLMQ_S2N_BUFSIZ - 1);
    memcpy(s2n, p, len);
    s2n[len] = '\0';
    *n = strtof(s2n, NULL);
}

#undef GLMQ_S2N_BUFSIZ

- (void)skipSpacesAfterGettingInt:(int *)n
{
    // get the integer and forward to the next word
    int len = [self countWordLength];
    GLMQGetInt(n, ptr + pos, len);
    pos += len;
    [self skipSpaces];
}

- (void)skipSpacesAfterGettingFloat:(GLfloat *)n
{
    // get the GLfloat and forward to the next word
    int len = [self countWordLength];
    GLMQGetFloat(n, ptr + pos, len);
    pos += len;
    [self skipSpaces];
}

- (void)skipSpacesAfterForwarding:(int)forward
{
    // only forward to the next word with a number of forwarding
    pos += forward;
    [self skipSpaces];
}

- (BOOL)skipSpacesAfterComparingWord:(const char *)word
{
    int len = [self countWordLength];
    BOOL r = pos + len < length && memcmp(ptr + pos, word, len) == 0;
    pos += len;
    [self skipSpaces];
    return r;
}

- (void)skipSpacesAfterGettingQuotedString:(char **)str
                                    length:(int *)len
                                     limit:(int)limit
{
    // get the GLfloat and forward to the next word
    [self getQuotedString:str
                   length:len
                    limit:limit];
    pos += *len;
    if (!isspace(*(ptr + pos)))
        pos += [self countWordLength];
    [self skipSpaces];
}

- (BOOL)parseSceneChunkWithWordLength:(int)wordLength
                                error:(NSError **)error
{
    // skip all values
    const char *const p = ptr + pos;
    GLMQScene *scene = (GLMQScene *)model->scene;
    if (wordLength == 0) {
        GLMQSetGLMQErrorAndReturnNo(kGLMQParseError, error);
    }
    else if (wordLength == 3) {
        if (memcmp(p, "amb", 3) == 0) {
            [self skipSpacesAfterForwarding:3];
            [self skipSpacesAfterGettingFloat:&scene->ambient[0]];
            [self skipSpacesAfterGettingFloat:&scene->ambient[1]];
            [self skipSpacesAfterGettingFloat:&scene->ambient[2]];
            return YES;
        }
        else if (memcmp(p, "pos", 3) == 0) {
            [self skipSpacesAfterForwarding:3];
            [self skipSpacesAfterGettingFloat:&scene->position[0]];
            [self skipSpacesAfterGettingFloat:&scene->position[1]];
            [self skipSpacesAfterGettingFloat:&scene->position[2]];
            return YES;
        }
    }
    else if (wordLength == 4) {
        if (memcmp(p, "head", 4) == 0) {
            [self skipSpacesAfterForwarding:4];
            [self skipSpacesAfterGettingFloat:&scene->head];
            return YES;
        }
        else if (memcmp(p, "pich", 4) == 0) {
            [self skipSpacesAfterForwarding:4];
            [self skipSpacesAfterGettingFloat:&scene->pich];
            return YES;
        }
    }
    else if (wordLength == 5) {
        if (memcmp(p, "ortho", 5) == 0) {
            [self skipSpacesAfterForwarding:5];
            [self skipSpacesAfterGettingFloat:&scene->ortho];
            return YES;
        }
        else if (memcmp(p, "zoom2", 5) == 0) {
            [self skipSpacesAfterForwarding:5];
            [self skipSpacesAfterGettingFloat:&scene->zoom2];
            return YES;
        }
    }
    else if (wordLength == 6 && memcmp(p, "lookat", 6) == 0) {
        [self skipSpacesAfterForwarding:6];
        [self skipSpacesAfterGettingFloat:&scene->lookAt[0]];
        [self skipSpacesAfterGettingFloat:&scene->lookAt[1]];
        [self skipSpacesAfterGettingFloat:&scene->lookAt[2]];
        return YES;
    }
    GLMQSetGLMQErrorAndReturnNo(kGLMQUnknownSceneParameterError, error);
    return NO;
}

- (BOOL)parseMaterialChunk:(NSError **)error
{
    // material name
    int shader = 0, vcol = 0;
    GLfloat diffuse = 0, ambient = 0, emission = 0, specular = 0, power = 0;
    GLfloat red = 0, green = 0, blue = 0, alpha = 0;
    GLMQSetGLMQErrorAndReturnNoIf(model->materialIndex >= (int)[model->materials count],
                                           kGLMQInvalidMaterialSizeError, error);
    GLMQMaterial *material = [model->materials objectAtIndex:model->materialIndex];
    // skip material's name
    int wordLength = [self countWordLength];
    pos += wordLength;
    [self skipSpaces];
    wordLength = [self countWordLength];
    while (wordLength != 0) {
        const char *p = ptr + pos;
        if (wordLength >= 4) {
            if (memcmp(p, "amb(", 4) == 0) {
                pos += 4;
                [self skipSpacesAfterGettingFloat:&ambient];
            }
            else if (memcmp(p, "col(", 4) == 0) {
                pos += 4;
                [self skipSpacesAfterGettingFloat:&red];
                [self skipSpacesAfterGettingFloat:&green];
                [self skipSpacesAfterGettingFloat:&blue];
                [self skipSpacesAfterGettingFloat:&alpha];
            }
            else if (memcmp(p, "dif(", 4) == 0) {
                pos += 4;
                [self skipSpacesAfterGettingFloat:&diffuse];
            }
            else if (memcmp(p, "emi(", 4) == 0) {
                pos += 4;
                [self skipSpacesAfterGettingFloat:&emission];
            }
            else if (memcmp(p, "spc(", 4) == 0) {
                pos += 4;
                [self skipSpacesAfterGettingFloat:&specular];
            }
            else if (memcmp(p, "tex(", 4) == 0) {
                pos += 4;
                char *path = material->texturePath;
                [self skipSpacesAfterGettingQuotedString:&path
                                                  length:&wordLength
                                                   limit:(int)sizeof(material->texturePath)];
                NSString *pathForKey = [[NSString alloc] initWithBytesNoCopy:path
                                                                      length:wordLength
                                                                    encoding:NSShiftJISStringEncoding
                                                                freeWhenDone:NO];
                if (pathForKey != nil) {
                    [images setValue:[NSNull null]
                              forKey:pathForKey];
                    [pathForKey release];
                }
            }
            else if (wordLength >= 5) {
                if (memcmp(p, "bump(", 5) == 0) {
                    pos += 5;
                    char *path = material->bumpTexturePath;
                    [self skipSpacesAfterGettingQuotedString:&path
                                                      length:&wordLength
                                                       limit:(int)sizeof(material->bumpTexturePath)];
                    NSString *pathForKey = [[NSString alloc] initWithBytesNoCopy:path
                                                                          length:wordLength
                                                                        encoding:NSShiftJISStringEncoding
                                                                    freeWhenDone:NO];
                    if (pathForKey != nil) {
                        [images setValue:[NSNull null]
                                  forKey:pathForKey];
                        [pathForKey release];
                    }
                }
                else if (memcmp(p, "vcol(", 5) == 0) {
                    pos += 5;
                    [self skipSpacesAfterGettingInt:&vcol];
                }
                else if (wordLength >= 6 && memcmp(p, "power(", 6) == 0) {
                    pos += 6;
                    [self skipSpacesAfterGettingFloat:&power];
                    material->power = power;
                }
                else if (wordLength >= 7) {
                    if (memcmp(p, "aplane(", 7) == 0) {
                        pos += 7;
                        char *path = material->alphaTexturePath;
                        [self skipSpacesAfterGettingQuotedString:&path
                                                          length:&wordLength
                                                           limit:(int)sizeof(material->alphaTexturePath)];
                        NSString *pathForKey = [[NSString alloc] initWithBytesNoCopy:path
                                                                              length:wordLength
                                                                            encoding:NSShiftJISStringEncoding
                                                                        freeWhenDone:NO];
                        if (pathForKey != nil) {
                            [images setValue:[NSNull null]
                                      forKey:pathForKey];
                            [pathForKey release];
                        }
                    }
                    else if (memcmp(p, "shader(", 7) == 0) {
                        pos += 7;
                        [self skipSpacesAfterGettingInt:&shader];
                    }
                    else if (wordLength >= 9 && memcmp(p, "proj_pos(", 9) == 0) {
                        pos += 9;
                        [self skipSpacesAfterGettingFloat:&material->projectionPosition[0]];
                        [self skipSpacesAfterGettingFloat:&material->projectionPosition[1]];
                        [self skipSpacesAfterGettingFloat:&material->projectionPosition[2]];
                    }
                    else if (wordLength >= 10 && memcmp(p, "proj_type(", 10) == 0) {
                        pos += 10;
                        [self skipSpacesAfterGettingInt:&material->projectionType];
                    }
                    else if (wordLength >= 11) {
                        if (memcmp(p, "proj_scale(", 11) == 0) {
                            [self skipSpacesAfterGettingFloat:&material->projectionScale[0]];
                            [self skipSpacesAfterGettingFloat:&material->projectionScale[1]];
                            [self skipSpacesAfterGettingFloat:&material->projectionScale[2]];
                        }
                        else if (memcmp(p, "proj_angle(", 11) == 0) {
                            pos += 11;
                            [self skipSpacesAfterGettingFloat:&material->projectionAngle[0]];
                            [self skipSpacesAfterGettingFloat:&material->projectionAngle[1]];
                            [self skipSpacesAfterGettingFloat:&material->projectionAngle[2]];
                        }
                        else {
                            GLMQSetGLMQErrorAndReturnNo(kGLMQUnknownMaterialParameterError, error);
                        }
                    }
                    else {
                        GLMQSetGLMQErrorAndReturnNo(kGLMQUnknownMaterialParameterError, error);
                    }
                }
                else {
                    GLMQSetGLMQErrorAndReturnNo(kGLMQUnknownMaterialParameterError, error);
                }
            }
            else {
                GLMQSetGLMQErrorAndReturnNo(kGLMQUnknownMaterialParameterError, error);
            }
        }
        else {
            GLMQSetGLMQErrorAndReturnNo(kGLMQUnknownMaterialParameterError, error);
        }
        wordLength = [self countWordLength];
    }
    GLfloat *col = material->color;
    col[0] = red;
    col[1] = green;
    col[2] = blue;
    GLfloat *dif = material->diffuse;
    dif[0] = diffuse * red;
    dif[1] = diffuse * green;
    dif[2] = diffuse * blue;
    GLfloat *amb = material->ambient;
    amb[0] = ambient * red;
    amb[1] = ambient * green;
    amb[2] = ambient * blue;
    GLfloat *emi = material->emission;
    emi[0] = emission * red;
    emi[1] = emission * green;
    emi[2] = emission * blue;
    GLfloat *spc = material->specular;
    spc[0] = specular * red;
    spc[1] = specular * green;
    spc[2] = specular * blue;
    col[3] = dif[3] = amb[3] = emi[3] = spc[3] = alpha;
    ++model->materialIndex;
    return YES;
}

- (BOOL)parseVertexChunkInLength:(int)len
                          object:(GLMQObject *)object
                           error:(NSError **)error
{
    if (*(ptr + pos) != '{') {
        if (error)
            *error = [NSError errorWithDomain:GLMQErrorDomain
                                         code:kGLMQInvalidNestError
                                     userInfo:nil];
        return NO;
    }
    [self skipToNextLine];
    GLMQPoint3D *vertexes = calloc(len, sizeof(GLMQPoint3D));
    if (vertexes == NULL) {
        if (error)
            *error = [NSError errorWithDomain:GLMQErrorDomain
                                         code:kGLMQMemoryExhaustionError
                                     userInfo:nil];
        return NO;
    }
    int wordLength = [self countWordLength], i = 0;
    while (wordLength != 0 && *(ptr + pos) != '}' && i < len) {
        GLMQPoint3D *vertex = &vertexes[i];
        GLMQGetFloat(&vertex->x, ptr + pos, wordLength);
        pos += wordLength;
        [self skipSpaces];
        [self skipSpacesAfterGettingFloat:&vertex->y];
        [self skipSpacesAfterGettingFloat:&vertex->z];
        [self skipToNextLine];
        wordLength = [self countWordLength];
        i++;
    }
    object->vertexes = vertexes;
    return YES;
}

- (BOOL)parseFacesChunkInLength:(int)len
                         object:(GLMQObject *)object
                          error:(NSError **)error
{
    if (*(ptr + pos) != '{') {
        if (error)
            *error = [NSError errorWithDomain:GLMQErrorDomain
                                         code:kGLMQInvalidNestError
                                     userInfo:nil];
        return NO;
    }
    [self skipToNextLine];
    GLMQFace *faces = calloc(len, sizeof(GLMQFace));
    if (faces == NULL) {
        if (error)
            *error = [NSError errorWithDomain:GLMQErrorDomain
                                         code:kGLMQMemoryExhaustionError
                                     userInfo:nil];
        return NO;
    }
    int wordLength = [self countWordLength], i = 0;
    while (wordLength != 0 && *(ptr + pos) != '}' && i < len) {
        GLMQFace *face = &faces[i];
        int vertexIndexSize = 0;
        GLMQGetInt(&vertexIndexSize, ptr + pos, wordLength);
        face->vertexIndexSize = vertexIndexSize;
        pos += wordLength;
        [self skipSpaces];
        // V(
        if (*(ptr + pos) == 'V') {
            pos += 2;
            [self skipSpacesAfterGettingInt:&face->vertexIndexes[0]];
            [self skipSpacesAfterGettingInt:&face->vertexIndexes[1]];
            [self skipSpacesAfterGettingInt:&face->vertexIndexes[2]];
            if (vertexIndexSize == 4)
                [self skipSpacesAfterGettingInt:&face->vertexIndexes[3]];
        }
        if (*(ptr + pos) == 'M') {
            // M(
            pos += 2;
            [self skipSpacesAfterGettingInt:&face->materialIndex];
        }
        // UV(
        if (*(ptr + pos) == 'U' && *(ptr + pos + 1) == 'V') {
            pos += 3;
            GLMQPoint2D *uv = face->uv;
            [self skipSpacesAfterGettingFloat:&uv[0].x];
            [self skipSpacesAfterGettingFloat:&uv[0].y];
            [self skipSpacesAfterGettingFloat:&uv[1].x];
            [self skipSpacesAfterGettingFloat:&uv[1].y];
            [self skipSpacesAfterGettingFloat:&uv[2].x];
            [self skipSpacesAfterGettingFloat:&uv[2].y];
            if (vertexIndexSize == 4) {
                [self skipSpacesAfterGettingFloat:&uv[3].x];
                [self skipSpacesAfterGettingFloat:&uv[3].y];
            }
        }
        [self skipToNextLine];
        wordLength = [self countWordLength];
        i++;
    }
    object->faces = faces;
    return YES;
}

- (BOOL)parseObjectChunkWithWordLength:(int)wordLength
                                 error:(NSError **)error
{
    const char *const p = ptr + pos;
    int vertexSize = 0, faceSize = 0;
    if (model->objectIndex > (int)[model->objects count]) {
        if (error)
            *error = [NSError errorWithDomain:GLMQErrorDomain
                                         code:kGLMQInvalidObjectSizeError
                                     userInfo:nil];
        return NO;
    }
    GLMQObject *object = (GLMQObject *)[model->objects objectAtIndex:model->objectIndex];
    if (wordLength == 0) {
        if (error)
            *error = [NSError errorWithDomain:GLMQErrorDomain
                                         code:kGLMQParseError
                                     userInfo:nil];
        return NO;
    }
    else if (wordLength == 4 && memcmp(p, "face", 4) == 0) {
        [self skipSpacesAfterForwarding:4];
        [self skipSpacesAfterGettingInt:&faceSize];
        if (![self parseFacesChunkInLength:faceSize
                                    object:object
                                     error:error])
            return NO;
        object->faceSize = faceSize;
        return YES;
    }
    else if (wordLength == 5) {
        if (memcmp(p, "color", 5) == 0) {
            [self skipSpacesAfterForwarding:5];
            // Red => [0] / Green => [1] / Blue => [2]
            [self skipSpacesAfterGettingFloat:&object->color[0]];
            [self skipSpacesAfterGettingFloat:&object->color[1]];
            [self skipSpacesAfterGettingFloat:&object->color[2]];
            return YES;
        }
        else if (memcmp(p, "depth", 5) == 0) {
            [self skipSpacesAfterForwarding:5];
            [self skipSpacesAfterGettingInt:&object->depth];
            return YES;
        }
        else if (memcmp(p, "facet", 5) == 0) {
            [self skipSpacesAfterForwarding:5];
            [self skipSpacesAfterGettingFloat:&object->facet];
            return YES;
        }
        else if (memcmp(p, "lathe", 5) == 0) {
            [self skipSpacesAfterForwarding:5];
            [self skipSpacesAfterGettingInt:&object->lathe];
            return YES;
        }
        else if (memcmp(p, "patch", 5) == 0) {
            [self skipSpacesAfterForwarding:5];
            [self skipSpacesAfterGettingInt:&object->patch];
            return YES;
        }
        else if (memcmp(p, "scale", 5) == 0) {
            [self skipSpacesAfterForwarding:5];
            // X => [0] / Y => [1] / Z => [2]
            [self skipSpacesAfterGettingFloat:&object->scale[0]];
            [self skipSpacesAfterGettingFloat:&object->scale[1]];
            [self skipSpacesAfterGettingFloat:&object->scale[2]];
            return YES;
        }
    }
    else if (wordLength == 6) {
        if (memcmp(p, "mirror", 6) == 0) {
            [self skipSpacesAfterForwarding:6];
            [self skipSpacesAfterGettingInt:&object->mirror];
            return YES;
        }
        else if (memcmp(p, "vertex", 6) == 0) {
            [self skipSpacesAfterForwarding:6];
            [self skipSpacesAfterGettingInt:&vertexSize];
            if (![self parseVertexChunkInLength:vertexSize
                                         object:object
                                          error:error])
                return NO;
            object->vertexSize = vertexSize;
            return YES;
        }
    }
    else if (wordLength == 7) {
        if (memcmp(p, "folding", 7) == 0) {
            [self skipSpacesAfterForwarding:7];
            [self skipSpacesAfterGettingInt:&object->folding];
            return YES;
        }
        else if (memcmp(p, "locking", 7) == 0) {
            [self skipSpacesAfterForwarding:7];
            [self skipSpacesAfterGettingInt:&object->locking];
            return YES;
        }
        else if (memcmp(p, "segment", 7) == 0) {
            [self skipSpacesAfterForwarding:7];
            [self skipSpacesAfterGettingInt:&object->segment];
            return YES;
        }
        else if (memcmp(p, "shading", 7) == 0) {
            [self skipSpacesAfterForwarding:7];
            [self skipSpacesAfterGettingInt:&object->shading];
            return YES;
        }
        else if (memcmp(p, "visible", 7) == 0) {
            [self skipSpacesAfterForwarding:7];
            [self skipSpacesAfterGettingInt:&object->visible];
            return YES;
        }
    }
    else if (wordLength == 8 && memcmp(p, "rotation", 8) == 0) {
        [self skipSpacesAfterForwarding:8];
        // H => [0] / P => [1] / B => [2]
        [self skipSpacesAfterGettingFloat:&object->rotation[0]];
        [self skipSpacesAfterGettingFloat:&object->rotation[1]];
        [self skipSpacesAfterGettingFloat:&object->rotation[2]];
        return YES;
    }
    else if (wordLength == 9 && memcmp(p, "lathe_seg", 9) == 0) {
        [self skipSpacesAfterForwarding:9];
        [self skipSpacesAfterGettingInt:&object->latheSegment];
        return YES;
    }
    else if (wordLength == 10) {
        if (memcmp(p, "color_type", 10) == 0) {
            [self skipSpacesAfterForwarding:10];
            [self skipSpacesAfterGettingInt:&object->colorType];
            return YES;
        }
        else if (memcmp(p, "lathe_axis", 10) == 0) {
            [self skipSpacesAfterForwarding:10];
            [self skipSpacesAfterGettingInt:&object->latheAxis];
            return YES;
        }
        else if (memcmp(p, "mirror_dis", 10) == 0) {
            [self skipSpacesAfterForwarding:10];
            [self skipSpacesAfterGettingFloat:&object->mirrorDistance];
            return YES;
        }
    }
    else if (wordLength == 11) {
        if (memcmp(p, "mirror_axis", 11) == 0) {
            [self skipSpacesAfterForwarding:11];
            [self skipSpacesAfterGettingInt:&object->mirrorAxis];
            return YES;
        }
        else if (memcmp(p, "translation", 11) == 0) {
            [self skipSpacesAfterForwarding:11];
            [self skipSpacesAfterGettingFloat:&object->translation[0]];
            [self skipSpacesAfterGettingFloat:&object->translation[1]];
            [self skipSpacesAfterGettingFloat:&object->translation[2]];
            return YES;
        }
    }
    GLMQSetGLMQErrorAndReturnNo(kGLMQUnknownObjectParameterError, error);
    return NO;
}

- (BOOL)parseChunk:(NSError **)error
{
    int wordLength = [self countWordLength];
    const char *const p = ptr + pos;
    [self skipSpaces];
    if (wordLength == 0) {
        GLMQSetGLMQErrorAndReturnNo(kGLMQParseError, error);
    }
    else if (*p == '}') {
        /*
         if (chunk == kGLMQObjectChunk) {
         }
         */
        if (chunk == kGLMQSceneChunk ||
            chunk == kGLMQMaterialChunk ||
            chunk == kGLMQObjectChunk)
            chunk = kGLMQRootChunk;
        else {
            GLMQSetGLMQErrorAndReturnNo(kGLMQInvalidNestError, error);
        }
    }
    else if (chunk == kGLMQRootChunk) {
        if (wordLength == 3 && memcmp(p, "Eof", 3) == 0) {
            ptr += 3;
        }
        else if (wordLength == 5 && memcmp(p, "Scene", 5) == 0) {
            chunk = kGLMQSceneChunk;
        }
        else if (wordLength == 6 && memcmp(p, "Object", 6) == 0) {
            chunk = kGLMQObjectChunk;
            [self skipSpacesAfterForwarding:6];
            // skip object's name
            [self countWordLengthAndSkipSpaces];
            GLMQObject *object = [[GLMQObject alloc] init];
            if (model->objects == nil) {
                model->objects = [[NSMutableArray alloc] init];
                [(NSMutableArray *)model->objects addObject:object];
            }
            else {
                [(NSMutableArray *)model->objects addObject:object];
                ++model->objectIndex;
            }
            [object release];
            GLMQSetGLMQErrorAndReturnNoIf(model->objects == nil,
                                          kGLMQMemoryExhaustionError, error);
        }
        else if (wordLength == 8 && memcmp(p, "Material", 8) == 0) {
            int materialSize = 0;
            chunk = kGLMQMaterialChunk;
            [self skipSpacesAfterForwarding:8];
            [self skipSpacesAfterGettingInt:&materialSize];
            model->materials = [[NSMutableArray alloc] initWithCapacity:materialSize];
            GLMQSetGLMQErrorAndReturnNoIf(model->materials == nil,
                                          kGLMQMemoryExhaustionError, error);
            for (int i = 0; i < materialSize; i++) {
                GLMQMaterial *material = [[GLMQMaterial alloc] init];
                [(NSMutableArray *)model->materials addObject:material];
                [material release];
            }
        }
        else if (wordLength == 9 && memcmp(p, "BackImage", 9) == 0) {
            // Ignore
            while (*(ptr + pos) != '}')
                [self skipToNextLine];
        }
        else if (wordLength == 10 && memcmp(p, "IncludeXml", 10) == 0) {
            // Ignore
            [self skipToNextLine];
        }
    }
    else if (chunk == kGLMQSceneChunk) {
        if (![self parseSceneChunkWithWordLength:wordLength
                                           error:error])
            return NO;
    }
    else if (chunk == kGLMQMaterialChunk) {
        if (![self parseMaterialChunk:error])
            return NO;
    }
    else if (chunk == kGLMQObjectChunk) {
        if (![self parseObjectChunkWithWordLength:wordLength
                                            error:error])
            return NO;
    }
    else {
        GLMQSetGLMQErrorAndReturnNo(kGLMQUnknownChunkError, error);
    }
    return YES;
}

- (BOOL)loadFromFile:(NSString *)path
               error:(NSError **)error
{
    // load once, cannot any more
    if (s.type != kGLMQNotLoaded)
        return YES;
    int fd = open([path UTF8String], O_RDONLY);
    GLMQSetNSPOSIXErrorAndReturnNoIf(fd == -1, error);
    struct stat st;
    GLMQSetNSPOSIXErrorAndReturnNoIf(fstat(fd, &st) == -1, error);
    length = st.st_size;
    ptr = (const char *)mmap(NULL, (size_t)length, PROT_READ, MAP_PRIVATE, fd, 0);
    GLMQSetNSPOSIXErrorAndReturnNoIf(ptr == MAP_FAILED, error);
    // to load textures
    dir = [path stringByDeletingLastPathComponent];
    s.type = kGLMQLoadFromFile;
    s.u.fd = fd;
    return YES;
}

- (void)loadFromData:(NSData *)data
{
    if (s.type != kGLMQNotLoaded)
        return;
    length = [data length];
    ptr = (const char *)[data bytes];
    dir = nil;
    s.type = kGLMQLoadFromMemory;
    s.u.data = [data retain];
}

- (BOOL)parse:(NSError **)error
{
    // parse once, cannot any more
    if (s.type == kGLMQNotLoaded || version > 0)
        return YES;
    // strlen("Metasequoia Document") => 20
    // strlen("\r\n") => 2
    if ((model = calloc(1, sizeof(GLMQModel))) != NULL) {
        if (length >= 45 && memcmp(ptr, "Metasequoia Document", 20) == 0) {
            pos += 20;
            [self skipToNextLine];
            // strlen("Format Text Ver 1.0") => 19
            // strlen("\r\n") * 2 => 4
            if ([self skipSpacesAfterComparingWord:"Format"] &&
                [self skipSpacesAfterComparingWord:"Text"] &&
                [self skipSpacesAfterComparingWord:"Ver"]) {
                GLMQGetFloat(&version, ptr + pos, [self countWordLength]);
                [self skipToNextLine];
                [self skipToNextLine];
                model->scene = [[GLMQScene alloc] init];
                while (pos < length) {
                    if (![self parseChunk:error])
                        return NO;
                    [self skipToNextLine];
                }
                return YES;
            }
        }
        GLMQSetGLMQErrorAndReturnNo(kGLMQInvalidHeaderError, error);
        if (error)
            *error = [NSError errorWithDomain:GLMQErrorDomain
                                         code:kGLMQInvalidHeaderError
                                     userInfo:nil];
    }
    else {
        GLMQSetGLMQErrorAndReturnNo(kGLMQMemoryExhaustionError, error);
    }
    return NO;
}

- (GLfloat)version
{
    return version;
}

@end
