//
//  EAGLView.m
//  MQMobile
//
//  Created by hkrn on 09/09/23.
//  Copyright hkrn 2009. All rights reserved.
//

#import "EAGLView.h"

#import "ES1Renderer.h"
//#import "ES2Renderer.h"

@implementation EAGLView

@synthesize animating;
@dynamic animationFrameInterval;

// You must implement this method
+ (Class) layerClass
{
    return [CAEAGLLayer class];
}

//The GL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
- (id) initWithCoder:(NSCoder*)coder
{    
    if ((self = [super initWithCoder:coder])) {
        // Get the layer
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
        eaglLayer.opaque = YES;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
		renderer = nil; //[[ES2Renderer alloc] init];
		if (!renderer) {
			renderer = [[ES1Renderer alloc] init];
			if (!renderer) {
				[self release];
				return nil;
			}
            [renderer loadModelFromURL];
		}
		animating = NO;
		displayLinkSupported = NO;
		animationFrameInterval = 1;
		displayLink = nil;
		animationTimer = nil;
		// A system version of 3.1 or greater is required to use CADisplayLink. The NSTimer
		// class is used as fallback when it isn't available.
		NSString *reqSysVer = @"3.1";
		NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
		if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending)
			displayLinkSupported = YES;
    }
    return self;
}

- (void) drawView:(id)sender
{
    [renderer render];
}

- (void) layoutSubviews
{
	[renderer resizeFromLayer:(CAEAGLLayer*)self.layer];
    [self drawView:nil];
}

- (NSInteger) animationFrameInterval
{
	return animationFrameInterval;
}

- (void) setAnimationFrameInterval:(NSInteger)frameInterval
{
	// Frame interval defines how many display frames must pass between each time the
	// display link fires. The display link will only fire 30 times a second when the
	// frame internal is two on a display that refreshes 60 times a second. The default
	// frame interval setting of one will fire 60 times a second when the display refreshes
	// at 60 times a second. A frame interval setting of less than one results in undefined
	// behavior.
	if (frameInterval >= 1) {
		animationFrameInterval = frameInterval;
		if (animating) {
			[self stopAnimation];
			[self startAnimation];
		}
	}
}

- (void) startAnimation
{
	if (!animating) {
		if (displayLinkSupported) {
			// CADisplayLink is API new to iPhone SDK 3.1. Compiling against earlier versions will result in a warning, but can be dismissed
			// if the system version runtime check for CADisplayLink exists in -initWithCoder:. The runtime check ensures this code will
			// not be called in system versions earlier than 3.1.

			displayLink = [NSClassFromString(@"CADisplayLink") displayLinkWithTarget:self selector:@selector(drawView:)];
			[displayLink setFrameInterval:animationFrameInterval];
			[displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		}
		else
			animationTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)((1.0 / 60.0) * animationFrameInterval) target:self selector:@selector(drawView:) userInfo:nil repeats:TRUE];
		animating = TRUE;
	}
}

- (void)stopAnimation
{
	if (animating) {
		if (displayLinkSupported) {
			[displayLink invalidate];
			displayLink = nil;
		}
		else {
			[animationTimer invalidate];
			animationTimer = nil;
		}
		animating = FALSE;
	}
}

- (CGFloat)distanceFromTouches:(NSSet *)allTouches
{
    NSArray *touches = [allTouches allObjects];
    UITouch *firstTouch = [touches objectAtIndex:0];
    UITouch *secondTouch = [touches objectAtIndex:1];
    CGPoint from = [firstTouch locationInView:self];
    CGPoint to = [secondTouch locationInView:self];
    CGFloat x = to.x - from.x;
    CGFloat y = to.y - from.y;
    return sqrt(x * x + y * y);
}

- (void)touchesBegan:(NSSet *)t
           withEvent:(UIEvent *)event
{
    NSSet *touches = [event touchesForView:[self superview]];
    if ([touches count] > 1)
        distance = [self distanceFromTouches:touches];
}

- (void)touchesMoved:(NSSet *)t
           withEvent:(UIEvent *)event
{
    NSSet *touches = [event touchesForView:[self superview]];
    if ([touches count] > 1) {
        CGFloat currentDistance = [self distanceFromTouches:touches];
        if (distance > currentDistance) {
            //NSLog(@"Zoom In: %.f %.f", distance, currentDistance);
            [renderer updateScale:-0.1];
        }
        else {
            //NSLog(@"Zoom Out: %.f %.f", distance, currentDistance);
            [renderer updateScale:0.1];
        }
        distance = currentDistance;
    }
    else {
        UITouch *touch = [touches anyObject];
        CGPoint current = [touch locationInView:self];
        CGPoint prev = [touch previousLocationInView:self];
        CGPoint angle = CGPointMake(current.x - prev.x, current.y - prev.y);
        [renderer updateAngle:angle];
    }
}

- (void) dealloc
{
    [renderer release];
	
    [super dealloc];
}

@end
