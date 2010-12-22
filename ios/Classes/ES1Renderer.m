//
//  ES1Renderer.m
//  MQMobile
//
//  Created by hkrn on 09/09/23.
//  Copyright hkrn 2009. All rights reserved.
//

#import "ES1Renderer.h"

@implementation ES1Renderer

// The base URL to the .mqo file and other resources
static NSString *g_baseurl = @"http://example.com/foo/bar";

// The filename of the .mqo file
static NSString *g_filename = @"baz";

// Timeout interval
static NSTimeInterval g_timeout = 30.0;

// Create an ES 1.1 context
- (id)init
{
	if (self = [super init]) {
		context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
        if (!context || ![EAGLContext setCurrentContext:context]) {
            [self release];
            return nil;
        }
		// Create default framebuffer object. The backing will be allocated for the current layer in -resizeFromLayer
		glGenFramebuffersOES(1, &defaultFramebuffer);
		glGenRenderbuffersOES(1, &colorRenderbuffer);
		glBindFramebufferOES(GL_FRAMEBUFFER_OES, defaultFramebuffer);
		glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
		glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, colorRenderbuffer);
        document = [[GLMQDocument alloc] init];
        downloaded = [[NSMutableData alloc] init];
        canRender = NO;
        modelAngle = CGPointZero;
        modelScale = 1;
	}
	return self;
}

- (void)setupView
{
    glViewport(0, 0, backingWidth, backingHeight);
    glLoadIdentity();
    glMatrixMode(GL_PROJECTION);
    //GLMQScene *scene = document.scene;
    //const GLfloat *position = scene.position;
    GLfloat fovy = 50.0f;
	GLfloat znear = 10.0f; //scene.zoom2;
	GLfloat zfar = 10000.0f; //position[2];
    GLfloat aspect = (GLfloat)backingWidth / backingHeight;
    GLfloat scale = znear * tanf(fovy * 0.5f * (float)M_PI / 180.0f);
    GLfloat x = backingWidth * scale * aspect / backingWidth;
    GLfloat y = backingHeight * scale / backingHeight;
    //glOrtho(-x, x, -y, y, znear, zfar);
    glFrustumf(-x, x, -y, y, znear, zfar);
	GLfloat lightAmbient[4] = { 0.5f, 0.5f, 0.5f, 1.0f };
    //const GLfloat *ambient = mqo.scene.ambient;
    //memcpy(lightAmbient, ambient, sizeof(GLfloat) * 3);
	glLightfv(GL_LIGHT0, GL_AMBIENT,  lightAmbient);
    glFrontFace(GL_CW);
    glCullFace(GL_BACK);
    glEnable(GL_LIGHT0);
    glEnable(GL_CULL_FACE);
    glEnable(GL_LIGHTING);
    glEnable(GL_DEPTH_TEST);
}

- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer
{	
	// Allocate color buffer backing based on the current layer size
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
    [context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:layer];
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
    glGenRenderbuffersOES(1, &depthRenderbuffer);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthRenderbuffer);
    glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, backingWidth, backingHeight);
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, depthRenderbuffer);
    if (glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
		NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
        return NO;
    }
    return YES;
}

- (void)updateAngle:(CGPoint)angle
{
    modelAngle.x += angle.y;
    modelAngle.y += angle.x;
}

- (void)updateScale:(CGFloat)scale
{
    modelScale += scale;
    modelScale = MAX(modelScale, 0.1);
}

- (void)build3DModelWithLoadingImage:(SEL)loadingImage
{
    NSError *error = nil;
    if (![document parse:&error]) {
        NSString *message = [NSString stringWithFormat:@"%@: %d", [error domain], [error code]];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Parsing error"
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
        return;
    }
    for (NSString *key in document.keysForImage) {
        NSData *data = [self performSelector:loadingImage
                                  withObject:key];
        [document setImageData:data
                        forKey:key];
    }
    [self setupView];
    if (![document createModel:&error]) {
        NSString *message = [NSString stringWithFormat:@"%@: %d", [error domain], [error code]];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Creating model error"
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
        return;
    }
    canRender = YES;
}

- (NSData *)loadImageFromResource:(NSString *)key
{
    NSString *location = [[NSString alloc] initWithFormat:@"%@/%@",
                          [[NSBundle mainBundle] resourcePath], key];
    NSData *data = [NSData dataWithContentsOfFile:location];
    [location release];
    return data;
}

- (void)loadModelFromURL
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@.mqo", g_baseurl, g_filename]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url
                                             cachePolicy:NSURLRequestUseProtocolCachePolicy
                                         timeoutInterval:g_timeout];
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:request
                                                                delegate:self];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [connection start];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [downloaded setLength:0];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
                                                    message:[error localizedRecoverySuggestion]
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
    NSString *path = [[NSString alloc] initWithFormat:@"%@/miku01.mqo", [[NSBundle mainBundle] resourcePath]];
    NSData *data = [[NSData alloc] initWithContentsOfFile:path];
    [path release];
    [document loadFromData:data];
    [data release];
    [self build3DModelWithLoadingImage:@selector(loadImageFromResource:)];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [downloaded setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [downloaded appendData:data];
}

- (NSData *)loadImageFromURL:(NSString *)key
{
    NSString *location = [[NSString alloc] initWithFormat:@"%@/%@", g_baseurl, key];
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:location]];
    [location release];
    return data;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [document loadFromData:downloaded];
    [self build3DModelWithLoadingImage:@selector(loadImageFromURL:)];
}

- (void)render
{
    [EAGLContext setCurrentContext:context];
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, defaultFramebuffer);
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
    if (canRender) {
        glMatrixMode(GL_MODELVIEW);
        //GLMQScene *scene = document.scene;
        //const GLfloat *lookAt = scene.lookAt;
        //const GLMQPoint3D *min = document.minVertex;
        //const GLMQPoint3D *max = document.maxVertex;
        glPushMatrix();
        glTranslatef(0.0f, -100.0f, -500.0f);
        //glTranslatef(0.0f, lookAt[1] * -1.0f, min->y - max->y);
        glRotatef(modelAngle.x, 1, 0, 0);
        glRotatef(modelAngle.y, 0, 1, 0);
        glScalef(modelScale, modelScale, modelScale);
        [document render];
        glPopMatrix();
    }
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER_OES];
}

- (void)dealloc
{
	// Tear down GL
	if (defaultFramebuffer) {
		glDeleteFramebuffersOES(1, &defaultFramebuffer);
		defaultFramebuffer = 0;
	}
	if (colorRenderbuffer) {
		glDeleteRenderbuffersOES(1, &colorRenderbuffer);
		colorRenderbuffer = 0;
	}
	// Tear down context
	if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];
	[context release];
	context = nil;
    [document release];
    [downloaded release];
	[super dealloc];
}

@end
