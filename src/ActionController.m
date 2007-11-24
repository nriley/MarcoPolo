//
//  ActionController.m
//  MarcoPolo
//
//  Created by David Symonds on 24/11/07.
//

#import "ActionController.h"


@implementation ActionController

- (id)initWithNibNamed:(NSString *)name
{
	if ([[self class] isEqualTo:[ActionController class]]) {
		[NSException raise:@"Abstract Class Exception"
			    format:@"Error, attempting to instantiate ActionController directly."];
	}

	if (!(self = [super init]))
		return nil;

	oldDescription = nil;

	// load nib
	NSNib *nib = [[[NSNib alloc] initWithNibNamed:name bundle:nil] autorelease];
	if (!nib) {
		NSLog(@"%@ >> failed loading nib named '%@'!", [self class], name);
		return nil;
	}
	NSArray *topLevelObjects = [NSArray array];
	if (![nib instantiateNibWithOwner:self topLevelObjects:&topLevelObjects]) {
		NSLog(@"%@ >> failed instantiating nib (named '%@')!", [self class], name);
		return nil;
	}

	// Look for an NSPanel
	panel = nil;
	NSEnumerator *en = [topLevelObjects objectEnumerator];
	NSObject *obj;
	while ((obj = [en nextObject])) {
		if ([obj isKindOfClass:[NSPanel class]] && !panel)
			panel = (NSPanel *) [obj retain];
	}
	if (!panel) {
		NSLog(@"%@ >> failed to find an NSPanel in nib named '%@'!", [self class], name);
		return nil;
	}

	return self;
}

- (void)dealloc
{
	[panel release];
	[oldDescription release];

	[super dealloc];
}

#pragma mark -
#pragma mark Sheet hooks

- (void)runPanelAsSheetOfWindow:(NSWindow *)window withParameter:(NSDictionary *)parameter
		 callbackObject:(NSObject *)callbackObject selector:(SEL)selector
{
//	NSString *typeToUse = [[self typesOfRulesMatched] objectAtIndex:0];
//	if ([parameter objectForKey:@"type"])
//		typeToUse = [parameter valueForKey:@"type"];
//	[self writeToPanel:parameter usingType:typeToUse];

	// Record callback as an NSInvocation, which is storable as an NSObject pointer.
	NSMethodSignature *sig = [callbackObject methodSignatureForSelector:selector];
	NSInvocation *contextInfo = [NSInvocation invocationWithMethodSignature:sig];
	[contextInfo setSelector:selector];
	[contextInfo setTarget:callbackObject];

	[NSApp beginSheet:panel
	   modalForWindow:window
	    modalDelegate:self
	   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
	      contextInfo:[contextInfo retain]];
}

- (IBAction)closeSheetWithOK:(id)sender
{
	[NSApp endSheet:panel returnCode:NSOKButton];
	[panel orderOut:nil];
}

- (IBAction)closeSheetWithCancel:(id)sender
{
	[NSApp endSheet:panel returnCode:NSCancelButton];
	[panel orderOut:nil];
}

// Private
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode != NSOKButton)
		return;

	NSInvocation *inv = (NSInvocation *) contextInfo;
	NSDictionary *dict = [self readFromPanel];
	[inv setArgument:&dict atIndex:2];

	[inv invoke];
	[inv release];
}

// XXX: Do we want to push the whole action dictionary to/from the panel?
//	Shouldn't just the parameter and description be sufficient?

- (NSMutableDictionary *)readFromPanel
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
//	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
//		[self name], @"type",
//		[NSNumber numberWithInt:0], @"delay",
//		[NSNumber numberWithBool:YES], @"enabled",
//		[NSArray array], @"when",
//		nil];

	if (oldDescription)
		[dict setValue:oldDescription forKey:@"description"];

	return dict;
}

- (void)writeToPanel:(NSDictionary *)dict usingType:(NSString *)type
{
	// Hang on to custom descriptions
	[oldDescription autorelease];
	oldDescription = nil;
	if ([dict objectForKey:@"description"]) {
		NSString *desc = [dict valueForKey:@"description"];
		if (desc && ([desc length] > 0))
			oldDescription = [desc retain];
	}
}

#pragma mark -

- (NSString *)name
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

@end
