//
//  ActionWithFile.m
//  MarcoPolo
//
//  Created by David Symonds on 30/11/07.
//

#import "ActionWithFile.h"


@implementation ActionWithFile

- (void)runPanelAsSheetOfWindow:(NSWindow *)window withParameter:(NSDictionary *)parameter
		 callbackObject:(NSObject *)callbackObject selector:(SEL)selector
{
	NSOpenPanel *oPanel = [NSOpenPanel openPanel];

	[oPanel setAllowedFileTypes:nil];	// any file type
	[oPanel setAllowsMultipleSelection:NO];
	[oPanel setCanChooseDirectories:NO];
	[oPanel setCanChooseFiles:YES];

	panel = oPanel;
	[self writeToPanel:parameter];

	// Record callback as an NSInvocation, which is storable as an NSObject pointer.
	NSMethodSignature *sig = [callbackObject methodSignatureForSelector:selector];
	NSInvocation *contextInfo = [NSInvocation invocationWithMethodSignature:sig];
	[contextInfo setSelector:selector];
	[contextInfo setTarget:callbackObject];

	NSString *dir = nil, *file = nil;
	if ([parameter objectForKey:@"parameter"]) {
		NSString *path = [parameter valueForKey:@"parameter"];
		dir = [path stringByDeletingLastPathComponent];
		file = [path lastPathComponent];
	}

	[oPanel beginSheetForDirectory:dir
				  file:file
				 types:nil
			modalForWindow:window
			 modalDelegate:self
			didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			   contextInfo:[contextInfo retain]];
}

- (NSMutableDictionary *)readFromPanel
{
	NSMutableDictionary *dict = [super readFromPanel];

	NSOpenPanel *oPanel = (NSOpenPanel *) panel;
	NSString *path = [[oPanel filenames] lastObject];

	[dict setValue:path forKey:@"parameter"];
	if (![dict objectForKey:@"description"])
		[dict setValue:[self descriptionOf:dict] forKey:@"description"];
	
	return dict;
}

- (NSString *)leadText
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (NSString *)descriptionOf:(NSDictionary *)actionDict
{
	return [super descriptionOf:actionDict];
}

- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString
{
	return [super execute:actionDict error:errorString];
}

@end
