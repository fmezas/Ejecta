#import <QuartzCore/QuartzCore.h>
#import "EJCanvasContext2DScreen.h"
#import "EJApp.h"

@implementation EJCanvasContext2DScreen

@synthesize scalingMode;


- (void)create {
	// Work out the final screen size - this takes the scalingMode, canvas size, 
	// screen size and retina properties into account
	
	CGRect frame = CGRectMake(0, 0, width, height);
	CGSize screen = [EJApp instance].view.bounds.size;
    float contentScale = (useRetinaResolution && [UIScreen mainScreen].scale == 2) ? 2 : 1;
	float aspect = frame.size.width / frame.size.height;
	
	if( scalingMode == kEJScalingModeFitWidth ) {
		frame.size.width = screen.width;
		frame.size.height = screen.width / aspect;
	}
	else if( scalingMode == kEJScalingModeFitHeight ) {
		frame.size.width = screen.height * aspect;
		frame.size.height = screen.height;
	}
	float internalScaling = frame.size.width / (float)width;
	[EJApp instance].internalScaling = internalScaling;
	
	backingStoreRatio = internalScaling * contentScale;
	
	bufferWidth = frame.size.width * contentScale;
	bufferHeight = frame.size.height * contentScale;
	
	NSLog(
		@"Creating ScreenCanvas (2D): "
			@"size: %dx%d, aspect ratio: %.3f, "
			@"scaled: %.3f = %.0fx%.0f, "
			@"retina: %@ = %.0fx%.0f, "
			@"msaa: %@",
		width, height, aspect, 
		internalScaling, frame.size.width, frame.size.height,
		(useRetinaResolution ? @"yes" : @"no"),
		frame.size.width * contentScale, frame.size.height * contentScale,
		(msaaEnabled ? [NSString stringWithFormat:@"yes (%d samples)", msaaSamples] : @"no")
	);
	
	// Create the OpenGL UIView with final screen size and content scaling (retina)
	glview = [[EAGLView alloc] initWithFrame:frame contentScale:contentScale retainedBacking:YES];
	
	// This creates the frame- and renderbuffers
	[super create];
	
	// Set up the renderbuffer and some initial OpenGL properties
	[glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)glview.layer];
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, viewRenderBuffer);
	

	glDisable(GL_CULL_FACE);
	glDisable(GL_DITHER);
	
	glEnable(GL_BLEND);
	glDepthFunc(GL_ALWAYS);
	
	// Flip the screen - OpenGL has the origin in the bottom left corner. We want the top left.
	vertexScale = EJVector2Make(2.0f/width, 2.0f/-height);
	vertexTranslate = EJVector2Make(-1.0f, 1.0f);
	
	[self prepare];
	
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);

	// Append the OpenGL view to Impact's main view
	[[EJApp instance] hideLoadingScreen];
	[[EJApp instance].view addSubview:glview];
}

- (void)dealloc {
	[glview release];
	[super dealloc];
}


- (void)setWidth:(short)newWidth {
	if( newWidth != width ) {
		NSLog(@"Warning: Can't change size of the screen rendering context");
	}
}

- (void)setHeight:(short)newHeight {
	if( newHeight != height ) {
		NSLog(@"Warning: Can't change size of the screen rendering context");
	}
}

- (EJImageData*)getImageDataSx:(short)sx sy:(short)sy sw:(short)sw sh:(short)sh {
	// FIXME: This takes care of the flipped pixel layout and the internal scaling.
	// The latter will mush pixels; not sure how to fix it - print warning instead.
	
	if( backingStoreRatio != 1 && [EJTexture smoothScaling] ) {
		NSLog(
			@"Warning: The screen canvas has been scaled; getImageData() may not work as expected. "
			@"Set ctx.imageSmoothingEnabled=false or use an off-screen Canvas for more accurate results."
		);
	}
	
	[self flushBuffers];
	
	// Read pixels; take care of the upside down screen layout and the backingStoreRatio
	int internalWidth = sw * backingStoreRatio;
	int internalHeight = sh * backingStoreRatio;
	int internalX = sx * backingStoreRatio;
	int internalY = (height-sy-sh) * backingStoreRatio;
	
	EJColorRGBA * internalPixels = malloc( internalWidth * internalHeight * sizeof(EJColorRGBA));
	glReadPixels( internalX, internalY, internalWidth, internalHeight, GL_RGBA, GL_UNSIGNED_BYTE, internalPixels );
	
	// Flip and scale pixels to requested size
	int size = sw * sh * sizeof(EJColorRGBA);
	EJColorRGBA * pixels = malloc( size );
	int index = 0;
	for( int y = 0; y < sh; y++ ) {
		for( int x = 0; x < sw; x++ ) {
			int internalIndex = (int)((sh-y-1) * backingStoreRatio) * internalWidth + (int)(x * backingStoreRatio);
			pixels[ index ] = internalPixels[ internalIndex ];
			index++;
		}
	}
	free(internalPixels);
	
	NSMutableData * data = [NSMutableData dataWithBytesNoCopy:pixels length:size];
	return [[[EJImageData alloc] initWithWidth:sw height:sh pixels:data] autorelease];
}

- (void)finish {
	glFinish();
}

- (void)present {
	[self flushBuffers];
	
	if( msaaEnabled ) {
		//Bind the MSAA and View frameBuffers and resolve
		glBindFramebuffer(GL_READ_FRAMEBUFFER_APPLE, msaaFrameBuffer);
		glBindFramebuffer(GL_DRAW_FRAMEBUFFER_APPLE, viewFrameBuffer);
		glResolveMultisampleFramebufferAPPLE();
		
		glBindRenderbuffer(GL_RENDERBUFFER, viewRenderBuffer);
		[glContext presentRenderbuffer:GL_RENDERBUFFER];
		glBindFramebuffer(GL_FRAMEBUFFER, msaaFrameBuffer);
	}
	else {
		[glContext presentRenderbuffer:GL_RENDERBUFFER];
	}	
}

@end
