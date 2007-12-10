//
//  FlexControls.m
//  MarcoPolo
//
//  Created by David Symonds on 11/12/07.
//

#import "FlexControls.h"


#pragma mark -
#pragma mark FlexControl

@interface FlexControl : NSObject {}

+ (void)increaseWidthOfWindowOf:(NSView *)view by:(float)delta;

@end

@implementation FlexControl

+ (void)increaseWidthOfWindowOf:(NSView *)view by:(float)delta
{
#ifdef DEBUG_MODE
	NSLog(@"Increasing window holding a %@ by %.1f", [view class], delta);
#endif

	NSWindow *win = [view window];

	NSRect rect = [win frame];
	rect.size.width += delta;
	[win setFrame:rect display:NO];
}

@end

#pragma mark -
#pragma mark FlexMatrix

@implementation FlexMatrix

- (void)flexToFit
{
	// Work out what size we want
	NSRect oldFrame = [self frame];
	[self sizeToFit];
	NSRect newFrame = [self frame];
	[self setFrame:oldFrame];

	float deltaWidth = newFrame.size.width - oldFrame.size.width;

	// We don't allow shrinking (for now)
	if (deltaWidth <= 0)
		return;

	[FlexControl increaseWidthOfWindowOf:self by:deltaWidth];
}

@end
