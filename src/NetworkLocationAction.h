//
//  NetworkLocationAction.h
//  MarcoPolo
//
//  Created by David Symonds on 4/07/07.
//

#import <Cocoa/Cocoa.h>
#import "GenericAction.h"


@interface NetworkLocationAction : GenericAction {
}

- (NSString *)descriptionOf:(NSDictionary *)actionDict;
- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString;

- (NSString *)suggestionLeadText;
- (NSArray *)suggestions;

@end
