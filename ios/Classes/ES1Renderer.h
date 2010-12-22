//
//  ES1Renderer.h
//  MQMobile
//
//  Created by hkrn on 09/09/23.
//  Copyright hkrn 2009. All rights reserved.
//

#import "ESRenderer.h"
#import "GLMQ.h"

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

@interface ES1Renderer : NSObject <ESRenderer>
{
@private
	EAGLContext *context;
	
	// The pixel dimensions of the CAEAGLLayer
	GLint backingWidth;
	GLint backingHeight;
	
	// The OpenGL names for the framebuffer and renderbuffer used to render to this view
	GLuint defaultFramebuffer;
    GLuint colorRenderbuffer;
    GLuint depthRenderbuffer;

    GLMQDocument *document;
    NSMutableData *downloaded;
    BOOL canRender;
    
    CGPoint modelAngle;
    GLfloat modelScale;
}

@end
