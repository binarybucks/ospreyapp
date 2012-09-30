#import "OSPChatArrayController.h"

@implementation OSPChatArrayController
- (void) awakeFromNib
{
    _fetchCount = 10;
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
    [self setSortDescriptors:[NSArray arrayWithObject:sort]];
    [super awakeFromNib];
}


// Configures fetch to only include *fetchCount* number of items
// The ArrayControllers sort descripter then takes care of sorting the returned ones ascending again so the last ones are the most recent ones
//
- (BOOL) fetchWithRequest:(NSFetchRequest *)fetchRequest
                    merge:(BOOL)merge
                    error:(NSError * *)error
{
    if (fetchRequest)
    {
        [fetchRequest setSortDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO]]];
        [fetchRequest setFetchLimit:_fetchCount];
    }

    return [super fetchWithRequest:fetchRequest merge:NO error:error];
}


- (IBAction) fetchMore:(id)sender
{
    _fetchCount = (int)((NSArray *)self.arrangedObjects).count + 10;
    NSError *error = nil;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:self.entityName inManagedObjectContext:self.managedObjectContext]];
    [request setPredicate:self.fetchPredicate];

    [self fetchWithRequest:request merge:YES error:&error];

    if (error != nil)
    {
        DDLogError(@"Error fetching more with %@", [error description]);
    }
}


@end
