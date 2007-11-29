//
//  ToggleableAction.m
//  MarcoPolo
//
//  Created by David Symonds on 7/06/07.
//

#import "ToggleableAction.h"


@interface ToggleableAction (Private)

- (BOOL)decodeParameter:(NSObject *)parameter;

@end

#pragma mark -

@implementation ToggleableAction

- (id)init
{
	if (!(self = [super init]))
		return nil;

	return self;
}

- (BOOL)decodeParameter:(NSObject *)parameter
{
	if ([parameter isKindOfClass:[NSNumber class]])
		return [(NSNumber *) parameter boolValue];
	else
		return ([parameter isEqual:@"on"] || [parameter isEqual:@"1"]);
}

- (NSString *)descriptionOf:(NSDictionary *)actionDict
{
	return [self descriptionOfTransitionToState:[self decodeParameter:[actionDict valueForKey:@"parameter"]]];
}

- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString
{
	return [self executeTransition:[self decodeParameter:[actionDict valueForKey:@"parameter"]]
				 error:errorString];
}

- (NSArray *)suggestions
{
	return [NSArray arrayWithObjects:
		[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"parameter",
			[self descriptionOfState:YES], @"description", nil],
		[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], @"parameter",
			[self descriptionOfState:NO], @"description", nil],
		nil];
}

- (NSString *)suggestionLeadText
{
	return @"";
}

- (NSString *)descriptionOfState:(BOOL)state
{
	if (state)
		return NSLocalizedString(@"on", @"Used in toggling actions");
	else
		return NSLocalizedString(@"off", @"Used in toggling actions");
}

- (NSString *)descriptionOfTransitionToState:(BOOL)state
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (BOOL)executeTransition:(BOOL)state error:(NSString **)errorString
{
	[self doesNotRecognizeSelector:_cmd];
	return NO;
}

@end
