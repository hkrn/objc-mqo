//
//  ESRenderer.h
//  MQMobile
//
//  Created by hkrn on 09/09/23.
//  Copyright hkrn 2009. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>

@protocol ESRenderer <NSObject>

- (void) loadModelFromURL;
- (void) render;
- (BOOL) resizeFromLayer:(CAEAGLLayer *)layer;
- (void) updateAngle:(CGPoint)angle;
- (void) updateScale:(CGFloat)scale;

@end
