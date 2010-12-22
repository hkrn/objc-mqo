//
//  MQMobileAppDelegate.m
//  MQMobile
//
//  Created by hkrn on 09/09/23.
//  Copyright hkrn 2009. All rights reserved.
//

#import "MQMobileAppDelegate.h"
#import "EAGLView.h"

@implementation MQMobileAppDelegate

@synthesize window;
@synthesize glView;

- (void) applicationDidFinishLaunching:(UIApplication *)application
{
	[glView startAnimation];
}

- (void) applicationWillResignActive:(UIApplication *)application
{
	[glView stopAnimation];
}

- (void) applicationDidBecomeActive:(UIApplication *)application
{
	[glView startAnimation];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	[glView stopAnimation];
}

- (void) dealloc
{
	[window release];
	[glView release];
	
	[super dealloc];
}

@end
