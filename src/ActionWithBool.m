//
//  ActionWithBool.m
//  MarcoPolo
//
//  Created by David Symonds on 7/06/07.
//

#import "ActionWithBool.h"


@interface ActionWithBool (Private)

- (BOOL)decodeParameter:(NSObject *)parameter;

@end

#pragma mark -

@implementation ActionWithBool

- (id)init
{
	if (!(self = [super initWithNibNamed:@"ActionWithBool"]))
		return nil;

	return self;
}

- (NSMutableDictionary *)readFromPanel
{
	NSMutableDictionary *dict = [super readFromPanel];

	BOOL val = [radio1 intValue];

	[dict setValue:[NSNumber numberWithBool:val] forKey:@"parameter"];
	if (![dict objectForKey:@"description"])
		[dict setValue:[self descriptionOfState:val] forKey:@"description"];

	return dict;
}

- (void)writeToPanel:(NSDictionary *)dict
{
	[super writeToPanel:dict];

	[radio1 setTitle:[self descriptionOfState:YES]];
	[radio2 setTitle:[self descriptionOfState:NO]];

	NSButtonCell *sel = radio1;
	if ([dict objectForKey:@"parameter"]) {
		BOOL val = [self decodeParameter:[dict valueForKey:@"parameter"]];
		sel = (val ? radio1 : radio2);
	}
	[sel performClick:self];
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
