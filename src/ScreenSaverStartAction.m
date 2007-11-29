//
//  ScreenSaverStartAction.m
//  MarcoPolo
//
//  Created by David Symonds on 4/11/07.
//

#import "ScreenSaverStartAction.h"


@implementation ScreenSaverStartAction

- (NSString *)suggestionLeadText
{
	// FIXME: is there some useful text we could use?
	return @"";
}

- (NSString *)descriptionOfState:(BOOL)state
{
	if (state)
		return NSLocalizedString(@"Start screen saver", @"Future tense");
	else
		return NSLocalizedString(@"Stop screen saver", @"Future tense");
}

- (NSString *)descriptionOfTransitionToState:(BOOL)state
{
	if (state)
		return NSLocalizedString(@"Starting screen saver.", @"");
	else
		return NSLocalizedString(@"Stopping screen saver.", @"");
}

- (BOOL)executeTransition:(BOOL)state error:(NSString **)errorString
{
	NSString *script = [NSString stringWithFormat:@"tell application \"ScreenSaverEngine\" to %@",
		(state ? @"activate" : @"quit")];

	if (![self executeAppleScript:script]) {
		if (state)
			*errorString = NSLocalizedString(@"Failed starting screen saver!", @"");
		else
			*errorString = NSLocalizedString(@"Failed stopping screen saver!", @"");
		return NO;
	}

	return YES;
}

@end
