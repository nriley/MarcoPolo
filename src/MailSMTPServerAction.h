//
//  MailSMTPServerAction.h
//  MarcoPolo
//
//  Created by David Symonds on 3/04/07.
//

#import <Cocoa/Cocoa.h>
#import "ActionWithLimitedOptions.h"


@interface MailSMTPServerAction : ActionWithLimitedOptions {
}

- (NSString *)descriptionOf:(NSDictionary *)actionDict;
- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString;

- (NSString *)suggestionLeadText;
- (NSArray *)suggestions;

@end
