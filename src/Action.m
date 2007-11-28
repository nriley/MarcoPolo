//
//  Action.m
//  MarcoPolo
//
//  Created by David Symonds on 3/04/07.
//

#import "Action.h"
#import "DSLogger.h"


@implementation Action

- (id)initWithNibNamed:(NSString *)name
{
	if ([[self class] isEqualTo:[Action class]]) {
		[NSException raise:@"Abstract Class Exception"
			    format:@"Error, attempting to instantiate Action directly."];
	}

	if (!(self = [super init]))
		return nil;

	oldDescription_ = nil;

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
	[oldDescription_ release];

	[super dealloc];
}

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

- (NSMutableDictionary *)readFromPanel
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];

	if (oldDescription_)
		[dict setValue:oldDescription_ forKey:@"description"];

	return dict;
}

- (void)writeToPanel:(NSDictionary *)dict
{
	// Hang on to custom descriptions
	[oldDescription_ autorelease];
	oldDescription_ = nil;
	if ([dict objectForKey:@"description"]) {
		NSString *desc = [dict valueForKey:@"description"];
		if (desc && ([desc length] > 0))
			oldDescription_ = [desc retain];
	}
}

#pragma mark Stubs

- (NSString *)name
{
	NSString *className = NSStringFromClass([self class]);
	if ([className hasPrefix:@"Action"])
		className = [className substringToIndex:([className length] - 6)];
	return className;
}

- (NSString *)descriptionOf:(NSDictionary *)actionDict
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString
{
	[self doesNotRecognizeSelector:_cmd];
	return NO;
}

#pragma mark AppleScript helpers

- (void)executeAppleScriptForReal:(NSString *)script
{
	appleScriptResult_ = nil;

	NSAppleScript *as = [[[NSAppleScript alloc] initWithSource:script] autorelease];
	if (!as) {
		NSLog(@"AppleScript failed to construct! Script was:\n%@", script);
		return;
	}
	NSDictionary *errorDict;
	if (![as compileAndReturnError:&errorDict]) {
		NSLog(@"AppleScript failed to compile! Script was:\n%@\nError dictionary: %@", script, errorDict);
		return;
	}
	appleScriptResult_ = [as executeAndReturnError:&errorDict];
	if (!appleScriptResult_)
		NSLog(@"AppleScript failed to execute! Script was:\n%@\nError dictionary: %@", script, errorDict);
}

- (BOOL)executeAppleScript:(NSString *)script
{
	// NSAppleScript is not thread-safe, so this needs to happen on the main thread. Ick.
	[self performSelectorOnMainThread:@selector(executeAppleScriptForReal:)
			       withObject:script
			    waitUntilDone:YES];
	return (appleScriptResult_ ? YES : NO);
}

- (NSArray *)executeAppleScriptReturningListOfStrings:(NSString *)script
{
	if (![self executeAppleScript:script])
		return nil;
	if ([appleScriptResult_ descriptorType] != typeAEList)
		return nil;

	int count = [appleScriptResult_ numberOfItems], i;
	NSMutableArray *list = [NSMutableArray arrayWithCapacity:count];
	for (i = 1; i <= count; ++i) {		// Careful -- AppleScript lists are 1-based
		NSAppleEventDescriptor *elt = [appleScriptResult_ descriptorAtIndex:i];
		if (!elt) {
			NSLog(@"Oops -- couldn't get descriptor at index %d", i);
			continue;
		}
		NSString *val = [elt stringValue];
		if (!val) {
			NSLog(@"Oops -- couldn't turn descriptor at index %d into string", i);
			continue;
		}
		[list addObject:val];
	}

	return list;
}

@end

#pragma mark -

@interface ActionSetController (Private)

//// NSMenu delegates (for adding rules)
//- (BOOL)menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(int)index shouldCancel:(BOOL)shouldCancel;
//- (BOOL)menuHasKeyEquivalent:(NSMenu *)menu forEvent:(NSEvent *)event target:(id *)target action:(SEL *)action;
//- (int)numberOfItemsInMenu:(NSMenu *)menu;

@end

#import "DefaultPrinterAction.h"

@implementation ActionSetController

- (id)init
{
	if (!(self = [super init]))
		return nil;

	NSArray *classes = [NSArray arrayWithObjects:
		[DefaultPrinterAction class],
		nil];
	if (NO) {
		// Purely for the benefit of 'genstrings'
		NSLocalizedString(@"DefaultPrinter", @"Action type");
	}

	// Instantiate all the actions
	NSMutableArray *actionList = [[NSMutableArray alloc] initWithCapacity:[classes count]];
	NSEnumerator *en = [classes objectEnumerator];
	Class klass;
	while ((klass = [en nextObject])) {
		Action *action = [[klass alloc] init];
		[actionList addObject:action];
	}
	actions = actionList;

	// TODO: any other init?

	return self;
}

- (void)dealloc
{
	[actions release];

	[super dealloc];
}

- (Action *)actionWithName:(NSString *)name
{
	NSEnumerator *en = [actions objectEnumerator];
	Action *action;
	while ((action = [en nextObject]))
		if ([[action name] isEqualToString:name])
			return action;
	return nil;
}

- (NSEnumerator *)actionEnumerator
{
	return [actions objectEnumerator];
}

@end

#if 0
#pragma mark -

@implementation Action

+ (NSString *)typeForClass:(Class)klass
{
	// Hack "Action" off class name (6 chars)
	// TODO: make this a bit more robust?
	NSString *className = NSStringFromClass(klass);
	return [className substringToIndex:([className length] - 6)];
}

+ (Class)classForType:(NSString *)type
{
	NSString *classString = [NSString stringWithFormat:@"%@Action", type];
	Class klass = NSClassFromString(classString);
	if (!klass) {
		NSLog(@"ERROR: No implementation class '%@'!", classString);
		return nil;
	}
	return klass;
}

+ (Action *)actionFromDictionary:(NSDictionary *)dict
{
	NSString *type = [dict valueForKey:@"type"];
	if (!type) {
		NSLog(@"ERROR: Action doesn't have a type!");
		return nil;
	}
	Action *obj = [[[Action classForType:type] alloc] initWithDictionary:dict];
	return [obj autorelease];
}

- (id)init
{
	if ([[self class] isEqualTo:[Action class]]) {
		[NSException raise:@"Abstract Class Exception"
			    format:@"Error, attempting to instantiate Action directly."];
	}

	if (!(self = [super init]))
		return nil;

	// Some sensible defaults
	type = [[Action typeForClass:[self class]] retain];
	delay = [[NSNumber alloc] initWithDouble:0];
	enabled = [[NSNumber alloc] initWithBool:YES];
	when = [[NSArray alloc] init];

	return self;
}

- (id)initWithDictionary:(NSDictionary *)dict
{
	if ([[self class] isEqualTo:[Action class]]) {
		[NSException raise:@"Abstract Class Exception"
			    format:@"Error, attempting to instantiate Action directly."];
	}

	if (!(self = [super init]))
		return nil;

	type = [[Action typeForClass:[self class]] retain];
	delay = [[dict valueForKey:@"delay"] copy];
	enabled = [[dict valueForKey:@"enabled"] copy];
	when = [[dict valueForKey:@"when"] retain];

	return self;
}

- (void)dealloc
{
	[type release];
	[delay release];
	[enabled release];
	[when release];

	[super dealloc];
}

- (NSMutableDictionary *)dictionary
{
	return [NSMutableDictionary dictionaryWithObjectsAndKeys:
		[[type copy] autorelease], @"type",
		[[delay copy] autorelease], @"delay",
		[[enabled copy] autorelease], @"enabled",
		[[when copy] autorelease], @"when",
		nil];
}

+ (NSString *)helpTextForActionOfType:(NSString *)type
{
	return [[Action classForType:type] helpText];
}

- (NSComparisonResult)compareDelay:(Action *)other
{
	return [[self valueForKey:@"delay"] compare:[other valueForKey:@"delay"]];
}

- (void)notImplemented:(NSString *)methodName
{
	[NSException raise:@"Abstract Class Exception"
		    format:[NSString stringWithFormat:@"Error, -[%@ %@] not implemented.",
			    [self class], methodName]];
}

- (NSString *)description
{
	[self notImplemented:@"description"];
	return @"Not implemented!";
}

- (BOOL)execute:(NSString **)errorString
{
	[self notImplemented:@"execute"];
	*errorString = @"Not implemented!";
	return NO;
}

+ (NSString *)helpText
{
	return @"Sorry, no help text written yet!";
}

+ (NSString *)creationHelpText
{
	return @"<Sorry, help text coming soon!>";
}

- (void)executeAppleScriptForReal:(NSString *)script
{
	appleScriptResult_ = nil;

	NSAppleScript *as = [[[NSAppleScript alloc] initWithSource:script] autorelease];
	if (!as) {
		NSLog(@"AppleScript failed to construct! Script was:\n%@", script);
		return;
	}
	NSDictionary *errorDict;
	if (![as compileAndReturnError:&errorDict]) {
		NSLog(@"AppleScript failed to compile! Script was:\n%@\nError dictionary: %@", script, errorDict);
		return;
	}
	appleScriptResult_ = [as executeAndReturnError:&errorDict];
	if (!appleScriptResult_)
		NSLog(@"AppleScript failed to execute! Script was:\n%@\nError dictionary: %@", script, errorDict);
}

- (BOOL)executeAppleScript:(NSString *)script
{
	// NSAppleScript is not thread-safe, so this needs to happen on the main thread. Ick.
	[self performSelectorOnMainThread:@selector(executeAppleScriptForReal:)
			       withObject:script
			    waitUntilDone:YES];
	return (appleScriptResult_ ? YES : NO);
}

- (NSArray *)executeAppleScriptReturningListOfStrings:(NSString *)script
{
	if (![self executeAppleScript:script])
		return nil;
	if ([appleScriptResult_ descriptorType] != typeAEList)
		return nil;

	int count = [appleScriptResult_ numberOfItems], i;
	NSMutableArray *list = [NSMutableArray arrayWithCapacity:count];
	for (i = 1; i <= count; ++i) {		// Careful -- AppleScript lists are 1-based
		NSAppleEventDescriptor *elt = [appleScriptResult_ descriptorAtIndex:i];
		if (!elt) {
			NSLog(@"Oops -- couldn't get descriptor at index %d", i);
			continue;
		}
		NSString *val = [elt stringValue];
		if (!val) {
			NSLog(@"Oops -- couldn't turn descriptor at index %d into string", i);
			continue;
		}
		[list addObject:val];
	}

	return list;
}

@end

#pragma mark -

#import "DefaultPrinterAction.h"
#import "DesktopBackgroundAction.h"
#import "FirewallRuleAction.h"
#import "IChatAction.h"
#import "MailIMAPServerAction.h"
#import "MailSMTPServerAction.h"
#import "MountAction.h"
#import "MuteAction.h"
#import "NetworkLocationAction.h"
#import "OpenAction.h"
#import "QuitApplicationAction.h"
#import "ScreenSaverPasswordAction.h"
#import "ScreenSaverStartAction.h"
#import "ScreenSaverTimeAction.h"
#import "ShellScriptAction.h"
#import "ToggleBluetoothAction.h"
#import "ToggleWiFiAction.h"
#import "UnmountAction.h"
#import "VPNAction.h"

@implementation ActionSetController

- (id)init
{
	if (!(self = [super init]))
		return nil;

	classes = [[NSArray alloc] initWithObjects:
		[DefaultPrinterAction class],
		[DesktopBackgroundAction class],
		[FirewallRuleAction class],
		[IChatAction class],
		[MailIMAPServerAction class],
		[MailSMTPServerAction class],
		[MountAction class],
		[MuteAction class],
		[NetworkLocationAction class],
		[OpenAction class],
		[QuitApplicationAction class],
		[ScreenSaverPasswordAction class],
		[ScreenSaverStartAction class],
		[ScreenSaverTimeAction class],
		[ShellScriptAction class],
		[ToggleBluetoothAction class],
		[ToggleWiFiAction class],
		[UnmountAction class],
		[VPNAction class],
			nil];
	if (NO) {
		// Purely for the benefit of 'genstrings'
		NSLocalizedString(@"DefaultPrinter", @"Action type");
		NSLocalizedString(@"DesktopBackground", @"Action type");
		NSLocalizedString(@"FirewallRule", @"Action type");
		NSLocalizedString(@"IChat", @"Action type");
		NSLocalizedString(@"MailIMAPServer", @"Action type");
		NSLocalizedString(@"MailSMTPServer", @"Action type");
		NSLocalizedString(@"Mount", @"Action type");
		NSLocalizedString(@"Mute", @"Action type");
		NSLocalizedString(@"NetworkLocation", @"Action type");
		NSLocalizedString(@"Open", @"Action type");
		NSLocalizedString(@"QuitApplication", @"Action type");
		NSLocalizedString(@"ScreenSaverPassword", @"Action type");
		NSLocalizedString(@"ScreenSaverStart", @"Action type");
		NSLocalizedString(@"ScreenSaverTime", @"Action type");
		NSLocalizedString(@"ShellScript", @"Action type");
		NSLocalizedString(@"ToggleBluetooth", @"Action type");
		NSLocalizedString(@"ToggleWiFi", @"Action type");
		NSLocalizedString(@"Unmount", @"Action type");
		NSLocalizedString(@"VPN", @"Action type");
	}

	return self;
}

- (void)dealloc
{
	[classes release];

	[super dealloc];
}

- (NSArray *)types
{
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:[classes count]];
	NSEnumerator *en = [classes objectEnumerator];
	Class klass;
	while ((klass = [en nextObject])) {
		[array addObject:[Action typeForClass:klass]];
	}
	return array;
}

#pragma mark NSMenu delegates

- (BOOL)menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(int)index shouldCancel:(BOOL)shouldCancel
{
	Class klass = [classes objectAtIndex:index];
	NSString *type = [Action typeForClass:klass];
	NSString *localisedType = NSLocalizedString(type, @"Action type");

	NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Add %@ Action...", @"Menu item"),
		localisedType];
	[item setTitle:title];

	[item setTarget:prefsWindowController];
	[item setAction:@selector(addAction:)];
	[item setRepresentedObject:klass];

	return YES;
}

- (BOOL)menuHasKeyEquivalent:(NSMenu *)menu forEvent:(NSEvent *)event target:(id *)target action:(SEL *)action
{
	// TODO: support keyboard menu jumping?
	return NO;
}

- (int)numberOfItemsInMenu:(NSMenu *)menu
{
	return [classes count];
}

@end

#endif
