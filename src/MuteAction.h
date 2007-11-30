//
//  MuteAction.h
//  MarcoPolo
//
//  Created by David Symonds on 7/06/07.
//

#import <Cocoa/Cocoa.h>
#import "ActionWithBool.h"


@interface MuteAction : ActionWithBool {
}

- (NSString *)descriptionOfState:(BOOL)state;
- (NSString *)descriptionOfTransitionToState:(BOOL)state;
- (BOOL)executeTransition:(BOOL)state error:(NSString **)errorString;

@end
