#import "NSManagedObjectContext+EasyFetching.h"

@implementation NSManagedObjectContext (EasyFetching)

- (NSArray *) fetchEntity:(NSString *)entityName withSortDescriptor:(NSSortDescriptor *)sortDescriptor fetchLimit:(NSInteger)fetchLimit predicate:(NSPredicate *)predicate
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSError *error = nil;
    NSArray *results = nil;

    [request setEntity:entity];
    [request setPredicate:predicate];
    [request setFetchLimit:fetchLimit];

    if (sortDescriptor != nil)
    {
        [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    }

    results = [self executeFetchRequest:request error:&error];
    if (error != nil)
    {
        [NSException raise:NSGenericException format:@"%@", [error description]];
    }

    return results;
}


@end
