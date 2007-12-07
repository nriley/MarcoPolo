//
//  LocalisableButton.m
//  MarcoPolo
//
//  Created by David Symonds on 7/12/07.
//

#import "LocalisableButton.h"


@interface LocalisableButton (Private)

- (void)updateSelf;
- (void)shiftSiblingsToAllowForExpansion:(float)delta;

@end

#pragma mark -

@implementation LocalisableButton

- (id)initWithCoder:(NSCoder *)coder
{
	if (!(self = [super initWithCoder:coder]))
		return nil;

	initialTitle = [[self title] copy];

	// Ensure we're flexible
	[self setAutoresizingMask:([self autoresizingMask] | NSViewWidthSizable)];

	return self;
}

- (void)dealloc
{
	[initialTitle release];

	[super dealloc];
}

- (void)awakeFromNib
{
	[self updateSelf];
}

#pragma mark -

- (void)updateSelf
{
	// Translate and set string
	NSString *displayTitle = NSLocalizedString(initialTitle, @"Button title");
	[self setTitle:displayTitle];

	NSRect oldFrame = [self frame];
	[self sizeToFit];
	NSRect newFrame = [self frame];

	if (oldFrame.size.width >= newFrame.size.width) {
		// Don't allow shrinking, so nothing to do
		//NSLog(@"Not changing button with title '%@'", initialTitle);
		[self setFrame:oldFrame];
		return;
	}

	float delta = newFrame.size.width - oldFrame.size.width;
	[self shiftSiblingsToAllowForExpansion:delta];
	//NSLog(@"Resized button by %.1f", delta);
}

- (void)shiftSiblingsToAllowForExpansion:(float)delta
{
	NSArray *siblingViews = [[self superview] subviews];

	BOOL expandLeft = ([self autoresizingMask] & NSViewMinXMargin);

	NSEnumerator *en = [siblingViews objectEnumerator];
	NSView *sibling;
	while ((sibling = [en nextObject])) {
		if (sibling == self)
			continue;

		NSRect them = [sibling frame], us = [self frame];
		if (NSMaxY(them) < NSMinY(us))
			continue;		// completely below
		if (NSMinY(them) > NSMaxY(us))
			continue;		// completely above

		NSPoint origin = [sibling frame].origin;
		if (expandLeft && (NSMaxX(them) < NSMaxX(us))) {
			// Sibling on the left, and need to push them left
			origin.x -= delta;
		} else if (!expandLeft && (NSMaxX(us) < NSMaxX(them))) {
			// Sibling on the right, and need to push them right
			origin.x += delta;
		}
		[sibling setFrameOrigin:origin];
	}

	if (expandLeft) {
		// Shift ourselves too
		NSPoint origin = [self frame].origin;
		origin.x -= delta;
		[self setFrameOrigin:origin];
	}
}

@end
