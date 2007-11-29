//
//  ToggleableAction.h
//  MarcoPolo
//
//  Created by David Symonds on 7/06/07.
//

#import <Cocoa/Cocoa.h>
#import "GenericAction.h"


@interface ToggleableAction : GenericAction {
}

- (NSString *)descriptionOf:(NSDictionary *)actionDict;
- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString;

- (NSArray *)suggestions;

// To be implemented by descendant classes
- (NSString *)suggestionLeadText;	// optional
- (NSString *)descriptionOfState:(BOOL)state;	// defaults to "on"/"off"
- (NSString *)descriptionOfTransitionToState:(BOOL)state;
- (BOOL)executeTransition:(BOOL)state error:(NSString **)errorString;

@end
