//
//  MuteAction.m
//  MarcoPolo
//
//  Created by David Symonds on 7/06/07.
//

#import "MuteAction.h"


@implementation MuteAction

- (NSString *)suggestionLeadText
{
	// FIXME: is there some useful text we could use?
	return @"";
}

- (NSString *)descriptionOfState:(BOOL)state
{
	if (state)
		return NSLocalizedString(@"Unmute system audio.", @"Future tense");
	else
		return NSLocalizedString(@"Mute system audio.", @"Future tense");
}

- (NSString *)descriptionOfTransitionToState:(BOOL)state
{
	if (state)
		return NSLocalizedString(@"Unmuting system audio.", @"Present continuous tense");
	else
		return NSLocalizedString(@"Muting system audio.", @"Present continuous tense");
}

- (BOOL)executeTransition:(BOOL)state error:(NSString **)errorString
{
	NSString *script = [NSString stringWithFormat:@"set volume %@ output muted",
				(state ? @"without" : @"with")];

	// Should never fail
	[self executeAppleScript:script];
	//if ([task terminationStatus] != 0) {
	//	return NO;
	//}

	return YES;
}

@end
