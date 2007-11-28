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

	originalDictionary_ = nil;

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
	[originalDictionary_ release];

	[super dealloc];
}

#pragma mark Sheet hooks

- (void)runPanelAsSheetOfWindow:(NSWindow *)window withParameter:(NSDictionary *)parameter
		 callbackObject:(NSObject *)callbackObject selector:(SEL)selector
{
	[self writeToPanel:parameter];

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
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:originalDictionary_];

	NSString *desc = [dict objectForKey:@"description"];
	if (desc && ([desc length] == 0))
		[dict removeObjectForKey:@"description"];

	return dict;
}

- (void)writeToPanel:(NSDictionary *)dict
{
	[originalDictionary_ autorelease];
	originalDictionary_ = [dict retain];
}

#pragma mark Stubs

- (NSString *)name
{
	NSString *className = NSStringFromClass([self class]);
	if ([className hasSuffix:@"Action"])
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

// NSMenu delegates (for adding actions)
- (BOOL)menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(int)index shouldCancel:(BOOL)shouldCancel;
- (BOOL)menuHasKeyEquivalent:(NSMenu *)menu forEvent:(NSEvent *)event target:(id *)target action:(SEL *)action;
- (int)numberOfItemsInMenu:(NSMenu *)menu;

@end

#import "DefaultPrinterAction.h"
#import "MailSMTPServerAction.h"
#import "NetworkLocationAction.h"
#import "ScreenSaverTimeAction.h"
#import "VPNAction.h"

@implementation ActionSetController

- (id)init
{
	if (!(self = [super init]))
		return nil;

	NSArray *classes = [NSArray arrayWithObjects:
		[DefaultPrinterAction class],
		[MailSMTPServerAction class],
		[NetworkLocationAction class],
		[ScreenSaverTimeAction class],
		[VPNAction class],
		nil];
	if (NO) {
		// Purely for the benefit of 'genstrings'
		NSLocalizedString(@"DefaultPrinter", @"Action type");
		NSLocalizedString(@"MailSMTPServer", @"Action type");
		NSLocalizedString(@"NetworkLocation", @"Action type");
		NSLocalizedString(@"ScreenSaverTime", @"Action type");
		NSLocalizedString(@"VPN", @"Action type");
	}

	// Instantiate all the actions
	NSMutableArray *list = [[NSMutableArray alloc] initWithCapacity:[classes count]];
	NSEnumerator *en = [classes objectEnumerator];
	Class klass;
	while ((klass = [en nextObject])) {
		Action *action = [[klass alloc] init];
		[list addObject:action];
	}
	actions = list;

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

#pragma mark NSMenu delegates

- (BOOL)menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(int)index shouldCancel:(BOOL)shouldCancel
{
	Action *action = [actions objectAtIndex:index];
	NSString *localisedType = NSLocalizedString([action name], @"Action type");

	NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Add %@ Action...", @"Menu item"),
		localisedType];
	[item setTitle:title];

	[item setTarget:prefsWindowController];
	[item setAction:@selector(addAction:)];
	[item setRepresentedObject:action];

	return YES;
}

- (BOOL)menuHasKeyEquivalent:(NSMenu *)menu forEvent:(NSEvent *)event target:(id *)target action:(SEL *)action
{
	// TODO: support keyboard menu jumping?
	return NO;
}

- (int)numberOfItemsInMenu:(NSMenu *)menu
{
	return [actions count];
}

@end

#if 0

#pragma mark -

#import "DesktopBackgroundAction.h"
#import "FirewallRuleAction.h"
#import "IChatAction.h"
#import "MailIMAPServerAction.h"
#import "MountAction.h"
#import "MuteAction.h"
#import "OpenAction.h"
#import "QuitApplicationAction.h"
#import "ScreenSaverPasswordAction.h"
#import "ScreenSaverStartAction.h"
#import "ShellScriptAction.h"
#import "ToggleBluetoothAction.h"
#import "ToggleWiFiAction.h"
#import "UnmountAction.h"

@implementation ActionSetController

- (id)init
{
	if (!(self = [super init]))
		return nil;

	classes = [[NSArray alloc] initWithObjects:
		[DesktopBackgroundAction class],
		[FirewallRuleAction class],
		[IChatAction class],
		[MailIMAPServerAction class],
		[MountAction class],
		[MuteAction class],
		[OpenAction class],
		[QuitApplicationAction class],
		[ScreenSaverPasswordAction class],
		[ScreenSaverStartAction class],
		[ShellScriptAction class],
		[ToggleBluetoothAction class],
		[ToggleWiFiAction class],
		[UnmountAction class],
			nil];
	if (NO) {
		// Purely for the benefit of 'genstrings'
		NSLocalizedString(@"DesktopBackground", @"Action type");
		NSLocalizedString(@"FirewallRule", @"Action type");
		NSLocalizedString(@"IChat", @"Action type");
		NSLocalizedString(@"MailIMAPServer", @"Action type");
		NSLocalizedString(@"Mount", @"Action type");
		NSLocalizedString(@"Mute", @"Action type");
		NSLocalizedString(@"Open", @"Action type");
		NSLocalizedString(@"QuitApplication", @"Action type");
		NSLocalizedString(@"ScreenSaverPassword", @"Action type");
		NSLocalizedString(@"ScreenSaverStart", @"Action type");
		NSLocalizedString(@"ShellScript", @"Action type");
		NSLocalizedString(@"ToggleBluetooth", @"Action type");
		NSLocalizedString(@"ToggleWiFi", @"Action type");
		NSLocalizedString(@"Unmount", @"Action type");
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

#endif
