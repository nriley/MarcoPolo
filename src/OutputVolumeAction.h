//
//  OutputVolumeAction.h
//  MarcoPolo
//
//  Created by David Symonds on 12/12/07.
//

#import <Cocoa/Cocoa.h>
#import "ActionWithFloat.h"


@interface OutputVolumeAction : ActionWithFloat {
}

- (NSString *)leadText;
- (NSString *)descriptionOf:(NSDictionary *)actionDict;
- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString;

@end
