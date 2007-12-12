//
//  ActionWithFloat.m
//  MarcoPolo
//
//  Created by David Symonds on 12/12/07.
//

#import "ActionWithFloat.h"


@implementation ActionWithFloat

- (id)init
{
	if (!(self = [super initWithNibNamed:@"ActionWithFloat"]))
		return nil;

	// Default to 0-100% display
	[parameterSlider setMinValue:0];
	[parameterSlider setMaxValue:1.0];

	return self;
}

- (NSMutableDictionary *)readFromPanel
{
	NSMutableDictionary *dict = [super readFromPanel];

	NSNumber *val = [NSNumber numberWithFloat:[parameterSlider floatValue]];

	[dict setValue:val forKey:@"parameter"];
	if (![dict objectForKey:@"description"])
		[dict setValue:[self descriptionOf:dict] forKey:@"description"];

	return dict;
}

- (void)writeToPanel:(NSDictionary *)dict
{
	[super writeToPanel:dict];

	[leadTextField setStringValue:[self leadText]];
	[leadTextField flexToFit];

	float initialValue;
	if ([dict objectForKey:@"parameter"])
		initialValue = [[dict valueForKey:@"parameter"] floatValue];
	else
		initialValue = ([parameterSlider minValue] + [parameterSlider maxValue]) / 2;
	[parameterSlider setFloatValue:initialValue];
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
