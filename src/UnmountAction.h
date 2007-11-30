//
//  UnmountAction.h
//  MarcoPolo
//
//  Created by Mark Wallis on 14/11/07.
//

#import <Cocoa/Cocoa.h>
#import "StringAction.h"


@interface UnmountAction : StringAction {
}

- (NSString *)leadText;
- (NSString *)descriptionOf:(NSDictionary *)actionDict;
- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString;

@end
