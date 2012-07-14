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
- (XMPPStream *)xmppStream
{
	return [[NSApp delegate] xmppStream];
}

- (XMPPRoster *)xmppRoster
{
	return [[NSApp delegate] xmppRoster];
}

- (OSPRosterStorage *)xmppRosterStorage
{
	return [[NSApp delegate] xmppRosterStorage];
}

- (NSDictionary *)jidKeyedDictionaryFromArray:(NSArray*)array{
    NSUInteger arrayCount = [array count];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    for(NSUInteger index = 0UL; index < arrayCount; index++) 
    { 
        [dict setValue:[array objectAtIndex:index] forKey:[[[array objectAtIndex:index] jid] bare]];
    }
    
    // return immutable copy
    return [NSDictionary dictionaryWithDictionary:dict];
}


- (OSPChatController *)chatController
{
	return [[NSApp delegate] chatController];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        initialAwakeFromNibCallFinished = NO;
    }
    
    return self;
}



- (id)init {
    self = [super init];
    if (self) {
//        contactArray = [[NSArray alloc] init];
//        contactDict = [[NSDictionary alloc] init];    
    }
    return self;
}

- (void) _setArrayControllerFetchPredicate {
    
    NSString *jid = [[NSUserDefaults standardUserDefaults] stringForKey:@"Account.Jid"];
    DDLogVerbose(@"FETCHING ROSTER WITH %@", jid);
    NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"streamBareJidStr == %@", jid];
    
    [arrayController setFetchPredicate:fetchPredicate];
}




-(void)awakeFromNib {
    // Medhod may be called more than once, so prevent all that stuff from being executed more than once
    if (!initialAwakeFromNibCallFinished) {
        LOGFUNCTIONCALL

        [[self xmppStream] addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [[self xmppRoster] addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [rosterTable setDoubleAction:@selector(chat:)];
        [rosterTable setTarget:self];
        
        [self _setArrayControllerFetchPredicate];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_setArrayControllerFetchPredicate) name:@"UserChangedJid" object:nil];
        initialAwakeFromNibCallFinished = YES;
        
        
    }
}

- (IBAction)chat:(id)sender
{
	if ([rosterTable selectedRow] >= 0) {
        [[self chatController] openChatWithUser:[[arrayController selectedObjects] objectAtIndex:0]];
        [[NSApp delegate] closeRosterPopover];
    }
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    return NO;
}

-(BOOL)control:(NSControl*)control textView:(NSTextView*)textView doCommandBySelector:(SEL)commandSelector {
    // selecting the next and previous item behaves strange when scrolling fast yet
    
    if(commandSelector == @selector(moveUp:)) {
        if ([arrayController canSelectPrevious]) {
            [arrayController selectPrevious:nil];
            [rosterTable scrollRowToVisible:[arrayController selectionIndex]-1];
        }
        return YES;
    }
    else if(commandSelector == @selector(moveDown:)) {
        if ([arrayController canSelectNext]) {
            [arrayController selectNext:nil];
            [rosterTable scrollRowToVisible:[arrayController selectionIndex]+1];
        }
        return YES;
    }
    else if(commandSelector == @selector(insertNewline:)) {
        [self chat:nil];
        return YES;
    }
    else if(commandSelector == @selector(cancelOperation:)) {
        [[NSApp delegate] closeRosterPopover];
        return YES;
    }   
    
    return NO;
}


- (IBAction)filterRoster:(id)sender {
    BOOL hadItems = NO;
    BOOL hasItems = NO;
    BOOL hadSelectedItem = NO;
    OSPUserStorageObject *selectedItemBeforeFilter = nil;

    NSMutableString *searchText = [NSMutableString stringWithString:[sender stringValue]];
    NSPredicate *filterPredicate;

    hadItems = [[arrayController arrangedObjects] count] > 0;
    hadSelectedItem = [[arrayController selectedObjects] count] >0 ;
    
    if (hadItems) {
        selectedItemBeforeFilter = [[arrayController selectedObjects] objectAtIndex:0];
    }

    
    // Remove extraenous whitespace
    while ([searchText rangeOfString:@"Â  "].location != NSNotFound) {
        [searchText replaceOccurrencesOfString:@"Â  " withString:@" " options:0 range:NSMakeRange(0, [searchText length])];
    }
    //Remove leading space
    if ([searchText length] != 0) [searchText replaceOccurrencesOfString:@" " withString:@"" options:0 range:NSMakeRange(0,1)];
    
    //Remove trailing space
    if ([searchText length] != 0) [searchText replaceOccurrencesOfString:@" " withString:@"" options:0 range:NSMakeRange([searchText length]-1, 1)];
    
    if ([searchText length] == 0) {
        [arrayController setFilterPredicate:nil];
        return;
    }
    
    NSArray *searchTerms = [searchText componentsSeparatedByString:@" "];
    if ([searchTerms count] == 1) {
        filterPredicate = [NSPredicate predicateWithFormat:@"(displayName contains[cd] %@) OR (jidStr contains[cd] %@)", searchText, searchText];
    } else {
        NSMutableArray *subPredicates = [[NSMutableArray alloc] init];
        for (NSString *term in searchTerms) {
            NSPredicate *p = [NSPredicate predicateWithFormat:@"(displayName contains[cd] %@) OR (jidStr contains[cd] %@)", term, term];
            [subPredicates addObject:p];
        }
        filterPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:subPredicates];
    }
    
    [arrayController setFilterPredicate:filterPredicate];
        
    hasItems = [[arrayController arrangedObjects] count] > 0;

    
    if (!hasItems) {
        return;
    } 
    
    if (hadSelectedItem) {
        if ([(NSArray*)[arrayController arrangedObjects] containsObject:selectedItemBeforeFilter]) {
        [rosterTable selectRowIndexes:[NSIndexSet indexSetWithIndex:[[arrayController arrangedObjects] indexOfObject:selectedItemBeforeFilter]] byExtendingSelection:NO];
            return;
        }
    }
    [rosterTable selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];


    
}


@end
