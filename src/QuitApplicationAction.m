//
//  QuitApplicationAction.m
//  MarcoPolo
//
//  Created by David Symonds on 15/10/07.
//

#import "QuitApplicationAction.h"


@implementation QuitApplicationAction

- (NSString *)leadText
{
	return NSLocalizedString(@"Quit application with this name:", @"");
}

- (NSString *)descriptionOf:(NSDictionary *)actionDict
{
	return [NSString stringWithFormat:NSLocalizedString(@"Quitting application '%@'.", @""),
		[actionDict valueForKey:@"parameter"]];
}

- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString
{
	// TODO: properly escape application name!
	NSString *script = [NSString stringWithFormat:
		@"tell application \"%@\" to quit",
		[actionDict valueForKey:@"parameter"]];

	if (![self executeAppleScript:script]) {
		*errorString = NSLocalizedString(@"Couldn't quit application!", @"In QuitApplicationAction");
		return NO;
	}

	return YES;
}

@end
