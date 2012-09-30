#import "OSPRosterController.h"
#import "OSPChatController.h"
#import "OSPRosterTableCellView.h"
#import "XMPPPresence+NiceShow.h"
#import "OSPTableView.h"
@interface OSPRosterController (PrivateApi)
- (void) _setArrayControllerFetchPredicate;

@end

@implementation OSPRosterController
@synthesize searchField;
- (XMPPStream *) xmppStream
{
    return [[NSApp delegate] xmppStream];
}


- (XMPPRoster *) xmppRoster
{
    return [[NSApp delegate] xmppRosterModule];
}


- (OSPRosterStorage *) xmppRosterStorage
{
    return [[NSApp delegate] xmppRosterStorage];
}


- (NSDictionary *) jidKeyedDictionaryFromArray:(NSArray *)array
{
    NSUInteger arrayCount = [array count];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];

    for (NSUInteger index = 0UL; index < arrayCount; index++)
    {
        [dict setValue:[array objectAtIndex:index] forKey:[[[array objectAtIndex:index] jid] bare]];
    }

    // return immutable copy
    return [NSDictionary dictionaryWithDictionary:dict];
}


- (OSPChatController *) chatController
{
    return [[NSApp delegate] chatController];
}


- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        initialAwakeFromNibCallFinished = NO;
        requests = [[NSMutableArray alloc] init];
        int jidIndex = -1;
    }

    return self;
}


- (id) init
{
    self = [super init];
    if (self)
    {
//        contactArray = [[NSArray alloc] init];
//        contactDict = [[NSDictionary alloc] init];
    }

    return self;
}


- (void) _setArrayControllerFetchPredicate
{
    NSString *jid = [[NSUserDefaults standardUserDefaults] stringForKey:@"Account.Jid"];
    DDLogVerbose(@"FETCHING ROSTER WITH %@", jid);
    NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"streamBareJidStr == %@", jid];

    [arrayController setFetchPredicate:fetchPredicate];
}


- (void) awakeFromNib
{
    // Medhod may be called more than once, so prevent all that stuff from being executed more than once
    if (!initialAwakeFromNibCallFinished)
    {
        LOGFUNCTIONCALL

        [rosterTable setDoubleAction : @selector(chat)];
        [rosterTable setTarget:self];

        [self _setArrayControllerFetchPredicate];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_setArrayControllerFetchPredicate) name:@"UserChangedJid" object:nil];

        NSRect visibleFrame = [[requestWindow screen] visibleFrame];
        NSRect windowFrame = [requestWindow frame];

        NSPoint windowPosition;
        windowPosition.x = visibleFrame.origin.x + visibleFrame.size.width - windowFrame.size.width - 5;
        windowPosition.y = visibleFrame.origin.y + visibleFrame.size.height - windowFrame.size.height - 5;

        [requestWindow setFrameOrigin:windowPosition];

        initialAwakeFromNibCallFinished = YES;
    }
}


- (void) chat
{
    OSPUserStorageObject *user = [[arrayController selectedObjects] lastObject];
    if (user)
    {
        [[NSApp delegate] closeRosterPopover];
        [[self chatController] openChatWithUser:user andMakeActive:YES];
    }
}


- (BOOL) tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    return NO;
}


- (BOOL) control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector
{
    // selecting the next and previous item behaves strange when scrolling fast yet

    if ( commandSelector == @selector(moveUp:) )
    {
        if ([arrayController canSelectPrevious])
        {
            [arrayController selectPrevious:nil];
            [rosterTable scrollRowToVisible:[arrayController selectionIndex] - 1];
        }

        return YES;
    }
    else if ( commandSelector == @selector(moveDown:) )
    {
        if ([arrayController canSelectNext])
        {
            [arrayController selectNext:nil];
            [rosterTable scrollRowToVisible:[arrayController selectionIndex] + 1];
        }

        return YES;
    }
    else if ( commandSelector == @selector(insertNewline:) )
    {
        [self chat];
        return YES;
    }
    else if ( commandSelector == @selector(cancelOperation:) )
    {
        [[NSApp delegate] closeRosterPopover];
        return YES;
    }

    return NO;
}


- (IBAction) filterRoster:(id)sender
{
    BOOL hadItems = NO;
    BOOL hasItems = NO;
    BOOL hadSelectedItem = NO;
    OSPUserStorageObject *selectedItemBeforeFilter = nil;

    NSMutableString *searchText = [NSMutableString stringWithString:[sender stringValue]];
    NSPredicate *filterPredicate;

    hadItems = [[arrayController arrangedObjects] count] > 0;
    hadSelectedItem = [[arrayController selectedObjects] count] > 0;

    if (hadItems && hadSelectedItem)
    {
        selectedItemBeforeFilter = [[arrayController selectedObjects] objectAtIndex:0];
    }

    // Remove extraenous whitespace
    while ([searchText rangeOfString:@"Â  "].location != NSNotFound)
    {
        [searchText replaceOccurrencesOfString:@"Â  " withString:@" " options:0 range:NSMakeRange(0, [searchText length])];
    }

    //Remove leading space
    if ([searchText length] != 0)
    {
        [searchText replaceOccurrencesOfString:@" " withString:@"" options:0 range:NSMakeRange(0,1)];
    }

    //Remove trailing space
    if ([searchText length] != 0)
    {
        [searchText replaceOccurrencesOfString:@" " withString:@"" options:0 range:NSMakeRange([searchText length] - 1, 1)];
    }

    if ([searchText length] == 0)
    {
        [arrayController setFilterPredicate:nil];
        return;
    }

    NSArray *searchTerms = [searchText componentsSeparatedByString:@" "];
    if ([searchTerms count] == 1)
    {
        filterPredicate = [NSPredicate predicateWithFormat:@"(displayName contains[cd] %@) OR (jidStr contains[cd] %@)", searchText, searchText];
    }
    else
    {
        NSMutableArray *subPredicates = [[NSMutableArray alloc] init];
        for (NSString *term in searchTerms)
        {
            NSPredicate *p = [NSPredicate predicateWithFormat:@"(displayName contains[cd] %@) OR (jidStr contains[cd] %@)", term, term];
            [subPredicates addObject:p];
        }

        filterPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:subPredicates];
    }

    [arrayController setFilterPredicate:filterPredicate];

    hasItems = [[arrayController arrangedObjects] count] > 0;

    if (!hasItems)
    {
        return;
    }

    if (hadSelectedItem)
    {
        if ([(NSArray *)[arrayController arrangedObjects] containsObject:selectedItemBeforeFilter])
        {
            [rosterTable selectRowIndexes:[NSIndexSet indexSetWithIndex:[[arrayController arrangedObjects] indexOfObject:selectedItemBeforeFilter]] byExtendingSelection:NO];
            return;
        }
    }

    [rosterTable selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
}


#pragma mark - Subscription management
- (void) xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence
{
    NSLog(@"Delegate call received %@", presence.fromStr);

    XMPPJID *jid = [presence from];

    if (![requests containsObject:jid])
    {
        [requests addObject:jid];

        if ([requests count] == 1)
        {
            jidIndex = 0;

            [jidField setStringValue:[jid bare]];
            [xofyField setHidden:YES];

            [requestWindow setAlphaValue:0.85F];
            [requestWindow makeKeyAndOrderFront:self];
        }
        else
        {
            [xofyField setStringValue:[NSString stringWithFormat:@"%i of %i", (jidIndex + 1), (int)[requests count]]];
            [xofyField setHidden:NO];
        }
    }
}


- (IBAction) acceptRequest:(id)sender
{
    XMPPJID *jid = [requests objectAtIndex:jidIndex];

    [[self xmppRoster] acceptPresenceSubscriptionRequestFrom:jid andAddToRoster:YES];

    [self nextRequest];
}


- (IBAction) rejectRequest:(id)sender
{
    XMPPJID *jid = [requests objectAtIndex:jidIndex];

    [[self xmppRoster] rejectPresenceSubscriptionRequestFrom:jid];

    [self nextRequest];
}


- (void) nextRequest
{
    DDLogInfo(@"RequestController: nextRequest");

    if (++jidIndex < [requests count])
    {
        XMPPJID *jid = [requests objectAtIndex:jidIndex];

        [jidField setStringValue:[jid bare]];
        [xofyField setStringValue:[NSString stringWithFormat:@"%i of %i", (jidIndex + 1), (int)[requests count]]];
    }
    else
    {
        [requests removeAllObjects];
        jidIndex = -1;
        [requestWindow close];
    }
}


@end
