/*
 The MIT License
 
 Copyright (c) 2009 hkrn
 Copyright (c) 2009 Sunao Hashimoto and Keisuke Konishi
 
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
//  GLMQDocument+Renderer.m
//  MQOReader
//
//  Created by hkrn on 09/07/13.
//  Copyright 2009 hkrn. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

#import "GLMQDocument+Renderer.h"
#import "GLMQDocument+Private.h"
#import "GLMQMaterial.h"
#import "GLMQMaterial+Private.h"
#import "GLMQObject.h"
#import "GLMQObject+Private.h"

@implementation GLMQDocument (Render)


typedef struct GLMQTGAImage GLMQTGAImage;
struct GLMQTGAImage {
    GLubyte *data;
    int bitsPerPixel;
    int width;
    int height;
    int size;
};

//
// based on http://wiki.livedoor.jp/mikk_ni3_92/d/TGA%B2%E8%C1%FC%C6%C9%A4%DF%B9%FE%A4%DF
//
static BOOL GLMQLoadTGAFromFile(NSDictionary *images,
                                NSString *texturePath,
                                GLMQTGAImage *tgaImage,
                                NSError **error)
{
    GLubyte tgaField[12];
    GLubyte tgaHeader[6];
    NSData *data = [images objectForKey:texturePath];
    NSUInteger location = 0;
    [data getBytes:tgaField
             range:NSMakeRange(location, sizeof(tgaField))];
    if (tgaField[2] != 2 && tgaField[2] != 3) {
        GLMQSetGLMQErrorAndReturnNo(kGLMQInvalidTextureDataError, error);
    }
    location += sizeof(tgaField);
    [data getBytes:tgaHeader
             range:NSMakeRange(location, sizeof(tgaHeader))];
    int width = (tgaHeader[1] << 8) + tgaHeader[0];
    int height = (tgaHeader[3] << 8) + tgaHeader[2];
    int bytesPerPixel = tgaHeader[4];
    if (width <= 0 || height <= 0 || bytesPerPixel != tgaImage->bitsPerPixel) {
        GLMQSetGLMQErrorAndReturnNo(kGLMQInvalidTextureDataError, error);
    }
    location += sizeof(tgaHeader);
    bytesPerPixel >>= 3;
    int tgaImageSize = width * height * bytesPerPixel;
    GLubyte *tgaImageData = (GLubyte *)malloc(tgaImageSize);
    if (tgaImageData == NULL) {
        GLMQSetGLMQErrorAndReturnNo(kGLMQMemoryExhaustionError, error);
    }
    [data getBytes:tgaImageData
             range:NSMakeRange(location, tgaImageSize)];
    if (bytesPerPixel > 2) {
        for (int i = 0; i < tgaImageSize; i += bytesPerPixel) {
            GLuint temp = tgaImageData[i];                                             
            tgaImageData[i] = tgaImageData[i + 2];
            tgaImageData[i + 2] = temp;
        }
    }
    tgaImage->width = width;
    tgaImage->height = height;
    tgaImage->data = tgaImageData;
    tgaImage->size = tgaImageSize;
    return YES;
}

#define kBytesPerPixel 4

static GLubyte *GetBitmapDataFromCGImage(CGImageRef image)
{
	size_t width = CGImageGetWidth(image);
	size_t height = CGImageGetHeight(image);
	GLubyte *buffer = (GLubyte *)malloc(width * height * kBytesPerPixel);
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(buffer, width, height, 8, width * kBytesPerPixel,
                                                 colorSpace, kCGImageAlphaPremultipliedLast);
	CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
	CGContextRelease(context);
	CGColorSpaceRelease(colorSpace);
	return buffer;
}

static CGImageRef CreateCGImageFromBitmap(GLubyte *bitmap, size_t width, size_t height)
{
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	size_t totalBytes = width * height * kBytesPerPixel;
	CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, bitmap, totalBytes, NULL);
	CGImageRef result = CGImageCreate(width, height, 8, 8 * kBytesPerPixel, width * kBytesPerPixel,
                                      colorSpace, kCGImageAlphaLast, provider, NULL, 0, 
									  kCGRenderingIntentDefault);
	CGDataProviderRelease(provider);
	CGColorSpaceRelease(colorSpace);
	return result;
}

static BOOL GLMQLoadTexturesFromPath(NSDictionary *images,
                                     NSString *texturePath,
                                     NSString *alphaTexturePath,
                                     GLMQMaterial *material,
                                     NSError **error)
{
    GLMQTGAImage tgaImage;
    CGImageRef imageRef = NULL;
    tgaImage.data = NULL;
    if ([[texturePath pathExtension] isEqualToString:@"tga"]) {
        // Loading the TGA file should be 32bit image with full index color
        tgaImage.bitsPerPixel = 32;
        if (!GLMQLoadTGAFromFile(images, texturePath, &tgaImage, error))
            return NO;
        imageRef = CreateCGImageFromBitmap(tgaImage.data, tgaImage.width, tgaImage.height);
    }
    else {
        NSData *data = [images objectForKey:texturePath];
#if TARGET_OS_IPHONE
        UIImage *image = [[UIImage alloc] initWithData:data];
        imageRef = CGImageRetain([image CGImage]);
#else
        NSImage *image = [[NSImage alloc] initWithData:data];
        NSBitmapImageRep *bitmapImage = [[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];
        imageRef = CGImageRetain([bitmapImage CGImage]);
        [bitmapImage release];
#endif
        [image release];
    }
    NSInteger width = CGImageGetWidth(imageRef);
    NSInteger height = CGImageGetHeight(imageRef);
    if (width != height) {
        CGImageRelease(imageRef);
        GLMQSetGLMQErrorAndReturnNo(kGLMQInvalidTextureSizeError, error);
    }
    CGImageAlphaInfo info = CGImageGetAlphaInfo(imageRef);
    GLubyte *destPixels = NULL;
    size_t bitsPerPixel = CGImageGetBitsPerPixel(imageRef);
    BOOL hasAlpha = ((info == kCGImageAlphaPremultipliedLast) ||
                     (info == kCGImageAlphaPremultipliedFirst) ||
                     (info == kCGImageAlphaLast) ||
                     (info == kCGImageAlphaFirst) ? YES : NO);
    // Loading the TGA file should be 8bit mono chrome color
    if (!hasAlpha && bitsPerPixel == 24 &&
        [[alphaTexturePath pathExtension] isEqualToString:@"tga"]) {
        tgaImage.bitsPerPixel = 8;
        free(tgaImage.data);
        if (!GLMQLoadTGAFromFile(images, alphaTexturePath, &tgaImage, error)) {
            CGImageRelease(imageRef);
            return NO;
        }
        // RGB 24bit to RGBA 32bit
        GLubyte *sourcePixels = GetBitmapDataFromCGImage(imageRef);
        destPixels = (GLubyte *)malloc(width * height * sizeof(int));
        if (destPixels == NULL) {
            CGImageRelease(imageRef);
            free(sourcePixels);
            free(tgaImage.data);
            GLMQSetGLMQErrorAndReturnNo(kGLMQMemoryExhaustionError, error);
        }
        int i = 0, offset = tgaImage.size - 1;
        while (i < tgaImage.size) {
            int di = (i << 2), si = i * kBytesPerPixel;
            destPixels[di + 0] = sourcePixels[si];
            destPixels[di + 1] = sourcePixels[si + 1];
            destPixels[di + 2] = sourcePixels[si + 2];
            destPixels[di + 3] = tgaImage.data[offset - (((i / height) * width) + (width - (i % height) - 1))];
            ++i;
        }
        free(sourcePixels);
        free(tgaImage.data);
        tgaImage.data = NULL;
        CGImageRelease(imageRef);
        imageRef = CreateCGImageFromBitmap(destPixels, width, height);
    }
    GLubyte *bitmapData = GetBitmapDataFromCGImage(imageRef);
    glPixelStorei(GL_PACK_ALIGNMENT, kBytesPerPixel);
    glPixelStorei(GL_UNPACK_ALIGNMENT, kBytesPerPixel);
    glGenTextures(1, &material->textureName);
    glBindTexture(GL_TEXTURE_2D, material->textureName);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height,
                 0, GL_RGBA, GL_UNSIGNED_BYTE, bitmapData);
    glBindTexture(GL_TEXTURE_2D, 0);
    CGImageRelease(imageRef);
    free(tgaImage.data);
    free(destPixels);
    free(bitmapData);
    return YES;
}

#undef kBytesPerPixel

static void GLMQNormalizeVector(GLMQVector *normalized,
                                const GLMQVector const a,
                                const GLMQVector const b,
                                const GLMQVector const c)
{
    GLMQVector v0, v1;
    v0.x = a.x - b.x;
    v0.y = a.y - b.y;
    v0.z = a.z - b.z;
    v1.x = c.x - b.x;
    v1.y = c.y - b.y;
    v1.z = c.z - b.z;
    GLfloat x = v0.y * v1.z - v0.z * v1.y;
    GLfloat y = v0.z * v1.x - v0.x * v1.z;
    GLfloat z = v0.x * v1.y - v0.y * v1.x;
    double n = sqrt(x * x + y * y + z * z);
    if (n != 0) {
        normalized->x = (GLfloat)(x / n);
        normalized->y = (GLfloat)(y / n);
        normalized->z = (GLfloat)(z / n);
    }
}

static BOOL GLMQNormalizeVertexes(GLMQVector **normalizedVertexes,
                                  const GLMQObject *const object,
                                  NSError **error)
{
    int vertexSize = object->vertexSize;
    const GLMQVector *const vertexes = object->vertexes;
    GLMQVector vector, *p = calloc(sizeof(GLMQVector), vertexSize);
    GLMQSetNSPOSIXErrorAndReturnNoIf(p == NULL, error);
    int i = 0;
    for (int faceSize = object->faceSize; i < faceSize; i++) {
        const GLMQFace const face = object->faces[i];
        int a = face.vertexIndexes[0];
        int b = face.vertexIndexes[1];
        int c = face.vertexIndexes[2];
        int d = face.vertexIndexes[3];
        GLMQNormalizeVector(&vector, vertexes[a], vertexes[b], vertexes[c]);
        if (face.vertexIndexSize == 3) {
            for (int j = 0; j < 3; j++) {
                int v = face.vertexIndexes[j];
                p[v].x += vector.x;
                p[v].y += vector.y;
                p[v].z += vector.z;
            }
        }
        else if (face.vertexIndexSize == 4) {
            for (int j = 0; j < 4; j++) {
                if (j == 3)
                    continue;
                int v = face.vertexIndexes[j];
                p[v].x += vector.x;
                p[v].y += vector.y;
                p[v].z += vector.z;
            }
            GLMQNormalizeVector(&vector, vertexes[a], vertexes[c], vertexes[d]);
            for (int j = 0; j < 4; j++) {
                if (j == 1)
                    continue;
                int v = face.vertexIndexes[j];
                p[v].x += vector.x;
                p[v].y += vector.y;
                p[v].z += vector.z;
            }
        }
    }
    for (i = 0; i < vertexSize; i++) {
        GLMQVector *v = &p[i];
        if (v->x == 0 && v->y == 0 && v->z == 0)
            continue;
        double len = sqrt(v->x * v->x + v->y * v->y + v->z * v->z);
        if (len != 0) {
            v->x = (GLfloat)(v->x / len);
            v->y = (GLfloat)(v->y / len);
            v->z = (GLfloat)(v->z / len);
        }
    }
    *normalizedVertexes = p;
    return YES;
}

static void GLMQSetVertexTexture(GLMQVertexTexture *t,
                                 const GLMQPoint2D *const uv,
                                 const GLMQPoint3D *const point,
                                 const GLMQVector *const normalized,
                                 const GLMQVector *const norm,
                                 GLfloat facet)
{
    t->point.x = point->x;
    t->point.y = point->y;
    t->point.z = point->z;
    t->uv[0] = uv->x;
    t->uv[1] = uv->y;
    double s = acos(normalized->x * norm->x + normalized->y * norm->y + normalized->z * norm->z);
    if (facet < s) {
        t->normal.x = normalized->x;
        t->normal.y = normalized->y;
        t->normal.z = normalized->z;
    }
    else {
        t->normal.x = norm->x;
        t->normal.y = norm->y;
        t->normal.z = norm->z;
    }
}

static void GLMQSetVertexPolygon(GLMQVertexPolygon *p,
                                 const GLMQPoint3D *const point,
                                 const GLMQVector *const normalized,
                                 const GLMQVector *const norm,
                                 GLfloat facet)
{
    p->point.x = point->x;
    p->point.y = point->y;
    p->point.z = point->z;
    double s = acos(normalized->x * norm->x + normalized->y * norm->y + normalized->z * norm->z);
    if (facet < s) {
        p->normal.x = normalized->x;
        p->normal.y = normalized->y;
        p->normal.z = normalized->z;
    }
    else {
        p->normal.x = norm->x;
        p->normal.y = norm->y;
        p->normal.z = norm->z;
    }
}

#define GLMQInitAndSetVertexTexture(j) \
GLMQVertexTexture *t = &texture[dpos]; \
const GLMQPoint2D const uv = face.uv[(j)]; \
const GLMQPoint3D const point = vertexes[v[(j)]]; \
const GLMQVector const norm = normalizedVertexes[v[(j)]]; \
GLMQSetVertexTexture(t, &uv, &point, &normalized, &norm, facet); \
dpos++

#define GLMQInitAndSetVertexPolygon(j) \
GLMQVertexPolygon *p = &polygon[dpos]; \
const GLMQPoint3D const point = vertexes[v[(j)]]; \
const GLMQVector const norm = normalizedVertexes[v[(j)]]; \
GLMQSetVertexPolygon(p, &point, &normalized, &norm, facet); \
dpos++

+ (void)createVertexesFromMaterial:(GLMQVertexMaterial *)matVertex
                           atIndex:(int)materialIndex
                        hasTexture:(BOOL)hasTexture
                normalizedVertexes:(const GLMQPoint3D *)normalizedVertexes
                            object:(const GLMQObject *)object
{
    GLMQVector normalized;
    const GLMQPoint3D *const vertexes = object->vertexes;
    GLfloat facet = object->facet;
    int dpos = 0;
    if (hasTexture) {
        GLMQVertexTexture *texture = matVertex->texture;
        for (int i = 0, faceSize = object->faceSize; i < faceSize; i++) {
            const GLMQFace const face = object->faces[i];
            if (face.materialIndex != materialIndex)
                continue;
            const int *const v = face.vertexIndexes;
            GLMQNormalizeVector(&normalized, vertexes[v[0]], vertexes[v[1]], vertexes[v[2]]);
            if (face.vertexIndexSize == 3) {
                for (int j = 0; j < 3; j++) {
                    GLMQInitAndSetVertexTexture(j);
                }
            }
            else if (face.vertexIndexSize == 4) {
                for (int j = 0; j < 3; j++) {
                    GLMQInitAndSetVertexTexture(j);
                }
                GLMQNormalizeVector(&normalized, vertexes[v[0]], vertexes[v[2]], vertexes[v[3]]);
                for (int j = 0; j < 4; j++) {
                    if (j == 1)
                        continue;
                    GLMQInitAndSetVertexTexture(j);
                }
            }
        }
    }
    else {
        GLMQVertexPolygon *polygon = matVertex->polygon;
        for (int i = 0, faceSize = object->faceSize; i < faceSize; i++) {
            const GLMQFace const face = object->faces[i];
            if (face.materialIndex != materialIndex)
                continue;
            const int *const v = face.vertexIndexes;
            GLMQNormalizeVector(&normalized, vertexes[v[0]], vertexes[v[1]], vertexes[v[2]]);
            if (face.vertexIndexSize == 3) {
                for (int j = 0; j < 3; j++) {
                    GLMQInitAndSetVertexPolygon(j);
                }
            }
            else if (face.vertexIndexSize == 4) {
                for (int j = 0; j < 3; j++) {
                    GLMQInitAndSetVertexPolygon(j);
                }
                GLMQNormalizeVector(&normalized, vertexes[v[0]], vertexes[v[2]], vertexes[v[3]]);
                for (int j = 0; j < 4; j++) {
                    if (j == 1)
                        continue;
                    GLMQInitAndSetVertexPolygon(j);
                }
            }
        }
    }
}

#undef GLMQInitAndSetVertexTexture
#undef GLMQInitAndSetVertexPolygon

#define GLMQSetMinAndMaxVertex(j, vertex) \
const GLMQPoint3D const point = (vertex)[(j)].point; \
GLMQPoint3D min = object->minVertex, max = object->maxVertex; \
min.x = MIN(min.x, point.x); \
min.y = MIN(min.y, point.y); \
min.z = MIN(min.z, point.z); \
max.x = MAX(max.x, point.x); \
max.y = MAX(max.y, point.y); \
max.z = MAX(max.z, point.z); \
object->minVertex = min; \
object->maxVertex = max;

typedef struct GLMQIndexedPoint3D GLMQIndexedPoint3D;
struct GLMQIndexedPoint3D {
    GLMQPoint3D point;
    int index;
};

typedef struct GLMQEdgeHash GLMQEdgeHash;
struct GLMQEdgeHash {
    int face;
    int line;
    int vertex;
    GLMQEdgeHash *next;
};

- (BOOL)subdivideByCatmullClarkWithObject:(GLMQObject *)object
                                    error:(NSError **)error
{
    int faceSize = object->faceSize, vertexSize = object->vertexSize;
    GLMQIndexedPoint3D *q = calloc(sizeof(GLMQIndexedPoint3D), faceSize);
    GLMQSetNSPOSIXErrorAndReturnNoIf(q == NULL, error);
    GLMQIndexedPoint3D *r = calloc(sizeof(GLMQIndexedPoint3D), faceSize * 4);
    GLMQSetNSPOSIXErrorAndReturnNoIf(r == NULL, error);
    GLMQIndexedPoint3D *v = calloc(sizeof(GLMQIndexedPoint3D), vertexSize);
    GLMQSetNSPOSIXErrorAndReturnNoIf(v == NULL, error);
    GLMQEdgeHash **edge = calloc(sizeof(GLMQEdgeHash *), vertexSize);
    GLMQSetNSPOSIXErrorAndReturnNoIf(edge == NULL, error);
    for (int i = 0; i < faceSize; i++) {
        const GLMQFace face = object->faces[i];
        int faceVertexIndexSize = face.vertexIndexSize;
        for (int j = 0; j < faceVertexIndexSize; j++) {
            int v1 = face.vertexIndexes[j];
            int v2 = face.vertexIndexes[(j + 1) % faceVertexIndexSize];
            GLMQEdgeHash *hash = calloc(sizeof(GLMQEdgeHash), 1);
            hash->face = i;
            hash->line = j;
            hash->vertex = v2;
            if (edge[v1] == NULL)
                edge[v1] = hash;
            else {
                GLMQEdgeHash **e = &edge[v1];
                while (*e != NULL)
                    *e = (*e)->next;
                *e = hash;
            }
            hash = calloc(sizeof(GLMQEdgeHash), 1);
            hash->face = i;
            hash->line = j;
            hash->vertex = v1;
            if (edge[v2] == NULL)
                edge[v2] = hash;
            else {
                GLMQEdgeHash **e = &edge[v1];
                while (*e != NULL)
                    *e = (*e)->next;
                *e = hash;
            }
        }
    }
    for (int i = 0; i < faceSize; i++) {
        const GLMQFace face = object->faces[i];
        GLMQIndexedPoint3D *qv = &q[i];
        GLMQPoint3D *qvp = &qv->point;
        int faceVertexIndexSize = face.vertexIndexSize;
        for (int j = 0; j < faceVertexIndexSize; j++) {
            int vertexIndex = face.vertexIndexes[j];
            const GLMQPoint3D vertex = object->vertexes[vertexIndex];
            qvp->x += vertex.x;
            qvp->y += vertex.y;
            qvp->z += vertex.z;
        }
        qvp->x /= (GLfloat)faceSize;
        qvp->y /= (GLfloat)faceSize;
        qvp->z /= (GLfloat)faceSize;
        qv->index = 1;
    }
    for (int i = 0; i < faceSize; i++) {
        GLMQFace face = object->faces[i];
        int faceVertexIndexSize = face.vertexIndexSize;
        for (int j = 0; j < faceVertexIndexSize; j++) {
            int v1 = face.vertexIndexes[j];
            int v2 = face.vertexIndexes[(j + 1) % faceVertexIndexSize];
            const GLMQEdgeHash *hash = edge[v2];
            GLMQIndexedPoint3D *rv = &r[i * j];
            while (hash != NULL) {
                if (hash->vertex == v1 && hash->face != i) {
                    GLMQPoint3D vtx1 = object->vertexes[v1];
                    GLMQPoint3D vtx2 = object->vertexes[v2];
                    GLMQPoint3D vtx3 = q[i].point;
                    GLMQPoint3D vtx4 = q[hash->face].point;
                    GLMQPoint3D *rvp = &rv->point;
                    rvp->x = (vtx1.x + vtx2.x + vtx3.x + vtx4.x) / 4;
                    rvp->y = (vtx1.y + vtx2.y + vtx3.y + vtx4.y) / 4;
                    rvp->z = (vtx1.z + vtx2.z + vtx3.z + vtx4.z) / 4;
                    break;
                }
                hash = hash->next;
            }
            if (hash == NULL) {
                GLMQPoint3D vtx1 = object->vertexes[v1];
                GLMQPoint3D vtx2 = object->vertexes[v2];
                GLMQIndexedPoint3D *vv1 = &v[v1];
                GLMQIndexedPoint3D *vv2 = &v[v2];
                GLMQPoint3D *vvp1 = &vv1->point;
                GLMQPoint3D *vvp2 = &vv2->point;
                GLMQPoint3D *rvp = &rv->point;
                vvp1->x = vtx1.x;
                vvp1->y = vtx1.y;
                vvp1->z = vtx1.z;
                vvp2->x = vtx2.x;
                vvp2->y = vtx2.y;
                vvp2->z = vtx2.z;
                vv1->index = -1;
                vv2->index = -1;
                rvp->x = (vtx1.x + vtx2.x) / 2;
                rvp->y = (vtx1.y + vtx2.y) / 2;
                rvp->z = (vtx1.z + vtx2.z) / 2;
            }
            rv->index = -1;
        }
    }
    for (int i = 0; i < vertexSize; i++) {
        if (v[i].index == -1)
            continue;
        GLMQEdgeHash *hash = edge[i];
        int count = 0;
        while (hash != NULL) {
            GLMQEdgeHash *hash2 = edge[i];
            while (hash2 != NULL) {
                if (hash->face == hash2->face)
                    break;
                hash2 = hash2->next;
            }
            if (hash2 == hash) {
                const GLMQPoint3D qvp = q[hash->face].point;
                GLMQPoint3D *vp = &v[i].point;
                vp->x += qvp.x;
                vp->y += qvp.y;
                vp->z += qvp.z;
                count++;
            }
            for (hash2 = edge[i]; hash2 != hash; hash2 = hash2->next) {
                if (hash->vertex == hash2->vertex)
                    break;
            }
            if (hash2 == hash) {
                const GLMQPoint3D vv = object->vertexes[hash->vertex];
                GLMQPoint3D *vp = &v[i].point;
                vp->x += vv.x;
                vp->y += vv.y;
                vp->z += vv.z;
            }
            hash = hash->next;
        }
        if (count > 0) {
            const GLMQPoint3D vv = object->vertexes[hash->vertex];
            GLMQPoint3D *vp = &v[i].point;
            vp->x /= (GLfloat)count;
            vp->y /= (GLfloat)count;
            vp->z /= (GLfloat)count;
            vp->x /= (GLfloat)((count - 2) * vv.x);
            vp->y /= (GLfloat)((count - 2) * vv.y);
            vp->z /= (GLfloat)((count - 2) * vv.z);
            vp->x /= (GLfloat)count;
            vp->y /= (GLfloat)count;
            vp->z /= (GLfloat)count;
        }
    }
    // TODO 新しい頂点の登録
    for (int i = 0; i < vertexSize; i++) {
        GLMQEdgeHash *e = edge[i];
        if (e != NULL) {
            GLMQEdgeHash *nextEdge = NULL;
            while (e != NULL) {
                nextEdge = e->next;
                free(e);
                e = nextEdge;
            }
            free(e);
            e = NULL;
        }
    }
    free(edge);
    free(q);
    free(r);
    free(v);
    edge = NULL;
    q = NULL;
    r = NULL;
    v = NULL;
    return YES;
}

- (BOOL)createObject:(GLMQObject *)object
               error:(NSError **)error
{
    int i = 0;
    int materialSize = (int)[model->materials count];
    int *materialVertexes = calloc(sizeof(int), materialSize);
    GLMQSetNSPOSIXErrorAndReturnNoIf(materialVertexes == NULL, error);
    GLMQVector *normalizedVertexes = NULL;
    if (!GLMQNormalizeVertexes(&normalizedVertexes, object, error))
        return NO;
    for (int faceSize = object->faceSize; i < faceSize; i++) {
        const GLMQFace face = object->faces[i];
        int materialIndex = face.materialIndex;
        if (materialIndex < 0 || materialIndex > materialSize)
            continue;
        if (face.vertexIndexSize == 3)
            materialVertexes[materialIndex] += 3;
        else if (face.vertexIndexSize == 4)
            materialVertexes[materialIndex] += 6;
    }
    object->materialVertexes = calloc(materialSize, sizeof(GLMQVertexMaterial));
    if (object->materialVertexes == NULL) {
        free(materialVertexes);
        free(normalizedVertexes);
        GLMQSetNSPOSIXErrorAndReturnNo(error);
    }
    for (i = 0; i < materialSize; i++) {
        GLMQMaterial *material = [model->materials objectAtIndex:i];
        GLMQVertexMaterial *matVertex = &object->materialVertexes[i];
        int vertexCount = materialVertexes[i];
        if (vertexCount <= 0)
            continue;
        matVertex->vertexCount = vertexCount;
        BOOL hasTexture = material->texturePath[0] != '\0';
        if (hasTexture) {
            matVertex->texture = calloc(vertexCount, sizeof(GLMQVertexTexture));
            if (matVertex->texture == NULL) {
                free(materialVertexes);
                free(normalizedVertexes);
                GLMQSetNSPOSIXErrorAndReturnNo(error);
            }
            if (material->textureName == 0) {
                NSString *texturePath = [NSString  stringWithUTF8String:material->texturePath];
                NSString *alphaTexturePath = [NSString stringWithUTF8String:material->alphaTexturePath];
                if (!GLMQLoadTexturesFromPath(images, texturePath, alphaTexturePath, material, error))
                    return NO;
            }
        }
        else {
            matVertex->polygon = calloc(vertexCount, sizeof(GLMQVertexPolygon));
            if (matVertex->polygon == NULL) {
                free(materialVertexes);
                free(normalizedVertexes);
                GLMQSetNSPOSIXErrorAndReturnNo(error);
            }
        }
        [[self class] createVertexesFromMaterial:matVertex
                                         atIndex:i
                                      hasTexture:hasTexture
                              normalizedVertexes:normalizedVertexes
                                          object:object];
        if (hasTexture) {
            GLMQVertexTexture texture;
            if (i == 0) {
                texture = matVertex->texture[0];
                object->minVertex = texture.point;
                object->maxVertex = texture.point;
            }
            for (int j = 0; j < vertexCount; j++) {
                GLMQSetMinAndMaxVertex(j, matVertex->texture);
            }
        }
        else {
            GLMQVertexPolygon polygon;
            if (i == 0) {
                polygon = matVertex->polygon[0];
                object->minVertex = polygon.point;
                object->maxVertex = polygon.point;
            }
            for (int j = 0; j < vertexCount; j++) {
                GLMQSetMinAndMaxVertex(j, matVertex->polygon);
            }
        }
#if GL_ARB_vertex_buffer_object
        glGenBuffersARB(1, &matVertex->vboName);
        glBindBufferARB(GL_ARRAY_BUFFER_ARB, matVertex->vboName);
        if (hasTexture)
            glBufferDataARB(GL_ARRAY_BUFFER_ARB,
                            vertexCount * sizeof(GLMQVertexTexture),
                            matVertex->texture, GL_STATIC_DRAW_ARB);
        else
            glBufferDataARB(GL_ARRAY_BUFFER_ARB,
                            vertexCount * sizeof(GLMQVertexPolygon),
                            matVertex->polygon, GL_STATIC_DRAW_ARB);
#else
        matVertex->vboName = 0;
#endif
    }
    free(materialVertexes);
    free(normalizedVertexes);
    materialVertexes = NULL;
    normalizedVertexes = NULL;
    return YES;
}

#undef GLMQSetMinAndMaxVertex

#if 0
- (void)writeToFile:(const NSString *)path
{
    FILE *fp = fopen([path UTF8String], "w");
    for (int i = 0; i < (int)[model->objects count]; i++) {
        const GLMQObjectClassStruct *const object = (const GLMQObjectClassStruct *const)[model->objects objectAtIndex:i];
        if (object->faces == NULL || object->vertexes == NULL)
            continue;
        if (object->materialVertexes != NULL) {
            for (int j = 0; j < (int)[model->materials count]; j++) {
                const GLMQMaterialClassStruct *const material = (const GLMQMaterialClassStruct *const)[model->materials objectAtIndex:j];
                const GLMQVertexMaterial *const matVertex = object->materialVertexes[j];
                BOOL hasTexture = material->textureName > 0;
                for (int k = 0; k < matVertex.vertexCount; k++) {
                    if (hasTexture) {
                        const GLMQVertexTexture t = matVertex.texture[k];
                        fprintf(fp, "%d:%d:%d point { x:%.3f, y:%.3f, z:%.3f }\n"
                                "%d:%d:%d uv { %.3f, %.3f }\n"
                                "%d:%d:%d normal { x:%.3f, y:%.3f, z:%.3f }\n",
                                i, j, k, t.point.x, t.point.y, t.point.z,
                                i, j, k, t.uv[0], t.uv[1],
                                i, j, k, t.normal.x, t.normal.y, t.normal.z
                                );
                    }
                    else {
                        const GLMQVertexPolygon t = matVertex.polygon[k];
                        fprintf(fp, "%d:%d:%d point { x:%.3f, y:%.3f, z:%.3f }\n"
                                "%d:%d:%d normal { x:%.3f, y:%.3f, z:%.3f };\n",
                                i, j, k, t.point.x, t.point.y, t.point.z,
                                i, j, k, t.normal.x, t.normal.y, t.normal.z
                                );
                    }
                }
            }
        }
    }
    fclose(fp);
}
#endif

- (BOOL)createModel:(NSError **)error
{
    for (int i = 0, size = (int)[model->objects count]; i < size; i++) {
        GLMQObject *object = [model->objects objectAtIndex:i];
        if (object->faces == NULL || object->vertexes == NULL)
            continue;
        if (![self createObject:object
                     error:error])
            return NO;
        GLMQPoint3D *modelMin = &model->minVertex, *modelMax = &model->maxVertex;
        const GLMQPoint3D const objectMin = object->minVertex, objectMax = object->maxVertex;
        if (i == 0) {
            modelMin->x = objectMin.x;
            modelMin->y = objectMin.y;
            modelMin->z = objectMin.z;
            modelMax->x = objectMin.x;
            modelMax->y = objectMax.y;
            modelMax->z = objectMax.z;
        }
        else {
            modelMin->x = MIN(modelMin->x, objectMin.x);
            modelMin->y = MIN(modelMin->y, objectMin.y);
            modelMin->z = MIN(modelMin->z, objectMin.z);
            modelMax->x = MAX(modelMax->x, objectMin.x);
            modelMax->y = MAX(modelMax->y, objectMax.y);
            modelMax->z = MAX(modelMax->z, objectMax.z);
        }
    }
    return YES;
}

static void RenderMaterials(const NSArray *materials,
                            const GLMQObject *object,
                            NSUInteger materialSize)
{
    const void *base = NULL;
    GLfloat environment[4];
    NSInteger offset = 0;
    for (NSUInteger i = 0; i < materialSize; i++) {
        const GLMQMaterial *const material = [materials objectAtIndex:i];
        const GLMQVertexMaterial const matVertex = object->materialVertexes[i];
        if (matVertex.vertexCount <= 0)
            continue;
        memcpy(environment, material->diffuse, sizeof(environment));
        glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, environment);
        memcpy(environment, material->ambient, sizeof(environment));
        glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, environment);
        memcpy(environment, material->specular, sizeof(environment));
        glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, environment);
        memcpy(environment, material->emission, sizeof(environment));
        glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, environment);
        glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, material->power);
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glEnableClientState(GL_VERTEX_ARRAY);
        glEnableClientState(GL_NORMAL_ARRAY);
        if (material->textureName != 0) {
            glEnableClientState(GL_TEXTURE_COORD_ARRAY);
            glEnable(GL_TEXTURE_2D);
            glBindTexture(GL_TEXTURE_2D, material->textureName);
            const GLMQVertexTexture const *firstVertex = &matVertex.texture[0];
#if GL_ARB_vertex_buffer_object
            base = (const void *const)NULL;
            glBindBufferARB(GL_ARRAY_BUFFER_ARB, matVertex.vboName);
#else
            base = (const void *)matVertex.texture;
#endif
            offset = (const void *const)&firstVertex->point - (const void *const)firstVertex;
            glVertexPointer(3, GL_FLOAT, (GLsizei)sizeof(GLMQVertexTexture), base + offset);
            offset = (const void *const)&firstVertex->uv - (const void *const)firstVertex;
            glTexCoordPointer(2, GL_FLOAT, (GLsizei)sizeof(GLMQVertexTexture), base + offset);
            offset = (const void *const)&firstVertex->normal - (const void *const)firstVertex;
            glNormalPointer(GL_FLOAT, (GLsizei)sizeof(GLMQVertexTexture), base + offset);
            glColor4f(material->color[0], material->color[1], material->color[2], material->color[3]);
            glDrawArrays(GL_TRIANGLES, 0, matVertex.vertexCount);
            glBindTexture(GL_TEXTURE_2D, 0);
            glDisable(GL_TEXTURE_2D);
            glDisableClientState(GL_TEXTURE_COORD_ARRAY);
        }
        else {
            glDisable(GL_TEXTURE_2D);
            const GLMQVertexPolygon const *firstVertex = &matVertex.polygon[0];
#if GL_ARB_vertex_buffer_object
            base = (const void *const)NULL;
            glBindBufferARB(GL_ARRAY_BUFFER_ARB, matVertex.vboName);
#else
            base = (const void *)matVertex.polygon;
#endif
            offset = (const void *const)&firstVertex->point - (const void *const)firstVertex;
            glVertexPointer(3, GL_FLOAT, (GLsizei)sizeof(GLMQVertexPolygon), base + offset);
            offset = (const void *const)&firstVertex->normal - (const void *const)firstVertex;
            glNormalPointer(GL_FLOAT, (GLsizei)sizeof(GLMQVertexPolygon), base + offset);
            glColor4f(material->color[0], material->color[1], material->color[2], material->color[3]);
            glDrawArrays(GL_TRIANGLES, 0, matVertex.vertexCount);
        }
#if GL_ARB_vertex_buffer_object
        glBindBufferARB(GL_ARRAY_BUFFER_ARB, 0);
#endif
        glDisableClientState(GL_VERTEX_ARRAY);
        glDisableClientState(GL_NORMAL_ARRAY);
    }
}

- (void)render
{
    const NSArray *objects = model->objects, *materials = model->materials;
    NSUInteger objectSize = [objects count], materialSize = [materials count];
    for (NSUInteger i = 0; i < objectSize; i++) {
        const GLMQObject *const object = [objects objectAtIndex:i];
        if (object->faces == NULL ||
            object->vertexes == NULL ||
            object->materialVertexes == NULL ||
            !object->visible)
            continue;
        glShadeModel(object->shading ? GL_SMOOTH : GL_FLAT);
        glPushMatrix();
        /*
        const GLfloat *tr = object->translation;
        if (tr[0] > 0 || tr[1] > 0 || tr[2] > 0)
            glTranslatef(tr[0], tr[1], tr[2]);
        const GLfloat *rot = object->rotation;
        if (rot[0] > 0 || rot[1] > 0 || rot[2] > 0)
            glRotatef(0.0f, rot[0], rot[1], rot[2]);
        const GLfloat *scale = object->scale;
        if (scale[0] > 0 || scale[1] > 0 || scale[2] > 0)
            glScalef(scale[0], scale[1], scale[2]);
         */
        RenderMaterials(materials, object, materialSize);
        glPopMatrix();
        if (object->mirror > 0) {
            glPushMatrix();
            switch (object->mirrorAxis) {
                case 1:
                default:
                    glCullFace(GL_FRONT);
                    glScalef(-1.0f, 1.0f, 1.0f);
                    break;
                case 2:
                    glScalef(1.0f, -1.0f, 1.0f);
                    break;
                case 4:
                    glScalef(1.0f, 1.0f, -1.0f);
                    break;
            }
            glTranslatef(0.0f, 0.0f, 0.0f);
            RenderMaterials(materials, object, materialSize);
            glCullFace(GL_BACK);
            glPopMatrix();
        }
    }
}

@end
